import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/progress_export_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/repositories/mastery_state_repository.dart';
import 'package:studyking/core/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_evaluation_repository.dart';
import 'package:studyking/features/practice/data/repositories/topic_dependency_repository.dart';
import 'package:studyking/features/questions/data/models/question_evaluation_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';

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
  Future<Result<void>> recordTopicAttempt({required String studentId, required String topicId, required bool isCorrect, required int confidence, required int timeSpentMs, String? subtopicId}) async =>
      Result.success(null);

  @override
  Future<Result<void>> recordQuestionAttempt({required String studentId, required String questionId, required bool isCorrect, required int confidence, required int timeSpentMs}) async =>
      Result.success(null);

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
  Future<Result<void>> init() async => Result.success(null);
}

class _FakeAttemptRepository implements AttemptRepository {
  @override
  bool get isOpen => true;

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
  Future<Result<void>> init() async => Result.success(null);

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
  Future<Result<Map<String, dynamic>>> getOverallStats(String studentId) async => Result.success(overallStats);

  @override
  Future<Result<List<Map<String, dynamic>>>> getBadges(String studentId) async => Result.success(badges);

  @override
  Future<Result<List<Map<String, dynamic>>>> getWeeklyTrend(int weeks, {String? studentId}) async => Result.success(trend);

  @override
  Future<Result<List<Map<String, dynamic>>>> getDailyTrend(int days, {String? studentId}) async => Result.success(trend);

  @override
  Future<Result<Map<String, dynamic>>> getTopicProgress(String studentId, String topicId) async => Result.success(overallStats);

  @override
  Future<Result<List<Map<String, dynamic>>>> getRecommendations(String studentId) async => Result.success([]);

  @override
  Future<Result<String>> getTopicMasteryLevel(String topicId, {String? studentId}) async => Result.success('');

  @override
  Future<Result<MasteryLevel>> getTopicMasteryLevelEnum(String topicId, {String? studentId}) async => Result.success(MasteryLevel.novice);

  @override
  Future<Result<String>> exportProgressCSV(String studentId) async => Result.success('');

  @override
  Future<Result<String>> exportQuestionsAndAttemptsCSV(String studentId) async => Result.success('');

  @override
  Future<Result<String>> exportSessionHistoryCSV(String studentId) async => Result.success('');

  @override
  void updateLocalization(AppLocalizations l10n) {}
}

class _FailingStudyProgressTracker implements StudyProgressTracker {
  @override
  Future<Result<Map<String, dynamic>>> getOverallStats(String studentId) async =>
      Result.failure('stats unavailable');

  @override
  Future<Result<List<Map<String, dynamic>>>> getBadges(String studentId) async =>
      Result.failure('badges unavailable');

  @override
  Future<Result<List<Map<String, dynamic>>>> getWeeklyTrend(int weeks, {String? studentId}) async =>
      Result.failure('trend unavailable');

  @override
  Future<Result<List<Map<String, dynamic>>>> getDailyTrend(int days, {String? studentId}) async => Result.success([]);

  @override
  Future<Result<Map<String, dynamic>>> getTopicProgress(String studentId, String topicId) async => Result.success({});

  @override
  Future<Result<List<Map<String, dynamic>>>> getRecommendations(String studentId) async => Result.success([]);

  @override
  Future<Result<String>> getTopicMasteryLevel(String topicId, {String? studentId}) async => Result.success('');

  @override
  Future<Result<MasteryLevel>> getTopicMasteryLevelEnum(String topicId, {String? studentId}) async => Result.success(MasteryLevel.novice);

  @override
  Future<Result<String>> exportProgressCSV(String studentId) async => Result.success('');

  @override
  Future<Result<String>> exportQuestionsAndAttemptsCSV(String studentId) async => Result.success('');

  @override
  Future<Result<String>> exportSessionHistoryCSV(String studentId) async => Result.success('');

  @override
  void updateLocalization(AppLocalizations l10n) {}
}

class _FailingMasteryGraphService implements MasteryGraphService {
  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) async =>
      Result.failure('mastery unavailable');

  @override
  Future<Result<MasteryState>> getTopicMastery(String studentId, String topicId) async => Result.success(MasteryState.initial(studentId: studentId, topicId: topicId));

  @override
  Future<Result<QuestionMasteryState>> getQuestionMastery(String studentId, String questionId) async => Result.success(QuestionMasteryState.initial(studentId: studentId, questionId: questionId, now: DateTime.now()));

  @override
  Future<Result<void>> recordTopicAttempt({required String studentId, required String topicId, required bool isCorrect, required int confidence, required int timeSpentMs, String? subtopicId}) async => Result.success(null);

  @override
  Future<Result<void>> recordQuestionAttempt({required String studentId, required String questionId, required bool isCorrect, required int confidence, required int timeSpentMs}) async => Result.success(null);

  @override
  Future<Result<void>> recordAttempt({required String studentId, required String topicId, required String questionId, required bool isCorrect, required int confidence, required int timeSpentMs, String? subtopicId}) async => Result.success(null);

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
  Future<Result<void>> migrateLegacyQuestion({required String questionId, String? markscheme, String? correctAnswer, List<String>? options, String? explanation}) async => Result.success(null);

  @override
  Future<Result<void>> saveEvaluation(QuestionEvaluation evaluation) async => Result.success(null);

  @override
  Future<Result<double>> getReadinessScore(String studentId, String topicId) async => Result.success(0.0);

  @override
  Future<Result<double>> getReviewUrgency(String studentId, String topicId) async => Result.success(0.0);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  MasteryStateRepository get masteryStateRepo => MasteryStateRepository();

  @override
  QuestionEvaluationRepository get questionEvaluationRepo => QuestionEvaluationRepository();

  @override
  QuestionMasteryStateRepository get questionMasteryRepo => QuestionMasteryStateRepository();

  @override
  TopicDependencyRepository get topicDependencyRepo => TopicDependencyRepository();
}

