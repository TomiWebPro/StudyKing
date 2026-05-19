import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/core/utils/sr_data_codec.dart';

void main() {
  group('SrDataCodec', () {
    group('serialize', () {
      test('serializes all fields', () {
        final data = QuestionSRData(
          repetitions: 3,
          easeFactor: 1.8,
          previousInterval: const Duration(days: 7),
          lastReview: DateTime(2025, 5, 25, 10, 30),
        );
        final json = SrDataCodec.serialize(data);
        expect(json, contains('"r":3'));
        expect(json, contains('"ef":1.8'));
        expect(json, contains('"pi"'));
        expect(json, contains('"lr"'));
      });

      test('serializes without optional fields', () {
        final data = const QuestionSRData(repetitions: 0);
        final json = SrDataCodec.serialize(data);
        expect(json, contains('"r":0'));
        expect(json, contains('"ef":2.5'));
        expect(json, isNot(contains('"pi"')));
        expect(json, isNot(contains('"lr"')));
      });

      test('serializes with edge ease factor', () {
        final data = const QuestionSRData(easeFactor: 1.3);
        final json = SrDataCodec.serialize(data);
        expect(json, contains('"ef":1.3'));
      });
    });

    group('deserialize', () {
      test('returns default for null input', () {
        final data = SrDataCodec.deserialize(null);
        expect(data.repetitions, 0);
        expect(data.easeFactor, 2.5);
        expect(data.previousInterval, isNull);
        expect(data.lastReview, isNull);
      });

      test('returns default for empty string', () {
        final data = SrDataCodec.deserialize('');
        expect(data.repetitions, 0);
        expect(data.easeFactor, 2.5);
      });

      test('returns default for invalid JSON', () {
        final data = SrDataCodec.deserialize('not json');
        expect(data.repetitions, 0);
        expect(data.easeFactor, 2.5);
      });

      test('deserializes all fields correctly', () {
        final json =
            '{"r":5,"ef":1.5,"pi":86400000,"lr":1718000000000}';
        final data = SrDataCodec.deserialize(json);
        expect(data.repetitions, 5);
        expect(data.easeFactor, 1.5);
        expect(data.previousInterval, const Duration(milliseconds: 86400000));
        expect(data.lastReview, DateTime.fromMillisecondsSinceEpoch(1718000000000));
      });

      test('deserializes with missing fields', () {
        final json = '{"r":2}';
        final data = SrDataCodec.deserialize(json);
        expect(data.repetitions, 2);
        expect(data.easeFactor, 2.5);
        expect(data.previousInterval, isNull);
        expect(data.lastReview, isNull);
      });
    });

    group('round-trip', () {
      test('encode then decode returns equivalent data', () {
        final original = QuestionSRData(
          repetitions: 4,
          easeFactor: 2.0,
          previousInterval: const Duration(days: 14),
          lastReview: DateTime(2025, 6, 1),
        );
        final json = SrDataCodec.serialize(original);
        final decoded = SrDataCodec.deserialize(json);
        expect(decoded.repetitions, original.repetitions);
        expect(decoded.easeFactor, original.easeFactor);
        expect(decoded.previousInterval, original.previousInterval);
        expect(decoded.lastReview, original.lastReview);
      });

      test('round-trip with null optionals', () {
        final original = const QuestionSRData();
        final json = SrDataCodec.serialize(original);
        final decoded = SrDataCodec.deserialize(json);
        expect(decoded.repetitions, 0);
        expect(decoded.easeFactor, 2.5);
        expect(decoded.previousInterval, isNull);
        expect(decoded.lastReview, isNull);
      });
    });
  });
}
