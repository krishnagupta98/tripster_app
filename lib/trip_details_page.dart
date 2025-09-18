// lib/trip_details_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/models/trip_model.dart';
import 'package:flutter_application_1/models/previous_trip_model.dart';
import 'package:flutter_application_1/services/database_helper.dart';
import 'package:flutter_application_1/ongoing_trip_page.dart'; // Assume this exists
import 'package:flutter_application_1/previous_trips_page.dart';
import 'package:flutter_application_1/previous_trips_details_page.dart';

const Color kPrimaryBlue = Color(0xFF1E40AF);
const Color kDarkBlue = Color(0xFF1E3A8A);

class TripDetailsPage extends StatefulWidget {
  final Trip trip;
  const TripDetailsPage({super.key, required this.trip});

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  late Trip _trip;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
  }

  Future<void> _startTrip() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Trip'),
        content: Text('Are you ready to start "${_trip.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        _trip = _trip.copyWith(status: 'active'); // Assume copyWith method added to model
        final dbHelper = DatabaseHelper();
        await dbHelper.updateTrip(_trip);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OngoingTripPage(trip: _trip)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error starting trip: $e')),
          );
        }
      }
    }
  }
  
  Future<void> _finishTrip() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Trip'),
        content: Text('Mark "${_trip.name}" as completed without starting?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finish', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
 
    if (confirm == true) {
      try {
        final completedTrip = _trip.copyWith(status: 'completed');
        final dbHelper = DatabaseHelper();
        await dbHelper.updateTrip(completedTrip);
 
        // Create basic previous trip record
        final prevTrip = PreviousTrip(
          baseTrip: completedTrip,
          route: [],
          expenses: [],
          photos: [],
        );
        await dbHelper.insertPreviousTrip(prevTrip);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip marked as completed!')),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PreviousTripDetailsPage(trip: prevTrip)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error finishing trip: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _trip.name,
                style: GoogleFonts.playfairDisplay(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              background: Hero(
                tag: _trip.imageUrl,
                child: CachedNetworkImage(
                  imageUrl: _trip.imageUrl,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.4),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(
                    icon: Icons.date_range_outlined,
                      title: 'Trip Dates',
                      content:
                          '${DateFormat('MMM d, yyyy').format(_trip.plannedDate)} - ${DateFormat('MMM d, yyyy').format(_trip.endDate)}',
                    ),
                    const SizedBox(height: 24),
                    _buildDetailItem(
                      icon: Icons.notes_outlined,
                      title: 'Notes',
                      content: _trip.notes,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Planned Activities',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: kDarkBlue),
                    ),
                    const SizedBox(height: 8),
                    ..._trip.activities.map((activity) => Card(
                          elevation: 1,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.check_circle_outline, color: kPrimaryBlue),
                            title: Text(activity, style: GoogleFonts.poppins()),
                          ),
                        )),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
      floatingActionButton: _trip.status == 'planned'
        ? Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'start',
                onPressed: _startTrip,
                backgroundColor: kPrimaryBlue,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.play_arrow),
                label: Text('Start Trip', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              FloatingActionButton.extended(
                heroTag: 'finish',
                onPressed: _finishTrip,
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.check),
                label: Text('Finish Trip', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ],
          )
        : null,
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