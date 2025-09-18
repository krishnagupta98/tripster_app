// lib/widgets/timeline_view.dart

import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/models/timeline_event.dart';
import 'package:flutter_application_1/models/trip_model.dart';
import 'package:flutter_application_1/trip_details_page.dart';
import 'package:latlong2/latlong.dart';

const Color kPrimaryBlue = Color(0xFF1E40AF);
const Color kDarkBlue = Color(0xFF1E3A8A);

class TimelineView extends StatelessWidget {
  final List<TimelineEvent> events;
  final bool isFirst;
  final bool isLast;

  const TimelineView({
    super.key,
    required this.events,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isFirst = index == 0;
        final isLast = index == events.length - 1;
        return TimelineTile(
          isFirst: isFirst,
          isLast: isLast,
          alignment: TimelineAlign.start,
          lineXY: 0.1,
          indicatorStyle: IndicatorStyle(
            width: 12,
            color: _getEventColor(event.eventType),
            indicator: _buildIndicator(event),
          ),
          endChild: _buildEventCard(context, event),
          beforeLineStyle: LineStyle(
            color: kPrimaryBlue,
            thickness: 2,
          ),
          afterLineStyle: LineStyle(
            color: kPrimaryBlue,
            thickness: 2,
          ),
        );
      },
    );
  }

  Widget _buildIndicator(TimelineEvent event) {
    if (event.imageUrl != null && event.imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 6,
        backgroundImage: CachedNetworkImageProvider(event.imageUrl!),
      );
    }
    return const Icon(Icons.location_pin, size: 12, color: Colors.white);
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case 'trip_start':
        return kPrimaryBlue;
      case 'activity':
        return Colors.green;
      case 'trip_end':
        return Colors.orange;
      default:
        return kDarkBlue;
    }
  }

  Widget _buildEventCard(BuildContext context, TimelineEvent event) {
    final isRecent = event.time.isAfter(DateTime.now().subtract(const Duration(hours: 1)));
    return Padding(
      padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
      child: AnimatedScale(
        scale: isRecent ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: _getEventColor(event.eventType).withValues(alpha: 0.1),
              child: Icon(
                _getEventIcon(event.eventType),
                color: _getEventColor(event.eventType),
              ),
            ),
            title: Text(
              event.title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.time.hour > 0 || event.time.minute > 0)
                  Text(
                    _formatTime(event.time),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                if (event.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      event.description,
                      style: GoogleFonts.poppins(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (event.location != null && event.location!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      event.location!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (event.travelMode != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Mode: ${event.travelMode}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue[600],
                      ),
                    ),
                  ),
                if (event.distance != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      '${event.distance!.toStringAsFixed(1)} km',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.green[600],
                      ),
                    ),
                  ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () => _navigateToTrip(context, event),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'trip_start':
        return Icons.flag;
      case 'activity':
        return Icons.event;
      case 'trip_end':
        return Icons.flag;
      default:
        return Icons.location_on;
    }
  }

  void _navigateToTrip(BuildContext context, TimelineEvent event) {
    if (event.tripId != null) {
      // Navigate to trip details - assume a way to get Trip from id
      // For now, placeholder
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TripDetailsPage(trip: Trip( // Placeholder
            id: event.tripId,
            name: event.title,
            location: event.location ?? '',
            imageUrl: event.imageUrl ?? '',
            plannedDate: event.time,
            endDate: event.time.add(const Duration(hours: 1)),
            notes: event.description,
            activities: [],
            status: 'planned',
          )),
        ),
      );
    }
  }
}