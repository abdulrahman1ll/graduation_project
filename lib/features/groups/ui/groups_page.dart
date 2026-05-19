import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../groups.dart' as chat;
import '../../../core/providers/role_provider.dart';
import '../../../core/theme/kashta_colors.dart';
import '../../../core/utils/localization.dart';
import 'widgets/chat_message_bubble.dart';

const Color _groupsTextSecondary = Color(0xFF7A6A5B);
const Color _groupsPrimary = Color(0xFFD97845);
const double _groupsRadius = 18;
const List<Color> _defaultGroupAvatarColors = <Color>[
  Color(0xFFAAC0AF),
  Color(0xFFE29F79),
  Color(0xFFEFDFCD),
  Color(0xFFD6E1D8),
];
const List<BoxShadow> _groupCardShadow = <BoxShadow>[
  BoxShadow(
    color: Color(0x1A8A5A2B),
    blurRadius: 16,
    spreadRadius: 0,
    offset: Offset(0, 6),
  ),
];

class GroupsPage extends StatefulWidget {
  const GroupsPage({
    super.key,
    required this.tr,
    required this.isArabic,
    required this.onToggleLanguage,
  });

  final Tr tr;
  final bool isArabic;
  final VoidCallback onToggleLanguage;

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final chat.GroupService _groupService = chat.GroupService();
  final chat.ChatService _chatService = chat.ChatService();
  final TextEditingController _searchController = TextEditingController();

  StreamSubscription<List<chat.Group>>? _groupsSubscription;
  final Map<String, StreamSubscription<List<chat.ChatMessage>>>
      _messageSubscriptions =
      <String, StreamSubscription<List<chat.ChatMessage>>>{};
  final Map<String, _GroupConversationSummary> _summaries =
      <String, _GroupConversationSummary>{};
  final Map<String, String> _senderNames = <String, String>{};

