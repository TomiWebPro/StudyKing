import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/services/action_planner.dart';

class _ConcreteActionPlanner extends ActionPlanner {
  bool scheduleLessonCalled = false;
  bool cancelLessonCalled = false;
  bool suggestPlanRegenerationCalled = false;

  @override
  Future<bool> scheduleLesson({
    required String topicId,
    required String topicTitle,
    required String subjectId,
    required DateTime scheduledTime,
    int durationMinutes = 30,
  }) async {
    scheduleLessonCalled = true;
    return true;
  }

  @override
  Future<bool> cancelLesson(String sessionId) async {
    cancelLessonCalled = true;
    return true;
  }

  @override
  Future<bool> suggestPlanRegeneration({
    required String studentId,
    required double adjustmentFactor,
  }) async {
    suggestPlanRegenerationCalled = true;
    return true;
  }
}

class _FailingActionPlanner extends ActionPlanner {
  @override
  Future<bool> scheduleLesson({
    required String topicId,
    required String topicTitle,
    required String subjectId,
    required DateTime scheduledTime,
    int durationMinutes = 30,
  }) async {
    throw Exception('Schedule failed');
  }

  @override
  Future<bool> cancelLesson(String sessionId) async {
    throw Exception('Cancel failed');
  }

  @override
  Future<bool> suggestPlanRegeneration({
    required String studentId,
    required double adjustmentFactor,
  }) async {
    throw Exception('Regeneration failed');
  }
}

void main() {
  group('ActionPlanner contract', () {
    test('scheduleLesson returns true on success', () async {
      final planner = _ConcreteActionPlanner();
      final result = await planner.scheduleLesson(
        topicId: 'topic-1',
        topicTitle: 'Algebra',
        subjectId: 'subj-1',
        scheduledTime: DateTime(2026, 6, 1, 10, 0),
      );
      expect(result, isTrue);
      expect(planner.scheduleLessonCalled, isTrue);
    });

    test('scheduleLesson accepts custom durationMinutes', () async {
      final planner = _ConcreteActionPlanner();
      final result = await planner.scheduleLesson(
        topicId: 'topic-1',
        topicTitle: 'Algebra',
        subjectId: 'subj-1',
        scheduledTime: DateTime(2026, 6, 1, 10, 0),
        durationMinutes: 60,
      );
      expect(result, isTrue);
    });

    test('cancelLesson returns true on success', () async {
      final planner = _ConcreteActionPlanner();
      final result = await planner.cancelLesson('session-1');
      expect(result, isTrue);
      expect(planner.cancelLessonCalled, isTrue);
    });

    test('suggestPlanRegeneration returns true on success', () async {
      final planner = _ConcreteActionPlanner();
      final result = await planner.suggestPlanRegeneration(
        studentId: 'student-1',
        adjustmentFactor: 0.8,
      );
      expect(result, isTrue);
      expect(planner.suggestPlanRegenerationCalled, isTrue);
    });

    test('scheduleLesson propagates exceptions from implementation', () async {
      final planner = _FailingActionPlanner();
      expect(
        () => planner.scheduleLesson(
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          subjectId: 'subj-1',
          scheduledTime: DateTime(2026, 6, 1, 10, 0),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('cancelLesson propagates exceptions from implementation', () async {
      final planner = _FailingActionPlanner();
      expect(
        () => planner.cancelLesson('session-1'),
        throwsA(isA<Exception>()),
      );
    });

    test('suggestPlanRegeneration propagates exceptions', () async {
      final planner = _FailingActionPlanner();
      expect(
        () => planner.suggestPlanRegeneration(
          studentId: 'student-1',
          adjustmentFactor: 0.8,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
