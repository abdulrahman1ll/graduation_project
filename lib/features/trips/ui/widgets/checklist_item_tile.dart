import 'package:flutter/material.dart';

import '../../services/checklist_user_resolver.dart';

class ChecklistItemTile extends StatelessWidget {
  const ChecklistItemTile({
    super.key,
    required this.itemName,
    required this.itemIcon,
    required this.done,
    required this.assignedTo,
    required this.currentUserId,
    required this.userResolver,
    required this.assignmentInProgress,
    required this.onDoneChanged,
    required this.onAssignPressed,
  });

  final String itemName;
  final IconData itemIcon;
  final bool done;
  final String? assignedTo;
  final String? currentUserId;
  final ChecklistUserResolver userResolver;
  final bool assignmentInProgress;
  final ValueChanged<bool> onDoneChanged;
  final VoidCallback onAssignPressed;

  @override
  Widget build(BuildContext context) {
    final normalizedAssignedTo = _normalizeUserId(assignedTo);
    final cardColor = done ? const Color(0xFFFFF7ED) : Colors.white;
    final iconColor =
        done ? Colors.orange.withValues(alpha: 0.6) : Colors.orange;
    final titleColor = done
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
          child: Checkbox(
            value: done,
            activeColor: Colors.orange,
            side: const BorderSide(color: Color(0xFFD0D0D0), width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              onDoneChanged(value);
            },
          ),
        ),
        title: Row(
          children: [
            Icon(itemIcon, color: iconColor, size: 25),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                itemName,
                style: TextStyle(
                  fontSize: 18.5,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                  decoration:
                      done ? TextDecoration.lineThrough : TextDecoration.none,
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
                currentUserId: currentUserId,
                userResolver: userResolver,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: assignmentInProgress
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
          tooltip: 'Assign item',
          onPressed: assignmentInProgress || currentUserId == null
              ? null
              : onAssignPressed,
        ),
      ),
    );
  }

  static String? _normalizeUserId(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
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
