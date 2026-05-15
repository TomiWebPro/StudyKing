import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:studyking/features/questions/data/adapters/markscheme_adapter.dart';
import 'package:studyking/features/questions/data/models/markscheme_model.dart';

void main() {
  group('MarkschemeAdapter', () {
    test('typeId is 12', () {
      expect(MarkschemeAdapter().typeId, 12);
    });

    test('hashCode and equality', () {
      final a1 = MarkschemeAdapter();
      final a2 = MarkschemeAdapter();
      expect(a1.hashCode, a2.hashCode);
      expect(a1 == a2, isTrue);
      expect(a1 == Object(), isFalse);
    });

    test('write/read round-trip', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(MarkschemeAdapter())
        ..registerAdapter(MarkSchemeStepAdapter());
      final adapter = MarkschemeAdapter();
      final source = Markscheme(
        questionId: 'q1',
        correctAnswer: 'Paris',
        acceptableAnswers: ['paris', 'french capital'],
        explanation: 'Capital of France',
        markschemePoints: 2.0,
        steps: [
          MarkSchemeStep(stepNumber: '1', requiredAnswer: 'Name city', points: 1.0),
        ],
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.questionId, 'q1');
      expect(restored.correctAnswer, 'Paris');
      expect(restored.acceptableAnswers, ['paris', 'french capital']);
      expect(restored.explanation, 'Capital of France');
      expect(restored.markschemePoints, 2.0);
      expect(restored.steps.length, 1);
    });

    test('write/read with minimal fields', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(MarkschemeAdapter())
        ..registerAdapter(MarkSchemeStepAdapter());
      final adapter = MarkschemeAdapter();
      final source = Markscheme(correctAnswer: 'Tokyo');

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.correctAnswer, 'Tokyo');
      expect(restored.acceptableAnswers, []);
      expect(restored.steps, []);
    });
  });

  group('MarkSchemeStepAdapter', () {
    test('typeId is 13', () {
      expect(MarkSchemeStepAdapter().typeId, 13);
    });

    test('write/read round-trip', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(MarkSchemeStepAdapter());
      final adapter = MarkSchemeStepAdapter();
      final source = MarkSchemeStep(
        stepNumber: '1',
        requiredAnswer: 'Calculate derivative',
        points: 2.5,
        description: 'First step',
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.stepNumber, '1');
      expect(restored.requiredAnswer, 'Calculate derivative');
      expect(restored.points, 2.5);
      expect(restored.description, 'First step');
    });

    test('hashCode and equality', () {
      expect(MarkSchemeStepAdapter().hashCode, MarkSchemeStepAdapter().hashCode);
      expect(MarkSchemeStepAdapter() == MarkSchemeStepAdapter(), isTrue);
    });
  });
}
