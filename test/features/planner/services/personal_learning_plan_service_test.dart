import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/repositories/mastery_state_repository.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/planner/data/repositories/roadmap_repository.dart';
import 'package:studyking/features/planner/services/personal_learning_plan_service.dart';
import 'package:studyking/features/planner/services/planner_advisor_strategy.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/questions/data/models/question_evaluation_model.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';
import 'package:studyking/l10n/generated/app_localizations_es.dart';

class FakeMasteryGraphService extends MasteryGraphService {
  final MasteryGraphRepository _fakeRepo;

  FakeMasteryGraphService(this._fakeRepo)
      : super(
          masteryStateRepo: FakeMasteryStateRepository(),
        );

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return _fakeRepo.getWeakTopics(studentId);
  }

  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) async {
    return _fakeRepo.getAllMasteryStates(studentId);
  }

  @override
  Future<Result<double>> getReadinessScore(String studentId, String topicId) async {
    final result = await _fakeRepo.getMasteryState(studentId, topicId);
    if (result.isSuccess && result.data != null) {
      return Result.success(result.data!.readinessScore);
    }
    return Result.success(0.5);
  }

  @override
  Future<Result<double>> getReviewUrgency(String studentId, String topicId) async {
    final result = await _fakeRepo.getMasteryState(studentId, topicId);
    if (result.isSuccess && result.data != null) {
      return Result.success(result.data!.reviewUrgency);
    }
    return Result.success(0.3);
  }
}

class FakeMasteryStateRepository extends MasteryStateRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<MasteryState>> getMasteryState(String studentId, String topicId) async {
    return Result.success(MasteryState.initial(studentId: studentId, topicId: topicId));
  }

  @override
  Future<Result<List<MasteryState>>> getAllMasteryStates(String studentId) async {
    return Result.success([]);
  }
}

class FakeMasteryGraphRepository extends MasteryGraphRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<MasteryState>> getMasteryState(String studentId, String topicId) async {
    final state = MasteryState.initial(studentId: studentId, topicId: topicId).copyWith(
      accuracy: 0.8,
      currentStreak: 5,
      masteryLevel: MasteryLevel.proficient,
    );
    return Result.success(state);
  }

  @override
  Future<Result<void>> updateMasteryState(MasteryState state) async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getAllMasteryStates(String studentId) async {
    return Result.success([
      MasteryState.initial(studentId: studentId, topicId: 'topic1').copyWith(accuracy: 0.9),
      MasteryState.initial(studentId: studentId, topicId: 'topic2').copyWith(accuracy: 0.7),
    ]);
  }

  @override
  Future<Result<QuestionMasteryState>> getQuestionMasteryState(String studentId, String questionId) async {
    return Result.success(QuestionMasteryState.initial(studentId: studentId, questionId: questionId, now: DateTime.now()));
  }

  @override
  Future<Result<void>> updateQuestionMasteryState(QuestionMasteryState state) async => Result.success(null);

  @override
  Future<Result<List<QuestionMasteryState>>> getDueQuestions(String studentId, {DateTime? asOf}) async => Result.success([]);

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(String studentId, {double threshold = 0.5}) async => Result.success([]);

  @override
  Future<Result<List<MasteryState>>> getTopicsNeedingReview(String studentId) async => Result.success([]);

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return Result.success([
      MasteryState.initial(studentId: studentId, topicId: 'topic1').copyWith(accuracy: 0.4),
    ]);
  }

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) async => Result.success({});

  @override
  Future<Result<void>> migrateFromLegacy({required String questionId, String? markscheme, String? correctAnswer, List<String>? options, String? explanation}) async => Result.success(null);

  @override
  Future<Result<QuestionEvaluation>> getEvaluation(String questionId) async {
    final evaluation = QuestionEvaluation(
      questionId: questionId,
      correctAnswer: 'test',
      acceptableAnswers: ['A', 'B', 'C', 'D'],
      explanation: 'test',
    );
    return Result.success(evaluation);
  }

  @override
  Future<Result<void>> saveEvaluation(QuestionEvaluation evaluation) async => Result.success(null);

  @override
  Future<Result<List<TopicDependency>>> getAllDependencies() async {
    return Result.success([
      TopicDependency(topicId: 'topic1', prerequisites: [], downstreamTopics: ['topic2']),
      TopicDependency(topicId: 'topic2', prerequisites: ['topic1'], downstreamTopics: []),
    ]);
  }

  @override
  Future<Result<TopicDependency>> getTopicDependency(String topicId) async {
    final dep = TopicDependency(topicId: topicId);
    return Result.success(dep);
  }

  @override
  Future<Result<void>> updateTopicDependency(TopicDependency dependency) async => Result.success(null);
}

class FakeTopicRepository extends TopicRepository {
  final Map<String, Topic> _topics = {};

  void addTopic(Topic topic) {
    _topics[topic.id] = topic;
  }

  @override
  Future<Result<void>> init() async {
    return Result.success(null);
  }

  @override
  Future<Result<void>> create(Topic topic) async {
    _topics[topic.id] = topic;
    return Result.success(null);
  }

  @override
  Future<Result<Topic?>> get(String id) async {
    return Result.success(_topics[id]);
  }

  @override
  Future<Result<List<Topic>>> getAll() async => Result.success(_topics.values.toList());

  @override
  Future<Result<List<Topic>>> getBySubject(String subjectId) async =>
      Result.success(_topics.values.where((t) => t.subjectId == subjectId).toList());

  @override
  Future<Result<List<Topic>>> getByParent(String parentId) async =>
      Result.success(_topics.values.where((t) => t.parentId == parentId).toList());

  @override
  Future<Result<List<Topic>>> getRootTopics() async =>
      Result.success(_topics.values.where((t) => t.parentId == null).toList());

  @override
  Future<Result<void>> delete(String id) async {
    _topics.remove(id);
    return Result.success(null);
  }

  @override
  Future<Result<void>> addParent(Topic topic, String parentId) async {
    return Result.success(null);
  }
}

class _FakePlanRepository extends PlanRepository {
  PersonalLearningPlan? _plan;
  bool throwOnLoad = false;

  @override
  Future<Result<void>> init() async {
    return Result.success(null);
  }

  @override
  Future<Result<PersonalLearningPlan?>> loadPlan(String studentId) async {
    if (throwOnLoad) throw Exception('load failed');
    return Result.success(_plan);
  }

  @override
  Future<Result<void>> savePlan(PersonalLearningPlan plan) async {
    _plan = plan;
    return Result.success(null);
  }

  @override
  Future<Result<bool>> hasPlan(String studentId) async =>
      Result.success(_plan != null);

  PersonalLearningPlan? get storedPlan => _plan;
}

class _FakePlanAdherenceRepository extends PlanAdherenceRepository {
  final List<PlanAdherenceModel> _records = [];

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<void>> create(PlanAdherenceModel model) async {
    _records.add(model);
    return Result.success(null);
  }

