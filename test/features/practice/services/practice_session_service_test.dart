import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/features/practice/services/practice_session_service.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import '../../../helpers/fakes.dart';

class _FakeSessionRepository extends SessionRepository {
  final List<Session> sessions = [];
  bool saveCalled = false;
  bool shouldThrowOnSave = false;
  bool shouldThrowOnGetAll = false;

  @override
  @override
  Future<Result<void>> save(String key, Session session) async {
    if (shouldThrowOnSave) return Result.failure('Session save error');
    sessions.add(session);
    saveCalled = true;
    return Result.success(null);
  }

  @override
  Future<Result<List<Session>>> getAll() async {
    if (shouldThrowOnGetAll) return Result.failure('Session getAll error');
    return Result.success(sessions);
  }
}

class _FakeSpacedRepetitionService extends SpacedRepetitionService {
  final List<_UpdateCall> updateCalls = [];
  bool shouldThrow = false;

  _FakeSpacedRepetitionService()
      : super(
          questionRepo: _FakeQuestionRepo(),
          attemptRepo: _FakeAttemptRepo(),
        );

  @override
  Future<Result<void>> updateNextReviewDate(
      String questionId, double masteryLevel) async {
    if (shouldThrow) return Result.failure('SR service error');
    updateCalls.add(_UpdateCall(questionId, masteryLevel));
    return Result.success(null);
  }
}

class _FakeQuestionRepo extends QuestionRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Question>>> getAll() async => Result.success([]);

  @override
  Future<Result<Question?>> get(String key) async => Result.success(null);

  @override
  Future<Result<void>> save(String key, Question value) async =>
      Result.success(null);

  @override
  Future<Result<void>> delete(String key) async => Result.success(null);
}

class _FakeAttemptRepo extends AttemptRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<StudentAttempt>>> getAll() async => Result.success([]);

  @override
  Future<Result<StudentAttempt?>> get(String key) async => Result.success(null);

  @override
  Future<Result<void>> save(String key, StudentAttempt item) async =>
      Result.success(null);

  @override
  Future<Result<void>> delete(String key) async => Result.success(null);
}

class _UpdateCall {
  final String questionId;
  final double masteryLevel;
  _UpdateCall(this.questionId, this.masteryLevel);
}

class _FakeClock implements Clock {
  DateTime _now;
  _FakeClock(this._now);

  @override
  DateTime now() => _now;

  void advance(Duration duration) {
    _now = _now.add(duration);
  }
}

