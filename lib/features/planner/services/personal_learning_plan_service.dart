import 'package:studyking/core/utils/answer_comparator.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/localization_helpers.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/study_utils.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/planner/services/syllabus_resolver.dart';
import 'package:studyking/features/planner/data/repositories/roadmap_repository.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';


class PlanGenerationConfig {
  final int planDurationDays;
  final int targetQuestionsPerDay;
  final double targetMinutesPerDay;
  final double masteryThreshold;
  final int maxQuestionsPerTopic;
  final bool includeRestDays;
  final int restDayFrequency;

  PlanGenerationConfig({
    this.planDurationDays = defaultPlanDurationDays,
    this.targetQuestionsPerDay = defaultQuestionsPerDay,
    this.targetMinutesPerDay = defaultMinutesPerDay,
    this.masteryThreshold = defaultMasteryThreshold,
    this.maxQuestionsPerTopic = defaultMaxQuestionsPerTopic,
    this.includeRestDays = false,
    this.restDayFrequency = defaultPlanDurationDays,
  });
}

class PersonalLearningPlanService {
  static final Logger _logger = const Logger('PersonalLearningPlanService');
  final MasteryGraphService _masteryService;
  final MasteryGraphRepository _repository;
  final TopicRepository _topicRepository;
  final PlanRepository _planRepository;
  final PlanAdherenceRepository _adherenceRepository;
  final QuestionRepository _questionRepository;
  final RoadmapRepository _roadmapRepository;
  final SyllabusResolver? _syllabusResolver;
  PlanGenerationConfig config;
  final AppLocalizations? _l10n;

  PersonalLearningPlanService({
    MasteryGraphService? masteryService,
    MasteryGraphRepository? repository,
    TopicRepository? topicRepository,
    PlanRepository? planRepository,
    PlanAdherenceRepository? adherenceRepository,
    RoadmapRepository? roadmapRepository,
    QuestionRepository? questionRepository,
    SyllabusResolver? syllabusResolver,
    PlanGenerationConfig? config,
    AppLocalizations? l10n,
  })  : _masteryService = masteryService ?? MasteryGraphService(),
        _repository = repository ?? MasteryGraphRepository(),
        _topicRepository = topicRepository ?? TopicRepository(),
        _planRepository = planRepository ?? PlanRepository(),
        _adherenceRepository = adherenceRepository ?? PlanAdherenceRepository(),
        _roadmapRepository = roadmapRepository ?? RoadmapRepository(),
        _questionRepository = questionRepository ?? QuestionRepository(),
        _syllabusResolver = syllabusResolver,
        config = config ?? PlanGenerationConfig(),
        _l10n = l10n;

  Future<Result<PersonalLearningPlan>> generatePlan(
    String studentId, {
    String courseName = '',
  }) async {
    return _buildPlan(studentId: studentId, courseName: courseName);
  }

  Future<Result<PersonalLearningPlan>> generatePlanFromSyllabus({
    required String studentId,
    required List<SyllabusGoal> syllabusGoals,
  }) async {
    return _buildPlan(
      studentId: studentId,
      syllabusGoals: syllabusGoals,
    );
  }

