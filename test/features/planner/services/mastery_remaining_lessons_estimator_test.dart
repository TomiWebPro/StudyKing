import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/features/planner/services/mastery_remaining_lessons_estimator.dart';

void main() {
  group('MasteryRemainingLessonsEstimator.estimateForTopic', () {
    test('novice with no signals needs the full level climb', () {
      final result = MasteryRemainingLessonsEstimator.estimateForTopic(
        const RemainingLessonsTopicInput(masteryLevel: MasteryLevel.novice),
      );
      expect(result.isSuccess, isTrue);
      // 4 level transitions (novice -> browsing -> developing -> proficient
      // -> expert) * 4 lessons each = 16.
      expect(result.data!.lessonsRemaining, 16);
      expect(result.data!.masteryProgress, closeTo(0.0, 0.0001));
    });

    test('expert with no weak signals needs zero lessons', () {
      final result = MasteryRemainingLessonsEstimator.estimateForTopic(
        const RemainingLessonsTopicInput(
          masteryLevel: MasteryLevel.expert,
          accuracy: 1.0,
        ),
      );
      expect(result.data!.lessonsRemaining, 0);
      expect(result.data!.masteryProgress, closeTo(1.0, 0.0001));
    });

    test('proficient topic (near-complete) needs few lessons', () {
      final result = MasteryRemainingLessonsEstimator.estimateForTopic(
        const RemainingLessonsTopicInput(
          masteryLevel: MasteryLevel.proficient,
          accuracy: 0.95,
        ),
      );
      // one remaining level * 4 lessons = 4.
      expect(result.data!.lessonsRemaining, 4);
      expect(result.data!.masteryProgress, closeTo((3 + 0.95) / 5, 0.0001));
    });

    test('developing topic with low accuracy and weak subtopics adds corrective lessons', () {
      final result = MasteryRemainingLessonsEstimator.estimateForTopic(
        const RemainingLessonsTopicInput(
          masteryLevel: MasteryLevel.developing,
          accuracy: 0.4,
          reviewUrgency: 0.8,
          forgettingRisk: 0.9,
          weakSubtopics: 2,
          dueQuestionCount: 7,
        ),
      );
      // base: 2 levels * 4 = 8
      // corrective: weak 2*1=2, due ceil(7/5)=2, lowAcc 2, review 1, forgetting 1
      expect(result.data!.lessonsRemaining, 8 + 2 + 2 + 2 + 1 + 1);
    });

    test('due questions convert to lessons via questionsPerLesson', () {
      final noDue = MasteryRemainingLessonsEstimator.estimateForTopic(
        const RemainingLessonsTopicInput(
          masteryLevel: MasteryLevel.developing,
          dueQuestionCount: 0,
        ),
      );
      final withDue = MasteryRemainingLessonsEstimator.estimateForTopic(
        const RemainingLessonsTopicInput(
          masteryLevel: MasteryLevel.developing,
          dueQuestionCount: 5,
        ),
      );
      expect(withDue.data!.lessonsRemaining - noDue.data!.lessonsRemaining, 1);
    });

    test('fromMasteryState maps weak subtopics from state', () {
      final state = MasteryState(
        studentId: 's',
        topicId: 't',
        masteryLevel: MasteryLevel.browsing,
        weakSubtopics: const ['a', 'b', 'c'],
        lastAttempt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      final input = RemainingLessonsTopicInput.fromMasteryState(state);
      expect(input.weakSubtopics, 3);
      expect(input.masteryLevel, MasteryLevel.browsing);
    });
  });

  group('MasteryRemainingLessonsEstimator.estimateForSubject', () {
    test('empty topic list yields zero lessons and zero progress', () {
      final result = MasteryRemainingLessonsEstimator.estimateForSubject(
        [],
        syllabusTopicCount: 0,
      );
      expect(result.isSuccess, isTrue);
      expect(result.data!.lessonsRemaining, 0);
      expect(result.data!.masteryProgress, 0.0);
    });

    test('partial mastery: one developing topic', () {
      final result = MasteryRemainingLessonsEstimator.estimateForSubject([
        const RemainingLessonsTopicInput(
          masteryLevel: MasteryLevel.developing,
          accuracy: 0.5,
        ),
      ]);
      // base: 2 levels * 4 = 8; low accuracy (0.5 > 0 and < 0.6) adds 2.
      expect(result.data!.lessonsRemaining, 10);
      expect(result.data!.masteryProgress, closeTo((2 + 0.5) / 5, 0.0001));
    });

    test('syllabus coverage adds full lessons for uncovered topics', () {
      final result = MasteryRemainingLessonsEstimator.estimateForSubject(
        [
          const RemainingLessonsTopicInput(
            masteryLevel: MasteryLevel.expert,
            accuracy: 1.0,
          ),
        ],
        syllabusTopicCount: 4,
      );
      // 1 covered (0 remaining) + 3 uncovered novice topics * (4*4=16) = 48.
      expect(result.data!.lessonsRemaining, 48);
    });

    test('averages progress across covered topics when no syllabus count', () {
      final result = MasteryRemainingLessonsEstimator.estimateForSubject([
        const RemainingLessonsTopicInput(
          masteryLevel: MasteryLevel.expert,
          accuracy: 1.0,
        ),
        const RemainingLessonsTopicInput(
          masteryLevel: MasteryLevel.novice,
          accuracy: 0.0,
        ),
      ]);
      // (1.0 + 0.0) / 2 = 0.5
      expect(result.data!.masteryProgress, closeTo(0.5, 0.0001));
    });
  });
}
