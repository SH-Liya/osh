
// home_screen.dart — OSH Monitor Home Screen
// Dark theme with blue accents designed for health monitoring
// Real time temperature and pulse data read from Firebase
// Realtime Database connected to ESP32 hardware device
// Health metrics stored and retrieved from Firestore database
// Exercise tracker with automatic timer and completed log
// Emergency alert button to notify contacts instantly


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// StatefulWidget used because multiple values change dynamically
// including live sensor readings, timer and health metrics
class _HomeScreenState extends State<HomeScreen> {

  // Firebase Authentication instance to get current logged in user
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firestore instance for reading and writing user health profile
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Realtime Database reference pointing to the /osh node
  // This is where ESP32 hardware sends live sensor data
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref('osh');

  // User profile details loaded from Firestore on startup
  String _userName = 'User';

  // Health metrics that user can tap to edit
  // Stored persistently in Firestore under users/{uid}
  double? _weight;   // weight in kilograms
  double? _height;   // height in centimetres
  int? _age;         // age in years
  String _gender = ''; // Male, Female or Other

  // BMI calculated automatically when weight and height are set
  double? _bmi;

  // Live vital sign readings received from ESP32 via Firebase
  // Updated in real time whenever hardware sends new data
  double _temperature = 0.0;  // body temperature in Celsius
  int _bpm = 0;               // pulse rate in beats per minute
  String _status = 'Offline'; // Online or Offline device status
  String _alert = '';         // alert message from hardware
  String _lastUpdated = '';   // timestamp of last hardware update

  // Exercise tracker state variables
  bool _isExercising = false; // true when workout is in progress
  Stopwatch _stopwatch = Stopwatch(); // automatic timer for workout
  List<Map<String, dynamic>> _completedExercises = []; // completed workouts list

  // Bottom navigation current selected index
  int _currentIndex = 0;

  // Text controllers for health metric edit dialogs
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  // initState runs once when the screen first appears
  @override
  void initState() {
    super.initState();
    // Load user profile data from Firestore on startup
    _loadUserData();
    // Start listening to live sensor data from Firebase Realtime Database
    _listenToSensorData();
  }

