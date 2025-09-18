// lib/widgets/timeline_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/models/timeline_event.dart';

const Color kPrimaryBlue = Color(0xFF1E40AF);
const Color kDarkBlue = Color(0xFF1E3A8A);

class TimelineView extends StatefulWidget {
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
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  int? _selectedEventIndex;
  DateTimeRange? _dateFilter;
  String _locationTypeFilter = 'all';
  double _durationFilter = 0.0; // in hours
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    _dateFilter = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<TimelineEvent> get _filteredEvents {
    var filtered = widget.events
        .where((e) => e.coordinates != null)
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    if (_dateFilter != null) {
      filtered = filtered.where((e) => e.time.isAfter(_dateFilter!.start) && e.time.isBefore(_dateFilter!.end)).toList();
    }

    if (_locationTypeFilter != 'all') {
      filtered = filtered.where((e) => e.eventType == _locationTypeFilter).toList();
    }

    if (_durationFilter > 0) {
      filtered = filtered.where((e) => (e.duration ?? 0) / 3600000 >= _durationFilter).toList(); // ms to hours
    }

    return filtered;
  }

  List<Marker> get _markers {
    return _filteredEvents.asMap().entries.map((entry) {
      final index = entry.key;
      final event = entry.value;
      return Marker(
        point: event.coordinates!,
        width: 40,
        height: 60,
        child: GestureDetector(
          onTap: () => _selectEvent(index),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _getEventColor(event.eventType),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on, color: Colors.white, size: 16),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
                ),
                child: Text(
                  DateFormat('HH:mm').format(event.time),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Polyline> get _polylines {
    if (_filteredEvents.length < 2) return [];
    final polylines = <Polyline>[];
    for (int i = 0; i < _filteredEvents.length - 1; i++) {
      polylines.add(
        Polyline(
          points: [_filteredEvents[i].coordinates!, _filteredEvents[i + 1].coordinates!],
          color: kPrimaryBlue,
          strokeWidth: 3,
          borderStrokeWidth: 0,
        ),
      );
    }
    return polylines;
  }

  LatLng get _mapCenter {
    if (_filteredEvents.isEmpty) return const LatLng(37.7749, -122.4194);
    final bounds = LatLngBounds.fromPoints(_filteredEvents.map((e) => e.coordinates!).toList());
    return _mapController.bounds?.center ?? bounds.center;
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

  void _selectEvent(int index) {
    setState(() {
      _selectedEventIndex = index;
    });
    _mapController.move(_filteredEvents[index].coordinates!, 16.0);
  }

  void _showDateFilter() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateFilter,
    );
    if (picked != null) {
      setState(() {
        _dateFilter = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    if (_filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No timeline events match the filters',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Filters
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _locationTypeFilter,
                  decoration: InputDecoration(
                    labelText: 'Location Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: [
                    'all',
                    'trip_start',
                    'activity',
                    'trip_end',
                  ].map((type) => DropdownMenuItem(value: type, child: Text(type.replaceAll('_', ' ').toUpperCase()))).toList(),
                  onChanged: (value) => setState(() => _locationTypeFilter = value ?? 'all'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Slider(
                  value: _durationFilter,
                  min: 0,
                  max: 24,
                  divisions: 24,
                  label: '${_durationFilter.toInt()}h+',
                  onChanged: (value) => setState(() => _durationFilter = value),
                ),
              ),
              IconButton(
                onPressed: _showDateFilter,
                icon: const Icon(Icons.date_range),
                tooltip: 'Date Range',
              ),
            ],
          ),
        ),
        Expanded(
          child: isDesktop
              ? Row(
                  children: [
                    // Map
                    Expanded(
                      flex: 3,
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _animationController.value,
                            child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _mapCenter,
                                initialZoom: 12,
                                minZoom: 2,
                                maxZoom: 18,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  subdomains: const ['a', 'b', 'c'],
                                ),
                                PolylineLayer(polylines: _polylines),
                                MarkerLayer(markers: _markers),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // List
                    Container(
                      width: 400,
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: kPrimaryBlue.withOpacity(0.1))),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: _filteredEvents.length,
                              itemBuilder: (context, index) {
                                final event = _filteredEvents[index];
                                final isSelected = _selectedEventIndex == index;
                                return ListTile(
                                  selected: isSelected,
                                  leading: CircleAvatar(
                                    backgroundColor: _getEventColor(event.eventType),
                                    child: Icon(Icons.location_on, color: Colors.white, size: 20),
                                  ),
                                  title: Text(event.title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(DateFormat('MMM dd, yyyy HH:mm').format(event.time)),
                                      if (event.description.isNotEmpty) Text(event.description),
                                      if (event.location != null) Text(event.location!),
                                    ],
                                  ),
                                  onTap: () => _selectEvent(index),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    // Map full
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _animationController.value,
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _mapCenter,
                              initialZoom: 12,
                              minZoom: 2,
                              maxZoom: 18,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c'],
                              ),
                              PolylineLayer(polylines: _polylines),
                              MarkerLayer(markers: _markers),
                            ],
                          ),
                        );
                      },
                    ),
                    // Bottom sheet for list
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 300,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.list),
                              title: const Text('Timeline Events'),
                              trailing: IconButton(
                                icon: const Icon(Icons.expand_less),
                                onPressed: () {}, // Could toggle height
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _filteredEvents.length,
                                itemBuilder: (context, index) {
                                  final event = _filteredEvents[index];
                                  final isSelected = _selectedEventIndex == index;
                                  return ListTile(
                                    selected: isSelected,
                                    leading: CircleAvatar(
                                      backgroundColor: _getEventColor(event.eventType),
                                      child: Icon(Icons.location_on, color: Colors.white, size: 20),
                                    ),
                                    title: Text(event.title),
                                    subtitle: Text(DateFormat('HH:mm').format(event.time)),
                                    onTap: () => _selectEvent(index),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        // Selected event details
        if (_selectedEventIndex != null)
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _filteredEvents[_selectedEventIndex!].title,
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(DateFormat('MMM dd, yyyy HH:mm').format(_filteredEvents[_selectedEventIndex!].time)),
                    if (_filteredEvents[_selectedEventIndex!].description.isNotEmpty)
                      Text(_filteredEvents[_selectedEventIndex!].description),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => setState(() => _selectedEventIndex = null),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}