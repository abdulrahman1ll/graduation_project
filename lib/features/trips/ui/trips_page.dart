import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/models/app_language.dart';
import '../../../core/utils/firestore_utils.dart';
import '../../../core/utils/localization.dart';
import '../../../core/widgets/language_app_bar.dart';
import '../helpers/checklist_utils.dart';
import 'add_trip_page.dart';

class TripsPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWithLanguage(
        tr: tr,
        isArabic: isArabic,
        title: tr.t('trips'),
        onToggleLanguage: onToggleLanguage,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            logFirestoreReadError('trips', error);
            if (error is FirebaseException &&
                error.code == 'permission-denied') {
              return Center(child: Text(tr.t('permission_denied')));
            }
            if (error is FirebaseException) {
              final link = extractIndexLink(error.message);
              if (link != null) {
                return const Center(
                  child: Text('Trips query requires a Firestore index.'),
                );
              }
            }
            return Center(child: Text(tr.t('load_error')));
          }
          final docs = snapshot.data?.docs ?? [];
          final today = DateTime.now();
          final todayStart = DateTime(today.year, today.month, today.day);
          int upcomingCount = 0;
          int pastCount = 0;
          for (final doc in docs) {
            final data = doc.data();
            final tripDateValue = data['tripDate'];
            if (tripDateValue is! Timestamp) {
              continue;
            }
            final tripDate = tripDateValue.toDate();
            if (tripDate.isBefore(todayStart)) {
              pastCount++;
            } else {
              upcomingCount++;
            }
          }

          if (docs.isEmpty) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TripStatCard(
                          title: tr.t('upcoming'),
                          value: upcomingCount,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TripStatCard(
                          title: tr.t('past'),
                          value: pastCount,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: Center(child: Text(tr.t('no_trips')))),
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
                        title: tr.t('upcoming'),
                        value: upcomingCount,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TripStatCard(
                        title: tr.t('past'),
                        value: pastCount,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = docs[index].data();
                    return Card(
                      child: ListTile(
                        title: Text((data['title'] ?? '').toString()),
                        subtitle: Text((data['description'] ?? '').toString()),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${tr.t('members')} ${(data['peopleCount'] ?? 0)}',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: tr.t('trip_checklist'),
                              icon: const Icon(
                                Icons.checklist,
                                color: Colors.orange,
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TripChecklistPage(
                                      tr: tr,
                                      tripId: doc.id,
                                      tripTitle: (data['title'] ?? '')
                                          .toString(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddTripPage(tr: tr, isArabic: isArabic),
            ),
          );
        },
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(tr.t('new_trip')),
      ),
    );
  }
}

class _TripStatCard extends StatelessWidget {
  const _TripStatCard({required this.title, required this.value});

  final String title;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
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
            stream: FirebaseFirestore.instance.collectionGroup('items').snapshots(),
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

                  final existingItemIds =
                      checklistSnapshot.data?.docs
                          .map((doc) {
                            final data = doc.data();
                            final itemId = (data['itemId'] ?? '').toString().trim();
                            if (itemId.isNotEmpty) {
                              return itemId;
                            }
                            return '';
                          })
                          .where((itemId) => itemId.isNotEmpty)
                          .toSet() ??
                      <String>{};

