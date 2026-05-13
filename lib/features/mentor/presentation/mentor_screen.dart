import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/llm/llm_chat_service.dart';
import '../../../core/services/mastery_graph_service.dart';
import '../../../core/services/study_progress_tracker.dart';
import '../../../core/data/repositories/attempt_repository.dart';
import '../../../core/widgets/conversation_input.dart';
import 'package:studyking/core/providers/app_providers.dart' show database;
import '../../../l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';
import '../services/mentor_service.dart';
import '../../teaching/presentation/widgets/chat_bubble.dart';
import '../../../core/data/models/conversation_message_model.dart';

class MentorScreen extends StatefulWidget {
  const MentorScreen({super.key});

  @override
  State<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends State<MentorScreen> {
  late final MentorService _mentorService;
  late final TextEditingController _textController;
  late final ScrollController _scrollController;
  late final FocusNode _inputFocusNode;
  final List<_ChatMessage> _messages = [];
  bool _isSending = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _scrollController = ScrollController();
    _inputFocusNode = FocusNode();
    _initializeMentor();
  }

  void _initializeMentor() {
    final llmConfig = LlmConfiguration(
      provider: LlmProvider.openRouter,
      apiKey: '',
    );
    final llmService = LlmService(config: llmConfig);
    final masteryService = MasteryGraphService();
    final progressTracker = StudyProgressTracker(
      attemptRepo: AttemptRepository(),
      masteryService: masteryService,
    );

    _mentorService = MentorService(
      database: database,
      llmService: llmService,
      masteryService: masteryService,
      progressTracker: progressTracker,
      modelId: 'openai/gpt-4o-mini',
      studentId: 'anonymous',
    );

    if (mounted) {
      setState(() => _isInitialized = true);
      _sendWelcomeMessage();
    }
  }

  Future<void> _sendWelcomeMessage() async {
    final l10n = AppLocalizations.of(context)!;
    final welcome = ConversationMessage(
      id: 'welcome',
      sessionId: 'mentor',
      role: MessageRole.mentor,
      type: MessageType.text,
      content: '''$l10n.mentorGreeting

I can help you with:
• Scheduling and rescheduling lessons
• Reviewing your study progress
• Planning long-term study goals
• Motivation and encouragement
• Deciding what to study next

How can I help you today?''',
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(_ChatMessage(
        message: welcome,
        isComplete: true,
      ));
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();

    final userMsg = ConversationMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: 'mentor',
      role: MessageRole.student,
      type: MessageType.text,
      content: text,
      timestamp: DateTime.now(),
    );

    final mentorMsg = ConversationMessage(
      id: 'mentor_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: 'mentor',
      role: MessageRole.mentor,
      type: MessageType.text,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    setState(() {
      _messages.add(_ChatMessage(message: userMsg, isComplete: true));
      _messages.add(_ChatMessage(message: mentorMsg, isComplete: false));
      _isSending = true;
    });
    _scrollToBottom();

    final buffer = StringBuffer();
    try {
      await for (final chunk in _mentorService.chat(text)) {
        buffer.write(chunk);
        final idx = _messages.length - 1;
        setState(() {
          _messages[idx] = _ChatMessage(
            message: _messages[idx].message.copyWith(
              content: buffer.toString(),
              isStreaming: true,
            ),
            isComplete: false,
          );
        });
        _scrollToBottom();
      }

      final idx = _messages.length - 1;
      setState(() {
        _messages[idx] = _ChatMessage(
          message: _messages[idx].message.copyWith(
            content: buffer.toString(),
            isStreaming: false,
          ),
          isComplete: true,
        );
        _isSending = false;
      });
    } catch (e) {
      final idx = _messages.length - 1;
      setState(() {
        _messages[idx] = _ChatMessage(
          message: _messages[idx].message.copyWith(
            content: 'Sorry, I encountered an error. Please try again.',
            isStreaming: false,
          ),
          isComplete: true,
        );
        _isSending = false;
      });
    }
    _scrollToBottom();
    _inputFocusNode.requestFocus();
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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Flexible(child: Text(l10n.mentorGreeting)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: l10n.progressReport,
            onPressed: _showProgressReport,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(l10n)
                : _buildMessageList(),
          ),
          ConversationInput(
            controller: _textController,
            focusNode: _inputFocusNode,
            isEnabled: _isInitialized,
            isLoading: _isSending,
            hintText: l10n.askMentorAnything,
            sendTooltip: l10n.send,
            onSend: _sendMessage,
          ),
        ],
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
            l10n.mentorGreeting,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              l10n.mentorSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: ResponsiveUtils.listPadding(context),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final chatMsg = _messages[index];
        return ChatBubble(message: chatMsg.message);
      },
    );
  }

  Future<void> _showProgressReport() async {
    if (!_isInitialized) return;

    try {
      final report = await _mentorService.getProgressReport();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.analytics,
                  color: Theme.of(ctx).colorScheme.primary),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(ctx)!.progressReport),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(report),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppLocalizations.of(ctx)!.close),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorOccurred)),
      );
    }
  }
}

class _ChatMessage {
  final ConversationMessage message;
  final bool isComplete;

  _ChatMessage({required this.message, required this.isComplete});
}
