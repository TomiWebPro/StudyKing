import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/models/student_availability_model.dart';

void main() {
  group('StudentAvailabilityModel', () {
    const studentId = 'student-1';
    final blackoutDate = DateTime(2026, 5, 25);

    group('constructor', () {
      test('creates instance with required fields', () {
        final availability = StudentAvailabilityModel(studentId: studentId);
        expect(availability.studentId, studentId);
        expect(availability.preferredStudyDays, [1, 2, 3, 4, 5, 6, 7]);
        expect(availability.preferredStartHour, 9);
        expect(availability.preferredEndHour, 21);
        expect(availability.maxSessionsPerDay, 3);
        expect(availability.defaultSessionDurationMinutes, 30);
        expect(availability.blackoutDates, []);
      });

      test('accepts all optional fields', () {
        final availability = StudentAvailabilityModel(
          studentId: studentId,
          preferredStudyDays: [1, 3, 5],
          preferredStartHour: 8,
          preferredEndHour: 18,
          maxSessionsPerDay: 2,
          defaultSessionDurationMinutes: 45,
          blackoutDates: [blackoutDate],
        );
        expect(availability.preferredStudyDays, [1, 3, 5]);
        expect(availability.preferredStartHour, 8);
        expect(availability.preferredEndHour, 18);
        expect(availability.maxSessionsPerDay, 2);
        expect(availability.defaultSessionDurationMinutes, 45);
        expect(availability.blackoutDates, [blackoutDate]);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final a = StudentAvailabilityModel(studentId: studentId);
        final copy = a.copyWith();
        expect(copy.studentId, a.studentId);
        expect(copy.preferredStudyDays, a.preferredStudyDays);
      });

      test('updates specified fields', () {
        final a = StudentAvailabilityModel(studentId: studentId);
        final copy = a.copyWith(maxSessionsPerDay: 1, preferredStartHour: 10);
        expect(copy.maxSessionsPerDay, 1);
        expect(copy.preferredStartHour, 10);
        expect(copy.studentId, studentId);
      });
    });

    group('isAvailableOn', () {
      test('returns false on blackout dates', () {
        final availability = StudentAvailabilityModel(
          studentId: studentId,
          blackoutDates: [blackoutDate],
        );
        expect(availability.isAvailableOn(blackoutDate), isFalse);
      });

      test('returns false for non-preferred days', () {
        final availability = StudentAvailabilityModel(
          studentId: studentId,
          preferredStudyDays: [1, 2, 3],
        );
        final sunday = DateTime(2026, 5, 17);
        expect(sunday.weekday, 7);
        expect(availability.isAvailableOn(sunday), isFalse);
      });

      test('returns true for preferred day not blacked out', () {
        final availability = StudentAvailabilityModel(
          studentId: studentId,
          preferredStudyDays: [1, 2, 3, 4, 5, 6, 7],
        );
        expect(availability.isAvailableOn(DateTime(2026, 5, 18)), isTrue);
      });
    });

    group('preferredStudyHoursPerDay', () {
      test('computes correct hours', () {
        final a = StudentAvailabilityModel(studentId: studentId);
        expect(a.preferredStudyHoursPerDay, 12);
      });

      test('computes custom hours', () {
        final a = StudentAvailabilityModel(
          studentId: studentId,
          preferredStartHour: 10,
          preferredEndHour: 16,
        );
        expect(a.preferredStudyHoursPerDay, 6);
      });
    });

    group('equality', () {
      test('identical instances are equal', () {
        final a = StudentAvailabilityModel(studentId: studentId);
        expect(a == a, isTrue);
      });

      test('different instances are not equal', () {
        final a = StudentAvailabilityModel(studentId: studentId);
        final b = StudentAvailabilityModel(studentId: 'other');
        expect(a == b, isFalse);
      });

      test('hashCode is consistent', () {
        final a = StudentAvailabilityModel(studentId: studentId);
        expect(a.hashCode, a.hashCode);
      });
    });
  });
}
