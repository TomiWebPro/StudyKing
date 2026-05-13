import 'package:flutter/material.dart';

class ConversationInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool isEnabled;
  final bool isLoading;
  final String hintText;
  final String sendTooltip;
  final VoidCallback onSend;
  final Widget? leading;
  final List<Widget>? trailing;

  const ConversationInput({
    super.key,
    required this.controller,
    this.focusNode,
    this.isEnabled = true,
    this.isLoading = false,
    required this.hintText,
    this.sendTooltip = 'Send',
    required this.onSend,
    this.leading,
    this.trailing,
  });

  @override
  State<ConversationInput> createState() => _ConversationInputState();
}

class _ConversationInputState extends State<ConversationInput> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (widget.leading != null) ...[
            widget.leading!,
            const SizedBox(width: 8),
          ],
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              enabled: widget.isEnabled && !widget.isLoading,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => widget.onSend(),
            ),
          ),
          const SizedBox(width: 8),
          if (widget.trailing != null)
            ...widget.trailing!
          else
            Semantics(
              button: true,
              label: widget.sendTooltip,
              child: IconButton.filled(
                icon: widget.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                onPressed:
                    widget.isEnabled && !widget.isLoading ? widget.onSend : null,
                tooltip: widget.sendTooltip,
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size(48, 48),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
