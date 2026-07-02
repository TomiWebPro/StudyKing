import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/planner/data/repositories/roadmap_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
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

class FakePlanRepository extends PlanRepository {
  final Map<String, PersonalLearningPlan> _storage = {};
  bool failOnInit = false;

  @override
  Future<Result<void>> init() async {
    if (failOnInit) throw Exception('Init failed');
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

class FakeMasteryGraphRepository extends MasteryGraphRepository {
  final Map<String, MasteryState> _masteryStates = {};
  bool failOnGenerate = false;
  Completer<Result<List<MasteryState>>>? generateCompleter;

  @override
  Future<Result<void>> init() async => Result.success(null);

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

class FakeTopicRepository extends TopicRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<Topic?>> get(String id) async => Result.success(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRoadmapRepository extends RoadmapRepository {
  final Map<String, RoadmapModel> _storage = {};
  bool failOnInit = false;
  bool failOnGet = false;
  bool failOnSave = false;
  Completer<void>? loadCompleter;

  @override
  Future<Result<void>> init() async {
    if (failOnInit) throw Exception('Init failed');
    if (loadCompleter != null) await loadCompleter!.future;
    return Result.success(null);
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

class FakeSessionRepository extends SessionRepository {
  final Map<String, Session> _storage = {};

  @override
  Future<Result<void>> init() async => Result.success(null);

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

class FakePendingActionRepository extends PendingActionRepository {
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

class FakeAdherenceRepo extends PlanAdherenceRepository {
  final List<PlanAdherenceModel> _records = [];

  void addRecord(PlanAdherenceModel record) => _records.add(record);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<PlanAdherenceModel>>> getByStudent(String studentId) async {
    return Result.success(_records.where((r) => r.studentId == studentId).toList());
  }
}

class FakePlanAdherenceOrchestrator extends PlanAdherenceOrchestrator {
  AdherenceDeviation? customDeviation;

  FakePlanAdherenceOrchestrator({AdherenceDeviation? adherenceDeviation})
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
  Future<Result<void>> recordActivity({required String studentId, required int actualMinutes, int actualQuestions = 0, String? planId}) async {
    return Result.success(null);
  }

  @override
  Future<Result<PersonalLearningPlan?>> suggestRegeneration({required String studentId, double? adjustmentFactor}) async {
    return Result.success(null);
  }
}

Widget buildPlannerTestApp({
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
  final repo = masteryGraphRepository ?? FakeMasteryGraphRepository();
  final svc = PlannerService(
    planRepo: planRepository ?? FakePlanRepository(),
    masteryService: MasteryGraphService(),
    repository: repo,
    topicRepository: topicRepository ?? FakeTopicRepository(),
    roadmapRepo: roadmapRepository ?? FakeRoadmapRepository(),
    sessionRepo: sessionRepository ?? FakeSessionRepository(),
    pendingActionRepo: pendingActionRepository ?? FakePendingActionRepository(),
    planOrchestrator: planOrchestrator ?? FakePlanAdherenceOrchestrator(),
    adherenceRepo: planAdherenceRepository ?? FakeAdherenceRepo(),
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
