import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_message_type.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.type,
    required this.content,
    required this.createdAt,
    required this.isPinned,
    required this.readBy,
  });

  final String id;
  final String groupId;
  final String senderId;
  final ChatMessageType type;
  final String content;
  final DateTime? createdAt;
  final bool isPinned;
  final List<String> readBy;

  bool hasRead(String userId) => readBy.contains(userId);

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return ChatMessage(
      id: snapshot.id,
      groupId: snapshot.reference.parent.parent?.id ?? '',
      senderId: (data['senderId'] ?? '').toString(),
      type: ChatMessageType.fromValue((data['type'] ?? 'text').toString()),
      content: (data['content'] ?? '').toString(),
      createdAt: _readDateTime(data['createdAt']),
      isPinned: data['isPinned'] == true,
      readBy: ((data['readBy'] as List<dynamic>?) ?? const <dynamic>[])
          .map((value) => value.toString())
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'senderId': senderId,
      'type': type.value,
      'content': content,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'isPinned': isPinned,
      'readBy': readBy,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? groupId,
    String? senderId,
    ChatMessageType? type,
    String? content,
    DateTime? createdAt,
    bool? isPinned,
    List<String>? readBy,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
      readBy: readBy ?? this.readBy,
    );
  }

  static DateTime? _readDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }
}
