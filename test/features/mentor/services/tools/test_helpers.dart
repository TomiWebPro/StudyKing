import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/practice/data/repositories/topic_dependency_repository.dart';
import 'package:studyking/features/practice/services/exam_session_service.dart';
import 'package:studyking/features/practice/services/readiness_scorer.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

// ---------------------------------------------------------------------------
// Hand-written fakes for mentor agent tool tests (no mockito/mocktail).
// ---------------------------------------------------------------------------

class FakeStudentIdService extends StudentIdService {
  final String _id;
  FakeStudentIdService([this._id = 'student-1']);

  @override
  String getStudentId() => _id;
}

class FakePlanAdherenceRepository extends PlanAdherenceRepository {
  final List<PlanAdherenceModel> records;
  FakePlanAdherenceRepository([this.records = const []]);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<PlanAdherenceModel>>> getByDateRange(
    String studentId,
    DateTime start,
    DateTime end,
  ) async {
    final filtered = records
        .where((r) =>
            r.studentId == studentId &&
            r.date.isAfter(start) &&
            r.date.isBefore(end))
        .toList();
    return Result.success(filtered);
  }
}

class FakePlanAdherenceOrchestrator extends PlanAdherenceOrchestrator {
  final PlanAdherenceRepository _fakeRepo;
  FakePlanAdherenceOrchestrator(this._fakeRepo) : super();

  @override
  PlanAdherenceRepository get adherenceRepository => _fakeRepo;
}

class FakeMasteryGraphService extends MasteryGraphService {
  List<MasteryState> weakTopics;
  List<QuestionMasteryState> atRisk;
  List<MasteryState> allMastery;
  MasteryState? topicMastery;

  FakeMasteryGraphService({
    this.weakTopics = const [],
    this.atRisk = const [],
    this.allMastery = const [],
    this.topicMastery,
  }) : super();

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async =>
      Result.success(weakTopics);

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(
    String studentId, {
    double threshold = 0.5,
  }) async =>
      Result.success(atRisk);

  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(
    String studentId,
  ) async =>
      Result.success(allMastery);

  @override
  Future<Result<MasteryState>> getTopicMastery(
    String studentId,
    String topicId,
  ) async =>
      Result.success(topicMastery ??
          (allMastery.isNotEmpty
              ? allMastery.first
              : MasteryState.initial(studentId: studentId, topicId: topicId)));
}

class FakeQuestionRepository extends QuestionRepository {
  List<Question> _all;
  FakeQuestionRepository([this._all = const []]);

  void setQuestions(List<Question> questions) => _all = questions;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async =>
      Result.success(_all.where((q) => q.subjectId == subjectId).toList());

  @override
  Future<Result<List<Question>>> getAll() async => Result.success(_all);
}

class FakeAttemptRepository extends AttemptRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async =>
      Result.success(const []);

  @override
  Future<Result<List<StudentAttempt>>> getAll() async => Result.success(const []);
}

class FakeStudyProgressTracker extends StudyProgressTracker {
  Map<String, dynamic> overallStats;

  FakeStudyProgressTracker(AppLocalizations l10n,
      [this.overallStats = const {}])
      : super(attemptRepo: FakeAttemptRepository(), l10n: l10n);

  @override
  Future<Result<Map<String, dynamic>>> getOverallStats(
    String studentId,
  ) async =>
      Result.success(overallStats);
}

class FakeLessonRepository extends LessonRepository {
  final List<Lesson> _all;
  FakeLessonRepository([this._all = const []]);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Lesson>>> getBySubject(String subjectId) async =>
      Result.success(_all.where((l) => l.subjectId == subjectId).toList());

  @override
  Future<Result<List<Lesson>>> getByTopic(String topicId) async =>
      Result.success(_all.where((l) => l.topicId == topicId).toList());

  @override
  Future<Result<List<Lesson>>> getBySubjectAndTopic(
    String subjectId,
    String topicId,
  ) async =>
      Result.success(_all
          .where((l) => l.subjectId == subjectId && l.topicId == topicId)
          .toList());

  @override
  Future<Result<List<Lesson>>> getAll() async => Result.success(_all);
}

class FakeTutorSessionRepository extends TutorSessionRepository {
  final List<TutorSession> sessions;
  FakeTutorSessionRepository([this.sessions = const []]);

  @override
  Future<Result<List<TutorSession>>> getStudentSessions(
    String studentId,
  ) async =>
      Result.success(
        sessions.where((s) => s.studentId == studentId).toList(),
      );
}

class FakeSubjectRepository extends SubjectRepository {
  final List<Subject> _all;
  FakeSubjectRepository([this._all = const []]);

  @override
  Future<Result<List<Subject>>> getAll() async => Result.success(_all);

