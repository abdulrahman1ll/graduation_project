import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../models/chat_types.dart';

class ChatService {
  ChatService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection('groups');

  CollectionReference<Map<String, dynamic>> _messagesRef(String groupId) {
    return _groups.doc(groupId).collection('messages');
  }

  DocumentReference<Map<String, dynamic>> _memberRef(
    String groupId,
    String userId,
  ) {
    return _groups.doc(groupId).collection('members').doc(userId);
  }

  Stream<List<ChatMessage>> watchMessages(
    String groupId, {
    bool descending = false,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _messagesRef(groupId).orderBy(
      'createdAt',
      descending: descending,
    );
    if (limit != null) {
      query = query.limit(limit);
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map(ChatMessage.fromFirestore)
          .toList(growable: false),
    );
  }

  Stream<List<ChatMessage>> watchPinnedMessages(
    String groupId, {
    int limit = 10,
  }) {
    return _messagesRef(groupId)
        .where('isPinned', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ChatMessage.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> sendMessage(
    String groupId,
    String senderId,
    String type,
    String content,
  ) async {
    try {
      _ensureSignedInUser(senderId);
      final trimmedContent = content.trim();
      if (trimmedContent.isEmpty) {
        throw _invalidArgument('Message content cannot be empty.');
      }

      final membershipSnapshot = await _memberRef(groupId, senderId).get(
        const GetOptions(source: Source.server),
      );
      if (!membershipSnapshot.exists) {
        throw _permissionDenied('You are not part of this group.');
      }

      final messageType = ChatMessageType.fromValue(type);

      await _messagesRef(groupId).add(<String, dynamic>{
        'senderId': senderId,
        'type': messageType.value,
        'content': trimmedContent,
        'createdAt': FieldValue.serverTimestamp(),
        'isPinned': false,
        'readBy': <String>[senderId],
      });
    } on FirebaseException catch (error, stackTrace) {
      _logFirestoreError('sendMessage', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      _logFirestoreError('sendMessage', error, stackTrace);
      rethrow;
    }
  }

  Future<void> sendSystemMessage(String groupId, String content) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw _permissionDenied('Authentication is required.');
    }
    await sendMessage(
      groupId,
      currentUser.uid,
      ChatMessageType.system.value,
      content,
    );
  }

  Future<void> pinMessage(
    String groupId,
    String messageId,
    String adminId,
  ) async {
    _ensureSignedInUser(adminId);
    await _assertAdmin(groupId, adminId);
    await _messagesRef(groupId).doc(messageId).update(<String, dynamic>{
      'isPinned': true,
    });
  }

  Future<void> unpinMessage(
    String groupId,
    String messageId,
    String adminId,
  ) async {
    _ensureSignedInUser(adminId);
    await _assertAdmin(groupId, adminId);
    await _messagesRef(groupId).doc(messageId).update(<String, dynamic>{
      'isPinned': false,
    });
  }

  Future<void> markMessagesAsRead(String groupId, String userId) async {
    _ensureSignedInUser(userId);
    await _assertMember(groupId, userId);

    const pageSize = 200;
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;

    while (true) {
      Query<Map<String, dynamic>> query = _messagesRef(groupId)
          .orderBy('createdAt', descending: true)
          .limit(pageSize);
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        break;
      }

      final batch = _firestore.batch();
      var changed = false;
      for (final doc in snapshot.docs) {
        final readBy = ((doc.data()['readBy'] as List<dynamic>?) ??
                const <dynamic>[])
            .map((value) => value.toString())
            .toSet();
        if (readBy.contains(userId)) {
          continue;
        }
        batch.update(doc.reference, <String, dynamic>{
          'readBy': FieldValue.arrayUnion(<String>[userId]),
        });
        changed = true;
      }

      if (changed) {
        await batch.commit();
      }

      if (snapshot.docs.length < pageSize) {
        break;
      }
      lastDocument = snapshot.docs.last;
    }
  }

  Future<void> sendChecklistItemAddedMessage({
    required String groupId,
    required String actorName,
    required String itemName,
  }) {
    return sendSystemMessage(groupId, '$actorName added $itemName');
  }

  Future<void> sendChecklistItemCompletedMessage({
    required String groupId,
    required String actorName,
    required String itemName,
  }) {
    return sendSystemMessage(groupId, '$actorName completed $itemName');
  }

  Future<GroupRole?> getUserRole(String groupId, String userId) async {
    final snapshot = await _memberRef(groupId, userId).get();
    if (!snapshot.exists) {
      return null;
    }
    final data = snapshot.data() ?? const <String, dynamic>{};
    return GroupRole.fromValue((data['role'] ?? 'member').toString());
  }

  Future<void> _assertMember(String groupId, String userId) async {
    final role = await getUserRole(groupId, userId);
    if (role == null) {
      throw _permissionDenied('You must be a group member to send messages.');
    }
  }

  Future<void> _assertAdmin(String groupId, String userId) async {
    final role = await getUserRole(groupId, userId);
    if (role != GroupRole.admin) {
      throw _permissionDenied('Only admins can perform this action.');
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
    debugPrint('ChatService.$action error: $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
