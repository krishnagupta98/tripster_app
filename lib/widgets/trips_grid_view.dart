// lib/widgets/trips_grid_view.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_application_1/trip_details_page.dart';
import 'package:flutter_application_1/previous_trips_details_page.dart';
import 'package:flutter_application_1/models/trip_model.dart';
import 'package:flutter_application_1/models/previous_trip_model.dart';

enum TripType { planned, previous }

class TripsGridView extends StatelessWidget {
  final List<dynamic> trips;
  final TripType tripType;

  const TripsGridView({
    super.key,
    required this.trips,
    required this.tripType,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final dynamic tripData = trips[index];
        
        final String imageUrl = tripType == TripType.planned ? tripData.imageUrl : tripData.baseTrip.imageUrl;
        final String name = tripType == TripType.planned ? tripData.name : tripData.baseTrip.name;

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {
              if (tripType == TripType.planned) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => TripDetailsPage(trip: tripData as Trip)));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (context) => PreviousTripDetailsPage(trip: tripData as PreviousTrip)));
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: imageUrl,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
                    errorWidget: (context, url, error) => const Icon(Icons.error_outline, color: Colors.redAccent),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withAlpha(153), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Text(
                    name,
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, shadows: const [Shadow(blurRadius: 4)]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}