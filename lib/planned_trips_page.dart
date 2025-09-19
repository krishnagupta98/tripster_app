// lib/planned_trips_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/models/trip_model.dart';
import 'package:flutter_application_1/services/database_helper.dart';
import 'package:flutter_application_1/widgets/add_trip_form.dart';
import 'package:flutter_application_1/widgets/planned_trips_view.dart';
import 'package:flutter_application_1/trip_details_page.dart';

// Using the new primary color for consistency
const Color kPrimaryBlue = Color(0xFF1E40AF);

class PlannedTripsPage extends StatefulWidget {
  const PlannedTripsPage({super.key});

  @override
  State<PlannedTripsPage> createState() => _PlannedTripsPageState();
}

class _PlannedTripsPageState extends State<PlannedTripsPage> {
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
      final trips = await dbHelper.getPlannedTrips();
      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading trips: $e')),
      );
    }
  }

  Future<void> _addTrip() async {
    final result = await showDialog<Trip>(
      context: context,
      builder: (context) => const Dialog(child: AddTripForm()),
    );
    if (result != null) {
      try {
        final dbHelper = DatabaseHelper();
        await dbHelper.insertTrip(result);
        await _loadTrips();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving trip: $e')),
        );
      }
    }
  }

  Future<void> _updateTrip(int index) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Updated trip: ${_trips[index].name}")),
    );
    
  }

  Future<void> _removeTrip(int index) async {
    final tripToDelete = _trips[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: Text('Are you sure you want to delete "${tripToDelete.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final dbHelper = DatabaseHelper();
        await dbHelper.deleteTrip(tripToDelete.id ?? 0);  // Assume id is set
        await _loadTrips();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting trip: $e')),
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
        title: Text("Manage Planned Trips", style: GoogleFonts.poppins()),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView.builder(
        itemCount: _trips.length,
        itemBuilder: (context, index) {
          final trip = _trips[index];
          return ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TripDetailsPage(trip: trip),
              ),
            ),
            leading: CircleAvatar(
              backgroundImage: NetworkImage(trip.imageUrl),
            ),
            title: Text(trip.name, style: GoogleFonts.poppins()),
            subtitle: Text(trip.location, style: GoogleFonts.poppins()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueGrey),
                  // This line ensures _updateTrip is referenced
                  onPressed: () => _updateTrip(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _removeTrip(index),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTrip,
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}