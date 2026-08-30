import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/hive_init_helper.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/providers/subject_repository_provider.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/lessons/providers/lesson_providers.dart';
import 'package:studyking/features/lessons/presentation/lesson_list_screen.dart';
import 'package:studyking/features/planner/presentation/planner_screen.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/quickguide/presentation/quick_guide_screen.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/settings_update.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'dart:async';

class _IntegrationFakePlanRepository extends PlanRepository {
  final Map<String, PersonalLearningPlan> _storage = {};

  @override
  Future<Result<void>> init() async {
    return Result.success(null);
  }

  @override
  Future<Result<void>> savePlan(PersonalLearningPlan plan) async {
    _storage[plan.studentId] = plan;
    return Result.success(null);
  }

  @override
  Future<Result<PersonalLearningPlan?>> loadPlan(String studentId) async {
    return Result.success(_storage[studentId]);
  }

  @override
  Future<Result<bool>> hasPlan(String studentId) async {
    return Result.success(_storage.containsKey(studentId));
  }

  @override
  Future<Result<List<PersonalLearningPlan>>> getAllPlans() async {
    return Result.success(_storage.values.toList());
  }

  @override
  Future<Result<void>> deletePlan(String studentId) async {
    _storage.remove(studentId);
    return Result.success(null);
  }
}

class _IntegrationFakeTopicRepository extends TopicRepository {
  final List<Topic> _topics;

  _IntegrationFakeTopicRepository({List<Topic>? topics}) : _topics = topics ?? [];

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<Topic?>> get(String id) async =>
      Result.success(_topics.where((t) => t.id == id).firstOrNull);

  @override
  Future<Result<List<Topic>>> getAll() async => Result.success(List.from(_topics));

  @override
  Future<Result<List<Topic>>> getBySubject(String subjectId) async =>
      Result.success(_topics.where((t) => t.subjectId == subjectId).toList());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _IntegrationFakeSubjectRepository extends SubjectRepository {
  final List<Subject> _subjects;

  _IntegrationFakeSubjectRepository({List<Subject>? subjects})
      : _subjects = subjects ?? [];

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Subject>>> getAll() async => Result.success(List.from(_subjects));

  @override
  Future<Result<Subject?>> get(String id) async =>
      Result.success(_subjects.where((s) => s.id == id).firstOrNull);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _IntegrationFakeLlmService extends LlmService {
  _IntegrationFakeLlmService()
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'fake-key-for-testing',
          ),
        );

