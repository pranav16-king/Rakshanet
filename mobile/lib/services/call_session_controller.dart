import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../models/call_session.dart';
import '../models/remote_user_profile.dart';
import 'bluetooth_radio_service.dart';
import 'call_history_repository.dart';
import 'database_service.dart';
import 'offline_audio_bridge.dart';

class NearbyCallAvailability {
  const NearbyCallAvailability({required this.isAvailable, required this.message});

  final bool isAvailable;
  final String message;
}

/// One authoritative foreground call state for the app. It uses a direct
/// Nearby Connections endpoint only: no call event or audio frame is ever
/// relayed through the mesh or sent to the internet.
class CallSessionController extends ChangeNotifier with WidgetsBindingObserver {
  CallSessionController({
    BluetoothRadioService? radio,
    OfflineAudioBridge? audioBridge,
    CallHistoryRepository? history,
    DateTime Function()? now,
    Uuid? uuid,
  })  : _radio = radio ?? BluetoothRadioService(),
        _audio = audioBridge ?? OfflineAudioBridge(),
        _history = history ?? const CallHistoryRepository(),
        _now = now ?? DateTime.now,
        _uuid = uuid ?? const Uuid() {
    WidgetsBinding.instance.addObserver(this);
    _controlSubscription = _radio.incomingCallControlStream.listen(_handleControl);
    _audioSubscription = _radio.incomingAudioFrameStream.listen(_handleAudioFrame);
    _captureSubscription = _audio.capturedFrames.listen(_sendCapturedFrame);
  }

  static const Duration invitationTimeout = Duration(seconds: 45);
  static const Duration connectionTimeout = Duration(seconds: 20);

  final BluetoothRadioService _radio;
  final OfflineAudioBridge _audio;
  final CallHistoryRepository _history;
  final DateTime Function() _now;
  final Uuid _uuid;

  StreamSubscription<NearbyCallControlFrame>? _controlSubscription;
  StreamSubscription<NearbyAudioFrame>? _audioSubscription;
  StreamSubscription<Uint8List>? _captureSubscription;
  Timer? _timeoutTimer;
  NearbyCallSession? _session;
  bool _captureActive = false;
  bool _sendingFrame = false;

  NearbyCallSession? get session => _session;
  bool get hasVisibleCall => _session != null;
  bool get isBusy => _session != null && !_session!.isTerminal;

  NearbyCallAvailability availabilityFor(RemoteUserProfile profile) {
    final endpoint = _radio.endpointForDevice(profile.userId);
    if (endpoint == null) {
      return const NearbyCallAvailability(
        isAvailable: false,
        message: 'Voice calls need a current direct Bluetooth or Wi-Fi Nearby connection.',
      );
    }
    if (isBusy) {
      return const NearbyCallAvailability(
        isAvailable: false,
        message: 'Finish the current nearby call before starting another.',
      );
    }
    return const NearbyCallAvailability(
      isAvailable: true,
      message: 'Direct nearby audio is available. Internet is not used.',
    );
  }

  Future<String?> startOutgoing(RemoteUserProfile profile) async {
    final availability = availabilityFor(profile);
    if (!availability.isAvailable) return availability.message;
    final microphone = await Permission.microphone.request();
    if (!microphone.isGranted) {
      return 'Microphone permission is required to place a voice call.';
    }
    final endpointId = _radio.endpointForDevice(profile.userId);
    if (endpointId == null) {
      return 'This nearby connection ended before the call could start.';
    }

    final createdAt = _now();
    final callId = _uuid.v4();
    _session = NearbyCallSession(
      callId: callId,
      peerDeviceId: profile.userId,
      peerName: profile.displayName,
      endpointId: endpointId,
      direction: CallDirection.outgoing,
      state: NearbyCallState.outgoing,
      createdAt: createdAt,
      expiresAt: createdAt.add(invitationTimeout),
      message: 'Calling nearby device…',
    );
    notifyListeners();

    final sent = await _sendControl('invite', extra: {
      'sender_device_id': DatabaseService.myDeviceId,
      'sender_name': DatabaseService.myDisplayName,
      'target_device_id': profile.userId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'expires_at': _session!.expiresAt.millisecondsSinceEpoch,
      'transport': 'nearby_connections',
    });
    if (!sent) {
      await _finish(CallFinalStatus.failed, 'The direct nearby link is unavailable.');
      return 'The direct nearby link is unavailable.';
    }
    _transition(NearbyCallState.ringing, message: 'Ringing nearby device…');
    _armTimeout(invitationTimeout, CallFinalStatus.timeout, 'No response from this nearby device.');
    return null;
  }