  List<chat.Group> _groups = const <chat.Group>[];
  bool _loading = true;
  Object? _error;
  String _searchQuery = '';

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _subscribeToGroups();
  }

  @override
  void dispose() {
    _groupsSubscription?.cancel();
    for (final subscription in _messageSubscriptions.values) {
      subscription.cancel();
    }
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final nextQuery = _searchController.text.trim().toLowerCase();
    if (nextQuery == _searchQuery) {
      return;
    }
    setState(() => _searchQuery = nextQuery);
  }

  void _subscribeToGroups() {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      setState(() {
        _loading = false;
        _error = widget.tr.t('failedToLoadGroups');
      });
      return;
    }

    _groupsSubscription = _groupService.watchUserGroups(currentUserId).listen(
      (groups) {
        _syncMessageSubscriptions(groups, currentUserId);
        if (!mounted) {
          return;
        }
        setState(() {
          _groups = groups;
          _loading = false;
          _error = null;
        });
      },
      onError: (Object error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _loading = false;
          _error = error;
        });
      },
    );
  }

  void _syncMessageSubscriptions(
    List<chat.Group> groups,
    String currentUserId,
  ) {
    final activeGroupIds = groups.map((group) => group.id).toSet();

    final removedIds = _messageSubscriptions.keys
        .where((groupId) => !activeGroupIds.contains(groupId))
        .toList(growable: false);
    for (final groupId in removedIds) {
      _messageSubscriptions.remove(groupId)?.cancel();
      _summaries.remove(groupId);
    }

    for (final group in groups) {
      if (_messageSubscriptions.containsKey(group.id)) {
        continue;
      }

      _messageSubscriptions[group.id] = _chatService
          .watchMessages(group.id)
          .listen((messages) => _handleMessagesChanged(
                groupId: group.id,
                messages: messages,
                currentUserId: currentUserId,
              ));
    }
  }

  Future<void> _handleMessagesChanged({
    required String groupId,
    required List<chat.ChatMessage> messages,
    required String currentUserId,
  }) async {
    final unreadCount = messages
        .where(
          (message) =>
              message.senderId != currentUserId &&
              !message.hasRead(currentUserId),
        )
        .length;
    final lastMessage = messages.isEmpty ? null : messages.last;
    final hasPinned = messages.any((message) => message.isPinned);

    if (lastMessage != null &&
        lastMessage.senderId.isNotEmpty &&
        !_senderNames.containsKey(lastMessage.senderId)) {
      final resolved = await _groupService.resolveUserNames(<String>[
        lastMessage.senderId,
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _senderNames.addAll(resolved);
      });
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _summaries[groupId] = _GroupConversationSummary(
        lastMessage: lastMessage,
        unreadCount: unreadCount,
        hasPinned: hasPinned,
      );
    });
  }

  List<chat.Group> get _visibleGroups {
    final filtered = _groups.where((group) {
      if (_searchQuery.isEmpty) {
        return true;
      }
      final name = group.name.toLowerCase();
      final description = group.description.toLowerCase();
      return name.contains(_searchQuery) || description.contains(_searchQuery);
    }).toList(growable: false);

    filtered.sort((a, b) {
      final aDate = _summaries[a.id]?.lastMessage?.createdAt ?? a.createdAt;
      final bDate = _summaries[b.id]?.lastMessage?.createdAt ?? b.createdAt;
      final aValue = aDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bValue = bDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bValue.compareTo(aValue);
    });

    return filtered;
  }

  Future<void> _showJoinGroupDialog() async {
    final scaffoldContext = context;
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(content: Text(widget.tr.t('please_sign_in_first'))),
      );
      return;
    }

    final didJoin = await showDialog<bool>(
      context: scaffoldContext,
      builder: (_) => _JoinGroupDialog(
        tr: widget.tr,
        groupService: _groupService,
        currentUserId: currentUserId,
      ),
    );

    if (!mounted || didJoin == null) {
      return;
    }

    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      SnackBar(
        content: Text(
          didJoin
              ? widget.tr.t('joinedGroup')
              : widget.tr.t('alreadyGroupMember'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _currentUserId;

    return Scaffold(
      backgroundColor: KashtaColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: KashtaColors.backgroundCream,
        foregroundColor: KashtaColors.textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Text(
          widget.tr.t('groupsTitle'),
          style: const TextStyle(
            color: KashtaColors.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: OutlinedButton.icon(
              onPressed: _showJoinGroupDialog,
              icon: const Icon(Icons.group_add_outlined, size: 18),
              label: Text(widget.tr.t('joinGroup')),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                foregroundColor: _groupsPrimary,
                backgroundColor: KashtaColors.cardSurface,
                side: const BorderSide(color: KashtaColors.sandBorder),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: currentUserId == null
          ? Center(
              child: Text(
                widget.tr.t('failedToLoadGroups'),
                style: const TextStyle(color: KashtaColors.textDark),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: KashtaColors.cardSurface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: KashtaColors.textDark.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      cursorColor: _groupsPrimary,
                      style: const TextStyle(
                        color: KashtaColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.tr.t('searchGroups'),
                        hintStyle: const TextStyle(
                          color: _groupsTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: _groupsPrimary,
                        ),
                        filled: true,
                        fillColor: KashtaColors.cardSurface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: KashtaColors.sandBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: _groupsPrimary,
                            width: 1.3,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: KashtaColors.sandBorder,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildBody(context, currentUserId),
                ),
              ],
            ),
      floatingActionButton: _CreateGroupFab(
        emptyState: _visibleGroups.isEmpty && !_loading,
        tr: widget.tr,
      ),
    );
  }

  Widget _buildBody(BuildContext context, String currentUserId) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _groupsPrimary),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          widget.tr.t('failedToLoadGroups'),
          style: const TextStyle(color: KashtaColors.textDark),
        ),
      );
    }

    final visibleGroups = _visibleGroups;
    if (visibleGroups.isEmpty) {
      if (_groups.isEmpty) {
        return _GroupsEmptyState(
          tr: widget.tr,
          onCreate: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => chat.CreateGroupPage(tr: widget.tr),
              ),
            );
          },
        );
      }
      return _GroupsQuietState(
        icon: Icons.search_off_rounded,
        text: widget.tr.t('noGroupsMatchSearch'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: visibleGroups.length,
      itemBuilder: (context, index) {
        final group = visibleGroups[index];
        final summary = _summaries[group.id];
        final avatarColor =
            _defaultGroupAvatarColors[index % _defaultGroupAvatarColors.length];
        final lastMessage = summary?.lastMessage;
        final senderName = lastMessage == null
            ? ''
            : (lastMessage.senderId == currentUserId
                ? widget.tr.t('you')
                : (_senderNames[lastMessage.senderId] ??
                    widget.tr.t('member')));
        final lastMessageContent = lastMessage == null
            ? ''
            : lastMessage.type == chat.ChatMessageType.system
                ? localizedSystemMessageContent(
                    widget.tr,
                    lastMessage.content,
                  )
                : lastMessage.content;
        final preview = lastMessage == null
            ? group.description
            : '$senderName: $lastMessageContent';

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == visibleGroups.length - 1 ? 0 : 12,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: KashtaColors.cardSurface,
              borderRadius: BorderRadius.circular(_groupsRadius),
              boxShadow: _groupCardShadow,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(_groupsRadius),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                borderRadius: BorderRadius.circular(_groupsRadius),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => chat.GroupChatPage(
                        groupId: group.id,
                        tr: widget.tr,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: avatarColor,
                        backgroundImage: group.imageUrl == null
                            ? null
                            : NetworkImage(group.imageUrl!),
                        child: group.imageUrl == null
                            ? const Icon(
                                Icons.groups_rounded,
                                color: KashtaColors.textDark,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    group.name.trim().isEmpty
                                        ? widget.tr.t('unnamedGroup')
                                        : group.name,
                                    style: const TextStyle(
                                      color: KashtaColors.textDark,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _TimeBadge(
                                  text: _formatTime(
                                    lastMessage?.createdAt ?? group.createdAt,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Text(
                              preview.isEmpty
                                  ? widget.tr.t('noMessagesPreview')
                                  : preview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _groupsTextSecondary,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 11),
                            Row(
                              children: [
                                if (summary?.hasPinned == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: KashtaColors.softOlive.withValues(
                                        alpha: 0.26,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: KashtaColors.softOlive
                                            .withValues(alpha: 0.42),
                                      ),
                                    ),
                                    child: Text(
                                      widget.tr.t('pinned'),
                                      style: const TextStyle(
                                        color: KashtaColors.textDark,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                if ((summary?.unreadCount ?? 0) > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _groupsPrimary,
                                      borderRadius: BorderRadius.circular(999),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _groupsPrimary.withValues(
                                            alpha: 0.22,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '${summary!.unreadCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) {
      return '';
    }
    final now = DateTime.now();
    final isSameDay = value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
    if (isSameDay) {
      final hour = value.hour.toString().padLeft(2, '0');
      final minute = value.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    return '${value.day}/${value.month}';
  }
}

class _GroupConversationSummary {
  const _GroupConversationSummary({
    required this.lastMessage,
    required this.unreadCount,
    required this.hasPinned,
  });

  final chat.ChatMessage? lastMessage;
  final int unreadCount;
  final bool hasPinned;
}

class _JoinGroupDialog extends StatefulWidget {
  const _JoinGroupDialog({
    required this.tr,
    required this.groupService,
    required this.currentUserId,
  });

  final Tr tr;
  final chat.GroupService groupService;
  final String currentUserId;

  @override
  State<_JoinGroupDialog> createState() => _JoinGroupDialogState();
}

class _JoinGroupDialogState extends State<_JoinGroupDialog> {
  final TextEditingController _controller = TextEditingController();

  String? _validationMessage;
  bool _joining = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final groupId = _controller.text.trim();
    if (groupId.isEmpty) {
      setState(() {
        _validationMessage = widget.tr.t('enterInvitationCode');
      });
      return;
    }

    setState(() {
      _joining = true;
      _validationMessage = null;
    });

    try {
      final didJoin = await widget.groupService.joinGroup(
        groupId,
        widget.currentUserId,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(didJoin);
    } on FirebaseException catch (error) {
      debugPrint(
        'GroupsPage.joinGroupByCode failed: '
        '${error.code} ${error.message}',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _joining = false;
        _validationMessage = error.code == 'not-found'
            ? widget.tr.t('groupNotFound')
            : error.message ?? widget.tr.t('unableToJoinGroup');
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _joining = false;
        _validationMessage = widget.tr.t('unableToJoinGroup');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KashtaColors.cardSurface,
      surfaceTintColor: KashtaColors.cardSurface,
      title: Text(
        widget.tr.t('joinGroup'),
        style: const TextStyle(
          color: KashtaColors.textDark,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: TextField(
        controller: _controller,
        enabled: !_joining,
        autofocus: true,
        cursorColor: _groupsPrimary,
        style: const TextStyle(color: KashtaColors.textDark),
        decoration: InputDecoration(
          labelText: widget.tr.t('enterInvitationCode'),
          errorText: _validationMessage,
          prefixIcon: const Icon(
            Icons.key_rounded,
            color: _groupsPrimary,
          ),
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: _joining ? null : (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: _joining ? null : () => Navigator.of(context).pop(),
          child: Text(widget.tr.t('cancel')),
        ),
        FilledButton(
          onPressed: _joining ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: _groupsPrimary,
            foregroundColor: Colors.white,
          ),
          child: _joining
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.tr.t('join')),
        ),
      ],
    );
  }
}

class _GroupsEmptyState extends StatelessWidget {
  const _GroupsEmptyState({
    required this.tr,
    required this.onCreate,
  });

  final Tr tr;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: KashtaColors.softOlive.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: KashtaColors.sandBorder),
                boxShadow: [
                  BoxShadow(
                    color: KashtaColors.textDark.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.groups_rounded,
                size: 36,
                color: KashtaColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr.t('no_groups_yet'),
              style: const TextStyle(
                color: KashtaColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr.t('groupsChatEmptySubtitle'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _groupsTextSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreate,
              style: FilledButton.styleFrom(
                backgroundColor: _groupsPrimary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add),
              label: Text(tr.t('createGroupTitle')),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateGroupFab extends StatelessWidget {
  const _CreateGroupFab({
    required this.emptyState,
    required this.tr,
  });

  final bool emptyState;
  final Tr tr;

  @override
  Widget build(BuildContext context) {
    return Consumer<RoleProvider>(
      builder: (context, provider, child) {
        if (emptyState) {
          return const SizedBox.shrink();
        }
        return FloatingActionButton.extended(
          backgroundColor: _groupsPrimary,
          foregroundColor: Colors.white,
          elevation: 4,
          highlightElevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          icon: const Icon(Icons.add),
          label: Text(
            tr.t('newGroup'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => chat.CreateGroupPage(tr: tr),
              ),
            );
          },
        );
      },
    );
  }
}

class _TimeBadge extends StatelessWidget {
  const _TimeBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: KashtaColors.backgroundCream,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: KashtaColors.sandBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _groupsTextSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

class _GroupsQuietState extends StatelessWidget {
  const _GroupsQuietState({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: KashtaColors.softOlive.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: KashtaColors.sandBorder),
              ),
              child: Icon(icon, color: KashtaColors.textDark, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _groupsTextSecondary,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
