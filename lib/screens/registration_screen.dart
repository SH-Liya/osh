
// registration_screen.dart
// New user fills this form to create an account
// Data is saved to Firebase Firestore database
// Shows popup warnings if fields are empty or invalid


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  // Controllers to read text from each input field
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Controls password visibility
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  // Shows loading spinner on button when registering
  bool _isLoading = false;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Free controllers when screen closes
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Shows a popup message at the bottom of the screen
  void _showSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFC62828) // Red for errors
            : const Color(0xFF2E7D32), // Green for success
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Validates form and registers user with Firebase
  Future<void> _register() async {

    // Get text from all fields
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Check if any field is empty — show popup if so
    if (name.isEmpty) {
      _showSnackbar('Please enter your full name');
      return;
    }
    if (email.isEmpty) {
      _showSnackbar('Please enter your email address');
      return;
    }
    if (phone.isEmpty) {
      _showSnackbar('Please enter your phone number');
      return;
    }
    if (password.isEmpty) {
      _showSnackbar('Please enter a password');
      return;
    }
    if (confirmPassword.isEmpty) {
      _showSnackbar('Please confirm your password');
      return;
    }

    // Check if passwords match
    if (password != confirmPassword) {
      _showSnackbar('Passwords do not match');
      return;
    }

    // Check password length
    if (password.length < 6) {
      _showSnackbar('Password must be at least 8 characters');
      return;
    }

    // Show loading spinner
    setState(() => _isLoading = true);

    try {
      // Create user in Firebase Authentication
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save extra user data to Firestore database
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': name,
        'email': email,
        'phone': phone,
        'createdAt': DateTime.now().toIso8601String(),
        'emergencyContacts': [], // Empty list for now
      });

      // Show success message
      _showSnackbar('Account created successfully!', isError: false);

      // Wait 1 second then go back to login screen
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }

    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase errors with clear messages
      if (e.code == 'email-already-in-use') {
        _showSnackbar('This email is already registered. Please log in.');
      } else if (e.code == 'invalid-email') {
        _showSnackbar('Please enter a valid email address');
      } else if (e.code == 'weak-password') {
        _showSnackbar('Password is too weak. Use at least 8 characters');
      } else {
        _showSnackbar('Registration failed. Please try again');
      }
    } finally {
      // Hide loading spinner
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // Back button at top left
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // OSH logo
              Center(
                child: SizedBox(
                  width: 140,
                  height: 70,
                  child: Image.asset(
                    'assets/images/osh_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Heading
              const Text(
                'Create account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Fill in your details to get started',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                ),
              ),

              const SizedBox(height: 28),

              // Full name field
              _buildLabel('Full name'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hint: 'Enter your full name',
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
              ),

              const SizedBox(height: 16),

              // Email field
              _buildLabel('Email address'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                hint: 'Enter your email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              // Phone number field
              _buildLabel('Phone number'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _phoneController,
                hint: 'Enter your phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 16),

              // Password field
              _buildLabel('Password'),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _passwordController,
                hint: 'Create a password',
                isVisible: _passwordVisible,
                onToggle: () {
                  setState(() => _passwordVisible = !_passwordVisible);
                },
              ),

              const SizedBox(height: 16),

              // Confirm password field
              _buildLabel('Confirm password'),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _confirmPasswordController,
                hint: 'Confirm your password',
                isVisible: _confirmPasswordVisible,
                onToggle: () {
                  setState(() =>
                      _confirmPasswordVisible = !_confirmPasswordVisible);
                },
              ),

              const SizedBox(height: 32),

              // Register button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  // Shows spinner when loading, calls _register when not
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    disabledBackgroundColor: const Color(0xFFBDBDBD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      // Show spinner while registering
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create account',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Already have account link
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF888888),
                      ),
                      children: [
                        TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Log in',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

            ],
          ),
        ),
      ),
    );
  }

  // Reusable label widget
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF333333),
      ),
    );
  }

  // Reusable text input field widget
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFAAAAAA),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFFAAAAAA)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF2E7D32),
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
      ),
    );
  }

  // Reusable password field with show/hide toggle
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFAAAAAA),
          fontSize: 14,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: Color(0xFFAAAAAA),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: const Color(0xFFAAAAAA),
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF2E7D32),
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
      ),
    );
  }
}