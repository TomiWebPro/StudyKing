import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:studyking/features/practice/data/adapters/mastery_improvement_adapter.dart';
import 'package:studyking/core/data/models/mastery_improvement_metric_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';

void main() {
  group('MasteryImprovementMetricAdapter', () {
    test('typeId is 31', () {
      expect(MasteryImprovementMetricAdapter().typeId, 31);
    });

    test('write/read round-trip with all fields and metadata', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(MasteryImprovementMetricAdapter());
      final adapter = MasteryImprovementMetricAdapter();
      final now = DateTime.now();
      final source = MasteryImprovementMetric(
        date: now,
        studentId: 'student1',
        topicId: 'topic1',
        previousAccuracy: 0.5,
        currentAccuracy: 0.85,
        accuracyDelta: 0.35,
        previousMasteryLevel: 0.4,
        currentMasteryLevel: 0.8,
        previousLevel: MasteryLevel.developing,
        currentLevel: MasteryLevel.proficient,
        metadata: {'source': 'quiz'},
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.date.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(restored.studentId, 'student1');
      expect(restored.topicId, 'topic1');
      expect(restored.previousAccuracy, 0.5);
      expect(restored.currentAccuracy, 0.85);
      expect(restored.accuracyDelta, 0.35);
      expect(restored.previousMasteryLevel, 0.4);
      expect(restored.currentMasteryLevel, 0.8);
      expect(restored.previousLevel, MasteryLevel.developing);
      expect(restored.currentLevel, MasteryLevel.proficient);
      expect(restored.metadata!['source'], 'quiz');
    });

    test('write/read with null metadata', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(MasteryImprovementMetricAdapter());
      final adapter = MasteryImprovementMetricAdapter();
      final now = DateTime.now();
      final source = MasteryImprovementMetric(
        date: now,
        studentId: 'student2',
        topicId: 'topic2',
        previousAccuracy: 0.0,
        currentAccuracy: 0.0,
        accuracyDelta: 0.0,
        previousMasteryLevel: 0.0,
        currentMasteryLevel: 0.0,
        previousLevel: MasteryLevel.novice,
        currentLevel: MasteryLevel.novice,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.studentId, 'student2');
      expect(restored.previousLevel, MasteryLevel.novice);
      expect(restored.currentLevel, MasteryLevel.novice);
      expect(restored.metadata, isNull);
    });

    test('write/read with empty metadata map', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(MasteryImprovementMetricAdapter());
      final adapter = MasteryImprovementMetricAdapter();
      final now = DateTime.now();
      final source = MasteryImprovementMetric(
        date: now,
        studentId: 'student3',
        topicId: 'topic3',
        previousAccuracy: 0.1,
        currentAccuracy: 0.2,
        accuracyDelta: 0.1,
        previousMasteryLevel: 0.1,
        currentMasteryLevel: 0.2,
        previousLevel: MasteryLevel.browsing,
        currentLevel: MasteryLevel.developing,
        metadata: {},
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.metadata, isA<Map<String, dynamic>>());
      expect(restored.metadata!, isEmpty);
    });

    test('write/read for all MasteryLevel pairings', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(MasteryImprovementMetricAdapter());
      final adapter = MasteryImprovementMetricAdapter();
      final now = DateTime.now();

      final pairings = [
        (MasteryLevel.novice, MasteryLevel.browsing),
        (MasteryLevel.browsing, MasteryLevel.developing),
        (MasteryLevel.developing, MasteryLevel.proficient),
        (MasteryLevel.proficient, MasteryLevel.expert),
        (MasteryLevel.expert, MasteryLevel.expert),
        (MasteryLevel.browsing, MasteryLevel.novice),
      ];

      for (final (prev, curr) in pairings) {
        final source = MasteryImprovementMetric(
          date: now,
          studentId: 'student-$prev-$curr',
          topicId: 'topic-$prev-$curr',
          previousAccuracy: 0.5,
          currentAccuracy: 0.7,
          accuracyDelta: 0.2,
          previousMasteryLevel: prev.index.toDouble() * 0.25,
          currentMasteryLevel: curr.index.toDouble() * 0.25,
          previousLevel: prev,
          currentLevel: curr,
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.previousLevel, prev);
        expect(restored.currentLevel, curr);
      }
    });

    test('write/read with extreme double values', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(MasteryImprovementMetricAdapter());
      final adapter = MasteryImprovementMetricAdapter();
      final now = DateTime.now();
      final source = MasteryImprovementMetric(
        date: now,
        studentId: 'student-extreme',
        topicId: 'topic-extreme',
        previousAccuracy: 1.0,
        currentAccuracy: 0.0,
        accuracyDelta: -1.0,
        previousMasteryLevel: double.minPositive,
        currentMasteryLevel: 1.0,
        previousLevel: MasteryLevel.novice,
        currentLevel: MasteryLevel.expert,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.previousAccuracy, 1.0);
      expect(restored.currentAccuracy, 0.0);
      expect(restored.accuracyDelta, -1.0);
      expect(restored.currentMasteryLevel, 1.0);
    });
  });
}