  Future<Result<PersonalLearningPlan>> _buildPlan({
    required String studentId,
    List<SyllabusGoal>? syllabusGoals,
    String courseName = '',
  }) async {
    try {
      await _repository.init();
    } catch (e) {
      return Result.failure(e.toString());
    }
    if (syllabusGoals != null) {
      try {
        await _adherenceRepository.init();
      } catch (e) {
        _logger.w('Failed to initialize adherence repository', e);
      }
    }

    final masteryStatesResult = await _repository.getAllMasteryStates(studentId);
    if (masteryStatesResult.isFailure) {
      return Result.failure(masteryStatesResult.error);
    }

    final allDependenciesResult = await _repository.getAllDependencies();
    if (allDependenciesResult.isFailure) {
      return Result.failure(allDependenciesResult.error);
    }

    var topicMastery = masteryStatesResult.data!;
    final dependencies = allDependenciesResult.data!;
    final dependencyMap = {for (var d in dependencies) d.topicId: d};

    var completedTopicIds = topicMastery
        .where((s) => s.masteryLevel.index >= MasteryLevel.proficient.index)
        .map((s) => s.topicId)
        .toSet();

    if (topicMastery.isEmpty && courseName.isNotEmpty) {
      return _buildEmptyMasteryPlan(
        studentId: studentId,
        courseName: courseName,
      );
    }

    if (topicMastery.isEmpty) {
      return Result.failure(
        'You need to add a subject and its topics before generating a plan.',
      );
    }

    if (courseName.isNotEmpty) {
      try {
        final subjectRepo = SubjectRepository();
        await subjectRepo.init();
        final subjectsResult = await subjectRepo.getAll();
        if (subjectsResult.isSuccess) {
          final matchingSubject = (subjectsResult.data ?? []).where(
          (s) => AnswerComparator.areEquivalent(s.name, courseName),
        ).firstOrNull;
          if (matchingSubject != null) {
            await _topicRepository.init();
            final topicsResult = await _topicRepository.getBySubject(matchingSubject.id);
            if (topicsResult.isSuccess) {
              final subjectTopicIds = (topicsResult.data ?? []).map((t) => t.id).toSet();
              final filteredMastery = topicMastery.where((s) => subjectTopicIds.contains(s.topicId)).toList();
              if (filteredMastery.isNotEmpty) {
                topicMastery = filteredMastery;
                completedTopicIds = topicMastery
                    .where((s) => s.masteryLevel.index >= MasteryLevel.proficient.index)
                    .map((s) => s.topicId)
                    .toSet();
              }
            }
          }
        }
      } catch (e) {
        _logger.w('Failed to resolve subject for mastery filtering', e);
      }
    }

    final allTopics = <String, Topic>{};
    if (syllabusGoals != null) {
      for (final goal in syllabusGoals) {
        final topicsResult = await _topicRepository.getBySubject(goal.subjectId);
        final topics = topicsResult.data ?? [];
        for (final topic in topics) {
          allTopics[topic.id] = topic;
        }
      }
    }

    final recommendations = _buildRecommendations(
      topicMastery: topicMastery,
      dependencyMap: dependencyMap,
      completedTopicIds: completedTopicIds,
    );

    if (syllabusGoals != null) {
      _addSyllabusRecommendations(
        recommendations: recommendations,
        syllabusTopicIds: allTopics.keys.toSet(),
      );
    }

    recommendations.sort((a, b) => b.priority.compareTo(a.priority));

    List<List<String>>? learningLevels;
    final resolver = _syllabusResolver;
    if (resolver != null) {
      try {
        final subjectId = syllabusGoals != null
            ? syllabusGoals.first.subjectId
            : studentId;
        final resolved = await resolver.resolveSyllabus(
          subjectId: subjectId,
          studentId: studentId,
          l10n: _l10n,
        );
        if (resolved.isSuccess && resolved.data!.isNotEmpty) {
          learningLevels = resolver.buildLearningLevels(resolved.data!);
        }
      } catch (e) {
        _logger.w('Failed to resolve syllabus', e);
      }
    }

    final dailyPlans = await _generateDailyPlans(
      studentId: studentId,
      recommendations: recommendations,
      dependencyMap: dependencyMap,
      completedTopicIds: completedTopicIds,
      learningLevels: learningLevels,
      courseName: courseName,
    );

    final linkedPlans = await _linkQuestionsToDailyPlans(dailyPlans);
    final totalSyllabusTopics = allTopics.isNotEmpty
        ? allTopics.length
        : topicMastery.length;
    final summary = _generateSummary(linkedPlans, recommendations,
        totalSyllabusTopics: totalSyllabusTopics, courseName: courseName);

    final Map<String, List<DailyPlan>> subjectPlansMap = {};
    if (syllabusGoals != null) {
      for (final goal in syllabusGoals) {
        final plansForSubject = linkedPlans.where((plan) =>
            plan.priorityTopics.any((t) => t.subjectId == goal.subjectId)).toList();
        if (plansForSubject.isNotEmpty) {
          subjectPlansMap[goal.subjectId] = plansForSubject;
        }
      }
    }

    final metadata = syllabusGoals != null
        ? <String, dynamic>{
            'syllabus_goals': syllabusGoals.map((g) => g.toJson()).toList(),
            if (subjectPlansMap.isNotEmpty)
              'subject_plans': subjectPlansMap.map(
                (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()),
              ),
          }
        : null;

    final plan = PersonalLearningPlan(
      studentId: studentId,
      generatedAt: DateTime.now(),
      dailyPlans: linkedPlans,
      summary: summary,
      recommendations: recommendations,
      planDurationDays: config.planDurationDays,
      targetMinutesPerDay: config.targetMinutesPerDay,
      targetQuestionsPerDay: config.targetQuestionsPerDay,
      metadata: metadata,
    );

    try {
      await _planRepository.init();
      await _planRepository.savePlan(plan);
    } catch (e) {
      _logger.w('Failed to save generated plan', e);
    }

    return Result.success(plan);
  }

