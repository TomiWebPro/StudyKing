import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';

void main() {
  group('PlanAdherenceModel', () {
    final date = DateTime(2026, 5, 16);
    const id = 'adherence-1';
    const studentId = 'student-1';
    const planId = 'plan-1';

    group('constructor', () {
      test('creates instance with required fields', () {
        final model = PlanAdherenceModel(
          id: id, studentId: studentId, date: date,
        );
        expect(model.id, id);
        expect(model.studentId, studentId);
        expect(model.date, date);
        expect(model.plannedQuestions, 0);
        expect(model.actualQuestions, 0);
        expect(model.plannedMinutes, 0);
        expect(model.actualMinutes, 0);
        expect(model.adherenceScore, 0.0);
        expect(model.planId, isNull);
        expect(model.metadata, isNull);
      });

      test('accepts all optional fields', () {
        final model = PlanAdherenceModel(
          id: id, studentId: studentId, date: date,
          plannedQuestions: 20, actualQuestions: 15,
          plannedMinutes: 60, actualMinutes: 45,
          adherenceScore: 0.75, planId: planId,
          metadata: {'source': 'manual'},
        );
        expect(model.plannedQuestions, 20);
        expect(model.actualQuestions, 15);
        expect(model.plannedMinutes, 60);
        expect(model.actualMinutes, 45);
        expect(model.adherenceScore, 0.75);
        expect(model.planId, planId);
        expect(model.metadata, {'source': 'manual'});
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final model = PlanAdherenceModel(
          id: id, studentId: studentId, date: date,
        );
        final copy = model.copyWith();
        expect(copy.id, model.id);
        expect(copy.studentId, model.studentId);
        expect(copy.date, model.date);
      });

      test('updates specified fields', () {
        final model = PlanAdherenceModel(
          id: id, studentId: studentId, date: date,
        );
        final later = DateTime(2026, 5, 17);
        final copy = model.copyWith(
          date: later, actualQuestions: 10, adherenceScore: 0.5,
        );
        expect(copy.date, later);
        expect(copy.actualQuestions, 10);
        expect(copy.adherenceScore, 0.5);
        expect(copy.id, id);
      });
    });

    group('equality', () {
      test('identical instances are equal', () {
        final a = PlanAdherenceModel(
          id: id, studentId: studentId, date: date,
        );
        expect(a == a, isTrue);
      });

      test('different instances are not equal', () {
        final a = PlanAdherenceModel(
          id: id, studentId: studentId, date: date,
        );
        final b = PlanAdherenceModel(
          id: 'other', studentId: studentId, date: date,
        );
        expect(a == b, isFalse);
      });

      test('hashCode is consistent', () {
        final a = PlanAdherenceModel(
          id: id, studentId: studentId, date: date,
        );
        expect(a.hashCode, a.hashCode);
      });
    });
  });
}
