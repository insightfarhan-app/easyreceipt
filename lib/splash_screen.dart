import 'package:EasyInvoice/Home/homepage.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_update/in_app_update.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progressValue = 0.0;
  String _loadingText = "Initializing...";

  @override
  void initState() {
    super.initState();
    _startAppSequence();
  }

  Future<void> _startAppSequence() async {
    // 1. Start the In-App Update check immediately in the background
    _checkForUpdate();

    // 2. Run the "Construction" Loading Simulation
    // Step 1: Initialize
    setState(() {
      _progressValue = 0.1;
      _loadingText = "Building App State...";
    });
    await Future.delayed(const Duration(milliseconds: 1000));

    // Step 2: Check Data
    if (mounted) {
      setState(() {
        _progressValue = 0.45;
        _loadingText = "Checking your data...";
      });
    }
    await Future.delayed(const Duration(milliseconds: 1200));

    // Step 3: Fetch Data
    if (mounted) {
      setState(() {
        _progressValue = 0.85;
        _loadingText = "Fetching data...";
      });
    }
    await Future.delayed(const Duration(milliseconds: 1000));

    // Step 4: Finalize
    if (mounted) {
      setState(() {
        _progressValue = 1.0;
        _loadingText = "Opening EasyInvoice...";
      });
    }
    await Future.delayed(const Duration(milliseconds: 500));

    // 3. Navigate to Home
    _navigateToHome();
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  // --- LOGIC: FORCE UPDATE ---
  Future<void> _checkForUpdate() async {
    try {
      AppUpdateInfo info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      debugPrint("Update check failed (Expected in Debug Mode): $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Professional White Background
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            Center(
              child: SizedBox(
                height: 300,
                width: 300,
                child: Lottie.asset(
                  'assets/animations/splash_anim.json',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.domain_verification_rounded,
                      size: 100,
                      color: Colors.blue.shade700,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              height: 30,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Text(
                  _loadingText,
                  key: ValueKey<String>(_loadingText),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: _progressValue),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                builder: (context, value, _) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2563EB),
                      ),
                    ),
                  );
                },
              ),
            ),

            const Spacer(flex: 3),

            Column(
              children: [
                Text(
                  "EasyInvoice",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Version 1.3.0",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