  Future<Result<PersonalLearningPlan>> _buildEmptyMasteryPlan({
    required String studentId,
    required String courseName,
  }) async {
    final now = DateTime.now();
    final dailyPlans = <DailyPlan>[];
    final totalDays = config.planDurationDays;

    String? resolvedSubjectId;
    final realTopics = <Topic>[];
    try {
      final subjectRepo = SubjectRepository();
      await subjectRepo.init();
      final subjectsResult = await subjectRepo.getAll();
      if (subjectsResult.isSuccess) {
        final matchingSubject = (subjectsResult.data ?? []).where(
          (s) => AnswerComparator.areEquivalent(s.name, courseName),
        ).firstOrNull;
        if (matchingSubject != null) {
          resolvedSubjectId = matchingSubject.id;
          await _topicRepository.init();
          final topicsResult = await _topicRepository.getBySubject(matchingSubject.id);
          if (topicsResult.isSuccess) {
            realTopics.addAll(topicsResult.data ?? []);
          }
        }
      }
    } catch (e) {
      _logger.w('Failed to resolve subject/topics for empty mastery plan', e);
    }

    final bool useRealTopics = resolvedSubjectId != null && realTopics.isNotEmpty;

    final defaultTopicCount = useRealTopics
        ? realTopics.length
        : (totalDays / 7).ceil().clamp(3, 20);

    final topicNames = <String>[];
    if (useRealTopics) {
      for (final topic in realTopics) {
        topicNames.add(topic.title);
      }
    } else {
      for (var i = 1; i <= defaultTopicCount; i++) {
        topicNames.add('$courseName - Topic $i');
      }
    }

    for (var day = 1; day <= totalDays; day++) {
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

      final topicIndex = (day - 1) % topicNames.length;
      final topicId = useRealTopics
          ? realTopics[topicIndex].id
          : 'generated_${day}_$studentId';
      final effectiveSubjectId = resolvedSubjectId ?? '';
      dailyPlans.add(DailyPlan(
        date: now.add(Duration(days: day - 1)),
        dayNumber: day,
        priorityTopics: [
          PlannedTopic(
            topicId: topicId,
            topicTitle: topicNames[topicIndex],
            priority: 1.0,
            reason: 'New topic from $courseName',
            readinessScore: 0.5,
            reviewUrgency: 0.0,
            estimatedQuestions: config.targetQuestionsPerDay,
            estimatedMinutes: config.targetMinutesPerDay.toInt(),
            reasons: ['Part of $courseName curriculum'],
            subjectId: effectiveSubjectId,
          ),
        ],
        reviewQuestionIds: [],
        stretchGoalQuestionIds: [],
        targetQuestions: config.targetQuestionsPerDay,
        targetMinutes: config.targetMinutesPerDay.round(),
        focus: 'Study: ${topicNames[topicIndex]}',
      ));
    }

    final linkedPlans = await _linkQuestionsToDailyPlans(dailyPlans);

    final summary = PlanSummary(
      totalQuestions: config.targetQuestionsPerDay * totalDays,
      totalMinutes: (config.targetMinutesPerDay * totalDays).round(),
      newTopics: topicNames.length,
      reviewTopics: 0,
      estimatedCoverage: useRealTopics ? 0.5 : 0.3,
      focusAreas: topicNames.take(3).toList(),
    );

    final plan = PersonalLearningPlan(
      studentId: studentId,
      generatedAt: now,
      dailyPlans: linkedPlans,
      summary: summary,
      recommendations: [],
      planDurationDays: config.planDurationDays,
      targetMinutesPerDay: config.targetMinutesPerDay,
      targetQuestionsPerDay: config.targetQuestionsPerDay,
      metadata: {
        'course_name': courseName,
        'empty_mastery_fallback': true,
      },
    );

    try {
      await _planRepository.init();
      await _planRepository.savePlan(plan);
    } catch (e) {
      _logger.w('Failed to save empty mastery plan', e);
    }

    return Result.success(plan);
  }

