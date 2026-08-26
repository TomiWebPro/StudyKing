import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/teaching/data/models/evaluation_result.dart';
import 'package:studyking/features/teaching/services/conversation_manager.dart';
import 'package:studyking/features/teaching/services/exercise_evaluator.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';

class _FakeLlmService extends LlmService {
  _FakeLlmService()
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: '',
          ),
        );

  @override
  Future<Result<String>> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async =>
      Result.success('ok');

  @override
  Stream<String> chatStream({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async* {
    yield 'ok';
  }
}

class _FakeExerciseEvaluator extends ExerciseEvaluator {
  _FakeExerciseEvaluator() : super(llmService: _FakeLlmService(), modelId: 'm');
}

void main() {
  group('ConversationManager syllabus switching', () {
    late ConversationManager manager;

    setUp(() {
      manager = ConversationManager(
        llmService: _FakeLlmService(),
        modelId: 'm',
        sessionId: 's',
        studentId: 'u',
        topicTitle: 'T',
        subjectId: 'subj',
        topicId: 't',
        exerciseEvaluator: _FakeExerciseEvaluator(),
        localeName: 'en',
        availableSyllabi: [
          SyllabusGoal(subjectId: 'subj-math', subjectTitle: 'Math'),
          SyllabusGoal(subjectId: 'subj-science', subjectTitle: 'Science'),
        ],
      );
    });

    test('starts with no active syllabus', () {
      expect(manager.currentSyllabusId, isNull);
      expect(manager.currentSyllabusTitle, isNull);
    });

    test('switches active syllabus via /syllabus command', () async {
      await manager.initialize();
      final responses = <String>[];
      await for (final chunk in manager.sendMessage('/syllabus Math')) {
        responses.add(chunk);
      }
      final joined = responses.join();
      expect(joined, contains('Math'));
      expect(manager.currentSyllabusTitle, 'Math');
      expect(manager.currentSyllabusId, 'subj-math');
    });

    test('clears active syllabus via /syllabus all', () async {
      await manager.initialize();
      await for (final _ in manager.sendMessage('/syllabus Math')) {}
      expect(manager.currentSyllabusId, 'subj-math');

      final responses = <String>[];
      await for (final chunk in manager.sendMessage('/syllabus all')) {
        responses.add(chunk);
      }
      expect(responses.join(), contains('all syllabi')); // case-insensitive compare via l10n
      expect(manager.currentSyllabusId, isNull);
    });

    test('does not treat a normal message as a switch', () async {
      await manager.initialize();
      final responses = <String>[];
      await for (final chunk in manager.sendMessage('Can you explain integrals?')) {
        responses.add(chunk);
      }
      expect(responses.join(), isNot(contains('Switched active syllabus')));
      expect(manager.currentSyllabusId, isNull);
    });
  });
}
