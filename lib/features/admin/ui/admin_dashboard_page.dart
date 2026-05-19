import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/role_provider.dart';
import '../../../core/theme/kashta_colors.dart';
import '../../../core/utils/firestore_utils.dart';
import '../../../core/utils/localization.dart';
import '../../explore/models/place_suitability.dart';
import '../../explore/services/place_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    super.key,
    required this.tr,
    required this.onOpenPlace,
  });

  final Tr tr;
  final void Function({
    required String placeId,
    required double lat,
    required double lng,
    required bool openDetailsOnLoad,
  }) onOpenPlace;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final PlaceService _placeService = PlaceService();
  final Set<String> _busyPlaceIds = <String>{};
  final Set<String> _busyReviewIds = <String>{};
  final Map<String, PlaceSuitability> _selectedSuitabilityByPlaceId =
      <String, PlaceSuitability>{};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoleProvider>();
    if (!provider.isAdmin) {
      return Scaffold(body: Center(child: Text(widget.tr.t('access_denied'))));
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.tr.t('admin_dashboard'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPlacesSection(
            title: 'Pending Places',
            status: 'pending',
            emptyText: widget.tr.t('no_pending_places'),
          ),
          const SizedBox(height: 16),
          _buildPlacesSection(
            title: 'Approved Places',
            status: 'approved',
            emptyText: 'No approved places',
          ),
          const SizedBox(height: 16),
          _buildReviewsSection(),
        ],
      ),
    );
  }

  Widget _buildPlacesSection({
    required String title,
    required String status,
    required String emptyText,
  }) {
    return _buildAdminSection(
      title: title,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('places')
            .where('status', isEqualTo: status)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            logFirestoreReadError('places', error);
            if (error is FirebaseException &&
                error.code == 'permission-denied') {
              return Text(widget.tr.t('permission_denied'));
            }
            return Text(widget.tr.t('failed_load_moderation_dashboard'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Text(emptyText);
          }

          return Column(
            children: docs
                .map(
                  (doc) => _buildPlaceItem(
                    doc: doc,
                    showModerationActions: status == 'pending',
                    allowOpenPlace: status == 'approved',
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildReviewsSection() {
    return _buildAdminSection(
      title: 'Reviews / Comments',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collectionGroup('reviews').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            logFirestoreReadError('places/*/reviews', error);
            if (error is FirebaseException &&
                error.code == 'permission-denied') {
              return Text(widget.tr.t('permission_denied'));
            }
            return const Text('Failed to load reviews');
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Text('No reviews or comments');
          }

          return Column(
            children: docs.map(_buildReviewItem).toList(),
          );
        },
      ),
    );
  }

  Widget _buildAdminSection({
    required String title,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceItem({
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required bool showModerationActions,
    required bool allowOpenPlace,
  }) {
    final data = doc.data();
    final placeId = doc.id;
    final isBusy = _busyPlaceIds.contains(placeId);
    final name = (data['name'] ?? 'Untitled place').toString();
    final environmentType = (data['environmentType'] ?? '-').toString();
    final status = (data['status'] ?? '-').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap:
              allowOpenPlace ? () => _openPlaceFromData(placeId, data) : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: KashtaColors.cardSurface,
              border: Border.all(color: KashtaColors.sandBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${widget.tr.t('type')}: $environmentType'),
                  const SizedBox(height: 4),
                  Text('Status: $status'),
                  const SizedBox(height: 10),
                  if (showModerationActions) ...[
                    _buildSuitabilitySelector(placeId: placeId),
                    const SizedBox(height: 10),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (showModerationActions) ...[
                        ElevatedButton(
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
                          child: Text(widget.tr.t('approve')),
                        ),
                        ElevatedButton(
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
                          child: Text(widget.tr.t('reject')),
                        ),
                      ],
                      OutlinedButton.icon(
                        onPressed:
                            isBusy ? null : () => _handleDeletePlace(placeId),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: KashtaColors.softOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuitabilitySelector({required String placeId}) {
    final selected = _selectedSuitabilityByPlaceId[placeId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.tr.t('suitable_for_admin_label'),
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
              label: Text(suitability.label(widget.tr)),
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

  Widget _buildReviewItem(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final placeRef = doc.reference.parent.parent;
    final placeId = placeRef?.id;
    final busyKey = '${placeId ?? 'unknown'}/${doc.id}';
    final isBusy = _busyReviewIds.contains(busyKey);
    final rating = (data['rating'] ?? '-').toString();
    final comment = (data['comment'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: placeRef == null ? null : () => _openReviewPlace(placeRef),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: KashtaColors.cardSurface,
              border: Border.all(color: KashtaColors.sandBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (placeRef == null)
                    const Text(
                      'Place: unknown',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    )
                  else
                    FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: placeRef.get(),
                      builder: (context, placeSnapshot) {
                        final placeData = placeSnapshot.data?.data();
                        final placeName =
                            (placeData?['name'] ?? placeId ?? 'Unknown place')
                                .toString();

                        return Text(
                          'Place: $placeName',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        );
                      },
                    ),
                  const SizedBox(height: 4),
                  Text('Rating: $rating'),
                  const SizedBox(height: 4),
                  Text(comment.isEmpty ? 'No comment' : comment),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: isBusy || placeId == null
                        ? null
                        : () => _handleDeleteReview(
                              placeId: placeId,
                              reviewId: doc.id,
                              busyKey: busyKey,
                            ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KashtaColors.softOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openPlaceFromData(String placeId, Map<String, dynamic> data) {
    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();

    if (lat == null || lng == null) {
      _showSnackBar('This place does not have map coordinates.');
      return;
    }

    widget.onOpenPlace(
      placeId: placeId,
      lat: lat,
      lng: lng,
      openDetailsOnLoad: true,
    );
  }

  Future<void> _openReviewPlace(
    DocumentReference<Map<String, dynamic>> placeRef,
  ) async {
    try {
      final placeDoc = await placeRef.get();
      if (!mounted) return;

      final data = placeDoc.data();
      if (data == null) {
        _showSnackBar('The place for this review no longer exists.');
        return;
      }

      _openPlaceFromData(placeDoc.id, data);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to open the related place.');
    }
  }

  Future<void> _handleApproveReject({
    required String placeId,
    required bool approve,
  }) async {
    final selectedSuitability = _selectedSuitabilityByPlaceId[placeId];
    if (approve && selectedSuitability == null) {
      _showSnackBar(widget.tr.t('select_suitable_for_before_approval'));
      return;
    }

    setState(() {
      _busyPlaceIds.add(placeId);
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
      _showSnackBar(
        approve ? 'Place approved.' : 'Place rejected.',
      );
    } catch (e) {
      _showErrorSnackBar(e);
    } finally {
      if (mounted) {
        setState(() {
          _busyPlaceIds.remove(placeId);
        });
      }
    }
  }

  Future<void> _handleDeletePlace(String placeId) async {
    final confirmed = await _confirmDelete();
    if (!confirmed) return;

    setState(() {
      _busyPlaceIds.add(placeId);
    });

    try {
      await _placeService.deletePlace(placeId);
      _showSnackBar('Place deleted.');
    } catch (e) {
      _showErrorSnackBar(e);
    } finally {
      if (mounted) {
        setState(() {
          _busyPlaceIds.remove(placeId);
        });
      }
    }
  }

  Future<void> _handleDeleteReview({
    required String placeId,
    required String reviewId,
    required String busyKey,
  }) async {
    final confirmed = await _confirmDelete();
    if (!confirmed) return;

    setState(() {
      _busyReviewIds.add(busyKey);
    });

    try {
      await _placeService.deleteReview(
        placeId: placeId,
        reviewId: reviewId,
      );
      _showSnackBar('Review deleted.');
    } catch (e) {
      _showErrorSnackBar(e);
    } finally {
      if (mounted) {
        setState(() {
          _busyReviewIds.remove(busyKey);
        });
      }
    }
  }

  Future<bool> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete'),
          content: const Text('Are you sure you want to delete this?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: KashtaColors.softOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorSnackBar(Object error) {
    if (!mounted) return;

    final message = error is FirebaseException
        ? error.message ?? error.code
        : widget.tr.t('operation_failed');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
