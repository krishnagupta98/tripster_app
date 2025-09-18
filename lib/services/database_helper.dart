import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import '../models/trip_model.dart';
import '../models/point_of_interest_model.dart';
import '../models/timeline_event.dart';
import '../models/previous_trip_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String documentsDirectory = await getDatabasesPath();
    String dbPath = path.join(documentsDirectory, 'tripster.db');
  
    Database database = await openDatabase(
      dbPath,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  
    return database;
  }

  Future<bool> _tableExists(Database db, String tableName) async {
    final result = await db.rawQuery('SELECT name FROM sqlite_master WHERE type="table" AND name="$tableName"');
    return result.isNotEmpty;
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE trips ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE trips ADD COLUMN longitude REAL');
    }
    if (oldVersion < 3) {
      final timelineTableExists = await _tableExists(db, 'timeline_events');
      if (timelineTableExists) {
        await db.execute('ALTER TABLE timeline_events ADD COLUMN travel_mode TEXT');
        await db.execute('ALTER TABLE timeline_events ADD COLUMN distance REAL');
      } else {
        // Create the table if it doesn't exist
        await db.execute('''
          CREATE TABLE timeline_events(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            time INTEGER NOT NULL,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            location TEXT,
            latitude REAL,
            longitude REAL,
            image_url TEXT,
            trip_id INTEGER,
            event_type TEXT NOT NULL,
            travel_mode TEXT,
            distance REAL,
            FOREIGN KEY (trip_id) REFERENCES trips (id)
          )
        ''');
      }
    }
    if (oldVersion < 4) {
      // Additional upgrade if needed, e.g., for pois or other tables
      // For now, no changes
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE timeline_events ADD COLUMN duration INTEGER');
      final pointsTableExists = await _tableExists(db, 'location_points');
      if (!pointsTableExists) {
        await db.execute('''
          CREATE TABLE location_points(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            accuracy REAL
          )
        ''');
      }
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE trips ADD COLUMN status TEXT DEFAULT "planned"');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        image_url TEXT,
        planned_date INTEGER NOT NULL,
        end_date INTEGER NOT NULL,
        notes TEXT,
        activities TEXT  -- JSON string,
        status TEXT DEFAULT 'planned'
      )
    ''');

    await db.execute('''
      CREATE TABLE previous_trips(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER,
        route TEXT,  -- JSON string of locations
        expenses TEXT,  -- JSON string of expenses
        photos TEXT,  -- JSON string of photos
        FOREIGN KEY (trip_id) REFERENCES trips (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pois(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category INTEGER NOT NULL,  -- 0: attraction, 1: cafe, 2: park
        latitude REAL NOT NULL,
        longitude REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE timeline_events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        time INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        location TEXT,
        latitude REAL,
        longitude REAL,
        image_url TEXT,
        trip_id INTEGER,
        event_type TEXT NOT NULL,
        travel_mode TEXT,
        distance REAL,
        duration INTEGER,  -- Added for stay duration in ms
        FOREIGN KEY (trip_id) REFERENCES trips (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE location_points(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL
      )
    ''');
  }

  // CRUD for Trips
  Future<int> insertTrip(Trip trip) async {
    final db = await database;
    Map<String, dynamic> data = {
      'name': trip.name,
      'location': trip.location,
      'latitude': trip.latitude,
      'longitude': trip.longitude,
      'image_url': trip.imageUrl,
      'planned_date': trip.plannedDate.millisecondsSinceEpoch,
      'end_date': trip.endDate.millisecondsSinceEpoch,
      'notes': trip.notes,
      'activities': jsonEncode(trip.activities),
      'status': trip.status,
    };
    return await db.insert('trips', data);
  }

  Future<List<Trip>> getAllTrips() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('trips');
    return List.generate(maps.length, (i) {
      Map<String, dynamic> map = maps[i];
      return Trip(
        id: map['id'],
        name: map['name'],
        location: map['location'],
        latitude: map['latitude'],
        longitude: map['longitude'],
        imageUrl: map['image_url'] ?? '',
        plannedDate: DateTime.fromMillisecondsSinceEpoch(map['planned_date']),
        endDate: DateTime.fromMillisecondsSinceEpoch(map['end_date']),
        notes: map['notes'],
        activities: List<String>.from(jsonDecode(map['activities'] ?? '[]')),
        status: map['status'] ?? 'planned',
      );
    });
  }

  Future<List<Trip>> getCompletedTrips() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('trips', where: 'status = ?', whereArgs: ['completed']);
    return List.generate(maps.length, (i) {
      Map<String, dynamic> map = maps[i];
      return Trip(
        id: map['id'],
        name: map['name'],
        location: map['location'],
        latitude: map['latitude'],
        longitude: map['longitude'],
        imageUrl: map['image_url'] ?? '',
        plannedDate: DateTime.fromMillisecondsSinceEpoch(map['planned_date']),
        endDate: DateTime.fromMillisecondsSinceEpoch(map['end_date']),
        notes: map['notes'],
        activities: List<String>.from(jsonDecode(map['activities'] ?? '[]')),
        status: map['status'] ?? 'completed',
      );
    });
  }
  Future<List<Trip>> getPlannedTrips() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('trips', where: 'status = ?', whereArgs: ['planned']);
    return List.generate(maps.length, (i) {
      Map<String, dynamic> map = maps[i];
      return Trip(
        id: map['id'],
        name: map['name'],
        location: map['location'],
        latitude: map['latitude'],
        longitude: map['longitude'],
        imageUrl: map['image_url'] ?? '',
        plannedDate: DateTime.fromMillisecondsSinceEpoch(map['planned_date']),
        endDate: DateTime.fromMillisecondsSinceEpoch(map['end_date']),
        notes: map['notes'],
        activities: List<String>.from(jsonDecode(map['activities'] ?? '[]')),
        status: map['status'] ?? 'planned',
      );
    });
  }

  Future<int> updateTrip(Trip trip) async {
    final db = await database;
    Map<String, dynamic> data = {
      'name': trip.name,
      'location': trip.location,
      'latitude': trip.latitude,
      'longitude': trip.longitude,
      'image_url': trip.imageUrl,
      'planned_date': trip.plannedDate.millisecondsSinceEpoch,
      'end_date': trip.endDate.millisecondsSinceEpoch,
      'notes': trip.notes,
      'activities': jsonEncode(trip.activities),
      'status': trip.status,
    };
    return await db.update('trips', data, where: 'id = ?', whereArgs: [trip.id]);
  }

  Future<int> deleteTrip(int id) async {
    final db = await database;
    return await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD for POIs
  Future<int> insertPoi(PointOfInterest poi) async {
    final db = await database;
    Map<String, dynamic> data = {
      'name': poi.name,
      'category': poi.category.index,
      'latitude': poi.coordinates.latitude,
      'longitude': poi.coordinates.longitude,
    };
    return await db.insert('pois', data);
  }

  Future<List<PointOfInterest>> getAllPois() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('pois');
    return List.generate(maps.length, (i) {
      Map<String, dynamic> map = maps[i];
      return PointOfInterest(
        id: map['id'],
        name: map['name'],
        category: PoiCategory.values[map['category']],
        coordinates: LatLng(map['latitude'], map['longitude']),
      );
    });
  }

  Future<int> updatePoi(PointOfInterest poi) async {
    final db = await database;
    Map<String, dynamic> data = {
      'name': poi.name,
      'category': poi.category.index,
      'latitude': poi.coordinates.latitude,
      'longitude': poi.coordinates.longitude,
    };
    return await db.update('pois', data, where: 'id = ?', whereArgs: [poi.id]);
  }

  Future<int> deletePoi(int id) async {
    final db = await database;
    return await db.delete('pois', where: 'id = ?', whereArgs: [id]);
  }

  // Timeline Events CRUD

  Future<int> insertTimelineEvent(TimelineEvent event) async {
    final db = await database;
    Map<String, dynamic> data = event.toJson();
    data['time'] = event.time.millisecondsSinceEpoch;
    data['latitude'] = event.coordinates?.latitude;
    data['longitude'] = event.coordinates?.longitude;
    data['travel_mode'] = event.travelMode;
    data['distance'] = event.distance;
    return await db.insert('timeline_events', data);
  }

  Future<List<TimelineEvent>> getAllTimelineEvents() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('timeline_events');
    return maps.map((map) => TimelineEvent.fromJson(map)).toList();
  }

  Future<void> generateLocationEventsForDate(DateTime date) async {
    final db = await database;
    final points = await getLocationPointsForDate(date);
    if (points.length < 2) return;

    // Simple clustering: group points close in space and time
    List<List<Map<String, dynamic>>> clusters = [];
    List<Map<String, dynamic>> currentCluster = [points[0]];
    LatLng currentCenter = LatLng(points[0]['latitude'], points[0]['longitude']);
    DateTime clusterStart = DateTime.fromMillisecondsSinceEpoch(points[0]['timestamp']);

    for (int i = 1; i < points.length; i++) {
      final point = points[i];
      final coord = LatLng(point['latitude'], point['longitude']);
      final time = DateTime.fromMillisecondsSinceEpoch(point['timestamp']);
      final dist = const Distance().as(LengthUnit.Meter, currentCenter, coord);
      final timeDiff = time.difference(clusterStart).inMinutes;

      if (dist < 100 && timeDiff < 10) {
        currentCluster.add(point);
        // Update center approximate
        currentCenter = LatLng(
          (currentCenter.latitude + coord.latitude) / 2,
          (currentCenter.longitude + coord.longitude) / 2,
        );
      } else {
        // End current cluster as 'arrived' event
        if (currentCluster.length > 1) {
          final durationMs = time.difference(clusterStart).inMilliseconds;
          final avgLat = currentCluster.map((p) => p['latitude']).reduce((a, b) => a + b) / currentCluster.length;
          final avgLng = currentCluster.map((p) => p['longitude']).reduce((a, b) => a + b) / currentCluster.length;
          final event = TimelineEvent(
            time: clusterStart,
            title: 'Arrived at location',
            description: 'Spent ${ (durationMs / 1000 / 60).round() } minutes here',
            coordinates: LatLng(avgLat, avgLng),
            eventType: 'arrived',
            duration: durationMs,
          );
          await insertTimelineEvent(event);
        }
        // Start new cluster
        currentCluster = [point];
        currentCenter = coord;
        clusterStart = time;
      }
    }

    // Last cluster
    if (currentCluster.length > 1) {
      final time = DateTime.fromMillisecondsSinceEpoch(points.last['timestamp']);
      final durationMs = time.difference(clusterStart).inMilliseconds;
      final avgLat = currentCluster.map((p) => p['latitude']).reduce((a, b) => a + b) / currentCluster.length;
      final avgLng = currentCluster.map((p) => p['longitude']).reduce((a, b) => a + b) / currentCluster.length;
      final event = TimelineEvent(
        time: clusterStart,
        title: 'Arrived at location',
        description: 'Spent ${ (durationMs / 1000 / 60).round() } minutes here',
        coordinates: LatLng(avgLat, avgLng),
        eventType: 'arrived',
        duration: durationMs,
      );
      await insertTimelineEvent(event);
    }

    // Travel events between clusters (simplified, add if needed)
  }

  Future<List<TimelineEvent>> getEventsForDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    List<Map<String, dynamic>> maps = await db.query(
      'timeline_events',
      where: 'time >= ? AND time < ?',
      whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
    );
    return maps.map((map) => TimelineEvent.fromJson(map)).toList();
  }

  Future<void> generateEventsFromTrip(Trip trip) async {
    final db = await database;

    try {
      // Delete existing events for this trip
      await db.delete('timeline_events', where: 'trip_id = ?', whereArgs: [trip.id]);
    } catch (e) {
      // If table doesn't exist, ignore delete
      print('Table timeline_events may not exist yet: $e');
    }

    if (trip.latitude == null || trip.longitude == null) {
      // If no coordinates, skip detailed generation or use defaults
      return;
    }

    final baseCoord = LatLng(trip.latitude!, trip.longitude!);
    final List<TimelineEvent> events = [];
    LatLng previousCoord = baseCoord;
    double cumulativeDistance = 0.0;

    // Start event
    final startEvent = TimelineEvent(
      time: trip.plannedDate,
      title: 'Start ${trip.name}',
      description: 'Beginning of your trip to ${trip.location}',
      location: trip.location,
      coordinates: baseCoord,
      imageUrl: trip.imageUrl,
      tripId: trip.id,
      eventType: 'trip_start',
      travelMode: null,
      distance: null,
    );
    events.add(startEvent);

    // Activity events - generate offsets for simulation
    final duration = trip.endDate.difference(trip.plannedDate);
    final activityInterval = duration.inMinutes / (trip.activities.length + 1);
    final random = DateTime.now().millisecondsSinceEpoch % 100; // Simple pseudo-random
    for (int i = 0; i < trip.activities.length; i++) {
      final offsetLat = (i + 1) * 0.01 + (random / 1000.0); // Simulate path
      final offsetLng = (i + 1) * 0.01;
      final activityCoord = LatLng(baseCoord.latitude + offsetLat, baseCoord.longitude + offsetLng);

      final activityTime = trip.plannedDate.add(Duration(minutes: ((i + 1) * activityInterval).round()));

      // Calculate distance from previous
      final distanceKm = const Distance().as(LengthUnit.Kilometer, previousCoord, activityCoord);
      final travelMode = _inferTravelMode(distanceKm);

      final activityEvent = TimelineEvent(
        time: activityTime,
        title: trip.activities[i],
        description: trip.notes.isNotEmpty ? trip.notes : 'Planned activity',
        location: trip.location,
        coordinates: activityCoord,
        imageUrl: trip.imageUrl,
        tripId: trip.id,
        eventType: 'activity',
        travelMode: travelMode,
        distance: distanceKm,
      );
      events.add(activityEvent);
      previousCoord = activityCoord;
      cumulativeDistance += distanceKm;
    }

    // End event - further offset
    final endCoord = LatLng(baseCoord.latitude + (trip.activities.length + 1) * 0.01, baseCoord.longitude + (trip.activities.length + 1) * 0.01);
    final endDistanceKm = const Distance().as(LengthUnit.Kilometer, previousCoord, endCoord);
    final endTravelMode = _inferTravelMode(endDistanceKm);

    final endEvent = TimelineEvent(
      time: trip.endDate,
      title: 'End ${trip.name}',
      description: 'Trip to ${trip.location} completed',
      location: trip.location,
      coordinates: endCoord,
      imageUrl: trip.imageUrl,
      tripId: trip.id,
      eventType: 'trip_end',
      travelMode: endTravelMode,
      distance: endDistanceKm,
    );
    events.add(endEvent);

    // Insert all events
    for (final event in events) {
      await insertTimelineEvent(event);
    }
  }

  String _inferTravelMode(double distanceKm) {
    if (distanceKm < 2.0) {
      return 'walking';
    } else if (distanceKm < 10.0) {
      return 'driving';
    } else {
      return 'other';
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<int> insertPreviousTrip(PreviousTrip prevTrip) async {
    final db = await database;
    final expensesJson = prevTrip.expenses.map((e) => {
      'description': e.description,
      'amount': e.amount,
      'icon': e.icon.codePoint,
    }).toList();
    final photosJson = prevTrip.photos.map((p) => {
      'imageUrl': p.imageUrl,
      'date': p.date.millisecondsSinceEpoch,
      'location': p.location,
    }).toList();
    Map<String, dynamic> data = {
      'trip_id': prevTrip.baseTrip.id,
      'route': jsonEncode(prevTrip.route),
      'expenses': jsonEncode(expensesJson),
      'photos': jsonEncode(photosJson),
    };
    return await db.insert('previous_trips', data);
  }

  Future<List<PreviousTrip>> getPreviousTrips() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('previous_trips');
    List<PreviousTrip> previousTrips = [];
    for (var prevMap in maps) {
      // Get the base trip
      final tripMaps = await db.query('trips', where: 'id = ?', whereArgs: [prevMap['trip_id']]);
      if (tripMaps.isEmpty) continue;
      final tripMap = tripMaps.first;
      final baseTrip = Trip(
        id: tripMap['id'] as int?,
        name: tripMap['name'] as String,
        location: tripMap['location'] as String,
        latitude: tripMap['latitude'] as double?,
        longitude: tripMap['longitude'] as double?,
        imageUrl: (tripMap['image_url'] as String?) ?? '',
        plannedDate: DateTime.fromMillisecondsSinceEpoch(tripMap['planned_date'] as int),
        endDate: DateTime.fromMillisecondsSinceEpoch(tripMap['end_date'] as int),
        notes: (tripMap['notes'] as String?) ?? '',
        activities: List<String>.from((jsonDecode((tripMap['activities'] as String?) ?? '[]') as List<dynamic>)),
        status: (tripMap['status'] as String?) ?? 'completed',
      );

      // Parse route
      final route = List<String>.from(jsonDecode(prevMap['route'] ?? '[]'));

      // Parse expenses
      final expensesJson = jsonDecode(prevMap['expenses'] ?? '[]');
      final expenses = expensesJson.map<Expense>((json) => Expense(
        description: json['description'] as String,
        amount: (json['amount'] as num).toDouble(),
        icon: IconData(json['icon'] as int),
      )).toList();

      // Parse photos
      final photosJson = jsonDecode(prevMap['photos'] ?? '[]');
      final photos = photosJson.map<TripPhoto>((json) => TripPhoto(
        imageUrl: json['imageUrl'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
        location: json['location'] as String,
      )).toList();

      final prevTrip = PreviousTrip(
        baseTrip: baseTrip,
        route: route,
        expenses: expenses,
        photos: photos,
      );
      previousTrips.add(prevTrip);
    }
    return previousTrips;
  }

  // CRUD for Location Points
  Future<int> insertLocationPoint(Map<String, dynamic> point) async {
    final db = await database;
    return await db.insert('location_points', point);
  }

  Future<List<Map<String, dynamic>>> getLocationPointsForDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return await db.query(
      'location_points',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
      orderBy: 'timestamp ASC',
    );
  }
}