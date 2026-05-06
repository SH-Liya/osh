
// main.dart — OSH Monitor App
// Entry point of the OSH temperature monitoring application
// Firebase has been connected for authentication and database
// All screens are organised inside the lib/screens/ folder


// Flutter's core material library imported for UI widgets
import 'package:flutter/material.dart';

// Firebase core imported to initialise the Firebase project
import 'package:firebase_core/firebase_core.dart';

// Auto-generated Firebase configuration file imported
// Generated using the flutterfire configure command
import 'firebase_options.dart';

// Splash screen imported as the first screen on app launch
import 'screens/splash_screen.dart';

// main() set as async because Firebase must be initialised
// before the app starts running
void main() async {

  // Ensures Flutter is ready before Firebase loads
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialised using the osh-monitor project configuration
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // OSH application launched
  runApp(const OSHApp());
}

// OSHApp is the root widget of the application
// StatelessWidget used because the app setup never changes
class OSHApp extends StatelessWidget {
  const OSHApp({super.key});

  // MaterialApp built to wrap the entire application
  // Sets the global theme and launches SplashScreen first
  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      // App title shown in the phone task switcher
      title: 'OSH Monitor',

      // Debug banner disabled for a cleaner appearance
      debugShowCheckedModeBanner: false,

      // Green colour theme applied across all screens
      // Seed colour 0xFF2E7D32 is forest green
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
        ),
        // Material Design 3 enabled for modern UI styling
        useMaterial3: true,
      ),

      // SplashScreen set as the first screen on app launch
      home: const SplashScreen(),
    );
  }
}