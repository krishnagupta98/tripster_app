// lib/signing_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_application_1/planned_trips_page.dart';
import 'package:flutter_application_1/models/trip_model.dart';
import 'package:flutter_application_1/models/previous_trip_model.dart';
import 'package:flutter_application_1/widgets/trips_grid_view.dart';
import 'package:flutter_application_1/widgets/add_trip_form.dart';

// Enhanced color palette for professional look
const Color kPrimaryBlue = Color(0xFF1E40AF);
const Color kSecondaryBlue = Color(0xFF3B82F6);
const Color kAccentBlue = Color(0xFF60A5FA);
const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kLightBlue = Color(0xFFF0F4FF); // Correctly defined here
const Color kGreyText = Color(0xFF475569);
const Color kLightGrey = Color(0xFF94A3B8);
const Color kSurfaceWhite = Color(0xFFFAFAFA);
const String sloganText = "Discover. Plan. Experience.";

enum UiPhase {
  signInPrompt,
  greetingCentered,
  dashboardVisible,
}

class SigningPage extends StatefulWidget {
  const SigningPage({super.key});
  @override
  State<SigningPage> createState() => _SigningPageState();
}

class _SigningPageState extends State<SigningPage> {
  final _nameController = TextEditingController();
  String _userName = '';
  UiPhase _phase = UiPhase.signInPrompt;
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Enhanced planned trips data
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
      expenses: [
        Expense(description: "Flights", amount: 650.00, icon: Icons.flight_takeoff),
        Expense(description: "Hotel Stay", amount: 450.00, icon: Icons.hotel),
        Expense(description: "Pasta Dinner", amount: 45.50, icon: Icons.restaurant),
        Expense(description: "Museum Tickets", amount: 60.00, icon: Icons.museum),
      ],
      photos: [
        TripPhoto(imageUrl: 'https://images.unsplash.com/photo-1525874684015-58379d421a52?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80', date: DateTime(2023, 7, 11), location: "Colosseum"),
        TripPhoto(imageUrl: 'https://images.unsplash.com/photo-1542820239-6b62eb8d774a?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1935&q=80', date: DateTime(2023, 7, 12), location: "Trevi Fountain"),
      ],
    ),
  ];

  void _submitName() {
    if (_nameController.text.trim().isNotEmpty) {
      setState(() {
        _userName = _nameController.text.trim();
        _phase = UiPhase.greetingCentered;
      });
      FocusScope.of(context).unfocus();
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _phase = UiPhase.dashboardVisible;
          });
        }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newTrip.name} has been added to your planned trips!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurfaceWhite,
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _buildCurrentPhaseWidget(),
            ),
            _buildTopLeftBranding(),
          ],
        ),
      ),
      bottomNavigationBar: _phase == UiPhase.dashboardVisible
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.schedule_outlined),
                    activeIcon: Icon(Icons.schedule),
                    label: 'Planned',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.history_outlined),
                    activeIcon: Icon(Icons.history),
                    label: 'Previous',
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: kPrimaryBlue,
                unselectedItemColor: kLightGrey,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 12),
                type: BottomNavigationBarType.fixed,
                onTap: _onItemTapped,
              ),
            ).animate().slideY(begin: 1.0, duration: 400.ms, curve: Curves.easeOutCubic)
          : null,
      floatingActionButton: _phase == UiPhase.dashboardVisible
          ? FloatingActionButton.extended(
              onPressed: _showAddTripSheet,
              label: Text(
                'Plan Trip',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              icon: const Icon(Icons.add_location_alt_outlined, size: 20),
              backgroundColor: kPrimaryBlue,
              foregroundColor: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.8, 0.8))
          : null,
    );
  }

  Widget _buildCurrentPhaseWidget() {
    switch (_phase) {
      case UiPhase.signInPrompt:
        return _buildSignInView();
      case UiPhase.greetingCentered:
        return _buildCenteredGreeting();
      case UiPhase.dashboardVisible:
        return _buildDashboardContent();
    }
  }

  Widget _buildSignInView() {
    return SingleChildScrollView(
      key: const ValueKey('signInView'),
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kSecondaryBlue, kPrimaryBlue],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: kSecondaryBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: const Icon(Icons.flight_takeoff_rounded, size: 60, color: Colors.white),
            ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),
            const SizedBox(height: 32),
            Text(
              sloganText,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(fontSize: 34, fontWeight: FontWeight.w700, color: kDarkBlue, height: 1.2),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
            const SizedBox(height: 12),
            Text(
              "Your personal travel companion",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: kGreyText),
            ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 48),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _submitName(),
                style: GoogleFonts.poppins(color: kDarkBlue, fontSize: 16, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  labelText: 'What should we call you?',
                  labelStyle: GoogleFonts.poppins(color: kGreyText, fontSize: 14, fontWeight: FontWeight.w500),
                  hintText: 'Enter your first name',
                  hintStyle: GoogleFonts.poppins(color: kLightGrey, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: const BorderSide(color: kPrimaryBlue, width: 2)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: BorderSide(color: Colors.grey.shade200, width: 1)),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: kLightBlue, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.person_outline, color: kPrimaryBlue, size: 20),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [kPrimaryBlue, kSecondaryBlue],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: ElevatedButton(
                onPressed: _submitName,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Start Your Journey', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildCenteredGreeting() {
    return Center(
      key: const ValueKey('centeredGreeting'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                Text(
                  'Welcome,',
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w500, color: kGreyText),
                ),
                const SizedBox(height: 8),
                Text(
                  _userName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(fontSize: 36, fontWeight: FontWeight.w700, color: kPrimaryBlue),
                ),
              ],
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    final List<Widget> dashboardPages = [
      TripsGridView(trips: _plannedTrips, tripType: TripType.planned),
      TripsGridView(trips: _previousTrips, tripType: TripType.previous),
    ];
    return Padding(
      key: const ValueKey('dashboardContent'),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Column(
        children: [
          const SizedBox(height: 120),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 4))],
            ),
            child: TextField(
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
            child: IndexedStack(
              index: _selectedIndex,
              children: dashboardPages,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopLeftBranding() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOutCubic,
      top: _phase == UiPhase.dashboardVisible ? 20 : -100, // Adjusted for SafeArea
      left: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [kSecondaryBlue, kPrimaryBlue]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.flight_takeoff_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              'Tripster',
              style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: kDarkBlue),
            ),
          ],
        ),
      ),
    ).animate(target: _phase == UiPhase.dashboardVisible ? 1.0 : 0.0).fadeIn(delay: 300.ms).slideX(begin: -0.5);
  }
}