// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/services/timeline_service.dart';
import 'package:flutter_application_1/models/timeline_event.dart';
import 'package:flutter_application_1/widgets/timeline_view.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeTimeline();
  }

  Future<void> _initializeTimeline() async {
    await _timelineService.initialize();
    _events = await _timelineService.getEventsForToday();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    _timelineService.timelineStream.listen((events) {
      if (mounted) {
        setState(() {
          _events = events;
        });
      }
    });
    await _timelineService.updateTimelineNow();
  }

  @override
  void dispose() {
    _timelineService.dispose();
    super.dispose();
  }

  double get totalDistance {
    return _events
        .where((e) => e.distance != null)
        .fold(0.0, (sum, e) => sum + (e.distance ?? 0.0));
  }

  int get steps {
    // Mock: approximate steps based on distance (assuming average walking)
    return (totalDistance * 1300).round();
  }

  Duration get timeOutdoors {
    if (_events.isEmpty) return Duration.zero;
    return _events.last.time.difference(_events.first.time);
  }

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
        title: Text(
          'Today\'s Journey',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: kBlue,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quick Stats
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: kGreen.withOpacity(0.05),
                border: Border(
                  bottom: BorderSide(color: kGreen.withOpacity(0.2), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard(
                    icon: Icons.directions_run,
                    label: 'Distance',
                    value: '${totalDistance.toStringAsFixed(1)} km',
                    color: kBlue,
                  ),
                  _buildStatCard(
                    icon: Icons.directions_walk,
                    label: 'Steps',
                    value: steps.toString(),
                    color: kGreen,
                  ),
                  _buildStatCard(
                    icon: Icons.access_time,
                    label: 'Outdoors',
                    value: _formatDuration(timeOutdoors),
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
            // Timeline
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80.0), // Space for FAB
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(kBlue),
                        ),
                      )
                    : _events.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.timeline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No locations visited today',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : TimelineView(
                            events: _events,
                            isFirst: true,
                            isLast: true,
                          ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Explore Page (placeholder)
          // Navigator.push(context, MaterialPageRoute(builder: (context) => ExploreScreen()));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Explore page coming soon!')),
          );
        },
        backgroundColor: kBlue,
        child: const Icon(Icons.explore, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}