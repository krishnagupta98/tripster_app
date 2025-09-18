// lib/models/trip_model.dart

class Trip {
  final int? id;
  final String name; // New field for the trip name
  final String location;
  final double? latitude;
  final double? longitude;
  final String imageUrl;
  final DateTime plannedDate; // This will be our start date
  final DateTime endDate; // New field for the end date
  final String notes;
  final List<String> activities;
  final String status;

  Trip({
    this.id,
    required this.name,
    required this.location,
    this.latitude,
    this.longitude,
    required this.imageUrl,
    required this.plannedDate,
    required this.endDate,
    required this.notes,
    required this.activities,
    this.status = 'planned',
  });

  Trip copyWith({
    int? id,
    String? name,
    String? location,
    double? latitude,
    double? longitude,
    String? imageUrl,
    DateTime? plannedDate,
    DateTime? endDate,
    String? notes,
    List<String>? activities,
    String? status,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      plannedDate: plannedDate ?? this.plannedDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      activities: activities ?? this.activities,
      status: status ?? this.status,
    );
  }
}