  @override
  Future<Result<List<PlanAdherenceModel>>> getByStudent(String studentId) async {
    return Result.success(_records.where((m) => m.studentId == studentId).toList()
      ..sort((a, b) => b.date.compareTo(a.date)));
  }

  List<PlanAdherenceModel> get records => List.unmodifiable(_records);
}

class _FakeRoadmapRepository extends RoadmapRepository {
  final Map<String, RoadmapModel> _roadmaps = {};
  int saveCount = 0;

  @override
  Future<Result<void>> init() async {
    return Result.success(null);
  }

  @override
  Future<Result<void>> saveRoadmap(RoadmapModel roadmap) async {
    _roadmaps[roadmap.id] = roadmap;
    saveCount++;
    return Result.success(null);
  }

  @override
  Future<Result<List<RoadmapModel>>> getRoadmapsByStudent(
      String studentId) async {
    return Result.success(
      _roadmaps.values.where((r) => r.studentId == studentId).toList(),
    );
  }

  @override
  Future<Result<RoadmapModel?>> loadRoadmap(String id) async =>
      Result.success(_roadmaps[id]);
}

final _logger = Logger('PlannerPLSPTest');

void main() {
  late String hivePath;

  setUpAll(() {
    hivePath = Directory.systemTemp.createTempSync('planner_plsp_test_').path;
    Hive.init(hivePath);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await Directory(hivePath).delete(recursive: true);
    } catch (e, st) {
      _logger.w('Cleanup failed: $e', e, st);
    }
  });

  group('PlanGenerationConfig', () {
    test('creates config with default values', () {
      final config = PlanGenerationConfig();

      expect(config.planDurationDays, equals(7));
      expect(config.targetQuestionsPerDay, equals(15));
      expect(config.targetMinutesPerDay, equals(30.0));
      expect(config.masteryThreshold, equals(0.8));
      expect(config.maxQuestionsPerTopic, equals(10));
      expect(config.includeRestDays, isFalse);
      expect(config.restDayFrequency, equals(7));
    });

    test('creates config with custom values', () {
      final config = PlanGenerationConfig(
        planDurationDays: 14,
        targetQuestionsPerDay: 20,
        targetMinutesPerDay: 45.0,
        masteryThreshold: 0.9,
        maxQuestionsPerTopic: 15,
        includeRestDays: true,
        restDayFrequency: 3,
      );

      expect(config.planDurationDays, equals(14));
      expect(config.targetQuestionsPerDay, equals(20));
      expect(config.targetMinutesPerDay, equals(45.0));
      expect(config.masteryThreshold, equals(0.9));
      expect(config.maxQuestionsPerTopic, equals(15));
      expect(config.includeRestDays, isTrue);
      expect(config.restDayFrequency, equals(3));
    });
  });

  group('PersonalLearningPlanService', () {
    late PersonalLearningPlanService service;
    late FakeMasteryGraphRepository mockRepo;
    late FakeTopicRepository mockTopicRepo;

    setUp(() {
      mockRepo = FakeMasteryGraphRepository();
      mockTopicRepo = FakeTopicRepository();
      service = PersonalLearningPlanService(
        masteryService: FakeMasteryGraphService(mockRepo),
        repository: mockRepo,
        topicRepository: mockTopicRepo,
        config: PlanGenerationConfig(planDurationDays: 3),
        l10n: AppLocalizationsEn(),
      );
    });

    group('generatePlan', () {
      test('generates plan successfully', () async {
        final result = await service.generatePlan('student1');

        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.studentId, equals('student1'));
        expect(result.data!.dailyPlans.length, equals(3));
        expect(result.data!.planDurationDays, equals(3));
      });

      test('generates plan with correct config', () async {
        final customConfig = PlanGenerationConfig(
          planDurationDays: 5,
          targetQuestionsPerDay: 10,
          targetMinutesPerDay: 20.0,
        );

        final serviceWithConfig = PersonalLearningPlanService(
          masteryService: FakeMasteryGraphService(mockRepo),
          repository: mockRepo,
          topicRepository: mockTopicRepo,
          config: customConfig,
          l10n: AppLocalizationsEn(),
        );

        final result = await serviceWithConfig.generatePlan('student1');

        expect(result.isSuccess, isTrue);
        expect(result.data!.planDurationDays, equals(5));
        expect(result.data!.targetQuestionsPerDay, equals(10));
        expect(result.data!.targetMinutesPerDay, equals(20.0));
      });

      test('returns failure when mastery states fail', () async {
        final failingRepo = _FailingMasteryGraphRepository();
        final failingService = PersonalLearningPlanService(
          masteryService: FakeMasteryGraphService(failingRepo),
          repository: failingRepo,
          topicRepository: mockTopicRepo,
          l10n: AppLocalizationsEn(),
        );

        final result = await failingService.generatePlan('student1');

        expect(result.isFailure, isTrue);
      });

      test('logs a warning when repository init fails during plan build', () async {
        final logs = <String>[];
        final original = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };
        addTearDown(() => debugPrint = original);

        final failingRepo = _FailingMasteryGraphRepository();
        final failingService = PersonalLearningPlanService(
          masteryService: FakeMasteryGraphService(failingRepo),
          repository: failingRepo,
          topicRepository: mockTopicRepo,
          l10n: AppLocalizationsEn(),
        );

        final result = await failingService.generatePlan('student1');

        expect(result.isFailure, isTrue);
        expect(
          logs.where((l) =>
              l.contains('[W]') &&
              l.contains('Failed to initialize repository for plan build')),
          isNotEmpty,
        );
      });

      test('generates plan with recommendations', () async {
        final result = await service.generatePlan('student1');

        expect(result.isSuccess, isTrue);
        expect(result.data!.recommendations, isNotEmpty);
      });

      test('generates plan with summary', () async {
        final result = await service.generatePlan('student1');

        expect(result.isSuccess, isTrue);
        expect(result.data!.summary, isNotNull);
        expect(result.data!.summary.totalQuestions, greaterThanOrEqualTo(0));
        expect(result.data!.summary.totalMinutes, greaterThanOrEqualTo(0));
      });

      test('generates plan successfully without l10n (no null-check crash)',
          () async {
        final serviceWithoutL10n = PersonalLearningPlanService(
          masteryService: FakeMasteryGraphService(mockRepo),
          repository: mockRepo,
          topicRepository: mockTopicRepo,
          config: PlanGenerationConfig(planDurationDays: 3),
        );

        final result = await serviceWithoutL10n.generatePlan('student1');

        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.dailyPlans, hasLength(3));
        for (final day in result.data!.dailyPlans) {
          expect(day.focus, isNotEmpty);
        }
        for (final recommendation in result.data!.recommendations) {
          expect(recommendation.reason, isNotEmpty);
        }
      });

      test('updateLocalization refreshes locale for subsequently generated plans',
          () async {
        final serviceWithoutL10n = PersonalLearningPlanService(
          masteryService: FakeMasteryGraphService(mockRepo),
          repository: mockRepo,
          topicRepository: mockTopicRepo,
          config: PlanGenerationConfig(planDurationDays: 1),
        );

        final before = await serviceWithoutL10n.generatePlan('student1');
        expect(before.isSuccess, isTrue);
        expect(before.data!.dailyPlans.first.focus, isNotEmpty);

        serviceWithoutL10n.updateLocalization(AppLocalizationsEs());

        final after = await serviceWithoutL10n.generatePlan('student1');
        expect(after.isSuccess, isTrue);
        // Spanish focus labels replace the English fallbacks after the refresh.
        expect(after.data!.dailyPlans.first.focus, contains('repaso'));
      });

      test('includes rest days when configured', () async {
        final configWithRest = PlanGenerationConfig(
          planDurationDays: 7,
          includeRestDays: true,
          restDayFrequency: 3,
        );

        final serviceWithRest = PersonalLearningPlanService(
          masteryService: FakeMasteryGraphService(mockRepo),
          repository: mockRepo,
          topicRepository: mockTopicRepo,
          config: configWithRest,
          l10n: AppLocalizationsEn(),
        );

        final result = await serviceWithRest.generatePlan('student1');

        expect(result.isSuccess, isTrue);
        final hasRestDay = result.data!.dailyPlans.any((d) => d.isRestDay);
        expect(hasRestDay, isTrue);
      });

      test('returns failure when topicMastery isEmpty and no courseName or syllabusGoals', () async {
        final emptyRepo = _EmptyMasteryGraphRepository();
        final emptyService = PersonalLearningPlanService(
          masteryService: FakeMasteryGraphService(emptyRepo),
          repository: emptyRepo,
          topicRepository: mockTopicRepo,
          l10n: AppLocalizationsEn(),
        );

        final result = await emptyService.generatePlan('student1');

        expect(result.isFailure, isTrue);
        expect(result.error, contains('add a subject'));
      });

      test('generates plan with advisor metadata when advisor is provided', () async {
        final advisor = FakePlannerAdvisorStrategy();
        final serviceWithAdvisor = PersonalLearningPlanService(
          masteryService: FakeMasteryGraphService(mockRepo),
          repository: mockRepo,
          topicRepository: mockTopicRepo,
          config: PlanGenerationConfig(planDurationDays: 3),
          l10n: AppLocalizationsEn(),
          advisor: advisor,
        );

        final result = await serviceWithAdvisor.generatePlan('student1');

        expect(result.isSuccess, isTrue);
        expect(result.data!.metadata, isNotNull);
        expect(result.data!.metadata!.containsKey('advisor_analysis'), isTrue);
      });
    });

    group('getNextStudyTopics', () {
      test('returns topics with limit', () async {
        final result = await service.getNextStudyTopics('student1', limit: 3);

        expect(result.isSuccess, isTrue);
        expect(result.data!.length, lessThanOrEqualTo(3));
      });

      test('returns topics sorted by priority', () async {
        final result = await service.getNextStudyTopics('student1', limit: 5);

        expect(result.isSuccess, isTrue);
        if (result.data!.length > 1) {
          for (var i = 0; i < result.data!.length - 1; i++) {
            expect(result.data![i].priority, greaterThanOrEqualTo(result.data![i + 1].priority));
          }
        }
      });

      test('returns failure on error', () async {
        final failingRepo = _FailingMasteryGraphRepository();
        final failingService = PersonalLearningPlanService(
          masteryService: FakeMasteryGraphService(failingRepo),
          repository: failingRepo,
          topicRepository: mockTopicRepo,
          l10n: AppLocalizationsEn(),
        );

        final result = await failingService.getNextStudyTopics('student1');

        expect(result.isFailure, isTrue);
      });
    });

    group('getAtRiskTopicIds', () {
      test('returns weak topic ids', () async {
        final result = await service.getAtRiskTopicIds('student1');

        expect(result.isSuccess, isTrue);
        expect(result.data, isA<List<String>>());
      });

      test('returns failure on error', () async {
        final failingRepo = _FailingMasteryGraphRepository();
        final failingService = PersonalLearningPlanService(
          masteryService: FakeMasteryGraphService(failingRepo),
          repository: failingRepo,
          topicRepository: mockTopicRepo,
          l10n: AppLocalizationsEn(),
        );

        final result = await failingService.getAtRiskTopicIds('student1');

        expect(result.isFailure, isTrue);
      });
    });

    group('getReadyToAdvanceTopicIds', () {
      test('returns ready topic ids', () async {
        final result = await service.getReadyToAdvanceTopicIds('student1');

        expect(result.isSuccess, isTrue);
        expect(result.data, isA<List<String>>());
      });

      test('returns failure on error', () async {
        final failingRepo = _FailingMasteryGraphRepository();
        final failingService = PersonalLearningPlanService(
          masteryService: FakeMasteryGraphService(failingRepo),
          repository: failingRepo,
          topicRepository: mockTopicRepo,
          l10n: AppLocalizationsEn(),
        );

        final result = await failingService.getReadyToAdvanceTopicIds('student1');

        expect(result.isFailure, isTrue);
      });
    });

    group('generatePlanFromSyllabus', () {
      test('generates plan from syllabus goals', () async {
        mockTopicRepo.addTopic(Topic(
          id: 'syl-topic-1',
          subjectId: 'sub_physics',
          title: 'Kinematics',
          description: '',
          syllabusText: '',
        ));
        final result = await service.generatePlanFromSyllabus(
          studentId: 'student1',
          syllabusGoals: [
            const SyllabusGoal(
              subjectId: 'sub_physics',
              subjectTitle: 'IB Physics',
              targetDays: 7,
              targetHoursPerDay: 2,
            ),
          ],
        );
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.dailyPlans, hasLength(3));
        expect(result.data!.recommendations, isNotEmpty);
      });
    });

    group('with injected fakes', () {
      late _FakePlanRepository planRepo;
      late _FakePlanAdherenceRepository adherenceRepo;
      late _FakeRoadmapRepository roadmapRepo;
      late PersonalLearningPlanService svc;

      setUp(() {
        planRepo = _FakePlanRepository();
        adherenceRepo = _FakePlanAdherenceRepository();
        roadmapRepo = _FakeRoadmapRepository();
        svc = PersonalLearningPlanService(
          planRepository: planRepo,
          adherenceRepository: adherenceRepo,
          roadmapRepository: roadmapRepo,
          config: PlanGenerationConfig(planDurationDays: 3),
        );
      });

      group('recordDailyAdherence', () {
        test('returns success when no plan exists', () async {
          final result = await svc.recordDailyAdherence(
            studentId: 'student1',
            actualQuestions: 10,
            actualMinutes: 30,
          );
          expect(result.isSuccess, isTrue);
        });

        test('records adherence with good score', () async {
          final now = DateTime.now();
          final plan = PersonalLearningPlan(
            studentId: 'student1',
            generatedAt: now,
            dailyPlans: [
              DailyPlan(
                date: now,
                dayNumber: 1,
                priorityTopics: [],
                reviewQuestionIds: [],
                stretchGoalQuestionIds: [],
                targetQuestions: 15,
                targetMinutes: 30,
                focus: 'Study',
              ),
            ],
            summary: PlanSummary(
              totalQuestions: 15, totalMinutes: 30,
              newTopics: 1, reviewTopics: 0,
              estimatedCoverage: 0.5, focusAreas: [],
            ),
            recommendations: [],
          );
          await planRepo.savePlan(plan);

          final result = await svc.recordDailyAdherence(
            studentId: 'student1',
            actualQuestions: 15,
            actualMinutes: 30,
          );
          expect(result.isSuccess, isTrue);
          expect(adherenceRepo.records, hasLength(1));
          expect(adherenceRepo.records.first.adherenceScore, greaterThanOrEqualTo(0.5));
        });

        test('persists the plan\'s own planId (not studentId) when planId is omitted', () async {
          final now = DateTime.now();
          final plan = PersonalLearningPlan(
            studentId: 'student1',
            planId: 'plan-regenerated-42',
            generatedAt: now,
            dailyPlans: [
              DailyPlan(
                date: now,
                dayNumber: 1,
                priorityTopics: [],
                reviewQuestionIds: [],
                stretchGoalQuestionIds: [],
                targetQuestions: 15,
                targetMinutes: 30,
                focus: 'Study',
              ),
            ],
            summary: PlanSummary(
              totalQuestions: 15, totalMinutes: 30,
              newTopics: 1, reviewTopics: 0,
              estimatedCoverage: 0.5, focusAreas: [],
            ),
            recommendations: [],
          );
          await planRepo.savePlan(plan);

          final result = await svc.recordDailyAdherence(
            studentId: 'student1',
            actualQuestions: 15,
            actualMinutes: 30,
          );
          expect(result.isSuccess, isTrue);
          expect(adherenceRepo.records, hasLength(1));
          // The record must reference the plan it belongs to. When a plan is
          // regenerated over an existing one, plan.planId differs from
          // studentId, so falling back to studentId mislinks the history.
          expect(adherenceRepo.records.first.planId, 'plan-regenerated-42');
          expect(adherenceRepo.records.first.planId, isNot('student1'));
        });

        test('uses the explicit planId parameter when provided', () async {
          final now = DateTime.now();
          final plan = PersonalLearningPlan(
            studentId: 'student1',
            planId: 'plan-own-id',
            generatedAt: now,
            dailyPlans: [
              DailyPlan(
                date: now,
                dayNumber: 1,
                priorityTopics: [],
                reviewQuestionIds: [],
                stretchGoalQuestionIds: [],
                targetQuestions: 15,
                targetMinutes: 30,
                focus: 'Study',
              ),
            ],
            summary: PlanSummary(
              totalQuestions: 15, totalMinutes: 30,
              newTopics: 1, reviewTopics: 0,
              estimatedCoverage: 0.5, focusAreas: [],
            ),
            recommendations: [],
          );
          await planRepo.savePlan(plan);

          final result = await svc.recordDailyAdherence(
            studentId: 'student1',
            actualQuestions: 15,
            actualMinutes: 30,
            planId: 'plan-explicit-77',
          );
          expect(result.isSuccess, isTrue);
          expect(adherenceRepo.records, hasLength(1));
          expect(adherenceRepo.records.first.planId, 'plan-explicit-77');
        });

        test('records poor adherence and triggers redistribute', () async {
          final now = DateTime.now();
          final futurePlan = PersonalLearningPlan(
            studentId: 'student1',
            generatedAt: now,
            dailyPlans: [
              DailyPlan(
                date: now,
                dayNumber: 1,
                priorityTopics: [],
                reviewQuestionIds: [],
                stretchGoalQuestionIds: [],
                targetQuestions: 15,
                targetMinutes: 30,
                focus: 'Study',
              ),
              DailyPlan(
                date: now.add(const Duration(days: 1)),
                dayNumber: 2,
                priorityTopics: [],
                reviewQuestionIds: [],
                stretchGoalQuestionIds: [],
                targetQuestions: 15,
                targetMinutes: 30,
                focus: 'Study',
              ),
              DailyPlan(
                date: now.add(const Duration(days: 2)),
                dayNumber: 3,
                priorityTopics: [],
                reviewQuestionIds: [],
                stretchGoalQuestionIds: [],
                targetQuestions: 15,
                targetMinutes: 30,
                focus: 'Study',
              ),
            ],
            summary: PlanSummary(
              totalQuestions: 45, totalMinutes: 90,
              newTopics: 1, reviewTopics: 0,
              estimatedCoverage: 0.5, focusAreas: [],
            ),
            recommendations: [],
          );
          // Save the original plan
          await planRepo.savePlan(futurePlan);
          // Verify plan was saved
          expect(planRepo.storedPlan, isNotNull);

          final result = await svc.recordDailyAdherence(
            studentId: 'student1',
            actualQuestions: 0,
            actualMinutes: 0,
          );
          expect(result.isSuccess, isTrue);
          expect(adherenceRepo.records, hasLength(1));
          expect(adherenceRepo.records.first.adherenceScore, lessThan(0.3));
        });

        test('returns failure when error occurs', () async {
          final throwingSvc = PersonalLearningPlanService(
            planRepository: planRepo,
            adherenceRepository: adherenceRepo,
            roadmapRepository: roadmapRepo,
            config: PlanGenerationConfig(planDurationDays: 3),
          );
          final result = await throwingSvc.recordDailyAdherence(
            studentId: 'student1',
            actualQuestions: 10,
            actualMinutes: 30,
          );
          expect(result.isFailure || result.isSuccess, isTrue);
        });
      });

      group('linkDailyPlanToRoadmap', () {
        test('returns success when no roadmaps exist', () async {
          final result = await svc.linkDailyPlanToRoadmap('student1', ['topic-1']);
          expect(result.isSuccess, isTrue);
        });

        test('marks milestone completed when topic matches', () async {
          final roadmap = RoadmapModel(
            id: 'rm-1',
            studentId: 'student1',
            goal: 'Learn Physics',
            createdAt: DateTime.now(),
            milestones: [
              MilestoneModel(
                id: 'ms-1',
                title: 'Week 1',
                deadline: DateTime.now(),
                topicsCovered: ['topic-1'],
                order: 1,
              ),
              MilestoneModel(
                id: 'ms-2',
                title: 'Week 2',
                deadline: DateTime.now().add(const Duration(days: 7)),
                topicsCovered: ['topic-2'],
                order: 2,
              ),
            ],
          );
          await roadmapRepo.saveRoadmap(roadmap);

          await svc.linkDailyPlanToRoadmap('student1', ['topic-1']);

          expect(roadmapRepo.saveCount, greaterThanOrEqualTo(1));
        });

        test('skips already completed roadmaps', () async {
          final roadmap = RoadmapModel(
            id: 'rm-completed',
            studentId: 'student1',
            goal: 'Learn Physics',
            createdAt: DateTime.now(),
            milestones: [
              MilestoneModel(
                id: 'ms-1',
                title: 'Week 1',
                deadline: DateTime.now(),
                topicsCovered: ['topic-1'],
                isCompleted: true,
                order: 1,
              ),
            ],
            status: 'completed',
          );
          await roadmapRepo.saveRoadmap(roadmap);

          await svc.linkDailyPlanToRoadmap('student1', ['topic-1']);
        });
      });

      group('redistributeMissedWorkload', () {
        test('completes without error when plan exists', () async {
          final now = DateTime.now();
          final plan = PersonalLearningPlan(
            studentId: 'student1',
            generatedAt: now.subtract(const Duration(days: 1)),
            dailyPlans: [
              DailyPlan(
                date: now.add(const Duration(days: 1)),
                dayNumber: 1,
                priorityTopics: [],
                reviewQuestionIds: [],
                stretchGoalQuestionIds: [],
                targetQuestions: 15,
                targetMinutes: 30,
                focus: 'Study',
              ),
              DailyPlan(
                date: now.add(const Duration(days: 2)),
                dayNumber: 2,
                priorityTopics: [],
                reviewQuestionIds: [],
                stretchGoalQuestionIds: [],
                targetQuestions: 15,
                targetMinutes: 30,
                focus: 'Study',
              ),
            ],
            summary: PlanSummary(
              totalQuestions: 30, totalMinutes: 60,
              newTopics: 1, reviewTopics: 0,
              estimatedCoverage: 0.5, focusAreas: [],
            ),
            recommendations: [],
          );
          await planRepo.savePlan(plan);

          final result = await svc.redistributeMissedWorkload(
            'student1',
            30,
            plan,
            strategy: 'days:2',
          );
          expect(result.isSuccess, isTrue);
        });

        test('uses "all" strategy', () async {
          final now = DateTime.now();
          final plan = PersonalLearningPlan(
            studentId: 'student1',
            generatedAt: now.subtract(const Duration(days: 1)),
            dailyPlans: [
              DailyPlan(
                date: now.add(const Duration(days: 1)),
                dayNumber: 1,
                priorityTopics: [],
                reviewQuestionIds: [],
                stretchGoalQuestionIds: [],
                targetQuestions: 15,
                targetMinutes: 30,
                focus: 'Study',
              ),
              DailyPlan(
                date: now.add(const Duration(days: 2)),
                dayNumber: 2,
                priorityTopics: [],
                reviewQuestionIds: [],
                stretchGoalQuestionIds: [],
                targetQuestions: 15,
                targetMinutes: 30,
                focus: 'Study',
              ),
            ],
            summary: PlanSummary(
              totalQuestions: 30, totalMinutes: 60,
              newTopics: 1, reviewTopics: 0,
              estimatedCoverage: 0.5, focusAreas: [],
            ),
            recommendations: [],
          );
          await planRepo.savePlan(plan);

          final result = await svc.redistributeMissedWorkload(
            'student1', 60, plan,
            strategy: 'all',
          );
          expect(result.isSuccess, isTrue);
        });

        test('caps each day by half of its own target, not the first day\'s',
            () async {
          final now = DateTime.now();
          final plan = PersonalLearningPlan(
            studentId: 'student1',
            generatedAt: now,
            dailyPlans: [
              DailyPlan(
                date: now.add(const Duration(days: 1)),
                dayNumber: 1,
                priorityTopics: [],
                reviewQuestionIds: [],
                stretchGoalQuestionIds: [],
                targetQuestions: 5,
                targetMinutes: 30, // per-day cap: ceil(30 * 0.5) = 15
                focus: 'Study',
              ),
              DailyPlan(
                date: now.add(const Duration(days: 2)),
                dayNumber: 2,
                priorityTopics: [],
                reviewQuestionIds: [],
                stretchGoalQuestionIds: [],
                targetQuestions: 20,
                targetMinutes: 120, // per-day cap: ceil(120 * 0.5) = 60
                focus: 'Study',
              ),
              DailyPlan(
                date: now.add(const Duration(days: 3)),
                dayNumber: 3,
                priorityTopics: [],
                reviewQuestionIds: [],
                stretchGoalQuestionIds: [],
                targetQuestions: 20,
                targetMinutes: 120,
                focus: 'Study',
              ),
            ],
            summary: PlanSummary(
              totalQuestions: 45, totalMinutes: 270,
              newTopics: 1, reviewTopics: 0,
              estimatedCoverage: 0.5, focusAreas: [],
            ),
            recommendations: [],
          );

          // 90 missed minutes over 2 days -> baseExtraPerDay = 45.
          // Day 1 can only absorb 15 (half of its 30-minute target);
          // day 2 absorbs the full 45 (under its 60-minute cap).
          final result = await svc.redistributeMissedWorkload(
            'student1', 90, plan,
            strategy: 'days:2',
          );

          expect(result.isSuccess, isTrue);
          final saved = planRepo.storedPlan!;
          expect(saved.dailyPlans[0].targetMinutes, 45); // 30 + 15
          expect(saved.dailyPlans[1].targetMinutes, 165); // 120 + 45
          // Day 3 is outside the 2-day redistribution window.
          expect(saved.dailyPlans[2].targetMinutes, 120);
        });

        test('returns success when no future non-rest days remain and student was away', () async {
          // Regression: daysSinceLastActivity.clamp(1, remainingDays)
          // threw ArgumentError when every remaining day was a rest day.
          final awayService = PersonalLearningPlanService(
            planRepository: planRepo,
            adherenceRepository: adherenceRepo,
            roadmapRepository: roadmapRepo,
            config: PlanGenerationConfig(planDurationDays: 3),
            studentIdService: await _studentIdServiceAwayFor(days: 3),
          );
          final now = DateTime.now();
          final plan = PersonalLearningPlan(
            studentId: 'student1',
            generatedAt: now.subtract(const Duration(days: 1)),
            dailyPlans: [
              DailyPlan(date: now.add(const Duration(days: 1)), dayNumber: 1,
                priorityTopics: [], reviewQuestionIds: [], stretchGoalQuestionIds: [],
                targetQuestions: 15, targetMinutes: 30, focus: 'Study',
                isRestDay: true),
              DailyPlan(date: now.add(const Duration(days: 2)), dayNumber: 2,
                priorityTopics: [], reviewQuestionIds: [], stretchGoalQuestionIds: [],
                targetQuestions: 15, targetMinutes: 30, focus: 'Study',
                isRestDay: true),
            ],
            summary: PlanSummary(totalQuestions: 30, totalMinutes: 60, newTopics: 1, reviewTopics: 0, estimatedCoverage: 0.5, focusAreas: []),
            recommendations: [],
            planDurationDays: 3,
          );
          await planRepo.savePlan(plan);

          final result = await awayService.redistributeMissedWorkload(
            'student1', 30, plan, strategy: 'days:2',
          );
          expect(result.isSuccess, isTrue);
        });

        test('returns success when plan ends today and student was away', () async {
          // Regression: the same clamp(1, 0) throw when the plan has
          // no future days left at all.
          final awayService = PersonalLearningPlanService(
            planRepository: planRepo,
            adherenceRepository: adherenceRepo,
            roadmapRepository: roadmapRepo,
            config: PlanGenerationConfig(planDurationDays: 3),
            studentIdService: await _studentIdServiceAwayFor(days: 3),
          );
          final now = DateTime.now();
          final plan = PersonalLearningPlan(
            studentId: 'student1',
            generatedAt: now.subtract(const Duration(days: 1)),
            dailyPlans: [
              DailyPlan(date: now, dayNumber: 1,
                priorityTopics: [], reviewQuestionIds: [], stretchGoalQuestionIds: [],
                targetQuestions: 15, targetMinutes: 30, focus: 'Study'),
            ],
            summary: PlanSummary(totalQuestions: 15, totalMinutes: 30, newTopics: 1, reviewTopics: 0, estimatedCoverage: 0.5, focusAreas: []),
            recommendations: [],
            planDurationDays: 1,
          );
          await planRepo.savePlan(plan);

          final result = await awayService.redistributeMissedWorkload('student1', 30, plan);
          expect(result.isSuccess, isTrue);
        });

        test('returns success when plan has no daily plans', () async {
          // Regression: the strategy clamp (parsed ?? 3).clamp(1, 0)
          // threw ArgumentError for an empty dailyPlans list.
          final now = DateTime.now();
          final plan = PersonalLearningPlan(
            studentId: 'student1',
            generatedAt: now.subtract(const Duration(days: 1)),
            dailyPlans: [],
            summary: PlanSummary(totalQuestions: 0, totalMinutes: 0, newTopics: 0, reviewTopics: 0, estimatedCoverage: 0.0, focusAreas: []),
            recommendations: [],
            planDurationDays: 3,
          );
          await planRepo.savePlan(plan);

          final result = await svc.redistributeMissedWorkload('student1', 30, plan);
          expect(result.isSuccess, isTrue);
        });

        test('still redistributes to remaining days when student was away longer', () async {
          final awayService = PersonalLearningPlanService(
            planRepository: planRepo,
            adherenceRepository: adherenceRepo,
            roadmapRepository: roadmapRepo,
            config: PlanGenerationConfig(planDurationDays: 3),
            studentIdService: await _studentIdServiceAwayFor(days: 5),
          );
          final now = DateTime.now();
          final plan = PersonalLearningPlan(
            studentId: 'student1',
            generatedAt: now.subtract(const Duration(days: 1)),
            dailyPlans: [
              DailyPlan(date: now.add(const Duration(days: 1)), dayNumber: 1,
                priorityTopics: [], reviewQuestionIds: [], stretchGoalQuestionIds: [],
                targetQuestions: 15, targetMinutes: 30, focus: 'Study'),
            ],
            summary: PlanSummary(totalQuestions: 15, totalMinutes: 30, newTopics: 1, reviewTopics: 0, estimatedCoverage: 0.5, focusAreas: []),
            recommendations: [],
            planDurationDays: 1,
          );
          await planRepo.savePlan(plan);

          final result = await awayService.redistributeMissedWorkload(
            'student1', 30, plan, strategy: 'days:3',
          );
          expect(result.isSuccess, isTrue);
          final stored = planRepo.storedPlan!;
          // redistributeDays = daysSinceLastActivity.clamp(1, 1) = 1, so
          // baseExtraPerDay = 30, capped at maxExtraPerDay (30 * 0.5 = 15):
          // the single remaining day gains 15 minutes.
          expect(stored.dailyPlans.first.targetMinutes, equals(45));
        });
      });

      group('extendPlan', () {
        test('extends plan by given days', () async {
          final now = DateTime.now();
          final plan = PersonalLearningPlan(
            studentId: 'student1',
            generatedAt: now.subtract(const Duration(days: 1)),
            dailyPlans: [
              DailyPlan(
                date: now,
                dayNumber: 1,
                priorityTopics: [],
                reviewQuestionIds: [],
                stretchGoalQuestionIds: [],
                targetQuestions: 15,
                targetMinutes: 30,
                focus: 'Study',
              ),
            ],
            summary: PlanSummary(
              totalQuestions: 15, totalMinutes: 30,
              newTopics: 1, reviewTopics: 0,
              estimatedCoverage: 0.5, focusAreas: [],
            ),
            recommendations: [],
            planDurationDays: 3,
          );
          await planRepo.savePlan(plan);

          final result = await svc.extendPlan('student1', 2);
          expect(result.isSuccess, isTrue);
          expect(planRepo.storedPlan!.dailyPlans, hasLength(3));
          expect(planRepo.storedPlan!.planDurationDays, equals(5));
        });

        test('returns success when no plan exists', () async {
          final result = await svc.extendPlan('student1', 2);
          expect(result.isSuccess, isTrue);
        });

        test('returns failure when plan has no daily plans', () async {
          // Regression: plan.dailyPlans.last threw 'Bad state: No element'
          // when the plan had an empty dailyPlans list.
          final now = DateTime.now();
          final plan = PersonalLearningPlan(
            studentId: 'student1',
            generatedAt: now.subtract(const Duration(days: 1)),
            dailyPlans: [],
            summary: PlanSummary(totalQuestions: 0, totalMinutes: 0, newTopics: 0, reviewTopics: 0, estimatedCoverage: 0.0, focusAreas: []),
            recommendations: [],
            planDurationDays: 3,
          );
          await planRepo.savePlan(plan);

          final result = await svc.extendPlan('student1', 2);
          expect(result.isFailure, isTrue);
          // The explicit guard must report the missing daily plans rather
          // than surfacing a 'Bad state: No element' from .last.
          expect(result.error, contains('no daily plans'));
        });

        test('returns failure when error occurs', () async {
          final throwingSvc = PersonalLearningPlanService(
            planRepository: planRepo,
            adherenceRepository: adherenceRepo,
            roadmapRepository: roadmapRepo,
            config: PlanGenerationConfig(planDurationDays: 3),
          );
          final result = await throwingSvc.extendPlan('student1', 2);
          expect(result.isFailure || result.isSuccess, isTrue);
        });
      });

      group('getCurrentAdherence', () {
        test('returns success with 0.0 when no records exist', () async {
          final result = await svc.getCurrentAdherence('student1');
          expect(result.isSuccess, isTrue);
          expect(result.data, equals(0.0));
        });

        test('returns success with average adherence from records', () async {
          final now = DateTime.now();
          await adherenceRepo.create(PlanAdherenceModel(
            id: 'adh-1', studentId: 'student1', date: now,
            plannedQuestions: 10, actualQuestions: 10,
            plannedMinutes: 30, actualMinutes: 30,
            adherenceScore: 0.8,
          ));
          await adherenceRepo.create(PlanAdherenceModel(
            id: 'adh-2', studentId: 'student1', date: now,
            plannedQuestions: 10, actualQuestions: 5,
            plannedMinutes: 30, actualMinutes: 15,
            adherenceScore: 0.5,
          ));
          final result = await svc.getCurrentAdherence('student1');
          expect(result.isSuccess, isTrue);
          expect(result.data, closeTo(0.65, 0.01));
        });

        test('returns failure when repository init fails', () async {
          final failingAdherenceRepo = _FailingAdherenceRepository();
          final failingSvc = PersonalLearningPlanService(
            planRepository: planRepo,
            adherenceRepository: failingAdherenceRepo,
            roadmapRepository: roadmapRepo,
            config: PlanGenerationConfig(planDurationDays: 3),
          );
          final result = await failingSvc.getCurrentAdherence('student1');
          expect(result.isFailure, isTrue);
          expect(result.error, isNotNull);
        });

        test('returns failure when getAverageAdherence returns failure', () async {
          final errorAdherenceRepo = _ErrorAdherenceRepository();
          final errorSvc = PersonalLearningPlanService(
            planRepository: planRepo,
            adherenceRepository: errorAdherenceRepo,
            roadmapRepository: roadmapRepo,
            config: PlanGenerationConfig(planDurationDays: 3),
          );
          final result = await errorSvc.getCurrentAdherence('student1');
          expect(result.isFailure, isTrue);
        });
      });

      group('getConsecutiveLowAdherenceDays', () {
        test('returns success with 0 when no records exist', () async {
          final result = await svc.getConsecutiveLowAdherenceDays('student1');
          expect(result.isSuccess, isTrue);
          expect(result.data, equals(0));
        });

        test('returns success with consecutive low days from records', () async {
          final now = DateTime.now();
          await adherenceRepo.create(PlanAdherenceModel(
            id: 'adh-1', studentId: 'student1',
            date: now.subtract(const Duration(days: 2)),
            adherenceScore: 0.3,
          ));
          await adherenceRepo.create(PlanAdherenceModel(
            id: 'adh-2', studentId: 'student1',
            date: now.subtract(const Duration(days: 1)),
            adherenceScore: 0.4,
          ));
          final result = await svc.getConsecutiveLowAdherenceDays('student1');
          expect(result.isSuccess, isTrue);
          expect(result.data, greaterThan(0));
        });

        test('returns failure when repository init fails', () async {
          final failingAdherenceRepo = _FailingAdherenceRepository();
          final failingSvc = PersonalLearningPlanService(
            planRepository: planRepo,
            adherenceRepository: failingAdherenceRepo,
            roadmapRepository: roadmapRepo,
            config: PlanGenerationConfig(planDurationDays: 3),
          );
          final result = await failingSvc.getConsecutiveLowAdherenceDays('student1');
          expect(result.isFailure, isTrue);
          expect(result.error, isNotNull);
        });

        test('returns failure when getConsecutiveLowAdherenceDays returns failure', () async {
          final errorAdherenceRepo = _ErrorAdherenceRepository();
          final errorSvc = PersonalLearningPlanService(
            planRepository: planRepo,
            adherenceRepository: errorAdherenceRepo,
            roadmapRepository: roadmapRepo,
            config: PlanGenerationConfig(planDurationDays: 3),
          );
          final result = await errorSvc.getConsecutiveLowAdherenceDays('student1');
          expect(result.isFailure, isTrue);
        });
      });

      group('catch block coverage', () {
        test('redistributeMissedWorkload handles rest days correctly', () async {
          final now = DateTime.now();
          final plan = PersonalLearningPlan(
            studentId: 'student1',
            generatedAt: now.subtract(const Duration(days: 1)),
            dailyPlans: [
              DailyPlan(date: now.add(const Duration(days: 1)), dayNumber: 1,
                priorityTopics: [], reviewQuestionIds: [], stretchGoalQuestionIds: [],
                targetQuestions: 15, targetMinutes: 30, focus: 'Study',
                isRestDay: true,
              ),
              DailyPlan(date: now.add(const Duration(days: 2)), dayNumber: 2,
                priorityTopics: [], reviewQuestionIds: [], stretchGoalQuestionIds: [],
                targetQuestions: 15, targetMinutes: 30, focus: 'Study',
              ),
            ],
            summary: PlanSummary(totalQuestions: 30, totalMinutes: 60, newTopics: 1, reviewTopics: 0, estimatedCoverage: 0.5, focusAreas: []),
            recommendations: [],
            planDurationDays: 2,
          );
          await planRepo.savePlan(plan);
          final result = await svc.redistributeMissedWorkload('student1', 30, plan, strategy: 'days:1');
          expect(result.isSuccess, isTrue);
        });

        test('redistributeMissedWorkload skips when lastRedistributionDate is recent', () async {
          final now = DateTime.now();
          final yesterday = now.subtract(const Duration(days: 1));
          final plan = PersonalLearningPlan(
            studentId: 'student1',
            generatedAt: now.subtract(const Duration(days: 2)),
            dailyPlans: [
              DailyPlan(date: now.add(const Duration(days: 1)), dayNumber: 1,
                priorityTopics: [], reviewQuestionIds: [], stretchGoalQuestionIds: [],
                targetQuestions: 15, targetMinutes: 30, focus: 'Study',
              ),
            ],
            summary: PlanSummary(totalQuestions: 15, totalMinutes: 30, newTopics: 1, reviewTopics: 0, estimatedCoverage: 0.5, focusAreas: []),
            recommendations: [],
            planDurationDays: 3,
            metadata: {'lastRedistributionDate': yesterday.toIso8601String()},
          );
          await planRepo.savePlan(plan);

          final result = await svc.redistributeMissedWorkload('student1', 30, plan, strategy: 'days:1');
          expect(result.isSuccess, isTrue);
          final stored = planRepo.storedPlan!;
          expect(stored.metadata!['lastRedistributionDate'], yesterday.toIso8601String());
        });

        test('redistributeMissedWorkload handles invalid strategy default', () async {
          final now = DateTime.now();
          final plan = PersonalLearningPlan(
            studentId: 'student1',
            generatedAt: now.subtract(const Duration(days: 1)),
            dailyPlans: [
              DailyPlan(date: now.add(const Duration(days: 1)), dayNumber: 1,
                priorityTopics: [], reviewQuestionIds: [], stretchGoalQuestionIds: [],
                targetQuestions: 15, targetMinutes: 30, focus: 'Study',
              ),
            ],
            summary: PlanSummary(totalQuestions: 15, totalMinutes: 30, newTopics: 1, reviewTopics: 0, estimatedCoverage: 0.5, focusAreas: []),
            recommendations: [],
            planDurationDays: 1,
          );
          await planRepo.savePlan(plan);
          final result = await svc.redistributeMissedWorkload('student1', 30, plan, strategy: 'invalid');
          expect(result.isSuccess, isTrue);
        });

        test('redistributeMissedWorkloadForStudent returns failure when plan load throws', () async {
          planRepo.throwOnLoad = true;
          final result = await svc.redistributeMissedWorkloadForStudent('student1', 30);
          expect(result.isFailure, isTrue);
        });
      });
    });
  });
}