class _FailingAttemptRepository implements AttemptRepository {
  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async =>
      Result.failure('attempts unavailable');

  @override
  bool get isOpen => true;

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
  Future<Result<void>> init() async => Result.success(null);

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

List<String> _capturedLogs = [];
void _installLogCapture() {
  _capturedLogs.clear();
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) _capturedLogs.add(message);
  };
}

void _uninstallLogCapture() {
  debugPrint = debugPrintThrottled;
}

void main() {
  group('ProgressExportService', () {
    late _FakeStudyProgressTracker mockTracker;
    late _FakeMasteryGraphService mockMastery;
    late _FakeAttemptRepository mockAttemptRepo;
    late ProgressExportService service;
    late AppLocalizations l10n;

    setUpAll(() async {
      await initializeDateFormatting();
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    setUp(() {
      mockTracker = _FakeStudyProgressTracker();
      mockMastery = _FakeMasteryGraphService();
      mockAttemptRepo = _FakeAttemptRepository();
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
        expect(csv.isSuccess, isTrue);
        expect(csv.data, contains('Overall Statistics'));
        expect(csv.data, contains('10'));
      });
    });

    group('exportComprehensivePDF', () {
      test('returns non-empty bytes', () async {
        mockTracker.overallStats = {
          'totalAttempts': 10, 'correctAttempts': 7, 'accuracy': 0.7,
          'avgTimePerQuestion': 30.0, 'totalStudyTimeHours': 5.0,
          'weeklyActivity': 3, 'dailyActivity': 1, 'topicsStudied': 2,
        };
        final bytes = await service.exportComprehensivePDF("student1", l10n);
        expect(bytes.isSuccess, isTrue);
        expect(bytes.data, isNotEmpty);
      });
    });

    group('swallowed Result failures', () {
      ProgressExportService failingService() => ProgressExportService(
            tracker: _FailingStudyProgressTracker(),
            masteryService: _FailingMasteryGraphService(),
            attemptRepo: _FailingAttemptRepository(),
          );

      test('exportComprehensiveJSON logs warnings and degrades gracefully', () async {
        _installLogCapture();
        addTearDown(_uninstallLogCapture);

        final result = await failingService().exportComprehensiveJSON("student1", l10n);

        expect(result.isSuccess, isTrue);
        final warnings = _capturedLogs.where((l) => l.contains('[W]')).toList();
        expect(warnings, isNotEmpty);
        expect(warnings.any((l) => l.contains('getOverallStats')), isTrue);
        expect(warnings.any((l) => l.contains('getBadges')), isTrue);
        expect(warnings.any((l) => l.contains('getAllTopicMastery')), isTrue);
      });

      test('exportComprehensiveCSV logs warnings and degrades gracefully', () async {
        _installLogCapture();
        addTearDown(_uninstallLogCapture);

        final result = await failingService().exportComprehensiveCSV("student1", l10n: l10n);

        expect(result.isSuccess, isTrue);
        final warnings = _capturedLogs.where((l) => l.contains('[W]')).toList();
        expect(warnings, isNotEmpty);
        expect(warnings.any((l) => l.contains('getWeeklyTrend')), isTrue);
      });

      test('exportComprehensivePDF logs warnings and degrades gracefully', () async {
        _installLogCapture();
        addTearDown(_uninstallLogCapture);

        final result = await failingService().exportComprehensivePDF("student1", l10n);

        expect(result.isSuccess, isTrue);
        final warnings = _capturedLogs.where((l) => l.contains('[W]')).toList();
        expect(warnings, isNotEmpty);
        expect(warnings.any((l) => l.contains('getOverallStats')), isTrue);
      });

      test('shareComprehensiveJSON logs warnings and degrades gracefully', () async {
        _installLogCapture();
        addTearDown(_uninstallLogCapture);

        final result = await failingService().shareComprehensiveJSON("student1", "file", l10n);

        expect(result.isSuccess || result.isFailure, isTrue);
        final warnings = _capturedLogs.where((l) => l.contains('[W]')).toList();
        expect(warnings, isNotEmpty);
        expect(warnings.any((l) => l.contains('getBadges')), isTrue);
      });
    });
  });
}
