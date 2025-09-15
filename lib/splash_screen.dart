// lib/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/auth/signin_screen.dart';
import 'package:flutter_application_1/signing_page.dart';
import 'package:flutter_application_1/consent_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color kPrimaryBlue = Color(0xFF1E40AF);
const Color kDarkBlue = Color(0xFF1E3A8A);

/// This widget checks the user's authentication state and directs them
/// to either the sign-in page or the main app dashboard.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the snapshot has data, a user is logged in
        if (snapshot.hasData) {
          return const SigningPage();
        }
        // Otherwise, the user is not logged in
        else {
          return const SignInScreen();
        }
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  /// Checks if consent has been given and navigates to the correct page.
  Future<void> _navigate() async {
    // Wait for 3 seconds for the splash to be visible
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final bool hasConsented = prefs.getBool('has_given_consent') ?? false;

    if (hasConsented) {
      // If consent is already given, go to the AuthGate
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    } else {
      // If no consent, show the ConsentPage for the first time
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ConsentPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey[100]!],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 120,
              ),
              const SizedBox(height: 20),
              Text(
                'Tripster',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                  color: kDarkBlue,
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 800.ms),
    );
  }
}