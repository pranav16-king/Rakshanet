class ShelterModel {
  final String id;
  final String name;
  final String type;
  final String distance;
  final int capacity;
  final int occupancy;
  final String lastUpdated;
  final List<String> amenities;

  const ShelterModel({
    required this.id,
    required this.name,
    required this.type,
    required this.distance,
    required this.capacity,
    required this.occupancy,
    required this.lastUpdated,
    required this.amenities,
  });

  double get occupancyRate => capacity == 0 ? 0 : occupancy / capacity;
}
