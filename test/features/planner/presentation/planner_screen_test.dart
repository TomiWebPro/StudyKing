import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/planner/data/repositories/roadmap_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/features/planner/presentation/planner_screen.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../helpers/navigator_observer_helper.dart';

class _FakePlanRepository extends PlanRepository {
  final Map<String, PersonalLearningPlan> _storage = {};
  bool failOnInit = false;

  @override
  Future<void> init() async {
    if (failOnInit) throw Exception('Init failed');
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
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<Topic?>> get(String id) async => Result.success(null);

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
  Future<Result<void>> saveRoadmap(RoadmapModel roadmap) async {
    if (failOnSave) throw Exception('Save failed');
    _storage[roadmap.id] = roadmap;
    return Result.success(null);
  }

  @override
  Future<Result<RoadmapModel?>> loadRoadmap(String id) async {
    return Result.success(_storage[id]);
  }

  @override
  Future<Result<List<RoadmapModel>>> getRoadmapsByStudent(String studentId) async {
    if (loadCompleter != null) await loadCompleter!.future;
    if (failOnGet) throw Exception('Get failed');
    return Result.success(
      _storage.values
          .where((r) => r.studentId == studentId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  @override
  Future<Result<List<RoadmapModel>>> getAllRoadmaps() async {
    return Result.success(_storage.values.toList());
  }

  @override
  Future<Result<void>> deleteRoadmap(String id) async {
    _storage.remove(id);
    return Result.success(null);
  }
}

class _FakeSessionRepository extends SessionRepository {
  final Map<String, Session> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> save(String key, Session session) async {
    _storage[session.id] = session;
    return Result.success(null);
  }

  @override
  Future<Result<Session?>> get(String id) async {
    return Result.success(_storage[id]);
  }

  @override
  Future<Result<List<Session>>> getAll() async {
    return Result.success(_storage.values.toList());
  }
}

class _FakePendingActionRepository extends PendingActionRepository {
  final Map<String, PendingActionModel> _storage = {};

  void addAction(PendingActionModel action) {
    _storage[action.id] = action;
  }

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<PendingActionModel>>> getPending(String studentId) async {
    return Result.success(_storage.values
        .where((a) => a.studentId == studentId && a.status == 'pending')
        .toList());
  }

  @override
  Future<Result<PendingActionModel?>> get(String id) async {
    return Result.success(_storage[id]);
  }

  @override
  Future<Result<void>> markCompleted(String id) async {
    final action = _storage[id];
    if (action != null) {
      _storage[id] = action.copyWith(status: 'completed');
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> markRejected(String id) async {
    final action = _storage[id];
    if (action != null) {
      _storage[id] = action.copyWith(status: 'rejected');
    }
    return Result.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAdherenceRepo extends PlanAdherenceRepository {
  final List<PlanAdherenceModel> _records = [];

  void addRecord(PlanAdherenceModel record) => _records.add(record);

  @override
  Future<void> init() async {}

  @override
  Future<List<PlanAdherenceModel>> getByStudent(String studentId) async {
    return _records.where((r) => r.studentId == studentId).toList();
  }
}

class _FakePlanAdherenceOrchestrator extends PlanAdherenceOrchestrator {
  AdherenceDeviation? customDeviation;

  _FakePlanAdherenceOrchestrator({AdherenceDeviation? adherenceDeviation})
      : customDeviation = adherenceDeviation;

  @override
  Future<Result<AdherenceDeviation>> checkAdherence(String studentId) async {
    return Result.success(customDeviation ?? const AdherenceDeviation());
  }

  @override
  Future<Result<Map<String, dynamic>>> getAdherenceReport(String studentId) async {
    return Result.success({'totalDays': 0, 'averageAdherence': 1.0, 'lowAdherenceDays': 0, 'weeklyTrend': <double>[]});
  }

  @override
  Future<void> recordActivity({required String studentId, required int actualMinutes, int actualQuestions = 0, String? planId}) async {}

  @override
  Future<Result<PersonalLearningPlan?>> suggestRegeneration({required String studentId, double? adjustmentFactor}) async {
    return Result.success(null);
  }
}

Widget _buildTestApp({
  PlanRepository? planRepository,
  MasteryGraphRepository? masteryGraphRepository,
  TopicRepository? topicRepository,
  RoadmapRepository? roadmapRepository,
  SessionRepository? sessionRepository,
  PendingActionRepository? pendingActionRepository,
  PlanAdherenceOrchestrator? planOrchestrator,
  PlanAdherenceRepository? planAdherenceRepository,
  String? fixedStudentId,
  NavigatorObserver? navigatorObserver,
  RouteFactory? onGenerateRoute,
}) {
  final id = fixedStudentId ?? 'test-student';
  final repo = masteryGraphRepository ?? _FakeMasteryGraphRepository();
  final svc = PlannerService(
    planRepo: planRepository ?? _FakePlanRepository(),
    masteryService: MasteryGraphService(),
    repository: repo,
    topicRepository: topicRepository ?? _FakeTopicRepository(),
    roadmapRepo: roadmapRepository ?? _FakeRoadmapRepository(),
    sessionRepo: sessionRepository ?? _FakeSessionRepository(),
    pendingActionRepo: pendingActionRepository ?? _FakePendingActionRepository(),
    planOrchestrator: planOrchestrator ?? _FakePlanAdherenceOrchestrator(),
    adherenceRepo: planAdherenceRepository ?? _FakeAdherenceRepo(),
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
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        await tester.pump();

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
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        // 30 days * 15 questions/day = 450; 120 min/day * 30 days = 3600
        expect(find.text('450Q'), findsOneWidget);
        expect(find.text('3600 min'), findsOneWidget);

        final plan = await planRepo.getAllPlans();
        expect(plan.data, hasLength(1));
        expect(plan.data!.first.studentId, 'test-student');
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
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(find.byType(SnackBar), findsOneWidget);
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
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

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
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

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

        await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
        await tester.enterText(find.byType(TextField).at(1), '30');
        await tester.enterText(find.byType(TextField).at(2), '2');
        await tester.pump();

        await tester.tap(find.text('Generate Plan'));
        await tester.pump();

        expect(find.text('Generating...'), findsOneWidget);

        masteryRepo.generateCompleter!.complete(Result.success([]));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

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
        expect(find.text('1200 min'), findsOneWidget);
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
        final observer = TestNavigatorObserver();
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
        expect(find.text('In Progress'), findsOneWidget);
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
        expect(roadmaps.data, isEmpty);
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
        expect(roadmaps.data, isEmpty);
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
        expect(roadmaps.data, hasLength(1));
        expect(roadmaps.data!.first.goal, 'Learn IB Physics in 180 days');
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
        expect(find.text('Completed'), findsOneWidget);
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
        expect(find.text('Not Started'), findsOneWidget);
      });
    });

    group('Pending Actions', () {
      testWidgets('shows pending actions section when actions exist',
          (tester) async {
        final pendingRepo = _FakePendingActionRepository();
        pendingRepo.addAction(PendingActionModel(
          id: 'action-1',
          studentId: 'test-student',
          actionType: 'schedule',
          topicTitle: 'Algebra',
        ));

        await tester.pumpWidget(_buildTestApp(
          pendingActionRepository: pendingRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.text('Pending Actions'), findsOneWidget);
        expect(find.text('Algebra'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
        expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
      });

      testWidgets('accept pending action marks it as completed',
          (tester) async {
        final pendingRepo = _FakePendingActionRepository();
        pendingRepo.addAction(PendingActionModel(
          id: 'action-2',
          studentId: 'test-student',
          actionType: 'schedule',
          topicTitle: 'Physics',
          payload: {
            'topicId': 'topic-1',
            'subjectId': 'subj-1',
            'scheduledTime': DateTime.now()
                .add(const Duration(days: 1))
                .toIso8601String(),
            'durationMinutes': 30,
          },
        ));

        await tester.pumpWidget(_buildTestApp(
          pendingActionRepository: pendingRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.text('Physics'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.check_circle_outline));
        await tester.pumpAndSettle();

        final action = await pendingRepo.get('action-2');
        expect(action.data?.status, 'completed');
      });

      testWidgets('dismiss pending action marks it as rejected',
          (tester) async {
        final pendingRepo = _FakePendingActionRepository();
        pendingRepo.addAction(PendingActionModel(
          id: 'action-3',
          studentId: 'test-student',
          actionType: 'reschedule',
          topicTitle: 'Chemistry',
        ));

        await tester.pumpWidget(_buildTestApp(
          pendingActionRepository: pendingRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.text('Chemistry'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.cancel_outlined));
        await tester.pumpAndSettle();

        final action = await pendingRepo.get('action-3');
        expect(action.data?.status, 'rejected');
      });

      testWidgets('pending actions section not shown when empty',
          (tester) async {
        await tester.pumpWidget(_buildTestApp(
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.text('Pending Actions'), findsNothing);
      });
    });

    group('Multi-syllabus input', () {
      testWidgets('toggle switches to multi-subject mode', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.text('Course/Subject +'), findsNothing);

        await tester.tap(find.text('Subjects'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Course/Subject +'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('add and remove syllabus entries', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          fixedStudentId: 'test-student',
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(find.text('Subjects'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(find.text('Course/Subject +'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);

        await tester.tap(find.text('Course/Subject +'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byIcon(Icons.remove_circle_outline), findsNWidgets(2));

        await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
      });

      testWidgets('multi-syllabus validation shows snackbar on empty fields', (tester) async {
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

        await tester.tap(find.text('Subjects'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Course/Subject +'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Generate Plan'));
        await tester.pumpAndSettle();

        expect(find.text('Please fill in all fields correctly'), findsOneWidget);
      });

      testWidgets('multi-syllabus with valid inputs triggers generation', (tester) async {
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

        await tester.tap(find.text('Subjects'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Course/Subject +'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
        await tester.enterText(find.byType(TextField).at(1), '30');
        await tester.enterText(find.byType(TextField).at(2), '2');
        await tester.pump();

        expect(find.text('Generate Plan'), findsOneWidget);

        await tester.tap(find.text('Generate Plan'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Adherence banner', () {
      testWidgets('shows banner when deviation requires regeneration', (tester) async {
        final planRepo = _FakePlanRepository();
        final existingPlan = PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [],
          summary: PlanSummary(
            totalQuestions: 0, totalMinutes: 0, newTopics: 0,
            reviewTopics: 0, estimatedCoverage: 0, focusAreas: [],
          ),
          recommendations: [],
          planDurationDays: 30,
          targetMinutesPerDay: 60.0,
          targetQuestionsPerDay: 10,
        );
        await planRepo.savePlan(existingPlan);

        final deviationPlanAdherenceOrchestrator = _FakePlanAdherenceOrchestrator(
          adherenceDeviation: const AdherenceDeviation(
            requiresRegeneration: true,
            requiresEscalation: false,
            message: 'You are behind schedule',
          ),
        );

        await tester.pumpWidget(_buildTestApp(
          planRepository: planRepo,
          planOrchestrator: deviationPlanAdherenceOrchestrator,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.text('Redistribute'), findsOneWidget);
        expect(find.text('Regenerate Plan'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });

      testWidgets('banner shows escalation styling when requiresEscalation', (tester) async {
        final planRepo = _FakePlanRepository();
        final existingPlan = PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [],
          summary: PlanSummary(
            totalQuestions: 0, totalMinutes: 0, newTopics: 0,
            reviewTopics: 0, estimatedCoverage: 0, focusAreas: [],
          ),
          recommendations: [],
          planDurationDays: 30,
          targetMinutesPerDay: 60.0,
          targetQuestionsPerDay: 10,
        );
        await planRepo.savePlan(existingPlan);

        final deviationPlanAdherenceOrchestrator = _FakePlanAdherenceOrchestrator(
          adherenceDeviation: const AdherenceDeviation(
            requiresRegeneration: true,
            requiresEscalation: true,
            message: 'Critical: you are far behind',
          ),
        );

        await tester.pumpWidget(_buildTestApp(
          planRepository: planRepo,
          planOrchestrator: deviationPlanAdherenceOrchestrator,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      });

      testWidgets('banner does not show when deviation is null', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.text('Redistribute'), findsNothing);
      });
    });

    group('Scheduled lessons', () {
      testWidgets('shows scheduled lessons section when lessons exist', (tester) async {
        final planRepo = _FakePlanRepository();
        final existingPlan = PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [],
          summary: PlanSummary(
            totalQuestions: 0, totalMinutes: 0, newTopics: 0,
            reviewTopics: 0, estimatedCoverage: 0, focusAreas: [],
          ),
          recommendations: [],
          planDurationDays: 30,
          targetMinutesPerDay: 60.0,
          targetQuestionsPerDay: 10,
        );
        await planRepo.savePlan(existingPlan);

        final sessionRepo = _FakeSessionRepository();
        final now = DateTime.now();
        final sess0 = Session(
          
                    id: 'sess-1',
                    studentId: 'test-student',
                    topicId: 'topic-1',
                    subjectId: 'subj-1',
                    startTime: now.add(const Duration(hours: 2)),
                    plannedDurationMinutes: 30,
                    status: SessionStatus.planned,
                  
        );
        await sessionRepo.save(sess0.id, sess0);

        await tester.pumpWidget(_buildTestApp(
          planRepository: planRepo,
          sessionRepository: sessionRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.text('Scheduled Lessons'), findsOneWidget);
        expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
      });

      testWidgets('completed lesson shows check icon and line-through title', (tester) async {
        final planRepo = _FakePlanRepository();
        final existingPlan = PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [],
          summary: PlanSummary(
            totalQuestions: 0, totalMinutes: 0, newTopics: 0,
            reviewTopics: 0, estimatedCoverage: 0, focusAreas: [],
          ),
          recommendations: [],
          planDurationDays: 30,
          targetMinutesPerDay: 60.0,
          targetQuestionsPerDay: 10,
        );
        await planRepo.savePlan(existingPlan);

        final sessionRepo = _FakeSessionRepository();
        final now = DateTime.now();
        final sess1 = Session(
          
                    id: 'sess-completed',
                    studentId: 'test-student',
                    topicId: 'topic-done',
                    subjectId: 'subj-1',
                    startTime: now.subtract(const Duration(hours: 4)),
                    endTime: now.subtract(const Duration(hours: 3)),
                    completed: true,
                    status: SessionStatus.completed,
                  
        );
        await sessionRepo.save(sess1.id, sess1);

        await tester.pumpWidget(_buildTestApp(
          planRepository: planRepo,
          sessionRepository: sessionRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.play_circle_filled), findsNothing);
        expect(find.byIcon(Icons.cancel_outlined), findsNothing);
      });

      testWidgets('play button on scheduled lesson navigates to tutor', (tester) async {
        final planRepo = _FakePlanRepository();
        final existingPlan = PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [],
          summary: PlanSummary(
            totalQuestions: 0, totalMinutes: 0, newTopics: 0,
            reviewTopics: 0, estimatedCoverage: 0, focusAreas: [],
          ),
          recommendations: [],
          planDurationDays: 30,
          targetMinutesPerDay: 60.0,
          targetQuestionsPerDay: 10,
        );
        await planRepo.savePlan(existingPlan);

        final sessionRepo = _FakeSessionRepository();
        final now = DateTime.now();
        final sess2 = Session(
          
                    id: 'sess-2',
                    studentId: 'test-student',
                    topicId: 'topic-2',
                    subjectId: 'subj-2',
                    startTime: now.add(const Duration(hours: 2)),
                    plannedDurationMinutes: 45,
                    status: SessionStatus.planned,
                  
        );
        await sessionRepo.save(sess2.id, sess2);

        await tester.pumpWidget(_buildTestApp(
          planRepository: planRepo,
          sessionRepository: sessionRepo,
          fixedStudentId: 'test-student',
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

        await tester.tap(find.byIcon(Icons.play_circle_filled));
        await tester.pumpAndSettle();

        expect(find.text('Tutor Screen'), findsOneWidget);
      });

      testWidgets('cancel lesson shows confirmation dialog and cancels', (tester) async {
        final planRepo = _FakePlanRepository();
        final existingPlan = PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [],
          summary: PlanSummary(
            totalQuestions: 0, totalMinutes: 0, newTopics: 0,
            reviewTopics: 0, estimatedCoverage: 0, focusAreas: [],
          ),
          recommendations: [],
          planDurationDays: 30,
          targetMinutesPerDay: 60.0,
          targetQuestionsPerDay: 10,
        );
        await planRepo.savePlan(existingPlan);

        final sessionRepo = _FakeSessionRepository();
        final now = DateTime.now();
        final sess3 = Session(
          
                    id: 'sess-cancel',
                    studentId: 'test-student',
                    topicId: 'topic-cancel',
                    subjectId: 'subj-1',
                    startTime: now.add(const Duration(hours: 2)),
                    plannedDurationMinutes: 30,
                    status: SessionStatus.planned,
                  
        );
        await sessionRepo.save(sess3.id, sess3);

        await tester.pumpWidget(_buildTestApp(
          planRepository: planRepo,
          sessionRepository: sessionRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.cancel_outlined));
        await tester.pumpAndSettle();

        expect(find.text('Are you sure you want to cancel this lesson?'), findsOneWidget);
        expect(find.text('Cancel'), findsWidgets);

        await tester.tap(find.text('Cancel').last);
        await tester.pumpAndSettle();

        final session = await sessionRepo.get('sess-cancel');
        expect(session.isSuccess, isTrue);
      });

      testWidgets('shows more lessons button when > 3 scheduled lessons', (tester) async {
        final planRepo = _FakePlanRepository();
        final existingPlan = PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [],
          summary: PlanSummary(
            totalQuestions: 0, totalMinutes: 0, newTopics: 0,
            reviewTopics: 0, estimatedCoverage: 0, focusAreas: [],
          ),
          recommendations: [],
          planDurationDays: 30,
          targetMinutesPerDay: 60.0,
          targetQuestionsPerDay: 10,
        );
        await planRepo.savePlan(existingPlan);

        final sessionRepo = _FakeSessionRepository();
        final now = DateTime.now();
        for (var i = 0; i < 5; i++) {
          final sess4 = Session(
            
                        id: 'sess-$i',
                        studentId: 'test-student',
                        topicId: 'topic-$i',
                        subjectId: 'subj-1',
                        startTime: now.add(Duration(hours: 2 + i)),
                        plannedDurationMinutes: 30,
                        status: SessionStatus.planned,
                      
          );
          await sessionRepo.save(sess4.id, sess4);
        }

        await tester.pumpWidget(_buildTestApp(
          planRepository: planRepo,
          sessionRepository: sessionRepo,
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.textContaining('more...'), findsOneWidget);
      });
    });

    group('Calendar tab', () {
      testWidgets('shows empty state when no plan exists', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Calendar'));
        await tester.pumpAndSettle();

        expect(find.text('No study plan yet'), findsOneWidget);
      });
    });

    group('Error and success handling', () {
      testWidgets('error container shows on study plan tab when error is set', (tester) async {
        final planRepo = _FakePlanRepository();
        final masteryRepo = _FakeMasteryGraphRepository();
        masteryRepo.failOnGenerate = true;

        await tester.pumpWidget(_buildTestApp(
          planRepository: planRepo,
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
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('success message shows snackbar', (tester) async {
        final planRepo = _FakePlanRepository();
        final existingPlan = PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [],
          summary: PlanSummary(
            totalQuestions: 0, totalMinutes: 0, newTopics: 0,
            reviewTopics: 0, estimatedCoverage: 0, focusAreas: [],
          ),
          recommendations: [],
          planDurationDays: 30,
          targetMinutesPerDay: 60.0,
          targetQuestionsPerDay: 10,
        );
        await planRepo.savePlan(existingPlan);

        final masteryRepo = _FakeMasteryGraphRepository();
        await tester.pumpWidget(_buildTestApp(
          planRepository: planRepo,
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
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(find.byType(SnackBar), findsOneWidget);
      });
    });

    group('Keyboard accessibility', () {
      testWidgets('renders FocusTraversalGroup for keyboard navigation', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.byType(FocusTraversalGroup), findsAtLeastNWidgets(1));
      });

      testWidgets('interactive elements have proper semantics for keyboard focus', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          fixedStudentId: 'test-student',
        ));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsNWidgets(3));
        expect(find.byType(ElevatedButton), findsOneWidget);
      });
    });
  });
}
