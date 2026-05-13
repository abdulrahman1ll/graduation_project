import 'package:cloud_firestore/cloud_firestore.dart';

class ChecklistResolvedUser {
  const ChecklistResolvedUser({
    required this.uid,
    required this.username,
    required this.fullName,
  });

  final String uid;
  final String? username;
  final String? fullName;

  String get displayName {
    final normalizedUsername = _normalize(username);
    if (normalizedUsername != null) {
      return normalizedUsername;
    }

    final normalizedFullName = _normalize(fullName);
    if (normalizedFullName != null) {
      return normalizedFullName;
    }

    return 'Member';
  }

  static String? _normalize(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}

class ChecklistAssignmentLabel {
  const ChecklistAssignmentLabel({
    required this.text,
    required this.isFallback,
  });

  final String text;
  final bool isFallback;
}

class ChecklistUserResolver {
  ChecklistUserResolver({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final Map<String, ChecklistResolvedUser> _userCache =
      <String, ChecklistResolvedUser>{};
  final Map<String, Future<ChecklistResolvedUser>> _pendingRequests =
      <String, Future<ChecklistResolvedUser>>{};

  Future<String> resolveAssignmentLabel({
    required String? assignedTo,
    required String currentUserId,
  }) async {
    final label = await resolveAssignmentLabelInfo(
      assignedTo: assignedTo,
      currentUserId: currentUserId,
    );
    return label.text;
  }

  Future<ChecklistAssignmentLabel> resolveAssignmentLabelInfo({
    required String? assignedTo,
    required String currentUserId,
  }) async {
    final normalizedAssignedTo = _normalizeUserId(assignedTo);
    if (normalizedAssignedTo == null) {
      return const ChecklistAssignmentLabel(text: '', isFallback: true);
    }
    if (normalizedAssignedTo == currentUserId) {
      return const ChecklistAssignmentLabel(text: 'You', isFallback: true);
    }

    final user = await _resolveUser(normalizedAssignedTo);
    final hasStoredName =
        ChecklistResolvedUser._normalize(user.username) != null ||
            ChecklistResolvedUser._normalize(user.fullName) != null;
    return ChecklistAssignmentLabel(
      text: user.displayName,
      isFallback: !hasStoredName,
    );
  }

  Future<ChecklistResolvedUser> _resolveUser(String uid) {
    final cachedUser = _userCache[uid];
    if (cachedUser != null) {
      return Future<ChecklistResolvedUser>.value(cachedUser);
    }

    final pendingRequest = _pendingRequests[uid];
    if (pendingRequest != null) {
      return pendingRequest;
    }

    final request = _firestore.collection('users').doc(uid).get().then((doc) {
      final data = doc.data() ?? const <String, dynamic>{};
      final resolvedUser = ChecklistResolvedUser(
        uid: uid,
        username: (data['username'] ?? '').toString(),
        fullName: (data['fullName'] ?? '').toString(),
      );
      _userCache[uid] = resolvedUser;
      _pendingRequests.remove(uid);
      return resolvedUser;
    }, onError: (Object error, StackTrace stackTrace) {
      _pendingRequests.remove(uid);
      throw error;
    });

    _pendingRequests[uid] = request;
    return request;
  }

  String? _normalizeUserId(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
