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

    test('write/read round-trip', () {
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
  });
}
