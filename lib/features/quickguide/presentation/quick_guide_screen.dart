import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/core/providers/llm_providers.dart' show llmServiceProvider;
import 'package:studyking/core/constants/app_constants.dart' show defaultModelForProvider, Timeouts;
import 'package:studyking/core/providers/app_providers.dart' show llmProviderProvider, selectedModelProvider, settingsProvider;
import 'package:studyking/core/widgets/conversation_input.dart';
import 'package:studyking/core/widgets/empty_state_widget.dart';
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
    this.defaultModelId = '',
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
        final l10n = AppLocalizations.of(context)!;
        await _showNoApiKeyMessage(l10n);
        if (mounted) {
          final idx = _messages.length - 1;
          setState(() {
            _messages[idx] = _messages[idx].copyWith(isStreaming: false);
          });
        }
        _isStreaming = false;
        return;
      }

      final l10n = AppLocalizations.of(context)!;
      final effectiveSystem = widget.systemPrompt ?? l10n.quickGuideSystemPrompt;
      final savedModel = ref.read(selectedModelProvider);
      final provider = ref.read(llmProviderProvider);
      final effectiveModelId = savedModel.isNotEmpty
          ? savedModel
          : (widget.defaultModelId.isNotEmpty
              ? widget.defaultModelId
              : defaultModelForProvider(provider));

      await for (final chunk in llm.chatStream(
        message: text,
        modelId: effectiveModelId,
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
    final lower = text.toLowerCase();
    if (lower.contains('explain')) return l10n.fallbackExplainResponse;
    if (lower.contains('quiz') || lower.contains('question')) return l10n.fallbackQuizResponse;
    if (lower.contains('math') || lower.contains('calculate')) return l10n.fallbackMathResponse;
    return l10n.fallbackGeneralResponse;
  }

  Future<void> _showNoApiKeyMessage(AppLocalizations l10n) async {
    final idx = _messages.length - 1;
    if (mounted) {
      setState(() {
        _messages[idx] = _messages[idx].copyWith(
          content: l10n.apiKeyNeeded,
          isStreaming: false,
        );
      });
    }
    final configureMsg = ConversationMessage(
      id: _uuid.v4(),
      sessionId: 'quickguide',
      role: MessageRole.tutor,
      type: MessageType.text,
      content: '${l10n.pleaseConfigureApiKey}\n\n[${l10n.configureNow}](/settings/api-config)',
      timestamp: DateTime.now(),
    );
    setState(() => _messages.add(configureMsg));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final reduceMotion = ref.read(settingsProvider).reduceMotion;
        if (reduceMotion) {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Timeouts.ms100,
            curve: Curves.easeOut,
          );
        }
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
    final theme = Theme.of(context);
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
        child: FocusTraversalGroup(
          child: Column(
          children: [
            if (_getLlmService().config.apiKey.isEmpty)
              _buildApiKeyBanner(l10n, theme),
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
            if (_showSuggestions && !_hasInteracted)
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                ),
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
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return EmptyStateWidget(
      icon: Icons.auto_awesome,
      title: l10n.quickGuide,
      subtitle: l10n.askAnything,
    );
  }

  Widget _buildApiKeyBanner(AppLocalizations l10n, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Row(
        children: [
          Icon(Icons.key, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.apiKeyRequired,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.apiConfig),
            child: Text(l10n.configureNow, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
