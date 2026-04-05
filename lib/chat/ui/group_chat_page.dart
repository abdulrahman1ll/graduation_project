import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/chat_message.dart';
import '../models/chat_message_type.dart';
import '../models/group.dart';
import '../models/group_role.dart';
import '../services/chat_service.dart';
import '../services/group_service.dart';
import '../services/invite_service.dart';
import 'group_checklist_flow.dart';
import 'group_details_page.dart';
import 'widgets/chat_composer.dart';
import 'widgets/chat_message_bubble.dart';

class GroupChatPage extends StatefulWidget {
  const GroupChatPage({
    super.key,
    required this.groupId,
    this.chatService,
    this.groupService,
    this.inviteService,
  });

  final String groupId;
  final ChatService? chatService;
  final GroupService? groupService;
  final InviteService? inviteService;

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  late final ChatService _chatService;
  late final GroupService _groupService;
  late final InviteService _inviteService;
  late final Stream<List<ChatMessage>> _messagesStream;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;

  bool _sending = false;
  GroupRole? _role;
  Object? _roleError;
  int _lastMessageCount = 0;
  final Map<String, String> _senderNames = <String, String>{};
  final Set<String> _loadingSenderIds = <String>{};

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _chatService = widget.chatService ?? ChatService();
    _groupService = widget.groupService ?? GroupService();
    _inviteService = widget.inviteService ?? const InviteService();
    _messagesStream = _chatService.watchMessages(widget.groupId);
    _loadRole();
    _listenForReadReceipts();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }
    try {
      final role = await _groupService.getUserRole(widget.groupId, userId);
      if (!mounted) {
        return;
      }
      setState(() {
        _role = role;
        _roleError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _roleError = error);
    }
  }

  void _listenForReadReceipts() {
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }
    _messagesSubscription = _messagesStream.listen((messages) async {
      await _primeSenderNames(messages);
      final hasUnread = messages.any(
        (message) => message.senderId != userId && !message.hasRead(userId),
      );
      if (hasUnread) {
        try {
          await _chatService.markMessagesAsRead(widget.groupId, userId);
        } catch (_) {}
      }
      _queueAutoScroll(messages.length);
    });
  }

  Future<void> _primeSenderNames(List<ChatMessage> messages) async {
    final missingIds = messages
        .map((message) => message.senderId)
        .where(
          (senderId) =>
              senderId.isNotEmpty &&
              !_senderNames.containsKey(senderId) &&
              !_loadingSenderIds.contains(senderId),
        )
        .toSet();
    if (missingIds.isEmpty) {
      return;
    }

    _loadingSenderIds.addAll(missingIds);
    final resolvedNames = await _groupService.resolveUserNames(missingIds);
    if (!mounted) {
      return;
    }
    setState(() {
      _senderNames.addAll(resolvedNames);
      _loadingSenderIds.removeAll(missingIds);
    });
  }

  void _queueAutoScroll(int messageCount) {
    if (_lastMessageCount == messageCount) {
      return;
    }
    _lastMessageCount = messageCount;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _copyInviteLink() async {
    final inviteLink = _inviteService.generateInviteLink(widget.groupId);
    await Clipboard.setData(ClipboardData(text: inviteLink));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite link copied')),
    );
  }

  Future<void> _handleSend(String content) async {
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }
    setState(() => _sending = true);
    try {
      final type = _inferType(content).value;
      await _chatService.sendMessage(widget.groupId, userId, type, content);
    } catch (error) {
      _showError('Unable to send message.');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _togglePin(ChatMessage message) async {
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }
    try {
      if (message.isPinned) {
        await _chatService.unpinMessage(widget.groupId, message.id, userId);
      } else {
        await _chatService.pinMessage(widget.groupId, message.id, userId);
      }
    } catch (_) {
      _showError('Unable to update message.');
    }
  }

  ChatMessageType _inferType(String content) {
    final uri = Uri.tryParse(content.trim());
    if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
      return ChatMessageType.link;
    }
    return ChatMessageType.text;
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_roleError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Chat')),
        body: const Center(child: Text('Unable to load group access')),
      );
    }

    return StreamBuilder<Group?>(
      stream: _groupService.watchGroup(widget.groupId),
      builder: (context, groupSnapshot) {
        final group = groupSnapshot.data;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            elevation: 0,
            titleSpacing: 12,
            title: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: group == null
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => GroupDetailsPage(
                            groupId: widget.groupId,
                            groupService: _groupService,
                          ),
                        ),
                      );
                    },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFFFE0B2),
                    backgroundImage: group?.imageUrl == null
                        ? null
                        : NetworkImage(group!.imageUrl!),
                    child: group?.imageUrl == null
                        ? const Icon(Icons.groups, color: Colors.orange)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      group?.name.trim().isNotEmpty == true
                          ? group!.name
                          : 'Group Chat',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (group != null)
                IconButton(
                  onPressed: () => openGroupChecklistFlow(
                    context: context,
                    group: group,
                    groupId: widget.groupId,
                    groupService: _groupService,
                  ),
                  tooltip: (group.tripId?.trim().isEmpty ?? true)
                      ? 'Link to checklist'
                      : 'Open checklist',
                  icon: Icon(
                    (group.tripId?.trim().isEmpty ?? true)
                        ? Icons.fact_check
                        : Icons.checklist,
                  ),
                ),
              IconButton(
                onPressed: _copyInviteLink,
                tooltip: 'Copy invite link',
                icon: const Icon(Icons.link),
              ),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/chat_bg.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              Column(
                children: [
                  _PinnedMessageBanner(
                    groupId: widget.groupId,
                    chatService: _chatService,
                    senderNames: _senderNames,
                  ),
                  Expanded(
                    child: StreamBuilder<List<ChatMessage>>(
                      stream: _messagesStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Unable to load messages'),
                          );
                        }

                        final messages = snapshot.data ?? const <ChatMessage>[];
                        if (messages.isEmpty) {
                          return const Center(
                            child: Text(
                              'No messages yet. Start the conversation.',
                            ),
                          );
                        }

                        _queueAutoScroll(messages.length);

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final senderName =
                                _senderNames[message.senderId] ?? 'Member';
                            return ChatMessageBubble(
                              key: ValueKey(message.id),
                              message: message,
                              senderName: senderName,
                              currentUserId: _currentUserId,
                              isSeenByCurrentUser:
                                  _currentUserId != null &&
                                  message.hasRead(_currentUserId!),
                              canPin: _role == GroupRole.admin &&
                                  message.type != ChatMessageType.system,
                              onTogglePin: () => _togglePin(message),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: ChatComposer(
                      isSending: _sending,
                      enabled: _role != null,
                      onSend: _handleSend,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PinnedMessageBanner extends StatelessWidget {
  const _PinnedMessageBanner({
    required this.groupId,
    required this.chatService,
    required this.senderNames,
  });

  final String groupId;
  final ChatService chatService;
  final Map<String, String> senderNames;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatMessage>>(
      stream: chatService.watchPinnedMessages(groupId, limit: 1),
      builder: (context, snapshot) {
        final message = (snapshot.data ?? const <ChatMessage>[]).firstOrNull;
        if (message == null) {
          return const SizedBox.shrink();
        }

        return InkWell(
          onTap: () => _showPinnedMessagesSheet(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.push_pin, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Pinned: ${message.content}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPinnedMessagesSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.6,
            child: StreamBuilder<List<ChatMessage>>(
              stream: chatService.watchPinnedMessages(groupId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? const <ChatMessage>[];
                if (messages.isEmpty) {
                  return const Center(child: Text('No pinned messages'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final senderName =
                        senderNames[message.senderId] ?? 'Member';
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            senderName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(message.content),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
