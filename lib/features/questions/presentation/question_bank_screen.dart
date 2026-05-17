import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/ingestion/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class QuestionBankScreen extends ConsumerStatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  ConsumerState<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends ConsumerState<QuestionBankScreen> {
  final _questionRepo = QuestionRepository();
  final _subjectRepo = SubjectRepository();
  final _topicRepo = TopicRepository();
  final _sourceRepo = SourceRepository();

  List<Question> _allQuestions = [];
  List<Subject> _subjects = [];
  List<Topic> _allTopics = [];
  List<Source> _allSources = [];
  bool _isLoading = true;
  String? _error;

  String _subjectFilter = '';
  String _typeFilter = '';
  String _sourceFilter = '';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final Set<String> _selectedIds = {};
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _questionRepo.init();
      await _subjectRepo.init();
      await _topicRepo.init();
      await _sourceRepo.init();

      final questionsResult = await _questionRepo.getAll();
      final subjectsResult = await _subjectRepo.getAll();
      final topicsResult = await _topicRepo.getAll();
      final sourcesResult = await _sourceRepo.getAll();

      if (mounted) {
        setState(() {
          _allQuestions = questionsResult.data ?? [];
          _subjects = subjectsResult.data ?? [];
          _allTopics = topicsResult.data ?? [];
          _allSources = sourcesResult.data ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<Question> get _filteredQuestions {
    return _allQuestions.where((q) {
      if (_subjectFilter.isNotEmpty && q.subjectId != _subjectFilter) return false;
      if (_typeFilter.isNotEmpty && q.type.name != _typeFilter) return false;
      if (_sourceFilter.isNotEmpty && !q.sourceIds.contains(_sourceFilter)) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!q.text.toLowerCase().contains(query)) return false;
      }
      return true;
    }).toList();
  }

  String? _sourceName(String sourceId) {
    return _allSources.where((s) => s.id == sourceId).firstOrNull?.title;
  }

  String? _subjectName(String subjectId) {
    return _subjects.where((s) => s.id == subjectId).firstOrNull?.name;
  }

  String? _topicName(String topicId) {
    return _allTopics.where((t) => t.id == topicId).firstOrNull?.title;
  }

  Future<void> _deleteQuestion(Question question) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await _questionRepo.delete(question.id);
    if (result.isSuccess && mounted) {
      setState(() {
        _allQuestions.removeWhere((q) => q.id == question.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Question deleted'),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () async {
              await _questionRepo.create(question);
              if (mounted) setState(() => _allQuestions.add(question));
            },
          ),
        ),
      );
    }
  }

  Future<void> _deleteSelected() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Questions'),
        content: Text('Are you sure you want to delete ${_selectedIds.length} question(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final idsToDelete = Set<String>.from(_selectedIds);
    for (final id in idsToDelete) {
      await _questionRepo.delete(id);
    }
    if (mounted) {
      setState(() {
        _allQuestions.removeWhere((q) => _selectedIds.contains(q.id));
        _selectedIds.clear();
        _selectionMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${idsToDelete.length} question(s) deleted')),
      );
    }
  }

  Future<void> _editQuestion(Question question) async {
    final l10n = AppLocalizations.of(context)!;
    final textController = TextEditingController(text: question.text);
    final explanationController = TextEditingController(text: question.explanation ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Question'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(labelText: 'Question text', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: explanationController,
                decoration: const InputDecoration(labelText: 'Explanation', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, {
              'text': textController.text,
              'explanation': explanationController.text,
            }),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;
    final updated = question.copyWith(
      text: result['text'] ?? question.text,
      explanation: result['explanation'] ?? question.explanation,
      updatedAt: DateTime.now(),
    );
    await _questionRepo.save(question.id, updated);
    if (mounted) {
      setState(() {
        final idx = _allQuestions.indexWhere((q) => q.id == question.id);
        if (idx != -1) _allQuestions[idx] = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final filtered = _filteredQuestions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Bank'),
        actions: [
          if (_selectionMode) ...[
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel selection',
              onPressed: () => setState(() { _selectedIds.clear(); _selectionMode = false; }),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete selected',
              onPressed: _selectedIds.isNotEmpty ? _deleteSelected : null,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Select multiple',
              onPressed: () => setState(() { _selectionMode = true; _selectedIds.clear(); }),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, child: Text(l10n.retry)),
                ]))
              : Column(
                  children: [
                    _buildSearchAndFilter(l10n),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text(
                        l10n.questionsCount(filtered.length),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.help_outline, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                                  const SizedBox(height: 16),
                                  Text(l10n.noQuestionsAvailable, style: theme.textTheme.bodyLarge),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: ResponsiveUtils.listPadding(context),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final q = filtered[index];
                                  final isSelected = _selectedIds.contains(q.id);
                                  final subjectName = _subjectName(q.subjectId);
                                  final topicName = _topicName(q.topicId);

                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                                    child: InkWell(
                                      onTap: _selectionMode
                                          ? () => setState(() {
                                                if (isSelected) { _selectedIds.remove(q.id); } else { _selectedIds.add(q.id); }
                                              })
                                          : () => _editQuestion(q),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (_selectionMode)
                                              Padding(
                                                padding: const EdgeInsetsDirectional.only(end: 12, top: 4),
                                                child: Icon(
                                                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                                  color: isSelected ? theme.colorScheme.primary : null,
                                                ),
                                              ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    q.text,
                                                    maxLines: 3,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: theme.textTheme.bodyMedium,
                                                  ),
                                                  const SizedBox(height: 6),
                                                    Wrap(
                                                      spacing: 8,
                                                      runSpacing: 4,
                                                      children: [
                                                        _smallChip(q.type.name, theme),
                                                        _smallChip('Difficulty ${q.difficulty}', theme),
                                                        if (subjectName != null) _smallChip(subjectName, theme),
                                                        if (topicName != null) _smallChip(topicName, theme),
                                                        if (q.sourceIds.isNotEmpty)
                                                          _smallChip('${q.sourceIds.length} source(s)', theme),
                                                        _smallChip(
                                                          q.model != null ? 'AI-generated' : 'Manual',
                                                          theme,
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                            ),
                                            if (!_selectionMode)
                                              PopupMenuButton<String>(
                                                onSelected: (v) {
                                                  if (v == 'edit') _editQuestion(q);
                                                  if (v == 'delete') _deleteQuestion(q);
                                                },
                                                itemBuilder: (_) => [
                                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Text(l10n.delete, style: TextStyle(color: theme.colorScheme.error)),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _smallChip(String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSecondaryContainer)),
    );
  }

  Widget _buildSearchAndFilter(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search questions',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(
                  label: _subjectFilter.isEmpty ? 'All subjects' : _subjectName(_subjectFilter) ?? _subjectFilter,
                  selected: _subjectFilter.isNotEmpty,
                  onTap: () => _showSubjectFilter(l10n),
                  onClear: _subjectFilter.isNotEmpty ? () => setState(() => _subjectFilter = '') : null,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: _typeFilter.isEmpty ? 'All types' : _typeFilter,
                  selected: _typeFilter.isNotEmpty,
                  onTap: () => _showTypeFilter(l10n),
                  onClear: _typeFilter.isNotEmpty ? () => setState(() => _typeFilter = '') : null,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: _sourceFilter.isEmpty ? 'All sources' : (_sourceName(_sourceFilter) ?? _sourceFilter),
                  selected: _sourceFilter.isNotEmpty,
                  onTap: () => _showSourceFilter(l10n),
                  onClear: _sourceFilter.isNotEmpty ? () => setState(() => _sourceFilter = '') : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InputChip(
      label: Text(label),
      selected: selected,
      onPressed: onTap,
      deleteIcon: onClear != null ? const Icon(Icons.close, size: 16) : null,
      onDeleted: onClear,
    );
  }

  void _showSubjectFilter(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('All subjects'),
            trailing: _subjectFilter.isEmpty ? const Icon(Icons.check) : null,
            onTap: () {
              Navigator.pop(ctx);
              setState(() => _subjectFilter = '');
            },
          ),
          ..._subjects.map((s) => ListTile(
            title: Text(s.name),
            trailing: _subjectFilter == s.id ? const Icon(Icons.check) : null,
            onTap: () { Navigator.pop(ctx); setState(() => _subjectFilter = s.id); },
          )),
        ],
      ),
    );
  }

  void _showTypeFilter(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('All types'),
            trailing: _typeFilter.isEmpty ? const Icon(Icons.check) : null,
            onTap: () {
              Navigator.pop(ctx);
              setState(() => _typeFilter = '');
            },
          ),
          ...QuestionType.values.map((t) => ListTile(
            title: Text(t.name),
            trailing: _typeFilter == t.name ? const Icon(Icons.check) : null,
            onTap: () { Navigator.pop(ctx); setState(() => _typeFilter = t.name); },
          )),
        ],
      ),
    );
  }

  void _showSourceFilter(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('All sources'),
            trailing: _sourceFilter.isEmpty ? const Icon(Icons.check) : null,
            onTap: () {
              Navigator.pop(ctx);
              setState(() => _sourceFilter = '');
            },
          ),
          ..._allSources.map((s) => ListTile(
            title: Text(s.title),
            trailing: _sourceFilter == s.id ? const Icon(Icons.check) : null,
            onTap: () { Navigator.pop(ctx); setState(() => _sourceFilter = s.id); },
          )),
        ],
      ),
    );
  }
}
