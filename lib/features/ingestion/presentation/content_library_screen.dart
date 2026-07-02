import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/widgets/error_retry_widget.dart';
import 'package:studyking/core/widgets/loading_screen.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/questions/providers/question_providers.dart'
    show questionRepositoryProvider, sourceRepositoryProvider;
import 'package:studyking/features/subjects/providers/subject_repository_provider.dart';
import 'package:studyking/core/utils/label_helpers.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class ContentLibraryScreen extends ConsumerStatefulWidget {
  final String? preselectedSubjectId;

  const ContentLibraryScreen({
    super.key,
    this.preselectedSubjectId,
  });

  @override
  ConsumerState<ContentLibraryScreen> createState() => _ContentLibraryScreenState();
}

class _ContentLibraryScreenState extends ConsumerState<ContentLibraryScreen> {
  static final Logger _logger = const Logger('ContentLibraryScreen');
  late final SourceRepository _sourceRepo;
  late final QuestionRepository _questionRepo;
  List<Source> _sources = [];
  List<Subject> _subjects = [];
  bool _isLoading = true;
  String? _error;

  String _subjectFilter = '';
  Set<String> _typeFilters = {};
  Set<String> _statusFilters = {};
  SortField _sortField = SortField.uploadDate;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _sourceRepo = ref.read(sourceRepositoryProvider);
    _questionRepo = ref.read(questionRepositoryProvider);
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _sourceRepo.init();
      await _questionRepo.init();
      final subjectsRepo = ref.read(subjectRepositoryProvider);
      await subjectsRepo.init();
      final subjectsResult = await subjectsRepo.getAll();
      final sourcesResult = await _sourceRepo.getAll();
      if (mounted) {
        setState(() {
          _sources = sourcesResult.data ?? [];
          _subjects = subjectsResult.data ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.w('Failed to load sources', e);
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)!.somethingWentWrong;
          _isLoading = false;
        });
      }
    }
  }

  String? _subjectName(String subjectId) {
    if (subjectId.isEmpty) return null;
    return _subjects.where((s) => s.id == subjectId).firstOrNull?.name;
  }

  IconData _typeIcon(SourceType type) {
    switch (type) {
      case SourceType.pdf:
        return Icons.picture_as_pdf;
      case SourceType.syllabus:
        return Icons.menu_book;
      case SourceType.textbook:
        return Icons.book;
      case SourceType.video:
        return Icons.video_library;
      case SourceType.lectureNotes:
        return Icons.note;
      case SourceType.externalResource:
        return Icons.article;
      case SourceType.image:
        return Icons.image;
      case SourceType.webPage:
        return Icons.language;
      case SourceType.audio:
        return Icons.headphones;
      case SourceType.document:
        return Icons.description;
    }
  }

  Color _statusColor(ProcessingStatus status, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case ProcessingStatus.completed:
        return cs.primary;
      case ProcessingStatus.failed:
        return cs.error;
      case ProcessingStatus.pending:
      case ProcessingStatus.extracting:
      case ProcessingStatus.classifying:
      case ProcessingStatus.summarizing:
      case ProcessingStatus.generatingQuestions:
      case ProcessingStatus.validating:
        return cs.tertiary;
    }
  }

  List<Source> get _filteredSources {
    var result = _sources.where((s) {
      if (widget.preselectedSubjectId != null && widget.preselectedSubjectId!.isNotEmpty) {
        if (s.subjectId != widget.preselectedSubjectId) return false;
      }
      if (_subjectFilter.isNotEmpty && s.subjectId != _subjectFilter) return false;
      if (_typeFilters.isNotEmpty && !_typeFilters.contains(s.type.name)) return false;
      if (_statusFilters.isNotEmpty && !_statusFilters.contains(s.statusEnum.name)) return false;
      return true;
    }).toList();

    result.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case SortField.title:
          cmp = a.title.compareTo(b.title);
        case SortField.uploadDate:
          cmp = a.id.compareTo(b.id);
        case SortField.status:
          cmp = a.processingStatus.compareTo(b.processingStatus);
        case SortField.type:
          cmp = a.type.index.compareTo(b.type.index);
      }
      return _sortAscending ? cmp : -cmp;
    });

    return result;
  }

  Future<void> _deleteSource(Source source) async {
    final l10n = AppLocalizations.of(context)!;
    final deleteQuestions = source.generatedQuestionIds.isNotEmpty;
    bool alsoDeleteQuestions = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInnerState) => AlertDialog(
          title: Text(l10n.deleteSourceTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.deleteSourceBody),
              if (deleteQuestions) ...[
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: Text(l10n.alsoDeleteQuestions),
                  value: alsoDeleteQuestions,
                  onChanged: (v) => setInnerState(() => alsoDeleteQuestions = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: Text(l10n.delete),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    if (alsoDeleteQuestions) {
      for (final qId in source.generatedQuestionIds) {
        await _questionRepo.delete(qId);
      }
    }

    final result = await _sourceRepo.delete(source.id);
    if (result.isSuccess && mounted) {
      setState(() {
        _sources.removeWhere((s) => s.id == source.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.sourceDeleted),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () async {
              await _sourceRepo.create(source);
              if (mounted) {
                setState(() {
                  _sources.add(source);
                });
              }
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final filteredSources = _filteredSources;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.contentLibrary),
        actions: [
          IconButton(
            icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
            tooltip: l10n.sortOrder,
            onPressed: () => setState(() => _sortAscending = !_sortAscending),
          ),
          PopupMenuButton<SortField>(
            icon: const Icon(Icons.sort),
            tooltip: l10n.sortBy,
            onSelected: (field) => setState(() => _sortField = field),
            itemBuilder: (_) => [
              PopupMenuItem(value: SortField.uploadDate, child: Text(l10n.date)),
              PopupMenuItem(value: SortField.title, child: Text(l10n.title)),
              PopupMenuItem(value: SortField.status, child: Text(l10n.status)),
              PopupMenuItem(value: SortField.type, child: Text(l10n.type)),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingScreen()
          : _error != null
              ? ErrorRetryWidget(message: _error!, onRetry: _load)
              : Column(
                  children: [
                    _buildFilterBar(l10n),
                    const Divider(height: 1),
                    Expanded(
                      child: filteredSources.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.folder_open, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                                  const SizedBox(height: 16),
                                  Text(l10n.noSourcesAvailable, style: theme.textTheme.bodyLarge),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.cloud_upload),
                                    label: Text(l10n.uploadMaterials),
                                    onPressed: () => Navigator.pushNamed(context, AppRoutes.upload),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: ResponsiveUtils.listPadding(context),
                                itemCount: filteredSources.length,
                                itemBuilder: (context, index) {
                                  final source = filteredSources[index];
                                  final subjectName = _subjectName(source.subjectId);
                                  return _SourceListTile(
                                    source: source,
                                    subjectName: subjectName,
                                    typeIcon: _typeIcon(source.type),
                                    statusColor: _statusColor(source.statusEnum, context),
                                    statusLabel: processingStatusLabel(source.statusEnum, l10n),
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.sourceDetail,
                                        arguments: source.id,
                                      );
                                    },
                                    onDelete: () => _deleteSource(source),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFilterBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, top: 8, end: 16, bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Row(
          children: [
            _filterChip(
              label: _subjectFilter.isEmpty ? l10n.allSubjects : _subjectName(_subjectFilter) ?? _subjectFilter,
              selected: _subjectFilter.isNotEmpty,
              onSelected: () => _showSubjectFilter(l10n),
              onClear: _subjectFilter.isNotEmpty ? () => setState(() => _subjectFilter = '') : null,
            ),
            const SizedBox(width: 8),
            _filterChip(
              label: _typeFilters.isEmpty
                  ? l10n.allTypes
                  : '${_typeFilters.length} ${l10n.selected}',
              selected: _typeFilters.isNotEmpty,
              onSelected: () => _showTypeFilter(l10n),
              onClear: _typeFilters.isNotEmpty ? () => setState(() => _typeFilters = {}) : null,
            ),
            const SizedBox(width: 8),
            _filterChip(
              label: _statusFilters.isEmpty
                  ? l10n.allStatuses
                  : '${_statusFilters.length} ${l10n.selected}',
              selected: _statusFilters.isNotEmpty,
              onSelected: () => _showStatusFilter(l10n),
              onClear: _statusFilters.isNotEmpty ? () => setState(() => _statusFilters = {}) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    VoidCallback? onClear,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InputChip(
        label: Text(label),
        selected: selected,
        onPressed: onSelected,
        deleteIcon: onClear != null
            ? Semantics(
                label: '${l10n.delete} $label',
                child: const Icon(Icons.close, size: 16),
              )
            : null,
        onDeleted: onClear,
      ),
    );
  }

  void _showSubjectFilter(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(l10n.allSubjects),
            trailing: _subjectFilter.isEmpty ? const Icon(Icons.check) : null,
            onTap: () {
              Navigator.pop(ctx);
              setState(() => _subjectFilter = '');
            },
          ),
          ..._subjects.map((s) => ListTile(
                title: Text(s.name),
                trailing: _subjectFilter == s.id ? const Icon(Icons.check) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _subjectFilter = s.id);
                },
              )),
        ],
      ),
    );
  }

  void _showTypeFilter(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInnerState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.allTypes),
              trailing: _typeFilters.isEmpty ? const Icon(Icons.check) : null,
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _typeFilters = {});
              },
            ),
            ...SourceType.values.map((t) => CheckboxListTile(
                  title: Text(sourceTypeLabel(t, l10n)),
                  value: _typeFilters.contains(t.name),
                  onChanged: (val) {
                    setInnerState(() {
                      if (val == true) {
                        setState(() => _typeFilters = {..._typeFilters, t.name});
                      } else {
                        setState(() => _typeFilters = {..._typeFilters}..remove(t.name));
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.platform,
                )),
          ],
        ),
      ),
    );
  }

  void _showStatusFilter(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInnerState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.allStatuses),
              trailing: _statusFilters.isEmpty ? const Icon(Icons.check) : null,
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _statusFilters = {});
              },
            ),
            ...ProcessingStatus.values.where((s) => s != ProcessingStatus.extracting && s != ProcessingStatus.validating).map((s) => CheckboxListTile(
                  title: Text(processingStatusLabel(s, l10n)),
                  value: _statusFilters.contains(s.name),
                  onChanged: (val) {
                    setInnerState(() {
                      if (val == true) {
                        setState(() => _statusFilters = {..._statusFilters, s.name});
                      } else {
                        setState(() => _statusFilters = {..._statusFilters}..remove(s.name));
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.platform,
                )),
          ],
        ),
      ),
    );
  }
}

