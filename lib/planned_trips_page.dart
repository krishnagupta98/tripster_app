// lib/planned_trips_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/models/trip_model.dart';

// Using the new primary color for consistency
const Color kPrimaryBlue = Color(0xFF1E40AF);

class PlannedTripsPage extends StatefulWidget {
  final List<Trip> plannedTrips;
  const PlannedTripsPage({super.key, required this.plannedTrips});

  @override
  State<PlannedTripsPage> createState() => _PlannedTripsPageState();
}

class _PlannedTripsPageState extends State<PlannedTripsPage> {
  late List<Trip> _trips;

  @override
  void initState() {
    super.initState();
    _trips = List.from(widget.plannedTrips);
  }

  void _addTrip() {
    // ... (This function remains the same)
  }

  // This function is now correctly used by the edit button
  void _updateTrip(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Updated trip: ${_trips[index].name}")),
    );
  }

  void _removeTrip(int index) {
    // ... (This function remains the same)
  }

  @override
  Widget build(BuildContext context) {
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