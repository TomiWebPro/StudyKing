import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/core/data/repositories/study_session_repository.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/widgets/widgets.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSession),
        content: Text(l10n.deleteSessionConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.delete),
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
              content: Text(l10n.sessionDeleted),
              action: SnackBarAction(
                label: l10n.undo,
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
            SnackBar(content: Text(l10n.failedToDeleteSession(e.toString()))),
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
    final l10n = AppLocalizations.of(context)!;
    final totalMinutes = _filteredSessions.fold<int>(
      0,
      (sum, s) => sum + _formatTimeMinutes(Duration(milliseconds: s.timeSpentMs)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sessionHistory),
        elevation: 0,
        actions: [
          if (_selectedDate != null || _selectedSubject != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearFilters,
              tooltip: l10n.clearFilters,
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
                                    : l10n.filterByDate,
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
                                _selectedSubject != null ? _selectedSubject! : l10n.filterBySubject,
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
                      _buildSummaryStat(context, l10n.sessionsLabel, _filteredSessions.length.toString(), Icons.history),
                      _buildSummaryStat(context, l10n.totalTime, formatDurationFromContext(context, Duration(minutes: totalMinutes)), Icons.access_time),
                      _buildSummaryStat(
                        context,
                        l10n.average,
                        _filteredSessions.isNotEmpty
                            ? formatDurationFromContext(context, Duration(minutes: totalMinutes ~/ _filteredSessions.length))
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

  Widget _buildSummaryStat(BuildContext context, String label, String value, IconData icon) {
    return MetricCard(
      label: label,
      value: value,
      icon: icon,
      accent: Theme.of(context).primaryColor,
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: theme.disabledColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            _selectedDate != null || _selectedSubject != null
                ? l10n.noSessionsFoundForFilters
                : l10n.noSessionsYet,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color ?? theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedDate != null || _selectedSubject != null
                ? l10n.tryAdjustingFilters
                : l10n.startStudyingToTrack,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
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
            color: Theme.of(context).colorScheme.error,
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
                l10n.sessionNumber(_allSessions.length - position),
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
                    '${session.questionsAnswered > 0 ? l10n.questionsCountLabel(session.questionsAnswered) : l10n.noQuestions}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (session.correctAnswers > 0)
                    Text(
                      l10n.correctOf(session.correctAnswers, session.questionsAnswered),
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
                formatDurationFromContext(context, timeSpent),
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
    final l10n = AppLocalizations.of(context)!;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: l10n.selectDateToFilter,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _filterSessions();
    }
  }

  Future<void> _showSubjectFilter() async {
    final l10n = AppLocalizations.of(context)!;
    final subjects = _allSessions.map((s) => s.subjectId).toSet().toList()..sort();

    if (subjects.isEmpty) return;

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.filterBySubjectTitle),
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
            child: Text(l10n.clearFilterLabel),
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