  List<PlanRecommendation> _buildRecommendations({
    required List<MasteryState> topicMastery,
    required Map<String, TopicDependency> dependencyMap,
    required Set<String> completedTopicIds,
  }) {
    return topicMastery.map((state) {
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
        explanations.add(_l10n?.planAccuracyLow ?? 'Accuracy is below 60% — needs focused practice');
      }
      if (state.reviewUrgency > 0.7) {
        explanations.add(_l10n?.planReviewOverdue ?? 'Review is overdue — forgetting risk is high');
      }
      if (state.currentStreak < 3) {
        explanations.add(_l10n?.planStreakLow ?? 'Streak is low — consistency needed');
      }
      if (isPrereq) {
        explanations.add(_l10n?.planPrerequisite ?? 'Prerequisite for upcoming topics — must master first');
      }
      if (downstreamCount > 0) {
        explanations.add(_l10n?.planBlocksDownstream(downstreamCount) ?? 'Blocks $downstreamCount downstream topic(s)');
      }

      return PlanRecommendation(
        topicId: state.topicId,
        reason: _generateRecommendationReason(state),
        recommendationType: _classifyRecommendation(state),
        priority: priority,
        explanations: explanations,
        prerequisiteReason: isPrereq ? (_l10n?.planRequiredForDependent ?? 'Required for dependent topics') : null,
        weaknessReason: state.accuracy < 0.6 ? (_l10n?.planWeakPerformance ?? 'Weak performance') : null,
        reviewReason: state.reviewUrgency > 0.7 ? (_l10n?.planHighForgettingRisk ?? 'High forgetting risk') : null,
      );
    }).toList();
  }

  void _addSyllabusRecommendations({
    required List<PlanRecommendation> recommendations,
    required Set<String> syllabusTopicIds,
  }) {
    for (final topicId in syllabusTopicIds) {
      if (!recommendations.any((r) => r.topicId == topicId)) {
        recommendations.add(PlanRecommendation(
          topicId: topicId,
          reason: _l10n?.planNewSyllabusTopic ?? 'New syllabus topic',
          recommendationType: 'syllabus',
          priority: 1.0,
          explanations: [_l10n?.planPartOfSyllabusGoal ?? 'Part of syllabus goal'],
        ));
      }
    }
  }

  Future<List<DailyPlan>> _linkQuestionsToDailyPlans(
    List<DailyPlan> dailyPlans,
  ) async {
    try {
      await _questionRepository.init();
      final allQuestions = await _questionRepository.getAll();
      final now = DateTime.now();

      return dailyPlans.map((plan) {
        if (plan.isRestDay) return plan;

        final reviewIds = <String>[];
        final stretchIds = <String>[];

        for (final topic in plan.priorityTopics) {
          final allQuestionsList = allQuestions.data ?? [];
        final topicQuestions = allQuestionsList
              .where((q) => q.topicId == topic.topicId)
              .toList();

          if (topic.reviewUrgency > 0.6) {
            final dueQuestions = topicQuestions
                .where((q) =>
                    q.nextReview != null && q.nextReview!.isBefore(now))
                .take(3)
                .map((q) => q.id)
                .toList();
            reviewIds.addAll(dueQuestions);
          }

          if (topic.readinessScore > 0.7) {
            final stretchFromTopic = topicQuestions
                .where((q) => q.difficulty >= 3)
                .take(2)
                .map((q) => q.id)
                .toList();
            stretchIds.addAll(stretchFromTopic);
          }
        }

        return plan.copyWith(
          reviewQuestionIds: reviewIds,
          stretchGoalQuestionIds: stretchIds,
        );
      }).toList();
    } catch (e) {
      _logger.w('Failed to link questions to daily plans', e);
      return dailyPlans;
    }
  }

  Future<Result<void>> recordDailyAdherence({
    required String studentId,
    required int actualQuestions,
    required int actualMinutes,
    String? planId,
  }) async {
    try {
      await _adherenceRepository.init();
      final planResult = await _planRepository.loadPlan(studentId);
      final plan = planResult.data;
      if (plan == null) return Result.success(null);

      final today = DateTime.now();
      final dayNumber = _getPlanDayNumber(plan, today);
      DailyPlan? todayPlan;
      if (dayNumber != null && dayNumber >= 1 && dayNumber <= plan.dailyPlans.length) {
        todayPlan = plan.dailyPlans[dayNumber - 1];
      }

      final plannedQuestions = todayPlan?.targetQuestions ?? 0;
      final plannedMinutes = todayPlan?.targetMinutes ?? 0;

      final adherenceScore = calculateAdherenceScore(
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

      await _adherenceRepository.create(model);

      if (adherenceScore < 0.3 && plannedMinutes > 0) {
        final missedMinutes = plannedMinutes - actualMinutes;
        if (missedMinutes > 0) {
          final result = await redistributeMissedWorkload(studentId, missedMinutes, plan);
          if (result.isFailure) {
            _logger.w('Failed to redistribute missed workload: ${result.error}');
          }
        }
      }

      if (adherenceScore >= 0.5 && todayPlan != null) {
        final completedTopicIds = todayPlan.priorityTopics
            .map((t) => t.topicId)
            .toList();
        if (completedTopicIds.isNotEmpty) {
          await linkDailyPlanToRoadmap(studentId, completedTopicIds);
        }
      }
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to record daily adherence', e);
      return Result.failure(e.toString());
    }
  }

  Future<void> linkDailyPlanToRoadmap(
    String studentId,
    List<String> completedTopicIds,
  ) async {
    await _roadmapRepository.init();
    final roadmapsResult = await _roadmapRepository.getRoadmapsByStudent(studentId);
    final roadmaps = roadmapsResult.data ?? [];
    for (final roadmap in roadmaps) {
      if (roadmap.status == 'completed') continue;
      bool changed = false;
      final updatedMilestones = roadmap.milestones.map((m) {
        if (m.isCompleted) return m;
        final hasAny = completedTopicIds.any((id) => m.topicsCovered.contains(id));
        if (hasAny) {
          changed = true;
          return m.copyWith(isCompleted: true);
        }
        return m;
      }).toList();
      if (changed) {
        final completedCount = updatedMilestones.where((m) => m.isCompleted).length;
        final newPercentage = (completedCount / updatedMilestones.length * 100);
        await _roadmapRepository.saveRoadmap(roadmap.copyWith(
          milestones: updatedMilestones,
          completionPercentage: newPercentage,
          status: newPercentage >= 100 ? 'completed' : roadmap.status,
        ));
      }
    }
  }

  Future<Result<void>> redistributeMissedWorkloadForStudent(
    String studentId,
    int missedMinutes, {
    String strategy = 'days:3',
  }) async {
    try {
      await _planRepository.init();
      final planResult = await _planRepository.loadPlan(studentId);
      final plan = planResult.data;
      if (plan == null) return Result.success(null);
      return redistributeMissedWorkload(studentId, missedMinutes, plan, strategy: strategy);
    } catch (e) {
      _logger.w('Failed to redistribute missed workload for student: $e');
      return Result.failure('PersonalLearningPlanService.redistributeMissedWorkloadForStudent: $e');
    }
  }

  Future<Result<void>> redistributeMissedWorkload(
    String studentId,
    int missedMinutes,
    PersonalLearningPlan plan, {
    String strategy = 'days:3',
  }) async {
    try {
      final now = DateTime.now();
      final todayStart = now.dateOnly;

      int redistributeDays;
      if (strategy == 'all') {
        redistributeDays = plan.dailyPlans.length;
      } else if (strategy.startsWith('days:')) {
        final parsed = int.tryParse(strategy.split(':').last);
        redistributeDays = (parsed ?? 3).clamp(1, plan.dailyPlans.length);
      } else {
        redistributeDays = 3;
      }

      final extraPerDay = (missedMinutes / redistributeDays).ceil();

      final updatedPlans = plan.dailyPlans.map((day) {
        final dDay = day.date.dateOnly;
        if (dDay.isAfter(todayStart) &&
            dDay.difference(todayStart).inDays <= redistributeDays &&
            !day.isRestDay) {
          return day.copyWith(
            targetMinutes: day.targetMinutes + extraPerDay,
          );
        }
        return day;
      }).toList();

      final updated = plan.copyWith(dailyPlans: updatedPlans);
      await _planRepository.savePlan(updated);
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to save redistributed plan', e);
      return Result.failure('PersonalLearningPlanService.redistributeMissedWorkload: $e');
    }
  }

  Future<Result<void>> extendPlan(String studentId, int extraDays) async {
    try {
      await _planRepository.init();
      final planResult = await _planRepository.loadPlan(studentId);
      final plan = planResult.data;
      if (plan == null) return Result.success(null);

      final lastDay = plan.dailyPlans.last.date;
      final newPlans = <DailyPlan>[];
      var nextDayNumber = plan.dailyPlans.length + 1;

      for (var i = 1; i <= extraDays; i++) {
        final date = lastDay.add(Duration(days: i));
        newPlans.add(DailyPlan(
          date: date,
          dayNumber: nextDayNumber++,
          priorityTopics: [],
          reviewQuestionIds: [],
          stretchGoalQuestionIds: [],
          targetQuestions: plan.targetQuestionsPerDay,
          targetMinutes: plan.targetMinutesPerDay.round(),
          focus: 'Extended study day',
        ));
      }

      final updated = plan.copyWith(
        dailyPlans: [...plan.dailyPlans, ...newPlans],
        planDurationDays: plan.planDurationDays + extraDays,
      );

      await _planRepository.savePlan(updated);
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to save extended plan', e);
      return Result.failure('PersonalLearningPlanService.extendPlan: $e');
    }
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


  Future<List<DailyPlan>> _generateDailyPlans({
    required String studentId,
    required List<PlanRecommendation> recommendations,
    required Map<String, TopicDependency> dependencyMap,
    required Set<String> completedTopicIds,
    List<List<String>>? learningLevels,
    String courseName = '',
  }) async {
    final dailyPlans = <DailyPlan>[];
    final now = DateTime.now();

    var recommendationIndex = 0;
    final questionsPerTopic = <String, int>{};

    final topicLevelMap = <String, int>{};
    if (learningLevels != null) {
      for (var level = 0; level < learningLevels.length; level++) {
        for (final topicId in learningLevels[level]) {
          topicLevelMap[topicId] = level;
        }
      }
    }

    final sortedRecs = List<PlanRecommendation>.from(recommendations);
    if (topicLevelMap.isNotEmpty) {
      sortedRecs.sort((a, b) {
        final aLevel = topicLevelMap[a.topicId] ?? 999;
        final bLevel = topicLevelMap[b.topicId] ?? 999;
        final levelCmp = aLevel.compareTo(bLevel);
        if (levelCmp != 0) return levelCmp;
        return b.priority.compareTo(a.priority);
      });
    }

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
          focus: _l10n?.planRestAndReview ?? 'Rest and review',
          isRestDay: true,
        ));
        continue;
      }

      final priorityTopics = <PlannedTopic>[];
      final reviewQuestionIds = <String>[];
      final stretchGoalQuestionIds = <String>[];

      var questionsToday = 0;
      var minutesToday = 0.0;

      while (recommendationIndex < sortedRecs.length &&
             questionsToday < config.targetQuestionsPerDay &&
             minutesToday < config.targetMinutesPerDay) {
        final rec = sortedRecs[recommendationIndex];
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
        final subjectId = await _getSubjectId(rec.topicId);

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
          subjectId: subjectId,
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
        focus: _generateFocus(priorityTopics, courseName: courseName),
      ));
    }

    return dailyPlans;
  }

  String _generateRecommendationReason(MasteryState state) {
    final l10n = _l10n;
    return planRecommendationReason(state.accuracy, state.reviewUrgency, l10n!);
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
      final topicResult = await _topicRepository.get(topicId);
      return topicResult.data?.title ?? topicId;
    } catch (e) {
      _logger.w('Failed to get topic title', e);
      return topicId;
    }
  }

  Future<double> _getReadinessScore(String topicId) async {
    try {
      final studentId = _getStudentId();
      final result = await _masteryService.getReadinessScore(studentId, topicId);
      return result.isSuccess ? result.data! : 0.5;
    } catch (e) {
      _logger.w('Failed to get readiness score', e);
      return 0.5;
    }
  }

  Future<double> _getReviewUrgency(String topicId) async {
    try {
      final studentId = _getStudentId();
      final result = await _masteryService.getReviewUrgency(studentId, topicId);
      return result.isSuccess ? result.data! : 0.3;
    } catch (e) {
      _logger.w('Failed to get review urgency', e);
      return 0.3;
    }
  }

  Future<String> _getSubjectId(String topicId) async {
    try {
      final topicResult = await _topicRepository.get(topicId);
      return topicResult.data?.subjectId ?? '';
    } catch (e) {
      _logger.w('Failed to get subject ID', e);
      return '';
    }
  }

  String _getStudentId() => StudentIdService().getStudentId();

  String _generateFocus(List<PlannedTopic> topics, {String courseName = ''}) {
    final l10n = _l10n;
    final prefix = courseName.isNotEmpty ? '$courseName: ' : '';
    if (topics.isEmpty) return '$prefix${planFocusLabel(isEmpty: true, weakRatio: 0, l10n: l10n!)}';
    final weakCount = topics.where((t) => t.reviewUrgency > 0.6).length;
    return '$prefix${planFocusLabel(isEmpty: false, weakRatio: weakCount / topics.length, l10n: l10n!)}';
  }

  PlanSummary _generateSummary(
    List<DailyPlan> dailyPlans,
    List<PlanRecommendation> recommendations, {
    int totalSyllabusTopics = 0,
    String courseName = '',
  }) {
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
      estimatedCoverage: _calculateCoverage(uniqueTopics.length, totalSyllabusTopics),
      focusAreas: focusAreas,
    );
  }

  double _calculateCoverage(int uniqueTopics, int totalSyllabusTopics) {
    if (totalSyllabusTopics > 0) {
      return (uniqueTopics / totalSyllabusTopics).clamp(0.0, 1.0);
    }
    return uniqueTopics > 0 ? 1.0 : 0.0;
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
    } catch (e) {
      _logger.w('Failed to get current adherence', e);
      return 0.0;
    }
  }

  Future<int> getConsecutiveLowAdherenceDays(String studentId) async {
    try {
      await _adherenceRepository.init();
      return _adherenceRepository.getConsecutiveLowAdherenceDays(studentId);
    } catch (e) {
      _logger.w('Failed to get consecutive low adherence days', e);
      return 0;
    }
  }
}
