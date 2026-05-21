import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/utils/sr_data_codec.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';

void main() {
  group('SrDataCodec', () {
    group('serialize/deserialize round-trip', () {
      test('round-trips with realistic QuestionSRData', () {
        final data = QuestionSRData(
          repetitions: 5,
          easeFactor: 1.8,
          previousInterval: const Duration(days: 7),
          lastReview: DateTime(2026, 5, 15),
          reviewLog: const [],
        );
        final json = SrDataCodec.serialize(data);
        final restored = SrDataCodec.deserialize(json);
        expect(restored.repetitions, 5);
        expect(restored.easeFactor, 1.8);
        expect(restored.previousInterval, const Duration(days: 7));
        expect(restored.lastReview, DateTime(2026, 5, 15));
      });

      test('round-trips with default QuestionSRData', () {
        const data = QuestionSRData();
        final json = SrDataCodec.serialize(data);
        final restored = SrDataCodec.deserialize(json);
        expect(restored.repetitions, 0);
        expect(restored.easeFactor, 2.5);
        expect(restored.previousInterval, isNull);
        expect(restored.lastReview, isNull);
      });

      test('round-trips with optional fields absent', () {
        final data = QuestionSRData(repetitions: 3, easeFactor: 2.0);
        final json = SrDataCodec.serialize(data);
        final restored = SrDataCodec.deserialize(json);
        expect(restored.repetitions, 3);
        expect(restored.easeFactor, 2.0);
        expect(restored.previousInterval, isNull);
        expect(restored.lastReview, isNull);
      });
    });

    group('deserialize edge cases', () {
      test('null input returns defaults', () {
        final result = SrDataCodec.deserialize(null);
        expect(result.repetitions, 0);
        expect(result.easeFactor, 2.5);
        expect(result.previousInterval, isNull);
        expect(result.lastReview, isNull);
      });

      test('empty string returns defaults', () {
        final result = SrDataCodec.deserialize('');
        expect(result.repetitions, 0);
        expect(result.easeFactor, 2.5);
      });

      test('malformed JSON returns defaults', () {
        final result = SrDataCodec.deserialize('not json');
        expect(result.repetitions, 0);
        expect(result.easeFactor, 2.5);
      });

      test('wrong JSON type returns defaults', () {
        final result = SrDataCodec.deserialize('"string"');
        expect(result.repetitions, 0);
        expect(result.easeFactor, 2.5);
      });

      test('partial data preserves known fields and fills defaults', () {
        final result = SrDataCodec.deserialize('{"r": 3}');
        expect(result.repetitions, 3);
        expect(result.easeFactor, 2.5);
        expect(result.previousInterval, isNull);
        expect(result.lastReview, isNull);
      });

      test('partial data with ef only', () {
        final result = SrDataCodec.deserialize('{"ef": 1.5}');
        expect(result.repetitions, 0);
        expect(result.easeFactor, 1.5);
      });

      test('partial data with all optional fields', () {
        final result = SrDataCodec.deserialize(
          '{"r": 2, "ef": 1.3, "pi": 86400000, "lr": 1717200000000}',
        );
        expect(result.repetitions, 2);
        expect(result.easeFactor, 1.3);
        expect(result.previousInterval, const Duration(milliseconds: 86400000));
        expect(result.lastReview, DateTime.fromMillisecondsSinceEpoch(1717200000000));
      });
    });
  });
}