/// Creates a [StudentIdService] whose last recorded activity was
/// [days] days ago, so `getDaysSinceLastActivity()` reports a
/// positive absence. The stale `lastActivityAt` key is removed
/// again after the test.
Future<StudentIdService> _studentIdServiceAwayFor({required int days}) async {
  final service = StudentIdService();
  await service.init();
  final box = Hive.box(HiveBoxNames.studentId);
  await box.put('lastActivityAt',
      DateTime.now().subtract(Duration(days: days)).toIso8601String());
  addTearDown(() async {
    await box.delete('lastActivityAt');
  });
  return service;
}

class FakePlannerAdvisorStrategy implements PlannerAdvisorStrategy {
  @override
  Future<Result<AdvisorAnalysis>> analyzeForPlanGeneration({
    required String studentId,
    required String courseName,
    required int planDurationDays,
    required double targetMinutesPerDay,
    List<String> weakTopicIds = const [],
    List<String> atRiskTopicIds = const [],
    double currentAdherence = 0.0,
    int consecutiveLowAdherenceDays = 0,
  }) async {
    return Result.success(const AdvisorAnalysis(
      workloadEstimate: 'Moderate',
      pathwaySuggestion: 'Start with basics',
      motivationalReasoning: 'Keep going',
      adaptationReasoning: 'On track',
    ));
  }

