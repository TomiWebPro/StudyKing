import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/lessons/providers/lesson_providers.dart';
import 'package:studyking/features/lessons/presentation/lesson_list_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeLessonRepository extends LessonRepository {
  final List<Lesson> _lessons;
  bool shouldThrow = false;

  _FakeLessonRepository({List<Lesson>? lessons}) : _lessons = lessons ?? [];

  @override
  Future<List<Lesson>> getAll() async {
    if (shouldThrow) throw Exception('Simulated DB error');
    return _lessons;
  }

  @override
  Future<Lesson?> get(String id) async {
    if (shouldThrow) throw Exception('Simulated DB error');
    return _lessons.where((l) => l.id == id).firstOrNull;
  }

  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> create(Lesson lesson) async => Result.success(null);
}

class _FakeTutorSessionRepository extends TutorSessionRepository {
  final List<TutorSession> _sessions;

  _FakeTutorSessionRepository({List<TutorSession>? sessions})
      : _sessions = sessions ?? [];

  @override
  Future<List<TutorSession>> getStudentSessions(String studentId) async {
    return _sessions;
  }

  @override
  Future<void> init() async {}
}

Widget _buildTestApp({
  LessonListArgs args = const LessonListArgs(topicId: 't1', topicTitle: 'Algebra'),
  List<Lesson>? lessons,
  List<TutorSession>? sessions,
  bool shouldThrow = false,
}) {
  final lessonRepo = _FakeLessonRepository(lessons: lessons);
  lessonRepo.shouldThrow = shouldThrow;
  final tutorSessionRepo = _FakeTutorSessionRepository(sessions: sessions);

  return ProviderScope(
    overrides: [
      lessonRepositoryProvider.overrideWithValue(lessonRepo),
      tutorSessionRepositoryProvider.overrideWithValue(tutorSessionRepo),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(
        builder: (context) => Scaffold(
          body: LessonListScreen(args: args),
        ),
      ),
      onGenerateRoute: (settings) {
        if (settings.name == '/lesson-detail') {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Lesson Detail')),
          );
        }
        return null;
      },
    ),
  );
}

void main() {
  group('LessonListScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(_buildTestApp());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays lessons when loaded', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(_buildTestApp(lessons: [
        Lesson(
          id: 'l1', subjectId: 's1', title: 'Intro to Algebra',
          topicId: 't1', blocks: [
            LessonBlock(id: 'b1', subjectId: 's1', lessonId: 'l1',
                type: LessonBlockType.text, content: 'Content', order: 0),
          ],
          createdAt: now,
        ),
        Lesson(
          id: 'l2', subjectId: 's1', title: 'Equations',
          topicId: 't1', blocks: [],
          createdAt: now,
        ),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('Intro to Algebra'), findsOneWidget);
      expect(find.text('Equations'), findsOneWidget);
      expect(find.text('1 block'), findsOneWidget);
      expect(find.text('0 blocks'), findsOneWidget);
    });

    testWidgets('shows empty state with Start AI Tutoring button when no lessons', (tester) async {
      await tester.pumpWidget(_buildTestApp(lessons: []));
      await tester.pumpAndSettle();

      expect(find.text('No lessons - use Planner to generate!'), findsOneWidget);
      expect(find.text('Start AI Tutoring'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
    });

    testWidgets('displays book and play_arrow icons for lessons', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(_buildTestApp(lessons: [
        Lesson(
          id: 'l1', subjectId: 's1', title: 'Lesson 1',
          topicId: 't1', blocks: [],
          createdAt: now,
        ),
      ]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsAtLeastNWidgets(1));
    });

    testWidgets('shows completed status icon and chip for completed lessons', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(_buildTestApp(lessons: [
        Lesson(
          id: 'l1', subjectId: 's1', title: 'Lesson 1',
          topicId: 't1', blocks: [],
          createdAt: now,
        ),
      ], sessions: [
        TutorSession(
          id: 'ts1', studentId: 'test-student', subjectId: 's1',
          topicId: 'l1', topicTitle: 'Lesson 1',
          status: SessionStatus.completed,
          startTime: now, plannedDurationMinutes: 30,
          lessonPlanJson: '', questionsAsked: 0, questionsCorrect: 0,
          confidenceRating: 0,
        ),
      ]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('shows inProgress status icon and chip', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(_buildTestApp(lessons: [
        Lesson(
          id: 'l1', subjectId: 's1', title: 'Lesson 1',
          topicId: 't1', blocks: [],
          createdAt: now,
        ),
      ], sessions: [
        TutorSession(
          id: 'ts1', studentId: 'test-student', subjectId: 's1',
          topicId: 'l1', topicTitle: 'Lesson 1',
          status: SessionStatus.inProgress,
          startTime: now, plannedDurationMinutes: 30,
          lessonPlanJson: '', questionsAsked: 0, questionsCorrect: 0,
          confidenceRating: 0,
        ),
      ]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
    });

    testWidgets('shows AI Tutoring icon button in app bar when lessons exist', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(_buildTestApp(lessons: [
        Lesson(
          id: 'l1', subjectId: 's1', title: 'Lesson 1',
          topicId: 't1', blocks: [],
          createdAt: now,
        ),
      ]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
    });

    testWidgets('shows error snackbar with retry when load fails', (tester) async {
      await tester.pumpWidget(_buildTestApp(shouldThrow: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('navigates to lesson detail on lesson tap', (tester) async {
      final now = DateTime.now();

      await tester.pumpWidget(_buildTestApp(
        lessons: [
          Lesson(
            id: 'l1', subjectId: 's1', title: 'Lesson 1',
            topicId: 't1', blocks: [],
            createdAt: now,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lesson 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Lesson Detail'), findsOneWidget);
    });
  });
}

