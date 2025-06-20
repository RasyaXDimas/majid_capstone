// splash_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
// Hapus impor yang tidak perlu jika hanya menavigasi ke AuthWrapper
// import 'package:capstone/pages/admin_dashboard.dart';
// import 'package:capstone/pages/sign_in.dart';
// import 'package:capstone/admin_auth_service.dart';

// Impor AuthWrapper
import 'package:capstone/main.dart'; // Jika AuthWrapper ada di main.dart
                                  // atau path yang sesuai jika AuthWrapper di file terpisah

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToAuthWrapper();
  }

  void _navigateToAuthWrapper() {
    Timer(const Duration(seconds: 3), () {
      if (mounted) { // Selalu baik untuk memeriksa apakah widget masih terpasang
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthWrapper()), // Selalu ke AuthWrapper
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 3),
          curve: Curves.easeInOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.5 + (0.8 * value),
                child: child,
              ),
            );
          },
          child: SvgPicture.asset(
            'assets/majid.svg',
            width: 1000,
            height: 1000,
          ),
        ),
      ),
    );
  }
}