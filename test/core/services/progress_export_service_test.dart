import 'dart:convert';
import 'dart:io';

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
  List<StudentAttempt> attempts = [];

  @override
  bool get isOpen => true;

  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async =>
      Result.success(attempts);

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

/// Extracts the text strings rendered into a PDF document's content
/// streams so unit tests can assert on what the export actually drew.
/// The `pdf` package deflates every content stream, so each stream is
/// inflated before its `(string)` operands are collected.
List<String> _extractPdfStrings(List<int> pdfBytes) {
  final raw = latin1.decode(pdfBytes);
  final strings = <String>[];
  final streamRegex = RegExp(r'stream\r?\n(.*?)\r?\nendstream', dotAll: true);
  for (final match in streamRegex.allMatches(raw)) {
    final segment = match.group(1)!;
    try {
      final content = latin1.decode(zlib.decode(latin1.encode(segment)));
      for (final m in RegExp(r'\(((?:[^()\\]|\\.)*)\)').allMatches(content)) {
        strings.add(m.group(1)!
            .replaceAll(r'\(', '(')
            .replaceAll(r'\)', ')')
            .replaceAll(r'\\', '\\'));
      }
    } catch (e) {
      // Streams that are not zlib-deflated (e.g. metadata) carry no
      // rendered text; skip them.
      debugPrint('Skipping non-deflate PDF stream: $e');
    }
  }
  return strings;
}

