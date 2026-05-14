import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/data/models/conversation_message_model.dart';
import 'package:studyking/core/providers/llm_providers.dart' show llmServiceProvider;
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider;
import 'package:studyking/core/widgets/conversation_input.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/quickguide/presentation/widgets/mode_navigation_widget.dart';
import 'package:studyking/features/quickguide/presentation/widgets/message_list_widget.dart';
import 'package:studyking/features/quickguide/presentation/widgets/suggested_prompts_widget.dart';
import 'package:studyking/features/quickguide/presentation/widgets/help_dialog.dart';

class QuickGuideScreen extends ConsumerStatefulWidget {
  final LlmService? llmService;
  final String defaultModelId;
  final String? systemPrompt;
  final bool showModeNavigation;

  const QuickGuideScreen({
    super.key,
    this.llmService,
    this.defaultModelId = 'openai/gpt-4o-mini',
    this.systemPrompt,
    this.showModeNavigation = true,
  });

  @override
  ConsumerState<QuickGuideScreen> createState() => _QuickGuideScreenState();
}

class _QuickGuideScreenState extends ConsumerState<QuickGuideScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  final Uuid _uuid = const Uuid();
  final Logger _logger = const Logger('QuickGuide');
  final ConversationMemory _memory = ConversationMemory();

  List<ConversationMessage> _messages = [];
  List<String> _suggestedPrompts = [];
  bool _isStreaming = false;
  bool _hasInteracted = false;
  bool _localized = false;
  bool _showSuggestions = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_localized) {
      final l10n = AppLocalizations.of(context)!;
      _messages = [
        ConversationMessage(
          id: _uuid.v4(),
          sessionId: 'quickguide',
          role: MessageRole.tutor,
          type: MessageType.text,
          content: l10n.quickGuideWelcomeMessage,
          timestamp: DateTime.now(),
        ),
      ];
      _suggestedPrompts = [
        l10n.suggestedPromptExplain,
        l10n.suggestedPromptQuiz,
        l10n.suggestedPromptMath,
      ];
      _localized = true;
    }
  }

  LlmService _getLlmService() {
    if (widget.llmService != null) return widget.llmService!;
    return ref.read(llmServiceProvider);
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isStreaming) return;

    setState(() {
      _hasInteracted = true;
      _showSuggestions = false;
    });

    final userMessage = ConversationMessage(
      id: _uuid.v4(),
      sessionId: 'quickguide',
      role: MessageRole.student,
      type: MessageType.text,
      content: text,
      timestamp: DateTime.now(),
    );

    _textController.clear();
    _inputFocusNode.unfocus();

    setState(() {
      _messages.add(userMessage);
      _isStreaming = true;
    });

    _memory.addUserMessage(text);
    _scrollToBottom();

    final tutorMessageId = _uuid.v4();
    final placeholder = ConversationMessage(
      id: tutorMessageId,
      sessionId: 'quickguide',
      role: MessageRole.tutor,
      type: MessageType.text,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    setState(() => _messages.add(placeholder));

    final buffer = StringBuffer();
    try {
      final llm = _getLlmService();
      if (llm.config.apiKey.isEmpty) {
        final response = _fallbackResponse(text);
        buffer.write(response);
      } else {
        final l10n = AppLocalizations.of(context)!;
        final effectiveSystem = widget.systemPrompt ?? l10n.quickGuideSystemPrompt;

        await for (final chunk in llm.chatStream(
          message: text,
          modelId: widget.defaultModelId,
          memory: _memory,
          systemPrompt: effectiveSystem,
        )) {
          buffer.write(chunk);
          if (mounted) {
            final idx = _messages.length - 1;
            setState(() {
              _messages[idx] = _messages[idx].copyWith(
                content: buffer.toString(),
                isStreaming: true,
              );
            });
          }
          _scrollToBottom();
        }
      }
    } catch (e) {
      _logger.e('QuickGuide error', e);
      buffer.write(_fallbackResponse(text));
    }

    if (mounted) {
      final idx = _messages.length - 1;
      setState(() {
        _messages[idx] = _messages[idx].copyWith(
          content: buffer.toString(),
          isStreaming: false,
          tokenCount: buffer.length ~/ 4,
        );
        _isStreaming = false;
      });
    }
    _memory.addAssistantMessage(buffer.toString());
    _scrollToBottom();
  }

  String _fallbackResponse(String text) {
    final l10n = AppLocalizations.of(context)!;
    return l10n.fallbackGeneralResponse;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _selectPrompt(String prompt) {
    _textController.text = prompt;
    _sendMessage();
  }

  void _clearConversation() {
    setState(() {
      final l10n = AppLocalizations.of(context)!;
      _messages = [
        ConversationMessage(
          id: _uuid.v4(),
          sessionId: 'quickguide',
          role: MessageRole.tutor,
          type: MessageType.text,
          content: l10n.quickGuideWelcomeMessage,
          timestamp: DateTime.now(),
        ),
      ];
      _showSuggestions = true;
      _hasInteracted = false;
    });
    _memory.clear();
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
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = ref.watch(settingsProvider).reduceMotion;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.quickGuide),
        actions: [
          if (_hasInteracted)
            Semantics(
              label: l10n.clearConversation,
              button: true,
              child: IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.clearConversation,
                onPressed: _clearConversation,
              ),
            ),
          Semantics(
            label: l10n.quickGuideHelp,
            button: true,
            child: IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: l10n.help,
              onPressed: () => showQuickGuideHelpDialog(context),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_showSuggestions && !_hasInteracted && widget.showModeNavigation)
              const ModeNavigationWidget(),
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState(l10n)
                  : MessageListWidget(
                      messages: _messages,
                      scrollController: _scrollController,
                      reduceMotion: reduceMotion,
                    ),
            ),
            AnimatedOpacity(
              opacity: _showSuggestions && !_hasInteracted ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: SuggestedPromptsWidget(
                prompts: _suggestedPrompts,
                onSelectPrompt: _selectPrompt,
              ),
            ),
            ConversationInput(
              controller: _textController,
              focusNode: _inputFocusNode,
              isEnabled: true,
              isLoading: _isStreaming,
              hintText: l10n.askAnything,
              sendTooltip: l10n.sendMessage,
              onSend: _sendMessage,
              semanticsLabel: l10n.semanticsMessageInput,
              semanticsHint: l10n.messageInputHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.quickGuide,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.askAnything,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
