import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/settings/data/models/settings_update.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider, planOrchestratorProvider, badgeServiceProvider;
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/utils/study_utils.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/features/focus_mode/presentation/widgets/focus_timer_widget.dart';
import 'package:studyking/features/focus_mode/presentation/widgets/inline_practice_widget.dart';
import 'package:studyking/features/focus_mode/presentation/widgets/session_summary_card.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_model.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_type.dart';
import 'package:studyking/features/focus_mode/providers/focus_mode_providers.dart' show focusSessionRepositoryProvider, studyTimerServiceProvider;
import 'package:studyking/features/sessions/services/study_timer_service.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider;
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/providers/service_providers.dart' show studentIdValueProvider;
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/widgets/loading_indicator.dart';

class FocusTimerScreen extends ConsumerStatefulWidget {
  final String? preselectedSubjectId;
  final String? preselectedTopicId;
  final int? defaultDurationMinutes;

  const FocusTimerScreen({
    super.key,
    this.preselectedSubjectId,
    this.preselectedTopicId,
    this.defaultDurationMinutes,
  });

  @override
  ConsumerState<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  static final Logger _logger = const Logger('FocusTimerScreen');
  late final StudyTimerService _service;

  bool _initialized = false;
  int _selectedMinutes = 25;
  Session? _completedSession;
  bool _inBreak = false;
  int _breakRemaining = 0;
  int _breakDuration = 300;
  Timer? _breakTimer;
  String _selectedSubjectId = '';
  bool _studyMode = true;
  FocusSessionType _sessionType = FocusSessionType.spacedRepetition;
  Map<String, double> _masteryBeforeValues = {};

  Map<String, dynamic>? _todayStats;
  int _weeklyMs = 0;
  List<Session> _recentSessions = [];
  int _lastTickMs = 0;

  List<Subject> _subjects = [];
  Map<String, int> _dueCounts = {};

  bool _showOnboarding = false;

  bool _inlinePracticeActive = false;
  Subject? _inlinePracticeSubject;
  FocusSession? _lastFocusSession;
  int _inlinePracticeQuestionCount = 10;

  bool _subjectsError = false;
  bool _dueCountsError = false;
  bool _statsError = false;

