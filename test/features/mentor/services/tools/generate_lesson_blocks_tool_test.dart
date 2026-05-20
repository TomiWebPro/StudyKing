import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/lessons/services/lesson_agent_service.dart';
import 'package:studyking/features/mentor/services/tools/generate_lesson_blocks_tool.dart';

T _required<T>() => throw UnimplementedError('stub not overridden');

class FakeLessonAgentService extends LessonAgentService {
  Future<Lesson?> Function({
    required String subjectId,
    required String topicId,
    required String topicTitle,
    String localeName,
  })? onGenerateLesson;

  FakeLessonAgentService()
      : super(
          llmService: _required(),
          modelId: '',
          lessonRepository: _required(),
          database: _required(),
        );

  @override
  Future<Lesson?> generateLesson({
    required String subjectId,
    required String topicId,
    required String topicTitle,
    String localeName = 'en',
  }) async {
    if (onGenerateLesson != null) {
      return onGenerateLesson!(
        subjectId: subjectId,
        topicId: topicId,
        topicTitle: topicTitle,
        localeName: localeName,
      );
    }
    return null;
  }
}

void main() {
  group('GenerateLessonBlocksTool', () {
    late FakeLessonAgentService fakeService;
    late GenerateLessonBlocksTool tool;

    setUp(() {
      fakeService = FakeLessonAgentService();
      tool = GenerateLessonBlocksTool(lessonAgentService: fakeService, localeName: 'en');
    });

    test('name returns generate_lesson_blocks', () {
      expect(tool.name, 'generate_lesson_blocks');
    });

    test('description is not empty', () {
      expect(tool.description, isNotEmpty);
    });

    test('parameters has correct JSON schema shape', () {
      final params = tool.parameters;
      expect(params['type'], 'object');
      final properties = params['properties'] as Map<String, dynamic>;
      expect(properties.keys, containsAll(['subjectId', 'topicId', 'topicTitle', 'localeName']));
      expect(properties['subjectId']['type'], 'string');
      expect(properties['topicId']['type'], 'string');
      expect(properties['topicTitle']['type'], 'string');
      expect(properties['localeName']['type'], 'string');
      expect(properties['localeName']['default'], 'en');
      expect(params['required'], ['subjectId', 'topicId', 'topicTitle']);
    });

    test('execute returns success with lesson data when generation succeeds', () async {
      fakeService.onGenerateLesson = ({
        required String subjectId,
        required String topicId,
        required String topicTitle,
        String localeName = 'en',
      }) async {
        return Lesson(
          id: 'lesson-123',
          subjectId: subjectId,
          title: topicTitle,
          topicId: topicId,
          blocks: [
            LessonBlock(
              id: 'b1',
              subjectId: subjectId,
              lessonId: '',
              type: LessonBlockType.text,
              content: 'Hello',
              order: 0,
            ),
          ],
          generatedBy: GeneratedBy.ai,
          createdAt: DateTime.now(),
        );
      };

      final result = await tool.execute({
        'subjectId': 'subj-1',
        'topicId': 'topic-1',
        'topicTitle': 'Algebra Basics',
      });

      expect(result, {
        'success': true,
        'lessonId': 'lesson-123',
        'blockCount': 1,
        'title': 'Algebra Basics',
      });
    });

    test('execute returns failure message when lesson generation returns null', () async {
      final result = await tool.execute({
        'subjectId': 'subj-1',
        'topicId': 'topic-1',
        'topicTitle': 'Algebra Basics',
      });

      expect(result, {
        'success': false,
        'message': 'Failed to generate lesson blocks',
      });
    });

    test('execute passes default locale when localeName is omitted', () async {
      String? capturedLocale;
      fakeService.onGenerateLesson = ({
        required String subjectId,
        required String topicId,
        required String topicTitle,
        String localeName = 'en',
      }) async {
        capturedLocale = localeName;
        return null;
      };

      await tool.execute({
        'subjectId': 'subj-1',
        'topicId': 'topic-1',
        'topicTitle': 'Algebra Basics',
      });

      expect(capturedLocale, 'en');
    });

    test('execute passes custom locale when localeName is provided', () async {
      String? capturedLocale;
      fakeService.onGenerateLesson = ({
        required String subjectId,
        required String topicId,
        required String topicTitle,
        String localeName = 'en',
      }) async {
        capturedLocale = localeName;
        return null;
      };

      await tool.execute({
        'subjectId': 'subj-1',
        'topicId': 'topic-1',
        'topicTitle': 'Algebra Basics',
        'localeName': 'es',
      });

      expect(capturedLocale, 'es');
    });
  });
}
