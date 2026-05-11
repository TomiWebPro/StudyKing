import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/core/data/repositories/study_session_repository.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/features/sessions/presentation/session_history_screen.dart';
import 'package:studyking/features/sessions/widgets/session_analytics.dart';


const String _defaultStudentId = 'anonymous';

class SessionTrackerScreen extends StatefulWidget {
  final StudySessionRepository? sessionRepository;

  const SessionTrackerScreen({super.key, this.sessionRepository});

  @override
  State<SessionTrackerScreen> createState() => _SessionTrackerScreenState();
}

class _SessionTrackerScreenState extends State<SessionTrackerScreen> with WidgetsBindingObserver {
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
      debugPrint('Error loading sessions: $e');
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
          SnackBar(content: Text('Failed to save session: $e')),
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

  String _formatElapsed(int seconds) {
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m ${secs}s';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Study Session Tracker'),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Session Tracker'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor.withValues(alpha: 0.1),
                      theme.primaryColor.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isTrackingSession ? 'Current Session' : 'No Active Session',
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
                      _isTrackingSession ? _formatElapsed(_elapsedSeconds) : 'Tap start to begin tracking',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _isTrackingSession ? theme.primaryColor : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isTrackingSession ? null : _startSession,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isTrackingSession ? theme.disabledColor : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                        if (_isTrackingSession)
                          ElevatedButton.icon(
                            onPressed: _endSession,
                            icon: const Icon(Icons.stop),
                            label: const Text('End'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                    'Recent Sessions',
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
                            '${_sortedSessions.take(5).length} of ${_allSessions.length}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SessionHistoryScreen(),
                            ),
                          );
                        },
                        child: const Text('View All'),
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
    if (_allSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: theme.disabledColor),
            const SizedBox(height: 8),
            Text('No sessions yet', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text('Start your first session!', style: theme.textTheme.bodySmall),
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

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(Icons.play_arrow, color: theme.primaryColor),
            title: Text(
              'Session ${_sortedSessions.length - position}',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${formatDuration(Duration(milliseconds: session.timeSpentMs))} • ${formatDate(session.startTime)}',
              style: theme.textTheme.bodySmall,
            ),
            trailing: Text(
              formatDuration(Duration(milliseconds: session.timeSpentMs)),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
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
    return AlertDialog(
      title: const Text('Session Complete'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('How many questions did you answer?'),
          const SizedBox(height: 8),
          TextField(
            controller: _questionsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Questions Answered',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _correctController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Correct Answers',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context, const _SessionEndStats(questionsAnswered: 0, correctAnswers: 0)),
          child: const Text('Skip'),
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
          child: const Text('Save'),
        ),
      ],
    );
  }
}
