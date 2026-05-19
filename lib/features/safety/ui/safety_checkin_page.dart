import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/kashta_colors.dart';
import '../../../core/utils/localization.dart';
import '../../../core/widgets/language_app_bar.dart';
import '../../../widgets/kashta_background.dart';
import '../services/safety_location_service.dart';

class SafetyCheckinPage extends StatefulWidget {
  const SafetyCheckinPage({
    super.key,
    required this.tr,
    required this.isArabic,
    required this.onToggleLanguage,
  });

  final Tr tr;
  final bool isArabic;
  final VoidCallback onToggleLanguage;

  @override
  State<SafetyCheckinPage> createState() => _SafetyCheckinPageState();
}

class _SafetyCheckinPageState extends State<SafetyCheckinPage> {
  final SafetyLocationService _locationService = SafetyLocationService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _destinationController = TextEditingController();
  final _expectedReturnTimeController = TextEditingController();
  final _currentLocationLinkController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _gettingLocation = false;
  DateTime _lastUpdateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers) {
      controller.addListener(_refreshPreview);
    }
    _loadSafetyInfo();
  }

  List<TextEditingController> get _controllers => [
        _nameController,
        _phoneController,
        _vehicleTypeController,
        _vehicleColorController,
        _plateNumberController,
        _destinationController,
        _expectedReturnTimeController,
        _currentLocationLinkController,
      ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller
        ..removeListener(_refreshPreview)
        ..dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWithLanguage(
        tr: widget.tr,
        isArabic: widget.isArabic,
        title: widget.tr.t('safety_checkin_title'),
        onToggleLanguage: widget.onToggleLanguage,
      ),
      body: KashtaBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SectionCard(
                    icon: Icons.account_circle_outlined,
                    title: widget.tr.t('safety_my_info'),
                    children: [
                      _SafetyTextField(
                        controller: _nameController,
                        label: widget.tr.t('safety_name'),
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                      ),
                      _SafetyTextField(
                        controller: _phoneController,
                        label: widget.tr.t('safety_phone'),
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      _SafetyTextField(
                        controller: _vehicleTypeController,
                        label: widget.tr.t('safety_vehicle_type'),
                        icon: Icons.directions_car_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      _SafetyTextField(
                        controller: _vehicleColorController,
                        label: widget.tr.t('safety_vehicle_color'),
                        icon: Icons.palette_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      _SafetyTextField(
                        controller: _plateNumberController,
                        label: widget.tr.t('safety_plate_number'),
                        icon: Icons.pin_outlined,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.tr.t('safety_saved_info_note'),
                        style: TextStyle(
                          color: KashtaColors.textDark.withValues(alpha: 0.72),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _saveSafetyInfo,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(widget.tr.t('safety_save_info')),
                          style: FilledButton.styleFrom(
                            backgroundColor: KashtaColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    icon: Icons.route_outlined,
                    title: widget.tr.t('safety_trip_details'),
                    children: [
                      _SafetyTextField(
                        controller: _destinationController,
                        label: widget.tr.t('safety_destination'),
                        icon: Icons.place_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      _SafetyTextField(
                        controller: _expectedReturnTimeController,
                        label: widget.tr.t('safety_expected_return_time'),
                        icon: Icons.schedule_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      _SafetyTextField(
                        controller: _currentLocationLinkController,
                        label: widget.tr.t('safety_current_location_link'),
                        icon: Icons.location_on_outlined,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.update,
                            size: 18,
                            color: KashtaColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${widget.tr.t('safety_last_update')}: ${_formatDateTime(_lastUpdateTime)}',
                              style: TextStyle(
                                color: KashtaColors.textDark
                                    .withValues(alpha: 0.72),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed:
                            _gettingLocation ? null : _getCurrentLocation,
                        icon: _gettingLocation
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location_outlined),
                        label: Text(widget.tr.t('safety_get_current_location')),
                      ),
                      const SizedBox(height: 14),
                      _MessagePreview(
                        title: widget.tr.t('safety_message_preview'),
                        message: _buildMessage(),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.tr.t('safety_whatsapp_manual_note'),
                        style: TextStyle(
                          color: KashtaColors.textDark.withValues(alpha: 0.72),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: _shareViaWhatsApp,
                        icon: const Icon(Icons.chat_outlined),
                        label: Text(widget.tr.t('safety_share_whatsapp')),
                        style: FilledButton.styleFrom(
                          backgroundColor: KashtaColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _copyMessage,
                        icon: const Icon(Icons.copy_outlined),
                        label: Text(widget.tr.t('safety_copy_message')),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _loadSafetyInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data() ?? const <String, dynamic>{};
      final safetyInfo = data['safetyInfo'];

      if (safetyInfo is Map<String, dynamic>) {
        _nameController.text = _stringValue(safetyInfo['name']);
        _phoneController.text = _stringValue(safetyInfo['phone']);
        _vehicleTypeController.text = _stringValue(safetyInfo['vehicleType']);
        _vehicleColorController.text =
            _stringValue(safetyInfo['vehicleColor']);
        _plateNumberController.text = _stringValue(safetyInfo['plateNumber']);
      } else {
        _nameController.text = _firstNonEmpty([
          data['displayName'],
          data['fullName'],
          user.displayName,
        ]);
        _phoneController.text = _firstNonEmpty([
          data['phoneNumber'],
          user.phoneNumber,
        ]);
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar(widget.tr.t('firestore_generic_error'));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveSafetyInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar(widget.tr.t('please_sign_in_first'));
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'safetyInfo': {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'vehicleType': _vehicleTypeController.text.trim(),
          'vehicleColor': _vehicleColorController.text.trim(),
          'plateNumber': _plateNumberController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      if (mounted) {
        _showSnackBar(widget.tr.t('safety_info_saved'));
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar(widget.tr.t('safety_info_save_failed'));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);
    try {
      final link = await _locationService.currentLocationLink();
      if (!mounted) {
        return;
      }
      setState(() {
        _currentLocationLinkController.text = link;
        _lastUpdateTime = DateTime.now();
      });
      _showSnackBar(widget.tr.t('safety_location_added'));
    } on SafetyLocationException catch (_) {
      if (mounted) {
        _showSnackBar(widget.tr.t('safety_location_failed'));
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar(widget.tr.t('safety_location_failed'));
      }
    } finally {
      if (mounted) {
        setState(() => _gettingLocation = false);
      }
    }
  }

  Future<void> _shareViaWhatsApp() async {
    if (!_hasCriticalTripDetails()) {
      return;
    }

    setState(() => _lastUpdateTime = DateTime.now());
    final message = _buildMessage();
    final uri = Uri.https('wa.me', '/', {'text': message});

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) {
        return;
      }
      if (!launched) {
        _showSnackBar(widget.tr.t('safety_whatsapp_open_failed'));
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar(widget.tr.t('safety_whatsapp_open_failed'));
      }
    }
  }

  Future<void> _copyMessage() async {
    if (!_hasCriticalTripDetails()) {
      return;
    }

    setState(() => _lastUpdateTime = DateTime.now());
    await Clipboard.setData(ClipboardData(text: _buildMessage()));
    if (mounted) {
      _showSnackBar(widget.tr.t('safety_message_copied'));
    }
  }

  bool _hasCriticalTripDetails() {
    if (_destinationController.text.trim().isEmpty ||
        _expectedReturnTimeController.text.trim().isEmpty) {
      _showSnackBar(widget.tr.t('safety_required_trip_fields'));
      return false;
    }
    return true;
  }

  String _buildMessage() {
    final lines = <String>[
      widget.tr.t('safety_message_title'),
      '',
      widget.tr.t('safety_message_intro'),
      '',
    ];
    _addLabel(lines, widget.tr.t('safety_name'), _nameController.text);
    _addLabel(lines, widget.tr.t('safety_phone'), _phoneController.text);
    _addLabel(
      lines,
      widget.tr.t('safety_destination'),
      _destinationController.text,
    );
    _addLabel(
      lines,
      widget.tr.t('safety_message_expected_return'),
      _expectedReturnTimeController.text,
    );

    final vehicleText = [
      _vehicleColorController.text.trim(),
      _vehicleTypeController.text.trim(),
    ].where((value) => value.isNotEmpty).join(' ');
    final hasVehicleInfo =
        vehicleText.isNotEmpty || _plateNumberController.text.trim().isNotEmpty;
    if (hasVehicleInfo) {
      _addLine(lines, '', force: true);
      _addLabel(lines, widget.tr.t('safety_message_vehicle'), vehicleText);
      _addLabel(
        lines,
        widget.tr.t('safety_message_plate_number'),
        _plateNumberController.text,
      );
    }

    if (_currentLocationLinkController.text.trim().isNotEmpty) {
      _addLine(lines, '', force: true);
      _addLine(
        lines,
        '${widget.tr.t('safety_message_current_location')}:',
        force: true,
      );
      _addLine(lines, _currentLocationLinkController.text);
    }

    _addLine(lines, '', force: true);
    _addLine(
      lines,
      '${widget.tr.t('safety_message_last_update')}:',
      force: true,
    );
    _addLine(lines, _formatDateTime(_lastUpdateTime), force: true);
    _addLine(lines, '', force: true);
    _addLine(
      lines,
      widget.tr.t('safety_message_footer'),
      force: true,
    );

    return lines.join('\n').trim();
  }

  void _addLabel(List<String> lines, String label, String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      lines.add('$label: $trimmed');
    }
  }

  void _addLine(List<String> lines, String value, {bool force = false}) {
    final trimmed = value.trim();
    if (force || trimmed.isNotEmpty) {
      lines.add(trimmed);
    }
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _stringValue(Object? value) => (value ?? '').toString().trim();

  String _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = _stringValue(value);
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  String _formatDateTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour < 12 ? widget.tr.t('am') : widget.tr.t('pm');
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')} $hour:$minute $period';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: KashtaColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SafetyTextField extends StatelessWidget {
  const _SafetyTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: KashtaColors.primary),
          filled: true,
          fillColor: KashtaColors.cardSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: KashtaColors.sandBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: KashtaColors.primary, width: 1.6),
          ),
        ),
      ),
    );
  }
}

class _MessagePreview extends StatelessWidget {
  const _MessagePreview({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KashtaColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KashtaColors.sandBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.message_outlined,
                color: KashtaColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            message,
            style: const TextStyle(height: 1.35),
          ),
        ],
      ),
    );
  }
}
