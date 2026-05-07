import 'package:flutter/material.dart';

import '../../services/checklist_user_resolver.dart';

class ChecklistItemTile extends StatefulWidget {
  const ChecklistItemTile({
    super.key,
    required this.itemName,
    required this.itemIcon,
    required this.done,
    required this.assignedTo,
    required this.currentUserId,
    required this.userResolver,
    required this.onDoneChanged,
    required this.onAssignPressed,
    required this.onReleasePressed,
  });

  final String itemName;
  final IconData itemIcon;
  final bool done;
  final String? assignedTo;
  final String? currentUserId;
  final ChecklistUserResolver userResolver;
  final ValueChanged<bool> onDoneChanged;
  final Future<void> Function()? onAssignPressed;
  final Future<void> Function()? onReleasePressed;

  @override
  State<ChecklistItemTile> createState() => _ChecklistItemTileState();
}

class _ChecklistItemTileState extends State<ChecklistItemTile> {
  bool _assignmentInProgress = false;
  bool _releaseInProgress = false;

  @override
  Widget build(BuildContext context) {
    final normalizedAssignedTo = _normalizeUserId(widget.assignedTo);
    final normalizedCurrentUserId = _normalizeUserId(widget.currentUserId);
    final canAssignToMe = normalizedAssignedTo == null;
    final canMarkDone = normalizedCurrentUserId != null &&
        normalizedAssignedTo == normalizedCurrentUserId;
    final canShowRelease = canMarkDone;
    final cardColor = widget.done ? const Color(0xFFFFF7ED) : Colors.white;
    final iconColor =
        widget.done ? Colors.orange.withValues(alpha: 0.6) : Colors.orange;
    final titleColor = widget.done
        ? const Color(0xFF1F1F1F).withValues(alpha: 0.58)
        : const Color(0xFF1F1F1F);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8B89B), width: 1.4),
      ),
      child: ListTile(
        dense: true,
        horizontalTitleGap: 6,
        minLeadingWidth: 34,
        minVerticalPadding: 6,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Transform.scale(
          scale: 1.08,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: canMarkDone
                ? null
                : () => _showBlockedDoneMessage(
                      context,
                      assignedTo: normalizedAssignedTo,
                    ),
            child: Checkbox(
              value: widget.done,
              activeColor: Colors.orange,
              side: const BorderSide(color: Color(0xFFD0D0D0), width: 1.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              onChanged: canMarkDone
                  ? (value) {
                      if (value == null) {
                        return;
                      }
                      widget.onDoneChanged(value);
                    }
                  : null,
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(widget.itemIcon, color: iconColor, size: 25),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.itemName,
                style: TextStyle(
                  fontSize: 18.5,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                  decoration: widget.done
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: const Color(0xFF8A8A8A).withValues(
                    alpha: 0.55,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: _AssignmentBadge(
                assignedTo: normalizedAssignedTo,
                currentUserId: normalizedCurrentUserId,
                userResolver: widget.userResolver,
              ),
            ),
          ],
        ),
        trailing: canAssignToMe
            ? IconButton(
                icon: _assignmentInProgress
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.add_circle_outline,
                        size: 20,
                        color: Colors.orange,
                      ),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                splashRadius: 18,
                tooltip: 'Assign to me',
                onPressed:
                    _assignmentInProgress || widget.onAssignPressed == null
                        ? null
                        : _assignToMe,
              )
            : canShowRelease
                ? IconButton(
                    icon: _releaseInProgress
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.close,
                            size: 18,
                            color: Color(0xFF7A6B55),
                          ),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    splashRadius: 18,
                    tooltip: 'Release item',
                    onPressed:
                        _releaseInProgress || widget.onReleasePressed == null
                            ? null
                            : _releaseFromMe,
                  )
                : null,
      ),
    );
  }

  Future<void> _releaseFromMe() async {
    final onReleasePressed = widget.onReleasePressed;
    if (onReleasePressed == null || _releaseInProgress) {
      return;
    }

    setState(() {
      _releaseInProgress = true;
    });

    try {
      await onReleasePressed();
    } finally {
      if (mounted) {
        setState(() {
          _releaseInProgress = false;
        });
      }
    }
  }

  Future<void> _assignToMe() async {
    final onAssignPressed = widget.onAssignPressed;
    if (onAssignPressed == null || _assignmentInProgress) {
      return;
    }

    setState(() {
      _assignmentInProgress = true;
    });

    try {
      await onAssignPressed();
    } finally {
      if (mounted) {
        setState(() {
          _assignmentInProgress = false;
        });
      }
    }
  }

  static String? _normalizeUserId(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  static void _showBlockedDoneMessage(
    BuildContext context, {
    required String? assignedTo,
  }) {
    final message = assignedTo == null
        ? 'Assign this item to yourself first.'
        : 'This item is assigned to another member.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AssignmentBadge extends StatelessWidget {
  const _AssignmentBadge({
    required this.assignedTo,
    required this.currentUserId,
    required this.userResolver,
  });

  final String? assignedTo;
  final String? currentUserId;
  final ChecklistUserResolver userResolver;

  @override
  Widget build(BuildContext context) {
    final normalizedCurrentUserId = currentUserId?.trim();
    if (assignedTo == null || assignedTo!.isEmpty) {
      return const SizedBox.shrink();
    }

    if (normalizedCurrentUserId == null || normalizedCurrentUserId.isEmpty) {
      return _buildBadge('Member');
    }

    return FutureBuilder<String>(
      future: userResolver.resolveAssignmentLabel(
        assignedTo: assignedTo,
        currentUserId: normalizedCurrentUserId,
      ),
      builder: (context, snapshot) {
        final label = snapshot.data ?? _fallbackLabel();
        return _buildBadge(label);
      },
    );
  }

  Widget _buildBadge(String label) {
    final style = _badgeStyle(label);
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: style.backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: style.hasBorder ? Border.all(color: style.borderColor) : null,
        ),
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            fontSize: 14,
            fontWeight: style.fontWeight,
            color: style.textColor,
            height: 1.05,
          ),
        ),
      ),
    );
  }

  _BadgeStyle _badgeStyle(String label) {
    if (label == 'You') {
      return const _BadgeStyle(
        backgroundColor: Color(0xFFCFEFD8),
        borderColor: Color(0xFF7AC48F),
        textColor: Color(0xFF166534),
        fontWeight: FontWeight.w700,
        hasBorder: true,
      );
    }

    return const _BadgeStyle(
      backgroundColor: Colors.transparent,
      borderColor: Color(0xFFBFC5CC),
      textColor: Color(0xFF535B65),
      fontWeight: FontWeight.w600,
      hasBorder: true,
    );
  }

  String _fallbackLabel() {
    if (assignedTo == null) {
      return '';
    }
    if (assignedTo == currentUserId) {
      return 'You';
    }
    return 'Member';
  }
}

class _BadgeStyle {
  const _BadgeStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.fontWeight,
    required this.hasBorder,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final FontWeight fontWeight;
  final bool hasBorder;
}
