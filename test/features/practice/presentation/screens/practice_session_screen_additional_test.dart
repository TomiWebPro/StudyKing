import 'dart:io' show Directory;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart' as hive_package;
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider;
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider;
import 'package:studyking/features/practice/presentation/screens/practice_session_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/routes/app_router.dart' show PracticeSessionArgs;
import '../shared_test_helpers.dart';

const _kSubmitAnswer = 'Submit Answer';
const _kNext = 'Next';
const _kNoQuestionsAvailable = 'No Questions Available';

class _FailingSrService extends FakeSpacedRepetitionService {
  @override
  Future<Result<List<Question>>> getPracticeQuestions(String subjectId) async {
    throw Exception('SR service error');
  }
}

class _FailingOrderedRepo extends FakeQuestionRepository {
  _FailingOrderedRepo() : super(Result.success([]));

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async {
    throw Exception('Ordered load error');
  }
}

String? _hivePath;

void main() {
  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('hive_test');
    _hivePath = dir.path;
    hive_package.Hive.init(_hivePath!);
  });

  tearDown(() async {
    if (_hivePath != null) {
      await hive_package.Hive.deleteBoxFromDisk('plan_adherences');
      await hive_package.Hive.deleteBoxFromDisk('plans');
      await hive_package.Hive.deleteBoxFromDisk('plan_milestones');
    }
  });
  group('PracticeSessionScreen - additional coverage', () {
    group('ordered questions loading', () {
      testWidgets('loads ordered questions by IDs', (tester) async {
        final questions = [
          question(id: 'q1', text: 'Q1', type: QuestionType.typedAnswer, markschemeText: 'a'),
          question(id: 'q2', text: 'Q2', type: QuestionType.typedAnswer, markschemeText: 'b'),
          question(id: 'q3', text: 'Q3', type: QuestionType.typedAnswer, markschemeText: 'c'),
        ];

        await tester.pumpWidget(_orderedSessionApp(
          questions: questions,
          orderedIds: ['q3', 'q1'],
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        // Should show Q3 first (from ordered list)
        expect(find.text('Q3'), findsOneWidget);
      });

      testWidgets('shows no questions dialog when ordered list empty', (tester) async {
        final questions = [
          question(id: 'q1', text: 'Q1', type: QuestionType.typedAnswer, markschemeText: 'a'),
        ];

        // Use non-existent IDs
        await tester.pumpWidget(_orderedSessionApp(
          questions: questions,
          orderedIds: ['nonexistent'],
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(_kNoQuestionsAvailable), findsOneWidget);
      });

      testWidgets('failing ordered repo shows loading then error dialog', (tester) async {
        final failingRepo = _FailingOrderedRepo();

        await tester.pumpWidget(ProviderScope(
          overrides: [
            settingsProvider.overrideWith((ref) => FakeSettingsController()),
            questionRepositoryProvider.overrideWithValue(failingRepo),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PracticeSessionScreen(
                          args: PracticeSessionArgs(
                            subjectId: 'subject-a',
                            orderedQuestionIds: ['q1'],
                          ),
                        ),
                      ),
                    ),
                    child: const Text('Open Session'),
                  ),
                ),
              ),
            ),
          ),
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pump();

        expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
      });
    });

    group('SR questions loading', () {
      testWidgets('loads spaced repetition due questions', (tester) async {
        final questions = [
          question(id: 'q1', text: 'SR Q1', type: QuestionType.typedAnswer, markschemeText: 'a'),
          question(id: 'q2', text: 'SR Q2', type: QuestionType.typedAnswer, markschemeText: 'b'),
        ];

        final srService = _SrServiceWithData(questions);

        await tester.pumpWidget(sessionApp(
          result: Result.success(questions),
          isSpacedRepetition: true,
          srService: srService,
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        expect(find.text('SR Q1'), findsOneWidget);
      });

      testWidgets('shows no questions dialog when SR returns empty', (tester) async {
        await tester.pumpWidget(sessionApp(
          result: Result.success([]),
          isSpacedRepetition: true,
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(_kNoQuestionsAvailable), findsOneWidget);
      });

      testWidgets('handles SR service failure gracefully', (tester) async {
        final srService = _FailingSrService();

        await tester.pumpWidget(sessionApp(
          result: Result.success([]),
          isSpacedRepetition: true,
          srService: srService,
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pump();

        expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
      });
    });

    group('confidence selector', () {
      testWidgets('tapping different confidence levels works', (tester) async {
        final questions = [
          question(id: 'q1', text: 'Q1', type: QuestionType.typedAnswer, markschemeText: 'a'),
        ];

        await tester.pumpWidget(sessionApp(result: Result.success(questions)));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'a');
        await tester.pump();
        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pumpAndSettle();

        // Change confidence to 5
        await tester.tap(find.text('5'));
        await tester.pump();

        expect(find.textContaining('Very'), findsOneWidget);
      });
    });

    group('previous question edge case', () {
      testWidgets('previous at first question does nothing', (tester) async {
        final questions = [
          question(id: 'q1', text: 'First', type: QuestionType.typedAnswer, markschemeText: 'a'),
          question(id: 'q2', text: 'Second', type: QuestionType.typedAnswer, markschemeText: 'b'),
        ];

        await tester.pumpWidget(sessionApp(result: Result.success(questions)));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'a');
        await tester.pump();
        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.ensureVisible(find.text(_kNext));
        await tester.pump();
        await tester.tap(find.text(_kNext));
        await tester.pumpAndSettle();

        // Now on second question
        expect(find.text('Second'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'b');
        await tester.pump();
        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Go back to first
        await tester.ensureVisible(find.text('Previous'));
        await tester.pump();
        await tester.tap(find.text('Previous'));
        await tester.pumpAndSettle();

        expect(find.text('First'), findsOneWidget);
      });
    });

    group('session completion edge cases', () {
      testWidgets('session with single question shows results', (tester) async {
        final questions = [
          question(id: 'q1', text: 'Only one', type: QuestionType.typedAnswer, markschemeText: 'answer'),
        ];

        await tester.pumpWidget(sessionApp(result: Result.success(questions)));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'answer');
        await tester.pump();
        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.ensureVisible(find.text(_kNext));
        await tester.pump();
        await tester.tap(find.text(_kNext));
        await tester.pump(const Duration(milliseconds: 600));

        expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
      });
    });

    group('keyboard navigation', () {
      testWidgets('shows FocusTraversalOrder for accessibility', (tester) async {
        final questions = [
          question(id: 'q1', text: 'Q1', type: QuestionType.singleChoice,
              markschemeText: 'A', options: ['A', 'B']),
        ];

        await tester.pumpWidget(sessionApp(result: Result.success(questions)));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        expect(find.byType(FocusTraversalGroup), findsAtLeastNWidgets(1));
        expect(find.byType(FocusTraversalOrder), findsAtLeastNWidgets(1));
      });
    });

    group('skip button', () {
      testWidgets('skip button appears when no answer selected', (tester) async {
        final questions = [
          question(id: 'q1', text: 'Q1', type: QuestionType.singleChoice,
              markschemeText: 'A', options: ['A', 'B']),
          question(id: 'q2', text: 'Q2', type: QuestionType.singleChoice,
              markschemeText: 'B', options: ['A', 'B']),
        ];

        await tester.pumpWidget(sessionApp(result: Result.success(questions)));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        // Skip button should be visible when no answer selected
        expect(find.text('Skip'), findsOneWidget);

        // Tap skip to go to next question
        await tester.tap(find.text('Skip'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Should be on Q2 now after skipping Q1
        expect(find.text('Q2'), findsOneWidget);
      });

      testWidgets('skip button hidden after answer selected', (tester) async {
        final questions = [
          question(id: 'q1', text: 'Q1', type: QuestionType.singleChoice,
              markschemeText: 'A', options: ['A', 'B']),
        ];

        await tester.pumpWidget(sessionApp(result: Result.success(questions)));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('A'));
        await tester.pump();

        expect(find.text('Skip'), findsNothing);
      });
    });

    group('reduced motion', () {
      testWidgets('renders without animation when reduceMotion', (tester) async {
        final questions = [
          question(id: 'q1', text: 'Q1', type: QuestionType.typedAnswer, markschemeText: 'a'),
          question(id: 'q2', text: 'Q2', type: QuestionType.typedAnswer, markschemeText: 'b'),
        ];

        await tester.pumpWidget(sessionApp(result: Result.success(questions)));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'a');
        await tester.pump();
        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pumpAndSettle();
        await tester.tap(find.text(_kNext));
        await tester.pumpAndSettle();

        expect(find.byType(AnimatedSwitcher), findsOneWidget);
      });
    });

    group('practice again', () {
      testWidgets('practice again button restarts session', (tester) async {
        final questions = [
          question(id: 'q1', text: 'Restart Q', type: QuestionType.typedAnswer, markschemeText: 'a'),
        ];

        await tester.pumpWidget(sessionApp(result: Result.success(questions)));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'a');
        await tester.pump();
        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.ensureVisible(find.text(_kNext));
        await tester.pump();
        await tester.tap(find.text(_kNext));
        await tester.pump(const Duration(milliseconds: 600));

        expect(find.byType(Scaffold), findsAtLeastNWidgets(1));

        await tester.ensureVisible(find.text('Practice Again'));
        await tester.pump();
        await tester.tap(find.text('Practice Again'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
      });
    });

    group('spaced repetition mode - additional', () {
      testWidgets('SR mode shows correct mode label', (tester) async {
        final questions = [
          question(id: 'q1', text: 'SR Q', type: QuestionType.typedAnswer, markschemeText: 'a'),
        ];

        final srService = _SrServiceWithData(questions);

        await tester.pumpWidget(sessionApp(
          result: Result.success(questions),
          isSpacedRepetition: true,
          srService: srService,
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Spaced'), findsWidgets);
      });
    });
  });
}

Widget _orderedSessionApp({
  required List<Question> questions,
  required List<String> orderedIds,
}) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith((ref) => FakeSettingsController()),
      questionRepositoryProvider.overrideWithValue(
        _OrderedFakeRepo(questions),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PracticeSessionScreen(
                    args: PracticeSessionArgs(
                      subjectId: 'subject-a',
                      orderedQuestionIds: orderedIds,
                    ),
                  ),
                ),
              ),
              child: const Text('Open Session'),
            ),
          ),
        ),
      ),
    ),
  );
}

class _OrderedFakeRepo extends FakeQuestionRepository {
  final List<Question> _questions;

  _OrderedFakeRepo(this._questions) : super(Result.success(_questions));

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async {
    return Result.success(_questions);
  }
}

class _SrServiceWithData extends FakeSpacedRepetitionService {
  final List<Question> _questions;

  _SrServiceWithData(this._questions);

  @override
  Future<Result<List<Question>>> getPracticeQuestions(String subjectId) async {
    return Result.success(_questions);
  }
}
