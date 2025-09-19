// lib/signing_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/planned_trips_page.dart';
import 'package:flutter_application_1/models/trip_model.dart';
import 'package:flutter_application_1/models/previous_trip_model.dart';
import 'package:flutter_application_1/widgets/trips_grid_view.dart';
import 'package:flutter_application_1/widgets/add_trip_form.dart';
import 'package:flutter_application_1/widgets/ongoing_trip_view.dart';
import 'package:flutter_application_1/services/location_service.dart';
import 'package:flutter_application_1/widgets/explore_map_view.dart';
import 'package:geocoding/geocoding.dart';

// Enhanced color palette for professional look
const Color kPrimaryBlue = Color(0xFF1E40AF);
const Color kSecondaryBlue = Color(0xFF3B82F6);
const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kGreyText = Color(0xFF475569);
const Color kLightGrey = Color(0xFF94A3B8);
const Color kSurfaceWhite = Color(0xFFFAFAFA);
const Color kLightBlue = Color(0xFFF0F4FF);

class SigningPage extends StatefulWidget {
  const SigningPage({super.key});
  @override
  State<SigningPage> createState() => _SigningPageState();
}

class _SigningPageState extends State<SigningPage> {
  int _selectedIndex = 0;

  // State for the ongoing trip feature
  final LocationService _locationService = LocationService();
  Trip? _ongoingTrip;
  Timer? _tripCheckTimer;

  @override
  void initState() {
    super.initState();
    // Start checking for an ongoing trip when the page loads
    _startOngoingTripCheck();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Sample Data
  final List<Trip> _plannedTrips = [
    Trip(
        name: 'Haldwani Weekend',
        location: 'Haldwani, Uttarakhand',
        imageUrl: 'https://images.unsplash.com/photo-1620921499993-6d5d7a421e9b?w=500',
        plannedDate: DateTime(2025, 9, 21),
        endDate: DateTime(2025, 9, 23),
        notes: "A weekend trip to the foothills.",
        activities: ["Hiking", "Local market visit"]),
    Trip(
      name: 'Autumn in Japan',
      location: 'Kyoto, Japan',
      imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=500',
      plannedDate: DateTime(2025, 10, 20),
      endDate: DateTime(2025, 10, 30),
      notes: "Visit ancient temples, walk through the Arashiyama Bamboo Grove...",
      activities: ["Kinkaku-ji Temple", "Fushimi Inari Shrine", "Gion District"],
    ),
  ];

  final List<PreviousTrip> _previousTrips = [
    PreviousTrip(
      baseTrip: Trip(
          name: 'Summer in Italy',
          location: 'Rome, Italy',
          imageUrl: 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=500',
          plannedDate: DateTime(2023, 7, 10),
          endDate: DateTime(2023, 7, 18),
          notes: "Explored the Colosseum, Vatican City, and ate amazing pasta.",
          activities: ["Colosseum Tour", "St. Peter's Basilica", "Trevi Fountain"]),
      route: ["Colosseum, Rome, Italy", "Trevi Fountain, Rome, Italy", "Vatican City"],
      expenses: [
        Expense(description: "Flights", amount: 650.00, icon: Icons.flight_takeoff),
        Expense(description: "Hotel Stay", amount: 450.00, icon: Icons.hotel),
      ],
      photos: [
        TripPhoto(imageUrl: 'https://images.unsplash.com/photo-1525874684015-58379d421a52?w=500', date: DateTime(2023, 7, 11), location: "Colosseum"),
      ],
    ),
  ];

  void _startOngoingTripCheck() {
    _checkForOngoingTrip(); // Check immediately on load
    _tripCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkForOngoingTrip(); // Then check again every 5 minutes
    });
  }

  Future<void> _checkForOngoingTrip() async {
    final now = DateTime.now();
    Trip? currentlyOngoingTrip;

    for (final trip in _plannedTrips) {
      if (!now.isBefore(trip.plannedDate) && !now.isAfter(trip.endDate.add(const Duration(days: 1)))) {
        try {
          final position = await _locationService.getCurrentLocation();
          if (position == null) continue;

          List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
          if (placemarks.isNotEmpty) {
            final currentCity = placemarks.first.locality ?? '';
            
            if (trip.location.toLowerCase().contains(currentCity.toLowerCase())) {
              currentlyOngoingTrip = trip;
              break; 
            }
          }
        } catch (e) {
          print("Error checking location for ongoing trip: $e");
        }
      }
    }

    if (mounted && currentlyOngoingTrip != _ongoingTrip) {
      setState(() {
        _ongoingTrip = currentlyOngoingTrip;
      });
    }
  }
  
  void _showAddTripSheet() async {
    final newTrip = await showModalBottomSheet<Trip>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return const AddTripForm();
      },
    );

    if (newTrip != null && mounted) {
      setState(() {
        _plannedTrips.add(newTrip);
      });
    }
  }
  
  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final user = FirebaseAuth.instance.currentUser;
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_circle, size: 60, color: kPrimaryBlue),
                const SizedBox(height: 12),
                Text("My Profile", style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: kDarkBlue)),
                const SizedBox(height: 8),
                if (user?.email != null)
                  Text(user!.email!, style: GoogleFonts.poppins(fontSize: 16, color: kGreyText)),
                const SizedBox(height: 24),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text("My Account", style: GoogleFonts.poppins()),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: Text("Settings", style: GoogleFonts.poppins()),
                  onTap: () => Navigator.pop(context),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text("Log Out", style: GoogleFonts.poppins(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    FirebaseAuth.instance.signOut();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tripCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurfaceWhite,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: _buildTopLeftBranding(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildDashboardContent(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Explore'),
            BottomNavigationBarItem(icon: Icon(Icons.schedule_outlined), activeIcon: Icon(Icons.schedule), label: 'Planned'),
            BottomNavigationBarItem(icon: Icon(Icons.directions_run_outlined), activeIcon: Icon(Icons.directions_run), label: 'Ongoing'),
            BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Previous'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: kPrimaryBlue,
          unselectedItemColor: kLightGrey,
          backgroundColor: Colors.transparent,
          elevation: 0,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ).animate().slideY(begin: 1.0, duration: 400.ms, curve: Curves.easeOutCubic),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTripSheet,
        label: Text('Plan Trip', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        icon: const Icon(Icons.add_location_alt_outlined),
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
      ).animate().fadeIn(delay: 800.ms),
    );
  }

  Widget _buildDashboardContent() {
    final List<Widget> dashboardPages = [
      const ExploreMapView(),
      TripsGridView(trips: _plannedTrips, tripType: TripType.planned),
      OngoingTripView(ongoingTrip: _ongoingTrip),
      TripsGridView(trips: _previousTrips, tripType: TripType.previous),
    ];
    
    // REMOVED Search Bar and related widgets from here for a cleaner layout
    return IndexedStack(
      index: _selectedIndex,
      children: dashboardPages,
    );
  }
  
  Widget _buildTopLeftBranding() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: 40),
            const SizedBox(width: 12),
            Text(
              'Tripster',
              style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: kDarkBlue),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15)],
          ),
          child: IconButton(
            icon: const Icon(Icons.person_outline, color: kGreyText),
            onPressed: _showProfileSheet,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }
}