  Future<String?> acceptIncoming() async {
    final active = _session;
    if (active == null || active.state != NearbyCallState.incoming) {
      return 'This call is no longer available.';
    }
    if (_now().isAfter(active.expiresAt)) {
      await _sendControl('timeout');
      await _finish(CallFinalStatus.timeout, 'This invitation has expired.');
      return 'This invitation has expired.';
    }
    final microphone = await Permission.microphone.request();
    if (!microphone.isGranted) {
      await _sendControl('reject', extra: {'reason': 'microphone_permission_denied'});
      await _finish(CallFinalStatus.rejected, 'Microphone permission was not granted.');
      return 'Microphone permission is required to accept a voice call.';
    }
    _transition(NearbyCallState.connecting, message: 'Starting local audio…');
    if (!await _startAudio()) {
      await _sendControl('failure');
      await _finish(CallFinalStatus.failed, 'The phone audio device could not start.');
      return 'The phone audio device could not start.';
    }
    await _sendControl('accept');
    _armTimeout(connectionTimeout, CallFinalStatus.failed, 'Audio connection could not be established.');
    return null;
  }

  Future<void> rejectIncoming() async {
    if (_session?.state != NearbyCallState.incoming) return;
    await _sendControl('reject');
    await _finish(CallFinalStatus.rejected, 'You declined the call.');
  }

  Future<void> cancelOutgoing() async {
    final state = _session?.state;
    if (state != NearbyCallState.outgoing && state != NearbyCallState.ringing) return;
    await _sendControl('cancel');
    await _finish(CallFinalStatus.cancelled, 'You cancelled the call.');
  }

  Future<void> endCall({CallFinalStatus status = CallFinalStatus.completed}) async {
    final active = _session;
    if (active == null || active.isTerminal) return;
    if (CallStateMachine.canTransition(active.state, NearbyCallState.ending)) {
      _transition(NearbyCallState.ending, message: 'Ending call…');
    }
    await _sendControl('end');
    await _finish(status, 'Call ended.');
  }

  Future<void> toggleMute() async {
    final active = _session;
    if (active == null || active.isTerminal || !active.hasConnectedMedia) return;
    if (active.isMuted) {
      _captureActive = await _audio.startCapture();
      if (!_captureActive) return;
      _session = active.copyWith(isMuted: false, message: 'Microphone on');
    } else {
      await _audio.stopCapture();
      _captureActive = false;
      _session = active.copyWith(isMuted: true, message: 'Microphone muted');
    }
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    final active = _session;
    if (active == null || active.isTerminal) return;
    try {
      await _audio.setSpeakerphone(!active.isSpeakerOn);
      _session = active.copyWith(isSpeakerOn: !active.isSpeakerOn);
      notifyListeners();
    } catch (_) {
      _session = active.copyWith(message: 'This audio route is not available.');
      notifyListeners();
    }
  }

  void dismissTerminalCall() {
    if (_session == null || !_session!.isTerminal) return;
    _session = null;
    notifyListeners();
  }

  Future<bool> _startAudio() async {
    final playback = await _audio.startPlayback();
    if (!playback) return false;
    _captureActive = await _audio.startCapture();
    if (!_captureActive) {
      await _audio.stop();
      return false;
    }
    return true;
  }

  Future<bool> _sendControl(
    String action, {
    Map<String, Object?> extra = const {},
  }) async {
    final active = _session;
    if (active == null) return false;
    return _radio.sendCallControl(active.endpointId, {
      'action': action,
      'call_id': active.callId,
      ...extra,
    });
  }

  void _handleControl(NearbyCallControlFrame frame) {
    final payload = frame.payload;
    final action = payload['action'];
    if (action is! String) return;
    if (action == 'invite') {
      unawaited(_receiveInvite(frame));
      return;
    }
    final active = _session;
    if (active == null ||
        payload['call_id'] != active.callId ||
        frame.endpointId != active.endpointId) {
      return;
    }
    switch (action) {
      case 'accept':
        if (active.direction == CallDirection.outgoing &&
            active.state == NearbyCallState.ringing) {
          unawaited(_onOutgoingAccepted());
        }
      case 'reject':
        if (!active.isTerminal) {
          unawaited(_finish(CallFinalStatus.rejected, '${active.peerName} declined the call.'));
        }
      case 'busy':
        if (!active.isTerminal) {
          unawaited(_finish(CallFinalStatus.busy, '${active.peerName} is already in another call.'));
        }
      case 'cancel':
        if (!active.isTerminal) {
          unawaited(_finish(CallFinalStatus.cancelled, '${active.peerName} cancelled the call.'));
        }
      case 'end':
        if (!active.isTerminal) {
          unawaited(_finish(CallFinalStatus.completed, '${active.peerName} ended the call.'));
        }
      case 'timeout':
        if (!active.isTerminal) {
          unawaited(_finish(CallFinalStatus.timeout, 'The call invitation expired.'));
        }
      case 'failure':
        if (!active.isTerminal) {
          unawaited(_finish(CallFinalStatus.failed, 'The nearby device could not start audio.'));
        }
      case 'audio_received':
        if (active.state == NearbyCallState.connecting) {
          _transition(NearbyCallState.active, message: 'Connected over nearby ${_transportLabel(active.endpointId)}');
        }
    }
  }

