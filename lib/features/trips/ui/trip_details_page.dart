import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/kashta_colors.dart';
import '../../../core/utils/firestore_utils.dart';
import '../../../core/utils/localization.dart';
import '../../groups/services/group_service.dart';
import '../models/trip_member.dart';
import '../services/trip_service.dart';

class TripDetailsPage extends StatelessWidget {
  const TripDetailsPage({
    super.key,
    required this.tr,
    required this.tripId,
    this.tripService,
    this.groupService,
  });

  final Tr tr;
  final String tripId;
  final TripService? tripService;
  final GroupService? groupService;

  @override
  Widget build(BuildContext context) {
    final resolvedTripService = tripService ?? TripService();
    final resolvedGroupService = groupService ?? GroupService();

    return Scaffold(
      appBar: AppBar(title: Text(tr.t('trip_details'))),
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
            return Center(child: Text(tr.t('failed_load_trip')));
          }

          final tripData = tripSnapshot.data?.data();
          if (tripData == null) {
            return Center(child: Text(tr.t('trip_not_found')));
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
                        title.isEmpty ? tr.t('untitled_trip') : title,
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
                                ? tr.t('no_date')
                                : _formatTripDateTime(tripDate, tr),
                          ),
                          _TripDetailChip(
                            icon: Icons.group_outlined,
                            text: '${members.length} ${tr.t('members')}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _TripAttendanceSection(
                        tr: tr,
                        tripId: tripId,
                        tripService: resolvedTripService,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        tr.t('trip_members'),
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
                        Text(tr.t('no_members_yet'))
                      else
                        ...members.map(
                          (member) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              radius: 18,
                              child: Icon(Icons.person, size: 18),
                            ),
                            title: Text(
                              memberNames[member.userId] ?? tr.t('member'),
                            ),
                            subtitle: Text(_statusLabel(member.status, tr)),
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
    required this.tr,
    required this.tripId,
    required this.tripService,
  });

  final Tr tr;
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
        SnackBar(content: Text(widget.tr.t('please_sign_in_first'))),
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
        showFirestoreError(context, e, tr: widget.tr);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _optimisticStatus = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.tr.t('unable_update_attendance'))),
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
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(widget.tr.t('sign_in_confirm_attendance')),
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
                  widget.tr.t('will_you_attend'),
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
                            ? KashtaColors.softOlive
                            : KashtaColors.softOrange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          status == 'going'
                              ? widget.tr.t('you_are_going')
                              : widget.tr.t('you_are_not_going'),
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
                          child: Text(widget.tr.t('change')),
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
                          label: Text(widget.tr.t('im_going')),
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
                          label: Text(widget.tr.t('not_going')),
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
        Icon(icon, size: 18, color: KashtaColors.primary),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

String _formatTripDateTime(DateTime value, Tr tr) {
  final months = <String>[
    tr.t('jan'),
    tr.t('feb'),
    tr.t('mar'),
    tr.t('apr'),
    tr.t('may'),
    tr.t('jun'),
    tr.t('jul'),
    tr.t('aug'),
    tr.t('sep'),
    tr.t('oct'),
    tr.t('nov'),
    tr.t('dec'),
  ];
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour < 12 ? tr.t('am') : tr.t('pm');
  return '${value.day} ${months[value.month - 1]} - $hour:$minute $period';
}

String _statusLabel(String status, Tr tr) {
  switch (status) {
    case 'going':
      return tr.t('going');
    case 'not_going':
      return tr.t('not_going');
    default:
      return tr.t('pending');
  }
}
