import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/questions/data/models/markscheme_model.dart';
import 'package:studyking/features/questions/data/models/question_evaluation_model.dart';
import 'package:studyking/core/services/answer_validation_service.dart';

Question _question({
  required String id,
  required QuestionType type,
  String correctAnswer = '',
  List<String> acceptableAnswers = const [],
}) {
  return Question(
    id: id,
    text: 'Test question',
    type: type,
    subjectId: 'subject-a',
    topicId: 'topic-a',
    markscheme: Markscheme(
      questionId: id,
      correctAnswer: correctAnswer,
      acceptableAnswers: acceptableAnswers,
    ),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void main() {
  group('AnswerValidationService', () {
    late AnswerValidationService service;

    setUp(() {
      service = AnswerValidationService();
    });

    test('returns incorrect result when markscheme is null', () {
      final question = Question(
        id: 'q-no-ms',
        text: 'No markscheme',
        type: QuestionType.typedAnswer,
        subjectId: 's1',
        topicId: 't1',
        markscheme: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = service.validateAnswerForQuestion(question, 'any answer');
      expect(result.isCorrect, isFalse);
      expect(result.explanation, contains('No markscheme'));
    });

    test('validates correct typed answer', () {
      final question = _question(
        id: 'q1',
        type: QuestionType.typedAnswer,
        correctAnswer: 'Paris',
      );

      final result = service.validateAnswerForQuestion(question, 'Paris');
      expect(result.isCorrect, isTrue);
    });

    test('validates incorrect typed answer', () {
      final question = _question(
        id: 'q2',
        type: QuestionType.typedAnswer,
        correctAnswer: 'Paris',
      );

      final result = service.validateAnswerForQuestion(question, 'London');
      expect(result.isCorrect, isFalse);
    });

    test('caches validator for same question', () {
      final question = _question(
        id: 'q-cache',
        type: QuestionType.typedAnswer,
        correctAnswer: '42',
      );

      final result1 = service.validateAnswerForQuestion(question, '42');
      final result2 = service.validateAnswerForQuestion(question, '42');
      expect(result1.isCorrect, isTrue);
      expect(result2.isCorrect, isTrue);
    });

    test('cache miss on first call', () {
      final question = _question(
        id: 'q-first',
        type: QuestionType.typedAnswer,
        correctAnswer: 'first',
      );
      final result = service.validateAnswerForQuestion(question, 'first');
      expect(result.isCorrect, isTrue);
    });

    test('cache hit on repeated call with same markscheme', () {
      final q1 = _question(id: 'q-hit', type: QuestionType.typedAnswer, correctAnswer: 'A');
      final q2 = _question(id: 'q-hit', type: QuestionType.typedAnswer, correctAnswer: 'A');

      expect(service.validateAnswerForQuestion(q1, 'A').isCorrect, isTrue);
      expect(service.validateAnswerForQuestion(q2, 'A').isCorrect, isTrue);
    });

    test('invalidates cache when markscheme changes', () {
      final question1 = _question(
        id: 'q-change',
        type: QuestionType.typedAnswer,
        correctAnswer: 'old',
      );
      final question2 = _question(
        id: 'q-change',
        type: QuestionType.typedAnswer,
        correctAnswer: 'new',
      );

      final result1 = service.validateAnswerForQuestion(question1, 'old');
      expect(result1.isCorrect, isTrue);

      final result2 = service.validateAnswerForQuestion(question2, 'new');
      expect(result2.isCorrect, isTrue);
    });

    test('invalidates cache when acceptableAnswers change', () {
      final q1 = _question(
        id: 'q-accept-change', type: QuestionType.typedAnswer,
        correctAnswer: 'Paris', acceptableAnswers: ['paris'],
      );
      final q2 = _question(
        id: 'q-accept-change', type: QuestionType.typedAnswer,
        correctAnswer: 'Paris', acceptableAnswers: ['PARIS', 'City of Light'],
      );

      expect(service.validateAnswerForQuestion(q1, 'paris').isCorrect, isTrue);
      expect(service.validateAnswerForQuestion(q2, 'PARIS').isCorrect, isTrue);
    });

    test('validates single choice answer', () {
      final question = _question(
        id: 'q-sc',
        type: QuestionType.singleChoice,
        correctAnswer: 'Option A',
      );

      final result = service.validateAnswerForQuestion(question, 'Option A');
      expect(result.isCorrect, isTrue);
    });

    test('validates multi choice answer', () {
      final question = _question(
        id: 'q-mc',
        type: QuestionType.multiChoice,
        correctAnswer: 'A,B',
      );

      final result = service.validateAnswerForQuestion(question, 'A,B');
      expect(result.isCorrect, isTrue);
    });

    test('returns incorrect for canvas drawing answer via validateAnswerForQuestion (string input is not valid canvas data)', () {
      final question = _question(
        id: 'q-canvas',
        type: QuestionType.canvas,
        correctAnswer: 'Drawing submitted',
      );

      final result = service.validateAnswerForQuestion(question, 'Drawing submitted');
      expect(result.isCorrect, isFalse);
    });

    test('validates essay answer (length > 50 chars is correct)', () {
      final question = _question(
        id: 'q-essay',
        type: QuestionType.essay,
        correctAnswer: '',
      );

      final result = service.validateAnswerForQuestion(question, 'A' * 60);
      expect(result.isCorrect, isTrue);
    });

    test('accepts answers from acceptable answers list', () {
      final question = _question(
        id: 'q-accept',
        type: QuestionType.typedAnswer,
        correctAnswer: 'Paris',
        acceptableAnswers: ['paris', 'PARIS', 'city of light'],
      );

      final result = service.validateAnswerForQuestion(question, 'paris');
      expect(result.isCorrect, isTrue);
    });

    test('validates math expression answer', () {
      final question = _question(
        id: 'q-math',
        type: QuestionType.mathExpression,
        correctAnswer: 'x=2',
      );

      final result = service.validateAnswerForQuestion(question, 'x=2');
      expect(result.isCorrect, isTrue);
    });

    test('validateWithMarkscheme returns correct for exact match', () {
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'Berlin');
      final result = service.validateWithMarkscheme('Berlin', QuestionType.typedAnswer, markscheme);
      expect(result.isCorrect, isTrue);
    });

    test('validateWithMarkscheme returns incorrect for null markscheme', () {
      final result = service.validateWithMarkscheme('answer', QuestionType.typedAnswer, null);
      expect(result.isCorrect, isFalse);
    });

    test('validateWithMarkscheme returns correct for acceptable answer', () {
      final markscheme = Markscheme(
        questionId: 'q1', correctAnswer: 'Berlin',
        acceptableAnswers: ['berlin', 'germany capital'],
      );
      final result = service.validateWithMarkscheme('berlin', QuestionType.typedAnswer, markscheme);
      expect(result.isCorrect, isTrue);
    });

    test('validateWithEvaluation exact match returns correct', () {
      final evaluation = QuestionEvaluation(
        questionId: 'q1', correctAnswer: '42',
      );
      final result = service.validateWithEvaluation(evaluation, '42');
      expect(result.isCorrect, isTrue);
      expect(result.score, 1.0);
    });

    test('validateWithEvaluation mismatch returns incorrect', () {
      final evaluation = QuestionEvaluation(
        questionId: 'q1', correctAnswer: 'Paris',
        explanation: 'Capital of France',
      );
      final result = service.validateWithEvaluation(evaluation, 'London');
      expect(result.isCorrect, isFalse);
      expect(result.feedback, contains('Incorrect'));
    });

    test('validateWithEvaluation fuzzy match exact answer returns correct', () {
      final evaluation = QuestionEvaluation(
        questionId: 'q1', correctAnswer: 'photosynthesis',
        evaluationType: EvaluationType.fuzzyMatch,
      );
      final result = service.validateWithEvaluation(evaluation, 'photosynthesis');
      expect(result.isCorrect, isTrue);
    });

    test('validateWithEvaluation step based match', () {
      final evaluation = QuestionEvaluation(
        questionId: 'q1', correctAnswer: 'steps',
        evaluationType: EvaluationType.stepBased,
        steps: [
          EvaluationStep(stepNumber: '1', requiredAnswer: 'step1', points: 1.0),
          EvaluationStep(stepNumber: '2', requiredAnswer: 'step2', points: 1.0),
        ],
      );
      final result = service.validateWithEvaluation(evaluation, 'my answer has step1 and step2');
      expect(result.isCorrect, isTrue);
    });

    test('validateWithEvaluation with acceptable answer match', () {
      final evaluation = QuestionEvaluation(
        questionId: 'q1', correctAnswer: 'Paris',
        acceptableAnswers: ['paris', 'PARIS'],
        evaluationType: EvaluationType.acceptableMatch,
      );
      final result = service.validateWithEvaluation(evaluation, 'PARIS');
      expect(result.isCorrect, isTrue);
    });

    test('validateAnswer returns correct result via validate method', () {
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'correct');
      final result = service.validateAnswer('correct', QuestionType.typedAnswer, 'q1', markscheme);
      expect(result.isCorrect, isTrue);
    });

    test('generates unique signature for different correct answers', () {
      final service2 = AnswerValidationService();
      final q1 = _question(id: 'q1', type: QuestionType.typedAnswer, correctAnswer: 'Answer A');
      final q2 = _question(id: 'q2', type: QuestionType.typedAnswer, correctAnswer: 'Answer B');
      final r1 = service2.validateAnswerForQuestion(q1, 'Answer A');
      final r2 = service2.validateAnswerForQuestion(q2, 'Answer B');
      expect(r1.isCorrect, isTrue);
      expect(r2.isCorrect, isTrue);
    });

    test('uses default explanation when question explanation is null', () {
      final question = _question(id: 'no-explanation', type: QuestionType.typedAnswer, correctAnswer: 'Answer');
      final correctResult = service.validateAnswerForQuestion(question, 'answer');
      final wrongResult = service.validateAnswerForQuestion(question, 'wrong');
      expect(correctResult.explanation, 'Correct!');
      expect(wrongResult.explanation, 'Incorrect.');
    });

    test('handles empty options list', () {
      final question = _question(id: 'empty-options', type: QuestionType.typedAnswer, correctAnswer: 'Correct');
      expect(service.validateAnswerForQuestion(question, 'Correct').isCorrect, isTrue);
      expect(service.validateAnswerForQuestion(question, 'wrong').isCorrect, isFalse);
    });

    test('handles null markscheme in question', () {
      final question = Question(
        id: 'null-markscheme', text: 'Q', type: QuestionType.typedAnswer,
        subjectId: 's1', topicId: 't1', markscheme: null,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final result = service.validateAnswerForQuestion(question, 'anything');
      expect(result.isCorrect, isFalse);
    });

    test('handles empty string markscheme', () {
      final question = _question(id: 'empty-ms', type: QuestionType.typedAnswer, correctAnswer: '');
      final result = service.validateAnswerForQuestion(question, 'answer');
      expect(result.isCorrect, isFalse);
    });

    test('handles whitespace-only answer', () {
      final question = _question(id: 'ws', type: QuestionType.typedAnswer, correctAnswer: 'correct');
      final result = service.validateAnswerForQuestion(question, '   ');
      expect(result.isCorrect, isFalse);
    });

    test('handles very long answer', () {
      final question = _question(id: 'long', type: QuestionType.typedAnswer, correctAnswer: 'answer');
      final result = service.validateAnswerForQuestion(question, 'a' * 1000);
      expect(result.isCorrect, isFalse);
    });

    test('handles special characters in markscheme', () {
      final question = _question(id: 'special', type: QuestionType.typedAnswer, correctAnswer: 'Test <>&"\'123');
      expect(service.validateAnswerForQuestion(question, 'test <>&"\'123').isCorrect, isTrue);
    });

    test('validates multiple questions in sequence correctly', () {
      final questions = [
        _question(id: 'seq-1', type: QuestionType.typedAnswer, correctAnswer: 'Answer 1'),
      ];
      questions.add(_question(id: 'seq-2', type: QuestionType.singleChoice, correctAnswer: 'A'));
      questions.add(_question(id: 'seq-3', type: QuestionType.multiChoice, correctAnswer: 'A,B'));

      expect(service.validateAnswerForQuestion(questions[0], 'answer 1').isCorrect, isTrue);
      expect(service.validateAnswerForQuestion(questions[1], 'A').isCorrect, isTrue);
      expect(service.validateAnswerForQuestion(questions[2], 'A,B').isCorrect, isTrue);
    });

    test('validates step by step answer with steps', () {
      final question = Question(
        id: 'q-steps',
        text: 'Steps',
        type: QuestionType.stepByStep,
        subjectId: 's1',
        topicId: 't1',
        markscheme: Markscheme(
          questionId: 'q-steps',
          correctAnswer: 'answer',
          steps: [
            MarkSchemeStep(stepNumber: '1', requiredAnswer: 'step1', points: 1.0),
          ],
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = service.validateAnswerForQuestion(question, 'no steps here');
      expect(result.isCorrect, isFalse);
    });

    test('validateMCQAnswer multi-choice partial match returns incorrect', () {
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'A,B,C');
      final result = service.validateWithMarkscheme('A,B', QuestionType.multiChoice, markscheme);
      expect(result.isCorrect, isFalse);
    });

    test('validateMCQAnswer multi-choice exact match with different order', () {
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'A,B');
      final result = service.validateWithMarkscheme('B,A', QuestionType.multiChoice, markscheme);
      expect(result.isCorrect, isTrue);
    });

    test('validateMathExpression normalizes spaces', () {
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'x=2');
      final result = service.validateWithMarkscheme('x = 2', QuestionType.mathExpression, markscheme);
      expect(result.isCorrect, isTrue);
    });

    test('validateMathExpression ignores case differences', () {
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'X*2=4');
      final result = service.validateWithMarkscheme('x*2=4', QuestionType.mathExpression, markscheme);
      expect(result.isCorrect, isTrue);
    });

    test('validateMathExpression detects different expressions', () {
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'x+2=4');
      final result = service.validateWithMarkscheme('x*2=4', QuestionType.mathExpression, markscheme);
      expect(result.isCorrect, isFalse);
    });

    test('validateMathExpression returns incorrect for wrong answer', () {
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'x=2');
      final result = service.validateWithMarkscheme('x=3', QuestionType.mathExpression, markscheme);
      expect(result.isCorrect, isFalse);
    });

    test('validateMathExpression returns incorrect when markscheme is null', () {
      final result = service.validateWithMarkscheme('x=2', QuestionType.mathExpression, null);
      expect(result.isCorrect, isFalse);
    });

    test('validateEssayAnswer empty answer returns incorrect', () {
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: '');
      final result = service.validateWithMarkscheme('', QuestionType.essay, markscheme);
      expect(result.isCorrect, isFalse);
    });

    test('validateEssayAnswer answer between 10 and 50 chars returns incorrect but not empty', () {
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: '');
      final result = service.validateWithMarkscheme('Exactly 20 chars!!', QuestionType.essay, markscheme);
      expect(result.isCorrect, isFalse);
    });

    test('validateEssayAnswer answer exactly 10 chars returns incorrect', () {
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: '');
      final tenChars = 'A' * 10;
      final result = service.validateWithMarkscheme(tenChars, QuestionType.essay, markscheme);
      expect(result.isCorrect, isFalse);
    });

    test('validateEssayAnswer answer just under 10 chars returns incorrect', () {
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: '');
      final nineChars = 'A' * 9;
      final result = service.validateWithMarkscheme(nineChars, QuestionType.essay, markscheme);
      expect(result.isCorrect, isFalse);
    });

    test('validateCanvasDrawing with non-empty valid data returns correct', () {
      final canvasData = [{'x': 10.0, 'y': 20.0}];
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: '');
      final result = QuestionAnswerValidator.validateCanvasDrawing(canvasData, markscheme);
      expect(result.isCorrect, isTrue);
    });

    test('validateCanvasDrawing with empty data returns incorrect', () {
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: '');
      final result = QuestionAnswerValidator.validateCanvasDrawing([], markscheme);
      expect(result.isCorrect, isFalse);
    });

    test('validateCanvasDrawing with empty map returns incorrect', () {
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: '');
      final result = QuestionAnswerValidator.validateCanvasDrawing([{}], markscheme);
      expect(result.isCorrect, isFalse);
    });

    test('validateStepByStep with markscheme checks all steps', () {
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: '', steps: [
        MarkSchemeStep(stepNumber: '1', requiredAnswer: 'step1', points: 1.0),
        MarkSchemeStep(stepNumber: '2', requiredAnswer: 'step2', points: 1.0),
      ]);
      final result = QuestionAnswerValidator.validateStepByStep('includes step1 and step2', markscheme);
      expect(result.isCorrect, isTrue);
    });

    test('validateStepByStep with missing steps returns incorrect', () {
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: '', steps: [
        MarkSchemeStep(stepNumber: '1', requiredAnswer: 'step1', points: 1.0),
        MarkSchemeStep(stepNumber: '2', requiredAnswer: 'step2', points: 1.0),
      ]);
      final result = QuestionAnswerValidator.validateStepByStep('only step1', markscheme);
      expect(result.isCorrect, isFalse);
    });

    test('validateStepByStep with null markscheme returns incorrect', () {
      final result = QuestionAnswerValidator.validateStepByStep('answer', null);
      expect(result.isCorrect, isFalse);
    });

    test('validateWithEvaluation with correctLabel shows correct label', () {
      final evaluation = QuestionEvaluation(
        questionId: 'q1', correctAnswer: '42',
      );
      final result = service.validateWithEvaluation(evaluation, '42', correctLabel: 'Perfect!');
      expect(result.feedback, 'Perfect!');
    });

    test('validateWithEvaluation with incorrectPrefix shows prefixed message', () {
      final evaluation = QuestionEvaluation(
        questionId: 'q1', correctAnswer: 'Paris',
        explanation: 'Capital city',
      );
      final result = service.validateWithEvaluation(evaluation, 'London', incorrectPrefix: 'Wrong.');
      expect(result.feedback, 'Wrong. Capital city');
    });

    test('validateWithEvaluation no explanation uses correctAnswerIs format', () {
      final evaluation = QuestionEvaluation(
        questionId: 'q1', correctAnswer: 'Paris',
      );
      final result = service.validateWithEvaluation(evaluation, 'London');
      expect(result.feedback, contains('Paris'));
    });

    test('validateWithEvaluation stepBased with steps scores correctly', () {
      final evaluation = QuestionEvaluation(
        questionId: 'q1', correctAnswer: 'answer',
        evaluationType: EvaluationType.stepBased,
        steps: [
          EvaluationStep(stepNumber: '1', requiredAnswer: 'step1', points: 1.0),
          EvaluationStep(stepNumber: '2', requiredAnswer: 'step2', points: 2.0),
        ],
      );
      final result = service.validateWithEvaluation(evaluation, 'has step2 but not step1');
      expect(result.score, greaterThan(0.0));
    });

    test('validateWithEvaluation with acceptable answer match via acceptableAnswers', () {
      final evaluation = QuestionEvaluation(
        questionId: 'q1', correctAnswer: 'Red',
        acceptableAnswers: ['blue', 'green'],
        evaluationType: EvaluationType.acceptableMatch,
      );
      final result = service.validateWithEvaluation(evaluation, 'blue');
      expect(result.isCorrect, isTrue);
    });

    test('validateWithEvaluation fuzzy match similar answer', () {
      final evaluation = QuestionEvaluation(
        questionId: 'q1', correctAnswer: 'the quick brown fox',
        evaluationType: EvaluationType.fuzzyMatch,
      );
      final result = service.validateWithEvaluation(evaluation, 'the quick brown fox jumps over');
      expect(result.isCorrect, isTrue);
    });

    test('validateWithEvaluation fuzzy match dissimilar answer', () {
      final evaluation = QuestionEvaluation(
        questionId: 'q1', correctAnswer: 'mitosis cell division',
        evaluationType: EvaluationType.fuzzyMatch,
      );
      final result = service.validateWithEvaluation(evaluation, 'quantum physics');
      expect(result.isCorrect, isFalse);
    });

    test('graphDrawing question type returns special handling message', () {
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: '');
      final result = QuestionAnswerValidator.validateStatic('', QuestionType.graphDrawing, markscheme);
      expect(result.isCorrect, isFalse);
    });

    test('fileUpload question type returns special handling message', () {
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: '');
      final result = QuestionAnswerValidator.validateStatic('', QuestionType.fileUpload, markscheme);
      expect(result.isCorrect, isFalse);
    });

    test('audioRecording question type returns special handling message', () {
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: '');
      final result = QuestionAnswerValidator.validateStatic('', QuestionType.audioRecording, markscheme);
      expect(result.isCorrect, isFalse);
    });

    test('validateWithMarkscheme multiChoice with null markscheme returns incorrect', () {
      final result = service.validateWithMarkscheme('A', QuestionType.multiChoice, null);
      expect(result.isCorrect, isFalse);
    });

    test('custom messages used when provided', () {
      final customMessages = ValidationMessages(
        markschemeUnavailable: 'Custom MS unavailable',
        pleaseProvideAnswer: 'Custom provide answer',
        correct: 'Custom correct!',
        incorrect: 'Custom incorrect.',
        answerTooShort: 'Custom too short',
        goodResponseLength: 'Custom good length',
        answerTooShortForCredit: 'Custom too short for credit',
        noDrawingDetected: 'Custom no drawing',
        invalidDrawingData: 'Custom invalid drawing',
        drawingDetected: 'Custom drawing detected',
        allStepsIdentified: 'Custom all steps identified',
        specialHandlingRequired: 'Custom special handling',
      );
      final serviceWithMessages = AnswerValidationService(messages: customMessages);
      final question = _question(id: 'q-msgs', type: QuestionType.typedAnswer, correctAnswer: 'Answer');
      final result = serviceWithMessages.validateAnswerForQuestion(question, 'wrong');
      expect(result.explanation, 'Custom incorrect.');
    });
  });

  group('ValidationMessages', () {
    test('english defaults are pre-defined', () {
      expect(ValidationMessages.english.correct, 'Correct!');
      expect(ValidationMessages.english.incorrect, 'Incorrect.');
      expect(ValidationMessages.english.markschemeUnavailable, 'No markscheme available');
    });

    test('someAnswersIncorrect with empty explanation returns fallback', () {
      expect(ValidationMessages.english.someAnswersIncorrect(''), 'Some answers are incorrect');
    });

    test('someAnswersIncorrect with non-empty explanation returns explanation', () {
      expect(ValidationMessages.english.someAnswersIncorrect('Custom msg'), 'Custom msg');
    });

    test('correctAnswerIs formats correctly', () {
      expect(ValidationMessages.english.correctAnswerIs('42'), 'The correct answer is: 42');
    });

    test('allStepsFormat formats correctly', () {
      expect(ValidationMessages.english.allStepsFormat(3), 'All 3 steps identified correctly!');
    });

    test('partialStepsFormat formats correctly', () {
      expect(
        ValidationMessages.english.partialStepsFormat(2, 5, 'step3, step4'),
        'Identified 2 of 5 steps. Missing: step3, step4',
      );
    });

    test('noStepsFormat formats correctly', () {
      expect(
        ValidationMessages.english.noStepsFormat('step1, step2'),
        'No required steps found in your answer. Key steps to include: step1, step2',
      );
    });

    test('allRequiredStepsMissing returns fallback', () {
      expect(ValidationMessages.english.allRequiredStepsMissing(), 'Some required steps missing');
    });

    test('default constructor provides empty strings', () {
      const msgs = ValidationMessages();
      expect(msgs.correct, '');
      expect(msgs.incorrect, '');
      expect(msgs.markschemeUnavailable, '');
    });
  });
}
