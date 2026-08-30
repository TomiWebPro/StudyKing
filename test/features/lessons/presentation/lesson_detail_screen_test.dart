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
import 'package:studyking/features/teaching/data/models/lesson_recap_model.dart';
import 'package:studyking/features/teaching/data/repositories/lesson_recap_repository.dart';
import 'package:studyking/features/teaching/services/lesson_recap_service.dart';
import 'package:studyking/features/teaching/providers/teaching_providers.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../../../helpers/navigator_observer_helper.dart';

class _StubLlmService extends LlmService {
  _StubLlmService()
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: '',
          ),
          httpClient: MockClient((request) async => http.Response('{}', 200)),
        );

  @override
  Future<Result<String>> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async =>
      Result.success('{}');

  @override
  Stream<String> chatStream({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async* {}
}

class _FakeLessonRecapService extends LessonRecapService {
  final LessonRecapModel? _recap;

  _FakeLessonRecapService(this._recap)
      : super(
          llmService: _StubLlmService(),
          modelId: 'model-1',
          repository: LessonRecapRepository(),
          localeName: 'en',
        );

  @override
  Future<Result<LessonRecapModel?>> getRecapForLesson(String lessonId) async =>
      Result.success(_recap);
}

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
  LessonRecapModel? recap,
  TestNavigatorObserver? navigatorObserver,
}) {
  final repo = _FakeLessonRepository(lessons: lessons);
  repo.shouldThrow = shouldThrow;
  return ProviderScope(
    overrides: [
      lessonRepositoryProvider.overrideWithValue(repo),
      lessonRecapServiceProvider.overrideWithValue(_FakeLessonRecapService(recap)),
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
  List<LessonBlock>? blocks,
}) {
  return Lesson(
    id: id,
    subjectId: subjectId,
    title: title,
    topicId: 't1',
    blocks: blocks ?? [
      LessonBlock(id: 'b1', subjectId: subjectId, lessonId: id,
          type: LessonBlockType.text, content: 'Content', order: 0),
    ],
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
      expect(find.byIcon(Icons.lightbulb), findsOneWidget);
      expect(find.byIcon(Icons.edit_note), findsOneWidget);

      expect(find.text('Explanation'), findsOneWidget);
      expect(find.text('Example'), findsOneWidget);
      expect(find.text('Exercise'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Quiz content'), findsOneWidget);
      expect(find.text('Summary content'), findsOneWidget);
      expect(find.byIcon(Icons.quiz), findsOneWidget);
      expect(find.byIcon(Icons.checklist), findsOneWidget);
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

    testWidgets('shows empty blocks state with generating message and refresh button', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [
          _createLesson(blocks: []),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
      expect(find.text('Generating...'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('empty blocks retry refreshes the lesson', (tester) async {
      final repo = _FakeLessonRepository(lessons: [
        _createLesson(id: 'l1', title: 'Initial', blocks: []),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lessonRepositoryProvider.overrideWithValue(repo),
            lessonRecapServiceProvider.overrideWithValue(_FakeLessonRecapService(null)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const Scaffold(
              body: LessonDetailScreen(
                args: LessonDetailArgs(
                  lessonId: 'l1', topicId: 't1', topicTitle: 'Algebra',
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
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Generating...'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Initial'), findsOneWidget);
      // Dispose to cancel periodic timer and avoid pending timer error
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('renders lesson recap card when a recap exists', (tester) async {
      final recap = LessonRecapModel(
        id: 'r1',
        sessionId: 's1',
        lessonId: 'l1',
        studentId: 'st',
        subjectId: 's1',
        topicId: 't1',
        topicTitle: 'Algebra',
        topicsCovered: ['linear equations'],
        struggles: ['fractions'],
        homework: ['practice set 3'],
        summary: 'We covered the basics of algebra step by step.',
        accuracy: 0.8,
        questionCount: 5,
        correctCount: 4,
        confidenceRating: 4,
        participationMessages: 12,
        generatedAt: DateTime(2026, 1, 1),
      );
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [_createLesson()],
        recap: recap,
      ));
      await tester.pumpAndSettle();

      expect(find.text('How the class went'), findsOneWidget);
      expect(find.text('Topics covered'), findsOneWidget);
      expect(find.text('linear equations'), findsOneWidget);
      expect(find.text('Struggles & misconceptions'), findsOneWidget);
      expect(find.text('fractions'), findsOneWidget);
      expect(find.text('Homework & practice'), findsOneWidget);
      expect(find.text('practice set 3'), findsOneWidget);
      expect(find.text('Accuracy'), findsOneWidget);
      expect(find.text('80.0%'), findsOneWidget);
    });

    testWidgets('does not render recap card when none exists', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(
          lessonId: 'l1',
          topicId: 't1',
          topicTitle: 'Algebra',
        ),
        lessons: [_createLesson()],
        recap: null,
      ));
      await tester.pumpAndSettle();

      expect(find.text('How the class went'), findsNothing);
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
            lessonRecapServiceProvider.overrideWithValue(_FakeLessonRecapService(null)),
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
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(lessonId: 'l1', topicId: 't1', topicTitle: 'Algebra'),
        lessons: [_createLesson()],
      ));
      await tester.pumpAndSettle();
      expect(find.text('00 00'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('00 01'), findsOneWidget);
      // Directly invoke PopScope's onPop to avoid Navigator.push harness hang
      final popScopes = tester.widgetList(find.byWidgetPredicate((w) => w is PopScope)).cast<PopScope>().toList();
      expect(popScopes, isNotEmpty);
      final target = popScopes.firstWhere((p) => p.canPop == false, orElse: () => popScopes.first);
      target.onPopInvokedWithResult?.call(false, null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('You have an active lesson timer. Leave anyway?'), findsOneWidget);
      expect(find.text('Leave anyway'), findsWidgets);
      expect(find.text('Cancel'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('PopScope dialog Leave anyway pops the route', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(lessonId: 'l1', topicId: 't1', topicTitle: 'Algebra'),
        lessons: [_createLesson()],
      ));
      await tester.pumpAndSettle();
      expect(find.text('00 00'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('00 01'), findsOneWidget);
      final popScopes = tester.widgetList(find.byWidgetPredicate((w) => w is PopScope)).cast<PopScope>().toList();
      expect(popScopes, isNotEmpty);
      final target = popScopes.firstWhere((p) => p.canPop == false, orElse: () => popScopes.first);
      target.onPopInvokedWithResult?.call(false, null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('You have an active lesson timer. Leave anyway?'), findsOneWidget);
      await tester.tap(find.text('Leave anyway').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('You have an active lesson timer. Leave anyway?'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('PopScope dialog Cancel dismisses the dialog', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        args: const LessonDetailArgs(lessonId: 'l1', topicId: 't1', topicTitle: 'Algebra'),
        lessons: [_createLesson()],
      ));
      await tester.pumpAndSettle();
      expect(find.text('00 00'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('00 01'), findsOneWidget);
      final popScopes = tester.widgetList(find.byWidgetPredicate((w) => w is PopScope)).cast<PopScope>().toList();
      expect(popScopes, isNotEmpty);
      final target = popScopes.firstWhere((p) => p.canPop == false, orElse: () => popScopes.first);
      target.onPopInvokedWithResult?.call(false, null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('You have an active lesson timer. Leave anyway?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('00'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('uses lesson subjectId when args.subjectId is empty', (tester) async {
      TutorArgs? capturedArgs;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lessonRepositoryProvider.overrideWithValue(_FakeLessonRepository(lessons: [
              _createLesson(subjectId: 'lesson-subject'),
            ])),
            lessonRecapServiceProvider.overrideWithValue(_FakeLessonRecapService(null)),
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
      expect(find.byType(FilledButton), findsAtLeastNWidgets(1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}
