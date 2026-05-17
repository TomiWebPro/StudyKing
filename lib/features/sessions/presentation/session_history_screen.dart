import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/services/progress_export_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/widgets/widgets.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/sessions/services/session_export_service.dart';
import 'package:intl/intl.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class SessionHistoryScreen extends StatefulWidget {
  final SessionRepository? sessionRepository;

  const SessionHistoryScreen({super.key, this.sessionRepository});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  final Logger _logger = const Logger('SessionHistoryScreen');
  late SessionRepository _sessionRepository;
  List<Session> _allSessions = [];
  List<Session> _filteredSessions = [];
  DateTime? _selectedDate;
  String? _selectedSubject;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _sessionRepository = widget.sessionRepository ?? SessionRepository();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final sessionsResult = await _sessionRepository.getAll();
      final sessions = sessionsResult.data ?? [];
      if (mounted) {
        setState(() {
          _allSessions = sessions.toList()
            ..sort((a, b) => b.startTime.millisecondsSinceEpoch.compareTo(a.startTime.millisecondsSinceEpoch));
          _isLoading = false;
        });
        _filterSessions();
      }
    } catch (e) {
      _logger.e('Error loading sessions', e);
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

  Future<void> _handleExport(String format) async {
    final l10n = AppLocalizations.of(context)!;
    final sessions = _filteredSessions;

    if (sessions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noSessionsYet)),
        );
      }
      return;
    }

    try {
      switch (format) {
        case 'csv':
          await SessionExportService.shareCSV(
            sessions,
            'session_history_${DateTime.now().millisecondsSinceEpoch}',
            l10n: l10n,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.sessionHistoryExportedCsv)),
            );
          }
        case 'pdf':
          await SessionExportService.sharePDF(
            sessions,
            'session_history_${DateTime.now().millisecondsSinceEpoch}',
            l10n,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.sessionHistoryExportedPdf)),
            );
          }
        case 'json':
          await SessionExportService.shareJSON(
            sessions,
            'session_history_${DateTime.now().millisecondsSinceEpoch}',
            l10n: l10n,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.sessionHistoryExportedJson)),
            );
          }
        case 'comprehensive_csv':
          {
            final exportService = ProgressExportService();
            await exportService.shareComprehensiveCSV(
              StudentIdService().getStudentId(),
              'comprehensive_report_${DateTime.now().millisecondsSinceEpoch}',
              l10n,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.comprehensiveReportExported)),
              );
            }
          }
        case 'comprehensive_pdf':
          {
            final exportService = ProgressExportService();
            await exportService.shareComprehensivePDF(
              StudentIdService().getStudentId(),
              'comprehensive_report_${DateTime.now().millisecondsSinceEpoch}',
              l10n,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.comprehensiveReportExported)),
              );
            }
          }
        case 'comprehensive_json':
          {
            final exportService = ProgressExportService();
            await exportService.shareComprehensiveJSON(
              StudentIdService().getStudentId(),
              'comprehensive_report_${DateTime.now().millisecondsSinceEpoch}',
              l10n,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.comprehensiveReportExported)),
              );
            }
          }
      }
    } catch (e) {
      _logger.e('Export failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailed(e.toString()))),
        );
      }
    }
  }

  Future<bool> _deleteSession(Session session) async {
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
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
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
                  _sessionRepository.save(session);
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
      (sum, s) => sum + _formatTimeMinutes(s.actualDuration),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sessionHistory),
        elevation: 0,
        actions: [
          if (_selectedDate != null || _selectedSubject != null)
            Semantics(
              label: l10n.clearFilters,
              child: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearFilters,
                tooltip: l10n.clearFilters,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.share),
              tooltip: l10n.sessionHistoryExport,
              onSelected: (value) => _handleExport(value),
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    l10n.sessionHistoryExport,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'csv',
                  child: ListTile(
                    leading: const Icon(Icons.table_chart),
                    title: Text(l10n.exportCsv),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'pdf',
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf),
                    title: Text(l10n.exportPdf),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'json',
                  child: ListTile(
                    leading: const Icon(Icons.code),
                    title: Text(l10n.labelJson),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    l10n.exportComprehensiveReport,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'comprehensive_csv',
                  child: ListTile(
                    leading: const Icon(Icons.assignment),
                    title: Text(l10n.comprehensiveCsv),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'comprehensive_pdf',
                  child: ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(l10n.comprehensivePdf),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'comprehensive_json',
                  child: ListTile(
                    leading: const Icon(Icons.assignment),
                    title: Text(l10n.comprehensiveJson),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FocusTraversalGroup(
            child: Column(
              children: [
                Container(
                  padding: ResponsiveUtils.screenPadding(context),
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FocusTraversalGroup(
                        child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          SizedBox(
                            width: ResponsiveUtils.breakpointOf(context).isMobile ? double.infinity : null,
                            child: OutlinedButton.icon(
                              onPressed: () => _showDatePicker(),
                              icon: Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                              label: Text(
                                _selectedDate != null
                                    ? DateFormat.yMd(l10n.localeName).format(_selectedDate!)
                                    : l10n.filterByDate,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: ResponsiveUtils.breakpointOf(context).isMobile ? double.infinity : null,
                            child: OutlinedButton.icon(
                              onPressed: () => _showSubjectFilter(),
                              icon: Icon(Icons.folder, color: theme.colorScheme.primary),
                              label: Text(
                                _selectedSubject != null ? _selectedSubject! : l10n.filterBySubject,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: ResponsiveUtils.screenPadding(context),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceEvenly,
                    children: [
                      _buildSummaryStat(context, l10n.sessionsLabel, formatDecimal(_filteredSessions.length.toDouble(), l10n.localeName), Icons.history),
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
            ),
        );
  }

  Widget _buildSummaryStat(BuildContext context, String label, String value, IconData icon) {
    return MetricCard(
      label: label,
      value: value,
      icon: icon,
      accent: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: ResponsiveUtils.emptyStateIconSize(context), color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
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
        final position = _allSessions.indexOf(session);
        final icon = _sessionIcon(session.type);
        final color = _sessionColor(session.type, theme);

        return Semantics(
          hint: l10n.swipeToDelete,
          child: Dismissible(
          key: Key(session.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) => _deleteSession(session),
          background: Semantics(
            excludeSemantics: true,
            child: Container(
            alignment: AlignmentDirectional.centerEnd,
            padding: const EdgeInsetsDirectional.only(end: 16),
            color: Theme.of(context).colorScheme.error,
            child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
          ),),
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.horizontalSpacing(context), vertical: 4),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              title: Row(
                children: [
                  Text(
                    l10n.sessionNumber(_allSessions.length - position),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 14, color: color),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${formatDateFromContext(context, session.startTime)} • '
                    '${session.questionsAnswered > 0 ? l10n.questionsCountLabel(session.questionsAnswered) : l10n.noQuestions}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (session.correctAnswers > 0)
                    Text(
                      l10n.correctOf(session.correctAnswers, session.questionsAnswered),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: session.questionsAnswered > 0 &&
                                session.correctAnswers >= (session.questionsAnswered / 2)
                            ? theme.colorScheme.primary
                            : theme.colorScheme.tertiary,
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatDurationFromContext(context, session.actualDuration),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: l10n.deleteSession,
                    button: true,
                    child: IconButton(
                      icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                      tooltip: l10n.deleteSession,
                      onPressed: () => _deleteSession(session),
                    ),
                  ),
                ],
              ),
              isThreeLine: true,
            ),
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
    final subjects = _allSessions.map((s) => s.subjectId).nonNulls.toSet().toList()..sort();

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
}
