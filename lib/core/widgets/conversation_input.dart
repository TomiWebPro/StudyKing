import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

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
  final String? semanticsLabel;
  final String? semanticsHint;

  const ConversationInput({
    super.key,
    required this.controller,
    this.focusNode,
    this.isEnabled = true,
    this.isLoading = false,
    required this.hintText,
    required this.sendTooltip,
    required this.onSend,
    this.leading,
    this.trailing,
    this.semanticsLabel,
    this.semanticsHint,
  });

  @override
  State<ConversationInput> createState() => _ConversationInputState();
}

class _ConversationInputState extends State<ConversationInput> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true):
            widget.onSend,
      },
      child: FocusTraversalGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsetsDirectional.only(
                start: ResponsiveUtils.screenPadding(context).left,
                end: ResponsiveUtils.screenPadding(context).right,
                top: 8,
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
                    child: Semantics(
                      label: widget.semanticsLabel,
                      hint: widget.semanticsHint,
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
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
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
                        onSubmitted: (_) {
                          if (!widget.isEnabled || widget.isLoading) return;
                          widget.onSend();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.trailing != null)
                    ...widget.trailing!
                  else
                    Semantics(
                      button: true,
                      label: widget.isLoading
                          ? AppLocalizations.of(context)!.sending
                          : widget.sendTooltip,
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
                        onPressed: widget.isEnabled && !widget.isLoading
                            ? widget.onSend
                            : null,
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
            ),
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: ResponsiveUtils.screenPadding(context).left,
                end: ResponsiveUtils.screenPadding(context).right,
                bottom: MediaQuery.of(context).padding.bottom + 4,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.sendHint,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
