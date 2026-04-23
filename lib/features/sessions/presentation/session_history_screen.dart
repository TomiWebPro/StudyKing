import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/core/data/repositories/study_session_repository.dart';

/// Session History Screen - View all past sessions
class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  late StudySessionRepository _sessionRepository;
  List<StudySession> _allSessions = [];
  List<StudySession> _filteredSessions = [];
  DateTime? _selectedDate;
  String? _selectedSubject;

  @override
  void initState() {
    super.initState();
    _sessionRepository = StudySessionRepository();
    _loadSessions();
    _filterSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final sessions = await _sessionRepository.getAll();
      if (mounted) {
        setState(() {
          _allSessions = sessions.toList();
          _filteredSessions = _allSessions;
        });
      }
    } catch (e) {
      debugPrint('Error loading sessions: $e');
    }
  }

  void _filterSessions() {
    var result = _allSessions;

    if (_selectedDate != null) {
      final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      result = result.where((s) => _isSameDay(s.startTime, _selectedDate!)).toList();
    }

    if (_selectedSubject != null && _selectedSubject!.isNotEmpty) {
      result = result.where((s) => s.subjectId == _selectedSubject).toList();
    }

    result.sort((a, b) => b.startTime.millisecondsSinceEpoch.compareTo(a.startTime.millisecondsSinceEpoch));

    if (mounted) {
      setState(() {
        _filteredSessions = result;
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _clearFilters() {
    setState(() {
      _selectedDate = null;
      _selectedSubject = null;
    });
    _filterSessions();
  }

  void _deleteSession(StudySession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text('Are you sure you want to delete this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _sessionRepository.delete(session.id);
      _loadSessions();
    }
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

  int _formatTimeMinutes(Duration duration) {
    return duration.inMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalMinutes = _filteredSessions.fold<int>(0, (sum, s) => sum + _formatTimeMinutes(Duration(milliseconds: s.timeSpentMs)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session History'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_selectedDate != null || _selectedSubject != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearFilters,
              tooltip: 'Clear filters',
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Controls
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.primaryColor.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDateFilter(),
                        icon: Icon(Icons.calendar_today, color: theme.primaryColor),
                        label: Text(
                          _selectedDate != null
                              ? '📅 ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : 'Filter by Date',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Subject filter would go here
                        },
                        icon: Icon(Icons.folder, color: theme.primaryColor),
                        label: Text(
                          _selectedSubject != null ? '📚 Subject' : 'Filter by Subject',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Summary Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryStat('Sessions', _filteredSessions.length.toString(), Icons.history),
                _buildSummaryStat('Total Time', _formatTime(Duration(minutes: totalMinutes)), Icons.access_time),
                _buildSummaryStat('Average', _filteredSessions.isNotEmpty
                    ? _formatTime(Duration(minutes: totalMinutes ~/ _filteredSessions.length))
                    : '0m', Icons.schedule),
              ],
            ),
          ),

          // Sessions List
          Expanded(
            child: _filteredSessions.isEmpty
                ? _buildEmptyState()
                : _buildSessionsList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.primaryColor, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: theme.disabledColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            _selectedDate != null || _selectedSubject != null
                ? 'No sessions found for selected filters'
                : 'No sessions yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedDate != null || _selectedSubject != null
                ? 'Try adjusting your filters'
                : 'Start studying to track your progress',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList(ThemeData theme) {
    return ListView.separated(
      itemCount: _filteredSessions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final session = _filteredSessions[index];
        final timeSpent = Duration(milliseconds: session.timeSpentMs);

        return Dismissible(
          key: Key(session.id),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) => _deleteSession(session),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.play_arrow, color: theme.primaryColor),
              ),
              title: Text(
                'Session ${index + 1}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(session.startTime)} • '
                    '${session.questionsAnswered > 0 ? '${session.questionsAnswered} questions' : 'No questions'}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (session.correctAnswers > 0)
                    Text(
                      'Correct: ${session.correctAnswers}/${session.questionsAnswered}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: session.questionsAnswered > 0 && session.correctAnswers >= (session.questionsAnswered / 2)
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                ],
              ),
              trailing: Text(
                _formatTime(timeSpent),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              isThreeLine: true,
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDateFilter() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'Select a date to filter sessions',
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _filterSessions();
    }
  }
}
