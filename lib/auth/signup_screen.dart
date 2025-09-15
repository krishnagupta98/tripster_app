// lib/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/auth/responsive_auth_page.dart';

const Color kPrimaryBlue = Color(0xFF1E40AF);
const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kGreyText = Color(0xFF475569);

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: ResponsiveAuthPage(
        formWidget: _SignUpForm(),
      ),
    );
  }
}

class _SignUpForm extends StatefulWidget {
  const _SignUpForm();

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match.")));
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Sign up failed")));
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
      // App bar for mobile view to have a back button
      appBar: MediaQuery.of(context).size.width < 800
          ? AppBar(
              title: Text("Create Account", style: GoogleFonts.playfairDisplay(color: kDarkBlue, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: kDarkBlue),
            )
          : null,
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Join Tripster", style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: kDarkBlue)),
            const SizedBox(height: 8),
            Text("Start planning your next adventure", style: GoogleFonts.poppins(fontSize: 16, color: kGreyText)),
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
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryBlue, foregroundColor: Colors.white),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('Create Account'),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account?"),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Sign In"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}