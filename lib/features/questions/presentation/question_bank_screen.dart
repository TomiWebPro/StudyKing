import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/utils/string_extensions.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/utils/label_helpers.dart';
import 'package:studyking/core/utils/id_generator.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/widgets/error_retry_widget.dart';
import 'package:studyking/core/widgets/loading_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider, sourceRepositoryProvider;
import 'package:studyking/features/subjects/providers/subject_repository_provider.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/core/utils/question_export_utils.dart';
import 'package:studyking/core/utils/question_import_utils.dart';

class QuestionBankScreen extends ConsumerStatefulWidget {
  final String? initialQuestionId;

  const QuestionBankScreen({
    super.key,
    this.initialQuestionId,
  });

  @override
  ConsumerState<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends ConsumerState<QuestionBankScreen> {
  static final Logger _logger = const Logger('QuestionBankScreen');
  late final QuestionRepository _questionRepo;
  late final SubjectRepository _subjectRepo;
  late final TopicRepository _topicRepo;
  late final SourceRepository _sourceRepo;

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
  bool? _modelFilter; // null = all, true = manual (model == null), false = AI (model != null)
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  final Set<String> _selectedIds = {};
  bool _selectionMode = false;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _questionRepo = ref.read(questionRepositoryProvider);
    _subjectRepo = ref.read(subjectRepositoryProvider);
    _topicRepo = ref.read(topicRepositoryProvider);
    _sourceRepo = ref.read(sourceRepositoryProvider);
    _load();
    _searchController.addListener(() {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() => _searchQuery = _searchController.text);
        }
      });
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
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
        if (widget.initialQuestionId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final idx = _allQuestions.indexWhere((q) => q.id == widget.initialQuestionId);
            if (idx >= 0) {
              _scrollController.animateTo(
                idx * 100.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        }
      }
    } catch (e) {
      _logger.w('Failed to load questions', e);
      if (mounted) setState(() { _error = AppLocalizations.of(context)!.somethingWentWrong; _isLoading = false; });
    }
  }

  List<Question> get _filteredQuestions {
    return _allQuestions.where((q) {
      if (_subjectFilter.isNotEmpty && q.subjectId != _subjectFilter) return false;
      if (_typeFilter.isNotEmpty && q.type.index.toString() != _typeFilter) return false;
      if (_sourceFilter.isNotEmpty && !q.sourceIds.contains(_sourceFilter)) return false;
      if (_modelFilter != null) {
        final isManual = q.model == null;
        if (_modelFilter! != isManual) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.normalized;
        if (!q.text.normalized.contains(query)) return false;
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
        title: Text(l10n.deleteQuestion),
        content: Text(l10n.deleteQuestionConfirm),
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
    if (confirmed != true || !mounted) return;

    final result = await _questionRepo.delete(question.id);
    if (result.isSuccess && mounted) {
      setState(() {
        _allQuestions.removeWhere((q) => q.id == question.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.questionDeleted),
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
        title: Text(l10n.deleteQuestions),
        content: Text(l10n.deleteQuestionsConfirm(_selectedIds.length)),
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
        SnackBar(content: Text(l10n.questionsDeleted(idsToDelete.length))),
      );
    }
  }

  Future<void> _exportQuestions() async {
    final l10n = AppLocalizations.of(context)!;
    final filtered = _filteredQuestions;
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noQuestionsAvailable)),
      );
      return;
    }

    final format = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.exportBackup),
        content: Text(l10n.questionsCount(filtered.length)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, 'csv'), child: Text(l10n.exportCsv)),
          FilledButton(onPressed: () => Navigator.pop(ctx, 'json'), child: Text('JSON')),
        ],
      ),
    );
    if (format == null || !mounted) return;

    final result = format == 'csv'
        ? await QuestionExportUtils.exportAsCsv(filtered)
        : await QuestionExportUtils.exportAsJson(filtered);

    if (result.isSuccess && mounted) {
      await QuestionExportUtils.shareFile(result.data!);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(result.error ?? ''))),
      );
    }
  }

  Future<void> _batchImportQuestions() async {
    final l10n = AppLocalizations.of(context)!;
    final textController = TextEditingController();
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.createQuestion),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.questionTextHint),
              const SizedBox(height: 8),
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: l10n.questionTextHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 8,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.save),
            ),
          ],
        ),
      );
      if (result != true || !mounted) return;
      final text = textController.text.trim();
      if (text.isEmpty) return;
      final importResult = await QuestionImportUtils.importFromText(text);
      if (importResult.isSuccess && importResult.data != null && mounted) {
        var saved = 0;
        for (final q in importResult.data!) {
          final saveResult = await _questionRepo.create(q);
          if (saveResult.isSuccess) {
            saved++;
            _allQuestions.add(q);
          }
        }
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.questionsCount(saved))),
          );
        }
      }
    } finally {
      textController.dispose();
    }
  }

  Future<void> _editQuestion(Question question) async {
    final l10n = AppLocalizations.of(context)!;
    final textController = TextEditingController(text: question.text);
    final explanationController = TextEditingController(text: question.explanation ?? '');
    final optionControllers = question.options.map((o) => TextEditingController(text: o)).toList();
    if (optionControllers.isEmpty) {
      optionControllers.add(TextEditingController());
      optionControllers.add(TextEditingController());
    }
    String selectedSubjectId = question.subjectId;
    String selectedTopicId = question.topicId;
    String selectedType = question.type.name;
    String selectedDifficulty = ['easy', 'medium', 'hard'][(question.difficulty - 1).clamp(0, 2)];
    int? selectedCorrectOption;
    final selectedCorrectOptions = <int>{};
    final selectedSourceIds = Set<String>.from(question.sourceIds);

    if (question.markscheme != null) {
      final correct = question.markscheme!.correctAnswer;
      final optIdx = question.options.indexOf(correct);
      if (optIdx >= 0) {
        selectedCorrectOption = optIdx;
      }
    }

    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setInnerState) => AlertDialog(
            title: Text(l10n.editQuestion),
            content: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    decoration: InputDecoration(labelText: l10n.questionText, border: const OutlineInputBorder()),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSubjectId.isEmpty ? null : selectedSubjectId,
                    decoration: InputDecoration(
                      labelText: l10n.subject,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: '', child: Text(l10n.none)),
                      ..._subjects.map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name),
                      )),
                    ],
                    onChanged: (v) {
                      selectedSubjectId = v ?? '';
                      setInnerState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedTopicId.isEmpty ? null : selectedTopicId,
                    decoration: InputDecoration(
                      labelText: l10n.topics,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: '', child: Text(l10n.none)),
                      ..._allTopics.where((t) => selectedSubjectId.isEmpty || t.subjectId == selectedSubjectId).map((t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(t.title),
                      )),
                    ],
                    onChanged: (v) {
                      selectedTopicId = v ?? '';
                      setInnerState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: InputDecoration(
                      labelText: l10n.type,
                      border: const OutlineInputBorder(),
                    ),
                    items: QuestionType.values.map((t) => DropdownMenuItem(
                      value: t.name,
                      child: Text(questionTypeLabel(t, l10n)),
                    )).toList(),
                    onChanged: (v) {
                      selectedType = v ?? QuestionType.singleChoice.name;
                      setInnerState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDifficulty,
                    decoration: InputDecoration(
                      labelText: l10n.difficulty,
                      border: const OutlineInputBorder(),
                    ),
                    items: ['easy', 'medium', 'hard'].map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(d[0].toUpperCase() + d.substring(1)),
                    )).toList(),
                    onChanged: (v) => selectedDifficulty = v ?? 'easy',
                  ),
                  if (_allSources.where((s) => selectedSubjectId.isEmpty || s.subjectId == selectedSubjectId).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: l10n.sources,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: '', child: Text(l10n.none)),
                        ..._allSources.where((s) => selectedSubjectId.isEmpty || s.subjectId == selectedSubjectId).map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.title),
                        )),
                      ],
                      onChanged: (v) {
                        if (v != null && v.isNotEmpty) {
                          setInnerState(() {
                            if (selectedSourceIds.contains(v)) {
                              selectedSourceIds.remove(v);
                            } else {
                              selectedSourceIds.add(v);
                            }
                          });
                        }
                      },
                    ),
                    if (selectedSourceIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: selectedSourceIds.map((sid) {
                            final name = _sourceName(sid) ?? sid;
                            return Chip(
                              label: Text(name, style: const TextStyle(fontSize: 12)),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => setInnerState(() => selectedSourceIds.remove(sid)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                  if (selectedType == QuestionType.singleChoice.name ||
                      selectedType == QuestionType.multiChoice.name) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    Text(l10n.answerOptions, style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...[
                      if (selectedType == QuestionType.singleChoice.name)
                        RadioGroup<int?>(
                          groupValue: selectedCorrectOption,
                          onChanged: (v) => setInnerState(() => selectedCorrectOption = v),
                          child: Column(
                            children: List.generate(optionControllers.length, (i) {
                              final controller = optionControllers[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Radio<int?>(value: i),
                                    Expanded(
                                      child: TextField(
                                        controller: controller,
                                        decoration: InputDecoration(
                                          hintText: '${l10n.addOption} ${i + 1}',
                                          border: const OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    if (optionControllers.length > 2)
                                      IconButton(
                                        icon: Icon(Icons.remove_circle_outline, color: Theme.of(ctx).colorScheme.error, size: 20),
                                        tooltip: l10n.delete,
                                        onPressed: () {
                                          setInnerState(() {
                                            controller.dispose();
                                            optionControllers.removeAt(i);
                                            if (selectedCorrectOption == i) {
                                              selectedCorrectOption = null;
                                            } else if (selectedCorrectOption != null && selectedCorrectOption! > i) {
                                              selectedCorrectOption = selectedCorrectOption! - 1;
                                            }
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        )
                      else
                        ...List.generate(optionControllers.length, (i) {
                          final controller = optionControllers[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: selectedCorrectOptions.contains(i),
                                  onChanged: (v) {
                                    setInnerState(() {
                                      if (v == true) {
                                        selectedCorrectOptions.add(i);
                                      } else {
                                        selectedCorrectOptions.remove(i);
                                      }
                                    });
                                  },
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      hintText: '${l10n.addOption} ${i + 1}',
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                if (optionControllers.length > 2)
                                  IconButton(
                                    icon: Icon(Icons.remove_circle_outline, color: Theme.of(ctx).colorScheme.error, size: 20),
                                    tooltip: l10n.delete,
                                    onPressed: () {
                                      setInnerState(() {
                                        controller.dispose();
                                        optionControllers.removeAt(i);
                                        if (selectedCorrectOption == i) {
                                          selectedCorrectOption = null;
                                        } else if (selectedCorrectOption != null && selectedCorrectOption! > i) {
                                          selectedCorrectOption = selectedCorrectOption! - 1;
                                        }
                                      });
                                    },
                                  ),
                              ],
                            ),
                          );
                        }),
                    ],
                    TextButton.icon(
                      onPressed: () => setInnerState(() => optionControllers.add(TextEditingController())),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.addOption),
                    ),
                    const Divider(),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: explanationController,
                    decoration: InputDecoration(
                      labelText: l10n.explanation,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
              FilledButton(
                onPressed: () {
                  final isMulti = selectedType == QuestionType.multiChoice.name;
                  Navigator.pop(ctx, {
                    'text': textController.text.trim(),
                    'subjectId': selectedSubjectId,
                    'topicId': selectedTopicId,
                    'type': selectedType,
                    'difficulty': selectedDifficulty,
                    'explanation': explanationController.text.trim(),
                    'options': optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
                    'correctOption': isMulti ? null : selectedCorrectOption,
                    'correctOptions': isMulti ? selectedCorrectOptions.toList() : null,
                    'sourceIds': selectedSourceIds.toList(),
                  });
                },
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      );

      if (result == null || !mounted) return;

      int difficultyValue;
      switch (selectedDifficulty) {
        case 'easy':
          difficultyValue = 1;
        case 'medium':
          difficultyValue = 2;
        case 'hard':
          difficultyValue = 3;
        default:
          difficultyValue = 1;
      }

      final options = (result['options'] as List<dynamic>?)?.cast<String>() ?? <String>[];
      final correctOption = result['correctOption'] as int?;
      final correctOptions = (result['correctOptions'] as List<dynamic>?)?.cast<int>();
      final sourceIds = (result['sourceIds'] as List<dynamic>?)?.cast<String>() ?? selectedSourceIds.toList();

      Markscheme? markscheme;
      if (correctOption != null && correctOption < options.length) {
        markscheme = Markscheme(correctAnswer: options[correctOption]);
      } else if (correctOptions != null && correctOptions.isNotEmpty) {
        final correctTexts = correctOptions
            .where((i) => i < options.length)
            .map((i) => options[i])
            .toList();
        if (correctTexts.isNotEmpty) {
          markscheme = Markscheme(
            correctAnswer: correctTexts.first,
            acceptableAnswers: correctTexts.skip(1).toList(),
          );
        }
      }

      final updated = question.copyWith(
        text: result['text'] as String? ?? question.text,
        subjectId: result['subjectId'] as String? ?? question.subjectId,
        topicId: result['topicId'] as String? ?? question.topicId,
        type: QuestionType.values.firstWhere(
          (t) => t.name == result['type'],
          orElse: () => question.type,
        ),
        difficulty: difficultyValue,
        options: options,
        sourceIds: sourceIds,
        markscheme: markscheme,
        explanation: (result['explanation'] as String?)?.isNotEmpty == true
            ? result['explanation'] as String
            : null,
        updatedAt: DateTime.now(),
      );
      await _questionRepo.save(question.id, updated);
      if (mounted) {
        setState(() {
          final idx = _allQuestions.indexWhere((q) => q.id == question.id);
          if (idx != -1) _allQuestions[idx] = updated;
        });
      }
    } finally {
      textController.dispose();
      explanationController.dispose();
      for (final c in optionControllers) {
        c.dispose();
      }
    }
  }

  Future<void> _showCreateQuestionDialog() async {
    final l10n = AppLocalizations.of(context)!;

    final textController = TextEditingController();
    final explanationController = TextEditingController();
    final optionControllers = <TextEditingController>[];
    String selectedSubjectId = '';
    String selectedTopicId = '';
    String selectedType = QuestionType.singleChoice.name;
    String selectedDifficulty = 'easy';
    int? selectedCorrectOption;
    final selectedCorrectOptions = <int>{};
    final selectedSourceIds = <String>{};
    var saveAndAddAnother = false;

    void addOptionField() {
      optionControllers.add(TextEditingController());
    }

    addOptionField();
    addOptionField();

    List<Topic> topicsForSubject() {
      if (selectedSubjectId.isEmpty) return _allTopics;
      return _allTopics.where((t) => t.subjectId == selectedSubjectId).toList();
    }

    List<Source> sourcesForSubject() {
      if (selectedSubjectId.isEmpty) return _allSources;
      return _allSources.where((s) => s.subjectId == selectedSubjectId).toList();
    }

    Future<void> continueCreate() async {
      int difficultyValue;
      switch (selectedDifficulty) {
        case 'easy':
          difficultyValue = 1;
        case 'medium':
          difficultyValue = 2;
        case 'hard':
          difficultyValue = 3;
        default:
          difficultyValue = 1;
      }

      final options = optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

      Markscheme? markscheme;
      if (selectedCorrectOption != null && selectedCorrectOption! < options.length) {
        markscheme = Markscheme(correctAnswer: options[selectedCorrectOption!]);
      } else if (selectedCorrectOptions.isNotEmpty) {
        final correctTexts = selectedCorrectOptions
            .where((i) => i < options.length)
            .map((i) => options[i])
            .toList();
        if (correctTexts.isNotEmpty) {
          markscheme = Markscheme(
            correctAnswer: correctTexts.first,
            acceptableAnswers: correctTexts.skip(1).toList(),
          );
        }
      }

      final question = Question(
        id: IdGenerator.generate('question'),
        text: textController.text.trim(),
        subjectId: selectedSubjectId,
        topicId: selectedTopicId,
        type: QuestionType.values.firstWhere(
          (t) => t.name == selectedType,
          orElse: () => QuestionType.singleChoice,
        ),
        difficulty: difficultyValue,
        options: options,
        sourceIds: selectedSourceIds.toList(),
        markscheme: markscheme,
        explanation: explanationController.text.trim().isNotEmpty
            ? explanationController.text.trim()
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final saveResult = await _questionRepo.create(question);
      if (saveResult.isSuccess && mounted) {
        setState(() => _allQuestions.add(question));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.questionCreated)),
        );
      }
    }

    try {
      while (true) {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setInnerState) => AlertDialog(
              title: Text(l10n.createQuestion),
              content: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        labelText: l10n.questionText,
                        hintText: l10n.questionTextHint,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubjectId.isEmpty ? null : selectedSubjectId,
                      decoration: InputDecoration(
                        labelText: l10n.subject,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: '', child: Text(l10n.none)),
                        ..._subjects.map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name),
                        )),
                      ],
                      onChanged: (v) {
                        selectedSubjectId = v ?? '';
                        selectedTopicId = '';
                        selectedSourceIds.clear();
                        setInnerState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedTopicId.isEmpty ? null : selectedTopicId,
                      decoration: InputDecoration(
                        labelText: l10n.topics,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: '', child: Text(l10n.none)),
                        ...topicsForSubject().map((t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(t.title),
                        )),
                      ],
                      onChanged: (v) {
                        selectedTopicId = v ?? '';
                        setInnerState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        labelText: l10n.type,
                        border: const OutlineInputBorder(),
                      ),
                      items: QuestionType.values.map((t) => DropdownMenuItem(
                        value: t.name,
                        child: Text(questionTypeLabel(t, l10n)),
                      )).toList(),
                      onChanged: (v) {
                        selectedType = v ?? QuestionType.singleChoice.name;
                        setInnerState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDifficulty,
                      decoration: InputDecoration(
                        labelText: l10n.difficulty,
                        border: const OutlineInputBorder(),
                      ),
                      items: ['easy', 'medium', 'hard'].map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(d[0].toUpperCase() + d.substring(1)),
                      )).toList(),
                      onChanged: (v) => selectedDifficulty = v ?? 'easy',
                    ),
                    if (sourcesForSubject().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: l10n.sources,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(value: '', child: Text(l10n.none)),
                          ...sourcesForSubject().map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.title),
                          )),
                        ],
                        onChanged: (v) {
                          if (v != null && v.isNotEmpty) {
                            setInnerState(() {
                              if (selectedSourceIds.contains(v)) {
                                selectedSourceIds.remove(v);
                              } else {
                                selectedSourceIds.add(v);
                              }
                            });
                          }
                        },
                      ),
                      if (selectedSourceIds.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: selectedSourceIds.map((sid) {
                              final name = _sourceName(sid) ?? sid;
                              return Chip(
                                label: Text(name, style: const TextStyle(fontSize: 12)),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () => setInnerState(() => selectedSourceIds.remove(sid)),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                    if (selectedType == QuestionType.singleChoice.name ||
                        selectedType == QuestionType.multiChoice.name) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      Text(l10n.answerOptions, style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (selectedType == QuestionType.singleChoice.name)
                        RadioGroup<int?>(
                          groupValue: selectedCorrectOption,
                          onChanged: (v) => setInnerState(() => selectedCorrectOption = v),
                          child: Column(
                            children: List.generate(optionControllers.length, (i) {
                              final controller = optionControllers[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Radio<int?>(value: i),
                                    Expanded(
                                      child: TextField(
                                        controller: controller,
                                        decoration: InputDecoration(
                                          hintText: '${l10n.addOption} ${i + 1}',
                                          border: const OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    if (optionControllers.length > 2)
                                      IconButton(
                                        icon: Icon(Icons.remove_circle_outline, color: Theme.of(ctx).colorScheme.error, size: 20),
                                        tooltip: l10n.delete,
                                        onPressed: () {
                                          setInnerState(() {
                                            controller.dispose();
                                            optionControllers.removeAt(i);
                                            if (selectedCorrectOption == i) {
                                              selectedCorrectOption = null;
                                            } else if (selectedCorrectOption != null && selectedCorrectOption! > i) {
                                              selectedCorrectOption = selectedCorrectOption! - 1;
                                            }
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        )
                      else
                        ...List.generate(optionControllers.length, (i) {
                          final controller = optionControllers[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: selectedCorrectOptions.contains(i),
                                  onChanged: (v) {
                                    setInnerState(() {
                                      if (v == true) {
                                        selectedCorrectOptions.add(i);
                                      } else {
                                        selectedCorrectOptions.remove(i);
                                      }
                                    });
                                  },
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      hintText: '${l10n.addOption} ${i + 1}',
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                if (optionControllers.length > 2)
                                  IconButton(
                                    icon: Icon(Icons.remove_circle_outline, color: Theme.of(ctx).colorScheme.error, size: 20),
                                    tooltip: l10n.delete,
                                    onPressed: () {
                                      setInnerState(() {
                                        controller.dispose();
                                        optionControllers.removeAt(i);
                                        if (selectedCorrectOption == i) {
                                          selectedCorrectOption = null;
                                        } else if (selectedCorrectOption != null && selectedCorrectOption! > i) {
                                          selectedCorrectOption = selectedCorrectOption! - 1;
                                        }
                                      });
                                    },
                                  ),
                              ],
                            ),
                          );
                        }),
                      TextButton.icon(
                        onPressed: () => setInnerState(() {
                          optionControllers.add(TextEditingController());
                        }),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l10n.addOption),
                      ),
                      const Divider(),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: explanationController,
                      decoration: InputDecoration(
                        labelText: l10n.explanation,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: saveAndAddAnother,
                      onChanged: (v) => setInnerState(() => saveAndAddAnother = v ?? false),
                      title: Text(l10n.saveOnly, style: const TextStyle(fontSize: 13)),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    if (textController.text.trim().isEmpty) return;
                    if ((selectedType == QuestionType.singleChoice.name ||
                        selectedType == QuestionType.multiChoice.name) &&
                        optionControllers.any((c) => c.text.trim().isEmpty)) {
                      return;
                    }
                    Navigator.pop(ctx, {'saveAndAddAnother': saveAndAddAnother});
                  },
                  child: Text(l10n.save),
                ),
              ],
            ),
          ),
        );

        if (result == null || !mounted) return;
        saveAndAddAnother = result['saveAndAddAnother'] as bool? ?? false;

        await continueCreate();

        if (!saveAndAddAnother || !mounted) break;

        textController.clear();
        explanationController.clear();
        for (final c in optionControllers) {
          c.dispose();
        }
        optionControllers.clear();
        addOptionField();
        addOptionField();
        selectedCorrectOption = null;
        selectedCorrectOptions.clear();
        selectedTopicId = '';
        selectedSourceIds.clear();
      }
    } finally {
      textController.dispose();
      explanationController.dispose();
      for (final c in optionControllers) {
        c.dispose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final filtered = _filteredQuestions;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateQuestionDialog,
        tooltip: l10n.createQuestion,
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: Text(l10n.questionBankScreen),
        actions: [
          if (_selectionMode) ...[
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: l10n.cancelSelection,
              onPressed: () => setState(() { _selectedIds.clear(); _selectionMode = false; }),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: l10n.deleteSelected,
              onPressed: _selectedIds.isNotEmpty ? _deleteSelected : null,
            ),
          ] else ...[
            PopupMenuButton<String>(
              tooltip: l10n.exportBackup,
              onSelected: (v) {
                if (v == 'export') _exportQuestions();
                if (v == 'import') _batchImportQuestions();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'export', child: Text(l10n.exportCsv)),
                PopupMenuItem(value: 'import', child: Text(l10n.importBackup)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: l10n.selectMultiple,
              onPressed: () => setState(() { _selectionMode = true; _selectedIds.clear(); }),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const LoadingScreen()
          : _error != null
              ? ErrorRetryWidget(message: _error!, onRetry: _load)
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
                                controller: _scrollController,
                                padding: ResponsiveUtils.listPadding(context),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final q = filtered[index];
                                  final isSelected = _selectedIds.contains(q.id);
                                  final subjectName = _subjectName(q.subjectId);
                                  final topicName = _topicName(q.topicId);

                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                                    child: Semantics(
                                      button: true,
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
                                                        _smallChip(questionTypeLabel(q.type, l10n), theme),
                                                        _smallChip(l10n.difficultyLabel(q.difficulty.toString()), theme),
                                                        if (subjectName != null) _smallChip(subjectName, theme),
                                                        if (topicName != null) _smallChip(topicName, theme),
                                                        if (q.sourceIds.isNotEmpty)
                                                          _smallChip(l10n.sourcesCount(q.sourceIds.length), theme),
                                                        _smallChip(
                                                          q.model != null ? l10n.aiGenerated : l10n.manual,
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
                                                  PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
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
      child: Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSecondaryContainer)),
    );
  }

  Widget _buildSearchAndFilter(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, top: 8, end: 16, bottom: 4),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchQuestions,
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Row(
              children: [
                _filterChip(
                  label: _subjectFilter.isEmpty ? l10n.allSubjects : _subjectName(_subjectFilter) ?? _subjectFilter,
                  selected: _subjectFilter.isNotEmpty,
                  onTap: () => _showSubjectFilter(l10n),
                  onClear: _subjectFilter.isNotEmpty ? () => setState(() => _subjectFilter = '') : null,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: _typeFilter.isEmpty
                      ? l10n.allTypes
                      : questionTypeLabel(QuestionType.values[int.parse(_typeFilter)], l10n),
                  selected: _typeFilter.isNotEmpty,
                  onTap: () => _showTypeFilter(l10n),
                  onClear: _typeFilter.isNotEmpty ? () => setState(() => _typeFilter = '') : null,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: _sourceFilter.isEmpty ? l10n.allSources : (_sourceName(_sourceFilter) ?? _sourceFilter),
                  selected: _sourceFilter.isNotEmpty,
                  onTap: () => _showSourceFilter(l10n),
                  onClear: _sourceFilter.isNotEmpty ? () => setState(() => _sourceFilter = '') : null,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: _modelFilter == null ? l10n.allTypes : (_modelFilter! ? l10n.manual : l10n.aiGenerated),
                  selected: _modelFilter != null,
                  onTap: () => _showModelFilter(l10n),
                  onClear: _modelFilter != null ? () => setState(() => _modelFilter = null) : null,
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
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InputChip(
        label: Text(label),
        selected: selected,
        onPressed: onTap,
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
            title: Text(l10n.allTypes),
            trailing: _typeFilter.isEmpty ? const Icon(Icons.check) : null,
            onTap: () {
              Navigator.pop(ctx);
              setState(() => _typeFilter = '');
            },
          ),
          ...QuestionType.values.map((t) => ListTile(
            title: Text(questionTypeLabel(t, l10n)),
            trailing: _typeFilter == t.index.toString() ? const Icon(Icons.check) : null,
            onTap: () { Navigator.pop(ctx); setState(() => _typeFilter = t.index.toString()); },
          )),
        ],
      ),
    );
  }

  void _showModelFilter(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(l10n.allTypes),
            trailing: _modelFilter == null ? const Icon(Icons.check) : null,
            onTap: () {
              Navigator.pop(ctx);
              setState(() => _modelFilter = null);
            },
          ),
          ListTile(
            title: Text(l10n.manual),
            trailing: _modelFilter == true ? const Icon(Icons.check) : null,
            onTap: () {
              Navigator.pop(ctx);
              setState(() => _modelFilter = true);
            },
          ),
          ListTile(
            title: Text(l10n.aiGenerated),
            trailing: _modelFilter == false ? const Icon(Icons.check) : null,
            onTap: () {
              Navigator.pop(ctx);
              setState(() => _modelFilter = false);
            },
          ),
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
            title: Text(l10n.allSources),
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


