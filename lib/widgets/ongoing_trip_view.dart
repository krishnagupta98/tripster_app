// lib/widgets/ongoing_trip_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/trip_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

const Color kPrimaryBlue = Color(0xFF1E40AF);
const Color kDarkBlue = Color(0xFF1E3A8A);

class OngoingTripView extends StatelessWidget {
  final Trip? ongoingTrip;

  const OngoingTripView({super.key, this.ongoingTrip});

  @override
  Widget build(BuildContext context) {
    if (ongoingTrip == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.luggage_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "No Ongoing Trips",
              style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "When a planned trip starts, it will appear here.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final trip = ongoingTrip!;
    final totalDays = trip.endDate.difference(trip.plannedDate).inDays + 1;
    final currentDay = DateTime.now().difference(trip.plannedDate).inDays + 1;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Currently On Trip", style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: kDarkBlue)),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: CachedNetworkImage(imageUrl: trip.imageUrl, fit: BoxFit.cover),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trip.name, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(trip.location, style: GoogleFonts.poppins(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text("Day $currentDay of $totalDays", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: currentDay / totalDays,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryBlue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}