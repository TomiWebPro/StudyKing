import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/mentor/services/tools/suggest_practice_tool.dart';

void main() {
  group('SuggestPracticeTool', () {
    List<Map<String, dynamic>> receivedCalls = [];

    SuggestPracticeTool buildTool({
      bool shouldSucceed = true,
      PracticeRecommendation? recommendation,
    }) {
      receivedCalls = [];
      return SuggestPracticeTool(
        onSuggestPractice: ({
          required String subjectId,
          String? topicId,
        }) async {
          receivedCalls.add({
            'subjectId': subjectId,
            'topicId': topicId,
          });
          if (shouldSucceed) {
            return Result.success(
              recommendation ??
                  PracticeRecommendation(
                    topicId: topicId ?? 'fractions',
                    message: 'I found 10 practice questions on fractions.',
                    questionIds: ['q1', 'q2', 'q3', 'q4', 'q5',
                        'q6', 'q7', 'q8', 'q9', 'q10'],
                  ),
            );
          }
          return Result.failure('mastery service unavailable');
        },
      );
    }

    test('tool name is suggest_practice', () {
      final tool = buildTool();
      expect(tool.name, 'suggest_practice');
    });

    test('description mentions practice suggestion', () {
      final tool = buildTool();
      expect(tool.description, contains('practice'));
      expect(tool.description, contains('weak'));
    });

    test('parameters include subjectId (required) and optional topicId', () {
      final tool = buildTool();
      final params = tool.parameters;
      expect(params['type'], 'object');
      expect(params['properties'], containsPair('subjectId', isA<Map>()));
      expect(params['properties'], containsPair('topicId', isA<Map>()));
      expect(params['required'], contains('subjectId'));
      expect(params['required'], isNot(contains('topicId')));
    });

    test('calls onSuggestPractice with subjectId when topicId omitted',
        () async {
      final tool = buildTool();

      final result = await tool.execute({'subjectId': 'math-hl'});

      expect(result['success'], isTrue);
      expect(result['subjectId'], 'math-hl');
      expect(receivedCalls, hasLength(1));
      expect(receivedCalls.first['subjectId'], 'math-hl');
      expect(receivedCalls.first['topicId'], isNull);
    });

    test('calls onSuggestPractice with subjectId and topicId when both provided',
        () async {
      final tool = buildTool();

      final result = await tool.execute({
        'subjectId': 'math-hl',
        'topicId': 'fractions',
      });

      expect(result['success'], isTrue);
      expect(result['subjectId'], 'math-hl');
      expect(result['recommendedTopicId'], 'fractions');
      expect(receivedCalls, hasLength(1));
      expect(receivedCalls.first['subjectId'], 'math-hl');
      expect(receivedCalls.first['topicId'], 'fractions');
    });

    test('returns success with message and questionIds from recommendation',
        () async {
      final tool = buildTool();

      final result = await tool.execute({'subjectId': 'math-hl'});

      expect(result['success'], isTrue);
      expect(result['message'], contains('practice questions'));
      expect(result['questionIds'], hasLength(10));
      expect(result['questionIds'], contains('q1'));
      expect(result['questionIds'], contains('q10'));
    });

    test('tolerates whitespace and case in subjectId via .normalized', () async {
      final tool = buildTool();

      final result = await tool.execute({
        'subjectId': '  MATH-HL  ',
      });

      expect(result['success'], isTrue);
      expect(result['subjectId'], 'math-hl');
      expect(receivedCalls.first['subjectId'], 'math-hl');
    });

    test('tolerates whitespace in topicId via .normalized', () async {
      final tool = buildTool();

      final result = await tool.execute({
        'subjectId': 'math-hl',
        'topicId': '  fractions  ',
      });

      expect(result['success'], isTrue);
      expect(result['recommendedTopicId'], 'fractions');
      expect(receivedCalls.first['topicId'], 'fractions');
    });

    test('returns failure when subjectId is empty', () async {
      final tool = buildTool();

      final result = await tool.execute({'subjectId': ''});

      expect(result['success'], isFalse);
      expect(result['error'], contains('subjectId'));
      expect(receivedCalls, isEmpty);
    });

    test('returns failure when subjectId is missing', () async {
      final tool = buildTool();

      final result = await tool.execute({'topicId': 'fractions'});

      expect(result['success'], isFalse);
      expect(result['error'], contains('subjectId'));
      expect(receivedCalls, isEmpty);
    });

    test('returns failure when subjectId is whitespace-only', () async {
      final tool = buildTool();

      final result = await tool.execute({'subjectId': '   '});

      expect(result['success'], isFalse);
      expect(result['error'], contains('subjectId'));
      expect(receivedCalls, isEmpty);
    });

    test('reports failure when onSuggestPractice callback fails', () async {
      final tool = buildTool(shouldSucceed: false);

      final result = await tool.execute({'subjectId': 'math-hl'});

      expect(result['success'], isFalse);
      expect(result['error'], contains('mastery service unavailable'));
      expect(receivedCalls, hasLength(1));
    });

    test('omits recommendedTopicId when topicId not provided and empty in rec',
        () async {
      final tool = buildTool(
        recommendation: PracticeRecommendation(
          topicId: '',
          message: 'No weak areas detected.',
          questionIds: [],
        ),
      );

      final result = await tool.execute({'subjectId': 'math-hl'});

      expect(result['success'], isTrue);
      expect(result.containsKey('recommendedTopicId'), isFalse);
      expect(result.containsKey('questionIds'), isFalse);
      expect(result['message'], 'No weak areas detected.');
    });

    test('returns empty questionIds when recommendation has none', () async {
      final tool = buildTool(
        recommendation: PracticeRecommendation(
          topicId: '',
          message: 'No weak areas detected in math-hl.',
        ),
      );

      final result = await tool.execute({'subjectId': 'math-hl'});

      expect(result['success'], isTrue);
      expect(result['message'], contains('No weak areas'));
      expect(result.containsKey('questionIds'), isFalse);
    });
  });
}
