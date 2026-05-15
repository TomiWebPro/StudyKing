import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/data/models/personal_learning_plan_model.dart';

class PlanRepository extends Repository<PersonalLearningPlan> {
  Future<void> init() async {
    await openBox(HiveBoxNames.learningPlans);
  }

  Future<void> create(PersonalLearningPlan plan) async {
    await super.save(plan.studentId, plan);
  }

  Future<void> savePlan(PersonalLearningPlan plan) async {
    await create(plan);
  }

  Future<PersonalLearningPlan?> loadPlan(String studentId) async {
    return super.get(studentId);
  }

  Future<void> deletePlan(String studentId) async {
    await super.delete(studentId);
  }

  Future<bool> hasPlan(String studentId) async {
    return box.containsKey(studentId);
  }

  Future<List<PersonalLearningPlan>> getAllPlans() async {
    return super.getAll();
  }
}