  // dispose runs when screen is destroyed — free up resources
  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    // Stop the exercise timer if still running
    _stopwatch.stop();
    super.dispose();
  }

  // Listens to real time sensor data from Firebase Realtime Database
  // onValue fires every time data changes in the /osh node
  // This means the screen updates automatically when ESP32 sends new readings
  void _listenToSensorData() {
    _database.onValue.listen((event) {
      if (event.snapshot.exists && mounted) {
        // Convert Firebase snapshot to a Dart Map
        final data = Map<String, dynamic>.from(
            event.snapshot.value as Map);
        setState(() {
          // Update all sensor values from the Firebase data
          _temperature = (data['temperature'] ?? 0.0).toDouble();
          _bpm = (data['bpm'] ?? 0).toInt();
          _status = data['status'] ?? 'Offline';
          _alert = data['alert'] ?? '';
          _lastUpdated = data['lastUpdated'] ?? '';
        });
      }
    });
  }

  // Loads user name and health metrics from Firestore
  // Called once when the screen opens
  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Fetch the user document from Firestore users collection
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _userName = data['name'] ?? 'User';
          _weight = data['weight']?.toDouble();
          _height = data['height']?.toDouble();
          _age = data['age'];
          _gender = data['gender'] ?? '';
        });
        // Recalculate BMI after loading weight and height
        _calculateBMI();
      }
    }
  }

  // Saves a single health metric field to Firestore
  // Called after user edits weight, height, age or gender
  Future<void> _saveToFirestore(String field, dynamic value) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({field: value});
    }
  }

  // Calculates BMI using the standard formula
  // BMI = weight (kg) / height (m) squared
  void _calculateBMI() {
    if (_weight != null && _height != null && _height! > 0) {
      // Convert height from centimetres to metres
      final heightM = _height! / 100;
      setState(() {
        _bmi = _weight! / (heightM * heightM);
      });
    }
  }

  // Returns BMI category based on WHO standard ranges
  String _getBMICategory() {
    if (_bmi == null) return '';
    if (_bmi! < 18.5) return 'Underweight';
    if (_bmi! < 25.0) return 'Normal';
    if (_bmi! < 30.0) return 'Overweight';
    return 'Obese';
  }

  // Returns colour matching the BMI category
  Color _getBMIColour() {
    if (_bmi == null) return Colors.grey;
    if (_bmi! < 18.5) return Colors.blue;
    if (_bmi! < 25.0) return const Color(0xFF00C853); // green
    if (_bmi! < 30.0) return Colors.orange;
    return Colors.red;
  }

  // Returns greeting text based on current time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // Returns formatted date string showing day name, date and year
  String _getDate() {
    final now = DateTime.now();
    final days = ['Monday', 'Tuesday', 'Wednesday',
        'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April',
        'May', 'June', 'July', 'August', 'September',
        'October', 'November', 'December'];
    return '${days[now.weekday - 1]}, ${now.day} '
        '${months[now.month - 1]} ${now.year}';
  }

  // Returns temperature status label based on clinical thresholds
  // Hypothermia below 35°C, normal range 36.1 to 37.2°C, fever above 38°C
  String _getTempStatus() {
    if (_temperature == 0) return 'No data';
    if (_temperature < 35.0) return 'Very Low!';
    if (_temperature < 36.1) return 'Low';
    if (_temperature <= 37.2) return 'Normal';
    if (_temperature <= 38.0) return 'Slightly High';
    return 'Fever!';
  }

  // Returns colour matching the temperature status
  Color _getTempColour() {
    if (_temperature == 0) return Colors.grey;
    if (_temperature < 35.0) return Colors.blue;
    if (_temperature < 36.1) return Colors.lightBlue;
    if (_temperature <= 37.2) return const Color(0xFF00C853);
    if (_temperature <= 38.0) return Colors.orange;
    return Colors.red;
  }

  // Returns pulse rate status based on normal adult range 60 to 100 BPM
  String _getPulseStatus() {
    if (_bpm == 0) return 'No data';
    if (_bpm < 60) return 'Low';
    if (_bpm <= 100) return 'Normal';
    return 'High';
  }

  // Starts the exercise timer when user taps Start Running
  // Stopwatch runs automatically in the background
  void _startExercise() {
    setState(() {
      _isExercising = true;
      _stopwatch.reset();
      _stopwatch.start();
    });
    // Rebuild screen every second to update the timer display
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _isExercising) {
        setState(() {});
        return true;
      }
      return false;
    });
  }

  // Stops the exercise timer and saves session to completed list
  // Completed sessions show with strikethrough in the log
  void _stopExercise() {
    _stopwatch.stop();
    final duration = _stopwatch.elapsed;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    setState(() {
      _isExercising = false;
      // Add completed session to the list with duration and time
      _completedExercises.add({
        'type': 'Running',
        'duration': '${minutes}m ${seconds}s',
        'time': TimeOfDay.now().format(context),
        'done': true,
      });
    });
  }

  // Formats the stopwatch elapsed time as MM:SS
  String _formatTimer() {
    final duration = _stopwatch.elapsed;
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds =
        (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Shows a dialog for the user to edit a health metric
  // Saves the new value to Firestore and updates the screen
  void _editMetric(
      String title,
      String hint,
      String suffix,
      TextEditingController controller,
      Function(double) onSave) {
    controller.text = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Text(
          'Enter your $title',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            suffixText: suffix,
            suffixStyle: const TextStyle(color: Colors.grey),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF2979FF)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide:
                  BorderSide(color: Color(0xFF2979FF), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                onSave(value);
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2979FF),
            ),
            child: const Text('Save',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Shows a dialog for the user to select their gender
  // Updates Firestore immediately when selection is made
  void _editGender() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Select gender',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Male', 'Female', 'Other'].map((g) {
            return ListTile(
              title: Text(g,
                  style: const TextStyle(color: Colors.white)),
              leading: Radio<String>(
                value: g,
                groupValue: _gender,
                activeColor: const Color(0xFF2979FF),
                onChanged: (value) async {
                  setState(() => _gender = value!);
                  await _saveToFirestore('gender', value);
                  if (mounted) Navigator.pop(context);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dark background colour matching the health app theme
      backgroundColor: const Color(0xFF0A0A1A),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── HEADER SECTION ───────────────────────────────
              // Shows greeting, current date and profile icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting uses first name only from profile
                      Text(
                        '${_getGreeting()}, '
                        '${_userName.split(' ').first}!',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Current date shown below greeting
                      Text(
                        _getDate(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  // Profile icon button — navigates to profile screen later
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2979FF)
                          .withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF2979FF),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(Icons.person,
                        color: Color(0xFF2979FF), size: 24),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── ALERT BANNER ─────────────────────────────────
              // Only shown when ESP32 sends an alert message
              // Red banner appears automatically for fever or hypothermia
              if (_alert.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _alert,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── VITAL SIGNS SECTION ──────────────────────────
              // Temperature and pulse displayed as two side by side cards
              // Data comes live from ESP32 via Firebase Realtime Database
              const Text(
                'Vital Signs',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [

                  // Temperature card — colour changes based on reading
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getTempColour()
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thermometer icon with colour matching status
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getTempColour()
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.thermostat,
                                color: _getTempColour(), size: 22),
                          ),
                          const SizedBox(height: 12),
                          // Temperature value — shows -- when no data
                          Text(
                            _temperature == 0
                                ? '--°C'
                                : '${_temperature.toStringAsFixed(1)}°C',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: _getTempColour(),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('Temperature',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 6),
                          // Status badge — Normal, Low, Fever etc
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getTempColour()
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getTempStatus(),
                              style: TextStyle(
                                fontSize: 11,
                                color: _getTempColour(),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Pulse rate card — always red colour
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Heart icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.favorite,
                                color: Colors.red, size: 22),
                          ),
                          const SizedBox(height: 12),
                          // BPM value — shows -- when no data
                          Text(
                            _bpm == 0 ? '--' : '$_bpm BPM',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('Pulse Rate',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 6),
                          // Status badge — Low, Normal or High
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getPulseStatus(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Device status bar showing Online/Offline and last update time
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Green dot for online, red for offline
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _status == 'Online'
                                ? const Color(0xFF00C853)
                                : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Device $_status',
                          style: TextStyle(
                            color: _status == 'Online'
                                ? const Color(0xFF00C853)
                                : Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Timestamp of last sensor reading from hardware
                    Text(
                      _lastUpdated.isEmpty
                          ? 'No data'
                          : 'Updated: $_lastUpdated',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── HEALTH METRICS SECTION ───────────────────────
              // User taps each card to edit their personal health data
              // All values saved to Firestore and persist between sessions
              const Text(
                'Health Metrics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              // Weight and Height cards side by side
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.monitor_weight_outlined,
                      label: 'Weight',
                      value: _weight != null
                          ? '${_weight!.toStringAsFixed(1)} kg'
                          : 'Tap to add',
                      colour: const Color(0xFF2979FF),
                      onTap: () => _editMetric(
                        'weight', 'e.g. 65', 'kg',
                        _weightController, (v) async {
                          setState(() => _weight = v);
                          await _saveToFirestore('weight', v);
                          // Recalculate BMI after weight changes
                          _calculateBMI();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.height,
                      label: 'Height',
                      value: _height != null
                          ? '${_height!.toStringAsFixed(0)} cm'
                          : 'Tap to add',
                      colour: const Color(0xFF7C4DFF),
                      onTap: () => _editMetric(
                        'height', 'e.g. 165', 'cm',
                        _heightController, (v) async {
                          setState(() => _height = v);
                          await _saveToFirestore('height', v);
                          // Recalculate BMI after height changes
                          _calculateBMI();
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Age and Gender cards side by side
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.cake_outlined,
                      label: 'Age',
                      value: _age != null
                          ? '$_age years'
                          : 'Tap to add',
                      colour: const Color(0xFF00BCD4),
                      onTap: () => _editMetric(
                        'age', 'e.g. 22', 'years',
                        _ageController, (v) async {
                          setState(() => _age = v.toInt());
                          await _saveToFirestore('age', v.toInt());
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.person_outline,
                      label: 'Gender',
                      value: _gender.isNotEmpty
                          ? _gender
                          : 'Tap to add',
                      colour: const Color(0xFFE040FB),
                      onTap: _editGender,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // BMI card — only shown after weight and height are entered
              // BMI calculated automatically using standard formula
              if (_bmi != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getBMIColour().withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      // BMI icon with colour matching category
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getBMIColour().withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.calculate_outlined,
                            color: _getBMIColour(), size: 26),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // BMI value rounded to 1 decimal place
                          Text(
                            'BMI: ${_bmi!.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          // Category label with matching colour
                          Text(
                            _getBMICategory(),
                            style: TextStyle(
                              fontSize: 13,
                              color: _getBMIColour(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // ── EXERCISE TRACKER SECTION ─────────────────────
              // User taps Start Running to begin automatic timer
              // Tapping Stop saves the session with duration to the log
              // Completed sessions shown with green tick and strikethrough
              const Text(
                'Exercise Tracker',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2979FF).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [

                    // Exercise type header row
                    Row(
                      children: [
                        // Running icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2979FF)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.directions_run,
                              color: Color(0xFF2979FF), size: 26),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Running',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Tap start to begin tracking',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Timer display — only visible when exercise is active
                    if (_isExercising)
                      Column(
                        children: [
                          // Large timer showing MM:SS format
                          Text(
                            _formatTimer(),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2979FF),
                              fontFeatures: [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          const Text(
                            'Running in progress...',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    // Start or Stop button — changes based on exercise state
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isExercising
                            ? _stopExercise
                            : _startExercise,
                        icon: Icon(
                          _isExercising
                              ? Icons.stop_circle_outlined
                              : Icons.play_circle_outlined,
                          color: Colors.white,
                        ),
                        label: Text(
                          _isExercising
                              ? 'Stop & Save'
                              : 'Start Running',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          // Red when stopping, blue when starting
                          backgroundColor: _isExercising
                              ? Colors.red
                              : const Color(0xFF2979FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),

                    // Completed exercises log
                    // Each entry shows strikethrough text indicating done
                    if (_completedExercises.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Completed today',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._completedExercises.map((exercise) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              // Green tick icon for completed session
                              const Icon(Icons.check_circle,
                                  color: Color(0xFF00C853), size: 18),
                              const SizedBox(width: 8),
                              // Strikethrough shows session is complete
                              Text(
                                'Running — ${exercise['duration']}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                  decoration:
                                      TextDecoration.lineThrough,
                                  decorationColor: Colors.grey,
                                ),
                              ),
                              const Spacer(),
                              // Time the session was completed
                              Text(
                                exercise['time'],
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── EMERGENCY ALERT BUTTON ────────────────────────
              // Sends alert to emergency contacts when tapped
              // Full SMS and call functionality added in contacts screen
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Show confirmation snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Emergency alert sent to contacts!'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 24),
                  label: const Text(
                    'Send Emergency Alert',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // ── BOTTOM NAVIGATION BAR ─────────────────────────────────
      // Five tabs — Home, Monitor, Contacts, Profile and Chat
      // Each tab will navigate to its respective screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E2E),
        selectedItemColor: const Color(0xFF2979FF),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart_outlined),
            activeIcon: Icon(Icons.monitor_heart),
            label: 'Monitor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts_outlined),
            activeIcon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
        ],
      ),
    );
  }

  // Reusable metric card widget used for weight, height, age and gender
  // Tapping any card opens an edit dialog to update the value
  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color colour,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colour.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coloured icon matching the metric type
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colour.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: colour, size: 18),
            ),
            const SizedBox(height: 10),
            // Value text — grey when empty, white when filled
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: value == 'Tap to add'
                    ? Colors.grey
                    : Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            // Label below value
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}