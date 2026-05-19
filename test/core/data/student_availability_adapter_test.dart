import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/planner/data/adapters/student_availability_adapter.dart';
import 'package:studyking/features/planner/data/models/student_availability_model.dart';
import '../../helpers/hive_test_utils.dart';

void main() {
  group('StudentAvailabilityModelAdapter', () {
    test('has correct typeId', () {
      final adapter = StudentAvailabilityModelAdapter();
      expect(adapter.typeId, 35);
    });

    test('is a TypeAdapter<StudentAvailabilityModel>', () {
      final adapter = StudentAvailabilityModelAdapter();
      expect(adapter, isA<TypeAdapter<StudentAvailabilityModel>>());
    });

    test('read and write round-trips with all fields', () {
      final adapter = StudentAvailabilityModelAdapter();
      final blackoutDate = DateTime.utc(2024, 12, 25);
      final availability = StudentAvailabilityModel(
        studentId: 'student1',
        preferredStudyDays: [1, 3, 5],
        preferredStartHour: 8,
        preferredEndHour: 22,
        maxSessionsPerDay: 5,
        defaultSessionDurationMinutes: 45,
        blackoutDates: [blackoutDate],
      );

      final writeCache = <int, dynamic>{};
      final writer = TestBinaryWriter(writeCache);
      adapter.write(writer, availability);

      final reader = TestBinaryReader(writeCache);
      final restored = adapter.read(reader);

      expect(restored.studentId, availability.studentId);
      expect(restored.preferredStudyDays, availability.preferredStudyDays);
      expect(restored.preferredStartHour, availability.preferredStartHour);
      expect(restored.preferredEndHour, availability.preferredEndHour);
      expect(restored.maxSessionsPerDay, availability.maxSessionsPerDay);
      expect(restored.defaultSessionDurationMinutes,
          availability.defaultSessionDurationMinutes);
      expect(restored.blackoutDates, availability.blackoutDates);
    });

    test('read and write round-trips with default values', () {
      final adapter = StudentAvailabilityModelAdapter();
      final availability = StudentAvailabilityModel(
        studentId: 'student2',
      );

      final writeCache = <int, dynamic>{};
      final writer = TestBinaryWriter(writeCache);
      adapter.write(writer, availability);

      final reader = TestBinaryReader(writeCache);
      final restored = adapter.read(reader);

      expect(restored.studentId, availability.studentId);
      expect(restored.preferredStudyDays, [1, 2, 3, 4, 5, 6, 7]);
      expect(restored.preferredStartHour, 9);
      expect(restored.preferredEndHour, 21);
      expect(restored.maxSessionsPerDay, 3);
      expect(restored.defaultSessionDurationMinutes, 30);
      expect(restored.blackoutDates, []);
    });

    test('read and write round-trips with empty blackout dates', () {
      final adapter = StudentAvailabilityModelAdapter();
      final availability = StudentAvailabilityModel(
        studentId: 'student3',
        preferredStudyDays: [2, 4],
        preferredStartHour: 10,
        preferredEndHour: 18,
        maxSessionsPerDay: 2,
        defaultSessionDurationMinutes: 60,
        blackoutDates: [],
      );

      final writeCache = <int, dynamic>{};
      final writer = TestBinaryWriter(writeCache);
      adapter.write(writer, availability);

      final reader = TestBinaryReader(writeCache);
      final restored = adapter.read(reader);

      expect(restored.studentId, availability.studentId);
      expect(restored.preferredStudyDays, [2, 4]);
      expect(restored.blackoutDates, []);
    });
  });
}
