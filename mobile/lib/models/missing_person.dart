import 'dart:convert';

/// Citizen or volunteer sighting of a missing individual
class MissingPersonSighting {
  final String reportedBy;
  final String location;
  final DateTime timestamp;
  final String? notes;
  final double? lat;
  final double? lng;
  final String? photoUrl;
  final String? photoPath;

  const MissingPersonSighting({
    required this.reportedBy,
    required this.location,
    required this.timestamp,
    this.notes,
    this.lat,
    this.lng,
    this.photoUrl,
    this.photoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'reported_by': reportedBy,
      'location': location,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'notes': notes,
      'lat': lat,
      'lng': lng,
      'photo_url': photoUrl,
      'photo_path': photoPath,
    };
  }

  factory MissingPersonSighting.fromMap(Map<String, dynamic> map) {
    DateTime ts;
    if (map['timestamp'] is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int);
    } else if (map['timestamp'] is String) {
      ts = DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }

    return MissingPersonSighting(
      reportedBy: map['reported_by']?.toString() ?? map['reportedBy']?.toString() ?? 'Anonymous Citizen',
      location: map['location']?.toString() ?? 'Disaster Zone',
      timestamp: ts,
      notes: map['notes']?.toString(),
      lat: map['lat'] is num ? (map['lat'] as num).toDouble() : double.tryParse(map['lat']?.toString() ?? ''),
      lng: map['lng'] is num ? (map['lng'] as num).toDouble() : double.tryParse(map['lng']?.toString() ?? ''),
      photoUrl: map['photo_url']?.toString() ?? map['photoUrl']?.toString(),
      photoPath: map['photo_path']?.toString() ?? map['photoPath']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory MissingPersonSighting.fromJson(Map<String, dynamic> json) => MissingPersonSighting.fromMap(json);
}

/// Missing Person Alert, Offline Mesh Bulletin & Registry Model
class MissingPerson {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String description;
  final String lastSeenLocation;
  final double? lat;
  final double? lng;
  final DateTime lastSeenTime;
  final DateTime reportedAt;
  final String? photoUrl;
  final String? photoPath;
  final String status; // 'MISSING', 'FOUND', 'SEARCHING', 'SIGHTED'
  final String? contactPhone;
  final String reportedBy;
  final List<MissingPersonSighting> sightings;

  MissingPerson({
    required this.id,
    required this.name,
    required this.age,
    this.gender = 'Unspecified',
    required this.description,
    required this.lastSeenLocation,
    this.lat,
    this.lng,
    DateTime? lastSeenTime,
    DateTime? reportedAt,
    this.photoUrl,
    this.photoPath,
    this.status = 'MISSING',
    this.contactPhone,
    this.reportedBy = 'Anonymous',
    this.sightings = const [],
  })  : lastSeenTime = lastSeenTime ?? (reportedAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        reportedAt = reportedAt ?? (lastSeenTime ?? DateTime.fromMillisecondsSinceEpoch(0));

  bool get isFound => status.toUpperCase() == 'FOUND';
  bool get isSighted => status.toUpperCase() == 'SIGHTED' || sightings.isNotEmpty;

  MissingPerson copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? description,
    String? lastSeenLocation,
    double? lat,
    double? lng,
    DateTime? lastSeenTime,
    DateTime? reportedAt,
    String? photoUrl,
    String? photoPath,
    String? status,
    String? contactPhone,
    String? reportedBy,
    List<MissingPersonSighting>? sightings,
  }) {
    return MissingPerson(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      description: description ?? this.description,
      lastSeenLocation: lastSeenLocation ?? this.lastSeenLocation,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      lastSeenTime: lastSeenTime ?? this.lastSeenTime,
      reportedAt: reportedAt ?? this.reportedAt,
      photoUrl: photoUrl ?? this.photoUrl,
      photoPath: photoPath ?? this.photoPath,
      status: status ?? this.status,
      contactPhone: contactPhone ?? this.contactPhone,
      reportedBy: reportedBy ?? this.reportedBy,
      sightings: sightings ?? this.sightings,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'description': description,
      'last_seen_location': lastSeenLocation,
      'lat': lat,
      'lng': lng,
      'last_seen_time': lastSeenTime.millisecondsSinceEpoch,
      'reported_at': reportedAt.millisecondsSinceEpoch,
      'photo_url': photoUrl,
      'photo_path': photoPath,
      'status': status,
      'contact_phone': contactPhone,
      'reported_by': reportedBy,
      'sightings_json': jsonEncode(sightings.map((s) => s.toMap()).toList()),
    };
  }

  factory MissingPerson.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val, [DateTime? fallback]) {
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? (fallback ?? DateTime.now());
      return fallback ?? DateTime.now();
    }

    final reportedAt = parseDate(map['reported_at'] ?? map['reportedAt'], null);
    final lastSeenTime = parseDate(map['last_seen_time'] ?? map['lastSeenTime'], reportedAt);

    List<MissingPersonSighting> parsedSightings = [];
    final rawSightings = map['sightings'] ?? map['sightings_json'];
    if (rawSightings is List) {
      parsedSightings = rawSightings
          .whereType<Map<String, dynamic>>()
          .map((s) => MissingPersonSighting.fromMap(s))
          .toList();
    } else if (rawSightings is String && rawSightings.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawSightings);
        if (decoded is List) {
          parsedSightings = decoded
              .whereType<Map<String, dynamic>>()
              .map((s) => MissingPersonSighting.fromMap(s))
              .toList();
        }
      } catch (_) {}
    }

    double? parseCoord(dynamic val) {
      if (val is num) return val.toDouble();
      if (val != null) return double.tryParse(val.toString());
      return null;
    }

    return MissingPerson(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      age: map['age'] is int ? map['age'] as int : (int.tryParse(map['age']?.toString() ?? '0') ?? 0),
      gender: map['gender']?.toString() ?? 'Unspecified',
      description: map['description']?.toString() ?? '',
      lastSeenLocation: map['last_seen_location']?.toString() ?? map['lastSeenLocation']?.toString() ?? '',
      lat: parseCoord(map['lat']),
      lng: parseCoord(map['lng']),
      lastSeenTime: lastSeenTime,
      reportedAt: reportedAt,
      photoUrl: map['photo_url']?.toString() ?? map['photoUrl']?.toString(),
      photoPath: map['photo_path']?.toString() ?? map['photoPath']?.toString(),
      status: (map['status']?.toString() ?? 'MISSING').toUpperCase(),
      contactPhone: map['contact_phone']?.toString() ?? map['contactPhone']?.toString(),
      reportedBy: map['reported_by']?.toString() ?? map['reportedBy']?.toString() ?? 'Anonymous',
      sightings: parsedSightings,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory MissingPerson.fromJson(Map<String, dynamic> json) => MissingPerson.fromMap(json);
}
