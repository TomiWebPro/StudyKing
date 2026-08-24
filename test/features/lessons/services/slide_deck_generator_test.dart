import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/lessons/services/slide_deck_generator.dart';

typedef ChatHandler = Future<Result<String>> Function({
  required String message,
  required String modelId,
  String? systemPrompt,
  String localeName,
  ConversationMemory? memory,
  List<Map<String, String>>? history,
  String feature,
});

class _FakeLlmService extends LlmService {
  ChatHandler? _chatHandler;
  bool shouldThrow = false;
  int callCount = 0;
  String lastFeature = '';

  _FakeLlmService() : super(
    config: LlmConfiguration(provider: LlmProvider.ollama, apiKey: 'test-key'),
  );

  void setHandler(ChatHandler handler) => _chatHandler = handler;
  void setFailNext() => shouldThrow = true;

  @override
  Future<Result<String>> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async {
    callCount++;
    lastFeature = feature;
    if (shouldThrow) {
      throw Exception('LLM API error');
    }
    if (_chatHandler != null) {
      return _chatHandler!(
        message: message,
        modelId: modelId,
        systemPrompt: systemPrompt,
        localeName: localeName,
        memory: memory,
        history: history,
        feature: feature,
      );
    }
    return Result.success('');
  }
}

class _FakeLessonRepository extends LessonRepository {
  final Map<String, Lesson> _storage = {};
  bool throwOnCreate = false;
  int createCallCount = 0;

  @override
  Future<Result<void>> create(Lesson lesson) async {
    if (throwOnCreate) return Result.failure('Create failed');
    _storage[lesson.id] = lesson;
    createCallCount++;
    return Result.success(null);
  }

  @override
  Future<Result<Lesson?>> get(String id) async {
    return Result.success(_storage[id]);
  }

  @override
  Future<Result<List<Lesson>>> getAll() async {
    return Result.success(_storage.values.toList());
  }

  @override
  Future<Result<List<Lesson>>> getBySubject(String subjectId) async {
    return Result.success(_storage.values.where((l) => l.subjectId == subjectId).toList());
  }

  @override
  Future<Result<List<Lesson>>> getByTopic(String topicId) async {
    return Result.success(_storage.values.where((l) => l.topicId == topicId).toList());
  }

  @override
  Future<Result<List<Lesson>>> getBySubjectAndTopic(
      String subjectId, String topicId) async {
    return Result.success(_storage.values
        .where((l) => l.subjectId == subjectId && l.topicId == topicId).toList());
  }

  @override
  Future<Result<void>> addBlock(LessonBlock block) async {
    return Result.success(null);
  }

  @override
  Future<Result<List<LessonBlock>>> getBlocksForLesson(String lessonId) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<LessonBlock>>> getBlocksBySubject(String subjectId) async {
    return Result.success([]);
  }

  @override
  Future<Result<void>> delete(String id) async {
    _storage.remove(id);
    return Result.success(null);
  }
}

