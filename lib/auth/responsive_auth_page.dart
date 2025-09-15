// lib/auth/responsive_auth_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kPrimaryBlue = Color(0xFF1E40AF);
const Color kDarkBlue = Color(0xFF1E3A8A);

class ResponsiveAuthPage extends StatelessWidget {
  final Widget formWidget;

  const ResponsiveAuthPage({super.key, required this.formWidget});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use a breakpoint to switch between layouts
        if (constraints.maxWidth < 800) {
          // Mobile Layout
          return formWidget;
        } else {
          // Desktop/Web Layout
          return Row(
            children: [
              // Left side decorative panel
              Expanded(
                child: Container(
                  color: kDarkBlue,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 80),
                          const SizedBox(height: 24),
                          Text(
                            "Tripster",
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Discover. Plan. Experience.",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Right side form
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: formWidget,
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }
}