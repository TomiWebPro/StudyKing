import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/practice/services/exam_session_service.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import '../../../helpers/fakes.dart';
import 'package:studyking/core/utils/clock.dart';

Question _q({
  required String id,
  required String text,
  QuestionType type = QuestionType.singleChoice,
  String markschemeText = 'A',
  String topicId = 'topic-a',
  List<String> options = const [],
  String? explanation,
  int difficulty = 1,
}) {
  final now = DateTime.utc(2024, 1, 1);
  return Question(
    id: id,
    text: text,
    type: type,
    difficulty: difficulty,
    subjectId: 'subject-a',
    topicId: topicId,
    markscheme: Markscheme(
      questionId: id,
      correctAnswer: markschemeText,
      explanation: explanation,
    ),
    options: options,
    createdAt: now,
    updatedAt: now,
    explanation: explanation,
  );
}

void main() {
  group('ExamResult', () {
    group('accuracy', () {
      test('returns 1.0 when all correct', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 2, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q'), isCorrect: true, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q'), isCorrect: true, timeSpentMs: 100),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.accuracy, 1.0);
      });

      test('returns 0.0 when all incorrect', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 2, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q'), isCorrect: false, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q'), isCorrect: false, timeSpentMs: 100),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.accuracy, 0.0);
      });

      test('returns 0.5 when half correct', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 2, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q'), isCorrect: true, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q'), isCorrect: false, timeSpentMs: 100),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.accuracy, 0.5);
      });

      test('excludes skipped from denominator', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 3, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q'), isCorrect: true, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q'), isCorrect: false, timeSpentMs: 0, wasSkipped: true),
            ExamQuestionResult(question: _q(id: 'q3', text: 'Q'), isCorrect: false, timeSpentMs: 100),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.accuracy, 0.5);
      });

      test('returns 0.0 when no non-skipped questions', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 1, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q'), isCorrect: false, timeSpentMs: 0, wasSkipped: true),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.accuracy, 0.0);
      });

      test('returns 0.0 when questionResults is empty', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 0, subjectId: 's'),
          questionResults: [],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.accuracy, 0.0);
      });
    });

    group('topicBreakdown', () {
      test('groups results by topic', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 4, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q', topicId: 't1'), isCorrect: true, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q', topicId: 't1'), isCorrect: false, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q3', text: 'Q', topicId: 't2'), isCorrect: true, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q4', text: 'Q', topicId: 't2'), isCorrect: true, timeSpentMs: 100),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.topicBreakdown['t1'], 0.5);
        expect(result.topicBreakdown['t2'], 1.0);
      });

      test('excludes skipped from topic breakdown', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 2, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q', topicId: 't1'), isCorrect: true, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q', topicId: 't1'), isCorrect: false, timeSpentMs: 0, wasSkipped: true),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.topicBreakdown['t1'], 1.0);
      });

      test('returns empty map for empty results', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 0, subjectId: 's'),
          questionResults: [],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.topicBreakdown, isEmpty);
      });
    });

    group('averageTimePerQuestionMs', () {
      test('calculates average correctly', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 3, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q'), isCorrect: true, timeSpentMs: 10000),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q'), isCorrect: true, timeSpentMs: 20000),
            ExamQuestionResult(question: _q(id: 'q3', text: 'Q'), isCorrect: true, timeSpentMs: 30000),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.averageTimePerQuestionMs, 20000);
      });

      test('returns 0.0 for empty results', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 0, subjectId: 's'),
          questionResults: [],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.averageTimePerQuestionMs, 0.0);
      });
    });

    group('counts', () {
      test('totalCorrect, totalIncorrect, totalSkipped', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 3, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q'), isCorrect: true, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q'), isCorrect: false, timeSpentMs: 0, wasSkipped: true),
            ExamQuestionResult(question: _q(id: 'q3', text: 'Q'), isCorrect: false, timeSpentMs: 100),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.totalCorrect, 1);
        expect(result.totalIncorrect, 1);
        expect(result.totalSkipped, 1);
      });
    });
  });

  group('ExamConfig', () {
    test('creates with required fields', () {
      const config = ExamConfig(
        durationMinutes: 30,
        questionCount: 10,
        subjectId: 's1',
      );
      expect(config.durationMinutes, 30);
      expect(config.questionCount, 10);
      expect(config.subjectId, 's1');
      expect(config.topicIds, isNull);
      expect(config.easyCount, isNull);
    });

    test('creates with all optional fields', () {
      const config = ExamConfig(
        durationMinutes: 45,
        questionCount: 20,
        subjectId: 's1',
        easyCount: 5,
        mediumCount: 10,
        hardCount: 5,
        topicIds: ['t1', 't2'],
      );
      expect(config.easyCount, 5);
      expect(config.mediumCount, 10);
      expect(config.hardCount, 5);
      expect(config.topicIds, ['t1', 't2']);
    });
  });

  group('ExamQuestionResult', () {
    test('creates with required fields', () {
      final q = _q(id: 'q1', text: 'Test');
      final result = ExamQuestionResult(
        question: q,
        isCorrect: true,
        timeSpentMs: 5000,
      );
      expect(result.question, q);
      expect(result.isCorrect, isTrue);
      expect(result.timeSpentMs, 5000);
      expect(result.userAnswer, isNull);
      expect(result.wasSkipped, isFalse);
    });

    test('creates with all fields', () {
      final q = _q(id: 'q1', text: 'Test');
      final result = ExamQuestionResult(
        question: q,
        userAnswer: 'A',
        isCorrect: true,
        timeSpentMs: 5000,
        wasSkipped: false,
      );
      expect(result.userAnswer, 'A');
      expect(result.wasSkipped, isFalse);
    });

    test('creates with skipped flag', () {
      final q = _q(id: 'q1', text: 'Test');
      final result = ExamQuestionResult(
        question: q,
        isCorrect: false,
        timeSpentMs: 0,
        wasSkipped: true,
      );
      expect(result.wasSkipped, isTrue);
    });
  });

  group('ExamSessionService error-state', () {
    test('finishExam handles session save failure gracefully', () async {
      final failingRepo = _FailingSessionRepository();
      final studentIdService = FakeStudentIdService();
      final service = ExamSessionService(
        sessionRepo: failingRepo,
        studentIdService: studentIdService,
        clock: _FixedClock(DateTime(2024, 6, 15, 12, 0)),
      );

      final config = ExamConfig(
        durationMinutes: 30,
        questionCount: 1,
        subjectId: 'sub1',
      );
      service.startExam(config);

      final result = await service.finishExam(
        config: config,
        questionResults: [
          ExamQuestionResult(
            question: _q(id: 'q1', text: 'Q'),
            isCorrect: true,
            timeSpentMs: 100,
          ),
        ],
      );
      expect(result, isA<ExamResult>());
      expect(result.totalCorrect, 1);
      service.dispose();
    });

    test('isTimeUp returns true for fresh exam (initial Duration.zero)', () {
      final failingRepo = _FailingSessionRepository();
      final studentIdService = FakeStudentIdService();
      final service = ExamSessionService(
        sessionRepo: failingRepo,
        studentIdService: studentIdService,
        clock: _FixedClock(DateTime(2024, 6, 15, 12, 0)),
      );
      expect(service.isTimeUp(), isTrue);
      service.dispose();
    });

    test('cancelExam clears state', () async {
      final repo = _FailingSessionRepository();
      final studentIdService = FakeStudentIdService();
      final service = ExamSessionService(
        sessionRepo: repo,
        studentIdService: studentIdService,
        clock: _FixedClock(DateTime(2024, 6, 15, 12, 0)),
      );

      final config = ExamConfig(
        durationMinutes: 30,
        questionCount: 1,
        subjectId: 'sub1',
      );
      service.startExam(config);
      expect(service.isActive, isTrue);

      service.cancelExam();
      expect(service.isActive, isFalse);
      service.dispose();
    });
  });


  group('ExamSessionService - coverage gaps', () {
  late ExamSessionService service;
  late _FakeSessionRepo sessionRepo;

  setUp(() {
    sessionRepo = _FakeSessionRepo();
    service = ExamSessionService(
      sessionRepo: sessionRepo,
      studentIdService: FakeStudentIdService(),
    );
  });

  tearDown(() {
    service.dispose();
  });

  group('isTimeUp', () {
    test('returns true when remaining is zero', () {
      final config = const ExamConfig(
        durationMinutes: 30,
        questionCount: 5,
        subjectId: 'sub1',
      );
      service.startExam(config);
      service.cancelExam();
      expect(service.isTimeUp(), isTrue);
    });

    test('returns false when time remains', () {
      final config = const ExamConfig(
        durationMinutes: 30,
        questionCount: 5,
        subjectId: 'sub1',
      );
      service.startExam(config);
      expect(service.isTimeUp(), isFalse);
      service.cancelExam();
    });
  });

  group('ExamSessionService lifecycle', () {
    test('finishExam with autoSubmitted sets correct tags', () async {
      final config = const ExamConfig(
        durationMinutes: 30,
        questionCount: 1,
        subjectId: 'sub1',
      );
      service.startExam(config);

      await service.finishExam(
        config: config,
        questionResults: [
          ExamQuestionResult(
              question: _createQ(id: 'q1'),
              isCorrect: true,
              timeSpentMs: 1000),
        ],
        autoSubmitted: true,
      );

      expect(sessionRepo.sessions.first.tags.contains('auto_submit:true'),
          isTrue);
    });

    test('finishExam without autoSubmitted sets correct tags', () async {
      final config = const ExamConfig(
        durationMinutes: 30,
        questionCount: 1,
        subjectId: 'sub1',
      );
      service.startExam(config);

      await service.finishExam(
        config: config,
        questionResults: [
          ExamQuestionResult(
              question: _createQ(id: 'q1'),
              isCorrect: true,
              timeSpentMs: 1000),
        ],
      );

      expect(sessionRepo.sessions.first.tags.contains('auto_submit:false'),
          isTrue);
    });

    test('dispose cancels timer and disposes notifiers', () {
      final localService = ExamSessionService(
        sessionRepo: sessionRepo,
        studentIdService: FakeStudentIdService(),
      );
      final config = const ExamConfig(
        durationMinutes: 30,
        questionCount: 5,
        subjectId: 'sub1',
      );
      localService.startExam(config);

      localService.cancelExam();
      localService.dispose();
    });

    test('ExamSessionService.dispose is safe to call once', () {
      final localService = ExamSessionService(
        sessionRepo: sessionRepo,
        studentIdService: FakeStudentIdService(),
      );
      localService.dispose();
    });
  });
}

class _FailingSessionRepository extends SessionRepository {
  _FailingSessionRepository() : super(clock: _FixedClock(DateTime(2024, 6, 15, 12, 0)));

  @override
  Future<Result<void>> save(String key, Session item) async {
    return Result.failure('Save failed');
  }

  @override
  Future<Result<Session?>> get(String key) async {
    return Result.success(null);
  }

  @override
  Future<Result<List<Session>>> getAll() async {
    return Result.success([]);
  }
}

class _FixedClock implements Clock {
  final DateTime fixed;
  _FixedClock(this.fixed);
  @override
  DateTime now() => fixed;
}

class _FakeSessionRepo extends SessionRepository {
  final List<Session> sessions = [];
  bool shouldThrow = false;

  @override
  @override
  Future<Result<void>> save(String key, Session session) async {
    if (shouldThrow) return Result.failure('Save error');
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

Question _createQ({
  String id = 'q1',
  String subjectId = 'sub1',
  String topicId = 't1',
  int difficulty = 1,
  String? srDataJson,
}) {
  return Question(
    id: id,
    text: 'Sample question?',
    type: QuestionType.singleChoice,
    subjectId: subjectId,
    topicId: topicId,
    difficulty: difficulty,
    createdAt: DateTime(2026, 5, 12),
    updatedAt: DateTime(2026, 5, 12),
    srDataJson: srDataJson,
  );
}
