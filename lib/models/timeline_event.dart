// lib/models/timeline_event.dart

import 'dart:convert';
import 'package:latlong2/latlong.dart';

class TimelineEvent {
  final int? id;
  final DateTime time;
  final String title;
  final String description;
  final String? location;
  final LatLng? coordinates;
  final String? imageUrl;
  final int? tripId;
  final String eventType; // 'arrived', 'traveled', 'location_update'
  final String? travelMode;
  final double? distance;
  final int? duration; // duration in ms for stay

  TimelineEvent({
    this.id,
    required this.time,
    required this.title,
    required this.description,
    this.location,
    this.coordinates,
    this.imageUrl,
    this.tripId,
    required this.eventType,
    this.travelMode,
    this.distance,
    this.duration,
  });

  TimelineEvent copyWith({
    int? id,
    DateTime? time,
    String? title,
    String? description,
    String? location,
    LatLng? coordinates,
    String? imageUrl,
    int? tripId,
    String? eventType,
    String? travelMode,
    double? distance,
    int? duration,
  }) {
    return TimelineEvent(
      id: id ?? this.id,
      time: time ?? this.time,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      coordinates: coordinates ?? this.coordinates,
      imageUrl: imageUrl ?? this.imageUrl,
      tripId: tripId ?? this.tripId,
      eventType: eventType ?? this.eventType,
      travelMode: travelMode ?? this.travelMode,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time.millisecondsSinceEpoch,
      'title': title,
      'description': description,
      'location': location,
      'latitude': coordinates?.latitude,
      'longitude': coordinates?.longitude,
      'image_url': imageUrl,
      'trip_id': tripId,
      'event_type': eventType,
      'travel_mode': travelMode,
      'distance': distance,
      'duration': duration,
    };
  }

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id'],
      time: DateTime.fromMillisecondsSinceEpoch(json['time']),
      title: json['title'],
      description: json['description'],
      location: json['location'],
      coordinates: json['latitude'] != null && json['longitude'] != null
          ? LatLng(json['latitude'], json['longitude'])
          : null,
      imageUrl: json['image_url'],
      tripId: json['trip_id'],
      eventType: json['event_type'],
      travelMode: json['travel_mode'],
      distance: json['distance']?.toDouble(),
      duration: json['duration'],
    );
  }
}