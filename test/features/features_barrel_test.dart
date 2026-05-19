import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/features.dart';

void main() {
  group('features barrel', () {
    test('exports dashboard features', () {
      expect(DashboardScreen, isNotNull);
    });

    test('exports focus_mode features', () {
      expect(FocusTimerScreen, isNotNull);
    });

    test('exports ingestion features', () {
      expect(UploadScreen, isNotNull);
    });

    test('exports lessons features', () {
      expect(LessonListScreen, isNotNull);
    });

    test('exports llm_tasks features', () {
      expect(LlmTaskManagerScreen, isNotNull);
    });

    test('exports mentor features', () {
      expect(MentorScreen, isNotNull);
    });

    test('exports planner features', () {
      expect(PlannerScreen, isNotNull);
    });

    test('exports practice features', () {
      expect(PracticeScreen, isNotNull);
    });

    test('exports quickguide features', () {
      expect(QuickGuideScreen, isNotNull);
    });

    test('exports sessions features', () {
      expect(SessionTrackerScreen, isNotNull);
    });

    test('exports settings features', () {
      expect(SettingsScreen, isNotNull);
    });

    test('exports subjects features', () {
      expect(SubjectListScreen, isNotNull);
    });

    test('exports teaching features', () {
      expect(TutorScreen, isNotNull);
    });

    test('can construct MasterySnapshot from re-exported dashboard barrel', () {
      const snapshot = MasterySnapshot(totalTopics: 10, masteredTopics: 5);
      expect(snapshot.totalTopics, 10);
      expect(snapshot.masteredTopics, 5);
      expect(snapshot.isEmpty, isFalse);
    });

    test('can construct FocusSession from re-exported focus_mode barrel', () {
      final session = FocusSession(
        id: 'test-id',
        studentId: 'student-1',
        startTime: DateTime(2025, 1, 15),
        durationMinutes: 30,
      );
      expect(session.id, 'test-id');
      expect(session.toJson()['id'], 'test-id');
      expect(session.toJson()['durationMinutes'], 30);
    });

    test('can construct LlmTaskFilter from re-exported llm_tasks barrel', () {
      const filter = LlmTaskFilter(feature: 'test-feature');
      expect(filter.feature, 'test-feature');
      expect(filter.status, isNull);
    });

    test('can construct BadgeDisplay from re-exported dashboard barrel', () {
      const badge = BadgeDisplay(
        name: 'Streak Master',
        description: 'Completed 7-day streak',
        category: 'streak',
      );
      expect(badge.name, 'Streak Master');
      expect(badge.description, 'Completed 7-day streak');
      expect(badge.category, 'streak');
    });
  });
}
