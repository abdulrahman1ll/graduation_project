import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../chat/services/group_service.dart';
import '../services/trip_service.dart';
import '../utils/firestore_utils.dart';
import '../utils/localization.dart';

class AddTripPage extends StatefulWidget {
  const AddTripPage({
    super.key,
    required this.tr,
    required this.isArabic,
    this.linkedGroupId,
  });

  final Tr tr;
  final bool isArabic;
  final String? linkedGroupId;

  @override
  State<AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends State<AddTripPage> {
  final TripService _tripService = TripService();
  final GroupService _groupService = GroupService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _peopleController = TextEditingController();
  final _locationUrlController = TextEditingController();
  String _visibility = 'public';
  DateTime? _tripDate;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _peopleController.dispose();
    _locationUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.tr;
    return Scaffold(
      appBar: AppBar(title: Text(tr.t('add_trip'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: tr.t('trip_name')),
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: tr.t('description')),
            ),
            TextFormField(
              controller: _peopleController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: tr.t('people_count')),
            ),
            TextFormField(
              controller: _locationUrlController,
              decoration: InputDecoration(labelText: tr.t('location_url')),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _visibility,
              items: const [
                DropdownMenuItem(value: 'public', child: Text('Public')),
                DropdownMenuItem(value: 'private', child: Text('Private')),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _visibility = value);
                      }
                    },
              decoration: const InputDecoration(labelText: 'Visibility'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saving ? null : _pickDate,
              child: Text(
                _tripDate == null ? tr.t('choose_trip_date') : _formatDate(_tripDate!),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(tr.t('save_trip')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _tripDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (selected != null) {
      setState(() => _tripDate = selected);
    }
  }

  Future<void> _save() async {
    final tr = widget.tr;
    final count = int.tryParse(_peopleController.text.trim());
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        count == null ||
        count <= 0 ||
        _locationUrlController.text.trim().isEmpty ||
        _tripDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr.t('fill_all_fields'))));
      return;
    }

    setState(() => _saving = true);
    try {
      final tripId = await _tripService.createTrip(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        peopleCount: count,
        locationUrl: _locationUrlController.text.trim(),
        tripDate: _tripDate!,
        visibility: _visibility,
        groupId: widget.linkedGroupId,
      );

      final linkedGroupId = widget.linkedGroupId?.trim() ?? '';
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (linkedGroupId.isNotEmpty && userId.isNotEmpty) {
        await _groupService.linkChecklistToGroup(
          groupId: linkedGroupId,
          tripId: tripId,
          userId: userId,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        showFirestoreError(context, e);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr.t('save_failed'))));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _formatDate(DateTime value) {
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '${value.year}/$m/$d';
  }
}
