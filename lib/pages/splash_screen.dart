import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:capstone/pages/sign_in.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignInPage()),
      );
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
              opacity: 1 * value,
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
