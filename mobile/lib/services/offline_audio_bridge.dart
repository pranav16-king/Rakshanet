import 'dart:async';

import 'package:flutter/services.dart';

class CallRecordingFiles {
  const CallRecordingFiles({this.localPath, this.remotePath});

  final String? localPath;
  final String? remotePath;

  bool get hasFiles => localPath != null || remotePath != null;

  static CallRecordingFiles? fromPlatform(Map<Object?, Object?>? value) {
    if (value == null) return null;
    final local = value['local_path']?.toString();
    final remote = value['remote_path']?.toString();
    if (local == null && remote == null) return null;
    return CallRecordingFiles(localPath: local, remotePath: remote);
  }
}

/// Android-native capture/playback bridge for an active Nearby call. Native
/// code owns the G.711 conversion, audio focus, jitter buffer, and optional
/// app-private recording; Dart only moves bounded call frames over Nearby.
class OfflineAudioBridge {
  static const MethodChannel _methods = MethodChannel(
    'org.rakshanet/offline_audio',
  );
  static const EventChannel _captureEvents = EventChannel(
    'org.rakshanet/offline_audio_capture',
  );

  final StreamController<Uint8List> _frames =
      StreamController<Uint8List>.broadcast();
  StreamSubscription<dynamic>? _captureSubscription;

  Stream<Uint8List> get capturedFrames => _frames.stream;

  Future<bool> startCapture() async {
    try {
      final ready = await _methods.invokeMethod<bool>('startCapture') ?? false;
      if (!ready) return false;
      _captureSubscription ??= _captureEvents.receiveBroadcastStream().listen(
        (dynamic frame) {
          if (frame is Uint8List && frame.isNotEmpty) {
            _frames.add(frame);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          _frames.addError(error, stackTrace);
        },
      );
      return true;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> startPlayback() async {
    try {
      return await _methods.invokeMethod<bool>('startPlayback') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> playFrame(Uint8List audio, {required String codec}) async {
    if (audio.isEmpty) return;
    try {
      await _methods.invokeMethod<void>('playFrame', {
        'audio': audio,
        'codec': codec,
      });
    } on PlatformException {
      // A disconnection races harmlessly with an arriving frame.
    }
  }

  Future<void> setSpeakerphone(bool enabled) async {
    try {
      await _methods.invokeMethod<void>('setSpeakerphone', enabled);
    } on PlatformException {
      // Keep the control truthful in the UI: the controller only updates its
      // state after this call completes without an exception.
      rethrow;
    }
  }

  Future<void> stopCapture() async {
    try {
      await _methods.invokeMethod<void>('stopCapture');
    } on PlatformException {
      // Capture may already be stopped after a hardware interruption.
    }
  }

  Future<CallRecordingFiles?> startCallRecording(String callId) async {
    try {
      final result = await _methods.invokeMapMethod<Object?, Object?>(
        'startCallRecording',
        callId,
      );
      return CallRecordingFiles.fromPlatform(result);
    } on PlatformException {
      return null;
    }
  }

  Future<CallRecordingFiles?> stopCallRecording() async {
    try {
      final result = await _methods.invokeMapMethod<Object?, Object?>(
        'stopCallRecording',
      );
      return CallRecordingFiles.fromPlatform(result);
    } on PlatformException {
      return null;
    }
  }

  Future<void> stop() async {
    try {
      await _methods.invokeMethod<void>('stopAudio');
    } on PlatformException {
      // Best-effort resource cleanup during teardown.
    }
  }

  Future<void> dispose() async {
    await stop();
    await _captureSubscription?.cancel();
    await _frames.close();
  }
}
