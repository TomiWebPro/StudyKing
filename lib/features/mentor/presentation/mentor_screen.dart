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
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/mentor/services/mentor_service.dart';
import 'package:studyking/features/teaching/presentation/widgets/chat_bubble.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/core/widgets/conversation_input.dart';
import 'package:studyking/features/mentor/data/models/chat_message_data.dart';

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
  final List<ChatMessageData> _messages = [];
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

  Future<void> _initializeMentor() async {
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

    await _mentorService.initialize();

    final history = _mentorService.memory.getHistory();
    final loadedMessages = history
        .where((m) => m.role == MessageRole.mentor || m.role == MessageRole.student)
        .map((m) => ChatMessageData(message: m, isComplete: true))
        .toList();

    if (mounted) {
      setState(() {
        _isInitialized = true;
        _messages.addAll(loadedMessages);
      });
      if (loadedMessages.isEmpty) {
        _sendWelcomeMessage();
      }
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
      _messages.add(ChatMessageData(
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
      _messages.add(ChatMessageData(message: userMsg, isComplete: true));
      _messages.add(ChatMessageData(message: mentorMsg, isComplete: false));
      _isSending = true;
    });
    _scrollToBottom();

    final buffer = StringBuffer();
    try {
      await for (final chunk in _mentorService.chat(text)) {
        buffer.write(chunk);
        final idx = _messages.length - 1;
        setState(() {
          _messages[idx] = ChatMessageData(
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
        _messages[idx] = ChatMessageData(
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
        _messages[idx] = ChatMessageData(
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
            size: ResponsiveUtils.emptyStateIconSize(context),
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.mentorGreeting,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: ResponsiveUtils.screenPadding(context),
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
      final localeName = l10n.localeName;

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) {
          final theme = Theme.of(ctx);
          final l10n = AppLocalizations.of(ctx)!;
          return AlertDialog(
            semanticLabel: l10n.progressReport,
            title: Row(
              children: [
                Icon(Icons.analytics,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.progressReport),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    headingLevel: 3,
                    child: _reportSectionHeader(
                      ctx,
                      Icons.track_changes,
                      l10n.mentorAccuracy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (report.accuracy / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        report.accuracy >= 70
                            ? theme.colorScheme.primary
                            : report.accuracy >= 40
                                ? theme.colorScheme.tertiary
                                : theme.colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatPercent(report.accuracy, localeName)} '
                    '(${formatDecimal(report.correctAttempts.toDouble(), localeName)}/'
                    '${formatDecimal(report.totalAttempts.toDouble(), localeName)} '
                    '${l10n.mentorCompletedLessons('').split(':').first.trim().toLowerCase()})',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  _reportStatRow(ctx, Icons.timer_outlined,
                      l10n.mentorTotalStudyTime(formatDecimal(
                          report.totalStudyTimeHours.toDouble(), localeName,
                          minFractionDigits: 1, maxFractionDigits: 1))),
                  const SizedBox(height: 4),
                  _reportStatRow(ctx, Icons.trending_up,
                      l10n.mentorWeeklyActivity(
                          formatDecimal(report.weeklyActivity.toDouble(), localeName))),
                  const SizedBox(height: 4),
                  _reportStatRow(ctx, Icons.check_circle_outline,
                      l10n.mentorCompletedLessons(
                          formatDecimal(report.completedLessons.toDouble(), localeName))),
                  const SizedBox(height: 4),
                  _reportStatRow(ctx, Icons.book_outlined,
                      l10n.mentorTopicsStudied(
                          formatDecimal(report.topicsStudied.toDouble(), localeName))),
                  if (report.weakTopics.isNotEmpty) ...[
                    const Divider(height: 24),
                    Semantics(
                      headingLevel: 3,
                      child: _reportSectionHeader(
                        ctx,
                        Icons.warning_amber,
                        l10n.weakAreas,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...report.weakTopics.take(3).map((topic) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.error_outline,
                              color: theme.colorScheme.error, size: 20),
                          title: Text(topic.topicId,
                              style: theme.textTheme.bodyMedium),
                          trailing: Text(
                            formatPercent(topic.accuracy * 100, localeName),
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            Navigator.pushNamed(
                              context,
                              AppRoutes.practiceSession,
                              arguments: PracticeSessionArgs(
                                subjectId: '',
                                topicId: topic.topicId,
                              ),
                            );
                          },
                        )),
                  ],
                  if (report.badges.isNotEmpty) ...[
                    const Divider(height: 24),
                    Semantics(
                      headingLevel: 3,
                      child: _reportSectionHeader(
                        ctx,
                        Icons.emoji_events,
                        l10n.mentorBadges,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: report.badges.map((badge) => Semantics(
                        label: badge['name'] as String,
                        child: Chip(
                          avatar: Icon(Icons.emoji_events,
                              size: 18, color: theme.colorScheme.secondary),
                          label: Text(badge['name'] as String,
                              style: theme.textTheme.bodySmall),
                        ),
                      )).toList(),
                    ),
                  ],
                  if (report.recommendations.isNotEmpty) ...[
                    const Divider(height: 24),
                    Semantics(
                      headingLevel: 3,
                      child: _reportSectionHeader(
                        ctx,
                        Icons.lightbulb_outline,
                        l10n.mentorRecommendationsSection,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...report.recommendations.take(3).map((rec) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• ',
                                  style: theme.textTheme.bodyMedium),
                              Expanded(
                                child: Text(
                                  rec['message'] as String,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.close),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.mentorProgressReportError)),
      );
    }
  }

  Widget _reportSectionHeader(BuildContext context, IconData icon, String title) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _reportStatRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
