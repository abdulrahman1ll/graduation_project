import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/app_language.dart';
import '../../../core/utils/localization.dart';
import '../models/group.dart';
import '../services/group_service.dart';
import '../../trips/trips.dart';
import '../ui/link_group_checklist_page.dart';

Future<void> openGroupChecklistFlow({
  required BuildContext context,
  required Group group,
  required String groupId,
  required GroupService groupService,
}) async {
  final tripId = group.tripId?.trim();
  if (tripId == null || tripId.isEmpty) {
    final linked = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => LinkGroupChecklistPage(
          groupId: groupId,
          groupService: groupService,
        ),
      ),
    );
    if (linked == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checklist linked')),
      );
    }
    return;
  }

  try {
    final tripSnapshot = await FirebaseFirestore.instance
        .collection('trips')
        .doc(tripId)
        .get();
    if (!tripSnapshot.exists) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No linked trip found.')),
        );
      }
      return;
    }
  } on FirebaseException catch (error) {
    debugPrint(
      'group_checklist_flow.open_checklist failed: '
      '${error.code} ${error.message}',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No linked trip found.')),
      );
    }
    return;
  }

  if (!context.mounted) {
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TripChecklistPage(
        tr: Tr(AppLanguage.en),
        tripId: tripId,
        tripTitle: group.name.trim().isEmpty ? 'Group Trip' : group.name,
      ),
    ),
  );
}
