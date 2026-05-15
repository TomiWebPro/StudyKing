import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/plan_adherence_model.dart';

void main() {
  group('PlanAdherenceModel', () {
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 5, 12, 10, 0, 0);
    });

    group('constructor', () {
      test('creates with required fields', () {
        final model = PlanAdherenceModel(
          id: 'pa-1',
          studentId: 'student-1',
          date: now,
        );
        expect(model.id, 'pa-1');
        expect(model.studentId, 'student-1');
        expect(model.date, now);
        expect(model.plannedQuestions, 0);
        expect(model.actualQuestions, 0);
        expect(model.plannedMinutes, 0);
        expect(model.actualMinutes, 0);
        expect(model.adherenceScore, 0.0);
        expect(model.planId, isNull);
        expect(model.metadata, isNull);
      });

      test('creates with all fields', () {
        final model = PlanAdherenceModel(
          id: 'pa-2',
          studentId: 'student-1',
          date: now,
          plannedQuestions: 10,
          actualQuestions: 8,
          plannedMinutes: 60,
          actualMinutes: 45,
          adherenceScore: 0.8,
          planId: 'plan-1',
          metadata: {'source': 'daily'},
        );
        expect(model.plannedQuestions, 10);
        expect(model.actualQuestions, 8);
        expect(model.plannedMinutes, 60);
        expect(model.actualMinutes, 45);
        expect(model.adherenceScore, 0.8);
        expect(model.planId, 'plan-1');
        expect(model.metadata, {'source': 'daily'});
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final model = PlanAdherenceModel(
          id: 'pa-1',
          studentId: 's1',
          date: now,
          plannedQuestions: 10,
          actualQuestions: 8,
          plannedMinutes: 60,
          actualMinutes: 45,
          adherenceScore: 0.8,
          planId: 'plan-1',
          metadata: {'k': 'v'},
        );
        final copy = model.copyWith();
        expect(copy.id, model.id);
        expect(copy.studentId, model.studentId);
        expect(copy.date, model.date);
        expect(copy.plannedQuestions, model.plannedQuestions);
        expect(copy.actualQuestions, model.actualQuestions);
        expect(copy.plannedMinutes, model.plannedMinutes);
        expect(copy.actualMinutes, model.actualMinutes);
        expect(copy.adherenceScore, model.adherenceScore);
        expect(copy.planId, model.planId);
        expect(copy.metadata, model.metadata);
      });

      test('updates specified fields', () {
        final model = PlanAdherenceModel(
          id: 'pa-1',
          studentId: 's1',
          date: now,
        );
        final copy = model.copyWith(
          plannedQuestions: 5,
          actualQuestions: 5,
          adherenceScore: 1.0,
        );
        expect(copy.plannedQuestions, 5);
        expect(copy.actualQuestions, 5);
        expect(copy.adherenceScore, 1.0);
        expect(copy.id, 'pa-1');
      });

      test('updates nullable fields', () {
        final model = PlanAdherenceModel(
          id: 'pa-1',
          studentId: 's1',
          date: now,
        );
        final copy = model.copyWith(
          planId: 'plan-2',
          metadata: {'note': 'test'},
        );
        expect(copy.planId, 'plan-2');
        expect(copy.metadata, {'note': 'test'});
      });
    });
  });
}
