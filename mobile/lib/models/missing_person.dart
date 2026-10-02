/// Missing Person Alert & Offline Bulletin
class MissingPerson {
  final String id;
  final String name;
  final int age;
  final String description;
  final String lastSeenLocation;
  final DateTime lastSeenTime;
  final String? photoPath;
  final String status; // 'SEARCHING', 'SIGHTED', 'FOUND'
  final String? contactPhone;

  const MissingPerson({
    required this.id,
    required this.name,
    required this.age,
    required this.description,
    required this.lastSeenLocation,
    required this.lastSeenTime,
    this.photoPath,
    this.status = 'SEARCHING',
    this.contactPhone,
  });

  bool get isFound => status.toUpperCase() == 'FOUND';
  bool get isSighted => status.toUpperCase() == 'SIGHTED';

  MissingPerson copyWith({
    String? id,
    String? name,
    int? age,
    String? description,
    String? lastSeenLocation,
    DateTime? lastSeenTime,
    String? photoPath,
    String? status,
    String? contactPhone,
  }) {
    return MissingPerson(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      description: description ?? this.description,
      lastSeenLocation: lastSeenLocation ?? this.lastSeenLocation,
      lastSeenTime: lastSeenTime ?? this.lastSeenTime,
      photoPath: photoPath ?? this.photoPath,
      status: status ?? this.status,
      contactPhone: contactPhone ?? this.contactPhone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'description': description,
      'last_seen_location': lastSeenLocation,
      'last_seen_time': lastSeenTime.millisecondsSinceEpoch,
      'photo_path': photoPath,
      'status': status,
      'contact_phone': contactPhone,
    };
  }

  factory MissingPerson.fromMap(Map<String, dynamic> map) {
    return MissingPerson(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      age: map['age'] is int ? map['age'] as int : (int.tryParse(map['age']?.toString() ?? '0') ?? 0),
      description: map['description']?.toString() ?? '',
      lastSeenLocation: map['last_seen_location']?.toString() ?? map['lastSeenLocation']?.toString() ?? '',
      lastSeenTime: map['last_seen_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_seen_time'] as int)
          : (map['lastSeenTime'] != null
              ? DateTime.tryParse(map['lastSeenTime'].toString()) ?? DateTime.now()
              : DateTime.now()),
      photoPath: map['photo_path']?.toString() ?? map['photoPath']?.toString(),
      status: map['status']?.toString() ?? 'SEARCHING',
      contactPhone: map['contact_phone']?.toString() ?? map['contactPhone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory MissingPerson.fromJson(Map<String, dynamic> json) => MissingPerson.fromMap(json);
}
