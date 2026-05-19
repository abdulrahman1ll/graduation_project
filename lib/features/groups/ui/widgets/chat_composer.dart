import 'package:flutter/material.dart';

import '../../../../core/theme/kashta_colors.dart';
import '../../../../core/utils/localization.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.isSending,
    required this.enabled,
    required this.tr,
    required this.onSend,
  });

  final bool isSending;
  final bool enabled;
  final Tr tr;
  final Future<void> Function(String content) onSend;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!widget.enabled || widget.isSending) {
      return;
    }
    final content = _controller.text.trim();
    if (content.isEmpty) {
      return;
    }
    _controller.clear();
    await widget.onSend(content);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: widget.enabled && !widget.isSending,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: widget.enabled
                    ? widget.tr.t('writeMessage')
                    : widget.tr.t('joinGroupToChat'),
                filled: true,
                fillColor: KashtaColors.cardSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: KashtaColors.sandBorder,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: KashtaColors.sandBorder,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: KashtaColors.primary.withValues(alpha: 0.48),
                    width: 1,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: widget.enabled && !widget.isSending ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: KashtaColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(46, 46),
              maximumSize: const Size(46, 46),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: widget.isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send, size: 18),
          ),
        ],
      ),
    );
  }
}