  int _lastMidSessionCapCheckMs = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service = ref.read(studyTimerServiceProvider);
    if (widget.defaultDurationMinutes != null && widget.defaultDurationMinutes! > 0) {
      _selectedMinutes = widget.defaultDurationMinutes!;
    }
    _initService();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _service.hasActiveSession) {
      _reconcileBackgroundTime();
    }
    if (state == AppLifecycleState.paused && _inBreak) {
      _breakTimer?.cancel();
    } else if (state == AppLifecycleState.resumed && _inBreak && _breakRemaining > 0) {
      _startBreakTimer();
    }
  }

  void _reconcileBackgroundTime() {
    if (!_service.hasActiveSession || _lastTickMs <= 0) return;
    final expectedMs = DateTime.now().millisecondsSinceEpoch - _lastTickMs;
    if (expectedMs > 2000) {
      final maxPlannedMs = (_service.currentSession?.plannedDurationMinutes ?? 25) * msPerMinute;
      final clampedMs = expectedMs > maxPlannedMs ? maxPlannedMs : expectedMs;
      _service.reconcileElapsedMs(clampedMs);
      if (_service.elapsedMs >= maxPlannedMs) {
        _service.completeSession();
      }
      _checkMidSessionCap();
    }
  }

  Future<void> _initService() async {
    try {
      _service.addOnSessionComplete(_onSessionComplete);
      _service.addOnTick(_onTick);
      await _loadStats();

      try {
        final focusSessionRepo = ref.read(focusSessionRepositoryProvider);
        await focusSessionRepo.init();
        final lastSessionResult = await focusSessionRepo.getLatest();
        if (lastSessionResult.isSuccess && lastSessionResult.data != null) {
          _lastFocusSession = lastSessionResult.data;
        }
      } catch (e) {
        _logger.w('Failed to load persisted focus session', e);
      }

      final settings = ref.read(settingsProvider);
      _breakDuration = settings.breakDurationSeconds;

      if (settings.firstFocusVisit) {
        _showOnboarding = true;
        try {
          ref.read(settingsProvider.notifier).updateSettings(SettingsUpdate(firstFocusVisit: false));
        } catch (e) {
          _logger.w('Failed to update first focus visit: $e');
        }
      }

      if (mounted) {
        setState(() => _initialized = true);
      }
      _loadInitialData();
    } catch (e) {
      _logger.w('Failed to initialize', e);
      if (mounted) {
        setState(() => _initialized = true);
      }
    }
  }

  Future<void> _loadInitialData() async {
    _loadSubjects();
    _loadDueCounts();
  }

  Future<void> _loadSubjects() async {
    try {
      final subjectRepo = ref.read(subjectsRepositoryProvider).valueOrNull;
      if (subjectRepo == null) return;
      final result = await subjectRepo.getAll();
      final subjects = result.data ?? [];
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _subjectsError = false;
        });
      }
    } catch (e) {
      _logger.w('Failed to load subjects', e);
      if (mounted) {
        setState(() => _subjectsError = true);
      }
    }
  }

  Future<void> _loadDueCounts() async {
    if (_subjects.isEmpty) return;
    try {
      final srService = ref.read(spacedRepetitionServiceProvider);
      final dueCounts = <String, int>{};
      for (final subject in _subjects) {
        final result = await srService.getPracticeQuestions(subject.id);
        final questions = result.data ?? [];
        dueCounts[subject.id] = questions.length;
      }
      if (mounted) {
        setState(() {
          _dueCounts = dueCounts;
          _dueCountsError = false;
        });
      }
    } catch (e) {
      _logger.w('Failed to load due counts', e);
      if (mounted) {
        setState(() => _dueCountsError = true);
      }
    }
  }

  void _onSessionComplete(Session session) {
    if (!mounted) return;
    setState(() {
      _completedSession = session;
      _inBreak = true;
      _breakRemaining = _breakDuration;
      _startBreakTimer();
    });
    unawaited(_loadStats());
    _recordAdherence(session);
    _checkBadges(session);
  }

  Future<void> _checkBadges(Session session) async {
    try {
      final studentId = ref.read(studentIdValueProvider);
      final badgeService = ref.read(badgeServiceProvider);
      await badgeService.checkAndUnlockBadges(studentId);
    } catch (e) {
      _logger.w('Badge check failed', e);
    }
  }

  Future<void> _recordAdherence(Session session) async {
    try {
      final planAdapter = ref.read(planOrchestratorProvider);
      final elapsedSeconds = session.actualDurationMs ~/ msPerSecond;
      final actualMinutes = (elapsedSeconds / 60).ceil().clamp(1, 480);
      await planAdapter.recordActivity(
        studentId: ref.read(studentIdValueProvider),
        actualMinutes: actualMinutes,
      );
    } catch (e) {
      // Logged internally by PlanAdherenceOrchestrator, non-critical for UX
    }
  }

  void _dismissOnboarding() {
    setState(() => _showOnboarding = false);
  }

  Future<void> _checkMidSessionCap() async {
    if (!_service.hasActiveSession) return;
    try {
      final exceededResult = await _service.isDailyCapExceededMidSession();
      final exceeded = exceededResult.data ?? false;
      if (exceeded && mounted) {
        final l10n = AppLocalizations.of(context)!;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.dailyLimitReached),
            content: Text(l10n.dailyLimitReachedBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.continueAnyway),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _service.completeSession();
                  if (mounted) setState(() {});
                },
                child: Text(l10n.endSession),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _logger.w('Failed to complete session', e);
    }
  }

  void _onTick(int elapsedMs) {
    if (mounted) {
      _lastTickMs = DateTime.now().millisecondsSinceEpoch;
      setState(() {});
      if (elapsedMs - _lastMidSessionCapCheckMs >= msPerMinute) {
        _lastMidSessionCapCheckMs = elapsedMs;
        _checkMidSessionCap();
      }
    }
  }

  void _startBreakTimer() {
    _breakTimer?.cancel();
    _breakTimer = Timer.periodic(Timeouts.second, (_) {
      if (!mounted) return;
      setState(() {
        _breakRemaining--;
      });
      if (_breakRemaining <= 0) {
        _breakTimer?.cancel();
        _breakTimer = null;
        setState(() {
          _inBreak = false;
          _completedSession = null;
        });
      }
    });
  }

  Future<void> _loadStats() async {
    try {
      final statsResult = await _service.getTodayStats();
      final weeklyResult = await _service.getTodayDurationMs();
      final recentResult = await _service.getRecentSessions();
      final stats = statsResult.data ?? <String, dynamic>{};
      final weekly = weeklyResult.data ?? 0;
      final recent = recentResult.data ?? [];
      if (mounted) {
        setState(() {
          _todayStats = stats;
          _weeklyMs = weekly;
          _recentSessions = recent;
          _statsError = false;
        });
      }
    } catch (e) {
      _logger.w('Failed to load stats', e);
      if (mounted) {
        setState(() => _statsError = true);
      }
    }
  }

  Future<void> _startFocus() async {
    try {
      final capResult = await _service.getDailyCapMinutes();
      final capMinutes = capResult.data ?? 0;
      if (capMinutes > 0) {
        final remainingResult = await _service.getRemainingDailyCapMinutes();
        final remaining = remainingResult.data ?? -1;
        if (remaining > 0 && _selectedMinutes > remaining) {
          if (mounted) {
            final l10n = AppLocalizations.of(context)!;
            final continueAnyway = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.dailyCapWarningTitle),
                content: Text(l10n.dailyCapWarningBody(_selectedMinutes, remaining)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.continueAnyway),
                  ),
                ],
              ),
            );
            if (continueAnyway != true) return;
          }
        }
      }

      final result = await _service.startSession(
        plannedDurationMinutes: _selectedMinutes,
        type: SessionType.focus,
        subjectId: _selectedSubjectId.isNotEmpty
            ? _selectedSubjectId
            : widget.preselectedSubjectId,
        topicId: widget.preselectedTopicId,
      );
      if (result.isFailure) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorStartingSession(''))),
          );
        }
        return;
      }
      if (_sessionType != FocusSessionType.freeFocus) {
        await _captureMasteryBefore();
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorStartingSession(''))),
        );
      }
    }
  }

  Future<void> _captureMasteryBefore() async {
    try {
      final studentId = ref.read(studentIdValueProvider);
      final masteryService = ref.read(masteryGraphServiceProvider);
      final weakResult = await masteryService.getWeakTopics(studentId);
      if (weakResult.isSuccess && weakResult.data != null) {
        final beforeValues = <String, double>{};
        for (final topic in weakResult.data!) {
          beforeValues[topic.topicId] = topic.accuracy;
        }
        _masteryBeforeValues = beforeValues;
      }
    } catch (e) {
      _logger.w('Failed to capture mastery before values', e);
    }
  }

  void _startFullPracticeSession(Subject subject) async {
    await Navigator.pushNamed(context, AppRoutes.practiceSession,
      arguments: PracticeSessionArgs(subjectId: subject.id),
    );
    _loadDueCounts();
  }

  void _startWeakAreasPractice() async {
    if (_subjects.isEmpty) return;
    final studentId = ref.read(studentIdValueProvider);
    final l10n = AppLocalizations.of(context)!;
    try {
      final masteryService = ref.read(masteryGraphServiceProvider);
      final weakResult = await masteryService.getWeakTopics(studentId);
      if (weakResult.isFailure || weakResult.data == null || weakResult.data!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noWeakAreasFound)),
          );
        }
        return;
      }
      final weakTopicIds = weakResult.data!.map((s) => s.topicId).toSet();
      final questionRepo = ref.read(questionRepositoryProvider);
      final allResult = await questionRepo.getAll();
      final allQuestions = allResult.data ?? [];
      final weakQuestions = allQuestions.where((q) => weakTopicIds.contains(q.topicId)).toList();
      if (weakQuestions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noWeakAreasQuestions)),
          );
        }
        return;
      }
      if (mounted) {
        await Navigator.pushNamed(context, AppRoutes.practiceSession,
          arguments: PracticeSessionArgs(
            subjectId: weakQuestions.first.subjectId,
            questionCount: weakQuestions.length,
          ),
        );
        _loadDueCounts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noWeakAreasFound)),
        );
      }
    }
  }

  void _startSpacedRepetition(Subject subject) async {
    final l10n = AppLocalizations.of(context)!;
    final srService = ref.read(spacedRepetitionServiceProvider);
    try {
      final result = await srService.getPracticeQuestions(subject.id);
      if (result.isFailure || result.data == null || result.data!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noReviewsScheduled)),
          );
        }
        return;
      }
      if (mounted) {
        await Navigator.pushNamed(context, AppRoutes.practiceSession,
          arguments: PracticeSessionArgs(
            subjectId: subject.id,
            questionCount: result.data!.length,
            isSpacedRepetition: true,
          ),
        );
        _loadDueCounts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noQuestionsAvailable)),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _breakTimer?.cancel();
    _service.removeOnSessionComplete(_onSessionComplete);
    _service.removeOnTick(_onTick);
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_service.hasActiveSession) return true;
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmExitFocus),
        content: Text(l10n.confirmExitFocusBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.stay),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.endSession),
          ),
        ],
      ),
    );
    if (result == true) {
      await _service.cancelSession();
      setState(() {});
      await _loadStats();
    }
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (!_initialized) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.focusMode)),
        body: const LoadingIndicator(),
      );
    }

    return PopScope(
      canPop: !_service.hasActiveSession,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(l10n.focusMode),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: l10n.help,
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(l10n.focusMode),
                content: Text(l10n.focusFirstVisitHelp),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.gotIt),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: l10n.refreshStats,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.screenPadding(context),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            if (_showOnboarding) ...[
              _buildOnboardingCard(l10n),
              const SizedBox(height: 12),
            ],
            _buildModeToggle(cs, l10n),
            if (widget.preselectedTopicId != null || widget.preselectedSubjectId != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Card(
                  margin: EdgeInsets.zero,
                  color: cs.primaryContainer.withValues(alpha: 0.5),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school, size: 14, color: cs.onPrimaryContainer),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.preselectedTopicId != null
                                ? l10n.lessonPracticeWithTopic(widget.preselectedTopicId!)
                                : l10n.lessonPractice,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (_inBreak && _completedSession != null)
              _buildBreakView(theme, cs, l10n)
            else if (_service.hasActiveSession)
              _buildActiveSessionView(theme, l10n)
            else if (_inlinePracticeActive && _inlinePracticeSubject != null)
              _buildInlinePracticeView(theme, cs, l10n)
            else if (!_studyMode)
              _buildSetupView(theme, l10n)
            else
              _buildStudyHubView(theme, cs, l10n),
            const SizedBox(height: 24),
            if (_statsError)
              _buildStatsError(theme, cs, l10n)
            else
              SessionSummaryCard(
                todayStats: _todayStats,
                weeklyMs: _weeklyMs,
                recentSessions: _recentSessions,
                lastPracticeSession: _lastFocusSession,
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildOnboardingCard(AppLocalizations l10n) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.focusMode,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: l10n.close,
                  onPressed: _dismissOnboarding,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.focusFirstVisitHelp,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.tonalIcon(
                onPressed: _dismissOnboarding,
                icon: const Icon(Icons.check, size: 18),
                label: Text(l10n.gotIt),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle(ColorScheme cs, AppLocalizations l10n) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _studyMode ? Icons.menu_book_outlined : Icons.timer_outlined,
                  size: 20,
                  color: cs.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _studyMode ? l10n.practice : l10n.focus,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                Semantics(
                  button: true,
                  label: _studyMode ? l10n.focusMode : l10n.practice,
                  child: Switch(
                    value: _studyMode,
                    onChanged: (_service.hasActiveSession || _inBreak)
                        ? null
                        : (v) => setState(() => _studyMode = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _studyMode ? l10n.inlinePracticeSubtitle : l10n.timerOnlyDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyHubView(ThemeData theme, ColorScheme cs, AppLocalizations l10n) {
    if (_subjectsError) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: cs.error),
              const SizedBox(height: 16),
              Text(l10n.somethingWentWrong, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(l10n.errorOccurred,
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  setState(() => _subjectsError = false);
                  _loadSubjects();
                },
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_subjects.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.school_outlined, size: 48, color: cs.primary.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(l10n.noSubjectsYet, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(l10n.addSubjectsAndQuestionsToStartPracticing,
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.subjectSelection),
                icon: const Icon(Icons.add),
                label: Text(l10n.addSubject),
              ),
            ],
          ),
        ),
      );
    }

    final totalDue = _dueCounts.values.fold(0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: ResponsiveUtils.cardPadding(context),
            child: Row(
              children: [
                Expanded(child: _buildStatItem(theme, Icons.schedule, '$totalDue', l10n.dueForReview)),
                Expanded(child: _buildStatItem(theme, Icons.book, '${_subjects.length}', l10n.subjects)),
              ],
            ),
          ),
        ),
        if (_dueCountsError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: cs.error),
                const SizedBox(width: 8),
                Text(l10n.errorOccurred, style: theme.textTheme.bodySmall?.copyWith(color: cs.error)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _dueCountsError = false);
                    _loadDueCounts();
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(l10n.retry, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        _buildSessionTypeSelector(theme, l10n),
        const SizedBox(height: 8),
        _buildQuestionCountSelector(theme, l10n),
        const SizedBox(height: 8),
        Text(l10n.yourSubjects, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._subjects.map((subject) => _buildSubjectPracticeCard(theme, cs, l10n, subject)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _subjects.any((s) => (_dueCounts[s.id] ?? 0) > 0)
                    ? () => _startSpacedRepetition(_subjects.firstWhere((s) => (_dueCounts[s.id] ?? 0) > 0))
                    : null,
                icon: const Icon(Icons.replay, size: 18),
                label: Text(l10n.spacedRepetition, style: const TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _subjects.isNotEmpty ? _startWeakAreasPractice : null,
                icon: const Icon(Icons.psychology_outlined, size: 18),
                label: Text(l10n.weakAreas, style: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
        if (totalDue > 0) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _startAllSubjectsInlinePractice(),
              icon: const Icon(Icons.interests, size: 18),
              label: Text(l10n.reviewDueQuestions, style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsError(ThemeData theme, ColorScheme cs, AppLocalizations l10n) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 32, color: cs.error),
            const SizedBox(height: 8),
            Text(l10n.somethingWentWrong, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(l10n.errorOccurred,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() => _statsError = false);
                _loadStats();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, IconData icon, String value, String label) {
    return MergeSemantics(
      child: Column(children: [
        Semantics(
          label: label,
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }

  Widget _buildSubjectPracticeCard(ThemeData theme, ColorScheme cs, AppLocalizations l10n, Subject subject) {
    final due = _dueCounts[subject.id] ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showPracticeOptions(subject),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.menu_book, color: cs.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subject.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        due > 0
                            ? l10n.dueQuestionsCount(due)
                            : l10n.readyForPractice,
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPracticeOptions(Subject subject) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(subject.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.quickreply),
              title: Text(l10n.quickPractice),
              subtitle: Text(l10n.inlinePracticeSubtitle),
              onTap: () {
                Navigator.pop(ctx);
                _startInlinePractice(subject);
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: Text(l10n.spacedRepetition),
              subtitle: Text(l10n.fullPracticeSubtitle),
              onTap: () {
                Navigator.pop(ctx);
                _startFullPracticeSession(subject);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _startInlinePractice(Subject subject) {
    setState(() {
      _inlinePracticeActive = true;
      _inlinePracticeSubject = subject;
    });
  }

  void _startAllSubjectsInlinePractice() {
    setState(() {
      _inlinePracticeActive = true;
      _inlinePracticeSubject = null;
      if (_inlinePracticeQuestionCount < 50) {
        _inlinePracticeQuestionCount = 50;
      }
    });
  }

  Future<void> _onInlinePracticeComplete(int correct, int total, Map<String, TopicAccuracy> perTopic) async {
    final studentId = ref.read(studentIdValueProvider);
    final now = DateTime.now();
    final topicIds = perTopic.keys.toList();
    final accuracy = total > 0 ? correct / total : 0.0;

    Map<String, double> masteryChanges = {};
    Map<String, TopicPerformance> topicBreakdown = {};

    try {
      final masteryService = ref.read(masteryGraphServiceProvider);

      for (final entry in perTopic.entries) {
        final topicId = entry.key;
        final topicAcc = entry.value;
        final topicPerformance = TopicPerformance(
          topicId: topicId,
          correct: topicAcc.correct,
          total: topicAcc.total,
          accuracyPercent: topicAcc.accuracyPercent,
        );
        topicBreakdown[topicId] = topicPerformance;
      }

      final currentWeakTopics = await masteryService.getWeakTopics(studentId);
      if (currentWeakTopics.isSuccess && currentWeakTopics.data != null) {
        for (final topic in currentWeakTopics.data!) {
          final tid = topic.topicId;
          final beforeValue = _masteryBeforeValues[tid] ?? 0.0;
          final afterValue = topic.accuracy;
          masteryChanges[tid] = afterValue - beforeValue;
        }
      }
    } catch (e) {
      _logger.w('Failed to compute mastery changes', e);
    }

    if (mounted) {
      final focusSession = FocusSession(
        id: 'focus_${now.millisecondsSinceEpoch}',
        studentId: studentId,
        startTime: now.subtract(const Duration(minutes: 5)),
        endTime: now,
        durationMinutes: 5,
        questionsAnswered: total,
        correctAnswers: correct,
        accuracy: accuracy,
        subjectIds: topicIds,
        masteryChanges: masteryChanges,
        sessionType: _sessionType,
        topicBreakdown: topicBreakdown,
      );

      try {
        final repo = ref.read(focusSessionRepositoryProvider);
        await repo.save(focusSession);
      } catch (e) {
        _logger.w('Failed to persist focus session', e);
      }

      if (mounted) {
        setState(() {
          _inlinePracticeActive = false;
          _inlinePracticeSubject = null;
          _lastFocusSession = focusSession;
        });
      }
    }
    _loadDueCounts();
  }

  Widget _buildBreakView(ThemeData theme, ColorScheme cs, AppLocalizations l10n) {
    return Semantics(
      liveRegion: true,
      label: l10n.breakRemainingLabel(formatTimer(Duration(seconds: _breakRemaining), l10n: l10n)),
      child: Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: ResponsiveUtils.cardPadding(context),
        child: Column(
          children: [
            Icon(Icons.self_improvement, size: ResponsiveUtils.emptyStateIconSize(context), color: cs.tertiary),
            const SizedBox(height: 16),
            Text(
              l10n.breakTime,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.tertiary,
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatTimer(Duration(seconds: _breakRemaining), l10n: l10n),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.sessionCompleted(_completedSession!.actualDurationMs ~/ msPerMinute),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _breakTimer?.cancel();
                      setState(() {
                        _inBreak = false;
                        _completedSession = null;
                      });
                    },
                    icon: const Icon(Icons.skip_next, size: 18),
                    label: Text(l10n.skip),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildActiveSessionView(ThemeData theme, AppLocalizations l10n) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: ResponsiveUtils.cardPadding(context),
        child: Column(
          children: [
            FocusTimerWidget(
              plannedDurationMinutes: _service.currentSession!.plannedDurationMinutes ?? 25,
              elapsedSeconds: _service.elapsedSeconds,
              isPaused: _service.isPaused,
              isActive: true,
              reduceMotion: ref.watch(settingsProvider).reduceMotion,
              onPause: () => setState(() { _service.pauseSession(); }),
              onResume: () => setState(() { _service.resumeSession(); }),
              onComplete: () async {
                await _service.completeSession();
              },
              onCancel: () async {
                await _service.cancelSession();
                setState(() {});
                _loadStats();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlinePracticeView(ThemeData theme, ColorScheme cs, AppLocalizations l10n) {
    final subject = _inlinePracticeSubject;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: ResponsiveUtils.cardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.quickreply, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(subject != null
                      ? '${l10n.quickPractice} — ${subject.name}'
                      : l10n.reviewDueQuestions,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: l10n.close,
                  onPressed: () => setState(() {
                    _inlinePracticeActive = false;
                    _inlinePracticeSubject = null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: InlinePracticeWidget(
                  subjectId: subject?.id,
                  questionCount: _inlinePracticeQuestionCount,
                  sessionType: _sessionType,
                  onComplete: _onInlinePracticeComplete,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupView(ThemeData theme, AppLocalizations l10n) {
    final presets = [10, 15, 25, 30, 45, 60];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: ResponsiveUtils.cardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.newFocusSession,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSubjectPicker(),
            const SizedBox(height: 16),
            Text(
              l10n.duration,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FocusTraversalGroup(
              child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((m) {
                final selected = _selectedMinutes == m;
                return Semantics(
                  button: true,
                  selected: selected,
                  label: l10n.minutesSemantics(m),
                  child: ChoiceChip(
                    label: Text(l10n.durationMinutes(m)),
                    selected: selected,
                    onSelected: (v) => setState(() => _selectedMinutes = m),
                    visualDensity: VisualDensity.adaptivePlatformDensity,
                  ),
                );
              }).toList(),
            ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _selectedMinutes.toDouble(),
              min: 1,
              max: 180,
              divisions: 179,
              label: l10n.minutesValue(_selectedMinutes),
              onChanged: (v) => setState(() => _selectedMinutes = v.round()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _startFocus,
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  l10n.focusForMinutes(_selectedMinutes),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTypeSelector(ThemeData theme, AppLocalizations l10n) {
    final types = FocusSessionType.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.sessionType,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((type) {
            final selected = _sessionType == type;
            return Semantics(
              button: true,
              selected: selected,
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_iconForSessionType(type), size: 16),
                    const SizedBox(width: 6),
                    Text(_labelForSessionType(type, l10n)),
                  ],
                ),
                selected: selected,
                onSelected: (v) => setState(() => _sessionType = type),
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _iconForSessionType(FocusSessionType type) {
    switch (type) {
      case FocusSessionType.quickPractice:
        return Icons.quickreply;
      case FocusSessionType.spacedRepetition:
        return Icons.replay;
      case FocusSessionType.weakAreaAttack:
        return Icons.psychology;
      case FocusSessionType.freeFocus:
        return Icons.timer;
    }
  }

  String _labelForSessionType(FocusSessionType type, AppLocalizations l10n) {
    switch (type) {
      case FocusSessionType.quickPractice:
        return l10n.quickPractice;
      case FocusSessionType.spacedRepetition:
        return l10n.spacedRepetition;
      case FocusSessionType.weakAreaAttack:
        return l10n.weakAreas;
      case FocusSessionType.freeFocus:
        return l10n.focus;
    }
  }

  Widget _buildQuestionCountSelector(ThemeData theme, AppLocalizations l10n) {
    final counts = [5, 10, 15, 20, 30, 50];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.questionsLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: counts.map((n) {
                final selected = _inlinePracticeQuestionCount == n;
                return ChoiceChip(
                  label: Text('$n'),
                  selected: selected,
                  onSelected: (_) => setState(() => _inlinePracticeQuestionCount = n),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectPicker() {
    final l10n = AppLocalizations.of(context)!;
    final subjects = _subjects;
    if (subjects.isEmpty) {
      return Semantics(
        label: l10n.addSubjectsForFocusHint,
        child: Card(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.addSubjectsForFocusHint,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.subjectSelection),
                  child: Text(l10n.settings),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: _selectedSubjectId.isEmpty ? null : _selectedSubjectId,
      decoration: InputDecoration(
        labelText: l10n.selectSubjectLabel,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        DropdownMenuItem(
          value: '',
          child: Text(l10n.subjectOptional),
        ),
        ...subjects.map((s) => DropdownMenuItem(
          value: s.id,
          child: Text(s.name),
        )),
      ],
      onChanged: (v) => setState(() => _selectedSubjectId = v ?? ''),
    );
  }
}
