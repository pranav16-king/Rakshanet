enum EmergencyType {
  medical('Medical', 'Severe injury, cardiac, trauma'),
  trapped('Trapped', 'Structural collapse, debris, locked'),
  fire('Fire', 'Active flames, toxic smoke, burn risk'),
  flood('Flood', 'Rapid water rise, rooftop marooned'),
  missingPerson('Missing Person', 'Unaccounted civilian or child'),
  customSituation('Custom Situation', 'Other critical emergency');

  final String label;
  final String description;
  const EmergencyType(this.label, this.description);

  static EmergencyType fromString(String? val) {
    if (val == null) return EmergencyType.customSituation;
    for (final t in EmergencyType.values) {
      if (t.label.toLowerCase() == val.toLowerCase() || t.name.toLowerCase() == val.toLowerCase()) {
        return t;
      }
    }
    return EmergencyType.customSituation;
  }
}

class EmergencyReport {
  final String id;
  final EmergencyType type;
  final int peopleCount;
  final String notes;
  final String status;
  final int createdAt;
  final double? latitude;
  final double? longitude;
  final String location;
  final bool syncPending;
  final String severity;
  final String? senderDeviceId;
  final bool isLocal;

  const EmergencyReport({
    required this.id,
    required this.type,
    this.peopleCount = 1,
    this.notes = '',
    this.status = 'SAVED',
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.location = 'Unknown',
    this.syncPending = false,
    this.severity = 'HIGH',
    this.senderDeviceId,
    this.isLocal = false,
  });

  /// Flexible factory for either category string or enum
  factory EmergencyReport.create({
    required String id,
    EmergencyType? type,
    String? category,
    int peopleCount = 1,
    String? notes,
    String? description,
    String status = 'SAVED',
    dynamic createdAt,
    dynamic timestamp,
    double? latitude,
    double? longitude,
    String? location,
    bool syncPending = false,
    String severity = 'HIGH',
    String? senderDeviceId,
    bool isLocal = false,
  }) {
    final resolvedType = type ?? (category != null ? EmergencyType.fromString(category) : EmergencyType.customSituation);
    final resolvedNotes = notes ?? description ?? '';
    final resolvedLocation = location ?? ((latitude != null && longitude != null) ? '$latitude, $longitude' : 'Unknown');
    final resolvedCreatedAt = (createdAt is int)
        ? createdAt
        : (timestamp is DateTime)
            ? timestamp.millisecondsSinceEpoch
            : (timestamp is int)
                ? timestamp
                : DateTime.now().millisecondsSinceEpoch;

    return EmergencyReport(
      id: id,
      type: resolvedType,
      peopleCount: peopleCount,
      notes: resolvedNotes,
      status: status,
      createdAt: resolvedCreatedAt,
      latitude: latitude,
      longitude: longitude,
      location: resolvedLocation,
      syncPending: syncPending,
      severity: severity,
      senderDeviceId: senderDeviceId,
      isLocal: isLocal,
    );
  }

  String get category => type.label;
  String get description => notes;
  DateTime get timestamp => DateTime.fromMillisecondsSinceEpoch(createdAt);

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'type': type.label,
      'description': notes,
      'status': status,
      'timestamp': createdAt,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'people_affected': peopleCount,
      'peopleCount': peopleCount,
      'severity': severity,
      'notes': notes,
      'created_at': createdAt,
    };
    if (senderDeviceId != null) {
      map['sender_device_id'] = senderDeviceId;
    }
    if (isLocal) {
      map['is_local'] = 1;
    }
    return map;
  }

  factory EmergencyReport.fromMap(Map<String, dynamic> map) {
    return EmergencyReport.create(
      id: map['id']?.toString() ?? '',
      type: EmergencyType.fromString(map['type']?.toString() ?? map['category']?.toString()),
      peopleCount: map['people_affected'] is int
          ? map['people_affected'] as int
          : (map['peopleCount'] is int
              ? map['peopleCount'] as int
              : int.tryParse(map['peopleCount']?.toString() ?? '1') ?? 1),
      notes: map['description']?.toString() ?? map['notes']?.toString() ?? '',
      status: map['status']?.toString() ?? 'SAVED',
      createdAt: map['timestamp'] is int
          ? map['timestamp'] as int
          : (map['created_at'] is int
              ? map['created_at'] as int
              : DateTime.now().millisecondsSinceEpoch),
      latitude: map['latitude'] is num ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] is num ? (map['longitude'] as num).toDouble() : null,
      location: map['location']?.toString(),
      syncPending: map['status'] == 'PENDING' || map['status'] == 'QUEUED' || map['sync_pending'] == 1,
      severity: map['severity']?.toString() ?? 'HIGH',
      senderDeviceId: map['sender_device_id']?.toString() ??
          map['senderDeviceId']?.toString() ??
          map['sender_id']?.toString(),
      isLocal: map['is_local'] == 1 ||
          map['is_local'] == true ||
          map['isLocal'] == true,
    );
  }
}
