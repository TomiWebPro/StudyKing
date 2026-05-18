import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/progress_export_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/practice/data/repositories/mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_evaluation_repository.dart';
import 'package:studyking/features/practice/data/repositories/topic_dependency_repository.dart';
import 'package:studyking/features/questions/data/models/question_evaluation_model.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';

class _FakeMasteryGraphService implements MasteryGraphService {
  List<MasteryState> states = [];

  @override
  final MasteryStateRepository masteryStateRepo = MasteryStateRepository();

  @override
  final QuestionEvaluationRepository questionEvaluationRepo = QuestionEvaluationRepository();

  @override
  final QuestionMasteryStateRepository questionMasteryRepo = QuestionMasteryStateRepository();

  @override
  final TopicDependencyRepository topicDependencyRepo = TopicDependencyRepository();

  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) async => Result.success(states);

  @override
  Future<Result<MasteryState>> getTopicMastery(String studentId, String topicId) async =>
      Result.success(MasteryState.initial(studentId: studentId, topicId: topicId));

  @override
  Future<Result<QuestionMasteryState>> getQuestionMastery(String studentId, String questionId) async =>
      Result.success(QuestionMasteryState.initial(studentId: studentId, questionId: questionId, now: DateTime.now()));

  @override
  Future<Result<void>> recordAttempt({required String studentId, required String topicId, required String questionId, required bool isCorrect, required int confidence, required int timeSpentMs, String? subtopicId}) async =>
      Result.success(null);

  @override
  Future<Result<List<QuestionMasteryState>>> getQuestionsDueForReview(String studentId, {DateTime? asOf}) async => Result.success([]);

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(String studentId, {double threshold = 0.5}) async => Result.success([]);

  @override
  Future<Result<List<MasteryState>>> getTopicsNeedingReview(String studentId) async => Result.success([]);

  @override
  Future<Result<List<QuestionMasteryState>>> getAllQuestionMastery(String studentId) async => Result.success([]);

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async => Result.success([]);

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) async => Result.success({});

  @override
  Future<Result<void>> migrateLegacyQuestion({required String questionId, String? markscheme, String? correctAnswer, List<String>? options, String? explanation}) async =>
      Result.success(null);

  @override
  Future<Result<void>> saveEvaluation(QuestionEvaluation evaluation) async => Result.success(null);

  @override
  Future<Result<double>> getReadinessScore(String studentId, String topicId) async => Result.success(0.0);

  @override
  Future<Result<double>> getReviewUrgency(String studentId, String topicId) async => Result.success(0.0);

  @override
  Future<void> init() async {}
}

class _FakeAttemptRepository implements AttemptRepository {
  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async => Result.success([]);

  @override
  Future<Result<List<StudentAttempt>>> getByStudentAndSubject(String studentId, String subjectId) async => Result.success([]);

  @override
  Future<Result<List<StudentAttempt>>> getByQuestion(String questionId) async => Result.success([]);

  @override
  Future<Result<List<StudentAttempt>>> getBySubject(String subjectId) async => Result.success([]);

  @override
  Future<Result<Map<String, dynamic>>> getSubjectStats(String subjectId) async => Result.success({});

  @override
  Future<Result<void>> create(StudentAttempt attempt) async => Result.success(null);

  @override
  Future<Result<void>> put(String key, StudentAttempt item) async => Result.success(null);

  @override
  Future<void> init() async {}

  @override
  Future<void> openBox(String boxName) async {}

  @override
  void attachBox(Box<StudentAttempt> box) {}

  @override
  Future<Result<void>> save(String key, StudentAttempt item) async => Result.success(null);

  @override
  Future<Result<StudentAttempt?>> get(String key) async => Result.success(null);

  @override
  Future<Result<List<StudentAttempt>>> getAll() async => Result.success([]);

  @override
  Future<Result<void>> delete(String key) async => Result.success(null);

  @override
  List<StudentAttempt> filterBy<K>(K Function(StudentAttempt) getter, K value) => [];

  @override
  Box<StudentAttempt> get box => _box!;
  Box<StudentAttempt>? _box;
}

class _FakeStudyProgressTracker implements StudyProgressTracker {
  Map<String, dynamic> overallStats = {};
  List<Map<String, dynamic>> badges = [];
  List<Map<String, dynamic>> trend = [];

  @override
  Future<Map<String, dynamic>> getOverallStats(String studentId) async => overallStats;

  @override
  Future<List<Map<String, dynamic>>> getBadges(String studentId) async => badges;

  @override
  Future<List<Map<String, dynamic>>> getWeeklyTrend(int weeks, {String? studentId}) async => trend;

  @override
  Future<Map<String, dynamic>> getTopicProgress(String studentId, String topicId) async => overallStats;

  @override
  Future<List<Map<String, dynamic>>> getRecommendations(String studentId) async => [];

  @override
  Future<String> getTopicMasteryLevel(String topicId, {String? studentId}) async => '';

  @override
  Future<MasteryLevel> getTopicMasteryLevelEnum(String topicId, {String? studentId}) async => MasteryLevel.novice;

