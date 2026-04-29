import 'package:cloud_firestore/cloud_firestore.dart';

class ChecklistAssignmentService {
  ChecklistAssignmentService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<String?> toggleAssignment({
    required String tripId,
    required String itemId,
    required String currentUserId,
    required String? assignedTo,
  }) async {
    final normalizedAssignedTo = _normalizeUserId(assignedTo);
    final nextAssignedTo =
        normalizedAssignedTo == currentUserId ? null : currentUserId;

    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('checklist')
        .doc(itemId)
        .update(<String, dynamic>{'assignedTo': nextAssignedTo});

    return nextAssignedTo;
  }

  static String? _normalizeUserId(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
