import 'package:cloud_firestore/cloud_firestore.dart';

class ChecklistAssignmentService {
  ChecklistAssignmentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<String?> assignToCurrentUser({
    required String tripId,
    required String itemId,
    required String currentUserId,
    required String? assignedTo,
  }) async {
    final normalizedAssignedTo = _normalizeUserId(assignedTo);
    if (normalizedAssignedTo != null) {
      return normalizedAssignedTo;
    }

    final normalizedCurrentUserId = _normalizeUserId(currentUserId);
    if (normalizedCurrentUserId == null) {
      return null;
    }

    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('checklist')
        .doc(itemId)
        .update(<String, dynamic>{'assignedTo': normalizedCurrentUserId});

    return normalizedCurrentUserId;
  }

  Future<void> releaseFromCurrentUser({
    required String tripId,
    required String itemId,
    required String currentUserId,
    required String? assignedTo,
    required bool done,
  }) async {
    final normalizedAssignedTo = _normalizeUserId(assignedTo);
    final normalizedCurrentUserId = _normalizeUserId(currentUserId);
    if (normalizedCurrentUserId == null ||
        normalizedAssignedTo != normalizedCurrentUserId ||
        done) {
      return;
    }

    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('checklist')
        .doc(itemId)
        .update(<String, dynamic>{
      'assignedTo': null,
      'assignedToName': FieldValue.delete(),
      'assignedName': FieldValue.delete(),
      'done': false,
      'isDone': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static String? _normalizeUserId(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