  Future<void> _receiveInvite(NearbyCallControlFrame frame) async {
    final payload = frame.payload;
    final callerId = payload['sender_device_id']?.toString() ?? '';
    final targetId = payload['target_device_id']?.toString() ?? '';
    final callerName = payload['sender_name']?.toString().trim() ?? '';
    final callId = payload['call_id']?.toString() ?? '';
    final expiry = int.tryParse(payload['expires_at']?.toString() ?? '');
    final connectedPeer = _radio.deviceForEndpoint(frame.endpointId);
    if (!_isValidCallId(callId) ||
        callerId.isEmpty ||
        callerName.isEmpty ||
        targetId != DatabaseService.myDeviceId ||
        connectedPeer?.deviceId != callerId ||
        expiry == null) {
      return;
    }
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(expiry);
    if (_now().isAfter(expiresAt) || expiresAt.difference(_now()) > invitationTimeout) {
      await _radio.sendCallControl(frame.endpointId, {'action': 'timeout', 'call_id': callId});
      return;
    }
    if (isBusy) {
      await _radio.sendCallControl(frame.endpointId, {'action': 'busy', 'call_id': callId});
      return;
    }
    _session = NearbyCallSession(
      callId: callId,
      peerDeviceId: callerId,
      peerName: callerName,
      endpointId: frame.endpointId,
      direction: CallDirection.incoming,
      state: NearbyCallState.incoming,
      createdAt: _now(),
      expiresAt: expiresAt,
      message: 'Incoming nearby voice call',
    );
    notifyListeners();
    _armTimeout(expiresAt.difference(_now()), CallFinalStatus.missed, 'You missed this nearby call.');
  }

  Future<void> _onOutgoingAccepted() async {
    _transition(NearbyCallState.connecting, message: 'Connecting local audio…');
    if (!await _startAudio()) {
      await _sendControl('failure');
      await _finish(CallFinalStatus.failed, 'The phone audio device could not start.');
      return;
    }
    _armTimeout(connectionTimeout, CallFinalStatus.failed, 'Audio connection could not be established.');
  }

  void _handleAudioFrame(NearbyAudioFrame frame) {
    final active = _session;
    if (active == null ||
        active.isTerminal ||
        active.callId != frame.callId ||
        active.endpointId != frame.endpointId ||
        active.state != NearbyCallState.connecting && active.state != NearbyCallState.active) {
      return;
    }
    unawaited(_audio.playFrame(frame.pcm));
    if (active.state == NearbyCallState.connecting) {
      _transition(NearbyCallState.active, message: 'Connected over nearby ${_transportLabel(active.endpointId)}');
      unawaited(_sendControl('audio_received'));
    }
  }

  void _sendCapturedFrame(Uint8List frame) {
    final active = _session;
    if (active == null ||
        !_captureActive ||
        active.isMuted ||
        (active.state != NearbyCallState.connecting && active.state != NearbyCallState.active) ||
        _sendingFrame) {
      return;
    }
    _sendingFrame = true;
    _radio.sendCallAudio(active.endpointId, active.callId, frame).whenComplete(() {
      _sendingFrame = false;
    });
  }

  void _transition(NearbyCallState next, {String? message}) {
    final active = _session;
    if (active == null || !CallStateMachine.canTransition(active.state, next)) return;
    _session = active.copyWith(
      state: next,
      connectedAt: next == NearbyCallState.active && active.connectedAt == null ? _now() : null,
      message: message,
    );
    notifyListeners();
  }

  void _armTimeout(Duration delay, CallFinalStatus status, String message) {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(delay.isNegative ? Duration.zero : delay, () async {
      final active = _session;
      if (active == null || active.isTerminal) return;
      if (status == CallFinalStatus.timeout || status == CallFinalStatus.missed) {
        await _sendControl('timeout');
      } else {
        await _sendControl('failure');
      }
      await _finish(status, message);
    });
  }

  Future<void> _finish(CallFinalStatus status, String message) async {
    final active = _session;
    if (active == null || active.isTerminal) return;
    _timeoutTimer?.cancel();
    _captureActive = false;
    await _audio.stop();
    final finalState = status == CallFinalStatus.failed
        ? NearbyCallState.failed
        : NearbyCallState.ended;
    _session = active.copyWith(
      state: finalState,
      endedAt: _now(),
      finalStatus: status,
      message: message,
    );
    await _history.save(_session!);
    notifyListeners();
  }

  String _transportLabel(String endpointId) {
    return _radio.deviceForEndpoint(endpointId)?.connectionType.name == 'wifiDirect'
        ? 'Wi-Fi Direct'
        : 'Bluetooth/Wi-Fi Nearby';
  }

  bool _isValidCallId(String callId) =>
      RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(callId);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused || state == AppLifecycleState.detached) && isBusy) {
      unawaited(endCall(status: CallFinalStatus.appBackgrounded));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timeoutTimer?.cancel();
    unawaited(_audio.dispose());
    unawaited(_controlSubscription?.cancel());
    unawaited(_audioSubscription?.cancel());
    unawaited(_captureSubscription?.cancel());
    super.dispose();
  }
}
