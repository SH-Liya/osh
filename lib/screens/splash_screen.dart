
// splash_screen.dart
// First screen the user sees when they open the OSH app
// Shows the logo with a fade and bounce animation
// Loading dots animate across the bottom
// After 3 seconds automatically goes to AgreementScreen


import 'package:flutter/material.dart';

// Import next screen so we can navigate to it after 3 seconds
import 'agreement_screen.dart';

// StatefulWidget because the dots change (state changes)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  // Connects this widget to its state class below
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// SingleTickerProviderStateMixin allows us to use AnimationController
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  // Controls the animation — like a stopwatch running from 0 to 1.2s
  late AnimationController _controller;

  // Fade animation — logo goes from invisible (0.0) to fully visible (1.0)
  late Animation<double> _fadeAnim;

  // Scale animation — logo grows from 70% size to 100% with bounce
  late Animation<double> _scaleAnim;

  // Tracks which dot is currently highlighted — starts at 0 (first dot)
  int _dotIndex = 0;

  // initState runs ONCE when the screen first appears
  @override
  void initState() {
    super.initState(); // Always call super first

    // Set up the animation controller to run for 1.2 seconds
    _controller = AnimationController(
      vsync: this, // Stops animation running when screen is off screen
      duration: const Duration(milliseconds: 1200),
    );

    // Fade starts slow then speeds up (easeIn curve)
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Scale has a bouncy elastic effect at the end (elasticOut curve)
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    // Start both animations immediately when screen opens
    _controller.forward();

    // After 400ms — highlight the second dot
    Future.delayed(const Duration(milliseconds: 400), () {
      // mounted checks screen is still open before updating
      if (mounted) setState(() => _dotIndex = 1);
    });

    // After 800ms — highlight the third dot
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _dotIndex = 2);
    });

    // After 3 seconds — go to AgreementScreen
    // pushReplacement removes splash from memory so user cannot go back
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AgreementScreen()),
        );
      }
    });
  }

  // dispose runs when screen is destroyed — free up animation memory
  @override
  void dispose() {
    _controller.dispose(); // Stop animation and release resources
    super.dispose();
  }

  // build describes what the screen looks like
  // Runs every time setState is called (when dot changes)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // White background for the splash screen
      backgroundColor: Colors.white,

      body: Center(
        // Center widget puts all children in the middle of the screen

        child: FadeTransition(
          // FadeTransition makes the whole column fade in
          opacity: _fadeAnim,

          child: ScaleTransition(
            // ScaleTransition makes the whole column grow in size
            scale: _scaleAnim,

            child: Column(
              // Column stacks widgets vertically one below the other
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // OSH logo loaded from the assets/images folder
                // Container adds a shadow behind the logo
                Container(
                  width: 180,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    // Subtle drop shadow behind the logo
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  // Image.asset loads image from pubspec.yaml assets
                  child: Image.asset(
                    'assets/images/osh_logo.png',
                    fit: BoxFit.contain, // Fits image without cropping
                  ),
                ),

                // Space between logo and app name
                const SizedBox(height: 28),

                // App name in large bold text
                const Text(
                  'OSH Monitor',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A), // Near black
                    letterSpacing: -0.5,
                  ),
                ),

                // Small space between name and tagline
                const SizedBox(height: 6),

                // Tagline in grey text below the app name
                const Text(
                  'Track your vitals, Live Longer!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888), // Medium grey
                  ),
                ),

                // Large space before the loading dots
                const SizedBox(height: 50),

                // Three animated loading dots in a row
                // Only one dot is active (green and wide) at a time
                // The other two are inactive (grey and small)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    // i = 0, 1, 2 for each dot
                    return AnimatedContainer(
                      // Smoothly animates size and colour changes
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      // Active dot is wider (20) inactive dot is small (8)
                      width: i == _dotIndex ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        // Green if active, grey if inactive
                        color: i == _dotIndex
                            ? const Color(0xFF2E7D32) // Active — green
                            : const Color(0xFFE0E0E0), // Inactive — grey
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                // Space between dots and loading text
                const SizedBox(height: 16),

                // Loading message at the very bottom
                const Text(
                  'Loading your health data...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFAAAAAA), // Light grey
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}