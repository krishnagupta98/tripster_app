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
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  int _selectedIndex = 0;
  bool _isSearchFocused = false;

  final List<String> _popularLocations = [
    'Tokyo, Japan', 'Paris, France', 'Rome, Italy', 'Bali, Indonesia', 
    'New York, USA', 'London, UK', 'Dubai, UAE', 'Maldives'
  ];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChange);
  }

  void _onSearchFocusChange() {
    if (mounted) {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Trip> _plannedTrips = [
    Trip(
      name: 'Autumn in Japan',
      location: 'Kyoto, Japan',
      imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80',
      plannedDate: DateTime(2025, 10, 20),
      endDate: DateTime(2025, 10, 30),
      notes: "Visit ancient temples, walk through the Arashiyama Bamboo Grove, and experience a traditional tea ceremony.",
      activities: ["Kinkaku-ji Temple", "Fushimi Inari Shrine", "Gion District"],
    ),
    Trip(
      name: 'Winter Skiing',
      location: 'Swiss Alps',
      imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80',
      plannedDate: DateTime(2026, 1, 15),
      endDate: DateTime(2026, 1, 22),
      notes: "A winter wonderland trip. Focus on skiing in Zermatt and enjoying the scenic train rides.",
      activities: ["Skiing", "Matterhorn Glacier Paradise", "Gornergrat Railway"],
    ),
  ];

  final List<PreviousTrip> _previousTrips = [
    PreviousTrip(
      baseTrip: Trip(
          name: 'Summer in Italy',
          location: 'Rome, Italy',
          imageUrl: 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1996&q=80',
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
        TripPhoto(imageUrl: 'https://images.unsplash.com/photo-1525874684015-58379d421a52?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80', date: DateTime(2023, 7, 11), location: "Colosseum"),
      ],
    ),
  ];

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
                Text(
                  "My Profile",
                  style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: kDarkBlue),
                ),
                const SizedBox(height: 8),
                if (user?.email != null)
                  Text(
                    user!.email!,
                    style: GoogleFonts.poppins(fontSize: 16, color: kGreyText),
                  ),
                const SizedBox(height: 24),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text("My Account", style: GoogleFonts.poppins()),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: Text("Settings", style: GoogleFonts.poppins()),
                  onTap: () {
                    Navigator.pop(context);
                  },
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
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurfaceWhite,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            _buildDashboardContent(),
            _buildTopLeftBranding(),
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
            BottomNavigationBarItem(icon: Icon(Icons.schedule_outlined), activeIcon: Icon(Icons.schedule), label: 'Planned'),
            BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Previous'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: kPrimaryBlue,
          unselectedItemColor: kLightGrey,
          backgroundColor: Colors.transparent,
          elevation: 0,
          onTap: _onItemTapped,
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
      TripsGridView(trips: _plannedTrips, tripType: TripType.planned),
      TripsGridView(trips: _previousTrips, tripType: TripType.previous),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Column(
        children: [
          const SizedBox(height: 100),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 4))],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: kDarkBlue),
              decoration: InputDecoration(
                hintText: 'Where would you like to go?',
                hintStyle: GoogleFonts.poppins(color: kLightGrey, fontSize: 15, fontWeight: FontWeight.w400),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: kLightBlue, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.search_rounded, color: kPrimaryBlue, size: 20),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0), borderSide: const BorderSide(color: kPrimaryBlue, width: 2)),
              ),
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: -0.1),
          const SizedBox(height: 24),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isSearchFocused
                  ? _buildSuggestionsList()
                  : IndexedStack(
                      index: _selectedIndex,
                      children: dashboardPages,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return ListView.builder(
      key: const ValueKey('suggestions'),
      itemCount: _popularLocations.length,
      itemBuilder: (context, index) {
        final location = _popularLocations[index];
        return ListTile(
          leading: const Icon(Icons.location_on_outlined, color: kGreyText),
          title: Text(location, style: GoogleFonts.poppins()),
          onTap: () {
            setState(() {
              _searchController.text = location;
              _searchFocusNode.unfocus();
            });
          },
        );
      },
    ).animate().fadeIn();
  }
  
  Widget _buildTopLeftBranding() {
    return Positioned(
      top: 20,
      left: 24,
      right: 24,
      child: Row(
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
      ),
    ).animate().fadeIn(delay: 300.ms);
  }
}