import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/group.dart';
import '../models/group_role.dart';
import '../models/member.dart';
import 'chat_service.dart';
import 'notification_service.dart';

class GroupService {
  GroupService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    ChatService? chatService,
    NotificationService? notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _chatService =
            chatService ?? ChatService(firestore: firestore, auth: auth),
        _notificationService = notificationService ?? NotificationService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final ChatService _chatService;
  final NotificationService _notificationService;

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection('groups');
  CollectionReference<Map<String, dynamic>> get _trips =>
      _firestore.collection('trips');
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  DocumentReference<Map<String, dynamic>> _memberRef(
    String groupId,
    String userId,
  ) {
    return _groups.doc(groupId).collection('members').doc(userId);
  }

  Stream<List<Member>> watchMembers(String groupId) {
    return _groups
        .doc(groupId)
        .collection('members')
        .orderBy('joinedAt')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(Member.fromFirestore).toList(growable: false),
        );
  }

  Stream<Group?> watchGroup(String groupId) {
    return _groups.doc(groupId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return Group.fromFirestore(snapshot);
    });
  }

  Stream<List<Group>> watchUserGroups(String userId) {
    return _groups
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final groups = snapshot.docs
              .map(Group.fromFirestore)
              .toList();
          groups.sort((a, b) {
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
          return groups;
        });
  }

  Future<String> createGroup(
    String tripId,
    String name,
    String description,
    String creatorId,
    String? imageUrl,
  ) async {
    _ensureSignedInUser(creatorId);
    final trimmedTripId = tripId.trim();
    final trimmedName = name.trim();
    final trimmedDescription = description.trim();

    if (trimmedTripId.isEmpty || trimmedName.isEmpty) {
      throw _invalidArgument('Trip ID and group name are required.');
    }

    final groupRef = _groups.doc();
    final creatorMemberRef = _memberRef(groupRef.id, creatorId);
    final tripRef = _trips.doc(trimmedTripId);

    try {
      final tripSnapshot = await tripRef.get();
      if (!tripSnapshot.exists) {
        throw _invalidArgument('Trip not found.');
      }

      final tripData = tripSnapshot.data() ?? const <String, dynamic>{};
      final existingGroupId = (tripData['groupId'] ?? '').toString().trim();
      if (existingGroupId.isNotEmpty) {
        throw _invalidArgument('This trip already has a group chat.');
      }

      final batch = _firestore.batch();
      batch.set(groupRef, <String, dynamic>{
        'tripId': trimmedTripId,
        'name': trimmedName,
        'description': trimmedDescription,
        'members': <String>[creatorId],
        'imageUrl': imageUrl,
        'createdBy': creatorId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(creatorMemberRef, <String, dynamic>{
        'userId': creatorId,
        'role': GroupRole.admin.value,
        'joinedAt': FieldValue.serverTimestamp(),
      });
      batch.update(tripRef, <String, dynamic>{'groupId': groupRef.id});
      await batch.commit();

      await _notificationService.subscribeToGroup(groupRef.id);
      final creatorName = await _resolveUserName(creatorId);
      try {
        await _chatService.sendSystemMessage(
          groupRef.id,
          '$creatorName created the group',
        );
      } on FirebaseException catch (error, stackTrace) {
        _logFirestoreError('sendSystemMessage(createGroup)', error, stackTrace);
      }

      return groupRef.id;
    } on FirebaseException catch (error, stackTrace) {
      _logFirestoreError('createGroup', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      _logFirestoreError('createGroup', error, stackTrace);
      rethrow;
    }
  }

  Future<String> uploadGroupImage({
    required String groupId,
    required String userId,
    required XFile imageFile,
  }) async {
    _ensureSignedInUser(userId);
    final role = await getUserRole(groupId, userId);
    if (role != GroupRole.admin) {
      throw _permissionDenied('Only admins can update the group image.');
    }

    final extension = _fileExtension(imageFile.name);
    final imageRef = _storage.ref().child(
      'groups/$groupId/cover_${DateTime.now().millisecondsSinceEpoch}.$extension',
    );
    final bytes = await imageFile.readAsBytes();
    final metadata = SettableMetadata(contentType: _contentTypeFor(extension));
    await imageRef.putData(bytes, metadata);
    final downloadUrl = await imageRef.getDownloadURL();
    await _groups.doc(groupId).update(<String, dynamic>{'imageUrl': downloadUrl});
    return downloadUrl;
  }

  Future<void> joinGroup(String groupId, String userId) async {
    _ensureSignedInUser(userId);
    final memberRef = _memberRef(groupId, userId);
    final memberSnapshot = await memberRef.get();
    if (memberSnapshot.exists) {
      await _notificationService.subscribeToGroup(groupId);
      return;
    }

    await memberRef.set(<String, dynamic>{
      'userId': userId,
      'role': GroupRole.member.value,
      'joinedAt': FieldValue.serverTimestamp(),
    });
    await _groups.doc(groupId).update(<String, dynamic>{
      'members': FieldValue.arrayUnion(<String>[userId]),
    });

    await _notificationService.subscribeToGroup(groupId);
    final memberName = await _resolveUserName(userId);
    await _chatService.sendSystemMessage(groupId, '$memberName joined the group');
  }

  Future<void> removeMember(
    String groupId,
    String adminId,
    String targetUserId,
  ) async {
    _ensureSignedInUser(adminId);
    if (adminId == targetUserId) {
      throw _invalidArgument('Admins cannot remove themselves.');
    }

    final adminRole = await getUserRole(groupId, adminId);
    if (adminRole != GroupRole.admin) {
      throw _permissionDenied('Only admins can remove members.');
    }

    final targetRef = _memberRef(groupId, targetUserId);
    final targetSnapshot = await targetRef.get();
    if (!targetSnapshot.exists) {
      return;
    }

    await targetRef.delete();
    await _groups.doc(groupId).update(<String, dynamic>{
      'members': FieldValue.arrayRemove(<String>[targetUserId]),
    });
    final targetName = await _resolveUserName(targetUserId);
    await _chatService.sendSystemMessage(
      groupId,
      '$targetName was removed from the group',
    );
  }

  Future<GroupRole?> getUserRole(String groupId, String userId) async {
    final snapshot = await _memberRef(groupId, userId).get();
    if (!snapshot.exists) {
      return null;
    }
    return Member.fromFirestore(snapshot).role;
  }

  Future<Map<String, String>> resolveUserNames(Iterable<String> userIds) async {
    final distinctIds = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (distinctIds.isEmpty) {
      return const <String, String>{};
    }

    final names = <String, String>{};
    for (var index = 0; index < distinctIds.length; index += 10) {
      final chunk = distinctIds.skip(index).take(10).toList(growable: false);
      final snapshot = await _users
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        names[doc.id] = _displayNameFromData(doc.data());
      }
    }

    for (final userId in distinctIds) {
      names.putIfAbsent(userId, () => 'Someone');
    }
    return names;
  }

  Future<String> _resolveUserName(String userId) async {
    final snapshot = await _users.doc(userId).get();
    if (!snapshot.exists) {
      return 'Someone';
    }
    final data = snapshot.data() ?? const <String, dynamic>{};
    return _displayNameFromData(data);
  }

  String _displayNameFromData(Map<String, dynamic> data) {
    final candidates = <String>[
      (data['displayName'] ?? '').toString(),
      (data['name'] ?? '').toString(),
      (data['username'] ?? '').toString(),
      (data['email'] ?? '').toString(),
    ];
    for (final candidate in candidates) {
      final trimmed = candidate.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return 'Someone';
  }

  String _fileExtension(String fileName) {
    final segments = fileName.split('.');
    if (segments.length < 2) {
      return 'jpg';
    }
    return segments.last.toLowerCase();
  }

  String _contentTypeFor(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  void _ensureSignedInUser(String userId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != userId) {
      throw _permissionDenied('Authentication is required.');
    }
  }

  FirebaseException _permissionDenied(String message) {
    return FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: message,
    );
  }

  FirebaseException _invalidArgument(String message) {
    return FirebaseException(
      plugin: 'cloud_firestore',
      code: 'invalid-argument',
      message: message,
    );
  }

  void _logFirestoreError(String action, Object error, [StackTrace? stackTrace]) {
    debugPrint('GroupService.$action error: $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
