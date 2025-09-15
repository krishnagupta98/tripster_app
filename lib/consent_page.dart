// lib/consent_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/splash_screen.dart';

const Color kPrimaryBlue = Color(0xFF1E40AF);
const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kGreyText = Color(0xFF475569);

class ConsentPage extends StatelessWidget {
  const ConsentPage({super.key});

  Future<void> _requestPermissionsAndContinue(BuildContext context) async {
    // Request permissions
    await Permission.locationWhenInUse.request();
    await Permission.activityRecognition.request();

    // Save consent decision
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_given_consent', true);

    // Navigate to the main app flow
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // The SingleChildScrollView makes the content scrollable, preventing overflow
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // This ensures the content tries to fill the screen vertically
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // This column groups the top content
                  Column(
                    children: [
                      const SizedBox(height: 40), // Top spacing
                      const Icon(Icons.privacy_tip_outlined, size: 80, color: kPrimaryBlue),
                      const SizedBox(height: 24),
                      Text(
                        "Your Privacy Matters",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: kDarkBlue),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "To help improve transportation planning, Tripster collects anonymous trip data in the background. Your data is always anonymized and secure.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 16, color: kGreyText, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      _buildPermissionItem(
                        icon: Icons.location_on_outlined,
                        title: "Location",
                        subtitle: "To record the start, end, and routes of your trips.",
                      ),
                      const SizedBox(height: 16),
                      _buildPermissionItem(
                        icon: Icons.directions_walk,
                        title: "Physical Activity",
                        subtitle: "To automatically detect if you are walking, driving, or cycling.",
                      ),
                    ],
                  ),
                  
                  // This section for the button is pushed to the bottom
                  Padding(
                    padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _requestPermissionsAndContinue(context),
                        style: ElevatedButton.styleFrom(backgroundColor: kPrimaryBlue, foregroundColor: Colors.white),
                        child: Text('I Agree & Continue', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({required IconData icon, required String title, required String subtitle}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: kPrimaryBlue.withOpacity(0.1),
        child: Icon(icon, color: kPrimaryBlue),
      ),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins()),
    );
  }
}