import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/localization.dart';
import '../services/group_service.dart';

class LinkGroupChecklistPage extends StatefulWidget {
  const LinkGroupChecklistPage({
    super.key,
    required this.groupId,
    required this.tr,
    this.groupService,
  });

  final String groupId;
  final Tr tr;
  final GroupService? groupService;

  @override
  State<LinkGroupChecklistPage> createState() => _LinkGroupChecklistPageState();
}

class _LinkGroupChecklistPageState extends State<LinkGroupChecklistPage> {
  late final GroupService _groupService;
  bool _linking = false;

  @override
  void initState() {
    super.initState();
    _groupService = widget.groupService ?? GroupService();
  }

  Future<void> _linkTrip(String tripId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return;
    }
    setState(() => _linking = true);
    try {
      await _groupService.linkChecklistToGroup(
        groupId: widget.groupId,
        tripId: tripId,
        userId: userId,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on FirebaseException catch (error) {
      debugPrint(
        'LinkGroupChecklistPage.linkChecklistToGroup failed: '
        '${error.code} ${error.message}',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(error.message ?? widget.tr.t('unable_to_link_checklist')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _linking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final tr = widget.tr;

    return Scaffold(
      appBar: AppBar(title: Text(tr.t('link_to_checklist'))),
      body: userId == null
          ? Center(child: Text(tr.t('load_error')))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('trips')
                  .where('createdBy', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  if (error is FirebaseException) {
                    debugPrint(
                      'LinkGroupChecklistPage.loadTrips failed: '
                      '${error.code} ${error.message}',
                    );
                  }
                  return Center(child: Text(tr.t('load_error')));
                }

                final trips = (snapshot.data?.docs ??
                        <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                    .toList(growable: false);
                trips.sort((a, b) {
                  final aDate = a.data()['createdAt'];
                  final bDate = b.data()['createdAt'];
                  if (aDate is Timestamp && bDate is Timestamp) {
                    return bDate.compareTo(aDate);
                  }
                  return 0;
                });
                if (trips.isEmpty) {
                  return Center(
                    child: Text(tr.t('no_trips_create_first')),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: trips.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    final data = trip.data();
                    final title =
                        (data['title'] ?? tr.t('untitled_trip')).toString();
                    final description = (data['description'] ?? '').toString();
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        tileColor: Colors.white,
                        title: Text(title),
                        subtitle: description.trim().isEmpty
                            ? null
                            : Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                        trailing: _linking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: _linking ? null : () => _linkTrip(trip.id),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
