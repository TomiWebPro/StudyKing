import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/core/data/repositories/study_session_repository.dart';
import 'package:studyking/core/utils/time_utils.dart';

class SessionHistoryScreen extends StatefulWidget {
  final StudySessionRepository? sessionRepository;

  const SessionHistoryScreen({super.key, this.sessionRepository});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  late StudySessionRepository _sessionRepository;
  List<StudySession> _allSessions = [];
  List<StudySession> _filteredSessions = [];
  DateTime? _selectedDate;
  String? _selectedSubject;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _sessionRepository = widget.sessionRepository ?? StudySessionRepository();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      await _sessionRepository.init();
      final sessions = await _sessionRepository.getAll();
      if (mounted) {
        setState(() {
          _allSessions = sessions.toList()
            ..sort((a, b) => b.startTime.millisecondsSinceEpoch.compareTo(a.startTime.millisecondsSinceEpoch));
          _isLoading = false;
        });
        _filterSessions();
      }
    } catch (e) {
      debugPrint('Error loading sessions: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterSessions() {
    var result = _allSessions;

    if (_selectedDate != null) {
      result = result.where((s) => s.startTime.isSameDay(_selectedDate!)).toList();
    }

    if (_selectedSubject != null && _selectedSubject!.isNotEmpty) {
      result = result.where((s) => s.subjectId == _selectedSubject).toList();
    }

    if (mounted) {
      setState(() {
        _filteredSessions = result;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedDate = null;
      _selectedSubject = null;
    });
    _filterSessions();
  }

  Future<bool> _deleteSession(StudySession session) async {
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
      try {
        await _sessionRepository.delete(session.id);
        if (mounted) {
          setState(() {
            _allSessions.remove(session);
            _filteredSessions.remove(session);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Session deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  _sessionRepository.create(session);
                  _loadSessions();
                },
              ),
            ),
          );
        }
        return true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete session: $e')),
          );
        }
        return false;
      }
    }
    return false;
  }

  int _formatTimeMinutes(Duration duration) {
    return duration.inMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalMinutes = _filteredSessions.fold<int>(
      0,
      (sum, s) => sum + _formatTimeMinutes(Duration(milliseconds: s.timeSpentMs)),
    );

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: theme.primaryColor.withValues(alpha: 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showDatePicker(),
                              icon: Icon(Icons.calendar_today, color: theme.primaryColor),
                              label: Text(
                                _selectedDate != null
                                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
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
                              onPressed: () => _showSubjectFilter(),
                              icon: Icon(Icons.folder, color: theme.primaryColor),
                              label: Text(
                                _selectedSubject != null ? _selectedSubject! : 'Filter by Subject',
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

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSummaryStat('Sessions', _filteredSessions.length.toString(), Icons.history),
                      _buildSummaryStat('Total Time', formatDuration(Duration(minutes: totalMinutes)), Icons.access_time),
                      _buildSummaryStat(
                        'Average',
                        _filteredSessions.isNotEmpty
                            ? formatDuration(Duration(minutes: totalMinutes ~/ _filteredSessions.length))
                            : '0m',
                        Icons.schedule,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _filteredSessions.isEmpty
                      ? _buildEmptyState(theme)
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: theme.disabledColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            _selectedDate != null || _selectedSubject != null
                ? 'No sessions found for selected filters'
                : 'No sessions yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color ?? theme.textTheme.bodySmall?.color,
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
        final position = _allSessions.indexOf(session);

        return Dismissible(
          key: Key(session.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) => _deleteSession(session),
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
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.play_arrow, color: theme.primaryColor),
              ),
              title: Text(
                'Session ${_allSessions.length - position}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${formatDate(session.startTime)} • '
                    '${session.questionsAnswered > 0 ? '${session.questionsAnswered} questions' : 'No questions'}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (session.correctAnswers > 0)
                    Text(
                      'Correct: ${session.correctAnswers}/${session.questionsAnswered}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: session.questionsAnswered > 0 &&
                                session.correctAnswers >= (session.questionsAnswered / 2)
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                ],
              ),
              trailing: Text(
                formatDuration(timeSpent),
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

  Future<void> _showDatePicker() async {
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

  Future<void> _showSubjectFilter() async {
    final subjects = _allSessions.map((s) => s.subjectId).toSet().toList()..sort();

    if (subjects.isEmpty) return;

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Subject'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return ListTile(
                title: Text(subject),
                selected: subject == _selectedSubject,
                onTap: () => Navigator.pop(context, subject),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    setState(() {
      _selectedSubject = selected;
    });
    _filterSessions();
  }
}
