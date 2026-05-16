import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/lessons/providers/lesson_providers.dart';
import 'package:studyking/features/lessons/presentation/lesson_detail_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeLessonRepository extends LessonRepository {
  final List<Lesson> _lessons;
  bool shouldThrow = false;

  _FakeLessonRepository({List<Lesson>? lessons}) : _lessons = lessons ?? [];

  @override
  Future<Lesson?> get(String id) async {
    if (shouldThrow) throw Exception('Simulated DB error');
    return _lessons.where((l) => l.id == id).firstOrNull;
  }

  @override
  Future<List<Lesson>> getAll() async => _lessons;

  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> create(Lesson lesson) async => Result.success(null);
}

Widget _buildTestApp({
  required LessonDetailArgs args,
  List<Lesson>? lessons,
  bool shouldThrow = false,
}) {
  final repo = _FakeLessonRepository(lessons: lessons);
  repo.shouldThrow = shouldThrow;
  return ProviderScope(
    overrides: [
      lessonRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(
        builder: (context) => Scaffold(
          body: LessonDetailScreen(args: args),
        ),
      ),
      onGenerateRoute: (settings) {
        if (settings.name == '/tutor') {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Tutor')),
          );
        }
        return null;
      },
    ),
  );
}

void main() {
  group('LessonDetailScreen', () {
    testWidgets('shows loading indicator when lesson is null', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [],
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays lesson title in AppBar', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          Lesson(
            id: 'l1', subjectId: 's1', title: 'Introduction to Algebra',
            topicId: 't1', blocks: [], createdAt: now,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Introduction to Algebra'), findsOneWidget);
    });

    testWidgets('displays all blocks with correct icons and localized titles', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          Lesson(
            id: 'l1', subjectId: 's1', title: 'Algebra',
            topicId: 't1',
            blocks: [
              LessonBlock(id: 'b1', subjectId: 's1', lessonId: 'l1',
                  type: LessonBlockType.text, content: 'Text explanation', order: 0),
              LessonBlock(id: 'b2', subjectId: 's1', lessonId: 'l1',
                  type: LessonBlockType.example, content: 'Example content', order: 1),
              LessonBlock(id: 'b3', subjectId: 's1', lessonId: 'l1',
                  type: LessonBlockType.exercise, content: 'Exercise content', order: 2),
              LessonBlock(id: 'b4', subjectId: 's1', lessonId: 'l1',
                  type: LessonBlockType.slide, content: 'Slide content', order: 3),
              LessonBlock(id: 'b5', subjectId: 's1', lessonId: 'l1',
                  type: LessonBlockType.quiz, content: 'Quiz content', order: 4),
              LessonBlock(id: 'b6', subjectId: 's1', lessonId: 'l1',
                  type: LessonBlockType.summary, content: 'Summary content', order: 5),
            ],
            createdAt: now,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Text explanation'), findsOneWidget);
      expect(find.text('Example content'), findsOneWidget);
      expect(find.text('Exercise content'), findsOneWidget);

      expect(find.byIcon(Icons.description), findsOneWidget);
      expect(find.byIcon(Icons.play_circle), findsOneWidget);
      expect(find.byIcon(Icons.note_add), findsOneWidget);

      expect(find.text('Explanation'), findsOneWidget);
      expect(find.text('Example'), findsOneWidget);
      expect(find.text('Exercise'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Quiz content'), findsOneWidget);
      expect(find.text('Summary content'), findsOneWidget);
      expect(find.byIcon(Icons.question_answer), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Slide'), findsOneWidget);
    });

    testWidgets('displays timer starting at 0:00', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          Lesson(
            id: 'l1', subjectId: 's1', title: 'Algebra',
            topicId: 't1', blocks: [], createdAt: now,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('0:00'), findsOneWidget);
    });

    testWidgets('timer updates after one second', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          Lesson(
            id: 'l1', subjectId: 's1', title: 'Algebra',
            topicId: 't1', blocks: [], createdAt: now,
          ),
        ],
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('0:01'), findsOneWidget);
    });

    testWidgets('timer continues incrementing', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          Lesson(
            id: 'l1', subjectId: 's1', title: 'Algebra',
            topicId: 't1', blocks: [], createdAt: now,
          ),
        ],
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));

      expect(find.text('0:05'), findsOneWidget);
    });

    testWidgets('dispose cancels the timer', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          Lesson(
            id: 'l1', subjectId: 's1', title: 'Algebra',
            topicId: 't1', blocks: [], createdAt: now,
          ),
        ],
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('0:03'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));

      expect(find.text('0:03'), findsNothing);
    });

    testWidgets('shows teaching mode icon button in app bar', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          Lesson(
            id: 'l1', subjectId: 's1', title: 'Algebra',
            topicId: 't1', blocks: [], createdAt: now,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
    });

    testWidgets('shows timer and teaching mode button in bottom bar', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          Lesson(
            id: 'l1', subjectId: 's1', title: 'Algebra',
            topicId: 't1', blocks: [], createdAt: now,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(BottomAppBar), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
    });

    testWidgets('shows error snackbar with retry when load fails', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        shouldThrow: true,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('navigates to tutor screen from app bar teaching mode button', (tester) async {
      final now = DateTime.now();

      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          Lesson(
            id: 'l1', subjectId: 's1', title: 'Algebra',
            topicId: 't1', blocks: [], createdAt: now,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.smart_toy_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Tutor'), findsOneWidget);
    });

    testWidgets('navigates to tutor screen from bottom bar teaching mode button', (tester) async {
      final now = DateTime.now();

      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          Lesson(
            id: 'l1', subjectId: 's1', title: 'Algebra',
            topicId: 't1', blocks: [], createdAt: now,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.smart_toy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Tutor'), findsOneWidget);
    });
  });

  group('Keyboard accessibility', () {
    testWidgets('renders FocusTraversalGroup in body and bottom bar', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(lessonId: 'l1', topicId: 't1', topicTitle: 'Algebra'),
        lessons: [
          Lesson(
            id: 'l1', subjectId: 's1', title: 'Algebra',
            topicId: 't1', blocks: [], createdAt: now,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(FocusTraversalGroup), findsNWidgets(2));
    });

    testWidgets('interactive elements are present for keyboard focus', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(lessonId: 'l1', topicId: 't1', topicTitle: 'Algebra'),
        lessons: [
          Lesson(
            id: 'l1', subjectId: 's1', title: 'Algebra',
            topicId: 't1', blocks: [], createdAt: now,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}

