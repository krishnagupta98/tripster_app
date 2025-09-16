// lib/models/point_of_interest_model.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum PoiCategory { attraction, cafe, park }

class PointOfInterest {
  final String name;
  final PoiCategory category;
  final LatLng coordinates;

  PointOfInterest({
    required this.name,
    required this.category,
    required this.coordinates,
  });

  IconData get icon {
    switch (category) {
      case PoiCategory.attraction:
        return Icons.tour;
      case PoiCategory.cafe:
        return Icons.local_cafe;
      case PoiCategory.park:
        return Icons.park;
    }
  }
}