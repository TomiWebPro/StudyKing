import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/providers/app_providers.dart' show databaseProvider, settingsProvider;
import 'package:studyking/core/providers/llm_providers.dart' show llmServiceProvider;
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart' show masteryGraphServiceProvider;
import 'package:studyking/features/mentor/providers/mentor_providers.dart' show mentorProgressTrackerProvider, mentorModelIdProvider, mentorEngagementNudgeRepoProvider, mentorSessionRepositoryProvider;
import 'package:studyking/features/planner/providers/planner_providers.dart' show plannerServiceProvider;
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/mentor/services/mentor_service.dart';
import 'package:studyking/features/mentor/data/models/mentor_action.dart';
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
  bool _initError = false;
  bool _isRetrying = false;
  String _initErrorMessage = '';
  MentorAction? _suggestedAction;

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
    try {
      final llmService = ref.read(llmServiceProvider);
      final masteryService = ref.read(masteryGraphServiceProvider);
      final progressTracker = ref.read(mentorProgressTrackerProvider);
      final studentId = StudentIdService().getStudentId();
      final l10n = AppLocalizations.of(context)!;
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
        localeName: l10n.localeName,
      );

      await _mentorService.initialize();

      final history = _mentorService.memory.getHistory();
      final loadedMessages = history
          .where((m) => m.role == MessageRole.mentor || m.role == MessageRole.student || m.role == MessageRole.system)
          .map((m) => ChatMessageData(message: m, isComplete: true))
          .toList();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _initError = false;
          _isRetrying = false;
          _messages.addAll(loadedMessages);
        });
        if (loadedMessages.isEmpty) {
          _sendWelcomeMessage();
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _refreshCheck());
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _initError = true;
          _isRetrying = false;
          _initErrorMessage = l10n.mentorInitFailed(e.toString());
        });
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
      content: l10n.mentorWelcomeFull(l10n.mentorGreeting, l10n.mentorWelcomeBody),
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(ChatMessageData(
        message: welcome,
        isComplete: true,
      ));
    });
  }

  void _refreshCheck() {
    _loadSuggestedAction();
  }

  Future<void> _loadSuggestedAction() async {
    try {
      final action = await _mentorService.suggestNextAction();
      if (mounted) {
        setState(() => _suggestedAction = action);
      }
    } catch (_) {}
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

    if (!_mentorService.hasApiKey) {
      final l10n = AppLocalizations.of(context)!;
      final idx = _messages.length - 1;
      setState(() {
        _messages[idx] = ChatMessageData(
          message: _messages[idx].message.copyWith(
            content: '${l10n.mentorApiKeyMissing} ${l10n.goToSettings}',
            isStreaming: false,
          ),
          isComplete: true,
        );
        _isSending = false;
      });
      _scrollToBottom();
      _inputFocusNode.requestFocus();
      return;
    }

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
    await _handlePostChatIntents();
  }

  Future<void> _handlePostChatIntents() async {
    try {
      final schedule = _mentorService.pendingScheduleProposal;
      final plan = _mentorService.pendingPlanProposal;

      if (schedule != null) {
        _mentorService.clearPendingSchedule();
        if (!mounted) return;
        await _showScheduleConfirmationDialog(schedule);
      } else if (plan != null) {
        _mentorService.clearPendingPlan();
        final msg = _mentorService.planDaysMessage(plan.days);
        if (!mounted) return;
        final msgObj = ConversationMessage(
          id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
          sessionId: 'mentor',
          role: MessageRole.mentor,
          type: MessageType.text,
          content: msg,
          timestamp: DateTime.now(),
        );
        setState(() {
          _messages.add(ChatMessageData(message: msgObj, isComplete: true));
        });
        _scrollToBottom();
      }

      final nudges = await _mentorService.checkWellbeingAndGenerateNudges();
      if (nudges.isNotEmpty && mounted) {
        setState(() {
          for (final nudge in nudges) {
            _messages.add(ChatMessageData(
              message: ConversationMessage(
                id: 'nudge_${DateTime.now().millisecondsSinceEpoch}',
                sessionId: 'mentor',
                role: MessageRole.mentor,
                type: MessageType.text,
                content: nudge,
                timestamp: DateTime.now(),
              ),
              isComplete: true,
            ));
          }
        });
        _scrollToBottom();
      }
      _loadSuggestedAction();
    } catch (_) {}
  }

  Future<void> _showScheduleConfirmationDialog(ScheduleProposal proposal) async {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat.yMd(l10n.localeName).add_Hm().format(proposal.proposedTime.toLocal());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.scheduleALesson),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.time}: $dateStr'),
            const SizedBox(height: 8),
            Text('${l10n.duration}: ${proposal.durationMinutes} min'),
            const SizedBox(height: 8),
            Text('Topic: ${proposal.topicTitle}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await _mentorService.confirmSchedule(proposal);
      if (mounted) {
        setState(() {
          _messages.add(ChatMessageData(
            message: ConversationMessage(
              id: 'sched_${DateTime.now().millisecondsSinceEpoch}',
              sessionId: 'mentor',
              role: MessageRole.mentor,
              type: MessageType.text,
              content: result,
              timestamp: DateTime.now(),
            ),
            isComplete: true,
          ));
        });
        _scrollToBottom();
      }
    }
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
            if (_initError)
              _buildInitErrorCard(l10n)
            else ...[
              if (_suggestedAction != null)
                _buildSuggestedActionCard(l10n),
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState(l10n)
                    : _buildMessageList(ref.watch(settingsProvider).reduceMotion),
              ),
            ],
            FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: ConversationInput(
                controller: _textController,
                focusNode: _inputFocusNode,
                isEnabled: _isInitialized,
                isLoading: _isSending,
                hintText: _initError ? l10n.mentorInitFailedHint : l10n.askMentorAnything,
                sendTooltip: l10n.send,
                onSend: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitErrorCard(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: ResponsiveUtils.screenPadding(context),
        child: Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _initErrorMessage,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.apiConfig),
                      icon: const Icon(Icons.settings),
                      label: Text(l10n.goToSettings),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isRetrying
                          ? null
                          : () {
                              setState(() {
                                _initError = false;
                                _initErrorMessage = '';
                                _isRetrying = true;
                              });
                              _initializeMentor();
                            },
                      icon: _isRetrying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(_isRetrying ? l10n.retrying : l10n.retry),
                    ),
                  ],
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

  Widget _buildSuggestedActionCard(AppLocalizations l10n) {
    return Padding(
      padding: ResponsiveUtils.screenPadding(context),
      child: Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Padding(
          padding: ResponsiveUtils.cardPadding(context),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.onSecondaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _suggestedAction!.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.dismiss,
                onPressed: () => setState(() => _suggestedAction = null),
              ),
            ],
          ),
        ),
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
      final topicRepo = ref.read(topicRepositoryProvider);

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
                          onTap: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            Navigator.of(ctx).pop();
                            try {
                              final topicResult = await topicRepo.get(topic.topicId);
                              final subjectId = topicResult.data?.subjectId;
                              if (subjectId != null && subjectId.isNotEmpty) {
                                if (!context.mounted) return;
                                navigator.pushNamed(
                                  AppRoutes.practiceSession,
                                  arguments: PracticeSessionArgs(
                                    subjectId: subjectId,
                                    topicId: topic.topicId,
                                  ),
                                );
                              } else {
                                if (!context.mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(content: Text(l10n.unableToResolveSubject)),
                                );
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              messenger.showSnackBar(
                                SnackBar(content: Text(l10n.unableToResolveSubject)),
                              );
                            }
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
                              Text(l10n.mentorBulletPoint,
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
