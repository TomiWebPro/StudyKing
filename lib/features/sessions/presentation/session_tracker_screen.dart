import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider;
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/widgets/widgets.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/sessions/presentation/widgets/session_analytics.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class SessionTrackerScreen extends ConsumerStatefulWidget {
  final SessionRepository? sessionRepository;

  const SessionTrackerScreen({super.key, this.sessionRepository});

  @override
  ConsumerState<SessionTrackerScreen> createState() => _SessionTrackerScreenState();
}

class _SessionTrackerScreenState extends ConsumerState<SessionTrackerScreen> with WidgetsBindingObserver {
  final Logger _logger = const Logger('SessionTrackerScreen');
  late SessionRepository _sessionRepository;
  List<Session> _allSessions = [];
  List<Session> _sortedSessions = [];
  int _currentStreak = 0;
  bool _isTrackingSession = false;
  DateTime? _sessionStartTime;
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionRepository = widget.sessionRepository ?? SessionRepository();
    _loadSessions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isTrackingSession) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed && _isTrackingSession && _sessionStartTime != null) {
      _elapsedSeconds = DateTime.now().difference(_sessionStartTime!).inSeconds;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateElapsed());
    }
  }

  Future<void> _loadSessions() async {
    try {
      final sessionsResult = await _sessionRepository.getAll();
      final sessions = sessionsResult.data ?? [];
      if (mounted) {
        setState(() {
          _allSessions = sessions.toList();
          _sortedSessions = List<Session>.from(_allSessions)
            ..sort((a, b) => b.startTime.millisecondsSinceEpoch.compareTo(a.startTime.millisecondsSinceEpoch));
          _isLoading = false;
        });
        _calculateStats();
      }
    } catch (e) {
      _logger.e('Error loading sessions', e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateStats() {
    final today = DateTime.now();

    int streak = 0;
    DateTime checkDate = today;

    while (true) {
      final hasSessionToday = _allSessions.any((s) => s.startTime.isSameDay(checkDate));
      if (hasSessionToday) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    _currentStreak = streak;
  }

  void _startSession() {
    setState(() {
      _isTrackingSession = true;
      _sessionStartTime = DateTime.now();
      _elapsedSeconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateElapsed());
  }

  void _updateElapsed() {
    if (_sessionStartTime == null) return;
    if (mounted) {
      setState(() {
        _elapsedSeconds = DateTime.now().difference(_sessionStartTime!).inSeconds;
      });
    }
  }

  Future<void> _endSession() async {
    _timer?.cancel();

    if (_sessionStartTime == null) return;

    final endTime = DateTime.now();
    final startTime = _sessionStartTime!;
    final duration = endTime.difference(startTime).inMilliseconds;

    if (!mounted) return;

    final stats = await showDialog<_SessionEndStats>(
      context: context,
      builder: (context) => const _SessionEndDialog(),
    );

    if (!mounted) return;

    final questionsAnswered = stats?.questionsAnswered ?? 0;
    final correctAnswers = stats?.correctAnswers ?? 0;
    final studentId = StudentIdService().getStudentId();

    final id = '${endTime.millisecondsSinceEpoch}_${Random().nextInt(99999)}';

    try {
      await _sessionRepository.save(Session(
        id: id,
        startTime: startTime,
        endTime: endTime,
        actualDurationMs: duration,
        questionsAnswered: questionsAnswered,
        correctAnswers: correctAnswers,
        studentId: studentId,
        subjectId: 'all',
        type: SessionType.manual,
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToSaveSession(e.toString()))),
        );
      }
    }

    // Track plan adherence via InstrumentationService
    try {
      final planRepo = PlanRepository();
      await planRepo.init();
      final plan = await planRepo.loadPlan(studentId);
      if (plan != null) {
        final todayPlan = plan.dailyPlans.where((d) =>
            d.date.year == DateTime.now().year &&
            d.date.month == DateTime.now().month &&
            d.date.day == DateTime.now().day).firstOrNull;
        if (todayPlan != null) {
          final instrumentation = InstrumentationService();
          await instrumentation.init();
          instrumentation.recordPlanAdherence(
            studentId: studentId,
            date: DateTime.now(),
            plannedQuestions: todayPlan.targetQuestions,
            actualQuestions: questionsAnswered,
            plannedMinutes: todayPlan.targetMinutes,
            actualMinutes: duration ~/ 60000,
          );
        }
      }
    } catch (_) {}

    // Track mastery improvement for topics practiced
    try {
      final instrumentation = InstrumentationService();
      await instrumentation.init();
      final masteryService = MasteryGraphService();
      await masteryService.init();
      final weakResult = await masteryService.getWeakTopics(studentId);
      if (weakResult.isSuccess) {
        for (final state in weakResult.data!) {
          await instrumentation.trackMasteryImprovement(studentId, state.topicId);
        }
      }
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _isTrackingSession = false;
      _sessionStartTime = null;
    });

    await _loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.studySessionTracker),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.studySessionTracker),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: ResponsiveUtils.screenPadding(context),
          child: SingleChildScrollView(
            child: FocusTraversalGroup(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GradientContainer(
                accent: theme.primaryColor,
                borderRadius: 16,
                padding: ResponsiveUtils.cardPadding(context),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isTrackingSession ? l10n.currentSession : l10n.noActiveSession,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: _isTrackingSession ? theme.primaryColor : theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          _isTrackingSession ? Icons.timer : Icons.timer_off,
                          color: _isTrackingSession ? theme.primaryColor : theme.textTheme.bodyMedium?.color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      liveRegion: true,
                      label: _isTrackingSession
                          ? '${l10n.currentSession}: ${formatDurationFromContext(context, Duration(seconds: _elapsedSeconds))}'
                          : l10n.tapStartToBegin,
                      child: Text(
                        _isTrackingSession ? formatDurationFromContext(context, Duration(seconds: _elapsedSeconds)) : l10n.tapStartToBegin,
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: (MediaQuery.sizeOf(context).shortestSide * 0.09).clamp(36.0, 64.0),
                          color: _isTrackingSession ? theme.primaryColor : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isTrackingSession ? null : _startSession,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(l10n.start),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isTrackingSession ? theme.disabledColor : theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            minimumSize: const Size(48, 48),
                          ),
                        ),
                        if (_isTrackingSession)
                          ElevatedButton.icon(
                            onPressed: _endSession,
                            icon: const Icon(Icons.stop),
                            label: Text(l10n.end),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                              foregroundColor: theme.colorScheme.onError,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              minimumSize: const Size(48, 48),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              SessionAnalyticsWidget(
                sessions: _allSessions,
                currentStreak: _currentStreak,
                reduceMotion: ref.watch(settingsProvider).reduceMotion,
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.recentSessions,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      if (_allSessions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            l10n.ofLabel(_sortedSessions.take(5).length, _allSessions.length),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      Semantics(
                        label: l10n.viewAll,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.sessionHistory);
                          },
                          child: Text(l10n.viewAll),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              _buildRecentSessionsList(theme),
            ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  IconData _sessionIcon(SessionType type) {
    switch (type) {
      case SessionType.focus:
        return Icons.timer;
      case SessionType.practice:
        return Icons.play_arrow;
      case SessionType.tutoring:
        return Icons.school;
      case SessionType.manual:
        return Icons.edit_note;
    }
  }

  Color _sessionColor(SessionType type, ThemeData theme) {
    switch (type) {
      case SessionType.focus:
        return theme.colorScheme.tertiary;
      case SessionType.practice:
        return theme.colorScheme.primary;
      case SessionType.tutoring:
        return theme.colorScheme.secondary;
      case SessionType.manual:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  Widget _buildRecentSessionsList(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    if (_allSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: ResponsiveUtils.emptyStateIconSize(context) * 0.6, color: theme.disabledColor),
            const SizedBox(height: 8),
            Text(l10n.noSessionsYet, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(l10n.startYourFirstSession, style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    final recentSessions = _sortedSessions.take(5).toList();

    return FocusTraversalGroup(
      child: ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentSessions.length,
      itemBuilder: (context, index) {
        final session = recentSessions[index];
        final position = _sortedSessions.indexOf(session);

        final icon = _sessionIcon(session.type);
        final color = _sessionColor(session.type, theme);

        return Semantics(
          label: l10n.sessionNumber(_sortedSessions.length - position),
          child: Card(
            margin: EdgeInsets.only(bottom: ResponsiveUtils.verticalSpacing(context) * 0.75),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              title: Row(
                children: [
                  Text(
                    l10n.sessionNumber(_sortedSessions.length - position),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  Icon(icon, size: 14, color: color),
                ],
              ),
              subtitle: Text(
                '${formatDurationFromContext(context, session.actualDuration)} • ${formatDateFromContext(context, session.startTime)}',
                style: theme.textTheme.bodySmall,
              ),
              trailing: Text(
                formatDurationFromContext(context, session.actualDuration),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ),
        );
      },
    ),
    );
  }
}

class _SessionEndStats {
  final int questionsAnswered;
  final int correctAnswers;

  const _SessionEndStats({required this.questionsAnswered, required this.correctAnswers});
}

class _SessionEndDialog extends StatefulWidget {
  const _SessionEndDialog();

  @override
  State<_SessionEndDialog> createState() => _SessionEndDialogState();
}

class _SessionEndDialogState extends State<_SessionEndDialog> {
  final _formKey = GlobalKey<FormState>();
  final _questionsController = TextEditingController(text: '0');
  final _correctController = TextEditingController(text: '0');

  @override
  void dispose() {
    _questionsController.dispose();
    _correctController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final questions = int.parse(_questionsController.text);
      final correct = int.parse(_correctController.text);
      Navigator.pop(
        context,
        _SessionEndStats(questionsAnswered: questions, correctAnswers: correct),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.sessionComplete),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.howManyQuestions),
            const SizedBox(height: 8),
            TextFormField(
              controller: _questionsController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.questionsAnswered,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                final n = int.tryParse(value ?? '');
                if (n == null || n < 0) return l10n.valueMustBePositive;
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _correctController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: l10n.correctAnswers,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                final n = int.tryParse(value ?? '');
                if (n == null || n < 0) return l10n.valueMustBePositive;
                final questions = int.tryParse(_questionsController.text) ?? 0;
                if (n > questions) return l10n.correctExceedsQuestions;
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context, const _SessionEndStats(questionsAnswered: 0, correctAnswers: 0)),
          child: Text(l10n.skip),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
