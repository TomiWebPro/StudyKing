import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:studyking/core/services/llm_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';

class QuickGuideScreen extends StatefulWidget {
  final LlmService? llmService;

  const QuickGuideScreen({super.key, this.llmService});

  @override
  State<QuickGuideScreen> createState() => _QuickGuideScreenState();
}

class _QuickGuideScreenState extends State<QuickGuideScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isTyping = false;
  bool _hasInteracted = false;
  List<_ChatMessage> _messages = [];
  List<String> _suggestedPrompts = [];
  bool _localized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_localized) {
      final l10n = AppLocalizations.of(context)!;
      _messages = [
        _ChatMessage(isUser: false, text: l10n.quickGuideWelcomeMessage),
      ];
      _suggestedPrompts = [
        l10n.suggestedPromptExplain,
        l10n.suggestedPromptQuiz,
        l10n.suggestedPromptMath,
      ];
      _localized = true;
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: text));
      _isTyping = true;
      _hasInteracted = true;
    });

    _textController.clear();
    _scrollToBottom();
    _inputFocusNode.unfocus();

    String response;
    try {
      final llm = widget.llmService;
      if (llm != null && llm.config.apiKey.isNotEmpty) {
        response = await llm.chat(
          message: text,
          modelId: 'google/gemini-2.5-flash-preview-05-20',
          systemPrompt: 'You are StudyKing Quick Guide, a helpful AI study assistant. '
              'Provide concise, educational answers. Help with explanations, quiz questions, '
              'and math problems. Respond conversationally.',
        );
      } else {
        response = _fallbackResponse(text);
      }
    } catch (_) {
      response = _fallbackResponse(text);
    }

    setState(() {
      _messages.add(_ChatMessage(isUser: false, text: response));
      _isTyping = false;
    });

    _scrollToBottom();
  }

  String _fallbackResponse(String text) {
    final l10n = AppLocalizations.of(context)!;
    if (text.toLowerCase().contains('explain')) {
      return l10n.fallbackExplainResponse;
    } else if (text.toLowerCase().contains('question') || text.toLowerCase().contains('quiz')) {
      return l10n.fallbackQuizResponse;
    } else if (text.toLowerCase().contains('math') || text.toLowerCase().contains('calculate')) {
      return l10n.fallbackMathResponse;
    } else {
      return l10n.fallbackGeneralResponse;
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _selectPrompt(String prompt) {
    _textController.text = prompt;
    _sendMessage();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.quickGuide),
        actions: [
          Semantics(
            label: l10n.quickGuideHelp,
            button: true,
            child: IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: l10n.help,
              onPressed: () => _showHelpDialog(context),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: ResponsiveUtils.listPadding(context),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final l10n = AppLocalizations.of(context)!;
                  return Semantics(
                    label: message.isUser ? l10n.semanticsYouSaid(message.text) : l10n.semanticsQuickGuideSaid(message.text),
                    child: Align(
                      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(bottom: ResponsiveUtils.verticalSpacing(context)),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.horizontalSpacing(context), vertical: 12),
                        decoration: BoxDecoration(
                          color: message.isUser
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: message.isUser
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Semantics(
              liveRegion: true,
              child: AnimatedOpacity(
                opacity: _isTyping ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: ResponsiveUtils.listPadding(context),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.quickGuideIsThinking,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!_hasInteracted && _messages.length <= 1)
              _buildSuggestedPrompts(context),
            _buildMessageComposer(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedPrompts(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: ResponsiveUtils.listPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: ResponsiveUtils.verticalSpacing(context) * 0.75),
            child: Text(
              l10n.suggestedPrompts,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedPrompts.map((prompt) {
              return Semantics(
                label: l10n.semanticsSendPrompt(prompt),
                button: true,
                  child: ActionChip(
                    label: Text(
                      prompt,
                      style: const TextStyle(fontSize: 13),
                    ),
                  onPressed: () => _selectPrompt(prompt),
                  backgroundColor: colorScheme.secondaryContainer,
                  side: BorderSide.none,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageComposer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _sendMessage,
      },
      child: FocusTraversalGroup(
        child: Container(
        padding: ResponsiveUtils.screenPadding(context),
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
            Expanded(
              child: Semantics(
                label: l10n.semanticsMessageInput,
                hint: l10n.messageInputHint,
                child: TextField(
                  controller: _textController,
                  focusNode: _inputFocusNode,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: l10n.askAnything,
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: l10n.sendMessage,
              button: true,
              child: IconButton.filled(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
                tooltip: l10n.sendMessage,
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
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.quickGuideHelpTitle),
        content: Text(l10n.quickGuideHelpContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.gotIt),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final bool isUser;
  final String text;
  _ChatMessage({required this.isUser, required this.text});
}
