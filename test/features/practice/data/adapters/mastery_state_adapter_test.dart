import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:studyking/features/practice/data/adapters/mastery_state_adapter.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';

void main() {
  group('MasteryStateAdapter', () {
    test('typeId is 16', () {
      expect(MasteryStateAdapter().typeId, 16);
    });

    test('hashCode and equality', () {
      expect(MasteryStateAdapter().hashCode, MasteryStateAdapter().hashCode);
      expect(MasteryStateAdapter() == MasteryStateAdapter(), isTrue);
    });

    test('write/read round-trip', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(MasteryStateAdapter());
      final adapter = MasteryStateAdapter();
      final now = DateTime.now();
      final source = MasteryState(
        studentId: 'student1',
        topicId: 'topic1',
        accuracy: 0.85,
        confidenceTrend: 0.75,
        speedTrend: 0.65,
        forgettingRisk: 0.1,
        totalAttempts: 20,
        correctAttempts: 17,
        averageTimeMs: 45000.0,
        lastAttempt: now,
        lastUpdated: now,
        currentStreak: 5,
        bestStreak: 8,
        recentConfidence: [3, 4, 5],
        recentAccuracy: [0.8, 0.9, 0.85],
        masteryLevel: MasteryLevel.proficient,
        readinessScore: 0.9,
        reviewUrgency: 0.2,
        weakSubtopics: ['subtopic_a'],
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.studentId, 'student1');
      expect(restored.topicId, 'topic1');
      expect(restored.accuracy, 0.85);
      expect(restored.confidenceTrend, 0.75);
      expect(restored.totalAttempts, 20);
      expect(restored.correctAttempts, 17);
      expect(restored.currentStreak, 5);
      expect(restored.bestStreak, 8);
      expect(restored.recentConfidence, [3, 4, 5]);
      expect(restored.masteryLevel, MasteryLevel.proficient);
    });

    test('write/read with minimal fields', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(MasteryStateAdapter());
      final adapter = MasteryStateAdapter();
      final now = DateTime.now();
      final source = MasteryState(studentId: 's1', topicId: 't1', lastAttempt: now, lastUpdated: now);

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.accuracy, 0.0);
      expect(restored.totalAttempts, 0);
      expect(restored.currentStreak, 0);
      expect(restored.masteryLevel, MasteryLevel.novice);
    });
  });
}
