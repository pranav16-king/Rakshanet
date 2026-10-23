import 'dart:async';

import 'package:flutter/services.dart';

/// Android-native PCM capture/playback bridge for an active Nearby call.
/// Native code owns AudioRecord, AudioTrack, audio focus and the jitter buffer;
/// Dart only moves bounded PCM frames onto the already-established local link.
class OfflineAudioBridge {
  static const MethodChannel _methods =
      MethodChannel('org.rakshanet/offline_audio');
  static const EventChannel _captureEvents =
      EventChannel('org.rakshanet/offline_audio_capture');

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

  Future<void> playFrame(Uint8List pcm) async {
    if (pcm.isEmpty) return;
    try {
      await _methods.invokeMethod<void>('playFrame', pcm);
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
