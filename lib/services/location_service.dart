import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'database_helper.dart';

class LocationService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Checks if location permission is granted.
  Future<bool> hasPermission() async {
    final status = await Geolocator.checkPermission();
    return status == LocationPermission.always || status == LocationPermission.whileInUse;
  }

  /// Requests location permission if not already granted.
  Future<LocationPermission> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission;
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
      print('Error getting location: $e'); // Replace with proper logging
      return null;
    }
  }

  /// Stores the current location in the database.
  Future<void> storeCurrentLocation() async {
    final position = await getCurrentLocation();
    if (position != null) {
      final point = {
        'timestamp': position.timestamp.millisecondsSinceEpoch,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      };
      await _dbHelper.insertLocationPoint(point);
    }
  }

  /// Checks if location services are enabled.
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Opens app settings for location permissions.
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}