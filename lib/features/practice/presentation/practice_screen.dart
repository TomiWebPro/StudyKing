import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/practice/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/core/errors/handlers.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/practice/services/practice_data_service.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_empty_state.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_mode_grid.dart';
import 'package:studyking/features/practice/presentation/widgets/subject_practice_card.dart';
import 'package:studyking/features/practice/presentation/widgets/subject_selection_sheet.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_mode_sheet.dart';
import 'package:studyking/features/practice/presentation/widgets/topic_selection_sheet.dart';
import 'package:studyking/features/practice/presentation/widgets/spaced_repetition_sheet.dart';
import 'package:studyking/features/practice/presentation/widgets/weak_areas_sheet.dart';
import 'package:studyking/features/practice/presentation/widgets/source_practice_sheet.dart';
import 'package:studyking/features/practice/presentation/screens/exam_session_screen.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  final Logger _logger = const Logger('PracticeScreen');
  late final PracticeDataService _dataService;
  late final SpacedRepetitionRepository _srRepo;
  late final QuestionRepository _questionRepo;
  late final StudentIdService _studentIdService;
  List<Subject> _subjects = [];
  bool _isLoading = true;
  Map<String, int> _dueCounts = {};
  bool _isLoadingDueCounts = false;

  @override
  void initState() {
    super.initState();
    final srService = ref.read(spacedRepetitionServiceProvider);
    _srRepo = ref.read(spacedRepetitionRepositoryProvider);
    _questionRepo = ref.read(questionRepositoryProvider);
    _studentIdService = ref.read(studentIdServiceProvider);
    _dataService = PracticeDataService(
      srService: srService,
      questionRepo: _questionRepo,
      subjectRepo: ref.read(subjectRepositoryProvider),
      studentIdService: _studentIdService,
    );
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final subjects = await _dataService.fetchSubjects();
      if (!mounted) return;
      setState(() {
        _subjects = subjects;
        _isLoading = false;
      });
      _loadDueCounts();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppErrorHandler.handleError(context, e, 'Subjects Load',
          retry: true, retryCallback: _retryLoadSubjects);
    }
  }

  Future<void> _retryLoadSubjects() => _loadSubjects();

  Future<void> _loadDueCounts() async {
    if (_subjects.isEmpty) return;
    setState(() => _isLoadingDueCounts = true);
    try {
      final dueCounts = await _dataService.loadDueCounts(_subjects);
      if (!mounted) return;
      setState(() {
        _dueCounts = dueCounts;
        _isLoadingDueCounts = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingDueCounts = false);
    }
  }

  void _startPractice(Subject subject) {
    Navigator.pushNamed(context, AppRoutes.practiceSession,
        arguments: PracticeSessionArgs(subjectId: subject.id));
  }

  Future<void> _startTopicPractice(String topic) async {
    try {
      final allQuestions = await _questionRepo.getAll();
      final topicQuestions =
          allQuestions.where((q) => q.topic == topic).toList();
      if (topicQuestions.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.noQuestionsAvailable)));
        return;
      }
      if (!mounted) return;
      Navigator.pushNamed(context, AppRoutes.practiceSession,
          arguments: PracticeSessionArgs(
            subjectId: topicQuestions.first.subjectId,
            topicId: topicQuestions.first.topicId,
            questionCount: topicQuestions.length,
          ));
    } catch (e) {
      _logger.e('Error starting practice session', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(AppLocalizations.of(context)!.failedToStartPractice)));
    }
  }

  Future<void> _launchWeakAreasForSubject(
      MasteryGraphService masteryService, Subject subject) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final studentId = _studentIdService.getStudentId();
      final weakTopicsResult =
          await masteryService.getWeakTopics(studentId);
      if (weakTopicsResult.isFailure ||
          weakTopicsResult.data == null ||
          weakTopicsResult.data!.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.noWeakAreasFound)));
        return;
      }
      final weakTopicIds =
          weakTopicsResult.data!.map((s) => s.topicId).toSet();
      final allQuestions = await _questionRepo.getAll().catchError((_) => <Question>[]);
      if (allQuestions.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.noQuestionsAvailable)));
        return;
      }
      final weakQuestions = allQuestions
          .where((q) => weakTopicIds.contains(q.topicId))
          .toList();
      if (weakQuestions.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.noWeakAreasQuestions)));
        return;
      }

      final scorer = ref.read(readinessScorerProvider);
      final scored = scorer.scoreQuestions(weakQuestions);
      final orderedQuestions = scored.map((s) => s.question).toList();

      if (!mounted) return;
      Navigator.pushNamed(context, AppRoutes.practiceSession,
          arguments: PracticeSessionArgs(
            subjectId: subject.id,
            questionCount: orderedQuestions.length,
          ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.noWeakAreasFound)));
      }
    }
  }

  void _startSpacedRepetitionSession(Subject subject) async {
    try {
      final result = await _srRepo.getPracticeQuestions(subject.id);
      if (result.isFailure || result.data == null || result.data!.isEmpty) {
        if (!mounted) return;
        SpacedRepetitionSheet.showAllCaughtUp(context);
        return;
      }
      if (!mounted) return;
      Navigator.pushNamed(context, AppRoutes.practiceSession,
          arguments: PracticeSessionArgs(
            subjectId: subject.id,
            questionCount: result.data!.length,
            isSpacedRepetition: true,
          ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(AppLocalizations.of(context)!.noQuestionsAvailable)));
      }
    }
  }

  void _startExamMode() {
    if (_subjects.isEmpty) return;
    if (_subjects.length == 1) {
      _navigateToExam(_subjects.first);
    } else {
      SubjectSelectionSheet.show(context,
          subjects: _subjects,
          onSubjectSelected: (subject) => _navigateToExam(subject));
    }
  }

  void _navigateToExam(Subject subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamSessionScreen(
          subjectId: subject.id,
          subjectName: subject.name,
        ),
      ),
    );
  }

  void _showSourcePracticeSheet() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final allQuestions = await _questionRepo.getAll();
      final sourceMap = <String, Set<String>>{};
      for (final q in allQuestions) {
        for (final sourceId in q.sourceIds) {
          sourceMap.putIfAbsent(sourceId, () => {});
          sourceMap[sourceId]!.add(q.id);
        }
      }

      final sources = sourceMap.entries
          .where((e) => e.value.isNotEmpty)
          .map((e) => SourceItemData(
                id: e.key,
                title: e.key,
                questionCount: e.value.length,
              ))
          .toList();

      if (sources.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.noSourcesAvailable)));
        return;
      }

      if (!mounted) return;
      SourcePracticeSheet.show(context,
          sources: sources,
          onSourceSelected: (sourceId, sourceTitle) {
            final sourceQuestions = allQuestions
                .where((q) => q.sourceIds.contains(sourceId))
                .toList();
            if (sourceQuestions.isNotEmpty) {
              Navigator.pushNamed(context, AppRoutes.practiceSession,
                  arguments: PracticeSessionArgs(
                    subjectId: sourceQuestions.first.subjectId,
                    questionCount: sourceQuestions.length,
                  ));
            }
          });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.noSourcesAvailable)));
      }
    }
  }

  void _showSubjectSelector() {
    SubjectSelectionSheet.show(context,
        subjects: _subjects,
        onSubjectSelected: (subject) => _startPractice(subject));
  }

  void _showPracticeModeDialog() {
    PracticeModeSheet.show(context,
        subjects: _subjects,
        onSubjectSelected: (subject) => _startPractice(subject));
  }

  Future<void> _showTopicSelector() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final topics = await _dataService.loadTopics(_questionRepo);
      if (topics.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.noTopicsAvailable)));
        return;
      }
      if (!mounted) return;
      TopicSelectionSheet.show(context,
          topics: topics,
          onTopicSelected: (topic) => _startTopicPractice(topic));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.noTopicsAvailable)));
      }
    }
  }

  void _showSpacedRepetitionSubjectSelector() {
    final subjectsWithDue =
        _subjects.where((s) => (_dueCounts[s.id] ?? 0) > 0).toList();
    if (subjectsWithDue.isEmpty) {
      SpacedRepetitionSheet.showAllCaughtUp(context);
      return;
    }
    SpacedRepetitionSheet.showSubjectPicker(context,
        subjectsWithDue: subjectsWithDue,
        dueCounts: _dueCounts,
        onSubjectSelected: (subject) =>
            _startSpacedRepetitionSession(subject));
  }

  Future<void> _startWeakAreasPractice() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final masteryService = ref.read(masteryGraphServiceProvider);
      await masteryService.init();
      if (_subjects.isEmpty) return;
      if (_subjects.length == 1) {
        await _launchWeakAreasForSubject(masteryService, _subjects.first);
        return;
      }
      if (!mounted) return;
      WeakAreasSheet.show(context,
          subjects: _subjects,
          onSubjectSelected: (subject) =>
              _launchWeakAreasForSubject(masteryService, subject));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.noWeakAreasFound)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.practiceMode),
        actions: [
          if (_subjects.isNotEmpty)
            Semantics(
              label: l10n.practiceOptions,
              child: IconButton(
                icon: const Icon(Icons.tune),
                onPressed: _showPracticeModeDialog,
                tooltip: l10n.practiceOptions,
              ),
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _subjects.isEmpty
            ? null
            : () {
                if (_subjects.length == 1) {
                  _startPractice(_subjects.first);
                } else {
                  _showSubjectSelector();
                }
              },
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.play_arrow),
        label: Text(
            _subjects.isEmpty ? l10n.noSubjects : l10n.practice),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_subjects.isEmpty) return const PracticeEmptyState();
    return RefreshIndicator(
      onRefresh: _loadSubjects,
      child: ListView(
        padding: ResponsiveUtils.listPadding(context),
        children: [
          PracticeModeGrid(
            isLoadingDueCounts: _isLoadingDueCounts,
            dueCounts: _dueCounts,
            hasSubjects: _subjects.isNotEmpty,
            onQuickPractice: _showPracticeModeDialog,
            onSpacedRepetition: _showSpacedRepetitionSubjectSelector,
            onTopicFocus: _showTopicSelector,
            onWeakAreas: _startWeakAreasPractice,
          ),
          const SizedBox(height: 16),
          _buildExtraModes(),
          const SizedBox(height: 16),
          _buildSubjectSection(context),
        ],
      ),
    );
  }

  Widget _buildExtraModes() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
            padding: ResponsiveUtils.listPadding(context),
      child: Row(
        children: [
          Expanded(
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _startExamMode,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.examMode,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.examModeDescription,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _showSourcePracticeSheet,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.source,
                        size: 32,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.sourcePractice,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.sourcePracticeDescription,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_subjects.length > 1) ...[
          Padding(
      padding: ResponsiveUtils.listPadding(context),
            child: Text(l10n.yourSubjects,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
        ],
        ..._subjects.map((subject) => SubjectPracticeCard(
            subject: subject,
            onTap: () => _startPractice(subject))),
      ],
    );
  }
}
