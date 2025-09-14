// lib/models/trip_model.dart

class Trip {
  final String name; // New field for the trip name
  final String location;
  final String imageUrl;
  final DateTime plannedDate; // This will be our start date
  final DateTime endDate; // New field for the end date
  final String notes;
  final List<String> activities;

  Trip({
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.plannedDate,
    required this.endDate,
    required this.notes,
    required this.activities,
  });
}