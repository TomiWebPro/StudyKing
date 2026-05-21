import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:studyking/features/planner/data/adapters/student_availability_adapter.dart';
import 'package:studyking/features/planner/data/models/student_availability_model.dart';

void main() {
  group('StudentAvailabilityModelAdapter', () {
    test('typeId is 35', () {
      expect(StudentAvailabilityModelAdapter().typeId, 35);
    });

    test('write/read round-trips all 7 fields', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(StudentAvailabilityModelAdapter());
      final adapter = StudentAvailabilityModelAdapter();
      final blackout = DateTime(2025, 12, 25);
      final source = StudentAvailabilityModel(
        studentId: 'student-1',
        preferredStudyDays: [1, 2, 3, 4, 5],
        preferredStartHour: 8,
        preferredEndHour: 22,
        maxSessionsPerDay: 4,
        defaultSessionDurationMinutes: 45,
        blackoutDates: [blackout],
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.studentId, 'student-1');
      expect(restored.preferredStudyDays, [1, 2, 3, 4, 5]);
      expect(restored.preferredStartHour, 8);
      expect(restored.preferredEndHour, 22);
      expect(restored.maxSessionsPerDay, 4);
      expect(restored.defaultSessionDurationMinutes, 45);
      expect(restored.blackoutDates.length, 1);
      expect(restored.blackoutDates.first.millisecondsSinceEpoch, blackout.millisecondsSinceEpoch);
    });

    test('write/read with default values when fields are null/missing', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(StudentAvailabilityModelAdapter());
      final adapter = StudentAvailabilityModelAdapter();
      final source = StudentAvailabilityModel(
        studentId: 'student-2',
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.studentId, 'student-2');
      expect(restored.preferredStudyDays, [1, 2, 3, 4, 5, 6, 7]);
      expect(restored.preferredStartHour, 9);
      expect(restored.preferredEndHour, 21);
      expect(restored.maxSessionsPerDay, 3);
      expect(restored.defaultSessionDurationMinutes, 30);
      expect(restored.blackoutDates, isEmpty);
    });

    test('write/read with edge values (single day, zero sessions, empty lists)', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(StudentAvailabilityModelAdapter());
      final adapter = StudentAvailabilityModelAdapter();
      final source = StudentAvailabilityModel(
        studentId: 'student-3',
        preferredStudyDays: [1],
        preferredStartHour: 0,
        preferredEndHour: 24,
        maxSessionsPerDay: 0,
        defaultSessionDurationMinutes: 0,
        blackoutDates: [],
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.studentId, 'student-3');
      expect(restored.preferredStudyDays, [1]);
      expect(restored.preferredStartHour, 0);
      expect(restored.preferredEndHour, 24);
      expect(restored.maxSessionsPerDay, 0);
      expect(restored.defaultSessionDurationMinutes, 0);
      expect(restored.blackoutDates, isEmpty);
    });

    test('write/read with multiple blackout dates', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(StudentAvailabilityModelAdapter());
      final adapter = StudentAvailabilityModelAdapter();
      final blackout1 = DateTime(2025, 1, 1);
      final blackout2 = DateTime(2025, 12, 25);
      final source = StudentAvailabilityModel(
        studentId: 'student-4',
        preferredStudyDays: [1, 2, 3],
        preferredStartHour: 10,
        preferredEndHour: 18,
        maxSessionsPerDay: 2,
        defaultSessionDurationMinutes: 60,
        blackoutDates: [blackout1, blackout2],
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.studentId, 'student-4');
      expect(restored.blackoutDates.length, 2);
      expect(restored.blackoutDates[0].millisecondsSinceEpoch, blackout1.millisecondsSinceEpoch);
      expect(restored.blackoutDates[1].millisecondsSinceEpoch, blackout2.millisecondsSinceEpoch);
    });

    test('field order matches write sequence (toJson equality)', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(StudentAvailabilityModelAdapter());
      final adapter = StudentAvailabilityModelAdapter();
      final source = StudentAvailabilityModel(
        studentId: 'order-test',
        preferredStudyDays: [1, 3, 5],
        preferredStartHour: 9,
        preferredEndHour: 17,
        maxSessionsPerDay: 3,
        defaultSessionDurationMinutes: 30,
        blackoutDates: [],
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.toJson(), source.toJson());
    });
  });
}
