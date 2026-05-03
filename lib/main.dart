// OSH Monitor App — main entry point
// All screens are in lib/screens/

import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

// App starts here
void main() {
  runApp(const OSHApp());
}

// Root widget — sets up theme and opens SplashScreen
class OSHApp extends StatelessWidget {
  const OSHApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // App name shown in phone task switcher
      title: 'OSH Monitor',

      // Hide the debug banner
      debugShowCheckedModeBanner: false,

      // Green theme for the whole app
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // Forest green
        ),
        useMaterial3: true,
      ),

      // First screen when app opens
      home: const SplashScreen(),
    );
  }
}