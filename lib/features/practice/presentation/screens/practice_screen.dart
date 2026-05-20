import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/errors/handlers.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/providers/study_progress_provider.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/subjects/providers/subject_repository_provider.dart';
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider;
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
import 'package:studyking/core/widgets/widgets.dart';


class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen>
    with AutomaticKeepAliveClientMixin {
  static final Logger _logger = const Logger('PracticeScreen');
  late final PracticeDataService _dataService;
  late final SpacedRepetitionService _srService;
  late final QuestionRepository _questionRepo;
  late final StudentIdService _studentIdService;
  late final SessionRepository _sessionRepo;
  late final StudyProgressTracker _progressTracker;
  List<Subject> _subjects = [];
  bool _isLoading = true;
  String? _loadError;
  Map<String, int> _dueCounts = {};
  bool _isLoadingDueCounts = false;
  bool _dueCountsLoadFailed = false;
  int _totalQuestionCount = 0;
  int _questionsToday = 0;
  bool _questionCountLoadFailed = false;
  bool _isLoadingActivity = true;
  int _weeklyAccuracy = 0;
  int _weeklyActivity = 0;
  int _practiceStreak = 0;
  int _weakTopicCount = 0;
  int _mediumTopicCount = 0;
  int _strongTopicCount = 0;
  List<Session> _recentSessions = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _srService = ref.read(spacedRepetitionServiceProvider);
    _questionRepo = ref.read(questionRepositoryProvider);
    _studentIdService = ref.read(studentIdServiceProvider);
    _sessionRepo = ref.read(sessionRepositoryProvider);
    _progressTracker = ref.read(studyProgressTrackerProvider);
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
      _loadActivity();
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
      _logger.w('Failed to load due counts', e);
      if (mounted) {
        setState(() {
          _isLoadingDueCounts = false;
          _dueCountsLoadFailed = true;
        });
      }
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
        _logger.w('Failed to load attempts count', e);
        _questionsToday = 0;
      }

      if (!mounted) return;
      setState(() {
        _totalQuestionCount = allQuestions.length;
      });
    } catch (e) {
      _logger.w('Failed to load question count', e);
      if (mounted) setState(() => _questionCountLoadFailed = true);
    }
  }

  Future<void> _loadActivity() async {
    try {
      final studentId = _studentIdService.getStudentId();
      final statsResult = await _progressTracker.getOverallStats(studentId);
      final stats = statsResult.data ?? <String, dynamic>{};
      final weeklyAcc = stats['accuracy'] as int? ?? 0;
      final weeklyAct = stats['weeklyActivity'] as int? ?? 0;

      final allMasteryResult =
          await ref.read(masteryGraphServiceProvider).getAllTopicMastery(studentId);
      final allMastery = allMasteryResult.data ?? [];
      int weak = 0, medium = 0, strong = 0;
      for (final ms in allMastery) {
        switch (ms.masteryLevel) {
          case MasteryLevel.novice:
          case MasteryLevel.browsing:
          case MasteryLevel.developing:
            weak++;
          case MasteryLevel.proficient:
            medium++;
          case MasteryLevel.expert:
            strong++;
        }
      }

      final sessionsResult = await _sessionRepo.getByStudent(studentId);
      final sessions = sessionsResult.data ?? [];
      final now = DateTime.now();
      final today = now.dateOnly;
      int streak = 0;
      for (var i = 0; i < 365; i++) {
        final day = today.subtract(Duration(days: i));
        final hasActivity = sessions.any((s) =>
            s.startTime.isSameDay(day) && s.completed) ||
            (allMastery.any((ms) => ms.lastAttempt.isSameDay(day)));
        if (hasActivity) {
          streak++;
        } else {
          break;
        }
      }

      final recentSessions = sessions
          .where((s) => s.completed && s.endTime != null)
          .toList()
        ..sort((a, b) => b.endTime!.compareTo(a.endTime!));
      final recent = recentSessions.take(3).toList();

      if (!mounted) return;
      setState(() {
        _isLoadingActivity = false;
        _weeklyAccuracy = weeklyAcc;
        _weeklyActivity = weeklyAct;
        _practiceStreak = streak;
        _weakTopicCount = weak;
        _mediumTopicCount = medium;
        _strongTopicCount = strong;
        _recentSessions = recent;
      });
    } catch (e) {
      _logger.w('Failed to load activity stats', e);
      if (mounted) setState(() => _isLoadingActivity = false);
    }
  }

  Future<void> _startPractice(Subject subject) async {
    final topicIds = await _getSubjectTopicIds(subject.id);
    final canProceed = await _checkPrerequisitesForTopicIds(topicIds);
    if (!canProceed) return;
    if (!mounted) return;
    final result = await Navigator.pushNamed(context, AppRoutes.practiceSession,
        arguments: PracticeSessionArgs(subjectId: subject.id)) as PracticeSessionResult?;
    _onSessionResult(result);
  }

  Future<List<String>> _getSubjectTopicIds(String subjectId) async {
    try {
      final repo = TopicRepository();
      await repo.init();
      final result = await repo.getBySubject(subjectId);
      return (result.data ?? []).map((t) => t.id).toList();
    } catch (e) {
      _logger.w('Failed to get subject topic IDs', e);
      return [];
    }
  }

  Future<bool> _checkPrerequisitesForTopicIds(
    List<String> topicIds,
  ) async {
    if (topicIds.isEmpty) return true;
    final prereqCheck = PrerequisiteCheckService();
    final allUnmetTopics = <String, Topic>{};
    for (final topicId in topicIds) {
      final result = await prereqCheck.checkPrerequisites(
        topicId: topicId,
        studentId: _studentIdService.getStudentId(),
      );
      if (result.isSuccess &&
          !result.data!.isReady &&
          result.data!.unmetPrerequisiteTopics.isNotEmpty) {
        for (final t in result.data!.unmetPrerequisiteTopics) {
          allUnmetTopics[t.id] = t;
        }
      }
    }
    if (allUnmetTopics.isEmpty) return true;
    if (!mounted) return false;
    final dialogResult = await PrerequisiteCheckService.showPrerequisiteDialog(
      context,
      unmetTopics: allUnmetTopics.values.toList(),
    );
    return dialogResult != true;
  }

  Future<void> _startTopicPractice(String topicId) async {
    try {
      final prereqCheck = PrerequisiteCheckService();
      final prereqResult = await prereqCheck.checkPrerequisites(
        topicId: topicId,
        studentId: _studentIdService.getStudentId(),
      );
      if (prereqResult.isSuccess &&
          !prereqResult.data!.isReady &&
          prereqResult.data!.unmetPrerequisiteTopics.isNotEmpty) {
        if (mounted) {
          final dialogResult = await PrerequisiteCheckService.showPrerequisiteDialog(
            context,
            unmetTopics: prereqResult.data!.unmetPrerequisiteTopics,
          );
          if (dialogResult == true) return;
        } else {
          return;
        }
      }

      final allQuestionsResult = await _questionRepo.getAll();
      final allQuestions = allQuestionsResult.data ?? [];
      final topicQuestions =
          allQuestions.where((q) => q.topicId == topicId).toList();
      if (topicQuestions.isEmpty) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.noQuestionsAvailable)));
        return;
      }
      final scorer = ref.read(readinessScorerProvider);
      final scored = await scorer.scoreQuestions(topicQuestions);
      final orderedIds = scored.map((s) => s.question.id).toList();
      if (!mounted) return;
      final tResult = await Navigator.pushNamed(context,
              AppRoutes.practiceSession,
              arguments: PracticeSessionArgs(
                subjectId: topicQuestions.first.subjectId,
                topicId: topicId,
                orderedQuestionIds: orderedIds,
                questionCount: orderedIds.length,
              )) as PracticeSessionResult?;
      _onSessionResult(tResult);
    } catch (e) {
      _logger.w('Error starting practice session', e);
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
      final allQuestionsResult = await _questionRepo.getAll();
      final allQuestions = allQuestionsResult.data ?? [];
      final subjectQuestions =
          allQuestions.where((q) => q.subjectId == subject.id).toList();
      final minAttempts = (subjectQuestions.length * 0.3).ceil().clamp(3, 50);

      final attemptRepo = ref.read(attemptRepositoryProvider);
      final attemptResult = await attemptRepo.getByStudent(studentId);
      final allAttempts = attemptResult.data ?? [];
      final subjectAttempts =
          allAttempts.where((a) => a.subjectId == subject.id).toList();
      if (subjectAttempts.length < minAttempts) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${subject.name}: Need at least $minAttempts attempted questions (30% of this subject) to identify weak areas')));
        return;
      }

      final insufficientData =
          allAttempts.length < minAttempts * 3;
      final weakTopicsResult =
          await masteryService.getWeakTopics(studentId);
      if (weakTopicsResult.isFailure ||
          weakTopicsResult.data == null ||
          weakTopicsResult.data!.isEmpty) {
        if (!mounted) return;
        if (insufficientData) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Need at least $minAttempts attempted questions (30% of this subject). ${l10n.noQuestionsAvailable}')));
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.noWeakAreasFound)));
        }
        return;
      }
      final weakTopicIds =
          weakTopicsResult.data!.map((s) => s.topicId).toSet();
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
      final topicIds = await _getSubjectTopicIds(subject.id);
      final canProceed = await _checkPrerequisitesForTopicIds(topicIds);
      if (!canProceed) return;
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
      if (_subjects.isNotEmpty) {
        final allTopicIds = <String>[];
        for (final subject in _subjects) {
          allTopicIds.addAll(await _getSubjectTopicIds(subject.id));
        }
        final canProceed = await _checkPrerequisitesForTopicIds(allTopicIds);
        if (!canProceed) return;
      }
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
      final result = await Navigator.pushNamed(context, AppRoutes.practiceSession,
          arguments: PracticeSessionArgs(
            subjectId: atRiskQuestions.first.subjectId,
            orderedQuestionIds: orderedIds,
            questionCount: orderedIds.length,
          )) as PracticeSessionResult?;
      _onSessionResult(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noWeakAreasFound)));
      }
    }
  }

  Future<void> _navigateToExam(Subject subject) async {
    final topicIds = await _getSubjectTopicIds(subject.id);
    final canProceed = await _checkPrerequisitesForTopicIds(topicIds);
    if (!canProceed) return;
    if (!mounted) return;
    await Navigator.pushNamed(
      context,
      AppRoutes.examSession,
      arguments: ExamSessionArgs(
        subjectId: subject.id,
        subjectName: subject.name,
      ),
    );
    _loadDueCounts();
  }

  Future<void> _showExamHistory() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final box = await Hive.openBox(HiveBoxNames.examResults);
      final allResults = box.values.cast<Map<String, dynamic>>().toList()
        ..sort((a, b) {
          final aTime = (a['result'] as Map<String, dynamic>?)?['startTime'] as String? ?? '';
          final bTime = (b['result'] as Map<String, dynamic>?)?['startTime'] as String? ?? '';
          return bTime.compareTo(aTime);
        });
      if (!mounted || allResults.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noExamHistory)),
          );
        }
        return;
      }
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.examHistory),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: allResults.take(20).map((entry) {
                final result = entry['result'] as Map<String, dynamic>?;
                if (result == null) return const SizedBox.shrink();
                final accuracy = (result['accuracy'] as num?)?.toDouble() ?? 0.0;
                final totalCorrect = (result['totalCorrect'] as num?)?.toInt() ?? 0;
                final totalIncorrect = (result['totalIncorrect'] as num?)?.toInt() ?? 0;
                final totalSkipped = (result['totalSkipped'] as num?)?.toInt() ?? 0;
                final totalQuestions = totalCorrect + totalIncorrect + totalSkipped;
                final startTime = result['startTime'] as String? ?? '';
                final date = startTime.length >= 10 ? startTime.substring(0, 10) : startTime;
                return ListTile(
                  dense: true,
                  title: Text(
                    '${formatPercent(accuracy * 100, l10n.localeName, minFractionDigits: 0)} — $totalQuestions ${l10n.questionsLabel}',
                  ),
                  subtitle: Text(date),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.close),
            ),
          ],
        ),
      );
    } catch (e) {
      _logger.w('Failed to load exam history', e);
    }
  }

  void _showSourcePracticeSheet() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (_subjects.isNotEmpty) {
        final allTopicIds = <String>[];
        for (final subject in _subjects) {
          allTopicIds.addAll(await _getSubjectTopicIds(subject.id));
        }
        final canProceed = await _checkPrerequisitesForTopicIds(allTopicIds);
        if (!canProceed) return;
      }
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
          onSourceSelected: (sourceId, sourceTitle) async {
            final sourceQuestions = allQuestions
                .where((q) => q.sourceIds.contains(sourceId))
                .toList();
            if (sourceQuestions.isNotEmpty) {
              final sourceSubjectId = sourceQuestions.first.subjectId;
              final topicIds = await _getSubjectTopicIds(sourceSubjectId);
              final canProceed = await _checkPrerequisitesForTopicIds(topicIds);
              if (!canProceed) return;
              if (!mounted) return;
              Navigator.pushNamed(context, AppRoutes.practiceSession,
                  arguments: PracticeSessionArgs(
                    subjectId: sourceSubjectId,
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
      final topics = await _dataService.loadTopicsWithNames(_questionRepo);
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
          onTopicSelected: (topicId) => _startTopicPractice(topicId));
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
        final topicIds = await _getSubjectTopicIds(_subjects.first.id);
        final canProceed = await _checkPrerequisitesForTopicIds(topicIds);
        if (!canProceed) return;
        await _launchWeakAreasForSubject(masteryService, _subjects.first);
        return;
      }
      if (!mounted) return;
      WeakAreasSheet.show(context,
          subjects: _subjects,
          onSubjectSelected: (subject) async {
            final topicIds = await _getSubjectTopicIds(subject.id);
            final canProceed = await _checkPrerequisitesForTopicIds(topicIds);
            if (!canProceed) return;
            await _launchWeakAreasForSubject(masteryService, subject);
          });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.noWeakAreasFound)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.practiceMode),
        actions: const [],
      ),
      body: _buildBody(),
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          final isXs = constraints.maxWidth < 360;
          if (isXs) {
            return FloatingActionButton.small(
              onPressed: _subjects.isEmpty ? null : () => _showSubjectSelector(),
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.play_arrow),
            );
          }
          return SizedBox(
            width: constraints.maxWidth - 64,
            child: FloatingActionButton.extended(
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
        },
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

  Widget _buildActivitySection() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (_isLoadingActivity) {
      return Card(
        child: Padding(
          padding: ResponsiveUtils.cardPadding(context),
          child: const LinearProgressIndicator(),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: ResponsiveUtils.cardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildActivityItem(
                  icon: Icons.trending_up,
                  label: l10n.accuracy,
                  value: formatPercent(_weeklyAccuracy.toDouble(), l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0),
                ),
                _buildActivityItem(
                  icon: Icons.local_fire_department,
                  label: l10n.thisWeek,
                  value: '$_weeklyActivity',
                ),
                _buildActivityItem(
                  icon: Icons.star,
                  label: l10n.weeklyActivity,
                  value: '${_practiceStreak}d',
                ),
              ],
            ),
            if (_weakTopicCount > 0 || _mediumTopicCount > 0 || _strongTopicCount > 0)
              Padding(
                padding: EdgeInsets.only(
                  top: ResponsiveUtils.verticalSpacing(context) / 2,
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (_weakTopicCount > 0)
                      _buildMasteryChip(context,
                          '$_weakTopicCount ${l10n.masteryLevelDeveloping}',
                          theme.colorScheme.error),
                    if (_mediumTopicCount > 0)
                      _buildMasteryChip(context,
                          '$_mediumTopicCount ${l10n.masteryLevelProficient}',
                          theme.colorScheme.tertiary),
                    if (_strongTopicCount > 0)
                      _buildMasteryChip(context,
                          '$_strongTopicCount ${l10n.masteryLevelExpert}',
                          theme.colorScheme.primary),
                  ],
                ),
              ),
            if (_recentSessions.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  top: ResponsiveUtils.verticalSpacing(context) / 2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.recentSessions,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...(_recentSessions.take(3).map((s) {
                      final score = s.questionsAnswered > 0
                          ? '${(s.correctAnswers / s.questionsAnswered * 100).round()}%'
                          : '-';
                      final date = formatDate(s.startTime, l10n: l10n);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '$date — $score',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    })),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasteryChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
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
    if (_isLoading) return const LoadingScreen();
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: ResponsiveUtils.screenPadding(context),
          child: ErrorRetryWidget(
            message: l10n.somethingWentWrong,
            retryLabel: l10n.retry,
            onRetry: _retryLoadSubjects,
          ),
        ),
      );
    }
    if (_subjects.isEmpty) return const Center(child: PracticeEmptyState());
    return RefreshIndicator(
      onRefresh: _loadSubjects,
      child: ListView(
        padding: ResponsiveUtils.listPadding(context),
        children: [
          if (_dueCountsLoadFailed || _questionCountLoadFailed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ErrorRetryWidget(
                message: l10n.somethingWentWrong,
                retryLabel: l10n.retry,
                onRetry: () {
                  setState(() {
                    _dueCountsLoadFailed = false;
                    _questionCountLoadFailed = false;
                  });
                  _loadDueCounts();
                  _loadQuestionCount();
                },
              ),
            ),
          _buildSummaryRow(),
          const SizedBox(height: 8),
          _buildActivitySection(),
          const SizedBox(height: 8),
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
      _ExtraModeCard(
        icon: Icons.history,
        iconColor: Theme.of(context).colorScheme.primary,
        title: l10n.examHistory,
        description: l10n.viewPastExamResults,
        onTap: _showExamHistory,
      ),
    ];
    return Padding(
      padding: ResponsiveUtils.listPadding(context),
      child: LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: modeCards
              .map((card) => SizedBox(
                    width: isXs || constraints.maxWidth < 500
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 8) / 2,
                    child: card,
                  ))
              .toList(),
        ),
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