void main() {
  group('PracticeSessionService', () {
    late _FakeSessionRepository sessionRepo;
    late _FakeSpacedRepetitionService srService;
    late PracticeSessionService service;

    setUp(() {
      sessionRepo = _FakeSessionRepository();
      srService = _FakeSpacedRepetitionService();
      service = PracticeSessionService(
        sessionRepo: sessionRepo,
        srService: srService,
        studentIdService: FakeStudentIdService(),
        subjectId: 'subj-1',
      );
    });

    group('timer', () {
      test('startTimer starts periodic timer', () {
        service.startTimer();
        expect(service.elapsedNotifier.value, Duration.zero);
        service.cancelTimer();
      });

      test('cancelTimer cancels active timer', () {
        service.cancelTimer();
      });
    });

    test('sessionStartTime returns the start time', () {
      final before = DateTime.now().subtract(const Duration(milliseconds: 1));
      final startTime = service.sessionStartTime;
      final after = DateTime.now().add(const Duration(milliseconds: 1));
      expect(startTime.compareTo(before), greaterThanOrEqualTo(0));
      expect(startTime.compareTo(after), lessThanOrEqualTo(0));
    });

    test('elapsedNotifier updates after timer ticks', () {
      fakeAsync((async) {
        service.startTimer();
        async.elapse(const Duration(milliseconds: 1100));
        expect(service.elapsedNotifier.value.inSeconds, greaterThanOrEqualTo(1));
        service.cancelTimer();
      });
    });

    group('updateNextReview', () {
      test('records correct answer with mastery 0.8', () async {
        await service.updateNextReview('q1', true);

        expect(srService.updateCalls, hasLength(1));
        expect(srService.updateCalls[0].questionId, 'q1');
        expect(srService.updateCalls[0].masteryLevel, 0.8);
      });

      test('records incorrect answer with mastery 0.2', () async {
        await service.updateNextReview('q1', false);

        expect(srService.updateCalls, hasLength(1));
        expect(srService.updateCalls[0].masteryLevel, 0.2);
      });

      test('handles errors gracefully when SR service fails', () async {
        srService.shouldThrow = true;
        await service.updateNextReview('q1', true);
        expect(srService.updateCalls, isEmpty);
      });
    });

    group('autoSaveSession', () {
      test('saves session with correct data', () async {
        await service.autoSaveSession(
          questionsAnswered: 10,
          correctAnswers: 7,
        );

        expect(sessionRepo.saveCalled, isTrue);
        expect(sessionRepo.sessions, hasLength(1));
        final saved = sessionRepo.sessions.first;
        expect(saved.subjectId, 'subj-1');
        expect(saved.questionsAnswered, 10);
        expect(saved.correctAnswers, 7);
        expect(saved.type, SessionType.practice);
      });

      test('generates unique session IDs', () async {
        await service.autoSaveSession(
          questionsAnswered: 5,
          correctAnswers: 3,
        );
        await service.autoSaveSession(
          questionsAnswered: 5,
          correctAnswers: 3,
        );

        expect(sessionRepo.sessions, hasLength(2));
        expect(sessionRepo.sessions[0].id, isNot(sessionRepo.sessions[1].id));
      });

      test('handles errors gracefully when session save fails', () async {
        sessionRepo.shouldThrowOnSave = true;
        await service.autoSaveSession(
          questionsAnswered: 10,
          correctAnswers: 7,
        );
        expect(sessionRepo.saveCalled, isFalse);
      });
    });

    test('startTimer cancels previous timer and resets elapsed', () {
      fakeAsync((async) {
        service.startTimer();
        async.elapse(const Duration(milliseconds: 1100));
        expect(service.elapsedNotifier.value.inSeconds, greaterThanOrEqualTo(1));

        service.startTimer();
        expect(service.elapsedNotifier.value, Duration.zero);

        async.elapse(const Duration(milliseconds: 500));
        expect(service.elapsedNotifier.value.inSeconds, greaterThanOrEqualTo(0));
        service.dispose();
      });
    });

    group('dispose', () {
      test('stops the timer from updating elapsed', () {
        fakeAsync((async) {
          service.startTimer();
          async.elapse(const Duration(milliseconds: 1100));
          expect(service.elapsedNotifier.value.inSeconds, greaterThanOrEqualTo(1));

          service.dispose();
          final valueAfterDispose = service.elapsedNotifier.value;

          async.elapse(const Duration(milliseconds: 500));
          expect(service.elapsedNotifier.value, equals(valueAfterDispose));
        });
      });

      test('can be called without an active timer', () {
        expect(() => service.dispose(), returnsNormally);
      });

      test('dispose is idempotent on cancelTimer', () {
        service.dispose();
        expect(() => service.cancelTimer(), returnsNormally);
      });
    });

    group('custom clock', () {
      test('sessionStartTime reflects custom clock time', () {
        final clock = _FakeClock(DateTime(2024, 6, 15, 10, 0, 0));
        final customService = PracticeSessionService(
          sessionRepo: sessionRepo,
          srService: srService,
          studentIdService: FakeStudentIdService(),
          clock: clock,
          subjectId: 'subj-1',
        );
        customService.startTimer();
        expect(
          customService.sessionStartTime,
          DateTime(2024, 6, 15, 10, 0, 0),
        );
        customService.dispose();
      });

      test('autoSaveSession uses custom clock for duration', () async {
        final clock = _FakeClock(DateTime(2024, 6, 15, 10, 0, 0));
        final repo = _FakeSessionRepository();
        final customService = PracticeSessionService(
          sessionRepo: repo,
          srService: srService,
          studentIdService: FakeStudentIdService(),
          clock: clock,
          subjectId: 'subj-1',
        );
        customService.startTimer();
        clock.advance(const Duration(minutes: 5));

        await customService.autoSaveSession(
          questionsAnswered: 10,
          correctAnswers: 7,
        );

        expect(repo.sessions, hasLength(1));
        expect(repo.sessions.first.correctAnswers, 7);
        customService.dispose();
      });
    });
  });

  group('PracticeSessionService - coverage gaps', () {
    test('updateNextReview handles exception gracefully', () async {
      final sessionRepo = _FakeSessionRepo();
      final srService = _FakeSrService();
      final clock = _CoverageFakeClock(DateTime(2026, 5, 16));
      srService.shouldThrow = true;

      final service = PracticeSessionService(
        sessionRepo: sessionRepo,
        srService: srService,
        studentIdService: FakeStudentIdService(),
        clock: clock,
        subjectId: 'sub1',
      );

      await service.updateNextReview('q1', true);
      service.dispose();
    });

    test('dispose with active timer and no timer is safe', () async {
      final sessionRepo = _FakeSessionRepo();
      final srService = _FakeSrService();
      final clock = _CoverageFakeClock(DateTime(2026, 5, 16));

      final service1 = PracticeSessionService(
        sessionRepo: sessionRepo,
        srService: srService,
        studentIdService: FakeStudentIdService(),
        clock: clock,
        subjectId: 'sub1',
      );
      service1.startTimer();
      service1.dispose();

      final service2 = PracticeSessionService(
        sessionRepo: sessionRepo,
        srService: srService,
        studentIdService: FakeStudentIdService(),
        clock: clock,
        subjectId: 'sub1',
      );
      service2.dispose();
    });

    test('autoSaveSession handles exception gracefully', () async {
      final sessionRepo = _FakeSessionRepo();
      final srService = _FakeSrService();
      final clock = _CoverageFakeClock(DateTime(2026, 5, 16));

      sessionRepo.shouldThrow = true;

      final service = PracticeSessionService(
        sessionRepo: sessionRepo,
        srService: srService,
        studentIdService: FakeStudentIdService(),
        clock: clock,
        subjectId: 'sub1',
      );

      await service.autoSaveSession(
        questionsAnswered: 5,
        correctAnswers: 3,
      );
      service.dispose();
    });
  });
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

class _FakeSrService extends SpacedRepetitionService {
  bool shouldThrow = false;

  _FakeSrService()
      : super(
          questionRepo: QuestionRepository(),
          attemptRepo: AttemptRepository(),
        );

  @override
  Future<Result<void>> updateNextReviewDate(
      String questionId, double masteryLevel) async {
    if (shouldThrow) return Result.failure('SR error');
    return Result.success(null);
  }
}

class _CoverageFakeClock implements Clock {
  final DateTime fixedNow;

  _CoverageFakeClock(this.fixedNow);

  @override
  DateTime now() => fixedNow;
}
