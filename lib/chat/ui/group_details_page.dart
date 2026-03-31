import 'package:flutter/material.dart';

import '../models/group.dart';
import '../models/member.dart';
import '../services/group_service.dart';
import 'group_checklist_flow.dart';

class GroupDetailsPage extends StatelessWidget {
  const GroupDetailsPage({
    super.key,
    required this.groupId,
    this.groupService,
  });

  final String groupId;
  final GroupService? groupService;

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
