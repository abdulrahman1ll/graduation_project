import 'package:flutter/material.dart';

import '../../models/app_language.dart';
import '../../screens/app_shell.dart';
import '../../utils/localization.dart';
import '../models/group.dart';
import '../services/group_service.dart';
import 'link_group_checklist_page.dart';

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
