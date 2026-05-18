import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/features/questions/data/models/question_evaluation_model.dart';
import 'package:studyking/features/practice/data/repositories/mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/topic_dependency_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_evaluation_repository.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';

/// Facade that delegates to four individual repositories.
/// New code should depend on the specific repositories directly.
class MasteryGraphRepository extends Repository<MasteryState> {
  final MasteryStateRepository masteryStateRepo;
  final QuestionMasteryStateRepository questionMasteryRepo;
  final TopicDependencyRepository topicDependencyRepo;
  final QuestionEvaluationRepository questionEvaluationRepo;

  MasteryGraphRepository({
    MasteryStateRepository? masteryStateRepo,
    QuestionMasteryStateRepository? questionMasteryRepo,
    TopicDependencyRepository? topicDependencyRepo,
    QuestionEvaluationRepository? questionEvaluationRepo,
  })  : masteryStateRepo = masteryStateRepo ?? MasteryStateRepository(),
        questionMasteryRepo = questionMasteryRepo ?? QuestionMasteryStateRepository(),
        topicDependencyRepo = topicDependencyRepo ?? TopicDependencyRepository(),
        questionEvaluationRepo = questionEvaluationRepo ?? QuestionEvaluationRepository();

  MasteryGraphRepository.test({
    required Box<MasteryState> masteryBox,
    required Box<QuestionMasteryState> questionMasteryBox,
    required Box<TopicDependency> dependencyBox,
    required Box<QuestionEvaluation> evaluationBox,
    MasteryStateRepository? masteryStateRepo,
    QuestionMasteryStateRepository? questionMasteryRepo,
    TopicDependencyRepository? topicDependencyRepo,
    QuestionEvaluationRepository? questionEvaluationRepo,
  })  : masteryStateRepo = masteryStateRepo ?? MasteryStateRepository(),
        questionMasteryRepo = questionMasteryRepo ?? QuestionMasteryStateRepository(),
        topicDependencyRepo = topicDependencyRepo ?? TopicDependencyRepository(),
        questionEvaluationRepo = questionEvaluationRepo ?? QuestionEvaluationRepository() {
    attachBox(masteryBox);
    this.masteryStateRepo.attachBox(masteryBox);
    this.questionMasteryRepo.attachBox(questionMasteryBox);
    this.topicDependencyRepo.attachBox(dependencyBox);
    this.questionEvaluationRepo.attachBox(evaluationBox);
  }

  @override
  Future<void> openBox(String boxName) async {
    await super.openBox(boxName);
  }

  Future<void> init() async {
    await masteryStateRepo.init();
    await questionMasteryRepo.init();
    await topicDependencyRepo.init();
    await questionEvaluationRepo.init();
    attachBox(Hive.box<MasteryState>(HiveBoxNames.masteryStates));
  }

  // --- MasteryState delegation ---

  Future<Result<MasteryState>> getMasteryState(
    String studentId,
    String topicId,
  ) {
    return masteryStateRepo.getMasteryState(studentId, topicId);
  }

  Future<Result<void>> updateMasteryState(MasteryState state) {
    return masteryStateRepo.updateMasteryState(state);
  }

  Future<Result<List<MasteryState>>> getAllMasteryStates(
      String studentId) {
    return masteryStateRepo.getAllMasteryStates(studentId);
  }

  Future<Result<List<MasteryState>>> getTopicsNeedingReview(
      String studentId) {
    return masteryStateRepo.getTopicsNeedingReview(studentId);
  }

  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) {
    return masteryStateRepo.getWeakTopics(studentId);
  }

  Future<Result<Map<String, dynamic>>> getMasterySnapshot(
      String studentId) {
    return masteryStateRepo.getMasterySnapshot(studentId);
  }

  // --- QuestionMasteryState delegation ---

  Future<Result<QuestionMasteryState>> getQuestionMasteryState(
    String studentId,
    String questionId,
  ) {
    return questionMasteryRepo.getQuestionMasteryState(studentId, questionId);
  }

  Future<Result<void>> updateQuestionMasteryState(
      QuestionMasteryState state) {
    return questionMasteryRepo.updateQuestionMasteryState(state);
  }

  Future<Result<List<QuestionMasteryState>>> getDueQuestions(
    String studentId, {
    DateTime? asOf,
  }) {
    return questionMasteryRepo.getDueQuestions(studentId, asOf: asOf);
  }

  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(
    String studentId, {
    double threshold = 0.5,
  }) {
    return questionMasteryRepo.getAtRiskQuestions(studentId, threshold: threshold);
  }

  // --- TopicDependency delegation ---

  Future<Result<TopicDependency>> getTopicDependency(String topicId) {
    return topicDependencyRepo.getTopicDependency(topicId);
  }

  Future<Result<void>> updateTopicDependency(
      TopicDependency dependency) {
    return topicDependencyRepo.updateTopicDependency(dependency);
  }

  Future<Result<List<TopicDependency>>> getAllDependencies() {
    return topicDependencyRepo.getAllDependencies();
  }

  // --- QuestionEvaluation delegation ---

  Future<Result<QuestionEvaluation>> getEvaluation(String questionId) {
    return questionEvaluationRepo.getEvaluation(questionId);
  }

  Future<Result<void>> saveEvaluation(QuestionEvaluation evaluation) {
    return questionEvaluationRepo.saveEvaluation(evaluation);
  }

  Future<Result<void>> migrateFromLegacy({
    required String questionId,
    String? markscheme,
    String? correctAnswer,
    List<String>? options,
    String? explanation,
  }) {
    return questionEvaluationRepo.migrateFromLegacy(
      questionId: questionId,
      markscheme: markscheme,
      correctAnswer: correctAnswer,
      options: options,
      explanation: explanation,
    );
  }
}
