
// agreement_screen.dart
// Shown once after the splash screen
// Explains what data the app collects and why
// User must tick the checkbox before the button activates
// Tapping the button navigates to the LoginScreen


import 'package:flutter/material.dart';

// Import next screen to navigate to after agreement
import 'login_screen.dart';

// StatefulWidget because _agreed changes when checkbox is tapped
class AgreementScreen extends StatefulWidget {
  const AgreementScreen({super.key});

  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen> {

  // Tracks checkbox state
  // false = not ticked, button is grey and disabled
  // true = ticked, button turns green and becomes tappable
  bool _agreed = false;

  // List of 4 agreement cards shown on the screen
  // Each card has an icon, colours, title and description
  final List<Map<String, dynamic>> _items = [
    {
      'icon': Icons.lock_outline,
      'color': Color(0xFF2E7D32),  // Green icon
      'bg': Color(0xFFE8F5E9),     // Light green background
      'title': 'Data privacy',
      'desc': 'Your health records are stored securely and never shared with third parties without your consent.',
    },
    {
      'icon': Icons.monitor_heart_outlined,
      'color': Color(0xFF1565C0),  // Blue icon
      'bg': Color(0xFFE3F2FD),     // Light blue background
      'title': 'Health data tracking',
      'desc': 'We record your temperature and pulse readings to monitor your health over time.',
    },
    {
      'icon': Icons.notifications_outlined,
      'color': Color(0xFFE65100),  // Orange icon
      'bg': Color(0xFFFFF3E0),     // Light orange background
      'title': 'Emergency alerts',
      'desc': 'If abnormal readings are detected, your emergency contacts will be notified.',
    },
    {
      'icon': Icons.phone_android_outlined,
      'color': Color(0xFF6A1B9A),  // Purple icon
      'bg': Color(0xFFF3E5F5),     // Light purple background
      'title': 'Device & storage access',
      'desc': 'We need camera, contacts and storage access for photo upload and emergency features.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // SafeArea keeps content below notch and status bar
      body: SafeArea(
        child: Column(
          children: [

            // ── TOP HEADER ──────────────────────────────────────
            // Contains logo, title and subtitle
            // Has a bottom border line to separate from the list
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF0F0F0)),
                ),
              ),
              child: Column(
                children: [
                  // OSH logo at the top of the screen
                  SizedBox(
                    width: 120,
                    height: 60,
                    child: Image.asset(
                      'assets/images/osh_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Main heading
                  const Text(
                    'Before you continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtitle
                  const Text(
                    'Please read and agree to our terms',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),

            // ── SCROLLABLE LIST ─────────────────────────────────
            // Expanded fills all remaining space between header and bottom
            // ListView makes it scrollable if content is too long
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length, // 4 items total
                // 8px gap between each card
                separatorBuilder: (_,_) => const SizedBox(height: 8),
                // Build each card from the _items list
                itemBuilder: (context, i) {
                  final item = _items[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFECECEC)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Coloured icon box on the left side
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: item['bg'] as Color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: item['color'] as Color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title and description on the right side
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Bold title
                              Text(
                                item['title'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Grey description below the title
                              Text(
                                item['desc'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF888888),
                                  height: 1.4, // Line spacing
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── BOTTOM SECTION ──────────────────────────────────
            // Contains the checkbox and the agree button
            // Sits at the very bottom of the screen
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFF0F0F0)),
                ),
              ),
              child: Column(
                children: [

                  // Tapping anywhere on this row toggles the checkbox
                  GestureDetector(
                    onTap: () => setState(() => _agreed = !_agreed),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Animated checkbox box
                        // Smoothly transitions from white to green when tapped
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            // Green when agreed, white when not agreed
                            color: _agreed
                                ? const Color(0xFF2E7D32)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              // Border also changes colour with the box
                              color: _agreed
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFAAAAAA),
                              width: 1.5,
                            ),
                          ),
                          // Tick icon only appears when agreed is true
                          child: _agreed
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        // RichText allows different styles in one text block
                        // Privacy Policy and Terms of Service are red and underlined
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF555555),
                              ),
                              children: [
                                TextSpan(
                                  text: 'I have read and agree to the OSH ',
                                ),
                                // Red underlined link text
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: Color(0xFFC62828),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(text: ' and '),
                                // Red underlined link text
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: Color(0xFFC62828),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Agree and continue button
                  // onPressed is null (disabled) when _agreed is false
                  // onPressed navigates to LoginScreen when _agreed is true
                  SizedBox(
                    width: double.infinity, // Full width button
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _agreed
                          ? () => Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              )
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32), // Green
                        // Grey when disabled
                        disabledBackgroundColor: const Color(0xFFBDBDBD),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0, // No shadow on button
                      ),
                      child: const Text(
                        'I Agree & Continue',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}