void main() {
  group('ProgressExportService', () {
    late _FakeStudyProgressTracker mockTracker;
    late _FakeMasteryGraphService mockMastery;
    late _FakeAttemptRepository mockAttemptRepo;
    late ProgressExportService service;
    late AppLocalizations l10n;
    late AppLocalizations esL10n;

    setUpAll(() async {
      await initializeDateFormatting();
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
      esL10n = await AppLocalizations.delegate.load(const Locale('es'));
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

      test('weekly trend section labels rows with the ISO week number, not the month', () async {
        mockTracker.overallStats = {
          'totalAttempts': 10, 'correctAttempts': 7, 'accuracy': 0.7,
          'avgTimePerQuestion': 30.0, 'totalStudyTimeHours': 5.0,
          'weeklyActivity': 3, 'dailyActivity': 1, 'topicsStudied': 2,
        };
        // A week starting 2026-10-05 is in calendar month 10 but ISO
        // week 41. The old export rendered the month number as the week
        // ("2026-W10"), mislabeling the Week column.
        mockTracker.trend = [
          {
            'week': 2026,
            'month': 10,
            'weekNumber': 41,
            'attempts': 5,
            'accuracy': 80,
            'improvement': 0.0,
            'isGap': false,
          },
        ];
        final csv = await service.exportComprehensiveCSV('student1');
        expect(csv.isSuccess, isTrue);
        expect(csv.data, contains('2026-W41'));
        expect(csv.data, isNot(contains('2026-W10')));
      });

      test('mastery level column stays invariant English for es locale',
          () async {
        mockTracker.overallStats = {
          'totalAttempts': 10, 'correctAttempts': 7, 'accuracy': 0.7,
          'avgTimePerQuestion': 30.0, 'totalStudyTimeHours': 5.0,
          'weeklyActivity': 3, 'dailyActivity': 1, 'topicsStudied': 2,
        };
        mockMastery.states = [
          MasteryState(
            studentId: 'student1',
            topicId: 'topic-1',
            lastAttempt: DateTime(2026, 1, 1),
            lastUpdated: DateTime(2026, 1, 1),
            masteryLevel: MasteryLevel.novice,
            accuracy: 0.4,
          ),
          MasteryState(
            studentId: 'student1',
            topicId: 'topic-2',
            lastAttempt: DateTime(2026, 1, 2),
            lastUpdated: DateTime(2026, 1, 2),
            masteryLevel: MasteryLevel.proficient,
            accuracy: 0.8,
          ),
        ];
        final csv = await service.exportComprehensiveCSV('student1',
            l10n: esL10n);
        expect(csv.isSuccess, isTrue);
        // CSV is data and must stay locale-independent even though an
        // es AppLocalizations was passed (AGENTS.md CSV invariant rule).
        expect(csv.data, contains('Novice'));
        expect(csv.data, contains('Proficient'));
        expect(csv.data, isNot(contains('Novato')));
        expect(csv.data, isNot(contains('Competente')));
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

      test('avg time per question uses the locale decimal separator',
          () async {
        mockTracker.overallStats = {
          'totalAttempts': 10,
          'correctAttempts': 7,
          'accuracy': 0.7,
          'avgTimePerQuestion': 12.5,
          'totalStudyTimeHours': 5.0,
          'weeklyActivity': 3,
          'dailyActivity': 1,
          'topicsStudied': 2,
        };
        // Regression: the avg-time cell used raw string interpolation,
        // which always emits a period separator ("12.5s") regardless of
        // locale. PDF exports are user-facing and must use the user's
        // locale (AGENTS.md i18n convention), so es renders "12,5s".
        final bytes = await service.exportComprehensivePDF('student1', esL10n);
        expect(bytes.isSuccess, isTrue);
        final rendered = _extractPdfStrings(bytes.data!);
        expect(rendered.any((s) => s.contains('12,5')), isTrue);
        expect(rendered.any((s) => s.contains('12.5')), isFalse);
      });

      test('recent activity renders attempts in the PDF without error',
          () async {
        mockTracker.overallStats = {
          'totalAttempts': 10, 'correctAttempts': 7, 'accuracy': 0.7,
          'avgTimePerQuestion': 30.0, 'totalStudyTimeHours': 5.0,
          'weeklyActivity': 3, 'dailyActivity': 1, 'topicsStudied': 2,
        };
        mockAttemptRepo.attempts = [
          StudentAttempt(
            id: 'q1_1',
            studentId: 'student1',
            questionId: 'q1',
            subjectId: 's1',
            timestamp: DateTime(2026, 1, 1),
          ),
          StudentAttempt(
            id: 'q2_2',
            studentId: 'student1',
            questionId: 'q2',
            subjectId: 's1',
            timestamp: DateTime(2026, 1, 10),
          ),
        ];
        final bytes = await service.exportComprehensivePDF("student1", l10n);
        expect(bytes.isSuccess, isTrue);
        expect(bytes.data, isNotEmpty);
      });

      test('overall statistics fall back to zeroed defaults on failure',
          () async {
        // Regression: the PDF export used to fall back to an empty map
        // when getOverallStats failed, rendering literal "null" (and
        // "nulls" for avg time) cells in the Overall Statistics table
        // instead of the zeroed defaults the JSON/CSV exports use.
        final bytes = await ProgressExportService(
          tracker: _FailingStudyProgressTracker(),
          masteryService: _FailingMasteryGraphService(),
          attemptRepo: _FailingAttemptRepository(),
        ).exportComprehensivePDF('student1', l10n);

        expect(bytes.isSuccess, isTrue);
        final rendered = _extractPdfStrings(bytes.data!);
        expect(rendered.where((s) => s.contains('null')), isEmpty);
        expect(rendered, contains('Total'));
        expect(rendered, contains('Attempts'));
        expect(rendered, contains('0'));
      });
    });

    group('dateRangeLabel', () {
      final oldestFirst = [
        StudentAttempt(
          id: 'q1_1',
          studentId: 'student1',
          questionId: 'q1',
          subjectId: 's1',
          timestamp: DateTime(2026, 1, 1),
        ),
        StudentAttempt(
          id: 'q2_2',
          studentId: 'student1',
          questionId: 'q2',
          subjectId: 's1',
          timestamp: DateTime(2026, 1, 10),
        ),
      ];

      test('renders the range oldest to newest', () async {
        // Regression: the PDF used to pass attempts.last (newest) as
        // the range start, producing "Date range: Jan 10 to Jan 1".
        expect(
          ProgressExportService.dateRangeLabel(oldestFirst, l10n),
          'Date range: 1/1/2026 to 1/10/2026',
        );
      });

      test('sorts attempts before rendering, newest-first input included',
          () async {
        expect(
          ProgressExportService.dateRangeLabel(oldestFirst.reversed.toList(), l10n),
          'Date range: 1/1/2026 to 1/10/2026',
        );
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
