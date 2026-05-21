import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:studyking/features/planner/data/adapters/plan_adherence_adapter.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_metric_model.dart';

void main() {
  group('PlanAdherenceMetricAdapter', () {
    test('typeId is 30', () {
      expect(PlanAdherenceMetricAdapter().typeId, 30);
    });

    test('write/read round-trip', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(PlanAdherenceMetricAdapter());
      final adapter = PlanAdherenceMetricAdapter();
      final now = DateTime.now();
      final source = PlanAdherenceMetric(
        date: now,
        studentId: 'student1',
        plannedQuestions: 10,
        actualQuestions: 8,
        plannedMinutes: 60,
        actualMinutes: 45,
        adherenceScore: 0.75,
        metadata: {'source': 'daily_tracker', 'version': 2},
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.date.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(restored.studentId, 'student1');
      expect(restored.plannedQuestions, 10);
      expect(restored.actualQuestions, 8);
      expect(restored.plannedMinutes, 60);
      expect(restored.actualMinutes, 45);
      expect(restored.adherenceScore, 0.75);
      expect(restored.metadata!['source'], 'daily_tracker');
      expect(restored.metadata!['version'], 2);
    });

    test('write/read with null metadata', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(PlanAdherenceMetricAdapter());
      final adapter = PlanAdherenceMetricAdapter();
      final now = DateTime.now();
      final source = PlanAdherenceMetric(
        date: now,
        studentId: 'student2',
        plannedQuestions: 5,
        actualQuestions: 5,
        plannedMinutes: 30,
        actualMinutes: 30,
        adherenceScore: 1.0,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.studentId, 'student2');
      expect(restored.adherenceScore, 1.0);
      expect(restored.metadata, isNull);
    });
  });
}
