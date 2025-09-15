// lib/widgets/previous_trips_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/previous_trip_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

const Color kPrimaryBlue = Color(0xFF1E40AF);

class PreviousTripsMap extends StatefulWidget {
  final List<PreviousTrip> previousTrips;
  const PreviousTripsMap({super.key, required this.previousTrips});

  @override
  State<PreviousTripsMap> createState() => _PreviousTripsMapState();
}

class _PreviousTripsMapState extends State<PreviousTripsMap> {
  final List<Marker> _markers = [];
  final List<LatLng> _routeCoordinates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateMapData();
  }

  Future<void> _generateMapData() async {
    for (var trip in widget.previousTrips) {
      try {
        List<Location> locations = await locationFromAddress(trip.baseTrip.location);
        if (locations.isNotEmpty) {
          final latLng = LatLng(locations.first.latitude, locations.first.longitude);
          _routeCoordinates.add(latLng);

          _markers.add(
            Marker(
              point: latLng,
              width: 80,
              height: 80,
              child: const Icon(
                Icons.location_pin,
                size: 40,
                color: kPrimaryBlue,
              ),
            ),
          );
        }
      } catch (e) {
        print("Could not geocode ${trip.baseTrip.location}: $e");
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : FlutterMap(
            options: MapOptions(
              initialCenter: _routeCoordinates.isNotEmpty ? _routeCoordinates.first : const LatLng(20.5937, 78.9629), // Default to India
              initialZoom: 4,
            ),
            children: [
              // Layer 1: The map tiles from OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_application_1', // Your app's package name
              ),
              // Layer 2: The route line
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routeCoordinates,
                    color: kPrimaryBlue,
                    strokeWidth: 3,
                  ),
                ],
              ),
              // Layer 3: The location markers
              MarkerLayer(
                markers: _markers,
              ),
            ],
          );
  }
}