                  final groupById = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
                    for (final doc in groupDocs) doc.id: doc,
                  };
                  final groupedItems =
                      <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

                  for (final itemDoc
                      in itemsSnapshot.data?.docs ??
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
                    ]
                      ..sort((a, b) {
                        final aOrder = (a.data()['order'] as num?)?.toInt() ?? 9999;
                        final bOrder = (b.data()['order'] as num?)?.toInt() ?? 9999;
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
                      final matchesItem = itemNameAr.contains(normalizedQuery) ||
                          itemNameEn.contains(normalizedQuery);
                      final matchesGroup =
                          groupNameAr.toLowerCase().contains(normalizedQuery) ||
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
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: const BorderSide(color: Colors.orange),
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
                                      childrenPadding: const EdgeInsets.fromLTRB(
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
                                            _expandedCategories.remove(group.id);
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
                                              style: const TextStyle(fontSize: 22),
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
                                          padding: const EdgeInsets.only(top: 5),
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
                                                  fontSize: isArabic ? 16 : 17.5,
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
                                                          color: Color(0xFF43A047),
                                                          size: 18,
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          widget.tr.t('added'),
                                                          style:
                                                              const TextStyle(
                                                                color: Color(
                                                                  0xFF43A047,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
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

Color _checklistAssignmentColor(String userId) {
  const colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];
  return colors[userId.hashCode.abs() % colors.length];
}

class _ChecklistAssignmentPreview extends StatelessWidget {
  const _ChecklistAssignmentPreview({
    required this.assignedTo,
    required this.currentUserId,
  });

  final String? assignedTo;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final isUnassigned = assignedTo == null || assignedTo!.isEmpty;
    final color = isUnassigned
        ? Colors.grey
        : _checklistAssignmentColor(assignedTo!).withValues(alpha: 0.8);
    final dot = isUnassigned ? '○' : '●';
    final label = isUnassigned
        ? 'Unassigned'
        : assignedTo == currentUserId
        ? 'You'
        : 'Member';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          dot,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
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
  final Map<String, String?> _localAssignedToOverrides = <String, String?>{};

  String? _effectiveAssignedTo(String itemId, String? persistedAssignedTo) {
    if (_localAssignedToOverrides.containsKey(itemId)) {
      return _localAssignedToOverrides[itemId];
    }
    return persistedAssignedTo;
  }

  void _toggleLocalAssignment({
    required String itemId,
    required String? currentUserId,
    required String? assignedTo,
  }) {
    if (currentUserId == null || currentUserId.isEmpty) {
      return;
    }

    setState(() {
      _localAssignedToOverrides[itemId] =
          assignedTo == currentUserId ? null : currentUserId;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tr.t('trip_checklist')} - ${widget.tripTitle}'),
        actions: [
          IconButton(
            tooltip: widget.tr.t('add'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddChecklistItemsPage(
                    tr: widget.tr,
                    tripId: widget.tripId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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

          final docs =
              (snapshot.data?.docs ?? [])
                  .where((doc) {
                    final itemId = (doc.data()['itemId'] ?? '').toString().trim();
                    return itemId.isNotEmpty;
                  })
                  .toList();
          final sortedDocs = sortChecklistByCompletion(docs);
          final totalItems = sortedDocs.length;
          final doneCount = sortedDocs
              .where((doc) => doc.data()['done'] == true)
              .length;
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
                  const LinearProgressIndicator(
                    value: 0,
                    color: Colors.orange,
                    backgroundColor: Color(0xFFF5F5F5),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    color: Colors.orange,
                    backgroundColor: const Color(0xFFF1F1F1),
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
                    final itemId = (data['itemId'] ?? '').toString();
                    final persistedAssignedTo =
                        (data['assignedTo'] as String?)?.trim();
                    final assignedTo = _effectiveAssignedTo(
                      itemId,
                      persistedAssignedTo,
                    );
                    final legacyIconName = (data['icon'] ?? '').toString();
                    final itemName = checklistDisplayName(
                      tr: widget.tr,
                      data: data,
                      arKey: 'name_ar',
                      enKey: 'name_en',
                      fallbackKey: 'name',
                    );
                    final itemIcon = itemId.isNotEmpty
                        ? iconFromChecklistItemId(itemId)
                        : iconFromName(legacyIconName);

                    return Card(
                      elevation: 1.2,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: CheckboxListTile(
                        value: done,
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          _toggleDone(context, doc.id, value);
                        },
                        activeColor: Colors.orange,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Row(
                          children: [
                            Icon(itemIcon, color: Colors.orange),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                itemName,
                                style: TextStyle(
                                  decoration: done
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _ChecklistAssignmentPreview(
                              assignedTo: assignedTo,
                              currentUserId: currentUserId,
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 18,
                                color: Colors.orange,
                              ),
                              visualDensity: VisualDensity.compact,
                              splashRadius: 18,
                              onPressed: () => _toggleLocalAssignment(
                                itemId: itemId,
                                currentUserId: currentUserId,
                                assignedTo: assignedTo,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(widget.tr.t('add_from_template')),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddChecklistItemsPage(
                tr: widget.tr,
                tripId: widget.tripId,
              ),
            ),
          );
        },
      ),
    );
  }
}



