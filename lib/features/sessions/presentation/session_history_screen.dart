import 'package:flutter/material.dart';
import 'package:studyking/core/constants/timeouts.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/services/progress_export_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/widgets/widgets.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/sessions/presentation/utils/session_utils.dart';
import 'package:studyking/features/sessions/services/session_export_service.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:intl/intl.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class SessionHistoryScreen extends StatefulWidget {
  final SessionRepository? sessionRepository;

  const SessionHistoryScreen({super.key, this.sessionRepository});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> with AutomaticKeepAliveClientMixin {
  static final Logger _logger = const Logger('SessionHistoryScreen');
  late SessionRepository _sessionRepository;
  List<Session> _allSessions = [];
  List<Session> _filteredSessions = [];
  DateTime? _selectedDate;
  String? _selectedSubject;
  bool _isLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _sessionRepository = widget.sessionRepository ?? SessionRepository();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
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
      _logger.w('Error loading sessions', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = AppLocalizations.of(context)!.somethingWentWrong;
        });
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
      final filename = 'session_history_${DateTime.now().millisecondsSinceEpoch}';
      switch (format) {
        case 'csv':
          await SessionExportService.shareCSV(sessions, filename, l10n: l10n);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.sessionHistoryExportedCsv)),
            );
          }
        case 'pdf':
          await SessionExportService.sharePDF(sessions, filename, l10n);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.sessionHistoryExportedPdf)),
            );
          }
        case 'json':
          await SessionExportService.shareJSON(sessions, filename, l10n: l10n);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.sessionHistoryExportedJson)),
            );
          }
        case 'comprehensive':
        case 'comprehensive_pdf':
        case 'comprehensive_json':
          {
            final attemptRepo = AttemptRepository();
            await attemptRepo.init();
            final masteryService = MasteryGraphService();
            await masteryService.init();
            final tracker = StudyProgressTracker(
              attemptRepo: attemptRepo,
              l10n: l10n,
            );
            final exportService = ProgressExportService(
              attemptRepo: attemptRepo,
              masteryService: masteryService,
              tracker: tracker,
            );
            final sidService = StudentIdService();
            final studentId = sidService.getStudentId();
            final compFilename = 'comprehensive_report_${DateTime.now().millisecondsSinceEpoch}';
            switch (format) {
              case 'comprehensive':
                await exportService.shareComprehensiveCSV(studentId, compFilename, l10n);
                break;
              case 'comprehensive_pdf':
                await exportService.shareComprehensivePDF(studentId, compFilename, l10n);
                break;
              case 'comprehensive_json':
                await exportService.shareComprehensiveJSON(studentId, compFilename, l10n);
                break;
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.comprehensiveReportExported)),
              );
            }
          }
      }
    } catch (e) {
      _logger.w('Export failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailed(''))),
        );
      }
    }
  }

  void _showExportSheet(AppLocalizations l10n, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: AppTheme.bottomSheetShape,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.sessionHistoryExport,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _exportTile(l10n, ctx, Icons.table_chart, l10n.exportCsv, l10n.sessionHistoryDescription, 'csv'),
              const Divider(height: 1, indent: 72),
              _exportTile(l10n, ctx, Icons.picture_as_pdf, l10n.exportPdf, l10n.sessionHistoryDescription, 'pdf'),
              const Divider(height: 1, indent: 72),
              _exportTile(l10n, ctx, Icons.code, l10n.labelJson, l10n.sessionHistoryDescription, 'json'),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  l10n.exportComprehensiveReport,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              _exportTile(l10n, ctx, Icons.assignment, l10n.comprehensiveCsv, l10n.exportAllDataDescription, 'comprehensive'),
              const Divider(height: 1, indent: 72),
              _exportTile(l10n, ctx, Icons.picture_as_pdf, l10n.comprehensivePdf, l10n.exportAllDataDescription, 'comprehensive_pdf'),
              const Divider(height: 1, indent: 72),
              _exportTile(l10n, ctx, Icons.code, l10n.comprehensiveJson, l10n.exportAllDataDescription, 'comprehensive_json'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exportTile(AppLocalizations l10n, BuildContext ctx, IconData icon, String title, String subtitle, String format) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        Navigator.pop(ctx);
        _handleExport(format);
      },
    );
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
            style: AppTheme.destructiveButtonStyle(context),
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
                  _sessionRepository.save(session.id, session);
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
            SnackBar(content: Text(l10n.failedToDeleteSession(''))),
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
    super.build(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final totalMinutes = _filteredSessions.fold<int>(
      0,
      (sum, s) => sum + _formatTimeMinutes(s.actualDuration),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sessionHistory),
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
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: l10n.sessionHistoryExport,
              onPressed: () => _showExportSheet(l10n, theme),
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingScreen()
          : _error != null
              ? _buildErrorState(theme)
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
                          Semantics(
                            button: true,
                            selected: _selectedDate != null,
                            label: l10n.filterByDate,
                            child: SizedBox(
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
                          ),
                          Semantics(
                            button: true,
                            selected: _selectedSubject != null,
                            label: l10n.filterBySubject,
                            child: SizedBox(
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
                          ),
                        ],
                      ),
                      ),
                    ],
                  ),
                ),

                MergeSemantics(
                  child: Padding(
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

  Widget _buildErrorState(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            l10n.somethingWentWrong,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              l10n.somethingWentWrong,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loadSessions,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ],
      ),
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

  bool _isStale(Session session) {
    return session.endTime == null &&
        !session.completed &&
        session.startTime.isBefore(DateTime.now().subtract(Timeouts.recentSessionWindow));
  }

  Future<void> _dismissStaleSession(Session session) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.staleSessionLabel),
        content: Text(l10n.cancelLessonConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.noThanks),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final dismissed = session.copyWith(completed: true);
      await _sessionRepository.save(dismissed.id, dismissed);
      _loadSessions();
    }
  }

  Widget _buildSessionsList(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return ListView.separated(
      itemCount: _filteredSessions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final session = _filteredSessions[index];
        final position = _allSessions.indexOf(session);
        final icon = sessionIcon(session.type);
        final color = sessionColor(session.type, theme);
        final isStale = _isStale(session);

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
                  color: (isStale ? theme.colorScheme.error : color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(isStale ? Icons.error_outline : icon,
                    color: isStale ? theme.colorScheme.error : color),
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
                  if (isStale) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(l10n.staleSessionLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          )),
                    ),
                  ],
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
                  if (isStale)
                    TextButton.icon(
                      onPressed: () => _dismissStaleSession(session),
                      icon: const Icon(Icons.close, size: 16),
                      label: Text(l10n.dismissAllMissed),
                    )
                  else ...[
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
    final subjectIds = _allSessions.map((s) => s.subjectId).nonNulls.toSet().toList()..sort();
    if (subjectIds.isEmpty) return;

    final subjectRepo = SubjectRepository();
    await subjectRepo.init();
    final subjectNames = <String, String>{};
    for (final id in subjectIds) {
      final result = await subjectRepo.get(id);
      final subject = result.data;
      subjectNames[id] = subject?.name ?? l10n.unknown;
    }

    if (!mounted) return;
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.filterBySubjectTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: subjectIds.length,
            itemBuilder: (context, index) {
              final id = subjectIds[index];
              final name = subjectNames[id] ?? l10n.unknown;
              return ListTile(
                title: Text(name),
                selected: id == _selectedSubject,
                onTap: () => Navigator.pop(context, id),
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
