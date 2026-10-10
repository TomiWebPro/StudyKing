import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/service_providers.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/practice/services/exam_session_service.dart';
import 'package:studyking/features/practice/services/mastery_recorder.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/features/practice/presentation/screens/exam_session_screen.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider;
import 'package:studyking/features/sessions/providers/session_providers.dart' show sessionRepositoryProvider;
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';

import '../shared_test_helpers.dart';

final _l10n = AppLocalizationsEn();

/// Hand-written fake whose [recordAttempt] future only completes when the
/// test resolves it, so a test can double-tap Submit while the mastery
/// write is still in flight (the async window the double-submit guard
/// must cover).
class _ControllableMasteryRecorder extends MasteryRecorder {
  _ControllableMasteryRecorder()
      : super(
          masteryGraphService: FakeMasteryGraphService(),
          srEngine: SpacedRepetitionEngine(),
          attemptRepo: FakeAttemptRepository(),
          questionMasteryRepo: QuestionMasteryStateRepository(),
          questionRepo: FakeQuestionRepository(Result.success(const [])),
        );

  final List<String> attemptedQuestionIds = [];
  final Completer<void> _writeGate = Completer<void>();

  void completeAttempt() {
    if (!_writeGate.isCompleted) _writeGate.complete();
  }

  @override
  Future<Result<void>> recordAttempt({
    required String studentId,
    required String questionId,
    required String subjectId,
    required String topicId,
    required bool isCorrect,
    required int timeSpentMs,
    required int confidence,
    required String userAnswer,
    DateTime? timestamp,
  }) async {
    attemptedQuestionIds.add(questionId);
    await _writeGate.future;
    return Result.success(null);
  }
}

class _FixedClock implements Clock {
  final DateTime fixed;
  _FixedClock(this.fixed);
  @override
  DateTime now() => fixed;
}

class _ExamStudentIdService extends StudentIdService {
  @override
  Result<String> getStudentId() => Result.success('test-student-id');

  @override
  Future<Result<void>> init() async => Result.success(null);
}

class _RecordingSessionRepository extends SessionRepository {
  final List<Session> sessions = [];

  _RecordingSessionRepository() : super(clock: _FixedClock(DateTime(2024, 6, 15)));

  @override
  Future<Result<void>> save(String key, Session item) async {
    sessions.add(item);
    return Result.success(null);
  }

  @override
  Future<Result<Session?>> get(String key) async => Result.success(null);
}

class _ExamQuestionRepository extends QuestionRepository {
  final List<Question> _questions;

  _ExamQuestionRepository(this._questions);

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async {
    return Result.success(
      _questions.where((q) => q.subjectId == subjectId).toList(),
    );
  }
}

/// Deterministic exam service: selects questions in id order and persists
/// the finished exam as a [Session] whose `questionsAnswered` mirrors the
/// number of recorded [ExamQuestionResult]s.
class _DeterministicExamSessionService extends ExamSessionService {
  final SessionRepository recordingRepo;

  _DeterministicExamSessionService({required SessionRepository repo})
      : recordingRepo = repo,
        super(
          sessionRepo: repo,
          studentIdService: _ExamStudentIdService(),
          clock: _FixedClock(DateTime(2024, 6, 15)),
        );

  @override
  List<Question> selectQuestions({
    required List<Question> pool,
    required ExamConfig config,
  }) {
    final candidates = pool
        .where((q) => q.subjectId == config.subjectId)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return candidates.take(config.questionCount).toList();
  }

  @override
  Future<Result<ExamResult>> finishExam({
    required ExamConfig config,
    required List<ExamQuestionResult> questionResults,
    bool autoSubmitted = false,
  }) async {
    // Mirror the real service's finishExam: it cancels the exam timer
    // and deactivates without zeroing timeRemainingNotifier (calling
    // cancelExam() here would fire _onTimeChanged and re-trigger
    // auto-submit while the screen is still marked active).
    final endTime = DateTime.now();
    final startTime = endTime.subtract(const Duration(minutes: 1));
    final result = ExamResult(
      config: config,
      questionResults: questionResults,
      startTime: startTime,
      endTime: endTime,
      wasAutoSubmitted: autoSubmitted,
    );
    final session = Session(
      id: 'exam_${startTime.millisecondsSinceEpoch}',
      studentId: 'test-student-id',
      subjectId: config.subjectId,
      type: SessionType.practice,
      startTime: startTime,
      endTime: endTime,
      actualDurationMs: endTime.difference(startTime).inMilliseconds,
      questionsAnswered: questionResults.length,
      correctAnswers: result.totalCorrect,
      completed: true,
      tags: ['exam'],
    );
    await recordingRepo.save(session.id, session);
    return Result.success(result);
  }
}

