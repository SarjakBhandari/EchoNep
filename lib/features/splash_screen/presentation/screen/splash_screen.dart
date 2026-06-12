import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatelessWidget {
  final String? message;

  const SplashScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF062A3A), Color(0xFF0B6E99), Color(0xFFF2B705)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.language, color: Colors.white, size: 72),
              const SizedBox(height: 24),
              Text(
                'ECHONEP',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message ?? 'Loading app state...',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
