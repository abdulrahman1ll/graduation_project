import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'localization.dart';

IconData iconFromName(String? iconName) {
  switch (iconName) {
    case 'tent':
      return Icons.terrain;
    case 'restaurant':
      return Icons.restaurant;
    case 'chair':
      return Icons.chair_alt;
    case 'water_drop':
      return Icons.water_drop;
    case 'flashlight_on':
      return Icons.flashlight_on;
    case 'checklist':
      return Icons.checklist;
    default:
      return Icons.checklist;
  }
}

Map<String, int> categoryTemplateCounts(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> templates,
  Tr tr,
) {
  final counts = <String, int>{};
  for (final doc in templates) {
    final data = doc.data();
    final category = (data['category'] ?? tr.t('other')).toString();
    counts[category] = (counts[category] ?? 0) + 1;
  }
  return counts;
}

List<QueryDocumentSnapshot<Map<String, dynamic>>> sortChecklistByCompletion(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> items,
) {
  final sorted = [...items];
  sorted.sort((a, b) {
    final aDone = a.data()['done'] == true;
    final bDone = b.data()['done'] == true;
    if (aDone == bDone) {
      return 0;
    }
    return aDone ? 1 : -1;
  });
  return sorted;
}

double checklistProgressValue({
  required int doneCount,
  required int totalCount,
}) {
  if (totalCount == 0) {
    return 0;
  }
  return doneCount / totalCount;
}
