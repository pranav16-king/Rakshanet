import '../database/app_database.dart';
import '../models/call_session.dart';

class CallHistoryRepository {
  const CallHistoryRepository();

  Future<void> save(NearbyCallSession session) async {
    final endedAt = session.endedAt;
    final status = session.finalStatus;
    if (endedAt == null || status == null) return;
    final startedAt = session.connectedAt ?? session.createdAt;
    final entry = CallHistoryEntry(
      id: '${session.callId}-${endedAt.millisecondsSinceEpoch}',
      callId: session.callId,
      peerDeviceId: session.peerDeviceId,
      peerName: session.peerName,
      direction: session.direction,
      status: status,
      createdAt: session.createdAt,
      endedAt: endedAt,
      durationSeconds: session.connectedAt == null
          ? 0
          : endedAt.difference(startedAt).inSeconds.clamp(0, 86400),
    );
    await AppDatabase.instance.insert('call_history', entry.toMap());
  }

  Future<List<CallHistoryEntry>> forPeer(String peerDeviceId) async {
    final rows = await AppDatabase.instance.query(
      'call_history',
      where: 'peer_device_id = ?',
      whereArgs: [peerDeviceId],
      orderBy: 'ended_at DESC',
      limit: 5,
    );
    return rows.map(CallHistoryEntry.fromMap).toList();
  }

  Future<void> clearLocalHistory() => AppDatabase.instance.delete('call_history');
}
