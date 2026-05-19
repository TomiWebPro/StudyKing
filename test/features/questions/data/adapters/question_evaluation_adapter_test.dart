import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:studyking/features/questions/data/adapters/question_evaluation_adapter.dart';
import 'package:studyking/features/questions/data/models/question_evaluation_model.dart';

void main() {
  group('QuestionEvaluationAdapter', () {
    test('typeId is 14', () {
      expect(QuestionEvaluationAdapter().typeId, 14);
    });

    test('hashCode and equality', () {
      expect(QuestionEvaluationAdapter().hashCode, QuestionEvaluationAdapter().hashCode);
      expect(QuestionEvaluationAdapter() == QuestionEvaluationAdapter(), isTrue);
      expect(QuestionEvaluationAdapter() == Object(), isFalse);
    });

    test('write/read round-trip', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(QuestionEvaluationAdapter())
        ..registerAdapter(EvaluationStepAdapter());
      final adapter = QuestionEvaluationAdapter();
      final source = QuestionEvaluation(
        questionId: 'q1',
        correctAnswer: '42',
        acceptableAnswers: ['forty-two', 'quarante-deux'],
        evaluationType: EvaluationType.acceptableMatch,
        explanation: 'The answer to everything',
        steps: [
          EvaluationStep(stepNumber: '1', requiredAnswer: 'Calculate', points: 1.0),
        ],
        maxPoints: 2.0,
        metadata: {'source': 'quiz'},
        version: 2,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.questionId, 'q1');
      expect(restored.correctAnswer, '42');
      expect(restored.acceptableAnswers, ['forty-two', 'quarante-deux']);
      expect(restored.evaluationType, EvaluationType.acceptableMatch);
      expect(restored.explanation, 'The answer to everything');
      expect(restored.steps!.length, 1);
      expect(restored.maxPoints, 2.0);
      expect(restored.metadata!['source'], 'quiz');
      expect(restored.version, 2);
    });

    test('write/read with minimal fields', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(QuestionEvaluationAdapter())
        ..registerAdapter(EvaluationStepAdapter());
      final adapter = QuestionEvaluationAdapter();
      final source = QuestionEvaluation(questionId: 'q2', correctAnswer: 'Yes');

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.acceptableAnswers, []);
      expect(restored.evaluationType, EvaluationType.exactMatch);
      expect(restored.explanation, isNull);
      expect(restored.steps, isNull);
      expect(restored.version, 1);
    });
  });

  group('EvaluationStepAdapter', () {
    test('typeId is 15', () {
      expect(EvaluationStepAdapter().typeId, 15);
    });

    test('write/read round-trip', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(EvaluationStepAdapter());
      final adapter = EvaluationStepAdapter();
      final source = EvaluationStep(
        stepNumber: '1',
        requiredAnswer: 'Step answer',
        points: 1.5,
        description: 'First step',
        partialCredit: 0.5,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.stepNumber, '1');
      expect(restored.requiredAnswer, 'Step answer');
      expect(restored.points, 1.5);
      expect(restored.description, 'First step');
      expect(restored.partialCredit, 0.5);
    });

    test('hashCode and equality', () {
      expect(EvaluationStepAdapter().hashCode, EvaluationStepAdapter().hashCode);
      expect(EvaluationStepAdapter() == EvaluationStepAdapter(), isTrue);
      expect(EvaluationStepAdapter() == Object(), isFalse);
    });
  });
}
