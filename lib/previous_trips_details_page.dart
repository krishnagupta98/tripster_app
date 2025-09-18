// lib/previous_trip_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/models/previous_trip_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

const Color kPrimaryBlue = Color(0xFF1E40AF);
const Color kDarkBlue = Color(0xFF1E3A8A);

class PreviousTripDetailsPage extends StatefulWidget {
  final PreviousTrip trip;
  const PreviousTripDetailsPage({super.key, required this.trip});

  @override
  State<PreviousTripDetailsPage> createState() =>
      _PreviousTripDetailsPageState();
}

class _PreviousTripDetailsPageState extends State<PreviousTripDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showFab = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      if (_tabController.index == 1) { // Expenses tab
        setState(() => _showFab = true);
      } else {
        setState(() => _showFab = false);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            floating: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.trip.baseTrip.name,
                  style: GoogleFonts.playfairDisplay(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              background: Hero(
                tag: widget.trip.baseTrip.imageUrl,
                child: CachedNetworkImage(
                  imageUrl: widget.trip.baseTrip.imageUrl,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.4),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: kDarkBlue,
              indicatorColor: kPrimaryBlue,
              tabs: const [
                Tab(icon: Icon(Icons.info_outline), text: "Details"),
                Tab(icon: Icon(Icons.receipt_long_outlined), text: "Expenses"),
                Tab(icon: Icon(Icons.photo_library_outlined), text: "Photos"),
                Tab(icon: Icon(Icons.map_outlined), text: "Map"),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildExpensesTab(),
                _buildPhotosTab(),
                TripRouteMap(locations: widget.trip.route),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Add new expense form would appear here.")));
              },
              backgroundColor: kPrimaryBlue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailItem(
            icon: Icons.calendar_today_outlined,
            title: 'Trip Dates',
            content:
                '${DateFormat('MMM d, yyyy').format(widget.trip.baseTrip.plannedDate)} - ${DateFormat('MMM d, yyyy').format(widget.trip.baseTrip.endDate)}',
          ),
          const SizedBox(height: 24),
          _buildDetailItem(
            icon: Icons.notes,
            title: 'Notes',
            content: widget.trip.baseTrip.notes,
          ),
          const SizedBox(height: 24),
          Text(
            'Activities',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: kDarkBlue),
          ),
          const SizedBox(height: 8),
          ...widget.trip.baseTrip.activities.map((activity) => Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: kPrimaryBlue),
                  title: Text(activity, style: GoogleFonts.poppins()),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildExpensesTab() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Total Expenses', style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[700])),
                const SizedBox(height: 8),
                Text(
                  '₹${widget.trip.totalExpenses.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, color: kDarkBlue),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...widget.trip.expenses.map((expense) => Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Icon(expense.icon, color: kPrimaryBlue),
                title: Text(expense.description, style: GoogleFonts.poppins()),
                trailing: Text('₹${expense.amount.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            )),
      ],
    );
  }

  Widget _buildPhotosTab() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: widget.trip.photos.length,
      itemBuilder: (context, index) {
        final photo = widget.trip.photos[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: GridTile(
            footer: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(photo.location, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(DateFormat('MMM d, yyyy').format(photo.date), style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
            child: CachedNetworkImage(
              imageUrl: photo.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildDetailItem({required IconData icon, required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: kPrimaryBlue, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: kDarkBlue),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 28.0),
          child: Text(
            content,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87, height: 1.5),
          ),
        ),
      ],
    );
  }
}

class TripRouteMap extends StatefulWidget {
  final List<String> locations;
  const TripRouteMap({super.key, required this.locations});

  @override
  State<TripRouteMap> createState() => _TripRouteMapState();
}

class _TripRouteMapState extends State<TripRouteMap> {
  final List<Marker> _markers = [];
  final List<LatLng> _routeCoordinates = [];
  bool _isLoading = true;
  LatLngBounds? _bounds;

  @override
  void initState() {
    super.initState();
    _geocodeRoute();
  }

  Future<void> _geocodeRoute() async {
    for (var locationName in widget.locations) {
      try {
        List<Location> locations = await locationFromAddress(locationName);
        if (locations.isNotEmpty) {
          final latLng = LatLng(locations.first.latitude, locations.first.longitude);
          _routeCoordinates.add(latLng);
          _markers.add(
            Marker(
              point: latLng,
              width: 120,
              height: 50,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]
                      ),
                      child: Text(
                        locationName.split(',').first,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const Icon(Icons.location_pin, color: kPrimaryBlue),
                ],
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint("Could not geocode $locationName: $e");
      }
    }
    
    if (_routeCoordinates.isNotEmpty) {
      _bounds = LatLngBounds.fromPoints(_routeCoordinates);
    }

    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_routeCoordinates.isEmpty) return const Center(child: Text("Could not find locations for this trip."));

    return FlutterMap(
      options: MapOptions(
        initialCameraFit: CameraFit.bounds(
          bounds: _bounds!,
          padding: const EdgeInsets.all(50.0),
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.flutter_application_1',
        ),
        PolylineLayer(
          polylines: [
            Polyline(points: _routeCoordinates, color: kPrimaryBlue, strokeWidth: 4),
          ],
        ),
        MarkerLayer(markers: _markers),
      ],
    );
  }
}