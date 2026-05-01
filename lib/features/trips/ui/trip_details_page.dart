import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/firestore_utils.dart';
import '../../groups/services/group_service.dart';
import '../models/trip_member.dart';
import '../services/trip_service.dart';

class TripDetailsPage extends StatelessWidget {
  const TripDetailsPage({
    super.key,
    required this.tripId,
    this.tripService,
    this.groupService,
  });

  final String tripId;
  final TripService? tripService;
  final GroupService? groupService;

  @override
  Widget build(BuildContext context) {
    final resolvedTripService = tripService ?? TripService();
    final resolvedGroupService = groupService ?? GroupService();

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Details')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .doc(tripId)
            .snapshots(),
        builder: (context, tripSnapshot) {
          if (tripSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (tripSnapshot.hasError) {
            logFirestoreReadError('trips/$tripId', tripSnapshot.error);
            return const Center(child: Text('Failed to load trip.'));
          }

          final tripData = tripSnapshot.data?.data();
          if (tripData == null) {
            return const Center(child: Text('Trip not found.'));
          }

          final title = (tripData['title'] ?? '').toString().trim();
          final description = (tripData['description'] ?? '').toString().trim();
          final tripDate = (tripData['tripDate'] as Timestamp?)?.toDate();

          return StreamBuilder<List<TripMember>>(
            stream: resolvedTripService.watchTripMembers(tripId),
            builder: (context, membersSnapshot) {
              final members = membersSnapshot.data ?? const <TripMember>[];
              final memberIds = members
                  .map((member) => member.userId)
                  .where((id) => id.trim().isNotEmpty)
                  .toList(growable: false);

              return FutureBuilder<Map<String, String>>(
                future: resolvedGroupService.resolveUserNames(memberIds),
                builder: (context, namesSnapshot) {
                  final memberNames =
                      namesSnapshot.data ?? const <String, String>{};

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        title.isEmpty ? 'Untitled trip' : title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(description),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 18,
                        runSpacing: 8,
                        children: [
                          _TripDetailChip(
                            icon: Icons.event_outlined,
                            text: tripDate == null
                                ? 'No date'
                                : _formatTripDateTime(tripDate),
                          ),
                          _TripDetailChip(
                            icon: Icons.group_outlined,
                            text: '${members.length} Members',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _TripAttendanceSection(
                        tripId: tripId,
                        tripService: resolvedTripService,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Members',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      if (membersSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          members.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else if (members.isEmpty)
                        const Text('No members yet.')
                      else
                        ...members.map(
                          (member) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              radius: 18,
                              child: Icon(Icons.person, size: 18),
                            ),
                            title: Text(memberNames[member.userId] ?? 'Member'),
                            subtitle: Text(_statusLabel(member.status)),
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

class _TripAttendanceSection extends StatefulWidget {
  const _TripAttendanceSection({
    required this.tripId,
    required this.tripService,
  });

  final String tripId;
  final TripService tripService;

  @override
  State<_TripAttendanceSection> createState() => _TripAttendanceSectionState();
}

class _TripAttendanceSectionState extends State<_TripAttendanceSection> {
  String? _optimisticStatus;
  String? _updatingStatus;

  Future<void> _updateAttendance(String status) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in first.')),
      );
      return;
    }

    setState(() {
      _optimisticStatus = status;
      _updatingStatus = status;
    });

    try {
      await widget.tripService.updateAttendance(widget.tripId, userId, status);
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() => _optimisticStatus = null);
        showFirestoreError(context, e);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _optimisticStatus = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update attendance.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updatingStatus = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Sign in to confirm attendance.'),
        ),
      );
    }

    return StreamBuilder<TripMember?>(
      stream: widget.tripService.watchTripMember(widget.tripId, userId),
      builder: (context, snapshot) {
        final savedStatus = snapshot.data?.status ?? 'pending';
        final status = _optimisticStatus ?? savedStatus;
        final isUpdating = _updatingStatus != null;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Will you attend?',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (status == 'going' || status == 'not_going') ...[
                  Row(
                    children: [
                      Icon(
                        status == 'going' ? Icons.check_circle : Icons.cancel,
                        color: status == 'going'
                            ? const Color(0xFF43A047)
                            : const Color(0xFFE53935),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          status == 'going'
                              ? 'You are going'
                              : 'You are not going',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (isUpdating)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        TextButton(
                          onPressed: () {
                            setState(() => _optimisticStatus = 'pending');
                          },
                          child: const Text('Change'),
                        ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: isUpdating
                              ? null
                              : () => _updateAttendance('going'),
                          icon: _updatingStatus == 'going'
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: const Text("I'm going"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isUpdating
                              ? null
                              : () => _updateAttendance('not_going'),
                          icon: _updatingStatus == 'not_going'
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.close),
                          label: const Text('Not going'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TripDetailChip extends StatelessWidget {
  const _TripDetailChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.orange),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

String _formatTripDateTime(DateTime value) {
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
  return '${value.day} ${months[value.month - 1]} - $hour:$minute $period';
}

String _statusLabel(String status) {
  switch (status) {
    case 'going':
      return 'Going';
    case 'not_going':
      return 'Not going';
    default:
      return 'Pending';
  }
}
