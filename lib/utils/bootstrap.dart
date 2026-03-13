import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

Future<void> seedChecklistTemplatesIfEmpty() async {
  try {
    final templates = FirebaseFirestore.instance.collection(
      'checklist_templates',
    );
    final existing = await templates.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return;
    }

    final defaults = <String, Map<String, String>>{
      'tent': {'name': 'Tent', 'category': 'Camping Gear', 'icon': 'tent'},
      'bbq': {
        'name': 'BBQ Set',
        'category': 'Food & Cooking',
        'icon': 'restaurant',
      },
      'chairs': {'name': 'Chairs', 'category': 'Comfort', 'icon': 'chair'},
      'water': {
        'name': 'Water',
        'category': 'Essentials',
        'icon': 'water_drop',
      },
      'flashlight': {
        'name': 'Flashlight',
        'category': 'Camping Gear',
        'icon': 'flashlight_on',
      },
    };
    final batch = FirebaseFirestore.instance.batch();
    defaults.forEach((docId, data) {
      batch.set(templates.doc(docId), data);
    });
    await batch.commit();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Checklist template seed skipped: $e');
    }
  }
}
