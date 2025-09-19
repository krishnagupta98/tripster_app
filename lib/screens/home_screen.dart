// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_application_1/services/database_helper.dart';
import 'package:flutter_application_1/models/trip_model.dart';
import 'package:flutter_application_1/ongoing_trip_page.dart';
import 'package:flutter_application_1/services/timeline_service.dart';
import 'package:flutter_application_1/models/timeline_event.dart';
import 'package:flutter_application_1/widgets/timeline_view.dart';
import 'package:flutter_application_1/trip_details_page.dart';
// Note: We don't import PreviousTripsDetailsPage here as it's not used.

const Color kBlue = Color(0xFF2196F3);
const Color kGreen = Color(0xFF4CAF50);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TimelineService _timelineService = TimelineService();
  List<TimelineEvent> _events = [];
  bool _isLoading = true;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Trip> _ongoingTrips = [];
  List<Trip> _plannedTrips = [];
  List<Trip> _completedTrips = [];

  @override
  void initState() {
    super.initState();
    _initializeTimeline();
    _loadOngoingTrips();
    _loadPlannedTrips();
    _loadCompletedTrips();
  }

  Future<void> _initializeTimeline() async {
    await _timelineService.initialize();
    _events = await _timelineService.getEventsForToday();
    if (mounted) setState(() => _isLoading = false);

    _timelineService.timelineStream.listen((events) {
      if (mounted) setState(() => _events = events);
    });
    await _timelineService.updateTimelineNow();
  }

  Future<void> _loadOngoingTrips() async {
    _ongoingTrips = await _dbHelper.getOngoingTrips();
    if (mounted) setState(() {});
  }

  Future<void> _loadPlannedTrips() async {
    _plannedTrips = await _dbHelper.getPlannedTrips();
    if (mounted) setState(() {});
  }

  Future<void> _loadCompletedTrips() async {
    _completedTrips = await _dbHelper.getCompletedTrips();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timelineService.dispose();
    super.dispose();
  }

  double get totalDistance => _events.where((e) => e.distance != null).fold(0.0, (sum, e) => sum + (e.distance ?? 0.0));
  int get steps => (totalDistance * 1300).round();
  Duration get timeOutdoors => _events.isEmpty ? Duration.zero : _events.last.time.difference(_events.first.time);

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Today\'s Journey', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100.0),
        children: [
          _buildQuickStatsSection(),
          const SizedBox(height: 16),
          _buildTimelineSection(),
          _buildPlannedTripsSection(),
          _buildOngoingTripsSection(),
          _buildPreviousTripsSection(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Explore page coming soon!'))),
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.explore),
      ),
    );
  }
  
  Widget _buildQuickStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(icon: Icons.directions_run, label: 'Distance', value: '${totalDistance.toStringAsFixed(1)} km', color: kBlue),
          _buildStatCard(icon: Icons.directions_walk, label: 'Steps', value: steps.toString(), color: kGreen),
          _buildStatCard(icon: Icons.access_time, label: 'Outdoors', value: _formatDuration(timeOutdoors), color: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return _buildSection(
      title: 'Timeline',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? _buildEmptyState(icon: Icons.timeline, text: 'No locations visited today')
              : TimelineView(events: _events, isFirst: true, isLast: true),
    );
  }

  Widget _buildOngoingTripsSection() {
    return _buildSection(
      title: 'Ongoing Trips',
      child: _ongoingTrips.isEmpty
          ? _buildEmptyState(text: 'No ongoing trips. Start a planned trip!')
          : _buildTripGrid(_ongoingTrips, (trip) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => OngoingTripPage(trip: trip)));
            }),
    );
  }

  Widget _buildPlannedTripsSection() {
    return _buildSection(
      title: 'Planned Trips',
      child: _plannedTrips.isEmpty
          ? _buildEmptyState(text: 'No planned trips. Add your first trip!')
          : _buildTripGrid(_plannedTrips, (trip) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => TripDetailsPage(trip: trip)));
            }),
    );
  }

  Widget _buildPreviousTripsSection() {
    return _buildSection(
      title: 'Previous Trips',
      child: _completedTrips.isEmpty
          ? _buildEmptyState(text: 'No previous trips yet.')
          : _buildTripGrid(_completedTrips, (trip) {
              // BUG FIX: Navigates to the simple TripDetailsPage because _completedTrips
              // is a List<Trip>, not List<PreviousTrip> with expense data.
              Navigator.push(context, MaterialPageRoute(builder: (context) => TripDetailsPage(trip: trip)));
            }),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: kBlue)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState({IconData? icon, required String text}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            if (icon != null) Icon(icon, size: 64, color: Colors.grey[400]),
            if (icon != null) const SizedBox(height: 16),
            Text(text, style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildTripGrid(List<Trip> trips, void Function(Trip) onTap) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => onTap(trip),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: trip.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error_outline, color: Colors.redAccent),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.black.withAlpha(153), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.center),
                  ),
                ),
                Positioned(
                  bottom: 16, left: 16, right: 16,
                  child: Text(
                    trip.name,
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, shadows: const [Shadow(blurRadius: 4)]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value, required Color color}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}