void main() {
  group('SlideDeckGenerator', () {
    late _FakeLlmService fakeLlm;
    late _FakeLessonRepository fakeLessonRepo;
    late SlideDeckGenerator generator;

    setUp(() {
      fakeLlm = _FakeLlmService();
      fakeLessonRepo = _FakeLessonRepository();
      generator = SlideDeckGenerator(
        llmService: fakeLlm,
        modelId: 'test-model',
        lessonRepository: fakeLessonRepo,
      );
    });

    group('generateSlideDeck', () {
      test('generates slide deck with multiple chapters', () async {
        fakeLlm.setHandler(({
          required String message,
          required String modelId,
          String? systemPrompt,
          String localeName = 'en',
          ConversationMemory? memory,
          List<Map<String, String>>? history,
          String feature = 'general',
        }) async {
          if (feature == 'slide_deck_structure') {
            return Result.success(jsonEncode({
              'chapters': [
                {
                  'title': 'Chapter 1: Introduction',
                  'sections': ['Overview', 'Background'],
                  'startIndex': 0,
                  'endIndex': 500,
                },
                {
                  'title': 'Chapter 2: Methods',
                  'sections': ['Data Collection', 'Analysis'],
                  'startIndex': 500,
                  'endIndex': 1000,
                },
              ],
            }));
          }
          if (feature == 'slide_deck_chapter') {
            return Result.success(jsonEncode([
              {
                'slideType': 'title',
                'content': 'Chapter Title Slide',
                'sectionTitle': 'Overview',
                'sectionOrder': 0,
              },
              {
                'slideType': 'concept',
                'content': 'Key concept explanation',
                'sectionTitle': 'Overview',
                'sectionOrder': 1,
              },
              {
                'slideType': 'quiz',
                'content': 'What is the main topic?',
                'sectionTitle': 'Overview',
                'sectionOrder': 2,
                'answerKey': 'Main topic',
              },
            ]));
          }
          return Result.success('');
        });

        final lessons = await generator.generateSlideDeck(
          subjectId: 'sub-1',
          topicId: 'topic-1',
          topicTitle: 'Test Topic',
          sourceContent: 'Source content here...',
          localeName: 'en',
        );

        expect(lessons.length, 3);
        expect(lessons[0].title, contains('Table of Contents'));
        expect(lessons[1].title, 'Chapter 1: Introduction');
        expect(lessons[2].title, 'Chapter 2: Methods');
        expect(fakeLessonRepo.createCallCount, 3);
      });

      test('generates single chapter when structure analysis returns empty', () async {
        fakeLlm.setHandler(({
          required String message,
          required String modelId,
          String? systemPrompt,
          String localeName = 'en',
          ConversationMemory? memory,
          List<Map<String, String>>? history,
          String feature = 'general',
        }) async {
          if (feature == 'slide_deck_structure') {
            return Result.success('[]');
          }
          if (feature == 'slide_deck_chapter') {
            return Result.success(jsonEncode([
              {'slideType': 'title', 'content': 'Title', 'sectionTitle': '', 'sectionOrder': 0},
            ]));
          }
          return Result.success('');
        });

        final lessons = await generator.generateSlideDeck(
          subjectId: 'sub-1',
          topicId: 'topic-1',
          topicTitle: 'Simple Topic',
          sourceContent: 'Some content',
          localeName: 'en',
        );

        expect(lessons.length, 2);
        expect(lessons[0].title, contains('Table of Contents'));
        expect(lessons[1].title, 'Simple Topic');
      });

      test('returns empty list when LLM throws exception', () async {
        fakeLlm.setFailNext();

        final lessons = await generator.generateSlideDeck(
          subjectId: 'sub-1',
          topicId: 'topic-1',
          topicTitle: 'Failed Topic',
          sourceContent: 'Content',
          localeName: 'en',
        );

        expect(lessons, isEmpty);
      });

      test('creates lessons with correct metadata', () async {
        fakeLlm.setHandler(({
          required String message,
          required String modelId,
          String? systemPrompt,
          String localeName = 'en',
          ConversationMemory? memory,
          List<Map<String, String>>? history,
          String feature = 'general',
        }) async {
          if (feature == 'slide_deck_structure') {
            return Result.success(jsonEncode({
              'chapters': [
                {
                  'title': 'Chapter 1',
                  'sections': [],
                  'startIndex': 0,
                  'endIndex': 100,
                },
              ],
            }));
          }
          if (feature == 'slide_deck_chapter') {
            return Result.success(jsonEncode([
              {
                'slideType': 'title',
                'content': 'Title',
                'sectionTitle': '',
                'sectionOrder': 0,
              },
            ]));
          }
          return Result.success('');
        });

        final lessons = await generator.generateSlideDeck(
          subjectId: 'sub-1',
          topicId: 'topic-1',
          topicTitle: 'Test Topic',
          sourceContent: 'Content',
          localeName: 'en',
        );

        final chapterLesson = lessons.firstWhere((l) => l.title == 'Chapter 1');
        expect(chapterLesson.subjectId, 'sub-1');
        expect(chapterLesson.topicId, 'topic-1');
        expect(chapterLesson.generatedBy, GeneratedBy.ai);
        expect(chapterLesson.blocks.first.chapterTitle, 'Chapter 1');
        expect(chapterLesson.blocks.first.slideType, SlideType.title);
        expect(chapterLesson.blocks.first.chapterOrder, 0);
      });

      test('handles repository failure gracefully', () async {
        fakeLlm.setHandler(({
          required String message,
          required String modelId,
          String? systemPrompt,
          String localeName = 'en',
          ConversationMemory? memory,
          List<Map<String, String>>? history,
          String feature = 'general',
        }) async {
          if (feature == 'slide_deck_structure') {
            return Result.success(jsonEncode({
              'chapters': [
                {
                  'title': 'Chapter 1',
                  'sections': [],
                  'startIndex': 0,
                  'endIndex': 100,
                },
              ],
            }));
          }
          if (feature == 'slide_deck_chapter') {
            return Result.success(jsonEncode([
              {'slideType': 'title', 'content': 'Title', 'sectionTitle': '', 'sectionOrder': 0},
            ]));
          }
          return Result.success('');
        });

        fakeLessonRepo.throwOnCreate = true;

        final lessons = await generator.generateSlideDeck(
          subjectId: 'sub-1',
          topicId: 'topic-1',
          topicTitle: 'Test',
          sourceContent: 'Content',
          localeName: 'en',
        );

        expect(lessons.length, 2);
      });

      test('parses various slide types correctly', () async {
        fakeLlm.setHandler(({
          required String message,
          required String modelId,
          String? systemPrompt,
          String localeName = 'en',
          ConversationMemory? memory,
          List<Map<String, String>>? history,
          String feature = 'general',
        }) async {
          if (feature == 'slide_deck_structure') {
            return Result.success(jsonEncode({
              'chapters': [
                {'title': 'Ch1', 'sections': [], 'startIndex': 0, 'endIndex': 50},
              ],
            }));
          }
          if (feature == 'slide_deck_chapter') {
            return Result.success(jsonEncode([
              {'slideType': 'title', 'content': 'Title', 'sectionTitle': '', 'sectionOrder': 0},
              {'slideType': 'definition', 'content': 'Definition', 'sectionTitle': 'Sec1', 'sectionOrder': 1},
              {'slideType': 'formula', 'content': 'E=mc^2', 'sectionTitle': 'Sec1', 'sectionOrder': 2},
              {'slideType': 'example', 'content': 'Example', 'sectionTitle': 'Sec2', 'sectionOrder': 3},
              {'slideType': 'summary', 'content': 'Summary', 'sectionTitle': '', 'sectionOrder': 4},
              {'slideType': 'quiz', 'content': 'Quiz?', 'sectionTitle': '', 'sectionOrder': 5, 'answerKey': 'A'},
            ]));
          }
          return Result.success('');
        });

        final lessons = await generator.generateSlideDeck(
          subjectId: 'sub-1',
          topicId: 'topic-1',
          topicTitle: 'Test',
          sourceContent: 'Content',
          localeName: 'en',
        );

        final chapterLesson = lessons.firstWhere((l) => l.title == 'Ch1');
        expect(chapterLesson.blocks.length, 6);
        expect(chapterLesson.blocks[0].slideType, SlideType.title);
        expect(chapterLesson.blocks[0].type, LessonBlockType.slide);
        expect(chapterLesson.blocks[1].slideType, SlideType.definition);
        expect(chapterLesson.blocks[2].slideType, SlideType.formula);
        expect(chapterLesson.blocks[3].slideType, SlideType.example);
        expect(chapterLesson.blocks[4].slideType, SlideType.summary);
        expect(chapterLesson.blocks[4].type, LessonBlockType.summary);
        expect(chapterLesson.blocks[5].slideType, SlideType.quiz);
        expect(chapterLesson.blocks[5].type, LessonBlockType.quiz);
        expect(chapterLesson.blocks[5].answerKey, 'A');
      });

      test('generates table of contents with chapter listing', () async {
        fakeLlm.setHandler(({
          required String message,
          required String modelId,
          String? systemPrompt,
          String localeName = 'en',
          ConversationMemory? memory,
          List<Map<String, String>>? history,
          String feature = 'general',
        }) async {
          if (feature == 'slide_deck_structure') {
            return Result.success(jsonEncode({
              'chapters': [
                {'title': 'Ch1', 'sections': [], 'startIndex': 0, 'endIndex': 50},
                {'title': 'Ch2', 'sections': [], 'startIndex': 50, 'endIndex': 100},
              ],
            }));
          }
          if (feature == 'slide_deck_chapter') {
            return Result.success(jsonEncode([
              {'slideType': 'title', 'content': 'Title', 'sectionTitle': '', 'sectionOrder': 0},
            ]));
          }
          return Result.success('');
        });

        final lessons = await generator.generateSlideDeck(
          subjectId: 'sub-1',
          topicId: 'topic-1',
          topicTitle: 'Math Book',
          sourceContent: 'Content',
          localeName: 'en',
        );

        final toc = lessons.first;
        expect(toc.title, contains('Table of Contents'));
        expect(toc.blocks.length, 1);
        expect(toc.blocks.first.slideType, SlideType.tableOfContents);
        expect(toc.blocks.first.content, contains('Chapter 1: Ch1'));
        expect(toc.blocks.first.content, contains('Chapter 2: Ch2'));
      });
    });

    group('_parseSlideResponse', () {
      test('parses JSON array of slides', () async {
        fakeLlm.setHandler(({
          required String message,
          required String modelId,
          String? systemPrompt,
          String localeName = 'en',
          ConversationMemory? memory,
          List<Map<String, String>>? history,
          String feature = 'general',
        }) async {
          if (feature == 'slide_deck_structure') {
            return Result.success(jsonEncode({
              'chapters': [
                {'title': 'Ch1', 'sections': ['Sec1'], 'startIndex': 0, 'endIndex': 50},
              ],
            }));
          }
          if (feature == 'slide_deck_chapter') {
            return Result.success(jsonEncode([
              {'slideType': 'concept', 'content': 'Concept 1', 'sectionTitle': 'Sec1', 'sectionOrder': 0},
              {'slideType': 'concept', 'content': 'Concept 2', 'sectionTitle': 'Sec1', 'sectionOrder': 1},
            ]));
          }
          return Result.success('');
        });

        final lessons = await generator.generateSlideDeck(
          subjectId: 'sub-1',
          topicId: 'topic-1',
          topicTitle: 'Test',
          sourceContent: 'Content',
          localeName: 'en',
        );

        final chapter = lessons.firstWhere((l) => l.title == 'Ch1');
        expect(chapter.blocks.length, 2);
        expect(chapter.blocks[0].content, 'Concept 1');
        expect(chapter.blocks[1].content, 'Concept 2');
        expect(chapter.blocks[0].sectionTitle, 'Sec1');
      });

      test('handles wrapped JSON with slides key', () async {
        fakeLlm.setHandler(({
          required String message,
          required String modelId,
          String? systemPrompt,
          String localeName = 'en',
          ConversationMemory? memory,
          List<Map<String, String>>? history,
          String feature = 'general',
        }) async {
          if (feature == 'slide_deck_structure') {
            return Result.success(jsonEncode({
              'chapters': [
                {'title': 'Ch1', 'sections': [], 'startIndex': 0, 'endIndex': 50},
              ],
            }));
          }
          if (feature == 'slide_deck_chapter') {
            return Result.success(jsonEncode({
              'slides': [
                {'slideType': 'title', 'content': 'Wrapped', 'sectionTitle': '', 'sectionOrder': 0},
              ],
            }));
          }
          return Result.success('');
        });

        final lessons = await generator.generateSlideDeck(
          subjectId: 'sub-1',
          topicId: 'topic-1',
          topicTitle: 'Test',
          sourceContent: 'Content',
          localeName: 'en',
        );

        final chapter = lessons.firstWhere((l) => l.title == 'Ch1');
        expect(chapter.blocks.length, 1);
        expect(chapter.blocks[0].content, 'Wrapped');
      });

      test('skips malformed slide items and logs a warning', () async {
        fakeLlm.setHandler(({
          required String message,
          required String modelId,
          String? systemPrompt,
          String localeName = 'en',
          ConversationMemory? memory,
          List<Map<String, String>>? history,
          String feature = 'general',
        }) async {
          if (feature == 'slide_deck_structure') {
            return Result.success(jsonEncode({
              'chapters': [
                {'title': 'Ch1', 'sections': [], 'startIndex': 0, 'endIndex': 50},
              ],
            }));
          }
          if (feature == 'slide_deck_chapter') {
            return Result.success(jsonEncode([
              {'slideType': 'concept', 'content': 'Concept 1', 'sectionTitle': 'Sec1', 'sectionOrder': 0},
              'this is not a slide object',
              {'slideType': 'concept', 'content': 'Concept 2', 'sectionTitle': 'Sec1', 'sectionOrder': 1},
            ]));
          }
          return Result.success('');
        });

        final records = <String>[];
        final originalPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) => records.add(message ?? '');

        final lessons = await generator.generateSlideDeck(
          subjectId: 'sub-1',
          topicId: 'topic-1',
          topicTitle: 'Test',
          sourceContent: 'Content',
          localeName: 'en',
        );

        debugPrint = originalPrint;

        final chapter = lessons.firstWhere((l) => l.title == 'Ch1');
        expect(chapter.blocks.length, 2);
        expect(
          records.any((r) => r.contains('malformed slide item')),
          isTrue,
          reason: 'expected a warning to be logged for the skipped item',
        );
      });

      test('strips markdown code fences from response', () async {
        fakeLlm.setHandler(({
          required String message,
          required String modelId,
          String? systemPrompt,
          String localeName = 'en',
          ConversationMemory? memory,
          List<Map<String, String>>? history,
          String feature = 'general',
        }) async {
          if (feature == 'slide_deck_structure') {
            return Result.success(jsonEncode({
              'chapters': [
                {'title': 'Ch1', 'sections': [], 'startIndex': 0, 'endIndex': 50},
              ],
            }));
          }
          if (feature == 'slide_deck_chapter') {
            return Result.success('```json\n[{"slideType": "concept", "content": "Fenced", "sectionTitle": "", "sectionOrder": 0}]\n```');
          }
          return Result.success('');
        });

        final lessons = await generator.generateSlideDeck(
          subjectId: 'sub-1',
          topicId: 'topic-1',
          topicTitle: 'Test',
          sourceContent: 'Content',
          localeName: 'en',
        );

        final chapter = lessons.firstWhere((l) => l.title == 'Ch1');
        expect(chapter.blocks.length, 1);
        expect(chapter.blocks[0].content, 'Fenced');
      });
    });

    group('_parseStructureResponse', () {
      test('parses chapters array from LLM response', () async {
        fakeLlm.setHandler(({
          required String message,
          required String modelId,
          String? systemPrompt,
          String localeName = 'en',
          ConversationMemory? memory,
          List<Map<String, String>>? history,
          String feature = 'general',
        }) async {
          if (feature == 'slide_deck_structure') {
            return Result.success(jsonEncode([
              {'title': 'Ch1', 'sections': ['A', 'B'], 'startIndex': 0, 'endIndex': 100},
            ]));
          }
          if (feature == 'slide_deck_chapter') {
            return Result.success(jsonEncode([
              {'slideType': 'concept', 'content': 'C', 'sectionTitle': '', 'sectionOrder': 0},
            ]));
          }
          return Result.success('');
        });

        final lessons = await generator.generateSlideDeck(
          subjectId: 'sub-1',
          topicId: 'topic-1',
          topicTitle: 'Test',
          sourceContent: 'Content',
          localeName: 'en',
        );

        expect(lessons.length, 2);
        expect(lessons[1].title, 'Ch1');
      });

      test('handles invalid JSON gracefully', () async {
        fakeLlm.setHandler(({
          required String message,
          required String modelId,
          String? systemPrompt,
          String localeName = 'en',
          ConversationMemory? memory,
          List<Map<String, String>>? history,
          String feature = 'general',
        }) async {
          if (feature == 'slide_deck_structure') {
            return Result.success('not valid json');
          }
          if (feature == 'slide_deck_chapter') {
            return Result.success(jsonEncode([
              {'slideType': 'concept', 'content': 'Fallback', 'sectionTitle': '', 'sectionOrder': 0},
            ]));
          }
          return Result.success('');
        });

        final lessons = await generator.generateSlideDeck(
          subjectId: 'sub-1',
          topicId: 'topic-1',
          topicTitle: 'Test',
          sourceContent: 'Content',
          localeName: 'en',
        );

        expect(lessons.length, 2);
      });
    });

    group('SlideDeckStyle', () {
      test('has all expected values', () {
        expect(SlideDeckStyle.values.length, 3);
        expect(SlideDeckStyle.values, contains(SlideDeckStyle.detailed));
        expect(SlideDeckStyle.values, contains(SlideDeckStyle.concise));
        expect(SlideDeckStyle.values, contains(SlideDeckStyle.examFocused));
      });
    });

    group('LessonBlock new fields', () {
      test('chapter and section fields are nullable and default to null', () {
        final block = LessonBlock(
          id: 'b1',
          subjectId: 's1',
          lessonId: 'l1',
          type: LessonBlockType.slide,
          content: 'Content',
        );
        expect(block.chapterTitle, isNull);
        expect(block.sectionTitle, isNull);
        expect(block.chapterOrder, isNull);
        expect(block.sectionOrder, isNull);
        expect(block.slideType, isNull);
      });

      test('serializes new fields in JSON', () {
        final block = LessonBlock(
          id: 'b1',
          subjectId: 's1',
          lessonId: 'l1',
          type: LessonBlockType.slide,
          content: 'Content',
          chapterTitle: 'Ch1',
          sectionTitle: 'Sec1',
          chapterOrder: 0,
          sectionOrder: 1,
          slideType: SlideType.concept,
        );
        final json = block.toJson();
        expect(json['chapterTitle'], 'Ch1');
        expect(json['sectionTitle'], 'Sec1');
        expect(json['chapterOrder'], 0);
        expect(json['sectionOrder'], 1);
        expect(json['slideType'], SlideType.concept.index);
      });

      test('deserializes new fields from JSON', () {
        final json = {
          'id': 'b1',
          'subjectId': 's1',
          'lessonId': 'l1',
          'type': 3,
          'content': 'Content',
          'chapterTitle': 'Ch1',
          'sectionTitle': 'Sec1',
          'chapterOrder': 0,
          'sectionOrder': 1,
          'slideType': 1,
        };
        final block = LessonBlock.fromJson(json);
        expect(block.chapterTitle, 'Ch1');
        expect(block.sectionTitle, 'Sec1');
        expect(block.chapterOrder, 0);
        expect(block.sectionOrder, 1);
        expect(block.slideType, SlideType.concept);
      });

      test('handles null new fields in JSON', () {
        final json = {
          'id': 'b1',
          'subjectId': 's1',
          'lessonId': 'l1',
          'type': 3,
          'content': 'Content',
        };
        final block = LessonBlock.fromJson(json);
        expect(block.chapterTitle, isNull);
        expect(block.sectionTitle, isNull);
        expect(block.chapterOrder, isNull);
        expect(block.sectionOrder, isNull);
        expect(block.slideType, isNull);
      });

      test('copyWith preserves new fields', () {
        final block = LessonBlock(
          id: 'b1',
          subjectId: 's1',
          lessonId: 'l1',
          type: LessonBlockType.slide,
          content: 'Content',
          chapterTitle: 'Ch1',
          sectionTitle: 'Sec1',
          chapterOrder: 0,
          sectionOrder: 1,
          slideType: SlideType.definition,
        );
        final copy = block.copyWith(content: 'Updated');
        expect(copy.chapterTitle, 'Ch1');
        expect(copy.sectionTitle, 'Sec1');
        expect(copy.chapterOrder, 0);
        expect(copy.sectionOrder, 1);
        expect(copy.slideType, SlideType.definition);
        expect(copy.content, 'Updated');
      });

      test('copyWith updates new fields', () {
        final block = LessonBlock(
          id: 'b1',
          subjectId: 's1',
          lessonId: 'l1',
          type: LessonBlockType.slide,
          content: 'Content',
          chapterTitle: 'Ch1',
          slideType: SlideType.concept,
        );
        final copy = block.copyWith(
          chapterTitle: 'Ch2',
          slideType: SlideType.formula,
        );
        expect(copy.chapterTitle, 'Ch2');
        expect(copy.slideType, SlideType.formula);
      });

      test('roundtrip preserves new fields', () {
        final original = LessonBlock(
          id: 'b1',
          subjectId: 's1',
          lessonId: 'l1',
          type: LessonBlockType.slide,
          content: 'Content',
          chapterTitle: 'Ch1',
          sectionTitle: 'Sec1',
          chapterOrder: 2,
          sectionOrder: 3,
          slideType: SlideType.example,
        );
        final restored = LessonBlock.fromJson(original.toJson());
        expect(restored.chapterTitle, 'Ch1');
        expect(restored.sectionTitle, 'Sec1');
        expect(restored.chapterOrder, 2);
        expect(restored.sectionOrder, 3);
        expect(restored.slideType, SlideType.example);
      });
    });

    group('SlideType enum', () {
      test('has all expected values', () {
        expect(SlideType.values.length, 9);
        expect(SlideType.values, contains(SlideType.title));
        expect(SlideType.values, contains(SlideType.concept));
        expect(SlideType.values, contains(SlideType.definition));
        expect(SlideType.values, contains(SlideType.formula));
        expect(SlideType.values, contains(SlideType.example));
        expect(SlideType.values, contains(SlideType.summary));
        expect(SlideType.values, contains(SlideType.quiz));
        expect(SlideType.values, contains(SlideType.reference));
        expect(SlideType.values, contains(SlideType.tableOfContents));
      });
    });
  });
}
