import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/role_provider.dart';
import '../../../core/theme/kashta_colors.dart';
import '../../../core/utils/firestore_utils.dart';
import '../../../core/utils/localization.dart';
import '../../explore/models/place_suitability.dart';
import '../../explore/services/place_service.dart';

class PendingPlacesPage extends StatefulWidget {
  const PendingPlacesPage({super.key, required this.tr});

  final Tr tr;

  @override
  State<PendingPlacesPage> createState() => _PendingPlacesPageState();
}

class _PendingPlacesPageState extends State<PendingPlacesPage> {
  final PlaceService _placeService = PlaceService();
  final Set<String> _busyIds = <String>{};
  final Map<String, PlaceSuitability> _selectedSuitabilityByPlaceId =
      <String, PlaceSuitability>{};

  @override
  Widget build(BuildContext context) {
    final tr = widget.tr;
    final provider = context.watch<RoleProvider>();
    if (!provider.isAdmin) {
      return Scaffold(body: Center(child: Text(tr.t('access_denied'))));
    }

    return Scaffold(
      appBar: AppBar(title: Text(tr.t('pending_places'))),
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
              return Center(child: Text(tr.t('permission_denied')));
            }
            return Center(child: Text(tr.t('failed_load_pending_places')));
          }

          final docs = pendingSnapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: Text(tr.t('no_pending_places')));
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
                        '${tr.t('type')}: '
                        '${(data['environmentType'] ?? '-').toString()}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${tr.t('created_by')}: '
                        '${(data['createdBy'] ?? '-').toString()}',
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
                      _buildSuitabilitySelector(placeId: placeId, tr: tr),
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
                                backgroundColor: KashtaColors.softOlive,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(tr.t('approve')),
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
                                backgroundColor: KashtaColors.softOrange,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(tr.t('reject')),
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

  Widget _buildSuitabilitySelector({
    required String placeId,
    required Tr tr,
  }) {
    final selected = _selectedSuitabilityByPlaceId[placeId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr.t('suitable_for_admin_label'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PlaceSuitability.values.map((suitability) {
            final isSelected = selected == suitability;
            return ChoiceChip(
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedSuitabilityByPlaceId[placeId] = suitability;
                });
              },
              showCheckmark: false,
              avatar: Icon(
                _suitabilityIcon(suitability),
                size: 16,
                color: isSelected ? Colors.white : KashtaColors.softOlive,
              ),
              label: Text(suitability.label(tr)),
              selectedColor: KashtaColors.softOlive,
              backgroundColor: KashtaColors.cardSurface,
              side: BorderSide(
                color: isSelected
                    ? KashtaColors.softOlive
                    : KashtaColors.sandBorder,
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : KashtaColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _suitabilityIcon(PlaceSuitability suitability) {
    switch (suitability) {
      case PlaceSuitability.families:
        return Icons.family_restroom_rounded;
      case PlaceSuitability.youth:
        return Icons.person_rounded;
      case PlaceSuitability.both:
        return Icons.groups_rounded;
    }
  }

  Future<void> _handleApproveReject({
    required String placeId,
    required bool approve,
  }) async {
    final selectedSuitability = _selectedSuitabilityByPlaceId[placeId];
    if (approve && selectedSuitability == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.tr.t('select_suitable_for_before_approval')),
        ),
      );
      return;
    }

    setState(() {
      _busyIds.add(placeId);
    });

    try {
      if (approve) {
        await _placeService.approvePlace(
          placeId: placeId,
          suitableFor: selectedSuitability!.value,
        );
      } else {
        await _placeService.rejectPlace(placeId);
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        showFirestoreError(context, e, tr: widget.tr);
      }
    } catch (_) {
      if (mounted) {
        showFirestoreError(
          context,
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'unknown',
            message: widget.tr.t('operation_failed'),
          ),
          tr: widget.tr,
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
