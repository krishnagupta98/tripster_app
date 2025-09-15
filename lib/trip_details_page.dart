// lib/trip_details_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/models/trip_model.dart';

const Color kPrimaryBlue = Color(0xFF1E40AF);
const Color kDarkBlue = Color(0xFF1E3A8A);

class TripDetailsPage extends StatelessWidget {
  final Trip trip;
  const TripDetailsPage({super.key, required this.trip});

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
                trip.name,
                style: GoogleFonts.playfairDisplay(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              background: Hero(
                tag: trip.imageUrl,
                child: CachedNetworkImage(
                  imageUrl: trip.imageUrl,
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
                          '${DateFormat('MMM d, yyyy').format(trip.plannedDate)} - ${DateFormat('MMM d, yyyy').format(trip.endDate)}',
                    ),
                    const SizedBox(height: 24),
                    _buildDetailItem(
                      icon: Icons.notes_outlined,
                      title: 'Notes',
                      content: trip.notes,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Planned Activities',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: kDarkBlue),
                    ),
                    const SizedBox(height: 8),
                    ...trip.activities.map((activity) => Card(
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