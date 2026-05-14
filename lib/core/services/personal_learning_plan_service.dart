import '../errors/result.dart';
import '../data/repositories/mastery_graph_repository.dart';
import '../data/repositories/topic_repository.dart';
import '../data/repositories/plan_repository.dart';
import '../data/repositories/plan_adherence_repository.dart';
import '../data/models/topic_dependency_model.dart';
import '../data/models/mastery_state_model.dart';
import '../data/models/personal_learning_plan_model.dart';
import '../data/models/plan_adherence_model.dart';
import 'mastery_graph_service.dart';
import 'student_id_service.dart';


class PlanGenerationConfig {
  final int planDurationDays;
  final int targetQuestionsPerDay;
  final double targetMinutesPerDay;
  final double masteryThreshold;
  final int maxQuestionsPerTopic;
  final bool includeRestDays;
  final int restDayFrequency;

  PlanGenerationConfig({
    this.planDurationDays = 7,
    this.targetQuestionsPerDay = 15,
    this.targetMinutesPerDay = 30.0,
    this.masteryThreshold = 0.8,
    this.maxQuestionsPerTopic = 10,
    this.includeRestDays = false,
    this.restDayFrequency = 7,
  });
}

class PersonalLearningPlanService {
  final MasteryGraphService _masteryService;
  final MasteryGraphRepository _repository;
  final TopicRepository _topicRepository;
  final PlanRepository _planRepository;
  final PlanAdherenceRepository _adherenceRepository;
  PlanGenerationConfig config;

  PersonalLearningPlanService({
    MasteryGraphService? masteryService,
    MasteryGraphRepository? repository,
    TopicRepository? topicRepository,
    PlanRepository? planRepository,
    PlanAdherenceRepository? adherenceRepository,
    PlanGenerationConfig? config,
  })  : _masteryService = masteryService ?? MasteryGraphService(),
        _repository = repository ?? MasteryGraphRepository(),
        _topicRepository = topicRepository ?? TopicRepository(),
        _planRepository = planRepository ?? PlanRepository(),
        _adherenceRepository = adherenceRepository ?? PlanAdherenceRepository(),
        config = config ?? PlanGenerationConfig();

  Future<Result<PersonalLearningPlan>> generatePlan(String studentId) async {
    try {
      await _repository.init();
      await _adherenceRepository.init();
    } catch (e) {
      return Result.failure('Failed to initialize repository: $e');
    }

    final masteryStatesResult = await _repository.getAllMasteryStates(studentId);
    if (masteryStatesResult.isFailure) {
      return Result.failure(masteryStatesResult.error);
    }

    final allDependenciesResult = await _repository.getAllDependencies();
    if (allDependenciesResult.isFailure) {
      return Result.failure(allDependenciesResult.error);
    }

    final topicMastery = masteryStatesResult.data!;
    final dependencies = allDependenciesResult.data!;
    final dependencyMap = {for (var d in dependencies) d.topicId: d};

    final completedTopicIds = topicMastery
        .where((s) => s.masteryLevel.index >= MasteryLevel.proficient.index)
        .map((s) => s.topicId)
        .toSet();

    final recommendations = <PlanRecommendation>[];

    for (final state in topicMastery) {
      final dependency = dependencyMap[state.topicId];
      final isPrereq = dependency?.prerequisites.any((p) => !completedTopicIds.contains(p)) ?? false;
      final downstreamCount = dependency?.downstreamTopics.length ?? 0;

      final priority = dependency?.calculatePriority(
            masteryState: state.accuracy,
            isPrerequisite: isPrereq,
            downstreamCount: downstreamCount,
          ) ??
          (1 - state.accuracy);

      final explanations = <String>[];
      if (state.accuracy < 0.6) {
        explanations.add('Accuracy is below 60% — needs focused practice');
      }
      if (state.reviewUrgency > 0.7) {
        explanations.add('Review is overdue — forgetting risk is high');
      }
      if (state.currentStreak < 3) {
        explanations.add('Streak is low — consistency needed');
      }
      if (isPrereq) {
        explanations.add('Prerequisite for upcoming topics — must master first');
      }
      if (downstreamCount > 0) {
        explanations.add('Blocks $downstreamCount downstream topic(s)');
      }

      recommendations.add(PlanRecommendation(
        topicId: state.topicId,
        reason: _generateRecommendationReason(state),
        recommendationType: _classifyRecommendation(state),
        priority: priority,
        explanations: explanations,
        prerequisiteReason: isPrereq ? 'Required for dependent topics' : null,
        weaknessReason: state.accuracy < 0.6 ? 'Weak performance' : null,
        reviewReason: state.reviewUrgency > 0.7 ? 'High forgetting risk' : null,
      ));
    }

    recommendations.sort((a, b) => b.priority.compareTo(a.priority));

    final dailyPlans = await _generateDailyPlans(
      studentId: studentId,
      recommendations: recommendations,
      dependencyMap: dependencyMap,
      completedTopicIds: completedTopicIds,
    );

    final summary = _generateSummary(dailyPlans, recommendations);
    final plan = PersonalLearningPlan(
      studentId: studentId,
      generatedAt: DateTime.now(),
      dailyPlans: dailyPlans,
      summary: summary,
      recommendations: recommendations,
      planDurationDays: config.planDurationDays,
      targetMinutesPerDay: config.targetMinutesPerDay,
      targetQuestionsPerDay: config.targetQuestionsPerDay,
    );

    try {
      await _planRepository.init();
      await _planRepository.savePlan(plan);
    } catch (_) {}

    return Result.success(plan);
  }