enum SortField { title, uploadDate, status, type }

class _SourceListTile extends StatelessWidget {
  final Source source;
  final String? subjectName;
  final IconData typeIcon;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SourceListTile({
    required this.source,
    this.subjectName,
    required this.typeIcon,
    required this.statusColor,
    required this.statusLabel,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(source.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 24),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.deleteSourceTitle),
            content: Text(l10n.deleteSourceBody),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: AppTheme.destructiveButtonStyle(ctx),
                child: Text(l10n.delete),
              ),
            ],
          ),
        );
        return confirmed == true;
      },
      onDismissed: (_) => onDelete(),
      child: Semantics(
        button: true,
        label: '${source.title}${subjectName != null ? ", $subjectName" : ""}, $statusLabel',
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(typeIcon, color: theme.colorScheme.primary, size: 20),
            ),
            title: Text(source.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subjectName != null)
                  Text(subjectName!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (source.statusEnum == ProcessingStatus.failed) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.error_outline, size: 14, color: theme.colorScheme.error),
                    ],
                  ],
                ),
                if (source.createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    formatDateFromContext(context, source.createdAt!),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (source.statusEnum == ProcessingStatus.failed)
                  IconButton(
                    icon: Icon(Icons.refresh, size: 20, color: theme.colorScheme.error),
                    tooltip: l10n.reprocess,
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.sourceDetail, arguments: source.id);
                    },
                  ),
                const SizedBox(width: 4),
                Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right),
              ],
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
