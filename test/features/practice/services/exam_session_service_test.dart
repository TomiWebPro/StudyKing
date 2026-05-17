import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/practice/services/exam_session_service.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/models/session_model.dart';

class _FakeStudentIdService extends StudentIdService {
  @override
  String getStudentId() => 'test-student';
  @override
  Future<void> init() async {}
}

class _FakeSessionRepository extends SessionRepository {
  final List<Session> sessions = [];

  @override
  Future<Result<void>> save(String key, Session session) async {
    sessions.add(session);
    return Result.success(null);
  }

  @override
  Future<Result<Session?>> get(String id) async {
    final idx = sessions.indexWhere((s) => s.id == id);
    if (idx == -1) return Result.success(null);
    return Result.success(sessions[idx]);
  }

  @override
  Future<Result<List<Session>>> getAll() async {
    return Result.success(sessions);
  }
}

Question _createQuestion({
  String id = 'q1',
  String subjectId = 'sub1',
  String topicId = 't1',
  int difficulty = 1,
}) {
  return Question(
    id: id,
    text: 'Test?',
    type: QuestionType.singleChoice,
    difficulty: difficulty,
    subjectId: subjectId,
    topicId: topicId,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    options: ['A', 'B', 'C', 'D'],
    markscheme: null,
  );
}

