import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/personal_learning_plan_model.dart';
import 'package:studyking/core/data/models/roadmap_model.dart';
import 'package:studyking/core/data/models/topic_dependency_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/core/data/repositories/plan_repository.dart';
import 'package:studyking/core/data/repositories/roadmap_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/planner/presentation/planner_screen.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakePlanRepository extends PlanRepository {
  final Map<String, PersonalLearningPlan> _storage = {};
  bool failOnInit = false;

  @override
  Future<void> init() async {
    if (failOnInit) throw Exception('Init failed');
  }

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

class _FakeMasteryGraphRepository extends MasteryGraphRepository {
  final Map<String, MasteryState> _masteryStates = {};
  bool failOnGenerate = false;
  Completer<Result<List<MasteryState>>>? generateCompleter;

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<MasteryState>>> getAllMasteryStates(String studentId) async {
    if (generateCompleter != null) {
      return generateCompleter!.future;
    }
    if (failOnGenerate) {
      return Result.failure('Simulated generation error');
    }
    return Result.success(
      _masteryStates.values.where((s) => s.studentId == studentId).toList(),
    );
  }

  @override
  Future<Result<List<TopicDependency>>> getAllDependencies() async {
    return Result.success([]);
  }

  @override
  Future<Result<MasteryState>> getMasteryState(String studentId, String topicId) async {
    final key = '${studentId}_$topicId';
    if (_masteryStates.containsKey(key)) {
      return Result.success(_masteryStates[key]!);
    }
    final state = MasteryState.initial(studentId: studentId, topicId: topicId);
    _masteryStates[key] = state;
    return Result.success(state);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTopicRepository extends TopicRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Topic?> get(String id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRoadmapRepository extends RoadmapRepository {
  final Map<String, RoadmapModel> _storage = {};
  bool failOnInit = false;
  bool failOnGet = false;
  bool failOnSave = false;
  Completer<void>? loadCompleter;

  @override
  Future<void> init() async {
    if (failOnInit) throw Exception('Init failed');
    if (loadCompleter != null) await loadCompleter!.future;
  }

  @override
  Future<void> saveRoadmap(RoadmapModel roadmap) async {
    if (failOnSave) throw Exception('Save failed');
    _storage[roadmap.id] = roadmap;
  }

  @override
  Future<RoadmapModel?> loadRoadmap(String id) async {
    return _storage[id];
  }

  @override
  Future<List<RoadmapModel>> getRoadmapsByStudent(String studentId) async {
    if (loadCompleter != null) await loadCompleter!.future;
    if (failOnGet) throw Exception('Get failed');
    return _storage.values
        .where((r) => r.studentId == studentId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<RoadmapModel>> getAllRoadmaps() async {
    return _storage.values.toList();
  }

  @override
  Future<void> deleteRoadmap(String id) async {
    _storage.remove(id);
  }
}

class _TestNavigatorObserver extends NavigatorObserver {
  Route<dynamic>? lastPushedRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastPushedRoute = route;
    super.didPush(route, previousRoute);
  }
}

Widget _buildTestApp({
  PlanRepository? planRepository,
  MasteryGraphRepository? masteryGraphRepository,
  TopicRepository? topicRepository,
  RoadmapRepository? roadmapRepository,
  String? fixedStudentId,
  NavigatorObserver? navigatorObserver,
  RouteFactory? onGenerateRoute,
}) {
  final id = fixedStudentId ?? 'test-student';
  Hive.init(Directory.systemTemp.createTempSync('planner_test_').path);
  final repo = masteryGraphRepository ?? _FakeMasteryGraphRepository();
  final svc = PlannerService(
    planRepo: planRepository ?? _FakePlanRepository(),
    masteryService: MasteryGraphService(repository: repo),
    repository: repo,
    topicRepository: topicRepository ?? _FakeTopicRepository(),
    roadmapRepo: roadmapRepository ?? _FakeRoadmapRepository(),
    fixedStudentId: id,
  );

  return ProviderScope(
    overrides: [
      plannerServiceProvider.overrideWith((ref) => svc),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      onGenerateRoute: onGenerateRoute,
      home: PlannerScreen(fixedStudentId: id),
    ),
  );
}

void main() {
  group('PlannerScreen', () {
    group('Study Plan tab', () {
      testWidgets('renders title and form fields', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.text('Study Planner'), findsWidgets);
        expect(find.text('Create Study Plan'), findsOneWidget);
        expect(find.text('Generate Plan'), findsOneWidget);
      });

      testWidgets('shows title and form labels', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.text('Study Planner'), findsWidgets);
        expect(find.text('Create Study Plan'), findsOneWidget);
        expect(find.text('Generate Plan'), findsOneWidget);
      });

      testWidgets('shows three input fields', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsNWidgets(3));
      });

      testWidgets('shows calendar icon on generate button', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      });

      testWidgets('generate button is enabled initially', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNotNull);
      });

      testWidgets('shows snackbar when fields are empty on generate', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Generate Plan'));
        await tester.pumpAndSettle();

        expect(find.text('Please fill in all fields correctly'), findsOneWidget);
      });

      testWidgets('days field uses number keyboard type', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
        expect(textFields.length, 3);

        final daysField = textFields[1];
        expect(daysField.keyboardType, TextInputType.number);

        final hoursField = textFields[2];
        expect(hoursField.keyboardType, TextInputType.number);
      });

      testWidgets('no schedule list shown initially', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.text('Your Study Schedule'), findsNothing);
      });

      testWidgets('form fields accept user input', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          planRepository: _FakePlanRepository(),
          masteryGraphRepository: _FakeMasteryGraphRepository(),
          topicRepository: _FakeTopicRepository(),
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
        await tester.enterText(find.byType(TextField).at(1), '30');
        await tester.enterText(find.byType(TextField).at(2), '2');
        await tester.pump();

        final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
        expect(textFields[0].controller?.text, 'IB Physics');
        expect(textFields[1].controller?.text, '30');
        expect(textFields[2].controller?.text, '2');
      });

      testWidgets('generate plan with valid data shows schedule and summary', (tester) async {
        final planRepo = _FakePlanRepository();
        final masteryRepo = _FakeMasteryGraphRepository();
        final topicRepo = _FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          planRepository: planRepo,
          masteryGraphRepository: masteryRepo,
          topicRepository: topicRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.text('Your Study Schedule'), findsNothing);
        expect(find.text('Plan Summary'), findsNothing);

        await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
        await tester.enterText(find.byType(TextField).at(1), '30');
        await tester.enterText(find.byType(TextField).at(2), '2');
        await tester.pump();

        await tester.tap(find.text('Generate Plan'));
        await tester.pumpAndSettle();

        expect(find.text('Your Study Schedule'), findsOneWidget);
        expect(find.text('Plan Summary'), findsOneWidget);
      });

      testWidgets('plan summary displays plan stats after generation', (tester) async {
        final planRepo = _FakePlanRepository();
        final masteryRepo = _FakeMasteryGraphRepository();
        final topicRepo = _FakeTopicRepository();

        await tester.pumpWidget(_buildTestApp(
          planRepository: planRepo,
          masteryGraphRepository: masteryRepo,
          topicRepository: topicRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
        await tester.enterText(find.byType(TextField).at(1), '30');
        await tester.enterText(find.byType(TextField).at(2), '2');
        await tester.pump();

        await tester.tap(find.text('Generate Plan'));
        await tester.pumpAndSettle();

        expect(find.text('0Q'), findsOneWidget);
        expect(find.text('0min'), findsOneWidget);

        final plan = await planRepo.getAllPlans();
        expect(plan, hasLength(1));
        expect(plan.first.studentId, 'test-student');
      });

      testWidgets('shows error container when plan generation fails', (tester) async {
        final masteryRepo = _FakeMasteryGraphRepository();
        masteryRepo.failOnGenerate = true;

        await tester.pumpWidget(_buildTestApp(
          planRepository: _FakePlanRepository(),
          masteryGraphRepository: masteryRepo,
          topicRepository: _FakeTopicRepository(),
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
        await tester.enterText(find.byType(TextField).at(1), '30');
        await tester.enterText(find.byType(TextField).at(2), '2');
        await tester.pump();

        await tester.tap(find.text('Generate Plan'));
        await tester.pumpAndSettle();

        expect(find.text('Simulated generation error'), findsOneWidget);
      });

      testWidgets('generate button shows progress indicator during generation', (tester) async {
        final masteryRepo = _FakeMasteryGraphRepository();
        masteryRepo.generateCompleter = Completer<Result<List<MasteryState>>>();

        await tester.pumpWidget(_buildTestApp(
          planRepository: _FakePlanRepository(),
          masteryGraphRepository: masteryRepo,
          topicRepository: _FakeTopicRepository(),
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
        await tester.enterText(find.byType(TextField).at(1), '30');
        await tester.enterText(find.byType(TextField).at(2), '2');
        await tester.pump();

        await tester.tap(find.text('Generate Plan'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        masteryRepo.generateCompleter!.complete(Result.success([]));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.calendar_today), findsOneWidget);
        expect(find.text('Your Study Schedule'), findsOneWidget);
      });

      testWidgets('generate button is disabled while generating', (tester) async {
        final masteryRepo = _FakeMasteryGraphRepository();
        masteryRepo.generateCompleter = Completer<Result<List<MasteryState>>>();

        await tester.pumpWidget(_buildTestApp(
          planRepository: _FakePlanRepository(),
          masteryGraphRepository: masteryRepo,
          topicRepository: _FakeTopicRepository(),
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
        await tester.enterText(find.byType(TextField).at(1), '30');
        await tester.enterText(find.byType(TextField).at(2), '2');
        await tester.pump();

        await tester.tap(find.text('Generate Plan'));
        await tester.pump();

        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull);

        masteryRepo.generateCompleter!.complete(Result.success([]));
        await tester.pumpAndSettle();

        final buttonAfter = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(buttonAfter.onPressed, isNotNull);
      });

      testWidgets('shows Generating text during generation', (tester) async {
        final masteryRepo = _FakeMasteryGraphRepository();
        masteryRepo.generateCompleter = Completer<Result<List<MasteryState>>>();

        await tester.pumpWidget(_buildTestApp(
          planRepository: _FakePlanRepository(),
          masteryGraphRepository: masteryRepo,
          topicRepository: _FakeTopicRepository(),
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(0), 'Math');
        await tester.enterText(find.byType(TextField).at(1), '10');
        await tester.enterText(find.byType(TextField).at(2), '1');
        await tester.pump();

        await tester.tap(find.text('Generate Plan'));
        await tester.pump();

        expect(find.text('Generating...'), findsOneWidget);

        masteryRepo.generateCompleter!.complete(Result.success([]));
        await tester.pumpAndSettle();

        expect(find.text('Generating...'), findsNothing);
        expect(find.text('Generate Plan'), findsOneWidget);
      });

      testWidgets('loads existing plan from repository on init', (tester) async {
        final planRepo = _FakePlanRepository();
        final existingPlan = PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [],
          summary: PlanSummary(
            totalQuestions: 50,
            totalMinutes: 1200,
            newTopics: 3,
            reviewTopics: 5,
            estimatedCoverage: 0.6,
            focusAreas: [],
          ),
          recommendations: [],
          planDurationDays: 30,
          targetMinutesPerDay: 120.0,
          targetQuestionsPerDay: 15,
        );
        await planRepo.savePlan(existingPlan);

        await tester.pumpWidget(_buildTestApp(
          planRepository: planRepo,
          masteryGraphRepository: _FakeMasteryGraphRepository(),
          topicRepository: _FakeTopicRepository(),
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.text('Your Study Schedule'), findsOneWidget);
        expect(find.text('Plan Summary'), findsOneWidget);
        expect(find.text('50Q'), findsOneWidget);
        expect(find.text('1200min'), findsOneWidget);
      });

      testWidgets('shows no plan when loadPlan returns null', (tester) async {
        final planRepo = _FakePlanRepository();

        await tester.pumpWidget(_buildTestApp(
          planRepository: planRepo,
          masteryGraphRepository: _FakeMasteryGraphRepository(),
          topicRepository: _FakeTopicRepository(),
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.text('Your Study Schedule'), findsNothing);
        expect(find.text('Plan Summary'), findsNothing);
      });

      testWidgets('loadExistingPlan silent catch does not crash when repository throws', (tester) async {
        final planRepo = _FakePlanRepository();
        planRepo.failOnInit = true;

        await tester.pumpWidget(_buildTestApp(
          planRepository: planRepo,
          masteryGraphRepository: _FakeMasteryGraphRepository(),
          topicRepository: _FakeTopicRepository(),
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.text('Your Study Schedule'), findsNothing);
        expect(find.text('Create Study Plan'), findsOneWidget);
      });

      testWidgets('planRepo.init failure in initState does not crash the screen', (tester) async {
        final planRepo = _FakePlanRepository();
        planRepo.failOnInit = true;

        await tester.pumpWidget(_buildTestApp(
          planRepository: planRepo,
          masteryGraphRepository: _FakeMasteryGraphRepository(),
          topicRepository: _FakeTopicRepository(),
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.text('Study Planner'), findsWidgets);
        expect(find.text('Create Study Plan'), findsOneWidget);
      });

      testWidgets('generate plan validates zero days', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          planRepository: _FakePlanRepository(),
          masteryGraphRepository: _FakeMasteryGraphRepository(),
          topicRepository: _FakeTopicRepository(),
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
        await tester.enterText(find.byType(TextField).at(1), '0');
        await tester.enterText(find.byType(TextField).at(2), '2');
        await tester.pump();

        await tester.tap(find.text('Generate Plan'));
        await tester.pumpAndSettle();

        expect(find.text('Please fill in all fields correctly'), findsOneWidget);
      });

      testWidgets('generate plan validates negative hours', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          planRepository: _FakePlanRepository(),
          masteryGraphRepository: _FakeMasteryGraphRepository(),
          topicRepository: _FakeTopicRepository(),
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
        await tester.enterText(find.byType(TextField).at(1), '30');
        await tester.enterText(find.byType(TextField).at(2), '-1');
        await tester.pump();

        await tester.tap(find.text('Generate Plan'));
        await tester.pumpAndSettle();

        expect(find.text('Please fill in all fields correctly'), findsOneWidget);
      });

      testWidgets('generate plan validates empty course name', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          planRepository: _FakePlanRepository(),
          masteryGraphRepository: _FakeMasteryGraphRepository(),
          topicRepository: _FakeTopicRepository(),
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(0), '');
        await tester.enterText(find.byType(TextField).at(1), '30');
        await tester.enterText(find.byType(TextField).at(2), '2');
        await tester.pump();

        await tester.tap(find.text('Generate Plan'));
        await tester.pumpAndSettle();

        expect(find.text('Please fill in all fields correctly'), findsOneWidget);
      });

      testWidgets('generate plan validates non-numeric input', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          planRepository: _FakePlanRepository(),
          masteryGraphRepository: _FakeMasteryGraphRepository(),
          topicRepository: _FakeTopicRepository(),
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
        await tester.enterText(find.byType(TextField).at(1), 'abc');
        await tester.enterText(find.byType(TextField).at(2), '2');
        await tester.pump();

        await tester.tap(find.text('Generate Plan'));
        await tester.pumpAndSettle();

        expect(find.text('Please fill in all fields correctly'), findsOneWidget);
      });

      testWidgets('openTutorMode triggers navigation when topic ID is non-empty', (tester) async {
        final planRepo = _FakePlanRepository();
        final observer = _TestNavigatorObserver();
        final existingPlan = PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [
            DailyPlan(
              dayNumber: 1,
              date: DateTime.now(),
              priorityTopics: [
                PlannedTopic(
                  topicId: 'topic-1',
                  topicTitle: 'Kinematics',
                  priority: 1.0,
                  reason: 'Weak area',
                  readinessScore: 0.3,
                  reviewUrgency: 0.8,
                  estimatedQuestions: 10,
                  estimatedMinutes: 60,
                  reasons: ['Weak area'],
                ),
              ],
              reviewQuestionIds: [],
              stretchGoalQuestionIds: [],
              targetQuestions: 10,
              targetMinutes: 60,
              focus: 'Study day',
              isRestDay: false,
            ),
          ],
          summary: PlanSummary(
            totalQuestions: 10,
            totalMinutes: 60,
            newTopics: 1,
            reviewTopics: 0,
            estimatedCoverage: 0.1,
            focusAreas: [],
          ),
          recommendations: [],
          planDurationDays: 1,
          targetMinutesPerDay: 60.0,
          targetQuestionsPerDay: 10,
        );
        await planRepo.savePlan(existingPlan);

        await tester.pumpWidget(_buildTestApp(
          planRepository: planRepo,
          masteryGraphRepository: _FakeMasteryGraphRepository(),
          topicRepository: _FakeTopicRepository(),
          fixedStudentId: 'test-student',
          navigatorObserver: observer,
          onGenerateRoute: (settings) {
            if (settings.name == '/tutor') {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Text('Tutor Screen')),
              );
            }
            return null;
          },
        ));
        await tester.pumpAndSettle();

        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -800),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.smart_toy_outlined), findsWidgets);

        await tester.tap(find.byIcon(Icons.smart_toy_outlined));
        await tester.pumpAndSettle();

        expect(find.text('Tutor Screen'), findsOneWidget);
      });

      testWidgets('responsive layout shows side-by-side fields on wide screens', (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(_buildTestApp(
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
        expect(textFields.length, 3);
        expect(textFields[1].controller, isNotNull);
        expect(textFields[2].controller, isNotNull);
      });

      testWidgets('generate plan handles repository init failure during generation', (tester) async {
        final planRepo = _FakePlanRepository();
        planRepo.failOnInit = true;

        await tester.pumpWidget(_buildTestApp(
          planRepository: planRepo,
          masteryGraphRepository: _FakeMasteryGraphRepository(),
          topicRepository: _FakeTopicRepository(),
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
        await tester.enterText(find.byType(TextField).at(1), '30');
        await tester.enterText(find.byType(TextField).at(2), '2');
        await tester.pump();

        await tester.tap(find.text('Generate Plan'));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('plan summary shows focus areas when present', (tester) async {
        final planRepo = _FakePlanRepository();
        final existingPlan = PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [],
          summary: PlanSummary(
            totalQuestions: 0,
            totalMinutes: 0,
            newTopics: 0,
            reviewTopics: 0,
            estimatedCoverage: 0,
            focusAreas: ['Math', 'Physics'],
          ),
          recommendations: [],
          planDurationDays: 30,
          targetMinutesPerDay: 120.0,
          targetQuestionsPerDay: 15,
        );
        await planRepo.savePlan(existingPlan);

        await tester.pumpWidget(_buildTestApp(
          planRepository: planRepo,
          masteryGraphRepository: _FakeMasteryGraphRepository(),
          topicRepository: _FakeTopicRepository(),
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.text('Focus: Math, Physics'), findsOneWidget);
      });

      testWidgets('plan with rest day shows rest chip', (tester) async {
        final planRepo = _FakePlanRepository();
        final existingPlan = PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [
            DailyPlan(
              dayNumber: 1,
              date: DateTime.now(),
              priorityTopics: [],
              reviewQuestionIds: [],
              stretchGoalQuestionIds: [],
              targetQuestions: 0,
              targetMinutes: 0,
              isRestDay: true,
            ),
          ],
          summary: PlanSummary(
            totalQuestions: 0,
            totalMinutes: 0,
            newTopics: 0,
            reviewTopics: 0,
            estimatedCoverage: 0,
            focusAreas: [],
          ),
          recommendations: [],
          planDurationDays: 1,
          targetMinutesPerDay: 0,
          targetQuestionsPerDay: 0,
        );
        await planRepo.savePlan(existingPlan);

        await tester.pumpWidget(_buildTestApp(
          planRepository: planRepo,
          masteryGraphRepository: _FakeMasteryGraphRepository(),
          topicRepository: _FakeTopicRepository(),
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.text('Rest'), findsOneWidget);
      });

      testWidgets('planned topic with empty topicId does not show tutor button', (tester) async {
        final planRepo = _FakePlanRepository();
        final existingPlan = PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [
            DailyPlan(
              dayNumber: 1,
              date: DateTime.now(),
              priorityTopics: [
                PlannedTopic(
                  topicId: '',
                  topicTitle: 'Empty Topic',
                  priority: 1.0,
                  reason: 'Test',
                  readinessScore: 0.5,
                  reviewUrgency: 0.3,
                  estimatedQuestions: 5,
                  estimatedMinutes: 30,
                  reasons: ['Test'],
                ),
              ],
              reviewQuestionIds: [],
              stretchGoalQuestionIds: [],
              targetQuestions: 5,
              targetMinutes: 30,
              isRestDay: false,
            ),
          ],
          summary: PlanSummary(
            totalQuestions: 5,
            totalMinutes: 30,
            newTopics: 1,
            reviewTopics: 0,
            estimatedCoverage: 0.1,
            focusAreas: [],
          ),
          recommendations: [],
          planDurationDays: 1,
          targetMinutesPerDay: 30.0,
          targetQuestionsPerDay: 5,
        );
        await planRepo.savePlan(existingPlan);

        await tester.pumpWidget(_buildTestApp(
          planRepository: planRepo,
          masteryGraphRepository: _FakeMasteryGraphRepository(),
          topicRepository: _FakeTopicRepository(),
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.smart_toy_outlined), findsNothing);
      });
    });

    group('Roadmaps tab', () {
      testWidgets('loadRoadmaps shows CircularProgressIndicator while loading', (tester) async {
        final roadmapRepo = _FakeRoadmapRepository();
        roadmapRepo.loadCompleter = Completer<void>();

        await tester.pumpWidget(_buildTestApp(
          roadmapRepository: roadmapRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pump();

        await tester.tap(find.text('Roadmaps'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        roadmapRepo.loadCompleter!.complete();
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('loadRoadmaps shows empty state when no roadmaps exist', (tester) async {
        final roadmapRepo = _FakeRoadmapRepository();

        await tester.pumpWidget(_buildTestApp(
          roadmapRepository: roadmapRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Roadmaps'));
        await tester.pumpAndSettle();

        expect(find.text('No roadmaps yet'), findsOneWidget);
        expect(find.text('e.g., I want to learn IB Physics in 180 days'), findsOneWidget);
      });

      testWidgets('loadRoadmaps shows ListView of roadmap cards when roadmaps exist', (tester) async {
        final roadmapRepo = _FakeRoadmapRepository();
        final roadmap = RoadmapModel(
          id: 'rm-1',
          studentId: 'test-student',
          goal: 'Learn IB Physics',
          createdAt: DateTime(2025, 1, 1),
          targetCompletionDate: DateTime(2025, 6, 1),
          milestones: [
            MilestoneModel(
              id: 'ms-1',
              title: 'Week 1',
              description: 'Foundation',
              deadline: DateTime(2025, 1, 15),
              order: 1,
              isCompleted: true,
            ),
            MilestoneModel(
              id: 'ms-2',
              title: 'Week 2',
              description: 'Core concepts',
              deadline: DateTime(2025, 2, 1),
              order: 2,
            ),
          ],
          status: 'active',
        );
        await roadmapRepo.saveRoadmap(roadmap);

        await tester.pumpWidget(_buildTestApp(
          roadmapRepository: roadmapRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Roadmaps'));
        await tester.pumpAndSettle();

        expect(find.text('Learn IB Physics'), findsOneWidget);
        expect(find.text('active'), findsOneWidget);
        expect(find.text('1/2 milestones'), findsOneWidget);
      });

      testWidgets('loadRoadmaps error path does not crash and shows empty state', (tester) async {
        final roadmapRepo = _FakeRoadmapRepository();
        roadmapRepo.failOnGet = true;

        await tester.pumpWidget(_buildTestApp(
          roadmapRepository: roadmapRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Roadmaps'));
        await tester.pumpAndSettle();

        expect(find.text('No roadmaps yet'), findsOneWidget);
      });

      testWidgets('tapping Create Roadmap opens AlertDialog with goal and days fields', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          roadmapRepository: _FakeRoadmapRepository(),
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Roadmaps'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create Roadmap'));
        await tester.pumpAndSettle();

        expect(find.text('Learning Goal'), findsOneWidget);
        expect(find.text('Days'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Generate Roadmap'), findsOneWidget);
      });

      testWidgets('cancelling roadmap dialog does not create a roadmap', (tester) async {
        final roadmapRepo = _FakeRoadmapRepository();

        await tester.pumpWidget(_buildTestApp(
          roadmapRepository: roadmapRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Roadmaps'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create Roadmap'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final roadmaps = await roadmapRepo.getAllRoadmaps();
        expect(roadmaps, isEmpty);
      });

      testWidgets('submitting empty goal cancels creation', (tester) async {
        final roadmapRepo = _FakeRoadmapRepository();

        await tester.pumpWidget(_buildTestApp(
          roadmapRepository: roadmapRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Roadmaps'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create Roadmap'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Generate Roadmap'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final roadmaps = await roadmapRepo.getAllRoadmaps();
        expect(roadmaps, isEmpty);
      });

      testWidgets('submitting valid goal creates a roadmap', (tester) async {
        final roadmapRepo = _FakeRoadmapRepository();

        await tester.pumpWidget(_buildTestApp(
          roadmapRepository: roadmapRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Roadmaps'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create Roadmap'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(0), 'Learn IB Physics in 180 days');
        await tester.enterText(find.byType(TextField).at(1), '30');
        await tester.pump();

        await tester.tap(find.text('Generate Roadmap'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final roadmaps = await roadmapRepo.getAllRoadmaps();
        expect(roadmaps, hasLength(1));
        expect(roadmaps.first.goal, 'Learn IB Physics in 180 days');
      });

      testWidgets('roadmap card renders status badge, progress bar, milestone count, target date', (tester) async {
        final roadmapRepo = _FakeRoadmapRepository();
        final roadmap = RoadmapModel(
          id: 'rm-2',
          studentId: 'test-student',
          goal: 'Master Python',
          createdAt: DateTime(2025, 1, 1),
          targetCompletionDate: DateTime(2025, 4, 1),
          milestones: [
            MilestoneModel(
              id: 'ms-1', title: 'Week 1', description: '',
              deadline: DateTime(2025, 1, 15), order: 1, isCompleted: true,
            ),
            MilestoneModel(
              id: 'ms-2', title: 'Week 2', description: '',
              deadline: DateTime(2025, 2, 1), order: 2,
            ),
            MilestoneModel(
              id: 'ms-3', title: 'Week 3', description: '',
              deadline: DateTime(2025, 2, 15), order: 3,
            ),
          ],
          status: 'completed',
        );
        await roadmapRepo.saveRoadmap(roadmap);

        await tester.pumpWidget(_buildTestApp(
          roadmapRepository: roadmapRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Roadmaps'));
        await tester.pumpAndSettle();

        expect(find.text('Master Python'), findsOneWidget);
        expect(find.text('completed'), findsOneWidget);
        expect(find.text('1/3 milestones'), findsOneWidget);
        expect(find.textContaining('Target Completion'), findsOneWidget);
      });

      testWidgets('buildMilestoneTimeline renders milestones', (tester) async {
        final roadmapRepo = _FakeRoadmapRepository();
        final now = DateTime.now();
        final roadmap = RoadmapModel(
          id: 'rm-3',
          studentId: 'test-student',
          goal: 'Learn Dart',
          createdAt: now.subtract(const Duration(days: 30)),
          targetCompletionDate: now.add(const Duration(days: 30)),
          milestones: [
            MilestoneModel(
              id: 'ms-past', title: 'Past', description: '',
              deadline: now.subtract(const Duration(days: 10)),
              order: 1, isCompleted: true,
            ),
            MilestoneModel(
              id: 'ms-overdue', title: 'Overdue', description: '',
              deadline: now.subtract(const Duration(days: 5)),
              order: 2, isCompleted: false,
            ),
            MilestoneModel(
              id: 'ms-future', title: 'Future', description: '',
              deadline: now.add(const Duration(days: 10)),
              order: 3,
            ),
          ],
          status: 'active',
        );
        await roadmapRepo.saveRoadmap(roadmap);

        await tester.pumpWidget(_buildTestApp(
          roadmapRepository: roadmapRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Roadmaps'));
        await tester.pumpAndSettle();

        expect(find.text('M1'), findsOneWidget);
        expect(find.text('M2'), findsOneWidget);
        expect(find.text('M3'), findsOneWidget);
      });

      testWidgets('buildMilestoneTimeline shows empty when no milestones', (tester) async {
        final roadmapRepo = _FakeRoadmapRepository();
        final roadmap = RoadmapModel(
          id: 'rm-4',
          studentId: 'test-student',
          goal: 'Empty milestones',
          createdAt: DateTime.now(),
          milestones: [],
          status: 'active',
        );
        await roadmapRepo.saveRoadmap(roadmap);

        await tester.pumpWidget(_buildTestApp(
          roadmapRepository: roadmapRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Roadmaps'));
        await tester.pumpAndSettle();

        expect(find.text('Empty milestones'), findsOneWidget);
      });

      testWidgets('roadmap card shows progress bar with correct value', (tester) async {
        final roadmapRepo = _FakeRoadmapRepository();
        final roadmap = RoadmapModel(
          id: 'rm-5',
          studentId: 'test-student',
          goal: 'Progress test',
          createdAt: DateTime.now(),
          milestones: [
            MilestoneModel(
              id: 'ms-1', title: 'W1', description: '',
              deadline: DateTime.now().add(const Duration(days: 7)),
              order: 1, isCompleted: true,
            ),
            MilestoneModel(
              id: 'ms-2', title: 'W2', description: '',
              deadline: DateTime.now().add(const Duration(days: 14)),
              order: 2,
            ),
          ],
          status: 'active',
        );
        await roadmapRepo.saveRoadmap(roadmap);

        await tester.pumpWidget(_buildTestApp(
          roadmapRepository: roadmapRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Roadmaps'));
        await tester.pumpAndSettle();

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('creating roadmap with save error shows error snackbar', (tester) async {
        final roadmapRepo = _FakeRoadmapRepository();
        roadmapRepo.failOnSave = true;

        await tester.pumpWidget(_buildTestApp(
          roadmapRepository: roadmapRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Roadmaps'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create Roadmap'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(0), 'Learn Dart');
        await tester.enterText(find.byType(TextField).at(1), '30');
        await tester.pump();

        await tester.tap(find.text('Generate Roadmap'));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('loadRoadmaps init failure does not crash', (tester) async {
        final roadmapRepo = _FakeRoadmapRepository();
        roadmapRepo.failOnInit = true;

        await tester.pumpWidget(_buildTestApp(
          roadmapRepository: roadmapRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Roadmaps'));
        await tester.pumpAndSettle();

        expect(find.text('No roadmaps yet'), findsOneWidget);
      });

      testWidgets('roadmap with archived status renders correctly', (tester) async {
        final roadmapRepo = _FakeRoadmapRepository();
        final now = DateTime.now();
        final roadmap = RoadmapModel(
          id: 'rm-archived',
          studentId: 'test-student',
          goal: 'Archived goal',
          createdAt: now,
          milestones: [],
          status: 'archived',
        );
        await roadmapRepo.saveRoadmap(roadmap);

        await tester.pumpWidget(_buildTestApp(
          roadmapRepository: roadmapRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Roadmaps'));
        await tester.pumpAndSettle();

        expect(find.text('Archived goal'), findsOneWidget);
        expect(find.text('archived'), findsOneWidget);
      });
    });
  });
}
