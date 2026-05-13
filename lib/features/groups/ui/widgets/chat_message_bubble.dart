import 'package:flutter/material.dart';

import '../../../../core/utils/localization.dart';
import '../../models/chat_message.dart';
import '../../models/chat_types.dart';

String localizedSystemMessageContent(Tr tr, String content) {
  const createdSuffix = ' created the group';
  const joinedSuffix = ' joined the group';
  final trimmedRight = content.trimRight();

  if (trimmedRight.endsWith(createdSuffix)) {
    final username =
        trimmedRight.substring(0, trimmedRight.length - createdSuffix.length);
    if (username.trim().isEmpty) {
      return content;
    }
    return tr.t('systemCreatedGroup').replaceAll('{username}', username);
  }
  if (trimmedRight.endsWith(joinedSuffix)) {
    final username =
        trimmedRight.substring(0, trimmedRight.length - joinedSuffix.length);
    if (username.trim().isEmpty) {
      return content;
    }
    return tr.t('systemJoinedGroup').replaceAll('{username}', username);
  }
  if (content.trim() == 'Checklist linked to this group') {
    return tr.t('systemChecklistLinked');
  }

  return content;
}

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.senderName,
    required this.tr,
    required this.currentUserId,
    required this.isSeenByCurrentUser,
    required this.canPin,
    required this.onTogglePin,
  });

  final ChatMessage message;
  final String senderName;
  final Tr tr;
  final String? currentUserId;
  final bool isSeenByCurrentUser;
  final bool canPin;
  final VoidCallback onTogglePin;

  bool get _isMine =>
      currentUserId != null && currentUserId == message.senderId;

  @override
  Widget build(BuildContext context) {
    if (message.type == ChatMessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              localizedSystemMessageContent(tr, message.content),
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final backgroundColor =
        _isMine ? const Color(0xFFFEE8C7) : const Color(0xFFEEFAEE);
    final alignment =
        _isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(_isMine ? 18 : 4),
      bottomRight: Radius.circular(_isMine ? 4 : 18),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onLongPress: canPin
            ? () async {
                final selected = await showModalBottomSheet<String>(
                  context: context,
                  builder: (menuContext) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(
                              message.isPinned
                                  ? Icons.push_pin_outlined
                                  : Icons.push_pin,
                            ),
                            title: Text(
                              message.isPinned ? tr.t('unpin') : tr.t('pin'),
                            ),
                            onTap: () =>
                                Navigator.of(menuContext).pop('toggle_pin'),
                          ),
                        ],
                      ),
                    );
                  },
                );
                if (selected == 'toggle_pin') {
                  onTogglePin();
                }
              }
            : null,
        child: Column(
          crossAxisAlignment: alignment,
          children: [
            Stack(
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: radius,
                    border: message.isPinned
                        ? Border.all(color: Colors.orange, width: 1.2)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isMine ? tr.t('you') : senderName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        message.content,
                        style: TextStyle(
                          fontSize: 15,
                          color: message.type == ChatMessageType.link
                              ? Colors.blue.shade700
                              : null,
                          decoration: message.type == ChatMessageType.link
                              ? TextDecoration.underline
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isSeenByCurrentUser ? tr.t('seen') : tr.t('sent'),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (message.isPinned)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Text(
                      '📌',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) {
      return tr.t('sending');
    }
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
