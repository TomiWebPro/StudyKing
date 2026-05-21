import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/remaining_workload_estimator.dart';

void main() {
  group('RemainingWorkloadEstimator', () {
    late RemainingWorkloadEstimator estimator;

    setUp(() {
      estimator = RemainingWorkloadEstimator();
    });

    test('can be instantiated', () {
      expect(estimator, isA<RemainingWorkloadEstimator>());
    });

    group('estimateSubjectWorkload', () {
      test('returns zero lessons for empty data', () {
        final result = estimator.estimateSubjectWorkload(
          subjectId: 'subj_1',
          subjectTitle: 'Math',
          topicTitles: {},
          questionsPerTopic: {},
          topicMasteryLevels: {},
        );

        expect(result.totalQuestions, 0);
        expect(result.estimatedLessonsRemaining, 0.0);
        expect(result.overallMasteryLevel, 1.0);
      });

      test('returns zero lessons when all questions are mastered', () {
        final result = estimator.estimateSubjectWorkload(
          subjectId: 'subj_1',
          subjectTitle: 'Math',
          topicTitles: {'topic_1': 'Algebra'},
          questionsPerTopic: {'topic_1': 10},
          topicMasteryLevels: {'topic_1': 0.9},
        );

        expect(result.totalQuestions, 10);
        expect(result.estimatedLessonsRemaining, 0.0);
        expect(result.masteredQuestions, 10);
      });

      test('estimates lessons for low-mastery topics', () {
        final result = estimator.estimateSubjectWorkload(
          subjectId: 'subj_1',
          subjectTitle: 'Math',
          topicTitles: {'topic_1': 'Algebra'},
          questionsPerTopic: {'topic_1': 16},
          topicMasteryLevels: {'topic_1': 0.3},
        );

        expect(result.totalQuestions, 16);
        expect(result.atRiskQuestions, 16);
        expect(result.estimatedLessonsRemaining, 2.0);
        expect(result.overallMasteryLevel, lessThan(1.0));
      });

      test('handles multiple topics correctly', () {
        final result = estimator.estimateSubjectWorkload(
          subjectId: 'subj_1',
          subjectTitle: 'Science',
          topicTitles: {
            'topic_1': 'Physics',
            'topic_2': 'Chemistry',
          },
          questionsPerTopic: {
            'topic_1': 10,
            'topic_2': 10,
          },
          topicMasteryLevels: {
            'topic_1': 0.9,
            'topic_2': 0.3,
          },
        );

        expect(result.totalQuestions, 20);
        expect(result.topicWorkloads.length, 2);
        expect(result.masteredQuestions, 10);
        expect(result.atRiskQuestions, 10);
      });
    });

    group('estimateOverallMastery', () {
      test('returns 1.0 for empty list', () {
        expect(estimator.estimateOverallMastery([]), 1.0);
      });

      test('aggregates multiple subjects correctly', () {
        final workloads = [
          estimator.estimateSubjectWorkload(
            subjectId: 'subj_1',
            subjectTitle: 'Math',
            topicTitles: {'topic_1': 'Algebra'},
            questionsPerTopic: {'topic_1': 10},
            topicMasteryLevels: {'topic_1': 0.9},
          ),
          estimator.estimateSubjectWorkload(
            subjectId: 'subj_2',
            subjectTitle: 'Science',
            topicTitles: {'topic_2': 'Physics'},
            questionsPerTopic: {'topic_2': 10},
            topicMasteryLevels: {'topic_2': 0.3},
          ),
        ];

        final mastery = estimator.estimateOverallMastery(workloads);
        expect(mastery, greaterThan(0.0));
        expect(mastery, lessThan(1.0));
      });
    });

    group('estimateTotalLessonsRemaining', () {
      test('returns 0 for empty list', () {
        expect(estimator.estimateTotalLessonsRemaining([]), 0.0);
      });

      test('sums lessons across subjects', () {
        final workloads = [
          estimator.estimateSubjectWorkload(
            subjectId: 'subj_1',
            subjectTitle: 'Math',
            topicTitles: {'topic_1': 'Algebra'},
            questionsPerTopic: {'topic_1': 16},
            topicMasteryLevels: {'topic_1': 0.3},
          ),
          estimator.estimateSubjectWorkload(
            subjectId: 'subj_2',
            subjectTitle: 'Science',
            topicTitles: {'topic_2': 'Physics'},
            questionsPerTopic: {'topic_2': 8},
            topicMasteryLevels: {'topic_2': 0.2},
          ),
        ];

        final total = estimator.estimateTotalLessonsRemaining(workloads);
        expect(total, greaterThan(0.0));
      });
    });
  });
}
