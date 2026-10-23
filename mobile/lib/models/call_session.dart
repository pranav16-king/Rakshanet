enum NearbyCallState {
  idle,
  outgoing,
  ringing,
  incoming,
  connecting,
  active,
  ending,
  ended,
  failed,
}

enum CallDirection { outgoing, incoming }

/// A recording can only become active on the phone that requested it after
/// the other participant approves in the active call.
enum CallRecordingState {
  none,
  requestingConsent,
  consentRequested,
  active,
  recorded,
  declined,
  unavailable,
}

enum CallFinalStatus {
  completed,
  rejected,
  busy,
  cancelled,
  missed,
  timeout,
  failed,
  appBackgrounded,
}

class NearbyCallSession {
  const NearbyCallSession({
    required this.callId,
    required this.peerDeviceId,
    required this.peerName,
    required this.endpointId,
    required this.direction,
    required this.state,
    required this.createdAt,
    required this.expiresAt,
    this.connectedAt,
    this.endedAt,
    this.finalStatus,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.recordingState = CallRecordingState.none,
    this.isPeerRecording = false,
    this.recordingLocalPath,
    this.recordingRemotePath,
    this.message,
  });

  final String callId;
  final String peerDeviceId;
  final String peerName;
  final String endpointId;
  final CallDirection direction;
  final NearbyCallState state;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? connectedAt;
  final DateTime? endedAt;
  final CallFinalStatus? finalStatus;
  final bool isMuted;
  final bool isSpeakerOn;
  final CallRecordingState recordingState;
  final bool isPeerRecording;
  final String? recordingLocalPath;
  final String? recordingRemotePath;
  final String? message;

  bool get isTerminal =>
      state == NearbyCallState.ended || state == NearbyCallState.failed;

  bool get hasConnectedMedia => connectedAt != null;

  NearbyCallSession copyWith({
    NearbyCallState? state,
    DateTime? connectedAt,
    DateTime? endedAt,
    CallFinalStatus? finalStatus,
    bool? isMuted,
    bool? isSpeakerOn,
    CallRecordingState? recordingState,
    bool? isPeerRecording,
    String? recordingLocalPath,
    String? recordingRemotePath,
    String? message,
  }) {
    return NearbyCallSession(
      callId: callId,
      peerDeviceId: peerDeviceId,
      peerName: peerName,
      endpointId: endpointId,
      direction: direction,
      state: state ?? this.state,
      createdAt: createdAt,
      expiresAt: expiresAt,
      connectedAt: connectedAt ?? this.connectedAt,
      endedAt: endedAt ?? this.endedAt,
      finalStatus: finalStatus ?? this.finalStatus,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      recordingState: recordingState ?? this.recordingState,
      isPeerRecording: isPeerRecording ?? this.isPeerRecording,
      recordingLocalPath: recordingLocalPath ?? this.recordingLocalPath,
      recordingRemotePath: recordingRemotePath ?? this.recordingRemotePath,
      message: message ?? this.message,
    );
  }
}

class CallStateMachine {
  const CallStateMachine._();

  static bool canTransition(NearbyCallState from, NearbyCallState to) {
    if (from == to) return true;
    switch (from) {
      case NearbyCallState.idle:
        return to == NearbyCallState.outgoing || to == NearbyCallState.incoming;
      case NearbyCallState.outgoing:
        return to == NearbyCallState.ringing ||
            to == NearbyCallState.ending ||
            to == NearbyCallState.failed;
      case NearbyCallState.ringing:
      case NearbyCallState.incoming:
        return to == NearbyCallState.connecting ||
            to == NearbyCallState.ending ||
            to == NearbyCallState.ended ||
            to == NearbyCallState.failed;
      case NearbyCallState.connecting:
        return to == NearbyCallState.active ||
            to == NearbyCallState.ending ||
            to == NearbyCallState.ended ||
            to == NearbyCallState.failed;
      case NearbyCallState.active:
        return to == NearbyCallState.ending || to == NearbyCallState.failed;
      case NearbyCallState.ending:
        return to == NearbyCallState.ended || to == NearbyCallState.failed;
      case NearbyCallState.ended:
      case NearbyCallState.failed:
        return to == NearbyCallState.idle;
    }
  }
}

class CallHistoryEntry {
  const CallHistoryEntry({
    required this.id,
    required this.callId,
    required this.peerDeviceId,
    required this.peerName,
    required this.direction,
    required this.status,
    required this.createdAt,
    required this.endedAt,
    required this.durationSeconds,
    this.recordingState = CallRecordingState.none,
    this.recordingLocalPath,
    this.recordingRemotePath,
  });

  final String id;
  final String callId;
  final String peerDeviceId;
  final String peerName;
  final CallDirection direction;
  final CallFinalStatus status;
  final DateTime createdAt;
  final DateTime endedAt;
  final int durationSeconds;
  final CallRecordingState recordingState;
  final String? recordingLocalPath;
  final String? recordingRemotePath;

  Map<String, dynamic> toMap() => {
    'id': id,
    'call_id': callId,
    'peer_device_id': peerDeviceId,
    'peer_name': peerName,
    'direction': direction.name,
    'status': status.name,
    'transport': 'nearby_connections',
    'created_at': createdAt.millisecondsSinceEpoch,
    'ended_at': endedAt.millisecondsSinceEpoch,
    'duration_seconds': durationSeconds,
    'recording_state': recordingState.name,
    'recording_local_path': recordingLocalPath,
    'recording_remote_path': recordingRemotePath,
  };

  factory CallHistoryEntry.fromMap(Map<String, dynamic> map) =>
      CallHistoryEntry(
        id: map['id'].toString(),
        callId: map['call_id'].toString(),
        peerDeviceId: map['peer_device_id'].toString(),
        peerName: map['peer_name'].toString(),
        direction: CallDirection.values.byName(map['direction'].toString()),
        status: CallFinalStatus.values.byName(map['status'].toString()),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['created_at'] as int,
        ),
        endedAt: DateTime.fromMillisecondsSinceEpoch(map['ended_at'] as int),
        durationSeconds: map['duration_seconds'] as int,
        recordingState: CallRecordingState.values.byName(
          map['recording_state']?.toString() ?? CallRecordingState.none.name,
        ),
        recordingLocalPath: map['recording_local_path']?.toString(),
        recordingRemotePath: map['recording_remote_path']?.toString(),
      );
}