Question _typedExamQuestion({String id = 'q1', String topicId = 't1'}) {
  final now = DateTime(2024, 1, 1);
  return Question(
    id: id,
    text: 'Text question $id?',
    type: QuestionType.typedAnswer,
    difficulty: 1,
    subjectId: 'sub1',
    topicId: topicId,
    markscheme: Markscheme(questionId: id, correctAnswer: 'Answer $id'),
    options: [],
    createdAt: now,
    updatedAt: now,
  );
}

Widget _examApp({
  required List<Question> questions,
  required MasteryRecorder recorder,
  required SessionRepository sessionRepo,
}) {
  return ProviderScope(
    overrides: [
      questionRepositoryProvider.overrideWithValue(_ExamQuestionRepository(questions)),
      examSessionServiceProvider.overrideWithValue(
        _DeterministicExamSessionService(repo: sessionRepo),
      ),
      sessionRepositoryProvider.overrideWithValue(sessionRepo),
      masteryRecorderProvider.overrideWithValue(recorder),
      studentIdServiceProvider.overrideWithValue(_ExamStudentIdService()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const ExamSessionScreen(subjectId: 'sub1', subjectName: 'Mathematics'),
    ),
  );
}

void main() {
  group('double-submit guard', () {
    group('PracticeSessionScreen', () {
      testWidgets('double-tap submit records the attempt exactly once', (tester) async {
        final recorder = _ControllableMasteryRecorder();
        final sessionRepo = FakeSessionRepository();
        final questions = [
          question(
            id: 'q1',
            text: 'What is 2+2?',
            type: QuestionType.typedAnswer,
            markschemeText: '4',
          ),
        ];

        await tester.pumpWidget(sessionApp(
          result: Result.success(questions),
          sessionRepo: sessionRepo,
          masteryRecorder: recorder,
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.enterText(find.byType(TextField).first, '4');
        await tester.pump();

        await tester.ensureVisible(find.text(_l10n.submitAnswer));
        await tester.pumpAndSettle();

        // First tap: the submission starts and the mastery write stays in flight.
        await tester.tap(find.text(_l10n.submitAnswer));
        await tester.pump();

        // Second tap lands while the write is still in flight.
        await tester.tap(find.text(_l10n.submitAnswer));
        await tester.pump();

        // Let the in-flight write complete.
        recorder.completeAttempt();
        await tester.pumpAndSettle();

        expect(recorder.attemptedQuestionIds, ['q1']);
        expect(find.text(_l10n.correctFeedback), findsWidgets);

        // Finish the session: the saved result must count the question once.
        await tester.ensureVisible(find.text(_l10n.next));
        await tester.pumpAndSettle();
        await tester.tap(find.text(_l10n.next));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        expect(sessionRepo.sessions, hasLength(1));
        expect(sessionRepo.sessions.first.correctAnswers, 1);
      });
    });

    group('ExamSessionScreen', () {
      testWidgets('double-tap submit records one result and one mastery attempt', (tester) async {
        final recorder = _ControllableMasteryRecorder();
        final sessionRepo = _RecordingSessionRepository();
        final questions = [_typedExamQuestion(id: 'q1')];

        await tester.pumpWidget(_examApp(
          questions: questions,
          recorder: recorder,
          sessionRepo: sessionRepo,
        ));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Start Exam'));
        await tester.pump();
        await tester.tap(find.text('Start Exam'));
        await tester.pump();
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byType(TextField));
        await tester.pump();
        await tester.enterText(find.byType(TextField), 'Answer q1');
        await tester.pump();

        await tester.ensureVisible(find.text(_l10n.submitAnswer));
        await tester.pumpAndSettle();

        // First tap: the submission starts and the mastery write stays in flight.
        await tester.tap(find.text(_l10n.submitAnswer));
        await tester.pump();

        // Second tap lands while the write is still in flight.
        await tester.tap(find.text(_l10n.submitAnswer));
        await tester.pump();

        // Let the in-flight write complete.
        recorder.completeAttempt();
        await tester.pumpAndSettle();

        expect(recorder.attemptedQuestionIds, ['q1']);
        expect(find.text(_l10n.correctFeedback), findsWidgets);

        // Last question: Next finishes the exam and persists the result.
        await tester.ensureVisible(find.widgetWithText(ElevatedButton, _l10n.next));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ElevatedButton, _l10n.next));
        await tester.pumpAndSettle();

        expect(sessionRepo.sessions, hasLength(1));
        expect(sessionRepo.sessions.first.questionsAnswered, 1);
        expect(sessionRepo.sessions.first.correctAnswers, 1);
      });
    });
  });
}
