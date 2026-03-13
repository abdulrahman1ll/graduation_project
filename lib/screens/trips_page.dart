part of 'app_shell.dart';

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
            .where('visibility', isEqualTo: 'public')
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

class AddChecklistItemsPage extends StatelessWidget {
  const AddChecklistItemsPage({
    super.key,
    required this.tr,
    required this.tripId,
  });

  final Tr tr;
  final String tripId;

  Future<void> _addTemplateToTripChecklist(
    BuildContext context,
    String templateId,
    Map<String, dynamic> data,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    try {
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(tripId)
          .collection('checklist')
          .doc(templateId)
          .set({
            'name': (data['name'] ?? '').toString(),
            'category': (data['category'] ?? '').toString(),
            'icon': (data['icon'] ?? 'checklist').toString(),
            'done': false,
            'addedBy': userId ?? 'unknown',
            'assignedTo': null,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr.t('checklist_item_added'))));
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        showFirestoreError(context, e);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr.t('save_failed'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr.t('add_checklist_items'))),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('checklist_templates')
            .snapshots(),
        builder: (context, templatesSnapshot) {
          if (templatesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (templatesSnapshot.hasError) {
            logFirestoreReadError(
              'checklist_templates',
              templatesSnapshot.error,
            );
            return Center(child: Text(tr.t('load_error')));
          }

          final docs = templatesSnapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: Text(tr.t('no_checklist_templates')));
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('trips')
                .doc(tripId)
                .collection('checklist')
                .snapshots(),
            builder: (context, checklistSnapshot) {
              if (checklistSnapshot.hasError) {
                logFirestoreReadError(
                  'trips/*/checklist',
                  checklistSnapshot.error,
                );
              }
              final existingIds =
                  checklistSnapshot.data?.docs.map((doc) => doc.id).toSet() ??
                  <String>{};

              final grouped =
                  <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
              for (final doc in docs) {
                final data = doc.data();
                final category = (data['category'] ?? tr.t('other')).toString();
                grouped.putIfAbsent(
                  category,
                  () => <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                );
                grouped[category]!.add(doc);
              }
              final categoryCounts = categoryTemplateCounts(docs, tr);
              final categories = grouped.keys.toList()..sort();
              for (final category in categories) {
                grouped[category]!.sort((a, b) {
                  final aName = (a.data()['name'] ?? '').toString();
                  final bName = (b.data()['name'] ?? '').toString();
                  return aName.compareTo(bName);
                });
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final items = grouped[category]!;
                  final count = categoryCounts[category] ?? 0;
                  return Card(
                    elevation: 1.2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ExpansionTile(
                      title: Text(
                        '$category ($count)',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      children: items.map((itemDoc) {
                        final data = itemDoc.data();
                        final iconName = (data['icon'] ?? 'checklist')
                            .toString();
                        final name = (data['name'] ?? '').toString();
                        final alreadyAdded = existingIds.contains(itemDoc.id);
                        return ListTile(
                          leading: Icon(
                            iconFromName(iconName),
                            color: Colors.orange,
                          ),
                          title: Text(name),
                          trailing: alreadyAdded
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      tr.t('added'),
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : IconButton(
                                  icon: const Icon(
                                    Icons.add_circle,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () => _addTemplateToTripChecklist(
                                    context,
                                    itemDoc.id,
                                    data,
                                  ),
                                ),
                        );
                      }).toList(),
                    ),
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

class TripChecklistPage extends StatelessWidget {
  const TripChecklistPage({
    super.key,
    required this.tr,
    required this.tripId,
    required this.tripTitle,
  });

  final Tr tr;
  final String tripId;
  final String tripTitle;

  Future<void> _toggleDone(
    BuildContext context,
    String itemId,
    bool newValue,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(tripId)
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
    return Scaffold(
      appBar: AppBar(
        title: Text('${tr.t('trip_checklist')} - $tripTitle'),
        actions: [
          IconButton(
            tooltip: tr.t('add'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddChecklistItemsPage(tr: tr, tripId: tripId),
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
            .doc(tripId)
            .collection('checklist')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            logFirestoreReadError('trips/*/checklist', snapshot.error);
            return Center(child: Text(tr.t('load_error')));
          }

          final docs = snapshot.data?.docs ?? [];
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
                    tr.t('checklist_progress'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('0 / 0 ${tr.t('items_completed')}'),
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(
                    value: 0,
                    color: Colors.orange,
                    backgroundColor: Color(0xFFF5F5F5),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Center(child: Text(tr.t('no_checklist_items'))),
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
                  tr.t('checklist_progress'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$doneCount / $totalItems ${tr.t('items_completed')}',
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
                    final iconName = (data['icon'] ?? 'checklist').toString();
                    final itemName = (data['name'] ?? '').toString();

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
                            Icon(iconFromName(iconName), color: Colors.orange),
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
        label: Text(tr.t('add_from_template')),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddChecklistItemsPage(tr: tr, tripId: tripId),
            ),
          );
        },
      ),
    );
  }
}

class AddTripPage extends StatefulWidget {
  const AddTripPage({super.key, required this.tr, required this.isArabic});

  final Tr tr;
  final bool isArabic;

  @override
  State<AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends State<AddTripPage> {
  final TripService _tripService = TripService();
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
                _tripDate == null
                    ? tr.t('choose_trip_date')
                    : _formatDate(_tripDate!),
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
      await _tripService.createTrip(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        peopleCount: count,
        locationUrl: _locationUrlController.text.trim(),
        tripDate: _tripDate!,
        visibility: _visibility,
      );
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


