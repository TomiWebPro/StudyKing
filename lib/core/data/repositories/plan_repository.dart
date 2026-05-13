import 'package:hive_flutter/hive_flutter.dart';
import '../models/personal_learning_plan_model.dart';

class PlanRepository {
  late Box<PersonalLearningPlan> _box;

  Future<void> init() async {
    _box = Hive.box<PersonalLearningPlan>('learning_plans');
  }

  Future<void> savePlan(PersonalLearningPlan plan) async {
    await _box.put(plan.studentId, plan);
  }

  Future<PersonalLearningPlan?> loadPlan(String studentId) async {
    return _box.get(studentId);
  }

  Future<void> deletePlan(String studentId) async {
    await _box.delete(studentId);
  }

  Future<bool> hasPlan(String studentId) async {
    return _box.containsKey(studentId);
  }

  Future<List<PersonalLearningPlan>> getAllPlans() async {
    return _box.values.toList();
  }
}
