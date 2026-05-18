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
import '../../../helpers/navigator_observer_helper.dart';

class _FakeLessonRepository extends LessonRepository {
  final List<Lesson> _lessons;
  bool shouldThrow = false;

  _FakeLessonRepository({List<Lesson>? lessons}) : _lessons = lessons ?? [];

  @override
  Future<Result<Lesson?>> get(String id) async {
    if (shouldThrow) throw Exception('Simulated DB error');
    return Result.success(_lessons.where((l) => l.id == id).firstOrNull);
  }

  @override
  Future<Result<List<Lesson>>> getAll() async => Result.success(_lessons);

  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> create(Lesson lesson) async => Result.success(null);
}

Widget _buildTestApp({
  required LessonDetailArgs args,
  List<Lesson>? lessons,
  bool shouldThrow = false,
  TestNavigatorObserver? navigatorObserver,
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
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      home: Builder(
        builder: (context) => Scaffold(
          body: LessonDetailScreen(args: args),
        ),
      ),
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.tutor) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('Tutor')),
          );
        }
        return null;
      },
    ),
  );
}

Lesson _createLesson({
  String id = 'l1',
  String subjectId = 's1',
  String title = 'Algebra',
  List<LessonBlock> blocks = const [],
}) {
  return Lesson(
    id: id,
    subjectId: subjectId,
    title: title,
    topicId: 't1',
    blocks: blocks,
    createdAt: DateTime.now(),
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
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          _createLesson(title: 'Introduction to Algebra'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Introduction to Algebra'), findsOneWidget);
    });

    testWidgets('displays all blocks with correct icons and localized titles', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          _createLesson(blocks: [
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
          ]),
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

    testWidgets('displays timer starting at 00 00', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          _createLesson(),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('00 00'), findsOneWidget);
    });

    testWidgets('timer updates after one second', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          _createLesson(),
        ],
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('00 01'), findsOneWidget);
    });

    testWidgets('timer continues incrementing', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          _createLesson(),
        ],
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));

      expect(find.text('00 05'), findsOneWidget);
    });

    testWidgets('dispose cancels the timer', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          _createLesson(),
        ],
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('00 03'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));

      expect(find.text('00 03'), findsNothing);
    });

    testWidgets('shows teaching mode icon button in app bar', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          _createLesson(),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
    });

    testWidgets('shows timer and teaching mode button in bottom bar', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          _createLesson(),
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
      expect(find.text('Retry'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows error screen with error icon and buttons when load fails', (tester) async {
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

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Failed to load lesson. Please check your connection and try again.'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
      expect(find.text('Retry'), findsAtLeastNWidgets(1));
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('Go Back on error screen navigates back', (tester) async {
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

      await tester.tap(find.text('Go Back'));
      await tester.pumpAndSettle();

      expect(find.text('Algebra'), findsNothing);
    });

    testWidgets('Retry on error screen reloads lesson', (tester) async {
      final repo = _FakeLessonRepository(lessons: [
        _createLesson(title: 'Retried Lesson'),
      ]);
      repo.shouldThrow = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lessonRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Builder(
              builder: (context) => const Scaffold(
                body: LessonDetailScreen(
                  args: LessonDetailArgs(
                    lessonId: 'l1',
                    topicId: 't1',
                    topicTitle: 'Algebra',
                  ),
                ),
              ),
            ),
            onGenerateRoute: (settings) {
              if (settings.name == AppRoutes.tutor) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const Scaffold(body: Text('Tutor')),
                );
              }
              return null;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      repo.shouldThrow = false;
      await tester.tap(find.text('Retry').first);
      await tester.pumpAndSettle();

      expect(find.text('Retried Lesson'), findsOneWidget);
    });

    testWidgets('navigates to tutor screen from app bar teaching mode button', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          _createLesson(),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.smart_toy_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Tutor'), findsOneWidget);
    });

    testWidgets('navigates to tutor screen from bottom bar teaching mode button', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          _createLesson(),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.smart_toy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Tutor'), findsOneWidget);
    });

    testWidgets('navigator pushes tutor route on teaching mode tap', (tester) async {
      final observer = TestNavigatorObserver();

      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          _createLesson(),
        ],
        navigatorObserver: observer,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.smart_toy_outlined));
      await tester.pumpAndSettle();

      expect(
        observer.pushedRoutes.any((r) => r.settings.name == '/tutor'),
        isTrue,
      );
    });

    testWidgets('navigator pops tutor on system back', (tester) async {
      final observer = TestNavigatorObserver();

      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          _createLesson(),
        ],
        navigatorObserver: observer,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.smart_toy_outlined));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(observer.poppedRoutes, hasLength(1));
    });

    testWidgets('shows PopScope confirmation dialog when timer is running on back', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lessonRepositoryProvider.overrideWithValue(
              _FakeLessonRepository(lessons: [_createLesson()]),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            initialRoute: '/home',
            routes: {
              '/home': (_) => const Scaffold(
                body: Center(child: Text('Home Screen')),
              ),
              '/detail': (_) => const LessonDetailScreen(
                args: LessonDetailArgs(
                  lessonId: 'l1', topicId: 't1', topicTitle: 'Algebra',
                ),
              ),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);

      await Navigator.of(tester.element(find.text('Home Screen'))).pushNamed('/detail');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('00 00'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Active Lesson Timer'), findsOneWidget);
      expect(find.text('Leave anyway'), findsWidgets);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('PopScope dialog Leave anyway pops the route', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lessonRepositoryProvider.overrideWithValue(
              _FakeLessonRepository(lessons: [_createLesson()]),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            initialRoute: '/home',
            routes: {
              '/home': (_) => const Scaffold(
                body: Center(child: Text('Home Screen')),
              ),
              '/detail': (_) => const LessonDetailScreen(
                args: LessonDetailArgs(
                  lessonId: 'l1', topicId: 't1', topicTitle: 'Algebra',
                ),
              ),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await Navigator.of(tester.element(find.text('Home Screen'))).pushNamed('/detail');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Active Lesson Timer'), findsOneWidget);

      await tester.tap(find.text('Leave anyway').last);
      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('PopScope dialog Cancel dismisses the dialog', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lessonRepositoryProvider.overrideWithValue(
              _FakeLessonRepository(lessons: [_createLesson()]),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            initialRoute: '/home',
            routes: {
              '/home': (_) => const Scaffold(
                body: Center(child: Text('Home Screen')),
              ),
              '/detail': (_) => const LessonDetailScreen(
                args: LessonDetailArgs(
                  lessonId: 'l1', topicId: 't1', topicTitle: 'Algebra',
                ),
              ),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await Navigator.of(tester.element(find.text('Home Screen'))).pushNamed('/detail');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Active Lesson Timer'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('00 00'), findsOneWidget);
    });

    testWidgets('uses lesson subjectId when args.subjectId is empty', (tester) async {
      TutorArgs? capturedArgs;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lessonRepositoryProvider.overrideWithValue(_FakeLessonRepository(lessons: [
              _createLesson(subjectId: 'lesson-subject'),
            ])),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Builder(
              builder: (context) => const Scaffold(
                body: LessonDetailScreen(
                  args: LessonDetailArgs(
                    lessonId: 'l1',
                    topicId: 't1',
                    topicTitle: 'Algebra',
                    subjectId: '',
                  ),
                ),
              ),
            ),
            onGenerateRoute: (settings) {
              if (settings.name == AppRoutes.tutor && settings.arguments is TutorArgs) {
                capturedArgs = settings.arguments as TutorArgs;
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const Scaffold(body: Text('Tutor')),
                );
              }
              return null;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.smart_toy_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(capturedArgs, isNotNull);
      expect(capturedArgs!.subjectId, 'lesson-subject');
    });
  });

  group('Keyboard accessibility', () {
    testWidgets('renders FocusTraversalGroup in body and bottom bar', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(lessonId: 'l1', topicId: 't1', topicTitle: 'Algebra'),
        lessons: [
          _createLesson(),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(FocusTraversalGroup), findsAtLeastNWidgets(2));
    });

    testWidgets('interactive elements are present for keyboard focus', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(lessonId: 'l1', topicId: 't1', topicTitle: 'Algebra'),
        lessons: [
          _createLesson(),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
