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

    test('exports questions features', () {
      expect(QuestionCardWidget, isNotNull);
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
  });
}
