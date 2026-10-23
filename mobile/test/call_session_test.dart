import 'package:flutter_test/flutter_test.dart';
import 'package:rakshanet_mobile/models/call_session.dart';

void main() {
  group('nearby call state machine', () {
    test('never promotes a ringing call directly to active', () {
      expect(
        CallStateMachine.canTransition(
          NearbyCallState.ringing,
          NearbyCallState.active,
        ),
        isFalse,
      );
    });

    test('requires connecting before active media state', () {
      expect(
        CallStateMachine.canTransition(
          NearbyCallState.ringing,
          NearbyCallState.connecting,
        ),
        isTrue,
      );
      expect(
        CallStateMachine.canTransition(
          NearbyCallState.connecting,
          NearbyCallState.active,
        ),
        isTrue,
      );
    });

    test('does not revive a terminal call without returning to idle', () {
      expect(
        CallStateMachine.canTransition(
          NearbyCallState.ended,
          NearbyCallState.active,
        ),
        isFalse,
      );
      expect(
        CallStateMachine.canTransition(
          NearbyCallState.ended,
          NearbyCallState.idle,
        ),
        isTrue,
      );
    });
  });

  test('history persists local recording metadata but never audio bytes', () {
    final entry = CallHistoryEntry(
      id: 'record-1',
      callId: '159c2efb-9523-43ce-b954-4df0245f4c8f',
      peerDeviceId: 'peer-1',
      peerName: 'Nearby person',
      direction: CallDirection.outgoing,
      status: CallFinalStatus.completed,
      createdAt: DateTime(2026, 1, 1, 12),
      endedAt: DateTime(2026, 1, 1, 12, 1),
      durationSeconds: 60,
      recordingState: CallRecordingState.recorded,
      recordingLocalPath: '/app-private/call_microphone.wav',
      recordingRemotePath: '/app-private/call_nearby.wav',
    );

    final map = entry.toMap();
    expect(map['transport'], 'nearby_connections');
    expect(map.containsKey('audio'), isFalse);
    expect(map['recording_state'], 'recorded');
    expect(map['recording_local_path'], '/app-private/call_microphone.wav');
    expect(map['recording_remote_path'], '/app-private/call_nearby.wav');
  });

  test('legacy history without recording metadata remains readable', () {
    final entry = CallHistoryEntry.fromMap({
      'id': 'legacy-1',
      'call_id': '159c2efb-9523-43ce-b954-4df0245f4c8f',
      'peer_device_id': 'peer-1',
      'peer_name': 'Nearby person',
      'direction': 'incoming',
      'status': 'completed',
      'created_at': DateTime(2026, 1, 1, 12).millisecondsSinceEpoch,
      'ended_at': DateTime(2026, 1, 1, 12, 1).millisecondsSinceEpoch,
      'duration_seconds': 60,
    });

    expect(entry.recordingState, CallRecordingState.none);
    expect(entry.recordingLocalPath, isNull);
    expect(entry.recordingRemotePath, isNull);
  });
}
