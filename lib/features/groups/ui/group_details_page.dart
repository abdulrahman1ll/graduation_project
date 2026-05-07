import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../models/group.dart';
import '../services/group_service.dart';
import '../helpers/group_checklist_flow.dart';
import '../../../core/models/app_language.dart';
import '../../trips/ui/add_trip_page.dart';
import '../../trips/models/trip_member.dart';
import '../../trips/services/trip_service.dart';
import '../../../core/utils/firestore_utils.dart';
import '../../../core/utils/localization.dart';

const Color _detailsBackground = Color(0xFFFFF8EF);
const Color _detailsCard = Color(0xFFFFFBF5);
const Color _detailsCardBorder = Color(0xFFF0DEC8);
const Color _detailsSoftOrange = Color(0xFFFFE8C2);
const Color _detailsOrange = Color(0xFFFF8A00);
const Color _detailsBrown = Color(0xFF6B4F35);
const Color _detailsDarkText = Color(0xFF2F2419);
const Color _detailsMutedText = Color(0xFF8A735C);
const double _detailsRadius = 16;

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
                  .where('memberIds', arrayContains: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  logFirestoreReadError('trips', snapshot.error);
                  return const Center(child: Text('Failed to load trips.'));
                }

                final docs = (snapshot.data?.docs ?? []).where((doc) {
                  final linkedGroupId =
                      (doc.data()['groupId'] ?? '').toString().trim();
                  return linkedGroupId.isEmpty || linkedGroupId == group.id;
                }).toList();
                docs.sort((a, b) {
                  final aDate = a.data()['tripDate'];
                  final bDate = b.data()['tripDate'];
                  if (aDate is Timestamp && bDate is Timestamp) {
                    return aDate.compareTo(bDate);
                  }
                  return 0;
                });

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
                        tripDate == null
                            ? 'No date'
                            : _formatTripDate(tripDate),
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
                              const SnackBar(
                                  content: Text('Trip linked to group')),
                            );
                          }
                        } on FirebaseException catch (e) {
                          debugPrint(
                            'GroupDetailsPage.linkChecklistToGroup failed: '
                            '${e.code} ${e.message}',
                          );
                          if (context.mounted) {
                            showFirestoreError(context, e);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Failed to link trip: $e')),
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

  Future<void> _showInviteMembersSheet(BuildContext context) async {
    final inviteLink = 'app://join?groupId=$groupId';

    Future<void> copyValue({
      required String value,
      required String message,
    }) async {
      await Clipboard.setData(ClipboardData(text: value));
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _detailsBackground,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite Members',
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Share this invitation code with your friends so they can join the group.',
                  style: TextStyle(color: _detailsBrown, height: 1.35),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Invitation Code',
                  style: TextStyle(
                    color: _detailsDarkText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _detailsCardBorder),
                  ),
                  child: SelectableText(
                    groupId,
                    style: const TextStyle(
                      color: _detailsDarkText,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _detailsBrown,
                          side: const BorderSide(color: _detailsCardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        onPressed: () => copyValue(
                          value: groupId,
                          message: 'Invitation code copied',
                        ),
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy Code'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _detailsOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        onPressed: () => copyValue(
                          value: inviteLink,
                          message: 'Invitation link copied',
                        ),
                        icon: const Icon(Icons.link),
                        label: const Text('Copy Link'),
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
  }

  @override
  Widget build(BuildContext context) {
    final resolvedGroupService = groupService ?? GroupService();
    final tripService = TripService();

    return StreamBuilder<Group?>(
      stream: resolvedGroupService.watchGroup(groupId),
      builder: (context, groupSnapshot) {
        if (groupSnapshot.hasError) {
          final error = groupSnapshot.error;
          if (error is FirebaseException) {
            debugPrint(
              'GroupDetailsPage.loadGroup failed: '
              '${error.code} ${error.message}',
            );
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Group Details')),
            body: const Center(child: Text('Unable to load group.')),
          );
        }
        final group = groupSnapshot.data;
        final tripId = group?.tripId?.trim() ?? '';

        return Scaffold(
          backgroundColor: _detailsBackground,
          appBar: AppBar(
            title: const Text('Group Details'),
            backgroundColor: _detailsBackground,
            foregroundColor: _detailsDarkText,
            elevation: 0,
          ),
          body: group == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<List<TripMember>>(
                  stream: tripId.isEmpty
                      ? Stream<List<TripMember>>.value(const <TripMember>[])
                      : tripService.watchTripMembers(tripId),
                  builder: (context, membersSnapshot) {
                    final members =
                        membersSnapshot.data ?? const <TripMember>[];
                    final memberIds = (group.members.isNotEmpty
                            ? group.members
                            : members.map((member) => member.userId))
                        .where((id) => id.trim().isNotEmpty)
                        .toSet()
                        .toList(growable: false);

                    return FutureBuilder<Map<String, String>>(
                      future: resolvedGroupService.resolveUserNames(memberIds),
                      builder: (context, namesSnapshot) {
                        final memberNames =
                            namesSnapshot.data ?? const <String, String>{};

                        final memberCount = group.members.isNotEmpty
                            ? group.members.length
                            : memberIds.length;
                        final hasUpcomingTrip = tripId.isNotEmpty;
                        final subtitleParts = <String>[
                          '$memberCount member${memberCount == 1 ? '' : 's'}',
                          if (hasUpcomingTrip) '1 upcoming trip',
                        ];

                        return ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          children: [
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: _detailsSoftOrange,
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 46,
                                  backgroundColor: _detailsSoftOrange,
                                  backgroundImage: group.imageUrl == null
                                      ? null
                                      : NetworkImage(group.imageUrl!),
                                  child: group.imageUrl == null
                                      ? const Icon(
                                          Icons.groups_rounded,
                                          size: 38,
                                          color: _detailsOrange,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              group.name.trim().isEmpty
                                  ? 'Group Chat'
                                  : group.name,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: _detailsDarkText,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitleParts.join(' - '),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _detailsMutedText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              group.description.trim().isEmpty
                                  ? 'No description yet.'
                                  : group.description,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: _detailsBrown,
                                    height: 1.35,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            Card(
                              elevation: 0,
                              color: _detailsCard,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(_detailsRadius),
                                side: const BorderSide(
                                  color: _detailsCardBorder,
                                ),
                              ),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: _detailsSoftOrange,
                                  child: Icon(
                                    Icons.group_add_outlined,
                                    color: _detailsOrange,
                                  ),
                                ),
                                title: const Text(
                                  'Invite Members',
                                  style: TextStyle(
                                    color: _detailsDarkText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Share an invitation code with friends',
                                  style: TextStyle(color: _detailsMutedText),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: _detailsBrown,
                                ),
                                onTap: () => _showInviteMembersSheet(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _detailsOrange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                    ),
                                    onPressed: () => openGroupChecklistFlow(
                                      context: context,
                                      group: group,
                                      groupId: groupId,
                                      groupService: resolvedGroupService,
                                    ),
                                    icon: const Icon(Icons.checklist),
                                    label: Text(
                                      (group.tripId?.trim().isEmpty ?? true)
                                          ? 'Link checklist'
                                          : 'Open checklist',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _detailsBrown,
                                      side: const BorderSide(
                                        color: _detailsCardBorder,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                    ),
                                    onPressed: () => _showPlanTripOptions(
                                      context,
                                      group,
                                      resolvedGroupService,
                                    ),
                                    icon: const Icon(
                                      Icons.calendar_month,
                                      color: _detailsOrange,
                                    ),
                                    label: const Text('Plan trip'),
                                  ),
                                ),
                              ],
                            ),
                            if (tripId.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              const Text(
                                'Upcoming Trip',
                                style: TextStyle(
                                  color: _detailsDarkText,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              FutureBuilder<
                                  DocumentSnapshot<Map<String, dynamic>>>(
                                future: FirebaseFirestore.instance
                                    .collection('trips')
                                    .doc(tripId)
                                    .get(),
                                builder: (context, tripSnapshot) {
                                  if (tripSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  if (tripSnapshot.hasError) {
                                    final error = tripSnapshot.error;
                                    if (error is FirebaseException) {
                                      debugPrint(
                                        'GroupDetailsPage.loadLinkedTrip failed: '
                                        '${error.code} ${error.message}',
                                      );
                                    }
                                    return const Text('No linked trip found.');
                                  }

                                  final tripData = tripSnapshot.data?.data();
                                  if (tripData == null) {
                                    return const Text('No linked trip found.');
                                  }

                                  final title = (tripData['title'] ?? '')
                                      .toString()
                                      .trim();
                                  final tripDate =
                                      (tripData['tripDate'] as Timestamp?)
                                          ?.toDate();

                                  return Card(
                                    elevation: 0,
                                    color: _detailsCard,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        _detailsRadius,
                                      ),
                                      side: const BorderSide(
                                        color: _detailsCardBorder,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title.isEmpty
                                                ? 'Untitled trip'
                                                : title,
                                            style: const TextStyle(
                                              color: _detailsDarkText,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _detailsSoftOrange,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.event_outlined,
                                                  size: 16,
                                                  color: _detailsOrange,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  tripDate == null
                                                      ? 'No date'
                                                      : _formatTripDate(
                                                          tripDate,
                                                        ),
                                                  style: const TextStyle(
                                                    color: _detailsBrown,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                            const SizedBox(height: 24),
                            const Text(
                              'Members',
                              style: TextStyle(
                                color: _detailsDarkText,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
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
                              ...memberIds.map(
                                (memberId) => Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _detailsCard,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _detailsCardBorder,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 18,
                                        backgroundColor: _detailsSoftOrange,
                                        child: Icon(
                                          Icons.person,
                                          size: 18,
                                          color: _detailsOrange,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          memberNames[memberId] ?? 'Member',
                                          style: const TextStyle(
                                            color: _detailsDarkText,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
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
