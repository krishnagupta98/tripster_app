// lib/widgets/explore_map_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/point_of_interest_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

const Color kPrimaryBlue = Color(0xFF1E40AF);
const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kGreyText = Color(0xFF475569);

class ExploreMapView extends StatefulWidget {
  const ExploreMapView({super.key});

  @override
  State<ExploreMapView> createState() => _ExploreMapViewState();
}

class _ExploreMapViewState extends State<ExploreMapView> {
  final MapController _mapController = MapController();
  PointOfInterest? _selectedPoi;

  // Data for major world monuments
  final List<PointOfInterest> _worldMonuments = [
    PointOfInterest(name: "Eiffel Tower", category: PoiCategory.attraction, coordinates: LatLng(48.8584, 2.2945)),
    PointOfInterest(name: "Statue of Liberty", category: PoiCategory.attraction, coordinates: LatLng(40.6892, -74.0445)),
    PointOfInterest(name: "Taj Mahal", category: PoiCategory.attraction, coordinates: LatLng(27.1751, 78.0421)),
    PointOfInterest(name: "Colosseum", category: PoiCategory.attraction, coordinates: LatLng(41.8902, 12.4922)),
    PointOfInterest(name: "Great Wall of China", category: PoiCategory.attraction, coordinates: LatLng(40.4319, 116.5704)),
    PointOfInterest(name: "Machu Picchu", category: PoiCategory.attraction, coordinates: LatLng(-13.1631, -72.5450)),
    PointOfInterest(name: "Sydney Opera House", category: PoiCategory.attraction, coordinates: LatLng(-33.8568, 151.2153)),
    PointOfInterest(name: "Pyramids of Giza", category: PoiCategory.attraction, coordinates: LatLng(29.9792, 31.1342)),
  ];

  void _onMarkerTap(PointOfInterest poi) {
    setState(() {
      _selectedPoi = poi;
    });
    _mapController.move(poi.coordinates, 13.0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(25, 0),
            initialZoom: 2.0,
            minZoom: 2.0,
            maxZoom: 18.0,
            // ADD THIS TO ENABLE ZOOMING AND OTHER GESTURES
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.flutter_application_1',
            ),
            MarkerLayer(
              markers: _worldMonuments.map((poi) {
                return Marker(
                  point: poi.coordinates,
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _onMarkerTap(poi),
                    child: Tooltip(
                      message: poi.name,
                      child: Container(
                        decoration: BoxDecoration(
                          color: kPrimaryBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
                        ),
                        child: Icon(poi.icon, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        _buildMapControls(),
        _buildPoiDetailsCard(),
      ],
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        children: [
          FloatingActionButton.small(
            heroTag: 'zoomIn',
            onPressed: () {
              _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.add, color: kDarkBlue),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'zoomOut',
            onPressed: () {
               _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.remove, color: kDarkBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildPoiDetailsCard() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      bottom: _selectedPoi != null ? 20 : -150,
      left: 20,
      right: 20,
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: kPrimaryBlue.withOpacity(0.1),
                child: Icon(_selectedPoi?.icon ?? Icons.help_outline, color: kPrimaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedPoi?.name ?? "No location selected",
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: kDarkBlue),
                    ),
                    Text(
                      "World Landmark",
                      style: GoogleFonts.poppins(fontSize: 12, color: kGreyText),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: kGreyText),
                onPressed: () => setState(() => _selectedPoi = null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}