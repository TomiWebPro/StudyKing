import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:studyking/features/planner/data/adapters/plan_adherence_model_adapter.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';

void main() {
  group('PlanAdherenceModelAdapter', () {
    test('typeId is 33', () {
      expect(PlanAdherenceModelAdapter().typeId, 33);
    });

    test('write/read round-trips all 10 fields', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(PlanAdherenceModelAdapter());
      final adapter = PlanAdherenceModelAdapter();
      final now = DateTime(2025, 6, 15, 10, 30);
      final source = PlanAdherenceModel(
        id: 'adh-001',
        studentId: 'student-1',
        date: now,
        plannedQuestions: 20,
        actualQuestions: 18,
        plannedMinutes: 120,
        actualMinutes: 110,
        adherenceScore: 0.9,
        planId: 'plan-abc',
        metadata: {
          'source': 'manual',
          'tags': ['exam-prep'],
        },
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, 'adh-001');
      expect(restored.studentId, 'student-1');
      expect(restored.date.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(restored.plannedQuestions, 20);
      expect(restored.actualQuestions, 18);
      expect(restored.plannedMinutes, 120);
      expect(restored.actualMinutes, 110);
      expect(restored.adherenceScore, 0.9);
      expect(restored.planId, 'plan-abc');
      expect(restored.metadata?['source'], 'manual');
      expect((restored.metadata?['tags'] as List).first, 'exam-prep');
    });

    test('write/read round-trips with null planId and metadata', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(PlanAdherenceModelAdapter());
      final adapter = PlanAdherenceModelAdapter();
      final now = DateTime(2025, 1, 1);
      final source = PlanAdherenceModel(
        id: 'adh-002',
        studentId: 'student-2',
        date: now,
        plannedQuestions: 10,
        actualQuestions: 5,
        plannedMinutes: 60,
        actualMinutes: 30,
        adherenceScore: 0.5,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, 'adh-002');
      expect(restored.studentId, 'student-2');
      expect(restored.plannedQuestions, 10);
      expect(restored.actualQuestions, 5);
      expect(restored.plannedMinutes, 60);
      expect(restored.actualMinutes, 30);
      expect(restored.adherenceScore, 0.5);
      expect(restored.planId, isNull);
      expect(restored.metadata, isNull);
    });

    test('write/read round-trips with zero and edge values', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(PlanAdherenceModelAdapter());
      final adapter = PlanAdherenceModelAdapter();
      final now = DateTime(2025, 12, 31, 23, 59, 59);
      final source = PlanAdherenceModel(
        id: 'adh-003',
        studentId: 'student-3',
        date: now,
        plannedQuestions: 0,
        actualQuestions: 0,
        plannedMinutes: 0,
        actualMinutes: 0,
        adherenceScore: 0.0,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, 'adh-003');
      expect(restored.plannedQuestions, 0);
      expect(restored.actualQuestions, 0);
      expect(restored.adherenceScore, 0.0);
      expect(restored.planId, isNull);
    });

    test('field order matches write sequence (toJson equality)', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(PlanAdherenceModelAdapter());
      final adapter = PlanAdherenceModelAdapter();
      final now = DateTime(2025, 6, 15);
      final source = PlanAdherenceModel(
        id: 'order-test',
        studentId: 'student',
        date: now,
        plannedQuestions: 5,
        actualQuestions: 3,
        plannedMinutes: 90,
        actualMinutes: 45,
        adherenceScore: 0.6,
        planId: 'plan-xyz',
        metadata: null,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.toJson(), source.toJson());
    });
  });
}
