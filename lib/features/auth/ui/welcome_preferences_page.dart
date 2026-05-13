import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/localization.dart';

class WelcomePreferencesPage extends StatefulWidget {
  const WelcomePreferencesPage({super.key, required this.tr});

  final Tr tr;

  @override
  State<WelcomePreferencesPage> createState() => _WelcomePreferencesPageState();
}

class _WelcomePreferencesPageState extends State<WelcomePreferencesPage> {
  String? _placeType;
  String? _distance;
  String? _temperature;
  String? _activity;
  bool _loading = false;

  Future<void> _savePreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_placeType == null ||
        _distance == null ||
        _temperature == null ||
        _activity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.tr.t('please_answer_all_questions'))),
      );
      return;
    }

    setState(() => _loading = true);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'preferences': {
        'placeType': _placeType,
        'distancePreference': _distance,
        'temperaturePreference': _temperature,
        'activityPreference': _activity,
      },
      'preferencesCompleted': true,
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
    final tr = widget.tr;

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

                  Text(
                    tr.t('welcome_title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    tr.t('choose_preferences'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),

                  const SizedBox(height: 30),

                  /// place type
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(tr.t('preferred_place_type')),
                  ),
                  const SizedBox(height: 10),
                  _buildOption(tr.t('desert'), "desert", _placeType,
                      (v) => setState(() => _placeType = v)),
                  _buildOption(tr.t('beach'), "beach", _placeType,
                      (v) => setState(() => _placeType = v)),
                  _buildOption(tr.t('nature'), "nature", _placeType,
                      (v) => setState(() => _placeType = v)),

                  const SizedBox(height: 20),

                  /// distance
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(tr.t('distance_preference')),
                  ),
                  const SizedBox(height: 10),
                  _buildOption(tr.t('near'), "near", _distance,
                      (v) => setState(() => _distance = v)),
                  _buildOption(tr.t('flexible'), "flexible", _distance,
                      (v) => setState(() => _distance = v)),

                  const SizedBox(height: 20),

                  /// temperature
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(tr.t('preferred_weather')),
                  ),
                  const SizedBox(height: 10),
                  _buildOption(tr.t('cool'), "cool", _temperature,
                      (v) => setState(() => _temperature = v)),
                  _buildOption(tr.t('moderate'), "moderate", _temperature,
                      (v) => setState(() => _temperature = v)),
                  _buildOption(tr.t('warm'), "warm", _temperature,
                      (v) => setState(() => _temperature = v)),

                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(tr.t('preferred_activity')),
                  ),
                  const SizedBox(height: 10),
                  _buildOption(tr.t('camping'), "camping", _activity,
                      (v) => setState(() => _activity = v)),
                  _buildOption(tr.t('barbecue'), "barbecue", _activity,
                      (v) => setState(() => _activity = v)),
                  _buildOption(tr.t('hiking'), "hiking", _activity,
                      (v) => setState(() => _activity = v)),
                  _buildOption(tr.t('relaxing'), "relaxing", _activity,
                      (v) => setState(() => _activity = v)),

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
                          : Text(tr.t('continue_button')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
