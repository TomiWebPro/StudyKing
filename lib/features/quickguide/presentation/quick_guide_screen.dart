import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../core/services/llm/llm_chat_service.dart';
import '../../../core/data/models/conversation_message_model.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/logger.dart';
import '../../teaching/presentation/tutor_screen.dart';

class QuickGuideScreen extends StatefulWidget {
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
  State<QuickGuideScreen> createState() => _QuickGuideScreenState();
}

class _QuickGuideScreenState extends State<QuickGuideScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  final Uuid _uuid = const Uuid();
  final Logger _logger = const Logger('QuickGuide');
  final ConversationMemory _memory = ConversationMemory(maxTurns: 30);

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
    return LlmService(
      config: const LlmConfiguration(
        provider: LlmProvider.openRouter,
        apiKey: '',
      ),
    );
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
        final effectiveSystem = widget.systemPrompt ??
            'You are StudyKing Quick Guide, a helpful AI study assistant. '
                'Provide concise, educational answers. Help with explanations, quiz questions, '
                'and math problems. Respond conversationally.';

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
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.quickGuide),
        actions: [
          if (_hasInteracted)
            Semantics(
              label: 'Clear conversation',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Clear conversation',
                onPressed: _clearConversation,
              ),
            ),
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
            if (_showSuggestions && !_hasInteracted)
              _buildModeNavigation(context),
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState(l10n)
                  : _buildMessageList(context, l10n),
            ),
            AnimatedOpacity(
              opacity: _showSuggestions && !_hasInteracted ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: _buildSuggestedPrompts(context),
            ),
            _buildTypingIndicator(colorScheme, l10n),
            _buildMessageComposer(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildModeNavigation(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: ResponsiveUtils.listPadding(context),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a study mode',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildModeCard(
                      context,
                      icon: Icons.smart_toy,
                      title: 'AI Tutor',
                      subtitle: 'Interactive conversational lessons',
                      color: colorScheme.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TutorScreen(
                              topicId: '',
                              topicTitle: '',
                              subjectId: '',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModeCard(
                      context,
                      icon: Icons.auto_awesome,
                      title: 'Mentor',
                      subtitle: 'Personal study assistant & planner',
                      color: colorScheme.secondary,
                      onTap: () {
                        Navigator.pushNamed(context, '/mentor');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: '$title: $subtitle',
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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

  Widget _buildMessageList(BuildContext context, AppLocalizations l10n) {
    return ListView.builder(
      controller: _scrollController,
      padding: ResponsiveUtils.listPadding(context),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isUser = message.role == MessageRole.student;
        return Semantics(
          label: isUser
              ? l10n.semanticsYouSaid(message.content)
              : l10n.semanticsQuickGuideSaid(message.content),
          child: Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: EdgeInsets.only(
                  bottom: ResponsiveUtils.verticalSpacing(context)),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.horizontalSpacing(context),
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content +
                        (message.isStreaming && message.content.isNotEmpty
                            ? '▌'
                            : ''),
                    style: TextStyle(
                      color: isUser
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  if (message.isStreaming && message.content.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SizedBox(
                        width: 20,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
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
            padding: EdgeInsets.only(
                bottom: ResponsiveUtils.verticalSpacing(context) * 0.75),
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

  Widget _buildTypingIndicator(ColorScheme colorScheme, AppLocalizations l10n) {
    return Semantics(
      liveRegion: true,
      child: AnimatedOpacity(
        opacity: _isStreaming ? 1.0 : 0.0,
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
    );
  }

  Widget _buildMessageComposer(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true):
            _sendMessage,
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
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
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
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: l10n.sendMessage,
                button: true,
                child: IconButton.filled(
                  icon: _isStreaming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  onPressed: _isStreaming ? null : _sendMessage,
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
