import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/features/practice/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/features/sessions/data/repositories/study_session_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/practice/services/practice_session_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeStudySessionRepository extends StudySessionRepository {
  final List<StudySession> sessions = [];
  bool initCalled = false;

  @override
  Future<void> init() async {
    initCalled = true;
  }

  @override
  Future<void> create(StudySession session) async {
    sessions.add(session);
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
    late _FakeStudySessionRepository sessionRepo;
    late _FakeSpacedRepetitionRepository srRepo;
    late PracticeSessionService service;

    setUp(() {
      sessionRepo = _FakeStudySessionRepository();
      srRepo = _FakeSpacedRepetitionRepository();
      service = PracticeSessionService(
        sessionRepo: sessionRepo,
        srRepo: srRepo,
        subjectId: 'subj-1',
      );
    });

    group('timer', () {
      testWidgets('startTimer starts periodic timer', (tester) async {
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Text('test'),
        ));

        service.startTimer(tester.binding.rootElement! as BuildContext);
        expect(service.timer, isNotNull);
        expect(service.timer!.isActive, isTrue);
        service.cancelTimer();
      });

      test('cancelTimer cancels active timer', () {
        service.cancelTimer();
        expect(service.timer, isNull);
      });

      testWidgets('startTimer cancels existing timer first', (tester) async {
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Text('test'),
        ));

        service.startTimer(tester.binding.rootElement! as BuildContext);
        final firstTimer = service.timer;
        service.startTimer(tester.binding.rootElement! as BuildContext);
        expect(firstTimer!.isActive, isFalse);
        service.cancelTimer();
      });

      test('elapsedTimeFormatted is initially null', () {
        expect(service.elapsedTimeFormatted, isNull);
      });

      test('sessionStartTime returns the start time', () {
        final before = DateTime.now().subtract(const Duration(milliseconds: 1));
        final startTime = service.sessionStartTime;
        final after = DateTime.now().add(const Duration(milliseconds: 1));
        expect(startTime.compareTo(before), greaterThanOrEqualTo(0));
        expect(startTime.compareTo(after), lessThanOrEqualTo(0));
      });

      testWidgets('sessionStartTime is updated when startTimer is called', (tester) async {
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Text('test'),
        ));

        final beforeStart = DateTime.now().subtract(const Duration(milliseconds: 1));
        service.startTimer(tester.binding.rootElement! as BuildContext);
        final afterStart = DateTime.now().add(const Duration(milliseconds: 1));

        expect(service.sessionStartTime.compareTo(beforeStart), greaterThanOrEqualTo(0));
        expect(service.sessionStartTime.compareTo(afterStart), lessThanOrEqualTo(0));
        service.cancelTimer();
      });

      testWidgets('elapsedTimeFormatted is set after timer ticks', (tester) async {
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Text('test'),
        ));

        service.startTimer(tester.binding.rootElement! as BuildContext);
        await tester.pump(const Duration(seconds: 1));

        expect(service.elapsedTimeFormatted, isNotNull);
        expect(service.elapsedTimeFormatted, isNotEmpty);
        service.cancelTimer();
      });
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

      test('does not throw when repository fails', () async {
        await service.updateNextReview('q1', true);
      });
    });

    group('autoSaveSession', () {
      test('saves session to repository', () async {
        await service.autoSaveSession(
          questionsAnswered: 10,
          correctAnswers: 7,
        );

        expect(sessionRepo.initCalled, isTrue);
        expect(sessionRepo.sessions, hasLength(1));
        expect(sessionRepo.sessions[0].subjectId, 'subj-1');
        expect(sessionRepo.sessions[0].questionsAnswered, 10);
        expect(sessionRepo.sessions[0].correctAnswers, 7);
      });

      test('generates unique session IDs', () async {
        await service.autoSaveSession(
          questionsAnswered: 5,
          correctAnswers: 3,
        );
        await service.autoSaveSession(
          questionsAnswered: 8,
          correctAnswers: 6,
        );

        expect(sessionRepo.sessions, hasLength(2));
        expect(
          sessionRepo.sessions[0].id,
          isNot(sessionRepo.sessions[1].id),
        );
      });

      test('handles zero counts', () async {
        await service.autoSaveSession(
          questionsAnswered: 0,
          correctAnswers: 0,
        );

        expect(sessionRepo.sessions, hasLength(1));
        expect(sessionRepo.sessions[0].questionsAnswered, 0);
        expect(sessionRepo.sessions[0].correctAnswers, 0);
      });

      test('does not throw when save fails', () async {
        final failingRepo = _FailingStudySessionRepository();
        final failingService = PracticeSessionService(
          sessionRepo: failingRepo,
          srRepo: srRepo,
          subjectId: 'subj-1',
        );

        await failingService.autoSaveSession(
          questionsAnswered: 5,
          correctAnswers: 3,
        );
      });
    });
  });
}

class _FailingStudySessionRepository extends StudySessionRepository {
  @override
  Future<void> init() async => throw Exception('Init failed');

  @override
  Future<void> create(StudySession session) async =>
      throw Exception('Create failed');
}
