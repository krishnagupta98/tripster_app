// lib/services/location_service.dart
import 'dart:async';
import 'package:flutter_application_1/services/database_helper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  // NEW: A subscription to manage the background location stream
  StreamSubscription<Position>? _positionStreamSubscription;

  /// Checks if location permission is granted.
  Future<bool> hasPermission() async {
    final status = await Geolocator.checkPermission();
    return status == LocationPermission.always || status == LocationPermission.whileInUse;
  }

  /// Requests location permission if not already granted.
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Gets the current location if permission is granted.
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPerm = await hasPermission();
      if (!hasPerm) {
        final perm = await requestPermission();
        if (perm != LocationPermission.always && perm != LocationPermission.whileInUse) {
          return null;
        }
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Stores the current location in the database.
  Future<void> storeCurrentLocation() async {
    final position = await getCurrentLocation();
    if (position != null) {
      await _savePosition(position);
    }
  }

  /// Checks if location services are enabled.
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// FIXED: This method now correctly calls the permission_handler function.
  Future<void> openPermissionSettings() async {
    await openAppSettings();
  }

  // --- NEW: BACKGROUND TRACKING METHODS ---

  /// Starts listening for location updates in the background.
  Future<void> startLocationTracking() async {
    // Stop any existing streams to avoid duplicates
    await stopLocationTracking();

    final hasPerm = await hasPermission();
    if (!hasPerm) {
      print("Location permission not granted. Cannot start tracking.");
      return;
    }

    // Define settings for how often to get updates
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100, // Update every 100 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
      .listen((Position position) {
        print("New location point received: ${position.latitude}, ${position.longitude}");
        _savePosition(position);
      });
  }

  /// Stops listening for background location updates.
  Future<void> stopLocationTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Helper method to save a position to the database
  Future<void> _savePosition(Position position) async {
    final point = {
      'timestamp': position.timestamp?.millisecondsSinceEpoch,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
    };
    await _dbHelper.insertLocationPoint(point);
  }
}