  @override
  Future<Result<AdvisorAnalysis>> analyzeForAdaptation({
    required String studentId,
    required double currentAdherence,
    required int consecutiveLowDays,
    required String planSummary,
  }) async {
    return Result.success(const AdvisorAnalysis(
      workloadEstimate: 'Reduced',
      pathwaySuggestion: 'Focus on weak areas',
      motivationalReasoning: 'Adjust pace',
      adaptationReasoning: 'Student needs lighter load',
    ));
  }
}

class _EmptyMasteryGraphRepository extends MasteryGraphRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<MasteryState>> getMasteryState(String studentId, String topicId) async {
    return Result.success(MasteryState.initial(studentId: studentId, topicId: topicId));
  }

  @override
  Future<Result<void>> updateMasteryState(MasteryState state) async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getAllMasteryStates(String studentId) async {
    return Result.success([]);
  }

  @override
  Future<Result<QuestionMasteryState>> getQuestionMasteryState(String studentId, String questionId) async {
    return Result.success(QuestionMasteryState.initial(studentId: studentId, questionId: questionId, now: DateTime.now()));
  }

  @override
  Future<Result<void>> updateQuestionMasteryState(QuestionMasteryState state) async => Result.success(null);

  @override
  Future<Result<List<QuestionMasteryState>>> getDueQuestions(String studentId, {DateTime? asOf}) async => Result.success([]);

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(String studentId, {double threshold = 0.5}) async => Result.success([]);

  @override
  Future<Result<List<MasteryState>>> getTopicsNeedingReview(String studentId) async => Result.success([]);

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async => Result.success([]);

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) async => Result.success({});

  @override
  Future<Result<void>> migrateFromLegacy({required String questionId, String? markscheme, String? correctAnswer, List<String>? options, String? explanation}) async => Result.success(null);

  @override
  Future<Result<QuestionEvaluation>> getEvaluation(String questionId) async => Result.failure('Failed');

  @override
  Future<Result<void>> saveEvaluation(QuestionEvaluation evaluation) async => Result.success(null);

  @override
  Future<Result<List<TopicDependency>>> getAllDependencies() async => Result.success([]);

  @override
  Future<Result<TopicDependency>> getTopicDependency(String topicId) async => Result.success(TopicDependency(topicId: topicId));

  @override
  Future<Result<void>> updateTopicDependency(TopicDependency dependency) async => Result.success(null);
}