  Future<void> recordDailyAdherence({
    required String studentId,
    required int actualQuestions,
    required int actualMinutes,
    String? planId,
  }) async {
    try {
      await _adherenceRepository.init();
      final plan = await _planRepository.loadPlan(studentId);
      if (plan == null) return;

      final today = DateTime.now();
      final dayNumber = _getPlanDayNumber(plan, today);
      DailyPlan? todayPlan;
      if (dayNumber != null && dayNumber >= 1 && dayNumber <= plan.dailyPlans.length) {
        todayPlan = plan.dailyPlans[dayNumber - 1];
      }

      final plannedQuestions = todayPlan?.targetQuestions ?? 0;
      final plannedMinutes = todayPlan?.targetMinutes ?? 0;

      final adherenceScore = _calculateAdherenceScore(
        plannedQuestions: plannedQuestions,
        actualQuestions: actualQuestions,
        plannedMinutes: plannedMinutes,
        actualMinutes: actualMinutes,
      );

      final model = PlanAdherenceModel(
        id: 'adh_${today.millisecondsSinceEpoch}_$studentId',
        studentId: studentId,
        date: today,
        plannedQuestions: plannedQuestions,
        actualQuestions: actualQuestions,
        plannedMinutes: plannedMinutes,
        actualMinutes: actualMinutes,
        adherenceScore: adherenceScore,
        planId: planId ?? plan.studentId,
      );

      await _adherenceRepository.save(model);
    } catch (_) {}
  }

  int? _getPlanDayNumber(PersonalLearningPlan plan, DateTime date) {
    for (final day in plan.dailyPlans) {
      if (day.date.year == date.year &&
          day.date.month == date.month &&
          day.date.day == date.day) {
        return day.dayNumber;
      }
    }
    return null;
  }

  double _calculateAdherenceScore({
    required int plannedQuestions,
    required int actualQuestions,
    required int plannedMinutes,
    required int actualMinutes,
  }) {
    if (plannedQuestions == 0 && plannedMinutes == 0) return 1.0;

    final questionScore = plannedQuestions > 0
        ? (actualQuestions / plannedQuestions).clamp(0.0, 1.0)
        : 0.5;
    final timeScore = plannedMinutes > 0
        ? (actualMinutes / plannedMinutes).clamp(0.0, 1.5)
        : 0.5;

    return (questionScore * 0.6 + timeScore * 0.4).clamp(0.0, 1.0);
  }

