import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:swap/home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to the home page after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set background color
      body: Center(
        child: Lottie.asset(
          'assets/Animation - 1741456733360.json', 
          width: 200,
          height: 200,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}