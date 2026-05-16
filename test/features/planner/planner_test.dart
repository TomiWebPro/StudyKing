import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/planner.dart';

void main() {
  group('planner barrel', () {
    test('exports PersonalLearningPlan', () => expect(PersonalLearningPlan, isNotNull));
    test('exports PlanAdherenceMetric', () => expect(PlanAdherenceMetric, isNotNull));
    test('exports EngagementNudgeRepository', () => expect(EngagementNudgeRepository, isNotNull));
    test('exports PendingActionRepository', () => expect(PendingActionRepository, isNotNull));
    test('exports PlanAdherenceRepository', () => expect(PlanAdherenceRepository, isNotNull));
    test('exports PlanRepository', () => expect(PlanRepository, isNotNull));
    test('exports RoadmapRepository', () => expect(RoadmapRepository, isNotNull));
    test('exports StudentAvailabilityRepository', () => expect(StudentAvailabilityRepository, isNotNull));
    test('exports PlannerScreen', () => expect(PlannerScreen, isNotNull));
    test('exports PlannerService', () => expect(PlannerService, isNotNull));
    test('exports ActionExecutor', () => expect(ActionExecutor, isNotNull));
    test('exports SyllabusResolver', () => expect(SyllabusResolver, isNotNull));
    test('exports PlannerNotifier', () => expect(PlannerNotifier, isNotNull));
    test('exports PlanSummaryCard', () => expect(PlanSummaryCard, isNotNull));
    test('exports DailyPlanCard', () => expect(DailyPlanCard, isNotNull));
    test('exports RoadmapCard', () => expect(RoadmapCard, isNotNull));
    test('exports MilestoneTimeline', () => expect(MilestoneTimeline, isNotNull));
    test('exports PendingActionCard', () => expect(PendingActionCard, isNotNull));
    test('exports LessonBookingSheet', () => expect(LessonBookingSheet, isNotNull));
    test('exports ProgressOverlayWidget', () => expect(ProgressOverlayWidget, isNotNull));
    test('exports CalendarViewWidget', () => expect(CalendarViewWidget, isNotNull));
  });
}
