import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';

class PlanRepository extends Repository<PersonalLearningPlan> {
  PlanRepository() : super(boxName: HiveBoxNames.learningPlans);

  Future<Result<void>> init() async {
    return Result.capture(
      () async => openBox(HiveBoxNames.learningPlans),
      context: 'PlanRepository.init',
    );
  }

  Future<Result<void>> create(PersonalLearningPlan plan) async {
    return super.put(plan.studentId, plan);
  }

  Future<Result<void>> savePlan(PersonalLearningPlan plan) async {
    return create(plan);
  }

  Future<Result<PersonalLearningPlan?>> loadPlan(String studentId) async {
    return super.get(studentId);
  }

  Future<Result<void>> deletePlan(String studentId) async {
    return super.delete(studentId);
  }

  Future<Result<bool>> hasPlan(String studentId) async {
    return Result.capture(
      () async => box.containsKey(studentId),
      context: 'hasPlan',
    );
  }

  Future<Result<List<PersonalLearningPlan>>> getAllPlans() async {
    return super.getAll();
  }
}
