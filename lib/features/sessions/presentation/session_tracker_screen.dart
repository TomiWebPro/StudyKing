import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/core/data/repositories/study_session_repository.dart';
import 'session_history_screen.dart';
import '../widgets/session_analytics.dart';

/// Session Tracker Screen - Main UI for tracking study sessions
class SessionTrackerScreen extends ConsumerStatefulWidget {
  const SessionTrackerScreen({super.key});

  @override
  ConsumerState<SessionTrackerScreen> createState() => _SessionTrackerScreenState();
}

class _SessionTrackerScreenState extends ConsumerState<SessionTrackerScreen> {
  late StudySessionRepository _sessionRepository;
  List<StudySession> _allSessions = [];
  Duration _totalStudyTime = Duration.zero;
  int _currentStreak = 0;
  bool _isTrackingSession = false;
  DateTime? _sessionStartTime;
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _sessionRepository = StudySessionRepository();
    _loadSessions();
    _calculateStats();
  }

  Future<void> _loadSessions() async {
    try {
      final sessions = await _sessionRepository.getAll();
      if (mounted) {
        setState(() {
          _allSessions = sessions.toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading sessions: $e');
    }
  }

  void _calculateStats() {
    final today = DateTime.now();
    
    // Calculate current streak
    int streak = 0;
    DateTime checkDate = DateTime.now().subtract(const Duration(days: 1));
    
    while (true) {
      final dateStr = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      final hasSessionToday = _allSessions.any((s) => _isSameDay(s.startTime, checkDate));
      
      if (hasSessionToday) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    _currentStreak = streak;
    
    // Calculate total study time
    int totalMs = 0;
    for (var session in _allSessions) {
      totalMs += session.timeSpentMs;
    }
    _totalStudyTime = Duration(milliseconds: totalMs);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _startSession() {
    setState(() {
      _isTrackingSession = true;
      _sessionStartTime = DateTime.now();
      _elapsedSeconds = 0;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _endSession() {
    _timer?.cancel();
    setState(() {
      _isTrackingSession = false;
    });
    
    final endTime = DateTime.now();
    final duration = endTime.difference(_sessionStartTime!).inMilliseconds;
    
    _sessionRepository.create(StudySession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: _sessionStartTime!,
      endTime: endTime,
      timeSpentMs: duration,
      questionsAnswered: 0,
      correctAnswers: 0,
      studentId: 'anonymous',
      subjectId: 'all',
    ));
    
    _loadSessions();
    _calculateStats();
  }

  String _formatTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatElapsed(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Session Tracker'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Active Session Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor.withOpacity(0.1),
                      theme.primaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.primaryColor.withOpacity(0.3),
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
              
              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Time',
                      _formatTime(_totalStudyTime),
                      Icons.access_time,
                      theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Sessions',
                      _allSessions.length.toString(),
                      Icons.history,
                      theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Current Streak',
                      '$_currentStreak days',
                      Icons.emoji_events,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildStatCard(
                      'Avg per Session',
                      _allSessions.isNotEmpty 
                          ? _formatTime(_totalStudyTime ~/ _allSessions.length)
                          : '0m',
                      Icons.schedule,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Recent Sessions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Sessions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
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
              
              // Recent Sessions List
              Expanded(
                child: _buildRecentSessionsList(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ],
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

    final sortedSessions = List<StudySession>.from(_allSessions)
      ..sort((a, b) => b.startTime.millisecondsSinceEpoch.compareTo(a.startTime.millisecondsSinceEpoch));
    
    final recentSessions = sortedSessions.take(5).toList();

    return ListView.builder(
      itemCount: recentSessions.length,
      itemBuilder: (context, index) {
        final session = recentSessions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              Icons.play_arrow,
              color: theme.primaryColor,
            ),
            title: Text(
              'Session ${index + 1}',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${_formatTime(Duration(milliseconds: session.timeSpentMs))} • ${_formatDate(session.startTime)}',
              style: theme.textTheme.bodySmall,
            ),
            trailing: Text(
              _formatTime(Duration(milliseconds: session.timeSpentMs)),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(date.year, date.month, date.day);
    
    if (sessionDate == today) {
      return 'Today';
    } else if (sessionDate.difference(today).abs() == const Duration(days: 1)) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
