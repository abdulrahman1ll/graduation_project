import 'package:flutter/material.dart';

import '../../../../core/utils/localization.dart';
import '../../models/chat_message.dart';
import '../../models/chat_types.dart';

const Color _chatPrimaryOrange = Color(0xFFD97845);
const Color _chatSandBorder = Color(0xFFEFDFCD);
const Color _chatOtherUserBubble = Color(0xFFEEF3EA);
const Color _chatMyMessageBubble = Color(0xFFFBE1D3);
const Color _chatCardSurface = Color(0xFFFFF9F1);
const Color _chatTextDark = Color(0xFF2E2B28);
const Color _chatTextSecondary = Color(0xFF7A6A5B);

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
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.canPin,
    required this.onTogglePin,
  });

  final ChatMessage message;
  final String senderName;
  final Tr tr;
  final String? currentUserId;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool canPin;
  final VoidCallback onTogglePin;

  bool get _isMine =>
      currentUserId != null && currentUserId == message.senderId;

  @override
  Widget build(BuildContext context) {
    if (message.type == ChatMessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _chatCardSurface,
              border: Border.all(color: _chatSandBorder),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              localizedSystemMessageContent(tr, message.content),
              style: const TextStyle(
                color: _chatTextSecondary,
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
        _isMine ? _chatMyMessageBubble : _chatOtherUserBubble;
    final alignment =
        _isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.only(
      topLeft: Radius.circular(!_isMine && !isFirstInGroup ? 8 : 18),
      topRight: Radius.circular(_isMine && !isFirstInGroup ? 8 : 18),
      bottomLeft: Radius.circular(!_isMine && !isLastInGroup ? 8 : 18),
      bottomRight: Radius.circular(_isMine && !isLastInGroup ? 8 : 18),
    );
    final showSenderName = !_isMine && isFirstInGroup;

    return Padding(
      padding: EdgeInsets.only(
        top: isFirstInGroup ? 9 : 2,
        bottom: isLastInGroup ? 9 : 2,
      ),
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
                        ? Border.all(color: _chatPrimaryOrange, width: 1.1)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showSenderName) ...[
                        Text(
                          senderName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _chatTextDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      SelectableText(
                        message.content,
                        style: TextStyle(
                          fontSize: 15,
                          color: message.type == ChatMessageType.link
                              ? _chatPrimaryOrange
                              : _chatTextDark,
                          decoration: message.type == ChatMessageType.link
                              ? TextDecoration.underline
                              : TextDecoration.none,
                        ),
                      ),
                      if (isLastInGroup) ...[
                        const SizedBox(height: 6),
                        Text(
                          _footerText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _chatTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (message.isPinned)
                  const PositionedDirectional(
                    top: 8,
                    end: 8,
                    child: Icon(
                      Icons.push_pin,
                      size: 14,
                      color: _chatTextSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String get _footerText {
    final time = _formatTime(message.createdAt);
    if (!_isMine || message.createdAt == null) {
      return time;
    }
    return '$time \u2713\u2713';
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
