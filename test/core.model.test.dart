import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/main.dart' as app;
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/questions/models/markscheme_model.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('StudyKing App', () {
    testWidgets('App loads successfully', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: app.StudyKingApp()));
    });
  });

  group('Question Model', () {
    late Question testQuestion;

    setUp(() {
      testQuestion = Question(
        id: 'test-1',
        text: 'What is capital of France?',
        type: QuestionType.singleChoice,
        subjectId: 'math',
        topicId: 'geometry',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        difficulty: 2,
        markscheme: Markscheme(questionId: 'test-1', correctAnswer: 'Paris'),
        tags: ['geography', 'capital'],
      );
    });

    test('Question serializes correctly', () {
      final json = testQuestion.toJson();
      expect(json['id'], equals('test-1'));
      expect(json['type'], equals(0));
      expect(json['difficulty'], equals(2));
    });

    test('Question deserializes correctly', () {
      final json = testQuestion.toJson();
      final restored = Question.fromJson(json);
      expect(restored.id, equals(testQuestion.id));
      expect(restored.text, equals(testQuestion.text));
      expect(restored.difficulty, equals(testQuestion.difficulty));
    });

    test('Empty tags list defaults to empty', () {
      expect(testQuestion.tags, isEmpty);
    });
  });

  group('Question Type Enums', () {
    test('QuestionType enum values', () {
      expect(QuestionType.singleChoice.index, equals(0));
      expect(QuestionType.multiChoice.index, equals(1));
      expect(QuestionType.typedAnswer.index, equals(2));
      expect(QuestionType.essay.index, equals(3));
      expect(QuestionType.mathExpression.index, equals(4));
      expect(QuestionType.canvas.index, equals(5));
      expect(QuestionType.stepByStep.index, equals(6));
    });
  });
}
