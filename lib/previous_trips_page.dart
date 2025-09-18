// lib/previous_trips_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/models/trip_model.dart';
import 'package:flutter_application_1/services/database_helper.dart';
import 'package:flutter_application_1/previous_trips_details_page.dart';
import 'package:flutter_application_1/models/previous_trip_model.dart';

const Color kPrimaryBlue = Color(0xFF1E40AF);

class PreviousTripsPage extends StatefulWidget {
  const PreviousTripsPage({super.key});

  @override
  State<PreviousTripsPage> createState() => _PreviousTripsPageState();
}

class _PreviousTripsPageState extends State<PreviousTripsPage> {
  List<Trip> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    try {
      final dbHelper = DatabaseHelper();
      final trips = await dbHelper.getCompletedTrips();
      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading previous trips: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Previous Trips", style: GoogleFonts.poppins()),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _trips.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No previous trips yet.'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _trips.length,
              itemBuilder: (context, index) {
                final trip = _trips[index];
                return ListTile(
                  onTap: () {
                    final prevTrip = PreviousTrip(
                      baseTrip: trip,
                      route: [],
                      expenses: [],
                      photos: [],
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PreviousTripDetailsPage(trip: prevTrip),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(trip.imageUrl),
                  ),
                  title: Text(trip.name, style: GoogleFonts.poppins()),
                  subtitle: Text(
                    '${trip.location} • ${DateFormat('MMM yyyy').format(trip.plannedDate)}',
                    style: GoogleFonts.poppins(),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                );
              },
            ),
    );
  }
}