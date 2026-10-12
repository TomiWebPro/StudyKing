import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/repositories/question_lookup.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';

/// Hand-written fake standing in for the questions feature's
/// `QuestionRepository`, which core services consume through the
/// `QuestionLookup` interface (dependency inversion).
class FakeQuestionLookup implements QuestionLookup {
  final Map<String, Question> questions = {};

  @override
  Future<Result<Question?>> get(String id) async {
    return Result.success(questions[id]);
  }
}

void main() {
  group('QuestionLookup', () {
    test('QuestionRepository implements the core interface (wiring)', () {
      // The questions feature's concrete repository can be passed
      // wherever core services expect a QuestionLookup.
      expect(QuestionRepository(), isA<QuestionLookup>());
    });

    test('a fake lookup resolves the topic of a stored question', () async {
      final lookup = FakeQuestionLookup()
        ..questions['q_1'] = Question(
          id: 'q_1',
          text: 'What is 2+2?',
          type: QuestionType.typedAnswer,
          subjectId: 'subject_math',
          topicId: 'topic_math',
          createdAt: DateTime(2026, 5, 12),
          updatedAt: DateTime(2026, 5, 12),
        );

      final found = await lookup.get('q_1');
      expect(found.isSuccess, isTrue);
      expect(found.data?.topicId, 'topic_math');
    });

    test('a fake lookup reports a missing question as success with null data',
        () async {
      final lookup = FakeQuestionLookup();

      final missing = await lookup.get('q_unknown');
      expect(missing.isSuccess, isTrue);
      expect(missing.data, isNull);
    });
  });
}