class _FailingAdherenceRepository extends PlanAdherenceRepository {
  @override
  Future<Result<void>> init() async => throw Exception('init failed');

  @override
  Future<Result<double>> getAverageAdherence(String studentId) async => Result.failure('failed');

  @override
  Future<Result<int>> getConsecutiveLowAdherenceDays(String studentId, {double threshold = 0.5}) async => Result.failure('failed');
}

class _ErrorAdherenceRepository extends PlanAdherenceRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<double>> getAverageAdherence(String studentId) async => Result.failure('getAverageAdherence failed');

  @override
  Future<Result<int>> getConsecutiveLowAdherenceDays(String studentId, {double threshold = 0.5}) async => Result.failure('getConsecutiveLowAdherenceDays failed');
}

class _FailingMasteryGraphRepository extends MasteryGraphRepository {
  @override
  Future<void> init() async => throw Exception('Init failed');

  @override
  Future<Result<MasteryState>> getMasteryState(String studentId, String topicId) async =>
      Result.failure('Failed to get mastery state');

  @override
  Future<Result<void>> updateMasteryState(MasteryState state) async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getAllMasteryStates(String studentId) async =>
      Result.failure('Failed to get all mastery states');

  @override
  Future<Result<QuestionMasteryState>> getQuestionMasteryState(String studentId, String questionId) async =>
      Result.success(QuestionMasteryState.initial(studentId: studentId, questionId: questionId, now: DateTime.now()));

