import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/plan_adherence_metric_model.dart';

void main() {
  group('PlanAdherenceMetric', () {
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 5, 12, 10, 0, 0);
    });

    group('constructor', () {
      test('creates with required fields', () {
        final metric = PlanAdherenceMetric(
          date: now,
          studentId: 'student-1',
          plannedQuestions: 10,
          actualQuestions: 8,
          plannedMinutes: 60,
          actualMinutes: 45,
          adherenceScore: 0.8,
        );
        expect(metric.date, now);
        expect(metric.studentId, 'student-1');
        expect(metric.plannedQuestions, 10);
        expect(metric.actualQuestions, 8);
        expect(metric.plannedMinutes, 60);
        expect(metric.actualMinutes, 45);
        expect(metric.adherenceScore, 0.8);
        expect(metric.metadata, isNull);
      });

      test('creates with metadata', () {
        final metric = PlanAdherenceMetric(
          date: now,
          studentId: 's1',
          plannedQuestions: 5,
          actualQuestions: 5,
          plannedMinutes: 30,
          actualMinutes: 30,
          adherenceScore: 1.0,
          metadata: {'perfect': true},
        );
        expect(metric.metadata, {'perfect': true});
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final metric = PlanAdherenceMetric(
          date: now,
          studentId: 's1',
          plannedQuestions: 10,
          actualQuestions: 8,
          plannedMinutes: 60,
          actualMinutes: 45,
          adherenceScore: 0.8,
          metadata: {'note': 'good'},
        );
        final json = metric.toJson();
        expect(json['date'], now.toIso8601String());
        expect(json['studentId'], 's1');
        expect(json['plannedQuestions'], 10);
        expect(json['actualQuestions'], 8);
        expect(json['plannedMinutes'], 60);
        expect(json['actualMinutes'], 45);
        expect(json['adherenceScore'], 0.8);
        expect(json['metadata'], {'note': 'good'});
      });

      test('serializes with null metadata', () {
        final metric = PlanAdherenceMetric(
          date: now,
          studentId: 's1',
          plannedQuestions: 0,
          actualQuestions: 0,
          plannedMinutes: 0,
          actualMinutes: 0,
          adherenceScore: 0.0,
        );
        final json = metric.toJson();
        expect(json['metadata'], isNull);
      });
    });
  });
}
