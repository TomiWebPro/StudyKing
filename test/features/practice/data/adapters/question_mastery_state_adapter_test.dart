import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:studyking/features/practice/data/adapters/question_mastery_state_adapter.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';

void main() {
  group('QuestionMasteryStateAdapter', () {
    test('typeId is 18', () {
      expect(QuestionMasteryStateAdapter().typeId, 18);
    });

    test('hashCode and equality', () {
      expect(QuestionMasteryStateAdapter().hashCode, QuestionMasteryStateAdapter().hashCode);
      expect(QuestionMasteryStateAdapter() == QuestionMasteryStateAdapter(), isTrue);
    });

    test('write/read round-trip with all fields', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(QuestionMasteryStateAdapter());
      final adapter = QuestionMasteryStateAdapter();
      final now = DateTime.now();
      final source = QuestionMasteryState(
        studentId: 's1',
        questionId: 'q1',
        correctCount: 5,
        incorrectCount: 2,
        currentStreak: 3,
        bestStreak: 7,
        averageTimeMs: 30000.0,
        confidenceHistory: [3, 4, 5],
        lastAttempt: now,
        lastCorrect: now.subtract(const Duration(hours: 1)),
        lastIncorrect: now.subtract(const Duration(days: 1)),
        nextReview: now.add(const Duration(days: 1)),
        masteryLevel: 0.75,
        reviewUrgency: 0.3,
        totalTimeMs: 150000,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.studentId, 's1');
      expect(restored.questionId, 'q1');
      expect(restored.correctCount, 5);
      expect(restored.incorrectCount, 2);
      expect(restored.currentStreak, 3);
      expect(restored.bestStreak, 7);
      expect(restored.averageTimeMs, 30000.0);
      expect(restored.confidenceHistory, [3, 4, 5]);
      expect(restored.lastAttempt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(restored.lastCorrect!.millisecondsSinceEpoch, now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch);
      expect(restored.lastIncorrect!.millisecondsSinceEpoch, now.subtract(const Duration(days: 1)).millisecondsSinceEpoch);
      expect(restored.nextReview!.millisecondsSinceEpoch, now.add(const Duration(days: 1)).millisecondsSinceEpoch);
      expect(restored.masteryLevel, 0.75);
      expect(restored.reviewUrgency, 0.3);
      expect(restored.totalTimeMs, 150000);
    });

    test('write/read with minimal fields', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(QuestionMasteryStateAdapter());
      final adapter = QuestionMasteryStateAdapter();
      final now = DateTime.now();
      final source = QuestionMasteryState(studentId: 's1', questionId: 'q1', lastAttempt: now);

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.studentId, 's1');
      expect(restored.questionId, 'q1');
      expect(restored.correctCount, 0);
      expect(restored.incorrectCount, 0);
      expect(restored.currentStreak, 0);
      expect(restored.bestStreak, 0);
      expect(restored.averageTimeMs, 0.0);
      expect(restored.confidenceHistory, isEmpty);
      expect(restored.lastCorrect, isNull);
      expect(restored.lastIncorrect, isNull);
      expect(restored.nextReview, isNull);
      expect(restored.masteryLevel, 0.0);
      expect(restored.reviewUrgency, 1.0);
      expect(restored.totalTimeMs, 0);
    });

    test('write/read with null nullable DateTime fields', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(QuestionMasteryStateAdapter());
      final adapter = QuestionMasteryStateAdapter();
      final now = DateTime.now();
      final source = QuestionMasteryState(
        studentId: 's1',
        questionId: 'q1',
        lastAttempt: now,
        correctCount: 3,
        incorrectCount: 1,
        lastCorrect: null,
        lastIncorrect: null,
        nextReview: null,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.correctCount, 3);
      expect(restored.incorrectCount, 1);
      expect(restored.lastCorrect, isNull);
      expect(restored.lastIncorrect, isNull);
      expect(restored.nextReview, isNull);
    });

    test('write/read with empty confidenceHistory', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(QuestionMasteryStateAdapter());
      final adapter = QuestionMasteryStateAdapter();
      final now = DateTime.now();
      final source = QuestionMasteryState(
        studentId: 's1',
        questionId: 'q1',
        lastAttempt: now,
        confidenceHistory: [],
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.confidenceHistory, isEmpty);
    });

    test('write/read with extreme masteryLevel values', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(QuestionMasteryStateAdapter());
      final adapter = QuestionMasteryStateAdapter();
      final now = DateTime.now();

      final testCases = [
        (0.0, 1.0, 0),
        (1.0, 0.0, 999999),
        (0.5, 0.5, 0),
        (0.999, 0.001, 1),
      ];

      for (final (ml, ru, ttm) in testCases) {
        final source = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          lastAttempt: now,
          masteryLevel: ml,
          reviewUrgency: ru,
          totalTimeMs: ttm,
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.masteryLevel, ml);
        expect(restored.reviewUrgency, ru);
        expect(restored.totalTimeMs, ttm);
      }
    });

    test('write/read with only some optional fields set', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(QuestionMasteryStateAdapter());
      final adapter = QuestionMasteryStateAdapter();
      final now = DateTime.now();
      final lastCorrect = now.subtract(const Duration(hours: 2));
      final source = QuestionMasteryState(
        studentId: 's1',
        questionId: 'q1',
        lastAttempt: now,
        lastCorrect: lastCorrect,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.lastCorrect!.millisecondsSinceEpoch, lastCorrect.millisecondsSinceEpoch);
      expect(restored.lastIncorrect, isNull);
      expect(restored.nextReview, isNull);
    });
  });
}
