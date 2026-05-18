import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/lessons/providers/lesson_providers.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/features/lessons/presentation/lesson_list_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/services/student_id_service.dart' show studentIdValueProvider;
import '../../../helpers/navigator_observer_helper.dart';

class _FakeLessonRepository extends LessonRepository {
  final List<Lesson> _lessons;
  bool shouldThrow = false;

  _FakeLessonRepository({List<Lesson>? lessons}) : _lessons = lessons ?? [];

  @override
  Future<Result<List<Lesson>>> getAll() async {
    if (shouldThrow) throw Exception('Simulated DB error');
    return Result.success(_lessons);
  }

  @override
  Future<Result<Lesson?>> get(String id) async {
    if (shouldThrow) throw Exception('Simulated DB error');
    return Result.success(_lessons.where((l) => l.id == id).firstOrNull);
  }

  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> create(Lesson lesson) async => Result.success(null);
}

class _FakeSessionRepository extends SessionRepository {
  final List<Session> _sessions;

  _FakeSessionRepository({List<Session>? sessions}) : _sessions = sessions ?? [];

  @override
  Future<Result<List<Session>>> getByStudent(String studentId) async {
    return Result.success(_sessions);
  }

  @override
  Future<Result<List<Session>>> getAll() async => Result.success(_sessions);

  @override
  Future<void> init() async {}
}

Widget _buildTestApp({
  LessonListArgs args = const LessonListArgs(topicId: 't1', topicTitle: 'Algebra'),
  List<Lesson>? lessons,
  List<Session>? sessions,
  bool shouldThrow = false,
  TestNavigatorObserver? navigatorObserver,
}) {
  final lessonRepo = _FakeLessonRepository(lessons: lessons);
  lessonRepo.shouldThrow = shouldThrow;
  final sessionRepo = _FakeSessionRepository(sessions: sessions);

  return ProviderScope(
    overrides: [
      lessonRepositoryProvider.overrideWithValue(lessonRepo),
      sessionRepositoryProvider.overrideWithValue(sessionRepo),
      studentIdValueProvider.overrideWith((ref) => 'test-student'),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      home: Builder(
        builder: (context) => Scaffold(
          body: LessonListScreen(args: args),
        ),
      ),
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.lessonDetail) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('Lesson Detail')),
          );
        }
        if (settings.name == AppRoutes.tutor) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('Tutor Screen')),
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
      expect(find.text('1 block').first, findsOneWidget);
      expect(find.text('0 blocks').first, findsOneWidget);
    });

    testWidgets('shows empty state with Start AI Tutoring button when no lessons', (tester) async {
      await tester.pumpWidget(_buildTestApp(lessons: []));
      await tester.pumpAndSettle();

      expect(find.text('No lessons - use Planner to generate!'), findsOneWidget);
      expect(find.text('Start AI Tutoring'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
    });

    testWidgets('empty state Start AI Tutoring navigates to tutor', (tester) async {
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(_buildTestApp(
        lessons: [],
        navigatorObserver: observer,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start AI Tutoring'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Tutor Screen'), findsOneWidget);
      expect(
        observer.pushedRoutes.any((r) => r.settings.name == '/tutor'),
        isTrue,
      );
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
        Session(
          id: 's1',
          studentId: 'test-student',
          subjectId: 's1',
          topicId: 'l1',
          type: SessionType.tutoring,
          startTime: now,
          endTime: now.add(const Duration(minutes: 30)),
          completed: true,
          status: SessionStatus.completed,
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
        Session(
          id: 's1',
          studentId: 'test-student',
          subjectId: 's1',
          topicId: 'l1',
          type: SessionType.tutoring,
          startTime: now,
          endTime: null,
          completed: false,
          status: SessionStatus.inProgress,
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

    testWidgets('AI Tutoring app bar icon navigates to tutor', (tester) async {
      final observer = TestNavigatorObserver();
      final now = DateTime.now();
      await tester.pumpWidget(_buildTestApp(
        lessons: [
          Lesson(
            id: 'l1', subjectId: 's1', title: 'Lesson 1',
            topicId: 't1', blocks: [],
            createdAt: now,
          ),
        ],
        navigatorObserver: observer,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.smart_toy_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Tutor Screen'), findsOneWidget);
      expect(
        observer.pushedRoutes.any((r) => r.settings.name == '/tutor'),
        isTrue,
      );
    });

    testWidgets('shows error snackbar with retry when load fails', (tester) async {
      await tester.pumpWidget(_buildTestApp(shouldThrow: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry callback shows snackbar and retries load', (tester) async {
      final now = DateTime.now();
      final repo = _FakeLessonRepository(lessons: [
        Lesson(
          id: 'l1', subjectId: 's1', title: 'Lesson 1',
          topicId: 't1', blocks: [], createdAt: now,
        ),
      ]);
      repo.shouldThrow = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lessonRepositoryProvider.overrideWithValue(repo),
            sessionRepositoryProvider.overrideWithValue(
              _FakeSessionRepository(sessions: [
                Session(
                  id: 's1', studentId: 'test-student', subjectId: 's1',
                  topicId: 'l1', type: SessionType.tutoring,
                  startTime: now, completed: true,
                  status: SessionStatus.completed,
                ),
              ]),
            ),
            studentIdValueProvider.overrideWith((ref) => 'test-student'),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Builder(
              builder: (context) => const Scaffold(
                body: LessonListScreen(
                  args: LessonListArgs(topicId: 't1', topicTitle: 'Algebra'),
                ),
              ),
            ),
            onGenerateRoute: (settings) {
              if (settings.name == AppRoutes.lessonDetail) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const Scaffold(body: Text('Lesson Detail')),
                );
              }
              if (settings.name == AppRoutes.tutor) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const Scaffold(body: Text('Tutor Screen')),
                );
              }
              return null;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SnackBar), findsOneWidget);

      repo.shouldThrow = false;
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Lesson 1'), findsOneWidget);
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

    testWidgets('navigator pushes lesson detail on lesson tap', (tester) async {
      final observer = TestNavigatorObserver();
      final now = DateTime.now();

      await tester.pumpWidget(_buildTestApp(
        lessons: [
          Lesson(
            id: 'l1', subjectId: 's1', title: 'Lesson 1',
            topicId: 't1', blocks: [],
            createdAt: now,
          ),
        ],
        navigatorObserver: observer,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lesson 1'));
      await tester.pumpAndSettle();

      expect(
        observer.pushedRoutes.any((r) => r.settings.name == '/lesson-detail'),
        isTrue,
      );
    });

    testWidgets('navigator pops lesson detail on system back', (tester) async {
      final observer = TestNavigatorObserver();
      final now = DateTime.now();

      await tester.pumpWidget(_buildTestApp(
        lessons: [
          Lesson(
            id: 'l1', subjectId: 's1', title: 'Lesson 1',
            topicId: 't1', blocks: [],
            createdAt: now,
          ),
        ],
        navigatorObserver: observer,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lesson 1'));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(observer.poppedRoutes, hasLength(1));
    });
  });

  group('Keyboard accessibility', () {
    testWidgets('renders FocusTraversalGroup for keyboard navigation', (tester) async {
      await tester.pumpWidget(_buildTestApp(lessons: []));
      await tester.pumpAndSettle();

      expect(find.byType(FocusTraversalGroup), findsAtLeastNWidgets(1));
    });

    testWidgets('focus traversal order exists on key elements', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(_buildTestApp(lessons: [
        Lesson(
          id: 'l1', subjectId: 's1', title: 'Lesson 1',
          topicId: 't1', blocks: [], createdAt: now,
        ),
      ]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