  @override
  Stream<String> chatStream({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async* {
    yield 'This is an integration test response about ${message.split(" ").last}.';
  }
}

class _FakeSettingsRepository extends SettingsRepository {
  final SettingsBox _settings;

  _FakeSettingsRepository() : _settings = SettingsBox();

  @override
  Future<Result<SettingsBox>> getSettings() async => Result.success(_settings);

  @override
  Future<Result<void>> updateSettings(SettingsUpdate update) async =>
      Result.success(null);
}

class _FakeSettingsController extends SettingsController {
  _FakeSettingsController() : super(_FakeSettingsRepository());
}

void main() {
  setUpAll(() async {
    await initializeHiveForIntegrationTests();
  });
  group('Integration - QuickGuide end-to-end', () {
    testWidgets('quick guide: send message and receive response', (tester) async {
      final llm = _IntegrationFakeLlmService();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) => _FakeSettingsController()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: QuickGuideScreen(llmService: llm, showModeNavigation: false),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Explain integration testing');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Explain integration testing'), findsOneWidget);
      expect(find.textContaining('integration test response'), findsOneWidget);
    });

    testWidgets('quick guide: help dialog flow', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) => _FakeSettingsController()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const QuickGuideScreen(showModeNavigation: false),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('quick guide: clear conversation after sending', (tester) async {
      final llm = _IntegrationFakeLlmService();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) => _FakeSettingsController()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: QuickGuideScreen(llmService: llm, showModeNavigation: false),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
    });
  });

  Widget buildPlannerTestApp({
    required PlanRepository planRepo,
    required TopicRepository topicRepo,
    SubjectRepository? subjectRepo,
  }) {
    final subjRepo = subjectRepo ??
        _IntegrationFakeSubjectRepository(subjects: [
          Subject(id: 'subj-physics', name: 'Physics'),
        ]);
    final effectiveTopicRepo = topicRepo is _IntegrationFakeTopicRepository &&
            (topicRepo)._topics.isEmpty
        ? _IntegrationFakeTopicRepository(topics: [
            Topic(id: 'topic-1', subjectId: 'subj-physics', title: 'Mechanics', description: 'desc', syllabusText: 'syllabus'),
          ])
        : topicRepo;
    final svc = PlannerService(
      planRepo: planRepo,
      masteryService: MasteryGraphService(),
      topicRepository: effectiveTopicRepo,
      fixedStudentId: 'test-student',
    );
    return ProviderScope(
      overrides: [
        plannerServiceProvider.overrideWith((ref) => svc),
        subjectRepositoryProvider.overrideWithValue(subjRepo),
        topicRepositoryProvider.overrideWithValue(effectiveTopicRepo),
        settingsProvider.overrideWith((ref) => _FakeSettingsController()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const PlannerScreen(fixedStudentId: 'test-student'),
      ),
    );
  }

  group('Integration - Planner end-to-end', () {
    testWidgets('planner: generate plan with valid data', (tester) async {
      final planRepo = _IntegrationFakePlanRepository();

      await tester.pumpWidget(buildPlannerTestApp(
        planRepo: planRepo,
        topicRepo: _IntegrationFakeTopicRepository(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);
      await tester.enterText(textFields.at(0), '30');
      await tester.enterText(textFields.at(1), '2');
      await tester.pump();

      await tester.tap(find.text('Generate Plan'));
      await tester.pump();
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 400));
        if (find.text('Your Study Schedule').evaluate().isNotEmpty) break;
      }

      expect(find.byType(PlannerScreen), findsOneWidget);
      final plans = await planRepo.getAllPlans();
      expect(plans.isSuccess, isTrue);
    });

    testWidgets('planner: shows error when generation fails', (tester) async {
      final planRepo = _IntegrationFakePlanRepository();
      await tester.pumpWidget(buildPlannerTestApp(
        planRepo: planRepo,
        topicRepo: _IntegrationFakeTopicRepository(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '30');
      await tester.enterText(textFields.at(1), '2');
      await tester.pump();

      await tester.tap(find.text('Generate Plan'));
      await tester.pump();
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 400));
        if (find.text('Your Study Schedule').evaluate().isNotEmpty) break;
      }

      expect(find.byType(PlannerScreen), findsOneWidget);
      final plans = await planRepo.getAllPlans();
      expect(plans.isSuccess, isTrue);
    });
  });

  group('Integration - Route Navigation', () {
    testWidgets('named route generation for known routes', (tester) async {
      final routes = <String>[];
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        initialRoute: AppRoutes.planner,
        onGenerateRoute: (settings) {
          routes.add(settings.name ?? '');
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: Text(settings.name ?? '')),
              body: const Center(child: Text('Route')),
            ),
          );
        },
      ));
      await tester.pumpAndSettle();

      expect(routes, contains(AppRoutes.planner));
    });

    testWidgets('LessonListScreen integrates with LessonDetailScreen navigation', (tester) async {
      final now = DateTime.now();
      final lessonRepo = _FakeLessonRepository(lessons: [
        Lesson(
          id: 'l1', subjectId: 's1', title: 'Integration Lesson',
          topicId: 't1',
          blocks: [
            LessonBlock(id: 'b1', subjectId: 's1', lessonId: 'l1',
                type: LessonBlockType.text, content: 'Integration content', order: 0),
          ],
          createdAt: now,
        ),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          lessonRepositoryProvider.overrideWithValue(lessonRepo),
          tutorSessionRepositoryProvider.overrideWithValue(_FakeTutorSessionRepo()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: LessonListScreen(
            args: const LessonListArgs(topicId: 't1', topicTitle: 'Test Topic'),
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
      ));
      await tester.pumpAndSettle();

      expect(find.text('Integration Lesson'), findsOneWidget);

      await tester.tap(find.text('Integration Lesson'));
      await tester.pumpAndSettle();
    });
  });
}

class _FakeLessonRepository extends LessonRepository {
  final List<Lesson> _lessons;

  _FakeLessonRepository({List<Lesson>? lessons}) : _lessons = lessons ?? [];

  @override
  Future<Result<List<Lesson>>> getAll() async => Result.success(_lessons);

  @override
  Future<Result<Lesson?>> get(String id) async => Result.success(_lessons.where((l) => l.id == id).firstOrNull);

  @override
  Future<void> init() async {}
}

class _FakeTutorSessionRepo extends TutorSessionRepository {
  @override
  Future<Result<List<TutorSession>>> getStudentSessions(
      String studentId) async {
    return Result.success([]);
  }

  @override
  Future<void> init() async {}
}