  @override
  Future<Result<Subject?>> get(String id) async =>
      Result.success(_all.where((s) => s.id == id).firstOrNull);
}

class FakeTopicRepository extends TopicRepository {
  final List<Topic> _all;
  FakeTopicRepository([this._all = const []]);

  @override
  Future<Result<List<Topic>>> getBySubject(String subjectId) async =>
      Result.success(_all.where((t) => t.subjectId == subjectId).toList());
}

class FakeTopicDependencyRepository extends TopicDependencyRepository {
  final List<TopicDependency> _all;
  final TopicDependency? _byTopic;
  FakeTopicDependencyRepository([this._all = const [], this._byTopic]);

  @override
  Future<Result<List<TopicDependency>>> getAllDependencies() async =>
      Result.success(_all);

  @override
  Future<Result<TopicDependency>> getTopicDependency(String topicId) async =>
      Result.success(_byTopic ??
          _all.where((d) => d.topicId == topicId).firstOrNull ??
          TopicDependency(topicId: topicId));
}

class FakePlannerService extends PlannerService {
  PersonalLearningPlan? plan;
  bool scheduleResult = true;

  FakePlannerService([this.plan])
      : super(
          localeName: 'en',
        );

  @override
  Future<Result<PersonalLearningPlan?>> generatePlan({
    required String course,
    required int daysValue,
    required int hoursValue,
    String? name,
  }) async =>
      Result.success(plan);

  @override
  Future<Result<void>> adjustPace(double newTargetMinutesPerDay,
          {bool recalculateDuration = false}) async =>
      Result.success(null);

  @override
  Future<Result<PersonalLearningPlan?>> loadExistingPlan() async =>
      Result.success(plan);

  @override
  Future<Result<void>> extendPlan(int extraDays) async =>
      Result.success(null);

  @override
  Future<Result<void>> redistributeMissedWorkload(
    int missedMinutes, {
    String strategy = 'days:3',
  }) async =>
      Result.success(null);

  @override
  Future<Result<bool>> scheduleLesson({
    required String topicId,
    required String topicTitle,
    required String subjectId,
    required DateTime scheduledTime,
    int durationMinutes = 30,
  }) async =>
      Result.success(scheduleResult);
}

class FakeSpacedRepetitionService extends SpacedRepetitionService {
  List<Question> dueQuestions;
  FakeSpacedRepetitionService(this.dueQuestions)
      : super(
          questionRepo: FakeQuestionRepository(),
          attemptRepo: FakeAttemptRepository(),
        );

  @override
  Future<Result<List<Question>>> getPracticeQuestions(
    String subjectId,
  ) async =>
      Result.success(dueQuestions);
}

class FakeReadinessScorer extends ReadinessScorer {
  FakeReadinessScorer() : super();

  @override
  Future<List<ScoredQuestion>> scoreQuestions(
    List<Question> questions,
  ) async =>
      questions
          .map((q) => ScoredQuestion(question: q, score: 1.0))
          .toList();
}

class FakeSessionRepository extends SessionRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Session>>> getByStudent(String studentId) async =>
      Result.success(const []);

  @override
  Future<Result<List<Session>>> getAll() async => Result.success(const []);
}

class FakeExamSessionService extends ExamSessionService {
  List<Question> selected;
  FakeExamSessionService([this.selected = const []])
      : super(
          sessionRepo: FakeSessionRepository(),
          studentIdService: FakeStudentIdService(),
        );

  @override
  List<Question> selectQuestions({
    required List<Question> pool,
    required ExamConfig config,
  }) =>
      selected.isNotEmpty ? selected : pool;
}

PersonalLearningPlan sampleLearningPlan({String studentId = 'student-1'}) {
  return PersonalLearningPlan(
    studentId: studentId,
    generatedAt: DateTime.now(),
    dailyPlans: [
      DailyPlan(
        date: DateTime.now(),
        dayNumber: 1,
        priorityTopics: const [],
        reviewQuestionIds: const [],
        stretchGoalQuestionIds: const [],
        targetQuestions: 10,
        targetMinutes: 60,
      ),
      DailyPlan(
        date: DateTime.now().add(const Duration(days: 1)),
        dayNumber: 2,
        priorityTopics: const [],
        reviewQuestionIds: const [],
        stretchGoalQuestionIds: const [],
        targetQuestions: 10,
        targetMinutes: 60,
      ),
    ],
    summary: PlanSummary(
      totalQuestions: 20,
      totalMinutes: 120,
      newTopics: 2,
      reviewTopics: 0,
      estimatedCoverage: 1.0,
      focusAreas: const [],
    ),
    recommendations: const [],
    targetMinutesPerDay: 60,
    targetQuestionsPerDay: 10,
  );
}
