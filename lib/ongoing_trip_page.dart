import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/models/trip_model.dart';

class OngoingTripPage extends StatelessWidget {
  final Trip trip;
  const OngoingTripPage({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(trip.name, style: GoogleFonts.poppins()),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Ongoing Trip: ${trip.name}'),
            Text('Location: ${trip.location}'),
            Text('Status: Active'),
            // Add navigation and weather here
          ],
        ),
      ),
    );
  }
}