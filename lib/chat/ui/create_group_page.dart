import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/group_service.dart';
import 'group_chat_page.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({
    super.key,
    this.initialTripId,
    this.groupService,
  });

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
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final tripId = _selectedTripId;
    if (userId == null) {
      return;
    }
    if (tripId == null ||
        tripId.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip, name, and description are required.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final groupId = await _groupService.createGroup(
        tripId,
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
          builder: (_) => GroupChatPage(groupId: groupId),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to create group.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to create group.')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          final availableTrips = (snapshot.data?.docs ?? const [])
              .where((doc) {
                final groupId = (doc.data()['groupId'] ?? '').toString().trim();
                return groupId.isEmpty;
              })
              .toList(growable: false);

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
                child: const Text('Choose group image'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: availableTrips.any((doc) => doc.id == _selectedTripId)
                    ? _selectedTripId
                    : null,
                items: availableTrips
                    .map(
                      (doc) => DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text((doc.data()['title'] ?? '').toString()),
                      ),
                    )
                    .toList(growable: false),
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _selectedTripId = value),
                decoration: const InputDecoration(
                  labelText: 'Trip',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Group name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                enabled: !_saving,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
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
                    : const Text('Create group'),
              ),
            ],
          );
        },
      ),
    );
  }
}