  Future<List<DailyPlan>> _generateDailyPlans({
    required String studentId,
    required List<PlanRecommendation> recommendations,
    required Map<String, TopicDependency> dependencyMap,
    required Set<String> completedTopicIds,
  }) async {
    final dailyPlans = <DailyPlan>[];
    final now = DateTime.now();

    var recommendationIndex = 0;
    final questionsPerTopic = <String, int>{};

    for (var day = 1; day <= config.planDurationDays; day++) {
      final isRestDay = config.includeRestDays && day % config.restDayFrequency == 0;

      if (isRestDay) {
        dailyPlans.add(DailyPlan(
          date: now.add(Duration(days: day - 1)),
          dayNumber: day,
          priorityTopics: [],
          reviewQuestionIds: [],
          stretchGoalQuestionIds: [],
          targetQuestions: 0,
          targetMinutes: 0,
          focus: 'Rest and review',
          isRestDay: true,
        ));
        continue;
      }

      final priorityTopics = <PlannedTopic>[];
      final reviewQuestionIds = <String>[];
      final stretchGoalQuestionIds = <String>[];

      var questionsToday = 0;
      var minutesToday = 0.0;

      while (recommendationIndex < recommendations.length &&
             questionsToday < config.targetQuestionsPerDay &&
             minutesToday < config.targetMinutesPerDay) {
        final rec = recommendations[recommendationIndex];
        final dependency = dependencyMap[rec.topicId];

        final readinessScore = await _getReadinessScore(rec.topicId);
        final isReady = dependency?.isReady(
              completedTopicIds.toList(),
              readinessScore,
            ) ??
            true;

        if (!isReady) {
          recommendationIndex++;
          continue;
        }

        final currentCount = questionsPerTopic[rec.topicId] ?? 0;
        if (currentCount >= config.maxQuestionsPerTopic) {
          recommendationIndex++;
          continue;
        }

        final estimatedQuestions = (dependency?.estimatedQuestions ?? 5).clamp(1, config.maxQuestionsPerTopic - currentCount);
        final estimatedMinutes = dependency?.estimatedMinutes ?? 15;

        final topicTitle = await _getTopicTitle(rec.topicId);
        final reviewUrgency = await _getReviewUrgency(rec.topicId);

        priorityTopics.add(PlannedTopic(
          topicId: rec.topicId,
          topicTitle: topicTitle,
          priority: rec.priority,
          reason: rec.reason,
          readinessScore: readinessScore,
          reviewUrgency: reviewUrgency,
          estimatedQuestions: estimatedQuestions,
          estimatedMinutes: estimatedMinutes,
          reasons: rec.explanations,
        ));

        questionsPerTopic[rec.topicId] = currentCount + estimatedQuestions;
        questionsToday += estimatedQuestions;
        minutesToday += estimatedMinutes.toDouble();
        recommendationIndex++;
      }

      dailyPlans.add(DailyPlan(
        date: now.add(Duration(days: day - 1)),
        dayNumber: day,
        priorityTopics: priorityTopics,
        reviewQuestionIds: reviewQuestionIds,
        stretchGoalQuestionIds: stretchGoalQuestionIds,
        targetQuestions: questionsToday,
        targetMinutes: minutesToday.round(),
        focus: _generateFocus(priorityTopics),
      ));
    }

    return dailyPlans;
  }

  String _generateRecommendationReason(MasteryState state) {
    if (state.accuracy >= 0.9) return 'High mastery — ready to advance';
    if (state.accuracy >= 0.8) return 'Good progress — maintain consistency';
    if (state.accuracy >= 0.6) return 'Developing — needs more practice';
    if (state.reviewUrgency > 0.7) return 'At risk — review overdue';
    return 'Needs attention — focus on fundamentals';
  }

  String _classifyRecommendation(MasteryState state) {
    if (state.reviewUrgency > 0.8) return 'review_urgent';
    if (state.accuracy < 0.6) return 'weakness';
    if (state.readinessScore > 0.8) return 'stretch';
    if (state.masteryLevel.index < MasteryLevel.developing.index) return 'foundational';
    return 'practice';
  }

  Future<String> _getTopicTitle(String topicId) async {
    try {
      final topic = await _topicRepository.get(topicId);
      return topic?.title ?? topicId;
    } catch (_) {
      return topicId;
    }
  }

  Future<double> _getReadinessScore(String topicId) async {
    try {
      final studentId = _getStudentId();
      final result = await _masteryService.getReadinessScore(studentId, topicId);
      return result.isSuccess ? result.data! : 0.5;
    } catch (_) {
      return 0.5;
    }
  }

