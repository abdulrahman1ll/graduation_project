import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/role_provider.dart';
import '../../../services/place_service.dart';
import '../../../utils/firestore_utils.dart';

class PendingPlacesPage extends StatefulWidget {
  const PendingPlacesPage({super.key});

  @override
  State<PendingPlacesPage> createState() => _PendingPlacesPageState();
}

class _PendingPlacesPageState extends State<PendingPlacesPage> {
  final PlaceService _placeService = PlaceService();
  final Set<String> _busyIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoleProvider>();
    if (!provider.isAdmin) {
      return const Scaffold(body: Center(child: Text('Access denied')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Places')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('places')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, pendingSnapshot) {
          if (pendingSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (pendingSnapshot.hasError) {
            final error = pendingSnapshot.error;
            logFirestoreReadError('places', error);
            if (error is FirebaseException &&
                error.code == 'permission-denied') {
              return const Center(child: Text('Permission denied'));
            }
            return const Center(child: Text('Failed to load pending places'));
          }

          final docs = pendingSnapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No pending places'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final placeId = doc.id;
              final imageBase64 = data['imageBase64'] as String?;
              final isBusy = _busyIds.contains(placeId);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (data['name'] ?? '').toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Type: ${(data['environmentType'] ?? '-').toString()}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created by: ${(data['createdBy'] ?? '-').toString()}',
                      ),
                      if (imageBase64 != null && imageBase64.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(imageBase64),
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isBusy
                                  ? null
                                  : () => _handleApproveReject(
                                      placeId: placeId,
                                      approve: true,
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Approve'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isBusy
                                  ? null
                                  : () => _handleApproveReject(
                                      placeId: placeId,
                                      approve: false,
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleApproveReject({
    required String placeId,
    required bool approve,
  }) async {
    setState(() {
      _busyIds.add(placeId);
    });

    try {
      if (approve) {
        await _placeService.approvePlace(placeId);
      } else {
        await _placeService.rejectPlace(placeId);
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        showFirestoreError(context, e);
      }
    } catch (_) {
      if (mounted) {
        showFirestoreError(
          context,
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'unknown',
            message: 'Operation failed',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busyIds.remove(placeId);
        });
      }
    }
  }
}
