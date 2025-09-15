// lib/auth/signin_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/auth/signup_screen.dart';

const Color kPrimaryBlue = Color(0xFF1E40AF);
const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kGreyText = Color(0xFF475569);

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Authentication failed")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 100,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // NEW: Added the Tripster logo and name
                const Icon(Icons.flight_takeoff_rounded, size: 80, color: kPrimaryBlue),
                const SizedBox(height: 16),
                Text(
                  "Tripster",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: kDarkBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text("Sign in to continue your journey", style: GoogleFonts.poppins(fontSize: 16, color: kGreyText)),
                const SizedBox(height: 48),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimaryBlue, foregroundColor: Colors.white),
                    child: _isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SignUpScreen()));
                  },
                  child: const Text("Don't have an account? Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}