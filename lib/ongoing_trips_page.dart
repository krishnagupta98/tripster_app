import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/models/trip_model.dart';
import 'package:flutter_application_1/services/database_helper.dart';
import 'package:flutter_application_1/ongoing_trip_page.dart';

const Color kPrimaryBlue = Color(0xFF1E40AF);

class OngoingTripsPage extends StatefulWidget {
  const OngoingTripsPage({super.key});

  @override
  State<OngoingTripsPage> createState() => _OngoingTripsPageState();
}

class _OngoingTripsPageState extends State<OngoingTripsPage> {
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
      final trips = await dbHelper.getOngoingTrips();
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
          SnackBar(content: Text('Error loading ongoing trips: $e')),
        );
      }
    }
  }

  Future<void> _updateTrip(int index) async {
    // TODO: Implement update functionality, perhaps navigate to edit form
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
        await dbHelper.deleteTrip(tripToDelete.id ?? 0);
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
        title: Text("Ongoing Trips", style: GoogleFonts.poppins()),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _trips.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No ongoing trips yet.'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _trips.length,
              itemBuilder: (context, index) {
                final trip = _trips[index];
                return ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OngoingTripPage(trip: trip),
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
    );
  }
}