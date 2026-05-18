import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/errors/handlers.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/features/ingestion/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/practice/services/practice_data_service.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_empty_state.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_mode_grid.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_mode_sheet.dart';
import 'package:studyking/features/practice/presentation/widgets/source_practice_sheet.dart';
import 'package:studyking/features/practice/presentation/widgets/spaced_repetition_sheet.dart';
import 'package:studyking/features/practice/presentation/widgets/subject_practice_card.dart';
import 'package:studyking/features/practice/presentation/widgets/subject_selection_sheet.dart';
import 'package:studyking/features/practice/presentation/widgets/topic_selection_sheet.dart';
import 'package:studyking/features/practice/presentation/widgets/weak_areas_sheet.dart';
import 'package:studyking/features/practice/data/models/practice_models.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/services/prerequisite_check_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';


class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  final Logger _logger = const Logger('PracticeScreen');
  late final PracticeDataService _dataService;
  late final SpacedRepetitionService _srService;
  late final QuestionRepository _questionRepo;
  late final StudentIdService _studentIdService;
  List<Subject> _subjects = [];
  bool _isLoading = true;
  String? _loadError;
  Map<String, int> _dueCounts = {};
  bool _isLoadingDueCounts = false;
  int _totalQuestionCount = 0;
  int _questionsToday = 0;

  @override
  void initState() {
    super.initState();
    _srService = ref.read(spacedRepetitionServiceProvider);
    _questionRepo = ref.read(questionRepositoryProvider);
    _studentIdService = ref.read(studentIdServiceProvider);
    _dataService = PracticeDataService(
      srService: _srService,
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
        _loadError = null;
      });
      _loadDueCounts();
      _loadQuestionCount();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = AppLocalizations.of(context)!.somethingWentWrong;
      });
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
    } catch (e) {
      _logger.e('Failed to load due counts', e);
      if (mounted) setState(() => _isLoadingDueCounts = false);
    }
  }

  Future<void> _loadQuestionCount() async {
    try {
      final allQuestionsResult = await _questionRepo.getAll();
      final allQuestions = allQuestionsResult.data ?? [];
      final studentId = _studentIdService.getStudentId();
      final now = DateTime.now();
      final today = now.dateOnly;

      final attemptRepo = ref.read(attemptRepositoryProvider);
      try {
        final result = await attemptRepo.getByStudent(studentId);
        final allAttempts = result.data ?? [];
        _questionsToday = allAttempts
            .where((a) => a.timestamp.isAfter(today))
            .length;
      } catch (e) {
        _logger.e('Failed to load attempts count', e);
        _questionsToday = 0;
      }

      if (!mounted) return;
      setState(() {
        _totalQuestionCount = allQuestions.length;
      });
    } catch (e) {
      _logger.e('Failed to load question count', e);
    }
  }

  Future<void> _startPractice(Subject subject) async {
    final result = await Navigator.pushNamed(context, AppRoutes.practiceSession,
        arguments: PracticeSessionArgs(subjectId: subject.id)) as PracticeSessionResult?;
    _onSessionResult(result);
  }

  Future<void> _startTopicPractice(String topic) async {
    try {
      final prereqCheck = PrerequisiteCheckService();
      final prereqResult = await prereqCheck.checkPrerequisites(
        topicId: topic,
        studentId: _studentIdService.getStudentId(),
      );
      if (prereqResult.isSuccess &&
          !prereqResult.data!.isReady &&
          prereqResult.data!.unmetPrerequisiteTopics.isNotEmpty) {
        if (mounted) {
          await PrerequisiteCheckService.showPrerequisiteDialog(
            context,
            unmetTopics: prereqResult.data!.unmetPrerequisiteTopics,
          );
        }
        return;
      }

      final allQuestionsResult = await _questionRepo.getAll();
      final allQuestions = allQuestionsResult.data ?? [];
      final trimmedTopic = topic.trim();
      var topicQuestions =
          allQuestions.where((q) => q.topicId == trimmedTopic).toList();
      if (topicQuestions.isEmpty) {
        topicQuestions = allQuestions
            .where((q) =>
                q.topic != null &&
                q.topic!.trim().toLowerCase() ==
                    trimmedTopic.toLowerCase())
            .toList();
      }
      if (topicQuestions.isEmpty) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.noQuestionsAvailable)));
        return;
      }
      if (!mounted) return;
      final tResult = await Navigator.pushNamed(context,
              AppRoutes.practiceSession,
              arguments: PracticeSessionArgs(
                subjectId: topicQuestions.first.subjectId,
                topicId: topicQuestions.first.topicId,
                questionCount: topicQuestions.length,
              )) as PracticeSessionResult?;
      _onSessionResult(tResult);
    } catch (e) {
      _logger.e('Error starting practice session', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(AppLocalizations.of(context)!.failedToStartPractice)));
    }
  }

  static const int _minAttemptsForWeakAreas = 10;

  Future<void> _launchWeakAreasForSubject(
      MasteryGraphService masteryService, Subject subject) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final studentId = _studentIdService.getStudentId();
      final attemptRepo = ref.read(attemptRepositoryProvider);
      final attemptResult = await attemptRepo.getByStudent(studentId);
      final allAttempts = attemptResult.data ?? [];
      final subjectAttempts =
          allAttempts.where((a) => a.subjectId == subject.id).toList();
      if (subjectAttempts.length < _minAttemptsForWeakAreas) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${subject.name}: ${l10n.practiceAtLeastTen}')));
        return;
      }

      final insufficientData =
          allAttempts.length < _minAttemptsForWeakAreas * 3;
      final weakTopicsResult =
          await masteryService.getWeakTopics(studentId);
      if (weakTopicsResult.isFailure ||
          weakTopicsResult.data == null ||
          weakTopicsResult.data!.isEmpty) {
        if (!mounted) return;
        if (insufficientData) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  '${l10n.practiceAtLeastTen}. ${l10n.noQuestionsAvailable}')));
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.noWeakAreasFound)));
        }
        return;
      }
      final weakTopicIds =
          weakTopicsResult.data!.map((s) => s.topicId).toSet();
      final allQuestionsResult = await _questionRepo.getAll().catchError((_) => Result.success(<Question>[]));
      final allQuestions = allQuestionsResult.data ?? [];
      if (allQuestions.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.noQuestionsAvailable)));
        return;
      }
      final weakQuestions = allQuestions
          .where((q) => weakTopicIds.contains(q.topicId) && q.subjectId == subject.id)
          .toList();
      if (weakQuestions.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.noWeakAreasQuestions)));
        return;
      }

      final scorer = ref.read(readinessScorerProvider);
      final scored = await scorer.scoreQuestions(weakQuestions);
      final orderedQuestionIds = scored.map((s) => s.question.id).toList();

      if (!mounted) return;
      final result = await Navigator.pushNamed(context,
              AppRoutes.practiceSession,
              arguments: PracticeSessionArgs(
                subjectId: subject.id,
                topicId: orderedQuestionIds.isNotEmpty
                    ? weakQuestions.firstWhere((q) => q.id == orderedQuestionIds.first).topicId
                    : null,
                questionCount: orderedQuestionIds.length,
                orderedQuestionIds: orderedQuestionIds,
              )) as PracticeSessionResult?;
      _onSessionResult(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.noWeakAreasFound)));
      }
    }
  }

  void _onSessionResult(PracticeSessionResult? result) {
    if (result != null) {
      _questionsToday += result.questionsAnswered;
    }
    _loadDueCounts();
  }

  void _startSpacedRepetitionSession(Subject subject) async {
    try {
      final result = await _srService.getPracticeQuestions(subject.id);
      if (result.isFailure || result.data == null || result.data!.isEmpty) {
        if (!mounted) return;
        SpacedRepetitionSheet.showAllCaughtUp(context);
        return;
      }
      if (!mounted) return;
      final dueQuestions = result.data!;
      dueQuestions.sort((a, b) => (a.nextReview ?? DateTime.now())
          .compareTo(b.nextReview ?? DateTime.now()));
      final dueQuestionIds = dueQuestions.map((q) => q.id).toList();
      final srResult = await Navigator.pushNamed(context,
              AppRoutes.practiceSession,
              arguments: PracticeSessionArgs(
                subjectId: subject.id,
                questionCount: dueQuestions.length,
                isSpacedRepetition: true,
                orderedQuestionIds: dueQuestionIds,
              )) as PracticeSessionResult?;
      _onSessionResult(srResult);
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

  Future<void> _startAtRiskPractice() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final masteryService = ref.read(masteryGraphServiceProvider);
      await masteryService.init();
      final studentId = _studentIdService.getStudentId();
      final atRiskResult = await masteryService.getAtRiskQuestions(studentId);
      if (atRiskResult.isFailure ||
          atRiskResult.data == null ||
          atRiskResult.data!.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noWeakAreasFound)));
        return;
      }
      final atRiskQuestionIds =
          atRiskResult.data!.map((s) => s.questionId).toSet();
      final allQuestionsResult =
          await _questionRepo.getAll().catchError((_) => Result.success(<Question>[]));
      final allQuestions = allQuestionsResult.data ?? [];
      final atRiskQuestions = allQuestions
          .where((q) => atRiskQuestionIds.contains(q.id))
          .toList();
      if (atRiskQuestions.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noWeakAreasQuestions)));
        return;
      }
      final scorer = ref.read(readinessScorerProvider);
      final scored = await scorer.scoreQuestions(atRiskQuestions);
      final orderedIds = scored.map((s) => s.question.id).toList();
      if (!mounted) return;
      await Navigator.pushNamed(context, AppRoutes.practiceSession,
          arguments: PracticeSessionArgs(
            subjectId: atRiskQuestions.first.subjectId,
            orderedQuestionIds: orderedIds,
            questionCount: orderedIds.length,
          ));
      _loadDueCounts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noWeakAreasFound)));
      }
    }
  }

  void _navigateToExam(Subject subject) {
    Navigator.pushNamed(
      context,
      AppRoutes.examSession,
      arguments: ExamSessionArgs(
        subjectId: subject.id,
        subjectName: subject.name,
      ),
    );
  }

  void _showSourcePracticeSheet() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final allQuestionsResult = await _questionRepo.getAll();
      final allQuestions = allQuestionsResult.data ?? [];
      final sourceMap = <String, Set<String>>{};
      for (final q in allQuestions) {
        for (final sourceId in q.sourceIds) {
          sourceMap.putIfAbsent(sourceId, () => {});
          sourceMap[sourceId]!.add(q.id);
        }
      }

      final allSources = await _getAllSources();

      final sourceItems = allSources.map((source) {
        final questionCount = sourceMap[source.id]?.length ?? 0;
        return SourceItemData(
          id: source.id,
          title: source.title,
          questionCount: questionCount,
          status: source.statusEnum,
        );
      }).toList();

      if (sourceItems.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.noSourcesAvailable)));
        return;
      }

      if (!mounted) return;
      SourcePracticeSheet.show(context,
          sources: sourceItems,
          onSourceSelected: (sourceId, sourceTitle) {
            final sourceQuestions = allQuestions
                .where((q) => q.sourceIds.contains(sourceId))
                .toList();
            if (sourceQuestions.isNotEmpty) {
              Navigator.pushNamed(context, AppRoutes.practiceSession,
                  arguments: PracticeSessionArgs(
                    subjectId: sourceQuestions.first.subjectId,
                    questionCount: sourceQuestions.length,
                  )).then((r) => _onSessionResult(r as PracticeSessionResult?));
            } else if (mounted) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.noQuestionsAvailable),
                  content: Text(l10n.sourceWithNoQuestions),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamed(context, AppRoutes.upload);
                      },
                      child: Text(l10n.uploadMaterials),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.ok),
                    ),
                  ],
                ),
              );
            }
          });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.noSourcesAvailable)));
      }
    }
  }

  Future<List<Source>> _getAllSources() async {
    try {
      final repo = SourceRepository();
      await repo.init();
      final result = await repo.getAll();
      return result.data ?? [];
    } catch (e) {
      return [];
    }
  }

  void _showSubjectSelector() {
    SubjectSelectionSheet.show(context,
        subjects: _subjects,
        onSubjectSelected: (subject) {
          _startPractice(subject);
        });
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
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.noTopicsAvailable),
            content: Text(l10n.uploadMaterialsToGenerateTopics),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.upload);
                },
                child: Text(l10n.uploadMaterials),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
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
        actions: const [],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _subjects.isEmpty
            ? null
            : () {
                _showSubjectSelector();
              },
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.play_arrow),
        label: Flexible(
          child: Text(
            _subjects.isEmpty ? l10n.noSubjects : l10n.practice,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    final l10n = AppLocalizations.of(context)!;
    final totalDue = _dueCounts.values.fold(0, (a, b) => a + b);
    return Card(
      child: Padding(
        padding: ResponsiveUtils.cardPadding(context),
        child: Row(
          children: [
            Expanded(child: _buildSummaryItem(context,
                icon: Icons.today, label: l10n.questionsToday, value: '$_questionsToday')),
            Expanded(child: _buildSummaryItem(context,
                icon: Icons.schedule, label: l10n.dueForReview, value: '$totalDue')),
            Expanded(child: _buildSummaryItem(context,
                icon: Icons.book, label: l10n.subjects, value: '${_subjects.length}')),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, {
    required IconData icon, required String label, required String value,
  }) {
    return Column(children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      SizedBox(height: ResponsiveUtils.verticalSpacing(context) / 2),
      Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
  }

  Widget _buildNoQuestionsBanner() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: ResponsiveUtils.cardPadding(context),
        child: Column(children: [
          Icon(Icons.quiz_outlined, size: 48,
              color: Theme.of(context).colorScheme.primaryContainer),
          SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
          Text(l10n.noQuestionsPracticeHint,
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.upload),
            icon: const Icon(Icons.upload),
            label: Text(l10n.uploadMaterials),
          ),
        ]),
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: ResponsiveUtils.screenPadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                l10n.somethingWentWrong,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _retryLoadSubjects,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }
    if (_subjects.isEmpty) return const PracticeEmptyState();
    return RefreshIndicator(
      onRefresh: _loadSubjects,
      child: ListView(
        padding: ResponsiveUtils.listPadding(context),
        children: [
          _buildSummaryRow(),
          if (_totalQuestionCount == 0) _buildNoQuestionsBanner() else
          PracticeModeGrid(
            isLoadingDueCounts: _isLoadingDueCounts,
            dueCounts: _dueCounts,
            totalQuestionCount: _totalQuestionCount,
            hasSubjects: _subjects.isNotEmpty,
            onQuickPractice: _showPracticeModeDialog,
            onSpacedRepetition: _showSpacedRepetitionSubjectSelector,
            onTopicFocus: _showTopicSelector,
            onWeakAreas: _startWeakAreasPractice,
          ),
          SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
          _buildExtraModes(),
          SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
          _buildSubjectSection(context),
        ],
      ),
    );
  }

  Widget _buildExtraModes() {
    final l10n = AppLocalizations.of(context)!;
    final isXs = ResponsiveUtils.breakpointOf(context).isXs;
    final modeCards = [
      _ExtraModeCard(
        icon: Icons.timer,
        iconColor: Theme.of(context).colorScheme.primary,
        title: l10n.examMode,
        description: l10n.examModeDescription,
        onTap: _startExamMode,
      ),
      _ExtraModeCard(
        icon: Icons.source,
        iconColor: Theme.of(context).colorScheme.secondary,
        title: l10n.sourcePractice,
        description: l10n.sourcePracticeDescription,
        onTap: _showSourcePracticeSheet,
      ),
      _ExtraModeCard(
        icon: Icons.warning,
        iconColor: Theme.of(context).colorScheme.error,
        title: l10n.atRiskQuestions,
        description: l10n.atRiskQuestionsDescription,
        onTap: _startAtRiskPractice,
      ),
      _ExtraModeCard(
        icon: Icons.quiz,
        iconColor: Theme.of(context).colorScheme.tertiary,
        title: l10n.questionBankLink,
        description: l10n.browseAndManageQuestions,
        onTap: () => Navigator.pushNamed(context, AppRoutes.questionBank),
      ),
    ];
    return Padding(
      padding: ResponsiveUtils.listPadding(context),
      child: isXs
          ? Column(
              children: modeCards,
            )
          : Row(
              children: modeCards
                  .map((card) => Expanded(child: card))
                  .toList(),
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
          SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
        ],
        ..._subjects.map((subject) => SubjectPracticeCard(
            subject: subject,
            onTap: () => _startPractice(subject))),
      ],
    );
  }
}

class _ExtraModeCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ExtraModeCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Semantics(
          button: true,
          label: '$title, $description',
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: ResponsiveUtils.cardPadding(context),
              child: Column(
                children: [
                  Icon(icon, size: 32, color: iconColor),
                  SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: ResponsiveUtils.verticalSpacing(context) / 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
