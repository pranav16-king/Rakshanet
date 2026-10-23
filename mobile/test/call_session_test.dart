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

  test('history persists metadata but carries no audio field', () {
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
    );

    final map = entry.toMap();
    expect(map['transport'], 'nearby_connections');
    expect(map.containsKey('audio'), isFalse);
    expect(map.containsKey('recording'), isFalse);
  });
}
