import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/planner/services/planner_service.dart';

class _FakePlannerService extends PlannerService {
  PersonalLearningPlan? _plan;
  List<PlanAdherenceModel> _adherenceRecords = [];
  List<RoadmapModel> _roadmaps = [];
  bool _throwOnLoadPlan = false;
  bool _throwOnLoadRoadmaps = false;

  _FakePlannerService() : super(fixedStudentId: 'test-student');

  void setPlan(PersonalLearningPlan p) => _plan = p;
  void setAdherenceRecords(List<PlanAdherenceModel> records) => _adherenceRecords = records;
  void setRoadmaps(List<RoadmapModel> roadmaps) => _roadmaps = roadmaps;
  void setThrowOnLoadPlan() => _throwOnLoadPlan = true;
  void setThrowOnLoadRoadmaps() => _throwOnLoadRoadmaps = true;

  @override
  Future<Result<PersonalLearningPlan?>> loadExistingPlan() async {
    if (_throwOnLoadPlan) throw Exception('load plan error');
    return Result.success(_plan);
  }

  @override
  Future<Result<List<PlanAdherenceModel>>> getAdherenceRecords() async {
    return Result.success(_adherenceRecords);
  }

  @override
  Future<Result<List<RoadmapModel>>> loadRoadmaps() async {
    if (_throwOnLoadRoadmaps) throw Exception('load roadmaps error');
    return Result.success(_roadmaps);
  }
}

void main() {
  group('syllabusProgressProvider', () {
    test('returns default data when no plan exists', () async {
      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(_FakePlannerService()),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(syllabusProgressProvider('test-student').future);
      expect(data.totalTopics, 0);
      expect(data.completedTopics, 0);
      expect(data.completionPercentage, 0.0);
      expect(data.focusAreas, isEmpty);
    });

    test('returns correct data when plan exists', () async {
      final now = DateTime.now();
      final plan = PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: now,
        dailyPlans: [
          DailyPlan(
            date: now,
            dayNumber: 1,
            priorityTopics: [
              PlannedTopic(topicId: 'topic-1', topicTitle: 'Kinematics', priority: 0.9, reason: 'test', readinessScore: 0.5, reviewUrgency: 0.3, estimatedQuestions: 5, estimatedMinutes: 30, reasons: [], subjectId: 'sub-1'),
              PlannedTopic(topicId: 'topic-2', topicTitle: 'Vectors', priority: 0.7, reason: 'test', readinessScore: 0.5, reviewUrgency: 0.3, estimatedQuestions: 5, estimatedMinutes: 30, reasons: [], subjectId: 'sub-1'),
            ],
            reviewQuestionIds: [],
            stretchGoalQuestionIds: [],
            targetQuestions: 10,
            targetMinutes: 60,
            focus: 'Study',
          ),
        ],
        summary: PlanSummary(
          totalQuestions: 10, totalMinutes: 60, newTopics: 2, reviewTopics: 0, estimatedCoverage: 0.5, focusAreas: ['topic-1'],
        ),
        recommendations: [
          PlanRecommendation(topicId: 'topic-1', reason: 'Weak', recommendationType: 'weakness', priority: 0.9, explanations: [], prerequisiteReason: null, weaknessReason: null, reviewReason: null),
        ],
      );

      final service = _FakePlannerService();
      service.setPlan(plan);
      service.setAdherenceRecords([
        PlanAdherenceModel(
          id: 'adh-1', studentId: 'test-student', date: now,
          plannedMinutes: 60, actualMinutes: 45,
          plannedQuestions: 10, actualQuestions: 8,
          adherenceScore: 0.75,
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(syllabusProgressProvider('test-student').future);
      expect(data.totalTopics, 2);
      expect(data.completedTopics, 2);
      expect(data.completionPercentage, 1.0);
      expect(data.focusAreas, hasLength(1));
      expect(data.focusAreas.first, 'topic-1');
    });

    test('handles exception gracefully', () async {
      final service = _FakePlannerService();
      service.setThrowOnLoadPlan();

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(syllabusProgressProvider('test-student').future);
      expect(data.totalTopics, 0);
      expect(data.completedTopics, 0);
    });
  });

  group('roadmapListProvider', () {
    test('returns empty list when no roadmaps exist', () async {
      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(_FakePlannerService()),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(roadmapListProvider('test-student').future);
      expect(data.roadmaps, isEmpty);
      expect(data.isLoading, false);
    });

    test('returns roadmaps when they exist', () async {
      final service = _FakePlannerService();
      service.setRoadmaps([
        RoadmapModel(id: 'rm-1', studentId: 'test-student', goal: 'Learn Physics', createdAt: DateTime.now()),
        RoadmapModel(id: 'rm-2', studentId: 'test-student', goal: 'Master Math', createdAt: DateTime.now()),
      ]);

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(roadmapListProvider('test-student').future);
      expect(data.roadmaps, hasLength(2));
      expect(data.roadmaps.first.goal, 'Learn Physics');
      expect(data.isLoading, false);
    });

    test('handles exception gracefully', () async {
      final service = _FakePlannerService();
      service.setThrowOnLoadRoadmaps();

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(roadmapListProvider('test-student').future);
      expect(data.roadmaps, isEmpty);
      expect(data.isLoading, false);
    });
  });
}
