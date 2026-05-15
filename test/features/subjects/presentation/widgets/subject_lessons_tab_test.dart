import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/subjects/presentation/widgets/subject_lessons_tab.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeLessonRepository extends LessonRepository {
  final List<Lesson> _lessons;
  final bool shouldThrow;

  _FakeLessonRepository(this._lessons, {this.shouldThrow = false});

  @override
  Future<List<Lesson>> getAll() async {
    if (shouldThrow) throw Exception('test error');
    return _lessons;
  }
}

class _TestNavigatorObserver extends NavigatorObserver {
  Route<dynamic>? pushedRoute;
  Route<dynamic>? poppedRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoute = route;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    poppedRoute = route;
  }
}

Lesson _lesson({
  required String id,
  required String subjectId,
  required String title,
  int blockCount = 0,
}) {
  return Lesson(
    id: id,
    subjectId: subjectId,
    title: title,
    topicId: 'topic-1',
    blocks: List.generate(
      blockCount,
      (i) => LessonBlock(
        id: 'block-$id-$i',
        subjectId: subjectId,
        lessonId: id,
        type: LessonBlockType.text,
        content: 'content-$i',
      ),
    ),
    createdAt: DateTime(2024, 1, 1),
  );
}

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('SubjectLessonsTab', () {
    const testSubjectId = 'subject-1';

    testWidgets('shows loading indicator initially', (tester) async {
      final repo = _FakeLessonRepository([]);
      await tester.pumpWidget(_buildTestApp(
        SubjectLessonsTab(
          subjectId: testSubjectId,
          lessonRepository: repo,
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no lessons', (tester) async {
      final repo = _FakeLessonRepository([]);
      await tester.pumpWidget(_buildTestApp(
        SubjectLessonsTab(
          subjectId: testSubjectId,
          lessonRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No lessons yet'), findsOneWidget);
      expect(find.text('Start learning by creating topics and questions'), findsOneWidget);
      expect(find.byIcon(Icons.book_outlined), findsOneWidget);
    });

    testWidgets('shows empty state when repository throws', (tester) async {
      final repo = _FakeLessonRepository([], shouldThrow: true);
      await tester.pumpWidget(_buildTestApp(
        SubjectLessonsTab(
          subjectId: testSubjectId,
          lessonRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No lessons yet'), findsOneWidget);
    });

    testWidgets('shows lesson card with title', (tester) async {
      final repo = _FakeLessonRepository([
        _lesson(id: 'l1', subjectId: testSubjectId, title: 'Algebra Basics'),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectLessonsTab(
          subjectId: testSubjectId,
          lessonRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Algebra Basics'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows blocks count in subtitle', (tester) async {
      final repo = _FakeLessonRepository([
        _lesson(id: 'l1', subjectId: testSubjectId, title: 'Algebra', blockCount: 3),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectLessonsTab(
          subjectId: testSubjectId,
          lessonRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('3 blocks'), findsOneWidget);
    });

    testWidgets('shows singular blocks count for single block', (tester) async {
      final repo = _FakeLessonRepository([
        _lesson(id: 'l1', subjectId: testSubjectId, title: 'Algebra', blockCount: 1),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectLessonsTab(
          subjectId: testSubjectId,
          lessonRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('1 block'), findsOneWidget);
    });

    testWidgets('shows book icon and chevron on lesson cards', (tester) async {
      final repo = _FakeLessonRepository([
        _lesson(id: 'l1', subjectId: testSubjectId, title: 'Algebra'),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectLessonsTab(
          subjectId: testSubjectId,
          lessonRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.book), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('renders multiple lessons', (tester) async {
      final repo = _FakeLessonRepository([
        _lesson(id: 'l1', subjectId: testSubjectId, title: 'Algebra'),
        _lesson(id: 'l2', subjectId: testSubjectId, title: 'Geometry'),
        _lesson(id: 'l3', subjectId: testSubjectId, title: 'Calculus'),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectLessonsTab(
          subjectId: testSubjectId,
          lessonRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('Geometry'), findsOneWidget);
      expect(find.text('Calculus'), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(3));
    });

    testWidgets('filters lessons by subjectId', (tester) async {
      final repo = _FakeLessonRepository([
        _lesson(id: 'l1', subjectId: testSubjectId, title: 'Correct Subject'),
        _lesson(id: 'l2', subjectId: 'other-subject', title: 'Wrong Subject'),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectLessonsTab(
          subjectId: testSubjectId,
          lessonRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Correct Subject'), findsOneWidget);
      expect(find.text('Wrong Subject'), findsNothing);
    });

    testWidgets('navigates to lesson detail on tap', (tester) async {
      final repo = _FakeLessonRepository([
        _lesson(id: 'l1', subjectId: testSubjectId, title: 'Algebra'),
      ]);

      final observer = _TestNavigatorObserver();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorObservers: [observer],
          onGenerateRoute: (settings) {
            if (settings.name == '/lesson-detail') {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Text('Lesson Detail Page')),
                settings: settings,
              );
            }
            return null;
          },
          home: Scaffold(
            body: SubjectLessonsTab(
              subjectId: testSubjectId,
              lessonRepository: repo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Algebra'));
      await tester.pumpAndSettle();

      expect(observer.pushedRoute, isNotNull);
      expect(observer.pushedRoute!.settings.name, '/lesson-detail');
    });

    testWidgets('does not show lessons from other subjects', (tester) async {
      final repo = _FakeLessonRepository([
        _lesson(id: 'l1', subjectId: 'other', title: 'Other Lesson'),
      ]);
      await tester.pumpWidget(_buildTestApp(
        SubjectLessonsTab(
          subjectId: testSubjectId,
          lessonRepository: repo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No lessons yet'), findsOneWidget);
    });
  });
}
