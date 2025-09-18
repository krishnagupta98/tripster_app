// lib/widgets/explore_map_view.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_application_1/models/trip_model.dart';
import 'package:flutter_application_1/services/database_helper.dart';
import 'package:flutter_application_1/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_application_1/services/timeline_service.dart';
import 'package:flutter_application_1/models/timeline_event.dart';
import 'dart:async';
import 'package:flutter_application_1/models/point_of_interest_model.dart';
import 'package:flutter_application_1/models/previous_trip_model.dart';
import 'explore_colors.dart' as explore_colors;
import 'package:flutter_application_1/trip_details_page.dart';
import 'package:flutter_application_1/previous_trips_details_page.dart';

class SearchResult {
  final String type; // 'poi', 'trip', 'prev_trip'
  final dynamic item;
  final double relevance;
  SearchResult({
    required this.type,
    required this.item,
    required this.relevance,
  });
}

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
  late List<TimelineEvent> _events;
  late List<Trip> _allTrips;
  late List<PointOfInterest> _allPois;
  late List<PreviousTrip> _allPreviousTrips;
  LatLng? _currentLocation;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _events = [];
    _allTrips = [];
    _allPois = [];
    _allPreviousTrips = [];
    _loadData();
    _eventSubscription = _timelineService.timelineStream.listen((events) {
      if (mounted) {
        setState(() {
          _events = events;
        });
      }
      _updateCurrentLocation();
    });
    _locationService.getCurrentLocation().then((location) {
      if (mounted && location != null) {
        final latLng = LatLng(location.latitude, location.longitude);
        setState(() {
          _currentLocation = latLng;
        });
        _mapController.move(latLng, 13.0);
      }
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _timelineService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadTrips(),
      _loadPois(),
      _loadPreviousTrips(),
    ]);
    _updateCurrentLocation();
  }
  
  Future<void> _loadPreviousTrips() async {
    _allPreviousTrips = await _dbHelper.getPreviousTrips();
    if (mounted) setState(() {});
  }

  Future<void> _loadTrips() async {
    _allTrips = await _dbHelper.getAllTrips();
    _allTrips.sort((a, b) => b.plannedDate.compareTo(a.plannedDate));
    if (mounted) setState(() {});
  }

  Future<void> _loadPois() async {
    _allPois = await _dbHelper.getAllPois();
    if (_allPois.isEmpty) {
      // Seed mock data if database is empty
      final mockPois = [
        PointOfInterest(name: "Local Cafe", category: PoiCategory.cafe, coordinates: const LatLng(37.7749, -122.4194), imageUrl: 'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?w=500', rating: 4.5, description: 'Cozy spot for single-origin coffee and pastries.'),
        PointOfInterest(name: "City Park", category: PoiCategory.park, coordinates: const LatLng(37.7549, -122.4394), imageUrl: 'https://images.unsplash.com/photo-1597852074332-9311b3e155b9?w=500', rating: 4.6, description: 'A beautiful green space perfect for picnics and relaxation.'),
        PointOfInterest(name: "Hidden Alley Art", category: PoiCategory.attraction, coordinates: const LatLng(37.7649, -122.4294), imageUrl: 'https://images.unsplash.com/photo-1558899478-43b378038b8a?w=500', rating: 4.8, description: 'Discover a vibrant collection of secret street art murals.'),
        PointOfInterest(name: "Taj Mahal", category: PoiCategory.attraction, coordinates: const LatLng(27.1751, 78.0421), imageUrl: 'https://images.unsplash.com/photo-1564507592333-c60657eea523?w=500', rating: 5.0, description: 'An immense mausoleum of white marble, an icon of Mughal architecture.'),
      ];
      for (final poi in mockPois) {
        await _dbHelper.insertPoi(poi);
      }
      _allPois = mockPois;
    }
    if (mounted) setState(() {});
  }

  void _updateCurrentLocation() {
    if (_currentLocation == null && _events.isNotEmpty && _events.first.coordinates != null) {
      if (mounted) {
        setState(() {
          _currentLocation = _events.first.coordinates;
        });
      }
    }
  }

  List<PointOfInterest> get _filteredPois {
    if (_searchQuery.isEmpty) return _allPois.take(10).toList();
    final query = _searchQuery.toLowerCase();
    final currentPos = _currentLocation ?? const LatLng(37.7749, -122.4194);
    final filtered = <PointOfInterest>[];
    for (final poi in _allPois) {
      final distanceKm = const Distance().as(LengthUnit.Kilometer, currentPos, poi.coordinates);
      if (distanceKm <= 50) {
        bool matches = (poi.name?.toLowerCase() ?? '').contains(query) ||
                       (poi.description?.toLowerCase() ?? '').contains(query);
        if (matches) {
          filtered.add(poi);
        }
      }
    }
    filtered.sort((a, b) {
      final distA = const Distance().as(LengthUnit.Kilometer, currentPos, a.coordinates);
      final distB = const Distance().as(LengthUnit.Kilometer, currentPos, b.coordinates);
      return distA.compareTo(distB);
    });
    return filtered.take(10).toList();
  }
  
  List<SearchResult> get _searchResults {
    if (_searchQuery.isEmpty) return [];
    final query = _searchQuery.toLowerCase();
    final results = <SearchResult>[];
    final currentPos = _currentLocation ?? const LatLng(37.7749, -122.4194);
  
    // POIs
    for (final poi in _allPois) {
      final distKm = const Distance().as(LengthUnit.Kilometer, currentPos, poi.coordinates);
      if (distKm <= 50) {
        double relevance = 0.0;
        if ((poi.name?.toLowerCase() ?? '').contains(query)) relevance += 1.0;
        if ((poi.description?.toLowerCase() ?? '').contains(query)) relevance += 0.5;
        if (relevance > 0) {
          relevance -= (distKm / 100).clamp(0.0, 0.5); // Penalize distance
          results.add(SearchResult(type: 'poi', item: poi, relevance: relevance));
        }
      }
    }
  
    // Trips
    for (final trip in _allTrips) {
      double relevance = 0.0;
      if (trip.name.toLowerCase().contains(query)) relevance += 1.0;
      if (trip.location.toLowerCase().contains(query)) relevance += 0.8;
      if (trip.notes.toLowerCase().contains(query)) relevance += 0.5;
      final actsStr = trip.activities.join(' ').toLowerCase();
      if (actsStr.contains(query)) relevance += 0.3;
      if (relevance > 0) {
        results.add(SearchResult(type: 'trip', item: trip, relevance: relevance));
      }
    }
  
    // Previous Trips
    for (final prev in _allPreviousTrips) {
      final trip = prev.baseTrip;
      double relevance = 0.0;
      if (trip.name.toLowerCase().contains(query)) relevance += 1.0;
      if (trip.location.toLowerCase().contains(query)) relevance += 0.8;
      if (trip.notes.toLowerCase().contains(query)) relevance += 0.5;
      final actsStr = trip.activities.join(' ').toLowerCase();
      if (actsStr.contains(query)) relevance += 0.3;
      final routeStr = prev.route.join(' ').toLowerCase();
      if (routeStr.contains(query)) relevance += 0.6;
      if (relevance > 0) {
        results.add(SearchResult(type: 'prev_trip', item: prev, relevance: relevance));
      }
    }
  
    results.sort((a, b) => b.relevance.compareTo(a.relevance));
    print('DEBUG: Search "$_searchQuery" returned ${results.length} results');
    return results.take(20).toList();
  }

  void _onPoiSelected(PointOfInterest poi) {
    setState(() => _selectedPoi = poi);
    _mapController.move(poi.coordinates, 15.0);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4, minChildSize: 0.2, maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text(poi.name ?? '', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: explore_colors.kPrimaryBlue)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text('${poi.rating}', style: GoogleFonts.poppins(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(poi.description ?? '', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: poi.imageUrl ?? '',
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(color: Colors.grey[300], child: const Icon(Icons.image_not_supported)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${poi.name} to trip'), backgroundColor: explore_colors.kPrimaryBlue));
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: explore_colors.kPrimaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: Text('Add to Trip', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() => setState(() => _selectedPoi = null));
  }

  void _onTripSelected(Trip trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  trip.name,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: explore_colors.kPrimaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${trip.location} • ${trip.plannedDate.day}/${trip.plannedDate.month}/${trip.plannedDate.year} - ${trip.endDate.day}/${trip.endDate.month}/${trip.endDate.year}',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Text(
                  trip.notes.isNotEmpty ? trip.notes : 'No notes',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                Text(
                  'Activities:',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...trip.activities.map((act) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('• $act', style: GoogleFonts.poppins(fontSize: 14)),
                )),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TripDetailsPage(trip: trip)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: explore_colors.kPrimaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('View Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onPrevTripSelected(PreviousTrip prevTrip) {
    final trip = prevTrip.baseTrip;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  trip.name,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: explore_colors.kPrimaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${trip.location} • Completed',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Text(
                  'Total Expenses: \$${prevTrip.totalExpenses.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 8),
                Text(
                  'Route: ${prevTrip.route.join(' → ')}',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                Text(
                  trip.notes.isNotEmpty ? trip.notes : 'No notes',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PreviousTripDetailsPage(trip: prevTrip)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: explore_colors.kPrimaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('View Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final center = _currentLocation ?? const LatLng(37.7749, -122.4194);
    final filteredPois = _filteredPois;
    final searchResults = _searchResults;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: TextField(
          onChanged: (value) {
            setState(() => _searchQuery = value);
            print('DEBUG: Search query updated to: $value');
          },
          decoration: InputDecoration(
            hintText: 'Search places, trips...',
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          ),
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: center, initialZoom: 13.0),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.flutter_application_1',
                ),
                MarkerLayer(
                  markers: [
                    ...filteredPois.map((poi) => Marker(
                          point: poi.coordinates,
                          width: 40, height: 40,
                          child: GestureDetector(
                            onTap: () => _onPoiSelected(poi),
                            child: const Icon(Icons.location_pin, color: explore_colors.kPrimaryBlue, size: 40),
                          ),
                        )),
                    if (_currentLocation != null)
                      Marker(
                        point: _currentLocation!,
                        width: 40, height: 40,
                        child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                      ),
                  ],
                ),
              ],
            ),
            if (_searchQuery.isNotEmpty && searchResults.isNotEmpty)
              Positioned(
                top: 80,
                left: 10,
                right: 10,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final result = searchResults[index];
                      if (result.type == 'poi') {
                        final poi = result.item as PointOfInterest;
                        return ListTile(
                          leading: const Icon(Icons.location_pin, color: explore_colors.kPrimaryBlue),
                          title: Text(poi.name ?? ''),
                          subtitle: Text(poi.description ?? ''),
                          onTap: () => _onPoiSelected(poi),
                        );
                      } else if (result.type == 'trip') {
                        final trip = result.item as Trip;
                        return ListTile(
                          leading: const Icon(Icons.flight, color: Colors.blue),
                          title: Text(trip.name),
                          subtitle: Text(trip.location),
                          onTap: () => _onTripSelected(trip),
                        );
                      } else if (result.type == 'prev_trip') {
                        final prev = result.item as PreviousTrip;
                        final trip = prev.baseTrip;
                        return ListTile(
                          leading: const Icon(Icons.history, color: Colors.green),
                          title: Text(trip.name),
                          subtitle: Text('${trip.location} • \$${prev.totalExpenses.toStringAsFixed(2)}'),
                          onTap: () => _onPrevTripSelected(prev),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _locationService.getCurrentLocation().then((location) {
            if (location != null && mounted) {
              final latLng = LatLng(location.latitude, location.longitude);
              setState(() => _currentLocation = latLng);
              _mapController.move(latLng, 13.0);
            }
          });
        },
        backgroundColor: explore_colors.kPrimaryBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}