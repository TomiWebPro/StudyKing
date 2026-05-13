import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/personal_learning_plan_model.dart';
import 'package:studyking/core/data/models/topic_dependency_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/core/data/repositories/plan_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/planner/presentation/planner_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakePlanRepository extends PlanRepository {
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

Widget _buildTestApp({
  PlanRepository? planRepository,
  MasteryGraphRepository? masteryGraphRepository,
  TopicRepository? topicRepository,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: PlannerScreen(
      planRepository: planRepository,
      masteryGraphRepository: masteryGraphRepository,
      topicRepository: topicRepository,
    ),
  );
}

void main() {
  group('PlannerScreen', () {
    testWidgets('renders title and form fields', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Study Planner'), findsOneWidget);
      expect(find.text('Create Study Plan'), findsOneWidget);
      expect(find.text('Generate Plan'), findsOneWidget);
    });

    testWidgets('shows three input fields', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets('shows calendar icon on generate button', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('generate button is enabled initially', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows snackbar when fields are empty on generate', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generate Plan'));
      await tester.pumpAndSettle();

      expect(find.text('Please fill in all fields correctly'), findsOneWidget);
    });

    testWidgets('days field uses number keyboard type', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(textFields.length, 3);

      final daysField = textFields[1];
      expect(daysField.keyboardType, TextInputType.number);

      final hoursField = textFields[2];
      expect(hoursField.keyboardType, TextInputType.number);
    });

    testWidgets('no schedule list shown initially', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Your Study Schedule'), findsNothing);
    });

    testWidgets('form fields accept user input', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        planRepository: _FakePlanRepository(),
        masteryGraphRepository: _FakeMasteryGraphRepository(),
        topicRepository: _FakeTopicRepository(),
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
      expect(plan.first.studentId, isNotEmpty);
    });

    testWidgets('shows error container when plan generation fails', (tester) async {
      final masteryRepo = _FakeMasteryGraphRepository();
      masteryRepo.failOnGenerate = true;

      await tester.pumpWidget(_buildTestApp(
        planRepository: _FakePlanRepository(),
        masteryGraphRepository: masteryRepo,
        topicRepository: _FakeTopicRepository(),
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
        studentId: StudentIdService().getStudentId(),
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
      ));
      await tester.pumpAndSettle();

      expect(find.text('Your Study Schedule'), findsOneWidget);
      expect(find.text('Plan Summary'), findsOneWidget);
      expect(find.text('50Q'), findsOneWidget);
      expect(find.text('1200min'), findsOneWidget);
    });
  });
}
