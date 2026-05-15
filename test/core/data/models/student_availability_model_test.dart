import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/student_availability_model.dart';

void main() {
  group('StudentAvailabilityModel', () {
    group('constructor', () {
      test('creates with required fields', () {
        final model = StudentAvailabilityModel(
          studentId: 'student-1',
        );
        expect(model.studentId, 'student-1');
        expect(model.preferredStudyDays, [1, 2, 3, 4, 5, 6, 7]);
        expect(model.preferredStartHour, 9);
        expect(model.preferredEndHour, 21);
        expect(model.maxSessionsPerDay, 3);
        expect(model.defaultSessionDurationMinutes, 30);
        expect(model.blackoutDates, isEmpty);
      });

      test('creates with all fields', () {
        final blackout = DateTime(2026, 5, 15);
        final model = StudentAvailabilityModel(
          studentId: 'student-1',
          preferredStudyDays: [1, 3, 5],
          preferredStartHour: 8,
          preferredEndHour: 18,
          maxSessionsPerDay: 2,
          defaultSessionDurationMinutes: 45,
          blackoutDates: [blackout],
        );
        expect(model.preferredStudyDays, [1, 3, 5]);
        expect(model.preferredStartHour, 8);
        expect(model.preferredEndHour, 18);
        expect(model.maxSessionsPerDay, 2);
        expect(model.defaultSessionDurationMinutes, 45);
        expect(model.blackoutDates, [blackout]);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final model = StudentAvailabilityModel(
          studentId: 's1',
          preferredStudyDays: [1, 3, 5],
          preferredStartHour: 8,
          preferredEndHour: 18,
          maxSessionsPerDay: 2,
          defaultSessionDurationMinutes: 45,
          blackoutDates: [DateTime(2026, 5, 15)],
        );
        final copy = model.copyWith();
        expect(copy.studentId, model.studentId);
        expect(copy.preferredStudyDays, model.preferredStudyDays);
        expect(copy.preferredStartHour, model.preferredStartHour);
        expect(copy.preferredEndHour, model.preferredEndHour);
        expect(copy.maxSessionsPerDay, model.maxSessionsPerDay);
        expect(copy.defaultSessionDurationMinutes, model.defaultSessionDurationMinutes);
        expect(copy.blackoutDates, model.blackoutDates);
      });

      test('updates specified fields', () {
        final model = StudentAvailabilityModel(studentId: 's1');
        final copy = model.copyWith(
          preferredStudyDays: [2, 4],
          maxSessionsPerDay: 1,
          defaultSessionDurationMinutes: 60,
        );
        expect(copy.preferredStudyDays, [2, 4]);
        expect(copy.maxSessionsPerDay, 1);
        expect(copy.defaultSessionDurationMinutes, 60);
        expect(copy.studentId, 's1');
      });

      test('updates blackout dates', () {
        final model = StudentAvailabilityModel(studentId: 's1');
        final blackout = DateTime(2026, 6, 1);
        final copy = model.copyWith(blackoutDates: [blackout]);
        expect(copy.blackoutDates, [blackout]);
      });
    });

    group('isAvailableOn', () {
      test('returns true for a preferred weekday without blackout', () {
        final model = StudentAvailabilityModel(
          studentId: 's1',
          preferredStudyDays: [1, 2, 3, 4, 5],
          blackoutDates: [],
        );
        final monday = DateTime(2026, 5, 11);
        expect(monday.weekday, 1);
        expect(model.isAvailableOn(monday), isTrue);
      });

      test('returns false for a non-preferred weekday', () {
        final model = StudentAvailabilityModel(
          studentId: 's1',
          preferredStudyDays: [1, 2, 3, 4, 5],
        );
        final saturday = DateTime(2026, 5, 16);
        expect(saturday.weekday, 6);
        expect(model.isAvailableOn(saturday), isFalse);
      });

      test('returns false for a blackout date even if preferred weekday', () {
        final blackout = DateTime(2026, 5, 11);
        final model = StudentAvailabilityModel(
          studentId: 's1',
          preferredStudyDays: [1, 2, 3, 4, 5, 6, 7],
          blackoutDates: [blackout],
        );
        expect(blackout.weekday, 1);
        expect(model.isAvailableOn(blackout), isFalse);
      });

      test('returns false when blackout date has different time but same day', () {
        final blackout = DateTime(2026, 5, 11, 10, 0, 0);
        final model = StudentAvailabilityModel(
          studentId: 's1',
          blackoutDates: [blackout],
        );
        final sameDay = DateTime(2026, 5, 11, 15, 30, 0);
        expect(model.isAvailableOn(sameDay), isFalse);
      });
    });

    group('preferredStudyHoursPerDay', () {
      test('returns difference between end and start hour', () {
        final model = StudentAvailabilityModel(
          studentId: 's1',
          preferredStartHour: 9,
          preferredEndHour: 17,
        );
        expect(model.preferredStudyHoursPerDay, 8);
      });

      test('handles different hours', () {
        final model = StudentAvailabilityModel(
          studentId: 's1',
          preferredStartHour: 8,
          preferredEndHour: 22,
        );
        expect(model.preferredStudyHoursPerDay, 14);
      });
    });
  });
}
