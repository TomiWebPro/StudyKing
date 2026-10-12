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
          topicMasteryLevels: {'topic_1': 1.0},
        );

        expect(result.totalQuestions, 10);
        expect(result.estimatedLessonsRemaining, 0.0);
        expect(result.masteredQuestions, 10);
      });

      test('estimates lessons proportionally for partially mastered topics', () {
        final result = estimator.estimateSubjectWorkload(
          subjectId: 'subj_1',
          subjectTitle: 'Math',
          topicTitles: {'topic_1': 'Algebra'},
          questionsPerTopic: {'topic_1': 10},
          topicMasteryLevels: {'topic_1': 0.9},
        );

        expect(result.masteredQuestions, 9);
        expect(result.unattemptedQuestions, 1);
        expect(result.estimatedLessonsRemaining, closeTo(0.125, 1e-9));
        expect(result.overallMasteryLevel, closeTo(0.9, 1e-9));
      });

      test('reports the actual topic mastery level, not a bucket-derived value',
          () {
        final result = estimator.estimateSubjectWorkload(
          subjectId: 'subj_1',
          subjectTitle: 'Math',
          topicTitles: {
            'topic_1': 'Algebra',
            'topic_2': 'Geometry',
          },
          questionsPerTopic: {'topic_1': 10, 'topic_2': 10},
          topicMasteryLevels: {'topic_1': 0.6, 'topic_2': 0.85},
        );

        // Regression: all-or-nothing bucketing used to report 0.3 and 1.0.
        expect(result.topicWorkloads[0].masteryLevel, closeTo(0.6, 1e-9));
        expect(result.topicWorkloads[1].masteryLevel, closeTo(0.85, 1e-9));
        // (6 + 9) / 20; 10 * 0.85 rounds to 9.
        expect(result.overallMasteryLevel, closeTo(0.75, 1e-9));
      });

      test('has no cliff in the estimate at the mastery threshold', () {
        final result = estimator.estimateSubjectWorkload(
          subjectId: 'subj_1',
          subjectTitle: 'Math',
          topicTitles: {
            'topic_1': 'Algebra',
            'topic_2': 'Geometry',
          },
          questionsPerTopic: {'topic_1': 100, 'topic_2': 100},
          topicMasteryLevels: {'topic_1': 0.69, 'topic_2': 0.71},
        );

        // Regression: 0.71 used to jump to zero lessons while 0.69
        // reported the full topic (12.5 lessons).
        final lessons69 = result.topicWorkloads[0].estimatedLessonsRemaining;
        final lessons71 = result.topicWorkloads[1].estimatedLessonsRemaining;
        expect(lessons71, greaterThan(0.0));
        expect((lessons69 - lessons71).abs(), lessThan(1.0));
        expect(lessons69, closeTo(3.875, 1e-9));
        expect(lessons71, closeTo(3.625, 1e-9));
      });

      test('populates unattempted questions for mid-mastery topics', () {
        final result = estimator.estimateSubjectWorkload(
          subjectId: 'subj_1',
          subjectTitle: 'Math',
          topicTitles: {'topic_1': 'Algebra'},
          questionsPerTopic: {'topic_1': 10},
          topicMasteryLevels: {'topic_1': 0.6},
        );

        // Regression: unattemptedQuestions was always 0 before.
        expect(result.masteredQuestions, 6);
        expect(result.atRiskQuestions, 0);
        expect(result.unattemptedQuestions, 4);
        expect(result.estimatedLessonsRemaining, 0.5);
      });

      test('clamps out-of-range mastery levels', () {
        final high = estimator.estimateSubjectWorkload(
          subjectId: 'subj_1',
          subjectTitle: 'Math',
          topicTitles: {'topic_1': 'Algebra'},
          questionsPerTopic: {'topic_1': 10},
          topicMasteryLevels: {'topic_1': 1.5},
        );
        expect(high.masteredQuestions, 10);
        expect(high.estimatedLessonsRemaining, 0.0);

        final low = estimator.estimateSubjectWorkload(
          subjectId: 'subj_1',
          subjectTitle: 'Math',
          topicTitles: {'topic_1': 'Algebra'},
          questionsPerTopic: {'topic_1': 10},
          topicMasteryLevels: {'topic_1': -0.5},
        );
        expect(low.masteredQuestions, 0);
        expect(low.atRiskQuestions, 10);
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
        expect(result.atRiskQuestions, 11);
        expect(result.estimatedLessonsRemaining, closeTo(1.375, 1e-9));
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
        expect(result.masteredQuestions, 12);
        expect(result.atRiskQuestions, 7);
        expect(result.unattemptedQuestions, 1);
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
