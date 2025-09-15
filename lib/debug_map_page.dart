// lib/debug_map_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/trip_model.dart';
import 'package:flutter_application_1/widgets/trip_map_painter.dart';

class DebugMapPage extends StatelessWidget {
  const DebugMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Using empty lists to test only the background drawing
    final List<Trip> dummyPlannedTrips = [];
    final List<Trip> dummyPreviousTrips = [];

    return Scaffold(
      appBar: AppBar(title: const Text("Map Debug Page")),
      // UPDATED: This SizedBox.expand forces the child to fill the entire body
      body: SizedBox.expand(
        child: CustomPaint(
          painter: TripMapPainter(
            plannedTrips: dummyPlannedTrips,
            previousTrips: dummyPreviousTrips,
            mapCenter: const Offset(0, 0),
            zoomLevel: 1.0,
            showRoutes: false,
            showPreviousTrips: false,
          ),
        ),
      ),
    );
  }
}