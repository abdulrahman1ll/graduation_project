import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../features/trips/helpers/checklist_utils.dart';

Future<void> seedChecklistTemplates() async {
  if (kDebugMode) {
    debugPrint('START SEED');
  }

  final firestore = FirebaseFirestore.instance;
  final templates = firestore.collection('checklist_templates');

  try {
    final existingGroups = await templates.get();
    for (final groupDoc in existingGroups.docs) {
      final itemsSnapshot = await groupDoc.reference.collection('items').get();
      for (final itemDoc in itemsSnapshot.docs) {
        await itemDoc.reference.delete();
      }
      await groupDoc.reference.delete();
    }

    for (final group in checklistTemplateGroups) {
      final groupRef = templates.doc(group.id);
      await groupRef.set({
        'id': group.id,
        'name_ar': group.nameAr,
        'name_en': group.nameEn,
        'order': group.order,
      });
      for (final item in group.items) {
        final itemRef = groupRef.collection('items').doc(item.id);
        await itemRef.set({
          'id': item.id,
          'name_ar': item.nameAr,
          'name_en': item.nameEn,
          'order': item.order,
        });
      }
    }

    if (kDebugMode) {
      debugPrint('SEED COMPLETED');
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('SEED FATAL ERROR: $e');
      debugPrintStack(stackTrace: st);
    }
  }
}

Future<void> syncChecklistTemplates() async {
  await seedChecklistTemplates();
}
