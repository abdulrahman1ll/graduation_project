import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/app_language.dart';
import '../../../core/utils/localization.dart';
import '../services/group_service.dart';
import 'group_chat_page.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({
    super.key,
    this.tr,
    this.initialTripId,
    this.groupService,
  });

  final Tr? tr;
  final String? initialTripId;
  final GroupService? groupService;

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  late final GroupService _groupService;

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _saving = false;
  String? _selectedTripId;

  @override
  void initState() {
    super.initState();
    _groupService = widget.groupService ?? GroupService();
    _selectedTripId = widget.initialTripId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (image == null) {
      return;
    }
    final bytes = await image.readAsBytes();
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedImage = image;
      _selectedImageBytes = bytes;
    });
  }

  Future<void> _save() async {
    final tr = _tr(context);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return;
    }
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.t('nameAndDescriptionRequired'))),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final groupId = await _groupService.createGroup(
        _selectedTripId,
        _nameController.text.trim(),
        _descriptionController.text.trim(),
        userId,
        null,
      );
      if (_selectedImage != null) {
        await _groupService.uploadGroupImage(
          groupId: groupId,
          userId: userId,
          imageFile: _selectedImage!,
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GroupChatPage(groupId: groupId, tr: tr),
        ),
      );
    } on FirebaseException catch (error) {
      debugPrint(
        'CreateGroupPage.createGroup failed: '
        '${error.code} ${error.message}',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? tr.t('unableToCreateGroup'))),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.t('unableToCreateGroup'))),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Tr _tr(BuildContext context) {
    if (widget.tr != null) {
      return widget.tr!;
    }
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Tr(isArabic ? AppLanguage.ar : AppLanguage.en);
  }

  @override
  Widget build(BuildContext context) {
    final tr = _tr(context);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: Text(tr.t('createGroupTitle'))),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: userId == null
            ? const Stream<QuerySnapshot<Map<String, dynamic>>>.empty()
            : FirebaseFirestore.instance
                .collection('trips')
                .where('createdBy', isEqualTo: userId)
                .snapshots(),
        builder: (context, snapshot) {
          final availableTrips = (snapshot.data?.docs ?? const []).where((doc) {
            final groupId = (doc.data()['groupId'] ?? '').toString().trim();
            return groupId.isEmpty;
          }).toList(growable: false);
          availableTrips.sort((a, b) {
            final aDate = a.data()['createdAt'];
            final bDate = b.data()['createdAt'];
            if (aDate is Timestamp && bDate is Timestamp) {
              return bDate.compareTo(aDate);
            }
            return 0;
          });

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: GestureDetector(
                  onTap: _saving ? null : _pickImage,
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: const Color(0xFFFFE0B2),
                    backgroundImage: _selectedImageBytes == null
                        ? null
                        : MemoryImage(_selectedImageBytes!),
                    child: _selectedImageBytes == null
                        ? const Icon(
                            Icons.add_a_photo_outlined,
                            size: 30,
                            color: Colors.orange,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _saving ? null : _pickImage,
                child: Text(tr.t('chooseGroupImage')),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                hint: Text(tr.t('checklistTripLinkOptional')),
                initialValue:
                    availableTrips.any((doc) => doc.id == _selectedTripId)
                        ? _selectedTripId
                        : null,
                items: availableTrips
                    .map(
                      (doc) => DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(
                          (doc.data()['title'] ?? '').toString().trim().isEmpty
                              ? tr.t('untitled_trip')
                              : (doc.data()['title'] ?? '').toString(),
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _selectedTripId = value),
                decoration: InputDecoration(
                  labelText: tr.t('checklistTrip'),
                  helperText: tr.t('leaveChecklistLinkEmpty'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                enabled: !_saving,
                decoration: InputDecoration(
                  labelText: tr.t('groupName'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                enabled: !_saving,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: tr.t('description'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(tr.t('createGroup')),
              ),
            ],
          );
        },
      ),
    );
  }
}