void main() {
  group('ExamSessionService', () {
    late _FakeSessionRepository sessionRepo;
    late ExamSessionService service;

    setUp(() {
      sessionRepo = _FakeSessionRepository();
      service = ExamSessionService(
        sessionRepo: sessionRepo,
        studentIdService: _FakeStudentIdService(),
      );
    });

    tearDown(() {
      service.dispose();
    });

    group('selectQuestions', () {
      test('selects questions for subject', () {
        final pool = [
          _createQuestion(id: 'q1', subjectId: 'sub1'),
          _createQuestion(id: 'q2', subjectId: 'sub1'),
          _createQuestion(id: 'q3', subjectId: 'sub2'),
        ];

        final config = const ExamConfig(
          durationMinutes: 30,
          questionCount: 2,
          subjectId: 'sub1',
        );

        final selected = service.selectQuestions(pool: pool, config: config);
        expect(selected, hasLength(2));
        expect(selected.every((q) => q.subjectId == 'sub1'), isTrue);
      });

      test('selects questions for specific topics', () {
        final pool = [
          _createQuestion(id: 'q1', topicId: 't1'),
          _createQuestion(id: 'q2', topicId: 't1'),
          _createQuestion(id: 'q3', topicId: 't2'),
        ];

        final config = const ExamConfig(
          durationMinutes: 30,
          questionCount: 5,
          subjectId: 'sub1',
          topicIds: ['t1'],
        );

        final selected = service.selectQuestions(pool: pool, config: config);
        expect(selected.every((q) => q.topicId == 't1'), isTrue);
      });

      test('selects questions by difficulty distribution', () {
        final pool = List.generate(
          10,
          (i) => _createQuestion(
            id: 'q$i',
            difficulty: (i % 5) + 1,
          ),
        );

        final config = const ExamConfig(
          durationMinutes: 30,
          questionCount: 6,
          subjectId: 'sub1',
          easyCount: 2,
          mediumCount: 2,
          hardCount: 2,
        );

        final selected = service.selectQuestions(pool: pool, config: config);
        expect(selected.length, lessThanOrEqualTo(6));
      });

      test('returns empty when no matching questions', () {
        final config = const ExamConfig(
          durationMinutes: 30,
          questionCount: 5,
          subjectId: 'nonexistent',
        );

        final selected = service.selectQuestions(pool: [], config: config);
        expect(selected, isEmpty);
      });
    });

    group('exam lifecycle', () {
      test('startExam initializes timer', () {
        final config = const ExamConfig(
          durationMinutes: 30,
          questionCount: 5,
          subjectId: 'sub1',
        );

        service.startExam(config);
        expect(service.isActive, isTrue);
        expect(service.examActiveNotifier.value, isTrue);
        expect(service.timeRemainingNotifier.value.inMinutes, 30);

        service.cancelExam();
      });

      test('cancelExam stops exam', () {
        final config = const ExamConfig(
          durationMinutes: 30,
          questionCount: 5,
          subjectId: 'sub1',
        );

        service.startExam(config);
        expect(service.isActive, isTrue);

        service.cancelExam();
        expect(service.isActive, isFalse);
        expect(service.examActiveNotifier.value, isFalse);
      });

      test('finishExam saves session', () async {
        final config = const ExamConfig(
          durationMinutes: 30,
          questionCount: 2,
          subjectId: 'sub1',
        );

        final questions = [
          _createQuestion(id: 'q1'),
          _createQuestion(id: 'q2'),
        ];

        service.startExam(config);

        final results = questions.map((q) => ExamQuestionResult(
          question: q,
          userAnswer: 'A',
          isCorrect: true,
          timeSpentMs: 10000,
        )).toList();

        final examResult = await service.finishExam(
          config: config,
          questionResults: results,
        );

        expect(examResult.totalCorrect, 2);
        expect(examResult.accuracy, 1.0);
        expect(sessionRepo.sessions, hasLength(1));
        expect(sessionRepo.sessions.first.type, SessionType.practice);
        expect(sessionRepo.sessions.first.tags.contains('exam'), isTrue);
      });

      test('finishExam calculates accuracy correctly', () async {
        final config = const ExamConfig(
          durationMinutes: 30,
          questionCount: 4,
          subjectId: 'sub1',
        );

        final results = [
          ExamQuestionResult(question: _createQuestion(id: 'q1'), isCorrect: true, timeSpentMs: 1000),
          ExamQuestionResult(question: _createQuestion(id: 'q2'), isCorrect: false, timeSpentMs: 1000),
          ExamQuestionResult(question: _createQuestion(id: 'q3'), isCorrect: true, timeSpentMs: 1000),
          ExamQuestionResult(question: _createQuestion(id: 'q4'), isCorrect: false, timeSpentMs: 1000),
        ];

        service.startExam(config);
        final examResult = await service.finishExam(
          config: config,
          questionResults: results,
        );

        expect(examResult.totalCorrect, 2);
        expect(examResult.totalIncorrect, 2);
        expect(examResult.accuracy, 0.5);
      });

      test('finishExam with skipped questions', () async {
        final config = const ExamConfig(
          durationMinutes: 30,
          questionCount: 3,
          subjectId: 'sub1',
        );

        final results = [
          ExamQuestionResult(question: _createQuestion(id: 'q1'), isCorrect: true, timeSpentMs: 1000),
          ExamQuestionResult(
            question: _createQuestion(id: 'q2'),
            isCorrect: false,
            timeSpentMs: 0,
            wasSkipped: true,
          ),
          ExamQuestionResult(question: _createQuestion(id: 'q3'), isCorrect: false, timeSpentMs: 1000),
        ];

        service.startExam(config);
        final examResult = await service.finishExam(
          config: config,
          questionResults: results,
        );

        expect(examResult.totalSkipped, 1);
        expect(examResult.totalCorrect, 1);
        expect(examResult.totalIncorrect, 1);
        expect(examResult.accuracy, 0.5);
      });

      test('topicBreakdown groups results by topic', () async {
        final config = const ExamConfig(
          durationMinutes: 30,
          questionCount: 4,
          subjectId: 'sub1',
        );

        final results = [
          ExamQuestionResult(question: _createQuestion(id: 'q1', topicId: 't1'), isCorrect: true, timeSpentMs: 1000),
          ExamQuestionResult(question: _createQuestion(id: 'q2', topicId: 't1'), isCorrect: false, timeSpentMs: 1000),
          ExamQuestionResult(question: _createQuestion(id: 'q3', topicId: 't2'), isCorrect: true, timeSpentMs: 1000),
          ExamQuestionResult(question: _createQuestion(id: 'q4', topicId: 't2'), isCorrect: true, timeSpentMs: 1000),
        ];

        service.startExam(config);
        final examResult = await service.finishExam(
          config: config,
          questionResults: results,
        );

        expect(examResult.topicBreakdown['t1'], 0.5);
        expect(examResult.topicBreakdown['t2'], 1.0);
      });

      test('averageTimePerQuestionMs calculates correctly', () async {
        final config = const ExamConfig(
          durationMinutes: 30,
          questionCount: 3,
          subjectId: 'sub1',
        );

        final results = [
          ExamQuestionResult(question: _createQuestion(id: 'q1'), isCorrect: true, timeSpentMs: 10000),
          ExamQuestionResult(question: _createQuestion(id: 'q2'), isCorrect: true, timeSpentMs: 20000),
          ExamQuestionResult(question: _createQuestion(id: 'q3'), isCorrect: true, timeSpentMs: 30000),
        ];

        service.startExam(config);
        final examResult = await service.finishExam(
          config: config,
          questionResults: results,
        );

        expect(examResult.averageTimePerQuestionMs, 20000);
      });
    });
  });
}
