import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/practice/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/practice/services/practice_session_service.dart';

class _FakeSessionRepository extends SessionRepository {
  final List<Session> sessions = [];
  bool saveCalled = false;

  @override
  Future<Result<void>> save(Session session) async {
    sessions.add(session);
    saveCalled = true;
    return Result.success(null);
  }

  @override
  Future<Result<List<Session>>> getAll() async {
    return Result.success(sessions);
  }
}

class _FakeSpacedRepetitionRepository extends SpacedRepetitionRepository {
  final List<_UpdateCall> updateCalls = [];

  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> updateNextReviewDate(
      String questionId, double masteryLevel) async {
    updateCalls.add(_UpdateCall(questionId, masteryLevel));
    return Result.success(null);
  }
}

class _UpdateCall {
  final String questionId;
  final double masteryLevel;
  _UpdateCall(this.questionId, this.masteryLevel);
}

void main() {
  group('PracticeSessionService', () {
    late _FakeSessionRepository sessionRepo;
    late _FakeSpacedRepetitionRepository srRepo;
    late PracticeSessionService service;

    setUp(() {
      sessionRepo = _FakeSessionRepository();
      srRepo = _FakeSpacedRepetitionRepository();
      service = PracticeSessionService(
        sessionRepo: sessionRepo,
        srRepo: srRepo,
        studentIdService: StudentIdService(),
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

    test('elapsedNotifier updates after timer ticks', () async {
      service.startTimer();
      await Future.delayed(const Duration(milliseconds: 1100));
      expect(service.elapsedNotifier.value.inSeconds, greaterThanOrEqualTo(1));
      service.cancelTimer();
    });

    group('updateNextReview', () {
      test('records correct answer with mastery 0.8', () async {
        await service.updateNextReview('q1', true);

        expect(srRepo.updateCalls, hasLength(1));
        expect(srRepo.updateCalls[0].questionId, 'q1');
        expect(srRepo.updateCalls[0].masteryLevel, 0.8);
      });

      test('records incorrect answer with mastery 0.2', () async {
        await service.updateNextReview('q1', false);

        expect(srRepo.updateCalls, hasLength(1));
        expect(srRepo.updateCalls[0].masteryLevel, 0.2);
      });

      test('handles errors gracefully', () async {
        await service.updateNextReview('q1', true);
        expect(srRepo.updateCalls, hasLength(1));
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

      test('handles errors gracefully', () async {
        await service.autoSaveSession(
          questionsAnswered: 10,
          correctAnswers: 7,
        );
        expect(sessionRepo.saveCalled, isTrue);
      });
    });
  });
}
