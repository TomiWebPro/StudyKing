import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/core/data/repositories/study_session_repository.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/widgets/widgets.dart';
import 'package:studyking/features/sessions/presentation/session_history_screen.dart';
import 'package:studyking/features/sessions/widgets/session_analytics.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../../core/utils/logger.dart';


const String _defaultStudentId = 'anonymous';

class SessionTrackerScreen extends StatefulWidget {
  final StudySessionRepository? sessionRepository;

  const SessionTrackerScreen({super.key, this.sessionRepository});

  @override
  State<SessionTrackerScreen> createState() => _SessionTrackerScreenState();
}

class _SessionTrackerScreenState extends State<SessionTrackerScreen> with WidgetsBindingObserver {
  final Logger _logger = const Logger('SessionTrackerScreen');
  late StudySessionRepository _sessionRepository;
  List<StudySession> _allSessions = [];
  List<StudySession> _sortedSessions = [];
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
    _sessionRepository = widget.sessionRepository ?? StudySessionRepository();
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
      await _sessionRepository.init();
      final sessions = await _sessionRepository.getAll();
      if (mounted) {
        setState(() {
          _allSessions = sessions.toList();
          _sortedSessions = List<StudySession>.from(_allSessions)
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

    final id = '${endTime.millisecondsSinceEpoch}_${Random().nextInt(99999)}';

    try {
      await _sessionRepository.create(StudySession(
        id: id,
        startTime: startTime,
        endTime: endTime,
        timeSpentMs: duration,
        questionsAnswered: questionsAnswered,
        correctAnswers: correctAnswers,
        studentId: _defaultStudentId,
        subjectId: 'all',
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToSaveSession(e.toString()))),
        );
      }
    }

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
                    Text(
                      _isTrackingSession ? formatDurationFromContext(context, Duration(seconds: _elapsedSeconds)) : l10n.tapStartToBegin,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _isTrackingSession ? theme.primaryColor : theme.textTheme.bodyMedium?.color,
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
                            backgroundColor: _isTrackingSession ? theme.disabledColor : Colors.green,
                            foregroundColor: Colors.white,
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
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SessionHistoryScreen(),
                              ),
                            );
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
    );
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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentSessions.length,
      itemBuilder: (context, index) {
        final session = recentSessions[index];
        final position = _sortedSessions.indexOf(session);

        return Semantics(
          label: l10n.sessionNumber(_sortedSessions.length - position),
          child: Card(
            margin: EdgeInsets.only(bottom: ResponsiveUtils.verticalSpacing(context) * 0.75),
            child: ListTile(
              leading: Icon(Icons.play_arrow, color: theme.primaryColor),
              title: Text(
                l10n.sessionNumber(_sortedSessions.length - position),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${formatDurationFromContext(context, Duration(milliseconds: session.timeSpentMs))} • ${formatDateFromContext(context, session.startTime)}',
                style: theme.textTheme.bodySmall,
              ),
              trailing: Text(
                formatDurationFromContext(context, Duration(milliseconds: session.timeSpentMs)),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ),
        );
      },
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
  final _questionsController = TextEditingController(text: '0');
  final _correctController = TextEditingController(text: '0');

  @override
  void dispose() {
    _questionsController.dispose();
    _correctController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.sessionComplete),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.howManyQuestions),
          const SizedBox(height: 8),
          TextField(
            controller: _questionsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.questionsAnswered,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _correctController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.correctAnswers,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context, const _SessionEndStats(questionsAnswered: 0, correctAnswers: 0)),
          child: Text(l10n.skip),
        ),
        ElevatedButton(
          onPressed: () {
            final questions = int.tryParse(_questionsController.text) ?? 0;
            final correct = int.tryParse(_correctController.text) ?? 0;
            Navigator.pop(
              context,
              _SessionEndStats(questionsAnswered: questions, correctAnswers: correct),
            );
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