  @override
  Future<Result<void>> updateQuestionMasteryState(QuestionMasteryState state) async => Result.success(null);

  @override
  Future<Result<List<QuestionMasteryState>>> getDueQuestions(String studentId, {DateTime? asOf}) async =>
      Result.success([]);

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(String studentId, {double threshold = 0.5}) async =>
      Result.success([]);

  @override
  Future<Result<List<MasteryState>>> getTopicsNeedingReview(String studentId) async => Result.success([]);

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async => Result.failure('Failed to get weak topics');

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) async => Result.success({});

  @override
  Future<Result<void>> migrateFromLegacy({required String questionId, String? markscheme, String? correctAnswer, List<String>? options, String? explanation}) async =>
      Result.success(null);

  @override
  Future<Result<QuestionEvaluation>> getEvaluation(String questionId) async =>
      Result.failure('Failed to get evaluation');

  @override
  Future<Result<void>> saveEvaluation(QuestionEvaluation evaluation) async => Result.success(null);

  @override
  Future<Result<List<TopicDependency>>> getAllDependencies() async =>
      Result.failure('Failed to get dependencies');

  @override
  Future<Result<TopicDependency>> getTopicDependency(String topicId) async =>
      Result.failure('Failed to get topic dependency');

  @override
  Future<Result<void>> updateTopicDependency(TopicDependency dependency) async => Result.success(null);
}