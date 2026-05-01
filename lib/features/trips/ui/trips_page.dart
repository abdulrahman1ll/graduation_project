import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/models/app_language.dart';
import '../../../core/utils/firestore_utils.dart';
import '../../../core/utils/localization.dart';
import '../../../core/widgets/language_app_bar.dart';
import '../helpers/checklist_utils.dart';
import '../models/trip_member.dart';
import '../services/checklist_assignment_service.dart';
import '../services/checklist_user_resolver.dart';
import '../services/trip_service.dart';
import 'add_trip_page.dart';
import 'trip_details_page.dart';
import 'widgets/checklist_item_tile.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({
    super.key,
    required this.tr,
    required this.isArabic,
    required this.onToggleLanguage,
  });

  final Tr tr;
  final bool isArabic;
  final VoidCallback onToggleLanguage;

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  final TripService _tripService = TripService();
  bool _showPastTrips = false;

  void _openAddTrip() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTripPage(
          tr: widget.tr,
          isArabic: widget.isArabic,
        ),
      ),
    );
  }

  Widget _buildTripCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    bool isPast = false,
  }) {
    final data = doc.data();
    final title = (data['title'] ?? '').toString().trim();
    final groupId = (data['groupId'] ?? '').toString().trim();
    final tripDate = (data['tripDate'] as Timestamp?)?.toDate();
    final fallbackMemberCount = (data['peopleCount'] as num?)?.toInt() ?? 0;

    return _TripDecisionCard(
      tr: widget.tr,
      title: title.isEmpty ? 'Untitled trip' : title,
      groupId: groupId,
      tripDate: tripDate,
      fallbackMemberCount: fallbackMemberCount,
      membersStream: _tripService.watchTripMembers(doc.id),
      isPast: isPast,
      onOpenChecklist: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TripChecklistPage(
              tr: widget.tr,
              tripId: doc.id,
              tripTitle: title.isEmpty ? 'Untitled trip' : title,
            ),
          ),
        );
      },
      onViewDetails: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TripDetailsPage(tripId: doc.id),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('trips').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          logFirestoreReadError('trips', error);
          if (error is FirebaseException && error.code == 'permission-denied') {
            return Center(child: Text(widget.tr.t('permission_denied')));
          }
          if (error is FirebaseException) {
            final link = extractIndexLink(error.message);
            if (link != null) {
              return const Center(
                child: Text('Trips query requires a Firestore index.'),
              );
            }
          }
          return Center(child: Text(widget.tr.t('load_error')));
        }
        final docs = snapshot.data?.docs ?? [];
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        final upcomingDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final pastDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        for (final doc in docs) {
          final data = doc.data();
          final tripDateValue = data['tripDate'];
          if (tripDateValue is! Timestamp) {
            upcomingDocs.add(doc);
            continue;
          }
          final tripDate = tripDateValue.toDate();
          if (tripDate.isBefore(todayStart)) {
            pastDocs.add(doc);
          } else {
            upcomingDocs.add(doc);
          }
        }
        final upcomingCount = upcomingDocs.length;
        final pastCount = pastDocs.length;

        if (docs.isEmpty) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _TripStatCard(
                        title: 'Upcoming Trips',
                        value: upcomingCount,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TripStatCard(
                        title: 'Past Trips',
                        value: pastCount,
                        action: IconButton(
                          tooltip: _showPastTrips
                              ? 'Hide past trips'
                              : 'Show past trips',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          iconSize: 22,
                          color: Colors.grey.shade700,
                          onPressed: pastCount == 0
                              ? null
                              : () {
                                  setState(() {
                                    _showPastTrips = !_showPastTrips;
                                  });
                                },
                          icon: Icon(
                            _showPastTrips
                                ? Icons.expand_less
                                : Icons.history,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: Center(child: Text(widget.tr.t('no_trips')))),
            ],
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _TripStatCard(
                      title: 'Upcoming Trips',
                      value: upcomingCount,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TripStatCard(
                      title: 'Past Trips',
                      value: pastCount,
                      action: IconButton(
                        tooltip:
                            _showPastTrips ? 'Hide past trips' : 'Show past trips',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        iconSize: 22,
                        color: Colors.grey.shade700,
                        onPressed: pastCount == 0
                            ? null
                            : () {
                                setState(() {
                                  _showPastTrips = !_showPastTrips;
                                });
                              },
                        icon: Icon(
                          _showPastTrips ? Icons.expand_less : Icons.history,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  if (upcomingDocs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No upcoming trips.',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    )
                  else
                    ...upcomingDocs.map((doc) => _buildTripCard(doc)),
                  if (pastCount > 0) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 24),
                    _PastTripsSection(
                      trips: pastDocs,
                      isExpanded: _showPastTrips,
                      buildTripCard: (doc) =>
                          _buildTripCard(doc, isPast: true),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );

    return Scaffold(
      appBar: appBarWithLanguage(
        tr: widget.tr,
        isArabic: widget.isArabic,
        title: widget.tr.t('trips'),
        onToggleLanguage: widget.onToggleLanguage,
        actions: [
          IconButton(
            tooltip: widget.tr.t('new_trip'),
            icon: const Icon(Icons.add),
            onPressed: _openAddTrip,
          ),
        ],
      ),
      body: body,
    );
  }
}

class _PastTripsSection extends StatelessWidget {
  const _PastTripsSection({
    required this.trips,
    required this.isExpanded,
    required this.buildTripCard,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> trips;
  final bool isExpanded;
  final Widget Function(QueryDocumentSnapshot<Map<String, dynamic>> doc)
      buildTripCard;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.78,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Past Trips',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 10),
            ...trips.map(buildTripCard),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              '${trips.length} past trip${trips.length == 1 ? '' : 's'} hidden',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TripDecisionCard extends StatelessWidget {
  const _TripDecisionCard({
    required this.tr,
    required this.title,
    required this.groupId,
    required this.tripDate,
    required this.fallbackMemberCount,
    required this.membersStream,
    this.isPast = false,
    required this.onOpenChecklist,
    required this.onViewDetails,
  });

  final Tr tr;
  final String title;
  final String groupId;
  final DateTime? tripDate;
  final int fallbackMemberCount;
  final Stream<List<TripMember>> membersStream;
  final bool isPast;
  final VoidCallback onOpenChecklist;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TripMember>>(
      stream: membersStream,
      builder: (context, snapshot) {
        final members = snapshot.data ?? const <TripMember>[];
        final memberCount =
            members.isEmpty ? fallbackMemberCount : members.length;
        final status = _TripReadyStatus.fromMembers(members);
        final pendingCount =
            members.where((member) => member.status == 'pending').length;

        return Card(
          elevation: isPast ? 0.5 : 1.5,
          color: isPast ? const Color(0xFFFAFAFA) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: isPast
                ? const BorderSide(color: Color(0xFFE0E0E0))
                : BorderSide.none,
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (status != null) ...[
                      const SizedBox(width: 12),
                      _ReadyBadge(status: status),
                    ],
                  ],
                ),
                _TripGroupSubtitle(tr: tr, groupId: groupId),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    _TripInfoChip(
                      icon: Icons.calendar_today_outlined,
                      text: _formatTripDate(tripDate),
                    ),
                    _TripInfoChip(
                      icon: Icons.group_outlined,
                      text: '$memberCount ${tr.t('members')}',
                    ),
                  ],
                ),
                if (pendingCount > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 17,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pendingCount == 1
                              ? '1 member not confirmed'
                              : '$pendingCount members not confirmed',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: onOpenChecklist,
                      icon: const Icon(Icons.checklist, size: 18),
                      label: const Text('Open Checklist'),
                      style: isPast
                          ? TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade500,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onViewDetails,
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('View Details'),
                      style: isPast
                          ? TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade500,
                            )
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TripGroupSubtitle extends StatelessWidget {
  const _TripGroupSubtitle({required this.tr, required this.groupId});

  final Tr tr;
  final String groupId;

  @override
  Widget build(BuildContext context) {
    if (groupId.isEmpty) {
      return _TripGroupText(text: _noGroupText);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final groupName = (data?['name'] ?? '').toString().trim();
        if (groupName.isEmpty) {
          return _TripGroupText(text: _noGroupText);
        }

        return _TripGroupText(text: groupName);
      },
    );
  }

  String get _noGroupText {
    return tr.language == AppLanguage.ar
        ? 'لم يتم تحديد القروب بعد'
        : 'No group yet';
  }
}

class _TripGroupText extends StatelessWidget {
  const _TripGroupText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.grey.shade700,
          height: 1.25,
        ),
      ),
    );
  }
}

class _TripReadyStatus {
  const _TripReadyStatus({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  static _TripReadyStatus? fromMembers(List<TripMember> members) {
    if (members.isEmpty) {
      return null;
    }

    final goingCount =
        members.where((member) => member.status == 'going').length;
    final pendingCount =
        members.where((member) => member.status == 'pending').length;
    final notGoingCount =
        members.where((member) => member.status == 'not_going').length;

    if (notGoingCount > goingCount && notGoingCount >= pendingCount) {
      return const _TripReadyStatus(
        label: 'Not happening',
        color: Color(0xFF616161),
        icon: Icons.circle,
      );
    }

    if (goingCount > pendingCount && goingCount >= notGoingCount) {
      return const _TripReadyStatus(
        label: 'Ready',
        color: Color(0xFF616161),
        icon: Icons.circle,
      );
    }

    return null;
  }
}

class _ReadyBadge extends StatelessWidget {
  const _ReadyBadge({required this.status});

  final _TripReadyStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 9, color: status.color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripInfoChip extends StatelessWidget {
  const _TripInfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19, color: const Color.fromARGB(255, 238, 156, 54)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade900,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

String _formatTripDate(DateTime? value) {
  if (value == null) {
    return 'No date';
  }

  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour < 12 ? 'AM' : 'PM';

  return '${value.day} ${months[value.month - 1]} • $hour:$minute $period';
}

class _TripStatCard extends StatelessWidget {
  const _TripStatCard({
    required this.title,
    required this.value,
    this.action,
  });

  final String title;
  final int value;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        height: 90,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade900,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: action == null
                        ? const SizedBox.shrink()
                        : IconTheme(
                            data: IconThemeData(
                              color: Colors.grey.shade700,
                              size: 22,
                            ),
                            child: action!,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddChecklistItemsPage extends StatefulWidget {
  const AddChecklistItemsPage({
    super.key,
    required this.tr,
    required this.tripId,
  });

  final Tr tr;
  final String tripId;

  @override
  State<AddChecklistItemsPage> createState() => _AddChecklistItemsPageState();
}

class _AddChecklistItemsPageState extends State<AddChecklistItemsPage> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedCategories = <String>{};

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final nextQuery = _searchController.text.trim().toLowerCase();
    if (nextQuery == _searchQuery) {
      return;
    }
    setState(() => _searchQuery = nextQuery);
  }

  Future<void> _addTemplateToTripChecklist(
    BuildContext context,
    _ChecklistTemplateGroupView group,
    QueryDocumentSnapshot<Map<String, dynamic>> itemDoc,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final itemData = itemDoc.data();
    final itemId = itemDoc.id;
    final itemName = checklistDisplayName(
      tr: widget.tr,
      data: itemData,
      arKey: 'name_ar',
      enKey: 'name_en',
      fallbackKey: 'name',
    );
    final groupName = checklistDisplayName(
      tr: widget.tr,
      data: group.data,
      arKey: 'name_ar',
      enKey: 'name_en',
      fallbackKey: 'category',
    );

    try {
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .collection('checklist')
          .doc(itemId)
          .set({
        'itemId': itemId,
        'groupId': group.id,
        'sourceTemplatePath': group.reference.path,
        'name': itemName,
        'name_ar': (itemData['name_ar'] ?? '').toString(),
        'name_en': (itemData['name_en'] ?? '').toString(),
        'category': groupName,
        'category_ar': (group.data['name_ar'] ?? '').toString(),
        'category_en': (group.data['name_en'] ?? '').toString(),
        'done': false,
        'addedBy': userId ?? 'unknown',
        'assignedTo': null,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(widget.tr.t('checklist_item_added'))),
        );
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        showFirestoreError(context, e);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(widget.tr.t('save_failed'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tr.t('add_checklist_items'))),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('checklist_templates')
            .orderBy('order')
            .snapshots(),
        builder: (context, groupsSnapshot) {
          if (groupsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (groupsSnapshot.hasError) {
            logFirestoreReadError(
              'checklist_templates',
              groupsSnapshot.error,
            );
            return Center(child: Text(widget.tr.t('load_error')));
          }

          final groupDocs = groupsSnapshot.data?.docs ?? [];
          if (groupDocs.isEmpty) {
            return Center(child: Text(widget.tr.t('no_checklist_templates')));
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream:
                FirebaseFirestore.instance.collectionGroup('items').snapshots(),
            builder: (context, itemsSnapshot) {
              if (itemsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (itemsSnapshot.hasError) {
                logFirestoreReadError(
                  'checklist_templates/*/items',
                  itemsSnapshot.error,
                );
                return Center(child: Text(widget.tr.t('load_error')));
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('trips')
                    .doc(widget.tripId)
                    .collection('checklist')
                    .snapshots(),
                builder: (context, checklistSnapshot) {
                  if (checklistSnapshot.hasError) {
                    logFirestoreReadError(
                      'trips/*/checklist',
                      checklistSnapshot.error,
                    );
                  }

                  final existingItemIds = checklistSnapshot.data?.docs
                          .map((doc) {
                            final data = doc.data();
                            final itemId =
                                (data['itemId'] ?? '').toString().trim();
                            if (itemId.isNotEmpty) {
                              return itemId;
                            }
                            return '';
                          })
                          .where((itemId) => itemId.isNotEmpty)
                          .toSet() ??
                      <String>{};

                  final groupById =
                      <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
                    for (final doc in groupDocs) doc.id: doc,
                  };
                  final groupedItems = <String,
                      List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

                  for (final itemDoc in itemsSnapshot.data?.docs ??
                      <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
                    final groupRef = itemDoc.reference.parent.parent;
                    final parentCollectionId = groupRef?.parent.id;
                    final groupId = groupRef?.id;
                    if (parentCollectionId != 'checklist_templates' ||
                        groupId == null ||
                        !groupById.containsKey(groupId)) {
                      continue;
                    }
                    groupedItems.putIfAbsent(
                      groupId,
                      () => <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                    );
                    groupedItems[groupId]!.add(itemDoc);
                  }

                  final groups = <_ChecklistTemplateGroupView>[];
                  for (final groupDoc in groupDocs) {
                    final groupId = groupDoc.id;
                    final groupData = groupDoc.data();
                    final groupItems = [
                      ...(groupedItems[groupId] ??
                          <QueryDocumentSnapshot<Map<String, dynamic>>>[]),
                    ]..sort((a, b) {
                        final aOrder =
                            (a.data()['order'] as num?)?.toInt() ?? 9999;
                        final bOrder =
                            (b.data()['order'] as num?)?.toInt() ?? 9999;
                        return aOrder.compareTo(bOrder);
                      });

                    final groupNameAr = (groupData['name_ar'] ?? '').toString();
                    final groupNameEn = (groupData['name_en'] ?? '').toString();
                    final filteredItems = groupItems.where((itemDoc) {
                      if (_searchQuery.isEmpty) {
                        return true;
                      }

                      final itemData = itemDoc.data();
                      final itemNameAr =
                          (itemData['name_ar'] ?? '').toString().toLowerCase();
                      final itemNameEn =
                          (itemData['name_en'] ?? '').toString().toLowerCase();
                      final normalizedQuery = _searchQuery.toLowerCase();
                      final matchesItem =
                          itemNameAr.contains(normalizedQuery) ||
                              itemNameEn.contains(normalizedQuery);
                      final matchesGroup = groupNameAr
                              .toLowerCase()
                              .contains(normalizedQuery) ||
                          groupNameEn.toLowerCase().contains(normalizedQuery);
                      return matchesItem || matchesGroup;
                    }).toList();

                    if (filteredItems.isEmpty) {
                      continue;
                    }

                    groups.add(
                      _ChecklistTemplateGroupView(
                        id: groupId,
                        reference: groupDoc.reference,
                        data: groupData,
                        items: filteredItems,
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: widget.tr.language == AppLanguage.ar
                                ? 'ابحث في عناصر القائمة'
                                : 'Search checklist items',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: const Color(0xFFF7F7F7),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide:
                                  const BorderSide(color: Colors.orange),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: groups.isEmpty
                            ? Center(
                                child: Text(
                                  widget.tr.language == AppLanguage.ar
                                      ? 'لا توجد عناصر مطابقة'
                                      : 'No matching items',
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: groups.length,
                                itemBuilder: (context, index) {
                                  final isArabic =
                                      Localizations.localeOf(context)
                                              .languageCode ==
                                          'ar';
                                  final group = groups[index];
                                  final groupTitle = checklistDisplayName(
                                    tr: widget.tr,
                                    data: group.data,
                                    arKey: 'name_ar',
                                    enKey: 'name_en',
                                    fallbackKey: 'category',
                                  );
                                  final groupEmoji =
                                      emojiForChecklistGroupId(group.id);
                                  final isExpanded = _searchQuery.isNotEmpty ||
                                      _expandedCategories.contains(group.id);

                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    elevation: 1.5,
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: ExpansionTile(
                                      key: PageStorageKey<String>(
                                        'checklist-group-${group.id}-${_searchQuery.isNotEmpty}',
                                      ),
                                      tilePadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      childrenPadding:
                                          const EdgeInsets.fromLTRB(
                                        16,
                                        8,
                                        16,
                                        16,
                                      ),
                                      initiallyExpanded: isExpanded,
                                      onExpansionChanged: (expanded) {
                                        setState(() {
                                          if (expanded) {
                                            _expandedCategories.add(group.id);
                                          } else {
                                            _expandedCategories
                                                .remove(group.id);
                                          }
                                        });
                                      },
                                      title: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color:
                                                  checklistGroupEmojiBackgroundColor(
                                                group.id,
                                              ).withValues(alpha: 0.9),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              groupEmoji,
                                              style:
                                                  const TextStyle(fontSize: 22),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              '$groupTitle (${group.items.length})',
                                              style: TextStyle(
                                                fontSize: isArabic ? 15 : 16.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      children: group.items.map((itemDoc) {
                                        final itemData = itemDoc.data();
                                        final itemId = itemDoc.id;
                                        final itemName = checklistDisplayName(
                                          tr: widget.tr,
                                          data: itemData,
                                          arKey: 'name_ar',
                                          enKey: 'name_en',
                                          fallbackKey: 'name',
                                        );
                                        final alreadyAdded =
                                            existingItemIds.contains(itemId);

                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: ListTile(
                                              dense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                              title: Text(
                                                itemName,
                                                style: TextStyle(
                                                  fontSize:
                                                      isArabic ? 16 : 17.5,
                                                  fontWeight: isArabic
                                                      ? FontWeight.w500
                                                      : FontWeight.w400,
                                                ),
                                              ),
                                              trailing: alreadyAdded
                                                  ? Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.check_circle,
                                                          color:
                                                              Color(0xFF43A047),
                                                          size: 18,
                                                        ),
                                                        const SizedBox(
                                                            width: 6),
                                                        Text(
                                                          widget.tr.t('added'),
                                                          style:
                                                              const TextStyle(
                                                            color: Color(
                                                              0xFF43A047,
                                                            ),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : IconButton(
                                                      icon: const Icon(
                                                        Icons.add_circle,
                                                        color: Colors.orange,
                                                        size: 18,
                                                      ),
                                                      onPressed: () =>
                                                          _addTemplateToTripChecklist(
                                                        context,
                                                        group,
                                                        itemDoc,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ChecklistTemplateGroupView {
  const _ChecklistTemplateGroupView({
    required this.id,
    required this.reference,
    required this.data,
    required this.items,
  });

  final String id;
  final DocumentReference<Map<String, dynamic>> reference;
  final Map<String, dynamic> data;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> items;
}

class TripChecklistPage extends StatefulWidget {
  const TripChecklistPage({
    super.key,
    required this.tr,
    required this.tripId,
    required this.tripTitle,
  });

  final Tr tr;
  final String tripId;
  final String tripTitle;

  @override
  State<TripChecklistPage> createState() => _TripChecklistPageState();
}

class _TripChecklistPageState extends State<TripChecklistPage> {
  final ChecklistAssignmentService _assignmentService =
      ChecklistAssignmentService();
  final ChecklistUserResolver _userResolver = ChecklistUserResolver();
  final Set<String> _assignmentInProgressIds = <String>{};

  Future<void> _toggleDone(
    BuildContext context,
    String itemId,
    bool newValue,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .collection('checklist')
          .doc(itemId)
          .update({'done': newValue});
    } on FirebaseException catch (e) {
      if (context.mounted) {
        showFirestoreError(context, e);
      }
    }
  }

  Future<void> _toggleAssignment(
    BuildContext context, {
    required String itemId,
    required String currentUserId,
    required String? assignedTo,
  }) async {
    setState(() {
      _assignmentInProgressIds.add(itemId);
    });

    try {
      await _assignmentService.toggleAssignment(
        tripId: widget.tripId,
        itemId: itemId,
        currentUserId: currentUserId,
        assignedTo: assignedTo,
      );
    } on FirebaseException catch (e) {
      if (context.mounted) {
        showFirestoreError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _assignmentInProgressIds.remove(itemId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    void openAddChecklistItems() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddChecklistItemsPage(
            tr: widget.tr,
            tripId: widget.tripId,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tr.t('trip_checklist')} - ${widget.tripTitle}'),
        actions: [
          IconButton(
            tooltip: 'Add from templates',
            onPressed: openAddChecklistItems,
            icon: const Icon(
              Icons.playlist_add,
              color: Colors.orange,
              size: 26,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF8EFE2),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/chat_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0xFFF8EFE2).withValues(alpha: 0.2),
            ),
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('trips')
                .doc(widget.tripId)
                .collection('checklist')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                logFirestoreReadError('trips/*/checklist', snapshot.error);
                return Center(child: Text(widget.tr.t('load_error')));
              }

              final docs = (snapshot.data?.docs ?? []).where((doc) {
                final itemId = (doc.data()['itemId'] ?? '').toString().trim();
                return itemId.isNotEmpty;
              }).toList();
              final sortedDocs = sortChecklistByCompletion(docs);
              final totalItems = sortedDocs.length;
              final doneCount =
                  sortedDocs.where((doc) => doc.data()['done'] == true).length;
              final progress = checklistProgressValue(
                doneCount: doneCount,
                totalCount: totalItems,
              );
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tr.t('checklist_progress'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('0 / 0 ${widget.tr.t('items_completed')}'),
                      const SizedBox(height: 10),
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F1F1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Center(
                          child: Text(widget.tr.t('no_checklist_items')),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                    child: Text(
                      widget.tr.t('checklist_progress'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '$doneCount / $totalItems ${widget.tr.t('items_completed')}',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFFFC15A),
                                    Color(0xFFFF8A3D),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: sortedDocs.length,
                      itemBuilder: (context, index) {
                        final doc = sortedDocs[index];
                        final data = doc.data();
                        final done = data['done'] == true;
                        final itemId = doc.id;
                        final assignedTo =
                            (data['assignedTo'] as String?)?.trim();
                        final runtimeItemId = (data['itemId'] ?? '').toString();
                        final legacyIconName = (data['icon'] ?? '').toString();
                        final itemName = checklistDisplayName(
                          tr: widget.tr,
                          data: data,
                          arKey: 'name_ar',
                          enKey: 'name_en',
                          fallbackKey: 'name',
                        );
                        final itemIcon = runtimeItemId.isNotEmpty
                            ? iconFromChecklistItemId(runtimeItemId)
                            : iconFromName(legacyIconName);

                        return ChecklistItemTile(
                          itemName: itemName,
                          itemIcon: itemIcon,
                          done: done,
                          assignedTo: assignedTo,
                          currentUserId: currentUserId,
                          userResolver: _userResolver,
                          assignmentInProgress:
                              _assignmentInProgressIds.contains(itemId),
                          onDoneChanged: (value) =>
                              _toggleDone(context, itemId, value),
                          onAssignPressed: currentUserId == null
                              ? () {}
                              : () => _toggleAssignment(
                                    context,
                                    itemId: itemId,
                                    currentUserId: currentUserId,
                                    assignedTo: assignedTo,
                                  ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
