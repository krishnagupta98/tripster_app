// lib/models/point_of_interest_model.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum PoiCategory { attraction, cafe, park }

class PointOfInterest {
  final int? id;
  final String name;
  final PoiCategory category;
  final LatLng coordinates;
  final String? imageUrl;
  final String? description;
  final double? rating;
  double? distanceFromEvent; // Non-final to allow setting

  PointOfInterest({
    this.id,
    required this.name,
    required this.category,
    required this.coordinates,
    this.imageUrl,
    this.description,
    this.rating,
    this.distanceFromEvent,
  });

  PointOfInterest copyWith({
    int? id,
    String? name,
    PoiCategory? category,
    LatLng? coordinates,
    String? imageUrl,
    String? description,
    double? rating,
    double? distanceFromEvent,
  }) {
    return PointOfInterest(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      coordinates: coordinates ?? this.coordinates,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      distanceFromEvent: distanceFromEvent ?? this.distanceFromEvent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.index,
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
      'image_url': imageUrl,
      'description': description,
      'rating': rating,
      'distance_from_event': distanceFromEvent,
    };
  }

  factory PointOfInterest.fromJson(Map<String, dynamic> json) {
    return PointOfInterest(
      id: json['id'],
      name: json['name'],
      category: PoiCategory.values[json['category']],
      coordinates: LatLng(json['latitude'], json['longitude']),
      imageUrl: json['image_url'],
      description: json['description'],
      rating: json['rating']?.toDouble(),
      distanceFromEvent: json['distance_from_event']?.toDouble(),
    );
  }

  IconData get icon {
    switch (category) {
      case PoiCategory.attraction:
        return Icons.place;
      case PoiCategory.cafe:
        return Icons.local_cafe;
      case PoiCategory.park:
        return Icons.park;
    }
  }
}