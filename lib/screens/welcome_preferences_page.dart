import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WelcomePreferencesPage extends StatefulWidget {
  const WelcomePreferencesPage({super.key});

  @override
  State<WelcomePreferencesPage> createState() => _WelcomePreferencesPageState();
}

class _WelcomePreferencesPageState extends State<WelcomePreferencesPage> {
  String? _placeType;
  String? _distance;
  String? _temperature;
  bool _loading = false;

  Future<void> _savePreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_placeType == null || _distance == null || _temperature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions')),
      );
      return;
    }

    setState(() => _loading = true);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'preferences': {
        'placeType': _placeType,
        'distancePreference': _distance,
        'temperaturePreference': _temperature,
      },
      'preferencesCompleted' :true,
    }, SetOptions(merge: true));

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  Widget _buildOption(
      String title, String value, String? groupValue, Function(String) onTap) {
    final selected = value == groupValue;

    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.orange.shade100 : Colors.white,
          border: Border.all(
            color: selected ? Colors.orange : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3ED),
     body: SafeArea(
  child: SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
              const SizedBox(height: 20),

              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.landscape_rounded,
                  size: 60,
                  color: Colors.orange,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Welcome to Kashta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Let us personalize your experience by asking you a few quick questions.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),

              const SizedBox(height: 30),

              /// place type
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Preferred place type"),
              ),
              const SizedBox(height: 10),
              _buildOption("Desert", "desert", _placeType,
                  (v) => setState(() => _placeType = v)),
              _buildOption("Beach", "beach", _placeType,
                  (v) => setState(() => _placeType = v)),
              _buildOption("Nature", "nature", _placeType,
                  (v) => setState(() => _placeType = v)),

              const SizedBox(height: 20),

              /// distance
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Distance preference"),
              ),
              const SizedBox(height: 10),
              _buildOption("Near", "near", _distance,
                  (v) => setState(() => _distance = v)),
              _buildOption("Flexible", "flexible", _distance,
                  (v) => setState(() => _distance = v)),

              const SizedBox(height: 20),

              /// temperature
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Preferred weather"),
              ),
              const SizedBox(height: 10),
              _buildOption("Cool", "cool", _temperature,
                  (v) => setState(() => _temperature = v)),
              _buildOption("Moderate", "moderate", _temperature,
                  (v) => setState(() => _temperature = v)),
              _buildOption("Warm", "warm", _temperature,
                  (v) => setState(() => _temperature = v)),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _savePreferences,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Continue"),
                ),
              ),
            ],
          ),
        ),
      ),
     )
    );
  }
}