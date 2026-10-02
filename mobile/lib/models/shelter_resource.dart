/// Shelter and Resource Hub information
class ShelterResource {
  final String id;
  final String name;
  final double distance; // in km
  final String openStatus; // 'OPEN', 'FULL', 'CLOSED'
  final int capacity; // current occupants
  final int maxCapacity;
  final List<String> supplies; // ['Food', 'Water', 'Medical', 'Power', 'Blankets']
  final String? address;
  final double? latitude;
  final double? longitude;

  const ShelterResource({
    required this.id,
    required this.name,
    required this.distance,
    required this.openStatus,
    required this.capacity,
    required this.maxCapacity,
    required this.supplies,
    this.address,
    this.latitude,
    this.longitude,
  });

  bool get isOpen => openStatus.toUpperCase() == 'OPEN';
  bool get isFull => openStatus.toUpperCase() == 'FULL' || capacity >= maxCapacity;
  int get availableSpots => (maxCapacity - capacity).clamp(0, maxCapacity);

  ShelterResource copyWith({
    String? id,
    String? name,
    double? distance,
    String? openStatus,
    int? capacity,
    int? maxCapacity,
    List<String>? supplies,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return ShelterResource(
      id: id ?? this.id,
      name: name ?? this.name,
      distance: distance ?? this.distance,
      openStatus: openStatus ?? this.openStatus,
      capacity: capacity ?? this.capacity,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      supplies: supplies ?? this.supplies,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'distance': distance,
      'open_status': openStatus,
      'capacity': capacity,
      'max_capacity': maxCapacity,
      'supplies': supplies.join(','),
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory ShelterResource.fromMap(Map<String, dynamic> map) {
    List<String> parsedSupplies = [];
    if (map['supplies'] is List) {
      parsedSupplies = (map['supplies'] as List).map((e) => e.toString()).toList();
    } else if (map['supplies'] is String && (map['supplies'] as String).isNotEmpty) {
      parsedSupplies = (map['supplies'] as String)
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return ShelterResource(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      distance: map['distance'] is num
          ? (map['distance'] as num).toDouble()
          : (double.tryParse(map['distance']?.toString() ?? '0.0') ?? 0.0),
      openStatus: map['open_status']?.toString() ?? map['openStatus']?.toString() ?? 'OPEN',
      capacity: map['capacity'] is int
          ? map['capacity'] as int
          : (int.tryParse(map['capacity']?.toString() ?? '0') ?? 0),
      maxCapacity: map['max_capacity'] is int
          ? map['max_capacity'] as int
          : (int.tryParse(map['maxCapacity']?.toString() ?? '100') ?? 100),
      supplies: parsedSupplies,
      address: map['address']?.toString(),
      latitude: map['latitude'] is num ? (map['latitude'] as num).toDouble() : double.tryParse(map['latitude']?.toString() ?? ''),
      longitude: map['longitude'] is num ? (map['longitude'] as num).toDouble() : double.tryParse(map['longitude']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory ShelterResource.fromJson(Map<String, dynamic> json) => ShelterResource.fromMap(json);
}
