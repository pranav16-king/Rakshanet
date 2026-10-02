/// Civilian / Volunteer User Profile for RakshaNet
class UserProfile {
  final String id;
  final String name;
  final String deviceId; // Canonical device identifier, e.g. SR-284739
  final String bloodGroup;
  final String emergencyContact;
  final String medicalNotes;
  final String language; // e.g. 'en', 'hi', 'ta'
  final bool isRegistered;
  final int? age;
  final int peopleHelped;
  final int messagesRelayed;
  final int sosForwarded;
  final int missingFound;
  final int createdAt; // Milliseconds since epoch
  final int updatedAt; // Milliseconds since epoch

  UserProfile({
    required this.id,
    required this.name,
    String? deviceId,
    String? meshId,
    this.bloodGroup = '',
    String? emergencyContact,
    String? medicalNotes,
    String? language,
    String? preferredLanguage,
    this.isRegistered = false,
    this.age,
    this.peopleHelped = 0,
    this.messagesRelayed = 0,
    this.sosForwarded = 0,
    this.missingFound = 0,
    dynamic createdAt,
    dynamic updatedAt,
  })  : deviceId = (deviceId != null && deviceId.isNotEmpty)
            ? deviceId
            : (meshId != null && meshId.isNotEmpty)
                ? meshId
                : 'SR-000000',
        emergencyContact = emergencyContact ?? '',
        medicalNotes = medicalNotes ?? '',
        language = (language != null && language.isNotEmpty)
            ? language
            : (preferredLanguage != null && preferredLanguage.isNotEmpty)
                ? preferredLanguage
                : 'en',
        createdAt = (createdAt is int)
            ? createdAt
            : (createdAt is DateTime)
                ? createdAt.millisecondsSinceEpoch
                : DateTime.now().millisecondsSinceEpoch,
        updatedAt = (updatedAt is int)
            ? updatedAt
            : (updatedAt is DateTime)
                ? updatedAt.millisecondsSinceEpoch
                : DateTime.now().millisecondsSinceEpoch;

  /// Alias for backward compatibility with mesh services
  String get meshId => deviceId;

  /// Alias for backward compatibility with settings
  String get preferredLanguage => language;

  DateTime get createdDateTime => DateTime.fromMillisecondsSinceEpoch(createdAt);
  DateTime get updatedDateTime => DateTime.fromMillisecondsSinceEpoch(updatedAt);

  /// Empty default profile (no hardcoded mock data)
  factory UserProfile.defaultMock() => UserProfile.unregistered();

  /// Empty default profile
  factory UserProfile.empty() => UserProfile.unregistered();

  /// Empty unregistered profile
  factory UserProfile.unregistered() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return UserProfile(
      id: 'unregistered',
      name: '',
      deviceId: '',
      language: 'en',
      isRegistered: false,
      peopleHelped: 0,
      messagesRelayed: 0,
      sosForwarded: 0,
      missingFound: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? deviceId,
    String? meshId,
    String? bloodGroup,
    String? emergencyContact,
    String? medicalNotes,
    String? language,
    String? preferredLanguage,
    bool? isRegistered,
    int? age,
    int? peopleHelped,
    int? messagesRelayed,
    int? sosForwarded,
    int? missingFound,
    dynamic createdAt,
    dynamic updatedAt,
  }) {
    int parseTime(dynamic val, int fallback) {
      if (val == null) return fallback;
      if (val is int) return val;
      if (val is DateTime) return val.millisecondsSinceEpoch;
      return fallback;
    }

    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceId: deviceId ?? meshId ?? this.deviceId,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      language: language ?? preferredLanguage ?? this.language,
      isRegistered: isRegistered ?? this.isRegistered,
      age: age ?? this.age,
      peopleHelped: peopleHelped ?? this.peopleHelped,
      messagesRelayed: messagesRelayed ?? this.messagesRelayed,
      sosForwarded: sosForwarded ?? this.sosForwarded,
      missingFound: missingFound ?? this.missingFound,
      createdAt: parseTime(createdAt, this.createdAt),
      updatedAt: parseTime(updatedAt, this.updatedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'device_id': deviceId,
      'blood_group': bloodGroup,
      'emergency_contact': emergencyContact,
      'medical_notes': medicalNotes,
      'language': language,
      'is_registered': isRegistered ? 1 : 0,
      'age': age,
      'people_helped': peopleHelped,
      'messages_relayed': messagesRelayed,
      'sos_forwarded': sosForwarded,
      'missing_found': missingFound,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    int parseTimestamp(dynamic val) {
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? DateTime.now().millisecondsSinceEpoch;
      return DateTime.now().millisecondsSinceEpoch;
    }

    return UserProfile(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      deviceId: map['device_id']?.toString() ?? map['deviceId']?.toString() ?? map['mesh_id']?.toString() ?? '',
      bloodGroup: map['blood_group']?.toString() ?? map['bloodGroup']?.toString() ?? '',
      emergencyContact: map['emergency_contact']?.toString() ?? map['emergencyContact']?.toString() ?? '',
      medicalNotes: map['medical_notes']?.toString() ?? map['medicalNotes']?.toString() ?? '',
      language: map['language']?.toString() ?? map['preferred_language']?.toString() ?? map['preferredLanguage']?.toString() ?? 'en',
      isRegistered: (map['is_registered'] == 1 || map['is_registered'] == true || map['isRegistered'] == true),
      age: map['age'] is int ? map['age'] as int : int.tryParse(map['age']?.toString() ?? ''),
      peopleHelped: map['people_helped'] is int ? map['people_helped'] as int : 0,
      messagesRelayed: map['messages_relayed'] is int ? map['messages_relayed'] as int : 0,
      sosForwarded: map['sos_forwarded'] is int ? map['sos_forwarded'] as int : 0,
      missingFound: map['missing_found'] is int ? map['missing_found'] as int : 0,
      createdAt: parseTimestamp(map['created_at']),
      updatedAt: parseTimestamp(map['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile.fromMap(json);
}
