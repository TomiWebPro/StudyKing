import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/utils/date_utils.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider;
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/services/voice_service.dart';
import 'package:studyking/features/mentor/providers/mentor_providers.dart' show mentorServiceProvider;
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/mentor/services/mentor_service.dart';
import 'package:studyking/features/mentor/data/models/mentor_action.dart';
import 'package:studyking/features/mentor/services/mentor_schedule_handler.dart';
import 'package:studyking/features/teaching/presentation/widgets/chat_bubble.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/core/widgets/conversation_input.dart';
import 'package:studyking/core/widgets/loading_indicator.dart';
import 'package:studyking/features/mentor/data/models/chat_message_data.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';

class MentorScreen extends ConsumerStatefulWidget {
  const MentorScreen({super.key});

  @override
  ConsumerState<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends ConsumerState<MentorScreen> {
  static final _logger = const Logger('MentorScreen');
  late final MentorService _mentorService;
  late final TextEditingController _textController;
  late final ScrollController _scrollController;
  late final FocusNode _inputFocusNode;
  final List<ChatMessageData> _messages = [];
  StreamSubscription<String>? _voiceSubscription;
  bool _isSending = false;
  bool _isInitialized = false;
  bool _initError = false;
  bool _isRetrying = false;
  String _initErrorMessage = '';
  String? _pendingRetryText;
  MentorAction? _suggestedAction;
  bool _suggestedActionError = false;
  bool _didInit = false;
  List<Session> _upcomingLessons = [];
  bool _isLoadingUpcoming = false;

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

  Future<void> _loadUnreadNudges() async {
    try {
      final recentNudges = await _mentorService.getRecentNudges(limit: 5);
      if (recentNudges.isNotEmpty && mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          final nudgeMessages = recentNudges.map((n) => ChatMessageData(
            message: ConversationMessage(
              id: 'nudge_${n.id}',
              sessionId: 'mentor',
              role: MessageRole.system,
              type: MessageType.text,
              content: n.message,
              timestamp: DateTime.now(),
            ),
            isComplete: true,
          )).toList();
          if (nudgeMessages.isNotEmpty) {
            _messages.addAll([
              ChatMessageData(
                message: ConversationMessage(
                  id: 'while_away',
                  sessionId: 'mentor',
                  role: MessageRole.system,
                  type: MessageType.text,
                  content: l10n.whileYouWereAway,
                  timestamp: DateTime.now(),
                ),
                isComplete: true,
              ),
              ...nudgeMessages,
              ChatMessageData(
                message: ConversationMessage(
                  id: 'while_away_end',
                  sessionId: 'mentor',
                  role: MessageRole.system,
                  type: MessageType.text,
                  content: l10n.endOfPendingMessages,
                  timestamp: DateTime.now(),
                ),
                isComplete: true,
              ),
            ]);
          }
        });
      }
    } catch (e) {
      _logger.w('Failed to load pending messages', e);
    }
  }

  Future<void> _initializeMentor() async {
    try {
      final studentId = ref.read(studentIdServiceProvider).getStudentId();
      _mentorService = ref.read(mentorServiceProvider(studentId));

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
        await _loadUnreadNudges();
        if (loadedMessages.isEmpty && _messages.isEmpty) {
          _sendWelcomeMessage();
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _refreshCheck());
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadUpcomingLessons());
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _initError = true;
          _isRetrying = false;
          _initErrorMessage = l10n.mentorInitFailed('');
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

  void _clearConversation() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearConversation),
        content: Text(l10n.clearConversation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _messages.clear();
                _mentorService.memory.clear();
              });
              _sendWelcomeMessage();
            },
            child: Text(l10n.clearConversation),
          ),
        ],
      ),
    );
  }

  void _refreshCheck() {
    _loadSuggestedAction();
  }

  Future<void> _loadSuggestedAction() async {
    try {
      final action = await _mentorService.suggestNextAction();
      if (mounted) {
        setState(() {
          _suggestedAction = action;
          _suggestedActionError = false;
        });
      }
    } catch (e) {
      _logger.w('Failed to load suggested action', e);
      if (mounted) {
        setState(() => _suggestedActionError = true);
      }
    }
  }

  Future<void> _loadUpcomingLessons() async {
    setState(() => _isLoadingUpcoming = true);
    try {
      final lessons = await _mentorService.getUpcomingLessons();
      if (mounted) {
        setState(() {
          _upcomingLessons = lessons;
          _isLoadingUpcoming = false;
        });
      }
    } catch (e) {
      _logger.w('Failed to load upcoming lessons', e);
      if (mounted) {
        setState(() => _isLoadingUpcoming = false);
      }
    }
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
      _pendingRetryText = text;
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

  Future<void> _retryLastMessage() async {
    final text = _pendingRetryText;
    if (text == null || text.isEmpty || _isSending) return;
    _pendingRetryText = null;
    _textController.text = text;
    _sendMessage();
  }

  Future<void> _handlePostChatIntents() async {
    try {
      final schedule = _mentorService.pendingScheduleProposal;
      final plan = _mentorService.pendingPlanProposal;
      final rescheduleSessionId = _mentorService.pendingRescheduleSessionId;

      if (schedule != null) {
        _mentorService.clearPendingSchedule();
        if (!mounted) return;
        await _showScheduleConfirmationDialog(schedule);
      } else if (rescheduleSessionId != null) {
        _mentorService.clearPendingReschedule();
        if (!mounted) return;
        final result = await _mentorService.suggestReschedule(rescheduleSessionId);
        if (mounted) {
          setState(() {
            _messages.add(ChatMessageData(
              message: ConversationMessage(
                id: 'resched_${DateTime.now().millisecondsSinceEpoch}',
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
      } else if (plan != null) {
        _mentorService.clearPendingPlan();
        if (!mounted) return;
        final l10nCtx = AppLocalizations.of(context)!;
        if (plan.goal != null) {
          final created = await _showRoadmapConfirmationDialog(plan, l10nCtx);
          if (created) return;
        }
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
      _loadUpcomingLessons();
    } catch (e) {
      _logger.w('Failed to handle post-chat intents', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorOccurred)),
        );
      }
    }
  }

  Future<void> _showScheduleConfirmationDialog(ScheduleProposal proposal) async {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = localizedDateTime(proposal.proposedTime, l10n.localeName);
    var editableDuration = proposal.durationMinutes;

    final resultDuration = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.scheduleALesson),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.scheduleTimeLabel(dateStr)),
              const SizedBox(height: 8),
              MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.scheduleDurationLabel(l10n.minutesValue(editableDuration))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          tooltip: l10n.decreaseDuration,
                          onPressed: editableDuration > 5
                              ? () => setDialogState(() => editableDuration -= 5)
                              : null,
                        ),
                        Expanded(
                          child: Slider(
                            value: editableDuration.toDouble(),
                            min: 5,
                            max: 180,
                            divisions: 35,
                            label: l10n.minutesValue(editableDuration),
                            onChanged: (v) => setDialogState(
                              () => editableDuration = v.round(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: l10n.increaseDuration,
                          onPressed: editableDuration < 180
                              ? () => setDialogState(() => editableDuration += 5)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(l10n.mentorScheduleTopic(proposal.topicTitle)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(editableDuration),
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    );

    if (resultDuration != null && mounted) {
      final updatedProposal = ScheduleProposal(
        topicTitle: proposal.topicTitle,
        topicId: proposal.topicId,
        subjectId: proposal.subjectId,
        proposedTime: proposal.proposedTime,
        durationMinutes: resultDuration,
      );
      final result = await _mentorService.confirmSchedule(updatedProposal);
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

  Future<bool> _showRoadmapConfirmationDialog(PlanProposal plan, AppLocalizations l10nCtx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10nCtx.createRoadmap),
        content: Text(l10nCtx.mentorPlanDaysPrompt(plan.days)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10nCtx.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10nCtx.createRoadmap),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(plannerProvider.notifier).createRoadmap(
        goal: plan.goal!,
        days: plan.days,
        l10n: l10nCtx,
        subjectId: plan.subjectId,
      );
      final msgObj = ConversationMessage(
        id: 'roadmap_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: 'mentor',
        role: MessageRole.mentor,
        type: MessageType.text,
        content: l10nCtx.roadmapCreated(plan.goal!),
        timestamp: DateTime.now(),
      );
      if (mounted) {
        setState(() {
          _messages.add(ChatMessageData(message: msgObj, isComplete: true));
        });
        _scrollToBottom();
      }
      return true;
    }
    return false;
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

  Widget _buildVoiceButton() {
    final voiceService = ref.read(voiceServiceProvider);
    final l10n = AppLocalizations.of(context)!;
    final isAvailable = voiceService.isAvailable;

    return IconButton(
      icon: Icon(
        voiceService.isListening ? Icons.mic : Icons.mic_none,
        color: voiceService.isListening
            ? Theme.of(context).colorScheme.error
            : null,
      ),
      tooltip: isAvailable ? l10n.voiceInput : l10n.micPermissionDenied,
      onPressed: isAvailable
          ? () {
              if (voiceService.isListening) {
                voiceService.stopListening();
              } else {
                voiceService.startListening(localeName: l10n.localeName);
                _voiceSubscription?.cancel();
                _voiceSubscription = voiceService.transcribedText.listen((text) {
                  _textController.text = text;
                  _textController.selection = TextSelection.fromPosition(
                    TextPosition(offset: text.length),
                  );
                });
              }
            }
          : null,
    );
  }

  @override
  void dispose() {
    _voiceSubscription?.cancel();
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: l10n.moreOptions,
            onSelected: (value) {
              if (value == 'clear') {
                _clearConversation();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: const Icon(Icons.refresh),
                  title: Text(l10n.clearConversation),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: FocusTraversalGroup(
        child: Column(
          children: [
            if (_initError)
              _buildInitErrorCard(l10n)
            else if (!_isInitialized)
              const LoadingIndicator()
            else ...[
              if (_suggestedAction != null)
                _buildSuggestedActionCard(l10n)
              else if (_suggestedActionError)
                _buildSuggestedActionError(l10n),
              if (_pendingRetryText != null)
                _buildRetryBanner(l10n),
              if (!_isLoadingUpcoming && _upcomingLessons.isNotEmpty)
                _buildRescheduleSection(l10n),
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
                leading: _buildVoiceButton(),
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
                          ? ResponsiveUtils.loaderInTouchTarget(size: 18)
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

  Widget _buildSuggestedActionError(AppLocalizations l10n) {
    return Padding(
      padding: ResponsiveUtils.screenPadding(context),
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: ResponsiveUtils.cardPadding(context),
          child: Row(
            children: [
              Icon(Icons.error_outline,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.errorOccurred,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _suggestedActionError = false;
                  });
                  _loadSuggestedAction();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRetryBanner(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cs.errorContainer,
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: cs.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.messageFailedRetry,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onErrorContainer,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _retryLastMessage,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Future<void> _onRescheduleLesson(Session lesson) async {
    try {
      final result = await _mentorService.suggestReschedule(lesson.id);
      if (mounted) {
        setState(() {
          _messages.add(ChatMessageData(
            message: ConversationMessage(
              id: 'resched_${DateTime.now().millisecondsSinceEpoch}',
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
    } catch (e) {
      _logger.w('Failed to suggest reschedule', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorOccurred)),
        );
      }
    }
  }

  Widget _buildRescheduleSection(AppLocalizations l10n) {
    if (_upcomingLessons.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: ResponsiveUtils.screenPadding(context),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.event_repeat,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.upcomingLessons,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._upcomingLessons.take(3).map((lesson) {
                final title = lesson.tutorMetadata?.topicTitle
                    ?? lesson.topicId
                    ?? l10n.unknown;
                final timeStr = localizedDateTime(lesson.startTime, l10n.localeName);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$title — $timeStr',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _onRescheduleLesson(lesson),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: Text(l10n.rescheduleLesson),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                );
              }),
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
        return _AnimatedMessageItem(
          key: ValueKey(chatMsg.message.id),
          reduceMotion: reduceMotion,
          child: ChatBubble(message: chatMsg.message, reduceMotion: reduceMotion),
        );
      },
    );
  }

  Future<void> _showProgressReport() async {
    if (!_isInitialized) return;

    final l10n = AppLocalizations.of(context)!;
    try {
      final localeName = AppLocalizations.of(context)!.localeName;
      final topicRepo = ref.read(topicRepositoryProvider);
      final report = await _mentorService.getProgressReport();

      final topicTitles = <String, String>{};
      for (final wt in report.weakTopics) {
        final result = await topicRepo.get(wt.topicId);
        topicTitles[wt.topicId] = result.data?.title ?? l10n.unknown;
      }

      if (!mounted) return;
      try {
        Navigator.of(context).pop();
      } catch (e) {
        _logger.w('Failed to pop navigator in progress report', e);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.mentorProgressReportError)),
        );
        return;
      }

      await Future.delayed(const Duration(milliseconds: 50));

      if (!mounted) return;
      try {
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
                physics: const AlwaysScrollableScrollPhysics(),
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
                      '${l10n.mentorCompletedLessons('').split(':').first})',
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
                            title: Text(topicTitles[topic.topicId] ?? l10n.unknown,
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
          SnackBar(content: Text(l10n.mentorProgressReportError)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      try {
        Navigator.of(context).pop();
      } catch (e) {
        _logger.w('Failed to pop navigator in error handler', e);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.mentorProgressReportError)),
        );
      }
    }
  }

  Widget _reportSectionHeader(BuildContext context, IconData icon, String title) {
    final theme = Theme.of(context);
    return MergeSemantics(
      child: Row(
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
      ),
    );
  }

  Widget _reportStatRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return MergeSemantics(
      child: Row(
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
      ),
    );
  }
}

class _AnimatedMessageItem extends StatefulWidget {
  final Widget child;
  final bool reduceMotion;

  const _AnimatedMessageItem({
    super.key,
    required this.child,
    this.reduceMotion = false,
  });

  @override
  State<_AnimatedMessageItem> createState() => _AnimatedMessageItemState();
}

class _AnimatedMessageItemState extends State<_AnimatedMessageItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
      _animation = CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      );
      _controller.forward();
    }
  }

  @override
  void dispose() {
    if (!widget.reduceMotion) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reduceMotion) return widget.child;
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}
