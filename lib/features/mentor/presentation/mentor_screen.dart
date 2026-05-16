import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/providers/app_providers.dart' show databaseProvider, settingsProvider;
import 'package:studyking/core/providers/llm_providers.dart' show llmServiceProvider;
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart' show masteryGraphServiceProvider;
import 'package:studyking/features/mentor/providers/mentor_providers.dart' show mentorProgressTrackerProvider, mentorModelIdProvider, mentorEngagementNudgeRepoProvider, mentorSessionRepositoryProvider;
import 'package:studyking/features/planner/providers/planner_providers.dart' show plannerServiceProvider;
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/mentor/services/mentor_service.dart';
import 'package:studyking/features/teaching/presentation/widgets/chat_bubble.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/core/widgets/conversation_input.dart';

class MentorScreen extends ConsumerStatefulWidget {
  const MentorScreen({super.key});

  @override
  ConsumerState<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends ConsumerState<MentorScreen> {
  late final MentorService _mentorService;
  late final TextEditingController _textController;
  late final ScrollController _scrollController;
  late final FocusNode _inputFocusNode;
  final List<_ChatMessage> _messages = [];
  bool _isSending = false;
  bool _isInitialized = false;

  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _scrollController = ScrollController();
    _inputFocusNode = FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      _initializeMentor();
    }
  }

  void _initializeMentor() {
    final llmService = ref.read(llmServiceProvider);
    final masteryService = ref.read(masteryGraphServiceProvider);
    final progressTracker = ref.read(mentorProgressTrackerProvider);
    final studentId = StudentIdService().getStudentId();
    _mentorService = MentorService(
      database: ref.read(databaseProvider),
      llmService: llmService,
      masteryService: masteryService,
      progressTracker: progressTracker,
      plannerService: ref.read(plannerServiceProvider),
      nudgeRepo: ref.read(mentorEngagementNudgeRepoProvider),
      sessionRepository: ref.read(mentorSessionRepositoryProvider),
      modelId: ref.read(mentorModelIdProvider),
      studentId: studentId,
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
      content: '${l10n.mentorGreeting}\n\n${l10n.mentorWelcomeBody}',
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
      final l10n = AppLocalizations.of(context)!;
      final idx = _messages.length - 1;
      setState(() {
        _messages[idx] = _ChatMessage(
          message: _messages[idx].message.copyWith(
            content: l10n.errorWithResponse,
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
        final reduceMotion = ref.read(settingsProvider).reduceMotion;
        if (reduceMotion) {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
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
      body: FocusTraversalGroup(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState(l10n)
                  : _buildMessageList(ref.watch(settingsProvider).reduceMotion),
            ),
            FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: ConversationInput(
                controller: _textController,
                focusNode: _inputFocusNode,
                isEnabled: _isInitialized,
                isLoading: _isSending,
                hintText: l10n.askMentorAnything,
                sendTooltip: l10n.send,
                onSend: _sendMessage,
              ),
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

  Widget _buildMessageList(bool reduceMotion) {
    return ListView.builder(
      controller: _scrollController,
      padding: ResponsiveUtils.listPadding(context),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final chatMsg = _messages[index];
        return ChatBubble(message: chatMsg.message, reduceMotion: reduceMotion);
      },
    );
  }

  Future<void> _showProgressReport() async {
    if (!_isInitialized) return;

    try {
      final l10n = AppLocalizations.of(context)!;
      final report = await _mentorService.getProgressReport();
      final buffer = StringBuffer();

      buffer.writeln(l10n.mentorProgressReportTitle);
      buffer.writeln(l10n.mentorOverallAccuracy(
        '${report.accuracy}',
        '${report.correctAttempts}',
        '${report.totalAttempts}',
      ));
      buffer.writeln(l10n.mentorTotalStudyTime(report.totalStudyTimeHours));
      buffer.writeln(l10n.mentorWeeklyActivity('${report.weeklyActivity}'));
      buffer.writeln(l10n.mentorCompletedLessons('${report.completedLessons}'));
      buffer.writeln(l10n.mentorTopicsStudied('${report.topicsStudied}'));

      if (report.weakTopics.isNotEmpty) {
        buffer.writeln(l10n.mentorAreasNeedingAttention);
        for (final topic in report.weakTopics.take(3)) {
          buffer.writeln(l10n.mentorTopicAccuracyEntry(
            topic.topicId,
            (topic.accuracy * 100).round(),
          ));
        }
      }

      if (report.badges.isNotEmpty) {
        buffer.writeln(l10n.mentorBadgesEarned);
        for (final badge in report.badges) {
          buffer.writeln(l10n.mentorBadgeEntry(
            badge['name'] as String,
            badge['description'] as String,
          ));
        }
      }

      if (report.recommendations.isNotEmpty) {
        buffer.writeln(l10n.mentorRecommendations);
        for (final rec in report.recommendations.take(3)) {
          buffer.writeln(l10n.mentorRecommendationEntry(rec['message'] as String));
        }
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          semanticLabel: AppLocalizations.of(ctx)!.progressReport,
          title: Row(
            children: [
              Icon(Icons.analytics,
                  color: Theme.of(ctx).colorScheme.primary),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(ctx)!.progressReport),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(buffer.toString()),
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
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mentorProgressReportError)),
      );
    }
  }
}

class _ChatMessage {
  final ConversationMessage message;
  final bool isComplete;

  _ChatMessage({required this.message, required this.isComplete});
}