  Future<double> _getReviewUrgency(String topicId) async {
    try {
      final studentId = _getStudentId();
      final result = await _masteryService.getReviewUrgency(studentId, topicId);
      return result.isSuccess ? result.data! : 0.3;
    } catch (_) {
      return 0.3;
    }
  }

  String _getStudentId() => StudentIdService().getStudentId();

  String _generateFocus(List<PlannedTopic> topics) {
    if (topics.isEmpty) return 'General review';
    final weakCount = topics.where((t) => t.reviewUrgency > 0.6).length;
    if (weakCount > topics.length / 2) return 'Focus on weak areas';
    return 'Practice and review';
  }

  PlanSummary _generateSummary(
    List<DailyPlan> dailyPlans,
    List<PlanRecommendation> recommendations,
  ) {
    final totalQuestions = dailyPlans.fold<int>(0, (sum, d) => sum + d.targetQuestions);
    final totalMinutes = dailyPlans.fold<int>(0, (sum, d) => sum + d.targetMinutes);

    final uniqueTopics = <String>{};
    for (final plan in dailyPlans) {
      for (final topic in plan.priorityTopics) {
        uniqueTopics.add(topic.topicId);
      }
    }

    final existingTopics = recommendations.where((r) => r.recommendationType != 'stretch').length;
    final newTopics = recommendations.where((r) => r.recommendationType == 'stretch').length;

    final focusAreas = recommendations
        .take(3)
        .map((r) => r.topicId)
        .toList();

    return PlanSummary(
      totalQuestions: totalQuestions,
      totalMinutes: totalMinutes,
      newTopics: newTopics,
      reviewTopics: existingTopics,
      estimatedCoverage: _calculateCoverage(uniqueTopics.length),
      focusAreas: focusAreas,
    );
  }

  double _calculateCoverage(int uniqueTopics) {
    const baseTopics = 10;
    return (uniqueTopics / baseTopics).clamp(0.0, 1.0);
  }

  Future<Result<List<PlannedTopic>>> getNextStudyTopics(
    String studentId, {
    int limit = 5,
  }) async {
    final planResult = await generatePlan(studentId);
    if (planResult.isFailure) {
      return Result.failure(planResult.error);
    }

    final allTopics = <PlannedTopic>[];
    for (final day in planResult.data!.dailyPlans) {
      allTopics.addAll(day.priorityTopics);
    }

    final uniqueTopics = <String, PlannedTopic>{};
    for (final topic in allTopics) {
      if (!uniqueTopics.containsKey(topic.topicId)) {
        uniqueTopics[topic.topicId] = topic;
      }
    }

    final sortedTopics = uniqueTopics.values.toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));

    return Result.success(sortedTopics.take(limit).toList());
  }

  Future<Result<List<String>>> getAtRiskTopicIds(String studentId) async {
    final weakResult = await _masteryService.getWeakTopics(studentId);
    if (weakResult.isFailure) {
      return Result.failure(weakResult.error);
    }

    return Result.success(weakResult.data!.map((s) => s.topicId).toList());
  }

  Future<Result<List<String>>> getReadyToAdvanceTopicIds(String studentId) async {
    final statesResult = await _masteryService.getAllTopicMastery(studentId);
    if (statesResult.isFailure) {
      return Result.failure(statesResult.error);
    }

    final readyTopics = statesResult.data!
        .where((s) => s.masteryLevel.index >= MasteryLevel.proficient.index && s.currentStreak >= 3)
        .map((s) => s.topicId)
        .toList();

    return Result.success(readyTopics);
  }

  Future<double> getCurrentAdherence(String studentId) async {
    try {
      await _adherenceRepository.init();
      return _adherenceRepository.getAverageAdherence(studentId);
    } catch (_) {
      return 0.0;
    }
  }

  Future<int> getConsecutiveLowAdherenceDays(String studentId) async {
    try {
      await _adherenceRepository.init();
      return _adherenceRepository.getConsecutiveLowAdherenceDays(studentId);
    } catch (_) {
      return 0;
    }
  }
}
