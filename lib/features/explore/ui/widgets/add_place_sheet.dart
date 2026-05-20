import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddPlaceSheet extends StatefulWidget {
  const AddPlaceSheet({
    super.key,
    required this.onSubmit,
  });

  final Future<void> Function({
    required BuildContext sheetContext,
    required String name,
    required String description,
    required String environmentType,
    required Uint8List? selectedImageBytes,
  }) onSubmit;

  @override
  State<AddPlaceSheet> createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends State<AddPlaceSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _environmentType = 'desert';
  Uint8List? _selectedImageBytes;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedImageBytes = bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Add New Place'),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Place Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLength: 200,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Write a short description about this place...',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _environmentType,
            items: const [
              DropdownMenuItem(value: 'desert', child: Text('Desert')),
              DropdownMenuItem(value: 'nature', child: Text('Nature')),
              DropdownMenuItem(value: 'beach', child: Text('Beach')),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _environmentType = value;
              });
            },
            decoration: const InputDecoration(
              labelText: 'Environment Type',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _pickImage,
            child: const Text('Pick Image (Optional)'),
          ),
          const SizedBox(height: 10),
          if (_selectedImageBytes != null)
            Image.memory(_selectedImageBytes!, height: 120),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () async {
              await widget.onSubmit(
                sheetContext: context,
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim(),
                environmentType: _environmentType,
                selectedImageBytes: _selectedImageBytes,
              );
            },
            child: const Text('Submit'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
