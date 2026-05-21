import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:studyking/features/planner/data/adapters/engagement_nudge_adapter.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';

void main() {
  group('EngagementNudgeModelAdapter', () {
    test('typeId is 32', () {
      expect(EngagementNudgeModelAdapter().typeId, 32);
    });

    test('write/read round-trips all 9 fields', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(EngagementNudgeModelAdapter());
      final adapter = EngagementNudgeModelAdapter();
      final now = DateTime(2025, 6, 15, 10, 30);
      final actedAt = DateTime(2025, 6, 15, 14, 0);
      final source = EngagementNudgeModel(
        id: 'nudge-001',
        studentId: 'student-1',
        nudgeType: 'overwork',
        message: 'You have been studying for 4 hours straight.',
        severity: 'high',
        topicId: 'topic-xyz',
        sentAt: now,
        wasActedUpon: true,
        actedUponAt: actedAt,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, 'nudge-001');
      expect(restored.studentId, 'student-1');
      expect(restored.nudgeType, 'overwork');
      expect(restored.message, 'You have been studying for 4 hours straight.');
      expect(restored.severity, 'high');
      expect(restored.topicId, 'topic-xyz');
      expect(restored.sentAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(restored.wasActedUpon, true);
      expect(restored.actedUponAt!.millisecondsSinceEpoch, actedAt.millisecondsSinceEpoch);
    });

    test('write/read with null optionals and defaults', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(EngagementNudgeModelAdapter());
      final adapter = EngagementNudgeModelAdapter();
      final now = DateTime(2025, 3, 1);
      final source = EngagementNudgeModel(
        id: 'nudge-002',
        studentId: 'student-2',
        nudgeType: 'revision',
        message: 'Time to review past topics.',
        sentAt: now,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, 'nudge-002');
      expect(restored.studentId, 'student-2');
      expect(restored.nudgeType, 'revision');
      expect(restored.severity, 'medium');
      expect(restored.topicId, isNull);
      expect(restored.wasActedUpon, false);
      expect(restored.actedUponAt, isNull);
    });

    test('write/read with edge values (empty strings, zero-length)', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(EngagementNudgeModelAdapter());
      final adapter = EngagementNudgeModelAdapter();
      final now = DateTime(2025, 12, 31, 23, 59, 59);
      final source = EngagementNudgeModel(
        id: '',
        studentId: '',
        nudgeType: '',
        message: '',
        severity: '',
        topicId: '',
        sentAt: now,
        wasActedUpon: false,
        actedUponAt: null,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, '');
      expect(restored.studentId, '');
      expect(restored.nudgeType, '');
      expect(restored.message, '');
      expect(restored.severity, '');
      expect(restored.topicId, '');
      expect(restored.wasActedUpon, false);
      expect(restored.actedUponAt, isNull);
    });

    test('field order matches write sequence (toJson equality)', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(EngagementNudgeModelAdapter());
      final adapter = EngagementNudgeModelAdapter();
      final now = DateTime(2025, 6, 15);
      final source = EngagementNudgeModel(
        id: 'order-test',
        studentId: 'student',
        nudgeType: 'planAdjustment',
        message: 'Adjust your study plan.',
        severity: 'low',
        topicId: null,
        sentAt: now,
        wasActedUpon: false,
        actedUponAt: null,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.toJson(), source.toJson());
    });
  });
}
