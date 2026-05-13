import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/lesson_block_model.dart';
import 'package:studyking/core/data/models/lesson_model.dart';
import 'package:studyking/core/data/models/personal_learning_plan_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/core/data/repositories/plan_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/topic_dependency_model.dart';
import 'package:studyking/core/data/models/tutor_session_model.dart';
import 'package:studyking/core/data/repositories/lesson_repository.dart';
import 'package:studyking/core/data/repositories/tutor_session_repository.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/lessons/presentation/lesson_list_screen.dart';
import 'package:studyking/features/planner/presentation/planner_screen.dart';
import 'package:studyking/features/quickguide/presentation/quick_guide_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'dart:async';

class _IntegrationFakePlanRepository extends PlanRepository {
  final Map<String, PersonalLearningPlan> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> savePlan(PersonalLearningPlan plan) async {
    _storage[plan.studentId] = plan;
  }

  @override
  Future<PersonalLearningPlan?> loadPlan(String studentId) async {
    return _storage[studentId];
  }

  @override
  Future<bool> hasPlan(String studentId) async {
    return _storage.containsKey(studentId);
  }

  @override
  Future<List<PersonalLearningPlan>> getAllPlans() async {
    return _storage.values.toList();
  }

  @override
  Future<void> deletePlan(String studentId) async {
    _storage.remove(studentId);
  }
}

class _IntegrationFakeMasteryGraphRepository extends MasteryGraphRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<List<MasteryState>>> getAllMasteryStates(String studentId) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<TopicDependency>>> getAllDependencies() async {
    return Result.success([]);
  }

  @override
  Future<Result<MasteryState>> getMasteryState(String studentId, String topicId) async {
    return Result.success(MasteryState.initial(studentId: studentId, topicId: topicId));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _IntegrationFakeTopicRepository extends TopicRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Topic?> get(String id) async => null;

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
    ConversationMemory? memory,
    List<Map<String, String>>? history,
  }) async* {
    yield 'This is an integration test response about ${message.split(" ").last}.';
  }
}

void main() {
  group('Integration - QuickGuide end-to-end', () {
    testWidgets('quick guide: send message and receive response', (tester) async {
      final llm = _IntegrationFakeLlmService();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: QuickGuideScreen(llmService: llm, showModeNavigation: false),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Explain integration testing');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Explain integration testing'), findsOneWidget);
      expect(find.textContaining('integration test response'), findsOneWidget);
    });

    testWidgets('quick guide: help dialog flow', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const QuickGuideScreen(showModeNavigation: false),
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
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: QuickGuideScreen(llmService: llm, showModeNavigation: false),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
    });
  });

  group('Integration - Planner end-to-end', () {
    testWidgets('planner: generate plan with valid data', (tester) async {
      final planRepo = _IntegrationFakePlanRepository();
      final masteryRepo = _IntegrationFakeMasteryGraphRepository();

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: PlannerScreen(
          planRepository: planRepo,
          masteryGraphRepository: masteryRepo,
          topicRepository: _IntegrationFakeTopicRepository(),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Physics');
      await tester.enterText(find.byType(TextField).at(1), '30');
      await tester.enterText(find.byType(TextField).at(2), '2');
      await tester.pump();

      await tester.tap(find.text('Generate Plan'));
      await tester.pumpAndSettle();

      expect(find.text('Your Study Schedule'), findsOneWidget);
      expect(find.text('Plan Summary'), findsOneWidget);
    });

    testWidgets('planner: shows error when generation fails', (tester) async {
      final masteryRepo = _IntegrationFakeMasteryGraphRepository();

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: PlannerScreen(
          planRepository: _IntegrationFakePlanRepository(),
          masteryGraphRepository: masteryRepo,
          topicRepository: _IntegrationFakeTopicRepository(),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Physics');
      await tester.enterText(find.byType(TextField).at(1), '30');
      await tester.enterText(find.byType(TextField).at(2), '2');
      await tester.pump();

      await tester.tap(find.text('Generate Plan'));
      await tester.pumpAndSettle();

      expect(find.text('Your Study Schedule'), findsOneWidget);
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
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: LessonListScreen(
          topicId: 't1',
          topicTitle: 'Test Topic',
          lessonRepository: _FakeLessonRepository(lessons: [
            Lesson(
              id: 'l1', subjectId: 's1', title: 'Integration Lesson',
              topicId: 't1',
              blocks: [
                LessonBlock(id: 'b1', subjectId: 's1', lessonId: 'l1',
                    type: LessonBlockType.text, content: 'Integration content', order: 0),
              ],
              createdAt: now,
            ),
          ]),
          tutorSessionRepository: _FakeTutorSessionRepo(),
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
  Future<List<Lesson>> getAll() async => _lessons;

  @override
  Future<Lesson?> get(String id) async => _lessons.where((l) => l.id == id).firstOrNull;

  @override
  Future<void> init() async {}
}

class _FakeTutorSessionRepo extends TutorSessionRepository {
  @override
  Future<List<TutorSession>> getStudentSessions(String studentId) async => [];

  @override
  Future<void> init() async {}
}
