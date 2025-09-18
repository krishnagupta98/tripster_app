// lib/widgets/explore_map_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/point_of_interest_model.dart';
import 'package:flutter_application_1/models/trip_model.dart';
import 'package:flutter_application_1/services/database_helper.dart';
import 'package:flutter_application_1/services/location_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_application_1/services/timeline_service.dart';
import 'package:flutter_application_1/models/timeline_event.dart';
import 'package:flutter_application_1/trip_details_page.dart';
import 'dart:async';
import 'explore_colors.dart' as exploreColors;
import 'dart:math' as math;


class ExploreMapView extends StatefulWidget {
  const ExploreMapView({super.key});

  @override
  State<ExploreMapView> createState() => _ExploreMapViewState();
}

class _ExploreMapViewState extends State<ExploreMapView> {
  final MapController _mapController = MapController();
  PointOfInterest? _selectedPoi;
  final TimelineService _timelineService = TimelineService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final LocationService _locationService = LocationService();
  StreamSubscription<List<TimelineEvent>>? _eventSubscription;
  List<TimelineEvent> _events = [];
  List<Trip> _allTrips = [];
  List<PointOfInterest> _allPois = [];
  LatLng? _currentLocation;
  String _searchQuery = '';

  Future<void> _loadTrips() async {
    _allTrips = await _dbHelper.getAllTrips();
    _allTrips.sort((a, b) => b.plannedDate.compareTo(a.plannedDate));
    if (mounted) setState(() {});
  }

  Future<void> _loadPois() async {
    _allPois = await _dbHelper.getAllPois();
    if (_allPois.isEmpty) {
      // Seed mock data
      final mockPois = [
        PointOfInterest(
          name: "Local Cafe",
          category: PoiCategory.cafe,
          coordinates: LatLng(37.7749, -122.4194),
          imageUrl: 'https://via.placeholder.com/300x200?text=Cafe',
          rating: 4.5,
          description: 'Cozy spot for coffee',
        ),
        PointOfInterest(
          name: "Street Food Stall",
          category: PoiCategory.cafe,
          coordinates: LatLng(37.7849, -122.4094),
          imageUrl: 'https://via.placeholder.com/300x200?text=Food',
          rating: 4.0,
          description: 'Delicious local eats',
        ),
        PointOfInterest(
          name: "Hidden Alley Art",
          category: PoiCategory.attraction,
          coordinates: LatLng(37.7649, -122.4294),
          imageUrl: 'https://via.placeholder.com/300x200?text=Art',
          rating: 4.8,
          description: 'Secret street art',
        ),
        PointOfInterest(
          name: "Vintage Bookstore",
          category: PoiCategory.attraction,
          coordinates: LatLng(37.7949, -122.3994),
          imageUrl: 'https://via.placeholder.com/300x200?text=Books',
          rating: 4.7,
          description: 'Rare finds await',
        ),
        PointOfInterest(
          name: "City Park",
          category: PoiCategory.park,
          coordinates: LatLng(37.7549, -122.4394),
          imageUrl: 'https://via.placeholder.com/300x200?text=Park',
          rating: 4.6,
          description: 'Relax in nature',
        ),
        PointOfInterest(
          name: "Riverside Trail",
          category: PoiCategory.park,
          coordinates: LatLng(37.8049, -122.3894),
          imageUrl: 'https://via.placeholder.com/300x200?text=Trail',
          rating: 4.9,
          description: 'Scenic walking path',
        ),
        PointOfInterest(
          name: "Eiffel Tower",
          category: PoiCategory.attraction,
          coordinates: LatLng(48.8584, 2.2945),
          imageUrl: 'https://via.placeholder.com/300x200?text=Eiffel',
          rating: 5.0,
          description: 'Iconic landmark',
        ),
        PointOfInterest(
          name: "Statue of Liberty",
          category: PoiCategory.attraction,
          coordinates: LatLng(40.6892, -74.0445),
          imageUrl: 'https://via.placeholder.com/300x200?text=Liberty',
          rating: 4.9,
          description: 'Symbol of freedom',
        ),
        PointOfInterest(
          name: "Taj Mahal",
          category: PoiCategory.attraction,
          coordinates: LatLng(27.1751, 78.0421),
          imageUrl: 'https://via.placeholder.com/300x200?text=Taj',
          rating: 5.0,
          description: 'Architectural marvel',
        ),
      ];
      for (final poi in mockPois) {
        await _dbHelper.insertPoi(poi);
      }
      _allPois = mockPois;
    }
    if (mounted) setState(() {});
  }

