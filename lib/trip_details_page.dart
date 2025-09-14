// lib/trip_details_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/models/trip_model.dart';

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
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                trip.location,
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
                      icon: Icons.calendar_today,
                      title: 'Planned Date',
                      content: DateFormat('MMMM d, yyyy').format(trip.plannedDate),
                    ),
                    const SizedBox(height: 24),
                    _buildDetailItem(
                      icon: Icons.notes,
                      title: 'Notes',
                      content: trip.notes,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Planned Activities',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1565C0)),
                    ),
                    const SizedBox(height: 8),
                    ...trip.activities.map((activity) => Card(
                          elevation: 1,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.check_circle_outline, color: Color(0xFF2196F3)),
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
            Icon(icon, color: const Color(0xFF2196F3), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1565C0)),
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