// lib/services/timeline_service.dart

import 'dart:async';
import 'dart:isolate';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_application_1/services/database_helper.dart';
import 'package:flutter_application_1/models/trip_model.dart';
import 'package:flutter_application_1/models/timeline_event.dart';
import 'package:flutter_application_1/services/location_service.dart';
import 'package:flutter_application_1/services/database_helper.dart';

class TimelineService {
  static const String taskName = 'timelineUpdateTask';
  final StreamController<List<TimelineEvent>> _eventStreamController = StreamController<List<TimelineEvent>>.broadcast();
  Stream<List<TimelineEvent>> get timelineStream => _eventStreamController.stream;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final LocationService _locationService = LocationService();

  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      try {
        final locationService = LocationService();
        await locationService.storeCurrentLocation();
        await _performTimelineUpdate();
        return Future.value(true);
      } catch (e) {
        return Future.value(false);
      }
    });
  }

  static Future<void> _performTimelineUpdate() async {
    final dbHelper = DatabaseHelper();
    final locationService = LocationService();
    final today = DateTime.now();

    // Store current location
    await locationService.storeCurrentLocation();

    // Get relevant trips for today
    final trips = await dbHelper.getAllTrips();
    final todayTrips = trips.where((trip) => _isTripOnDate(trip, today)).toList();

    // Generate events for each trip
    for (final trip in todayTrips) {
      await dbHelper.generateEventsFromTrip(trip);
    }

    // Generate location-based events
    await dbHelper.generateLocationEventsForDate(today);

    // Get events for today
    final events = await dbHelper.getEventsForDate(today);
    // Broadcast to stream (in background, this might need adjustment for UI)
    // For simplicity, update DB; UI listens on init
  }

  static bool _isTripOnDate(Trip trip, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return trip.plannedDate.isBefore(end) && trip.endDate.isAfter(start);
  }

  Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
    await _registerPeriodicTask();
  }

  Future<void> _registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: const Duration(minutes: 15), // Minimum for periodic
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  Future<void> updateTimelineNow() async {
    await _performTimelineUpdate();
    final today = DateTime.now();
    final events = await _dbHelper.getEventsForDate(today);
    _eventStreamController.add(events);
  }

  Future<void> startLocationTracking() async {
    // Can be called to start periodic updates if needed beyond workmanager
    await _locationService.requestPermission();
    await updateTimelineNow();
  }

  Future<List<TimelineEvent>> getEventsForToday() async {
    final today = DateTime.now();
    return await _dbHelper.getEventsForDate(today);
  }

  void dispose() {
    _eventStreamController.close();
  }
}