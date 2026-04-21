import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/group.dart';
import '../models/member.dart';
import '../services/group_service.dart';
import '../helpers/group_checklist_flow.dart';
import '../../../core/models/app_language.dart';
import '../../trips/ui/add_trip_page.dart';
import '../../../core/utils/firestore_utils.dart';
import '../../../core/utils/localization.dart';

class GroupDetailsPage extends StatelessWidget {
  const GroupDetailsPage({
    super.key,
    required this.groupId,
    this.groupService,
  });

  final String groupId;
  final GroupService? groupService;

  Future<void> _showPlanTripOptions(
    BuildContext context,
    Group group,
    GroupService resolvedGroupService,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.event_available),
                title: const Text('Select existing trip'),
                onTap: () => Navigator.of(context).pop('existing'),
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Create new trip'),
                onTap: () => Navigator.of(context).pop('create'),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || selected == null) {
      return;
    }

    if (selected == 'existing') {
      await _showExistingTripsSheet(context, group, resolvedGroupService);
      return;
    }

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final tr = Tr(isArabic ? AppLanguage.ar : AppLanguage.en);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (tripContext) => AddTripPage(
          tr: tr,
          isArabic: isArabic,
          linkedGroupId: group.id,
        ),
      ),
    );
  }

  Future<void> _showExistingTripsSheet(
    BuildContext context,
    Group group,
    GroupService resolvedGroupService,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in first.')));
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.7,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('trips')
                  .orderBy('tripDate')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  logFirestoreReadError('trips', snapshot.error);
                  return const Center(child: Text('Failed to load trips.'));
                }

                final docs =
                    (snapshot.data?.docs ?? []).where((doc) {
                      final linkedGroupId =
                          (doc.data()['groupId'] ?? '').toString().trim();
                      return linkedGroupId.isEmpty || linkedGroupId == group.id;
                    }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('No trips available.'));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (tripContext, itemIndex) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final title = (data['title'] ?? '').toString().trim();
                    final tripDate = (data['tripDate'] as Timestamp?)?.toDate();

                    return ListTile(
                      title: Text(title.isEmpty ? 'Untitled trip' : title),
                      subtitle: Text(
                        tripDate == null ? 'No date' : _formatTripDate(tripDate),
                      ),
                      onTap: () async {
                        try {
                          await resolvedGroupService.linkChecklistToGroup(
                            groupId: group.id,
                            tripId: doc.id,
                            userId: userId,
                          );
                          if (context.mounted) {
                            Navigator.of(sheetContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Trip linked to group')),
                            );
                          }
                        } on FirebaseException catch (e) {
                          if (context.mounted) {
                            showFirestoreError(context, e);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to link trip: $e')),
                            );
                          }
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _formatTripDate(DateTime value) {
    final year = value.year.toString();
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year/$month/$day';
  }

  @override
  Widget build(BuildContext context) {
    final resolvedGroupService = groupService ?? GroupService();

    return StreamBuilder<Group?>(
      stream: resolvedGroupService.watchGroup(groupId),
      builder: (context, groupSnapshot) {
        final group = groupSnapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Group Details'),
          ),
          body: group == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<List<Member>>(
                  stream: resolvedGroupService.watchMembers(groupId),
                  builder: (context, membersSnapshot) {
                    final members = membersSnapshot.data ?? const <Member>[];
                    final memberIds = members
                        .map((member) => member.userId)
                        .where((id) => id.trim().isNotEmpty)
                        .toSet()
                        .toList(growable: false);

                    return FutureBuilder<Map<String, String>>(
                      future: resolvedGroupService.resolveUserNames(memberIds),
                      builder: (context, namesSnapshot) {
                        final memberNames =
                            namesSnapshot.data ?? const <String, String>{};

                        return ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            Center(
                              child: CircleAvatar(
                                radius: 56,
                                backgroundColor: const Color(0xFFFFE0B2),
                                backgroundImage: group.imageUrl == null
                                    ? null
                                    : NetworkImage(group.imageUrl!),
                                child: group.imageUrl == null
                                    ? const Icon(
                                        Icons.groups,
                                        size: 40,
                                        color: Colors.orange,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              group.name.trim().isEmpty
                                  ? 'Group Chat'
                                  : group.name,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              group.description.trim().isEmpty
                                  ? 'No description yet.'
                                  : group.description,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => openGroupChecklistFlow(
                                  context: context,
                                  group: group,
                                  groupId: groupId,
                                  groupService: resolvedGroupService,
                                ),
                                child: Text(
                                  (group.tripId?.trim().isEmpty ?? true)
                                      ? 'Link to checklist'
                                      : 'Open checklist',
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _showPlanTripOptions(
                                  context,
                                  group,
                                  resolvedGroupService,
                                ),
                                icon: const Icon(Icons.calendar_month),
                                label: const Text('Plan next trip'),
                              ),
                            ),
                            if (group.tripId?.trim().isNotEmpty ?? false) ...[
                              const SizedBox(height: 20),
                              Text(
                                'Upcoming Trip',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 10),
                              FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                future: FirebaseFirestore.instance
                                    .collection('trips')
                                    .doc(group.tripId!.trim())
                                    .get(),
                                builder: (context, tripSnapshot) {
                                  if (tripSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final tripData = tripSnapshot.data?.data();
                                  if (tripData == null) {
                                    return const Text('No linked trip found.');
                                  }

                                  final title =
                                      (tripData['title'] ?? '').toString().trim();
                                  final tripDate =
                                      (tripData['tripDate'] as Timestamp?)
                                          ?.toDate();

                                  return Card(
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      title: Text(
                                        title.isEmpty ? 'Untitled trip' : title,
                                      ),
                                      subtitle: Text(
                                        tripDate == null
                                            ? 'No date'
                                            : _formatTripDate(tripDate),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                            const SizedBox(height: 24),
                            Text(
                              'Members',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            if (membersSnapshot.connectionState ==
                                    ConnectionState.waiting &&
                                members.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else
                              ...members.map(
                                (member) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    radius: 18,
                                    child: Icon(Icons.person, size: 18),
                                  ),
                                  title: Text(
                                    memberNames[member.userId] ?? 'Member',
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}
