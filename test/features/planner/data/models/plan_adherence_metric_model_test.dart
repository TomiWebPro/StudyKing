import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_metric_model.dart';

void main() {
  group('PlanAdherenceMetric', () {
    final date = DateTime(2026, 5, 16);
    const studentId = 'student-1';

    group('constructor', () {
      test('creates instance with all required fields', () {
        final metric = PlanAdherenceMetric(
          date: date, studentId: studentId,
          plannedQuestions: 20, actualQuestions: 15,
          plannedMinutes: 60, actualMinutes: 45,
          adherenceScore: 0.75,
        );
        expect(metric.date, date);
        expect(metric.studentId, studentId);
        expect(metric.plannedQuestions, 20);
        expect(metric.actualQuestions, 15);
        expect(metric.plannedMinutes, 60);
        expect(metric.actualMinutes, 45);
        expect(metric.adherenceScore, 0.75);
        expect(metric.metadata, isNull);
      });

      test('accepts metadata', () {
        final metric = PlanAdherenceMetric(
          date: date, studentId: studentId,
          plannedQuestions: 0, actualQuestions: 0,
          plannedMinutes: 0, actualMinutes: 0,
          adherenceScore: 0.0,
          metadata: {'note': 'no study today'},
        );
        expect(metric.metadata, {'note': 'no study today'});
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final metric = PlanAdherenceMetric(
          date: date, studentId: studentId,
          plannedQuestions: 10, actualQuestions: 8,
          plannedMinutes: 30, actualMinutes: 25,
          adherenceScore: 0.8,
        );
        final json = metric.toJson();
        expect(json['date'], date.toIso8601String());
        expect(json['studentId'], studentId);
        expect(json['plannedQuestions'], 10);
        expect(json['actualQuestions'], 8);
        expect(json['plannedMinutes'], 30);
        expect(json['actualMinutes'], 25);
        expect(json['adherenceScore'], 0.8);
        expect(json['metadata'], isNull);
      });

      test('serializes with metadata', () {
        final metric = PlanAdherenceMetric(
          date: date, studentId: studentId,
          plannedQuestions: 10, actualQuestions: 10,
          plannedMinutes: 30, actualMinutes: 30,
          adherenceScore: 1.0,
          metadata: {'perfect': true},
        );
        final json = metric.toJson();
        expect(json['metadata'], {'perfect': true});
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'date': date.toIso8601String(),
          'studentId': studentId,
          'plannedQuestions': 10,
          'actualQuestions': 8,
          'plannedMinutes': 30,
          'actualMinutes': 25,
          'adherenceScore': 0.8,
        };
        final metric = PlanAdherenceMetric.fromJson(json);
        expect(metric.date, date);
        expect(metric.studentId, studentId);
        expect(metric.plannedQuestions, 10);
        expect(metric.actualQuestions, 8);
        expect(metric.plannedMinutes, 30);
        expect(metric.actualMinutes, 25);
        expect(metric.adherenceScore, 0.8);
        expect(metric.metadata, isNull);
      });

      test('handles metadata', () {
        final json = {
          'date': date.toIso8601String(),
          'studentId': studentId,
          'plannedQuestions': 5,
          'actualQuestions': 3,
          'plannedMinutes': 15,
          'actualMinutes': 10,
          'adherenceScore': 0.6,
          'metadata': {'note': 'test'},
        };
        final metric = PlanAdherenceMetric.fromJson(json);
        expect(metric.metadata, {'note': 'test'});
      });
    });

    group('serialization roundtrip', () {
      test('preserves all fields', () {
        final original = PlanAdherenceMetric(
          date: date, studentId: studentId,
          plannedQuestions: 20, actualQuestions: 18,
          plannedMinutes: 60, actualMinutes: 55,
          adherenceScore: 0.9,
          metadata: {'source': 'manual'},
        );
        final restored = PlanAdherenceMetric.fromJson(original.toJson());
        expect(restored.date, original.date);
        expect(restored.studentId, original.studentId);
        expect(restored.plannedQuestions, original.plannedQuestions);
        expect(restored.actualQuestions, original.actualQuestions);
        expect(restored.plannedMinutes, original.plannedMinutes);
        expect(restored.actualMinutes, original.actualMinutes);
        expect(restored.adherenceScore, original.adherenceScore);
        expect(restored.metadata, original.metadata);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final metric = PlanAdherenceMetric(
          date: date, studentId: studentId,
          plannedQuestions: 10, actualQuestions: 8,
          plannedMinutes: 30, actualMinutes: 25,
          adherenceScore: 0.8,
        );
        final copy = metric.copyWith();
        expect(copy.date, metric.date);
        expect(copy.adherenceScore, metric.adherenceScore);
      });

      test('updates specified fields', () {
        final metric = PlanAdherenceMetric(
          date: date, studentId: studentId,
          plannedQuestions: 10, actualQuestions: 8,
          plannedMinutes: 30, actualMinutes: 25,
          adherenceScore: 0.8,
        );
        final later = DateTime(2026, 5, 17);
        final copy = metric.copyWith(
          date: later, adherenceScore: 0.95, actualQuestions: 10,
        );
        expect(copy.date, later);
        expect(copy.adherenceScore, 0.95);
        expect(copy.actualQuestions, 10);
        expect(copy.studentId, studentId);
      });
    });

    group('equality', () {
      test('identical instances are equal', () {
        final a = PlanAdherenceMetric(
          date: date, studentId: studentId,
          plannedQuestions: 10, actualQuestions: 8,
          plannedMinutes: 30, actualMinutes: 25,
          adherenceScore: 0.8,
        );
        expect(a == a, isTrue);
      });

      test('same values are equal', () {
        final a = PlanAdherenceMetric(
          date: date, studentId: studentId,
          plannedQuestions: 10, actualQuestions: 8,
          plannedMinutes: 30, actualMinutes: 25,
          adherenceScore: 0.8,
        );
        final b = PlanAdherenceMetric(
          date: date, studentId: studentId,
          plannedQuestions: 10, actualQuestions: 8,
          plannedMinutes: 30, actualMinutes: 25,
          adherenceScore: 0.8,
        );
        expect(a, b);
      });

      test('different values are not equal', () {
        final a = PlanAdherenceMetric(
          date: date, studentId: studentId,
          plannedQuestions: 10, actualQuestions: 8,
          plannedMinutes: 30, actualMinutes: 25,
          adherenceScore: 0.8,
        );
        final b = PlanAdherenceMetric(
          date: date, studentId: studentId,
          plannedQuestions: 10, actualQuestions: 9,
          plannedMinutes: 30, actualMinutes: 25,
          adherenceScore: 0.8,
        );
        expect(a == b, isFalse);
      });

      test('hashCode is consistent', () {
        final a = PlanAdherenceMetric(
          date: date, studentId: studentId,
          plannedQuestions: 10, actualQuestions: 8,
          plannedMinutes: 30, actualMinutes: 25,
          adherenceScore: 0.8,
        );
        expect(a.hashCode, a.hashCode);
      });
    });
  });
}