  @override
  Future<String> exportProgressCSV(String studentId) async => '';

  @override
  Future<String> exportQuestionsAndAttemptsCSV(String studentId) async => '';

  @override
  Future<String> exportSessionHistoryCSV(String studentId) async => '';

  @override
  void updateLocalization(AppLocalizations l10n) {}
}

class _FakeL10n {
  String get csvOverallStats => 'Overall Statistics';
  String get csvColTotalAttempts => 'Total Attempts';
  String get csvColCorrect => 'Correct';
  String get csvColAccuracy => 'Accuracy';
  String get csvColAvgTime => 'Avg Time';
  String get csvColTotalHours => 'Total Hours';
  String get csvColWeeklyActivity => 'Weekly Activity';
  String get csvColDailyActivity => 'Daily Activity';
  String get csvColTopicsStudied => 'Topics Studied';
  String get csvTopicMastery => 'Topic Mastery';
  String get csvColTopicId => 'Topic ID';
  String get csvColMasteryLevel => 'Mastery Level';
  String get csvColLastPracticed => 'Last Practiced';
  String get csvColReviewUrgency => 'Review Urgency';
  String get csvAllAttempts => 'All Attempts';
  String get csvColQuestionId => 'Question ID';
  String get csvColSubjectId => 'Subject ID';
  String get csvColTime => 'Time';
  String get csvColTimestamp => 'Timestamp';
  String get csvWeeklyTrend => 'Weekly Trend';
  String get csvColWeek => 'Week';
  String get csvColAttempts => 'Attempts';
  String get csvColImprovement => 'Improvement';
  String get csvBadges => 'Badges';
  String get csvColBadgeName => 'Badge Name';
  String get csvColBadgeDescription => 'Description';
  String get csvColDateUnlocked => 'Date';
  String get masteryLevelNovice => 'Novice';
  String get masteryLevelBrowsing => 'Browsing';
  String get masteryLevelDeveloping => 'Developing';
  String get masteryLevelProficient => 'Proficient';
  String get masteryLevelExpert => 'Expert';
  String get pdfProgressReport => 'Progress Report';
  String pdfGenerated(String date) => 'Generated: $date';
  String pdfStudentId(String id) => 'Student: $id';
  String get pdfOverallStatistics => 'Overall Statistics';
  String get pdfMetric => 'Metric';
  String get pdfValue => 'Value';
  String get correctAnswers => 'Correct';
  String get accuracy => 'Accuracy';
  String get avgTime => 'Avg Time';
  String get totalStudyTime => 'Total Study Time';
  String get pdfTopicMasteryBreakdown => 'Topic Mastery';
  String get pdfTableTopic => 'Topic';
  String get pdfTableAttempts => 'Attempts';
  String get pdfTableLevel => 'Level';
  String get pdfNoMasteryData => 'No mastery data';
  String get pdfBadgesEarned => 'Badges';
  String get pdfNoBadges => 'No badges';
  String get pdfRecentActivitySummary => 'Recent Activity';
  String pdfTotalAttemptsRecorded(int count) => '$count attempts';
  String pdfDateRange(String from, String to) => '$from to $to';
  String pdfCorrectFraction(int correct, int total) => '$correct/$total correct';
}

void main() {
  group('ProgressExportService', () {
    late _FakeStudyProgressTracker mockTracker;
    late _FakeMasteryGraphService mockMastery;
    late _FakeAttemptRepository mockAttemptRepo;
    late ProgressExportService service;
    late _FakeL10n l10n;

    setUp(() {
      mockTracker = _FakeStudyProgressTracker();
      mockMastery = _FakeMasteryGraphService();
      mockAttemptRepo = _FakeAttemptRepository();
      l10n = _FakeL10n();
      service = ProgressExportService(
        tracker: mockTracker,
        masteryService: mockMastery,
        attemptRepo: mockAttemptRepo,
      );
    });

    group('exportComprehensiveCSV', () {
      test('returns CSV with overall stats section', () async {
        mockTracker.overallStats = {
          'totalAttempts': 10, 'correctAttempts': 7, 'accuracy': 0.7,
          'avgTimePerQuestion': 30.0, 'totalStudyTimeHours': 5.0,
          'weeklyActivity': 3, 'dailyActivity': 1, 'topicsStudied': 2,
        };
        final csv = await service.exportComprehensiveCSV('student1');
        expect(csv, contains('Overall Statistics'));
        expect(csv, contains('10'));
      });
    });

    group('exportComprehensivePDF', () {
      test('returns non-empty bytes', () async {
        mockTracker.overallStats = {
          'totalAttempts': 10, 'correctAttempts': 7, 'accuracy': 0.7,
          'avgTimePerQuestion': 30.0, 'totalStudyTimeHours': 5.0,
          'weeklyActivity': 3, 'dailyActivity': 1, 'topicsStudied': 2,
        };
        final bytes = await service.exportComprehensivePDF('student1', l10n as dynamic);
        expect(bytes, isNotEmpty);
      });
    });
  });
}
