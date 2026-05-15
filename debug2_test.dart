import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/personal_learning_plan_service.dart';

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
  Future<List<PersonalLearningPlan>> getAllPlans() async {
    return _storage.values.toList();
  }
}

class _FakeMasteryGraphRepository extends MasteryGraphRepository {
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('trace plan generation', (tester) async {
    Hive.init(Directory.systemTemp.createTempSync('planner_test_').path);
    
    final planRepo = _FakePlanRepository();
    final masteryRepo = _FakeMasteryGraphRepository();
    
    final svc = PersonalLearningPlanService(
      repository: masteryRepo,
      planRepository: planRepo,
      config: PlanGenerationConfig(
        planDurationDays: 30,
        targetMinutesPerDay: 120,
        targetQuestionsPerDay: 15,
      ),
    );
    
    final result = await svc.generatePlan('test-student');
    if (result.isSuccess) {
      result.data!.dailyPlans.length;
      result.data!.summary.totalQuestions;
    }
  });
}
