import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/student_attempt_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/mentor/services/syllabus_focus_service.dart';
import 'package:studyking/features/mentor/services/tools/review_mistakes_tool.dart';
import 'package:studyking/features/practice/services/mistake_review_service.dart';

import 'test_helpers.dart';

/// Hand-written fake that overrides the one method the tool calls
/// ([MistakeReviewService.getMistakesFromSession]) so we can control
/// the mistake data without any Hive I/O.
class FakeMistakeReviewService extends MistakeReviewService {
  List<MistakeEntry> mistakes = const [];
  bool shouldFail = false;

  FakeMistakeReviewService()
      : super(
          attemptRepo: FakeAttemptRepository(),
          questionRepo: FakeQuestionRepository(),
        );

  @override
  Future<Result<List<MistakeEntry>>> getMistakesFromSession({
    required String studentId,
    required String subjectId,
    DateTime? after,
  }) async {
    if (shouldFail) {
      return Result.failure('Storage unavailable');
    }
    return Result.success(mistakes);
  }
}

Question _buildQuestion({
  String id = 'q1',
  String subjectId = 'math',
  String topicId = 'fractions',
  String text = 'What is 1/2 + 1/3?',
  String? topic,
  Markscheme? markscheme,
  String? explanation,
  int difficulty = 2,
}) {
  return Question(
    id: id,
    text: text,
    type: QuestionType.typedAnswer,
    subjectId: subjectId,
    topicId: topicId,
    difficulty: difficulty,
    markscheme: markscheme,
    explanation: explanation,
    topic: topic,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

MistakeEntry _buildMistake({
  String questionId = 'q1',
  String subjectId = 'math',
  String topicId = 'fractions',
  String correctAnswer = '5/6',
  String? explanation,
  String userAnswer = '1/3',
}) {
  final question = _buildQuestion(
    id: questionId,
    subjectId: subjectId,
    topicId: topicId,
    markscheme: Markscheme(
      questionId: questionId,
      correctAnswer: correctAnswer,
      explanation: explanation,
    ),
  );
  final attempt = StudentAttempt(
    id: 'a1',
    studentId: 'student-1',
    questionId: questionId,
    subjectId: subjectId,
    isCorrect: false,
    timestamp: DateTime(2026, 1, 1),
    userAnswer: userAnswer,
  );
  return MistakeEntry(
    question: question,
    attempt: attempt,
    correctAnswer: correctAnswer,
    explanation: explanation,
  );
}

void main() {
  group('ReviewMistakesTool', () {
    late FakeStudentIdService studentIdService;
    late FakeMistakeReviewService mistakeService;
    late SyllabusFocusService focusService;

    setUp(() {
      studentIdService = FakeStudentIdService('student-1');
      mistakeService = FakeMistakeReviewService();
      focusService = SyllabusFocusService();
    });

    ReviewMistakesTool buildTool({
      bool withFocus = false,
    }) {
      return ReviewMistakesTool(
        mistakeReviewService: mistakeService,
        studentIdService: studentIdService,
        focusService: withFocus ? focusService : null,
      );
    }

    // -----------------------------------------------------------------
    // Structure
    // -----------------------------------------------------------------
    test('tool name is review_mistakes', () {
      final tool = buildTool();
      expect(tool.name, 'review_mistakes');
    });

    test('description mentions mistakes, markscheme explanation, and concept',
        () {
      final tool = buildTool();
      expect(tool.description, contains('mistake'));
      expect(tool.description, contains('markscheme'));
      expect(tool.description, contains('concept'));
    });

    test('parameters include subjectId, daysBack, and limit', () {
      final tool = buildTool();
      final params = tool.parameters;
      expect(params['type'], 'object');
      expect(params['properties'], containsPair('subjectId', isA<Map>()));
      expect(params['properties'], containsPair('daysBack', isA<Map>()));
      expect(params['properties'], containsPair('limit', isA<Map>()));
      expect(params['required'], isEmpty);
    });

    test('daysBack and limit have defaults in the parameter schema', () {
      final tool = buildTool();
      final params = tool.parameters;
      final props = params['properties'] as Map<String, dynamic>;
      expect(props['daysBack']['default'], 7);
      expect(props['limit']['default'], 10);
    });

    // -----------------------------------------------------------------
    // Behavioural: returns wrong answers with markscheme explanations
    // and concept links (the core vision of this tool)
    // -----------------------------------------------------------------
    test(
        'returns wrong answers with markscheme explanations and concept links '
        'from a recent session', () async {
      mistakeService.mistakes = [
        _buildMistake(
          questionId: 'q1',
          subjectId: 'math',
          topicId: 'fractions',
          correctAnswer: '5/6',
          explanation: 'Add fractions by finding a common denominator.',
          userAnswer: '1/3',
        ),
      ];

      final tool = buildTool();
      final result = await tool.execute({'subjectId': 'math'});

      expect(result['success'], isTrue);
      expect(result['subjectId'], 'math');
      expect(result['totalFound'], 1);

      final mistakes = result['mistakes'] as List;
      expect(mistakes, hasLength(1));
      final m = mistakes.first as Map<String, dynamic>;
      expect(m['questionId'], 'q1');
      expect(m['questionText'], contains('1/2 + 1/3'));
      expect(m['concept'], 'fractions');
      expect(m['subjectId'], 'math');
      expect(m['userAnswer'], '1/3');
      expect(m['correctAnswer'], '5/6');
      expect(m['explanation'], contains('common denominator'));
      expect(m['markschemeExplanation'], contains('common denominator'));
      expect(m['difficulty'], 2);
    });

    test('returns multiple mistakes with distinct concepts', () async {
      mistakeService.mistakes = [
        _buildMistake(
          questionId: 'q1',
          subjectId: 'math',
          topicId: 'fractions',
          correctAnswer: '5/6',
          explanation: 'Common denominator explanation.',
          userAnswer: '1/3',
        ),
        _buildMistake(
          questionId: 'q2',
          subjectId: 'math',
          topicId: 'derivatives',
          correctAnswer: '2x + 3',
          explanation: 'Power rule explanation.',
          userAnswer: 'x^2',
        ),
      ];

      final tool = buildTool();
      final result = await tool.execute({'subjectId': 'math'});

      expect(result['success'], isTrue);
      expect(result['totalFound'], 2);
      final mistakes = result['mistakes'] as List;
      expect(mistakes[0]['concept'], 'fractions');
      expect(mistakes[1]['concept'], 'derivatives');
    });

    test('includes optional topic label and markscheme points when present',
        () async {
      final question = Question(
        id: 'q1',
        text: 'How many grams of CO2?',
        type: QuestionType.typedAnswer,
        subjectId: 'chem',
        topicId: 'stoichiometry',
        difficulty: 3,
        markscheme: Markscheme(
          questionId: 'q1',
          correctAnswer: '44.1g',
          explanation: 'Use molar mass.',
          markschemePoints: 4.0,
        ),
        topic: 'Chemistry',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final attempt = StudentAttempt(
        id: 'a1',
        studentId: 'student-1',
        questionId: 'q1',
        subjectId: 'chem',
        isCorrect: false,
        timestamp: DateTime(2026, 1, 1),
        userAnswer: '22g',
      );
      mistakeService.mistakes = [
        MistakeEntry(
          question: question,
          attempt: attempt,
          correctAnswer: '44.1g',
          explanation: 'Use molar mass.',
        ),
      ];

      final tool = buildTool();
      final result = await tool.execute({'subjectId': 'chem'});

      expect(result['success'], isTrue);
      final m = (result['mistakes'] as List).first as Map;
      expect(m['topic'], 'Chemistry');
      expect(m['points'], 4.0);
    });

    test('returns no-mistakes message when session has none', () async {
      final tool = buildTool();
      final result = await tool.execute({'subjectId': 'math'});

      expect(result['success'], isTrue);
      expect(result['totalFound'], 0);
      expect(result['mistakes'], isEmpty);
      expect(result['message'], contains('No recent mistakes'));
    });

    // -----------------------------------------------------------------
    // Behavioural: focus fallback
    // -----------------------------------------------------------------
    test('falls back to syllabus focus when subjectId is omitted', () async {
      mistakeService.mistakes = [
        _buildMistake(
          questionId: 'q1',
          subjectId: 'math',
          topicId: 'fractions',
          correctAnswer: '5/6',
          explanation: 'Explanation.',
          userAnswer: '1/3',
        ),
      ];

      focusService.setFocus('math', subjectTitle: 'Math');
      final tool = buildTool(withFocus: true);

      final result = await tool.execute({});

      expect(result['success'], isTrue);
      expect(result['subjectId'], 'math');
      expect(result['totalFound'], 1);
    });

    test('normalises subjectId via .normalized (whitespace / case)', () async {
      mistakeService.mistakes = [
        _buildMistake(subjectId: 'math', topicId: 'fractions'),
      ];

      final tool = buildTool();
      final result = await tool.execute({'subjectId': '  MATH  '});

      expect(result['success'], isTrue);
      expect(result['subjectId'], 'math');
    });

    test('tolerates string-encoded integer args from the LLM', () async {
      mistakeService.mistakes = List.generate(
        5,
        (i) => _buildMistake(questionId: 'q${i + 1}', topicId: 't${i + 1}'),
      );

      final tool = buildTool();
      final result = await tool.execute({
        'subjectId': 'math',
        'daysBack': '30',
        'limit': '3',
      });

      expect(result['success'], isTrue);
      expect(result['totalFound'], 3);
      expect(result['message'], contains('3 mistakes'));
    });

    test('omits daysBack when 0 means all-time lookback', () async {
      mistakeService.mistakes = [
        _buildMistake(questionId: 'q1', topicId: 'fractions'),
      ];

      final tool = buildTool();
      final result = await tool.execute({
        'subjectId': 'math',
        'daysBack': 0,
      });

      expect(result['success'], isTrue);
      expect(result['totalFound'], 1);
    });

    // -----------------------------------------------------------------
    // Behavioural: error handling
    // -----------------------------------------------------------------
    test('returns failure when studentId is empty', () async {
      studentIdService = FakeStudentIdService('');
      final tool = ReviewMistakesTool(
        mistakeReviewService: mistakeService,
        studentIdService: studentIdService,
        focusService: focusService,
      );

      final result = await tool.execute({'subjectId': 'math'});

      expect(result['success'], isFalse);
      expect(result['error'], 'no_student_id');
      expect(result['message'], contains('No student'));
    });

    test('returns failure when subjectId is empty and no focus set', () async {
      final tool = buildTool();

      final result = await tool.execute({});

      expect(result['success'], isFalse);
      expect(result['error'], 'no_subject');
      expect(result['message'], contains('subjectId'));
    });

    test('returns failure when subjectId is whitespace-only and no focus',
        () async {
      final tool = buildTool();
      final result =
          await tool.execute({'subjectId': '   '});

      expect(result['success'], isFalse);
      expect(result['error'], 'no_subject');
    });

    test('propagates service failure result', () async {
      mistakeService.shouldFail = true;

      final tool = buildTool();
      final result = await tool.execute({'subjectId': 'math'});

      expect(result['success'], isFalse);
      expect(result['error'], 'Storage unavailable');
      expect(result['subjectId'], 'math');
    });

    test('limit caps the number of mistakes returned', () async {
      mistakeService.mistakes = List.generate(
        20,
        (i) => _buildMistake(questionId: 'q${i + 1}', topicId: 't${i + 1}'),
      );

      final tool = buildTool();
      final result = await tool.execute({
        'subjectId': 'math',
        'limit': 5,
      });

      expect(result['success'], isTrue);
      expect(result['totalFound'], 5);
      expect((result['mistakes'] as List), hasLength(5));
    });
  });
}
