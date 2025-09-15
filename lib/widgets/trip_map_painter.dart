// lib/widgets/trip_map_painter.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/trip_model.dart';
import 'dart:math' as math;

const Color kSecondaryBlue = Color(0xFF3B82F6);

class TripMapPainter extends CustomPainter {
  final List<Trip> plannedTrips;
  final List<Trip> previousTrips;
  final Offset mapCenter;
  final double zoomLevel;
  final bool showRoutes;
  final bool showPreviousTrips;

  TripMapPainter({
    required this.plannedTrips,
    required this.previousTrips,
    required this.mapCenter,
    required this.zoomLevel,
    required this.showRoutes,
    required this.showPreviousTrips,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // Draw a simple, bright background to confirm this is working
    paint.color = const Color(0xFFE3F2FD);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Draw some abstract landmasses
    paint.color = const Color(0xFFBBDEFB);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 50, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.6), 80, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}