  List<dynamic> get _filteredRecommendations {
    List<dynamic> recommendations = [];
    List<PointOfInterest> filteredPois = [];
    final currentPos = _currentLocation ?? (_events.isNotEmpty && _events.first.coordinates != null ? _events.first.coordinates : null);

    if (currentPos != null) {
      Map<PointOfInterest, double> minDistances = {};
      for (final poi in _allPois) {
        final distanceKm = Distance().as(LengthUnit.Kilometer, currentPos, poi.coordinates);
        if (distanceKm > 50) continue;

        if (true) {  // No category or distance filters
          minDistances[poi] = math.min(minDistances[poi] ?? double.infinity, distanceKm);
        }
      }
      // Apply search filter and sort by min distance
      var poiWithDist = minDistances.entries
          .where((entry) {
            final poi = entry.key;
            return _searchQuery.isEmpty || poi.name.toLowerCase().contains(_searchQuery.toLowerCase());
          })
          .toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      filteredPois = poiWithDist.map((e) => e.key).toList();  // Show all, not just top 5
    } else if (_searchQuery.isNotEmpty) {
      // Fallback search
      final defaultCenter = LatLng(37.7749, -122.4194);
      filteredPois = _allPois.where((poi) {
        bool searchMatch = poi.name.toLowerCase().contains(_searchQuery.toLowerCase());
        return searchMatch;
      }).toList()
        ..sort((a, b) => Distance().as(LengthUnit.Meter, a.coordinates, defaultCenter)
            .compareTo(Distance().as(LengthUnit.Meter, b.coordinates, defaultCenter)));
    }

    // Filter Trips
    List<Trip> filteredTrips = [];
    if (_searchQuery.isNotEmpty) {
      filteredTrips = _allTrips.where((trip) =>
        trip.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        trip.location.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    } else {
      filteredTrips = _allTrips.take(3).toList();
    }

    // Combine
    recommendations.addAll(filteredPois);
    recommendations.addAll(filteredTrips);

    return recommendations;
  }

  @override
  void initState() {
    super.initState();
    _loadTrips();
    _loadPois();
    _loadCurrentLocation();
    _initializeTimeline();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      print('Error loading current location: $e');
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _timelineService.dispose();
    super.dispose();
  }

  Future<void> _initializeTimeline() async {
    await _timelineService.initialize();
    _eventSubscription = _timelineService.timelineStream.listen((events) {
      if (mounted) {
        setState(() {
          _events = events;
        });
      }
    });
    await _timelineService.updateTimelineNow();
  }

  Future<void> _refreshTimeline() async {
    await _timelineService.updateTimelineNow();
  }

  void _onPoiTap(PointOfInterest poi) {
    setState(() {
      _selectedPoi = poi;
    });
    _mapController.move(poi.coordinates, 15.0);
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    // Current location marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.my_location, color: Colors.white, size: 20),
          ),
        ),
      );
    }
    // Timeline event markers
    for (final event in _events) {
      if (event.coordinates != null) {
        markers.add(
          Marker(
            point: event.coordinates!,
            width: 30,
            height: 30,
            child: Icon(Icons.location_on, color: Colors.blue, size: 30),
          ),
        );
      }
    }
    // Filtered POI markers
    final filteredPois = _filteredRecommendations.whereType<PointOfInterest>().toList();
    for (final poi in filteredPois) {
      markers.add(
        Marker(
          point: poi.coordinates,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _onPoiTap(poi),
            child: Container(
              decoration: BoxDecoration(
                color: _getPoiColor(poi.category),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(poi.icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  Color _getPoiColor(PoiCategory category) {
    switch (category) {
      case PoiCategory.cafe:
        return exploreColors.kGreen;
      case PoiCategory.attraction:
        return kPrimaryBlue;
      case PoiCategory.park:
        return Colors.orange;
      default:
        return kDarkBlue;
    }
  }

  Widget _buildCategorySection(String title, List<PointOfInterest> pois) {
    if (pois.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kDarkBlue,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: pois.length,
            itemBuilder: (context, index) {
              final poi = pois[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: () => _onPoiTap(poi),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: SizedBox(
                      width: 160,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: Image.network(
                              poi.imageUrl ?? 'https://via.placeholder.com/160x100',
                              height: 100,
                              width: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 100,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  poi.name,
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  poi.description ?? '',
                                  style: GoogleFonts.poppins(fontSize: 12, color: exploreColors.kGreyText),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 16, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${poi.rating ?? 0.0}',
                                      style: GoogleFonts.poppins(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTripsSection(List<Trip> trips) {
    if (trips.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Matching Trips',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kDarkBlue,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TripDetailsPage(trip: trip),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: SizedBox(
                      width: 160,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.trip_origin, size: 32, color: kPrimaryBlue),
                            const SizedBox(height: 8),
                            Text(
                              trip.name,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              trip.location,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: exploreColors.kGreyText,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final recommendations = _filteredRecommendations;
    final nearbyEats = recommendations.where((r) => r is PointOfInterest && r.category == PoiCategory.cafe).cast<PointOfInterest>().toList();
    final hiddenGems = recommendations.where((r) => r is PointOfInterest && r.category == PoiCategory.attraction).cast<PointOfInterest>().toList();
    final outdoorSpots = recommendations.where((r) => r is PointOfInterest && r.category == PoiCategory.park).cast<PointOfInterest>().toList();
    final matchingTrips = recommendations.where((r) => r is Trip).cast<Trip>().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore', style: TextStyle(color: Colors.white)),
        backgroundColor: kPrimaryBlue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshTimeline,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // No filters
            // Dynamic sections
            recommendations.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No recommendations yet. Start exploring!',
                      style: GoogleFonts.poppins(color: exploreColors.kGreyText),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 1,  // Single item for all sections
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          if (matchingTrips.isNotEmpty) _buildTripsSection(matchingTrips),
                          if (nearbyEats.isNotEmpty) _buildCategorySection('Nearby Eats', nearbyEats),
                          if (hiddenGems.isNotEmpty) _buildCategorySection('Hidden Gems', hiddenGems),
                          if (outdoorSpots.isNotEmpty) _buildCategorySection('Outdoor Spots', outdoorSpots),
                        ],
                      );
                    },
                  ),
            // Map
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation ?? (_events.isNotEmpty && _events.first.coordinates != null ? _events.first.coordinates! : const LatLng(37.7749, -122.4194)),
                      initialZoom: 12.0,
                      minZoom: 2.0,
                      maxZoom: 18.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.flutter_application_1',
                      ),
                      MarkerLayer(markers: _buildMarkers()),
                    ],
                  ),
                  _buildMapControls(),
                  _buildPoiDetailsCard(),
                ],
              ),
            ),
          ],
        ),
      ),
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
            onPressed: () => _mapController.move(_mapController.center, _mapController.zoom + 1),
            backgroundColor: Colors.white,
            child: const Icon(Icons.add, color: kDarkBlue),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'zoomOut',
            onPressed: () => _mapController.move(_mapController.center, _mapController.zoom - 1),
            backgroundColor: Colors.white,
            child: const Icon(Icons.remove, color: kDarkBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildPoiDetailsCard() {
    if (_selectedPoi == null) return const SizedBox.shrink();

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      bottom: 20,
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
                child: Icon(_selectedPoi!.icon, color: kPrimaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedPoi!.name,
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: kDarkBlue),
                    ),
                    Text(
                      _selectedPoi!.description ?? '',
                      style: GoogleFonts.poppins(fontSize: 12, color: exploreColors.kGreyText),
                    ),
                    if (_selectedPoi!.rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('${_selectedPoi!.rating}'),
                        ],
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: exploreColors.kGreyText),
                onPressed: () => setState(() => _selectedPoi = null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}