// LLM Service - handles AI-powered content generation and validation
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/enums.dart';
import '../data/models/lesson_block_model.dart';
import '../data/models/question_model.dart';
import '../data/models/lesson_model.dart';

enum LlmProvider { openRouter, ollama }

class LlmConfiguration {
  final LlmProvider provider;
  final String apiKey;
  final String baseUrl;

  const LlmConfiguration({
    required this.provider,
    required this.apiKey,
    this.baseUrl = '',
  });
}

class LlmService {
  final LlmConfiguration config;

  LlmService({required this.config});

  Future<String> _callLlm(String prompt, String model) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (config.provider == LlmProvider.openRouter) {
      headers['Authorization'] = 'Bearer ${config.apiKey}';

      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: headers,
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': 'You are a helpful AI tutor.'},
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('OpenRouter API Error: ${response.body}');
      }
    } else if (config.provider == LlmProvider.ollama) {
      final response = await http.post(
        Uri.parse('${config.baseUrl}/api/chat'),
        headers: headers,
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message']['content'];
      } else {
        throw Exception('Ollama API Error: ${response.body}');
      }
    } else {
      throw Exception('Unknown LLM provider');
    }
  }

  Future<List<Question>> generateQuestions({
    required String topicTitle,
    required String syllabus,
    required String subjectId,
    required int count,
    required int difficulty,
    required String modelId,
  }) async {
    if (config.apiKey.isEmpty) {
      return _getMockQuestions(topicTitle, count, difficulty, subjectId);
    }

    final prompt = '''
Generate $count practice questions for the topic "$topicTitle" in subject ID: $subjectId.
Syllabus: $syllabus
Difficulty level: $difficulty/5

Each question should have:
1. A clear question text
2. Multiple choice options (A, B, C, D)  
3. The correct answer
4. A brief explanation

Format as JSON array with subjectId field.
''';

    try {
      final response = await _callLlm(prompt, modelId);
      return _parseQuestions(response, subjectId);
    } catch (e) {
      debugPrint('LLM Question Generation Error: $e');
      return _getMockQuestions(topicTitle, count, difficulty, subjectId);
    }
  }

  Future<List<LessonBlock>> generateLessonBlocks({
    required String topicTitle,
    required String subjectId,
    required String content,
    required String modelId,
  }) async {
    if (config.apiKey.isEmpty) {
      return _getMockLessonBlocks(subjectId);
    }

    final prompt = '''
Create structured lesson blocks for topic: $topicTitle

Subject ID: $subjectId
Content to explain: $content

Generate blocks with type and content. Include subjectId in each block.
''';

    try {
      final response = await _callLlm(prompt, modelId);
      return _parseLessonBlocks(response, subjectId);
    } catch (e) {
      debugPrint('LLM Lesson Generation Error: $e');
      return _getMockLessonBlocks(subjectId);
    }
  }

  Future<Lesson> generateLesson({
    required String title,
    required String subjectId,
    required String topicId,
    required String content,
    required String modelId,
    int difficulty = 1,
  }) async {
    if (config.apiKey.isEmpty) {
      return _getMockLesson(title, subjectId, topicId, difficulty);
    }

    final prompt = '''
Generate a complete lesson for:
Title: $title
Subject ID: $subjectId
Topic ID: $topicId

Content overview: $content

Generate:
1. Lesson title and structure
2. Lesson blocks (text, examples, exercises)
3. Difficulty level

Respond with JSON containing lesson structure.
''';

    try {
      final response = await _callLlm(prompt, modelId);
      return _parseLesson(response, title, subjectId, topicId, difficulty);
    } catch (e) {
      debugPrint('LLM Lesson Generation Error: $e');
      return _getMockLesson(title, subjectId, topicId, difficulty);
    }
  }

  Future<String> validateAnswer({
    required String questionText,
    required String userAnswer,
    required String correctAnswer,
    required String subjectId,
    String? topicId,
    required String modelId,
  }) async {
    if (config.apiKey.isEmpty) {
      return _mockValidateAnswer(subjectId);
    }

    final context = topicId != null 
        ? 'Subject: $subjectId, Topic: $topicId' 
        : 'Subject: $subjectId';

    final prompt = '''
Evaluate if the user answer matches the correct answer.
Context: $context

Question: $questionText
User Answer: $userAnswer
Correct Answer: $correctAnswer

Provide validation result with explanation.
''';

    try {
      final response = await _callLlm(prompt, modelId);
      return response;
    } catch (e) {
      return _mockValidateAnswer(subjectId);
    }
  }

  Future<Map<String, dynamic>> generateStudyPlan({
    required String subjectId,
    required String course,
    required int days,
    required int hoursPerDay,
    required String modelId,
  }) async {
    if (config.apiKey.isEmpty) {
      return _mockStudyPlan(subjectId, course, days, hoursPerDay);
    }

    final prompt = '''
Generate a study plan for: $course (Subject ID: $subjectId)
Duration: $days days
Time per day: $hoursPerDay hours

Include:
1. Daily topics to cover
2. Practice recommendations
3. Milestone checkpoints

Format as JSON with subject-specific recommendations.
''';

    try {
      final response = await _callLlm(prompt, modelId);
      return _parseStudyPlan(response, subjectId);
    } catch (e) {
      return _mockStudyPlan(subjectId, course, days, hoursPerDay);
    }
  }

  List<Question> _parseQuestions(String response, String subjectId) {
    try {
      final data = jsonDecode(response);
      if (data is List) {
        return data.map((json) {
          return Question(
            id: json['id'] ?? 'q_${subjectId}_mock_${DateTime.now().millisecondsSinceEpoch}',
            text: json['text'] ?? json['question'] ?? 'Mock question',
            type: _parseQuestionType(json['type']),
            difficulty: json['difficulty'] ?? 1,
            subjectId: subjectId,
            topicId: json['topicId'] ?? 'topic_general',
            variantIds: List<String>.from(json['variantIds'] ?? []),
            sourceIds: List<String>.from(json['sourceIds'] ?? []),
            allowedAnswerTypes: json['allowedAnswerTypes'] ?? '',
            markscheme: json['markscheme'] ?? json['answer'] ?? '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  QuestionType _parseQuestionType(dynamic typeValue) {
    if (typeValue is int && typeValue >= 0 && typeValue < QuestionType.values.length) {
      return QuestionType.values[typeValue];
    }
    final typeStr = typeValue.toString().toLowerCase();
    if (typeStr.contains('multiple')) return QuestionType.multiChoice;
    if (typeStr.contains('short')) return QuestionType.typedAnswer;
    if (typeStr.contains('essay')) return QuestionType.essay;
    return QuestionType.singleChoice;
  }

  List<LessonBlock> _parseLessonBlocks(String response, String subjectId) {
    try {
      final data = jsonDecode(response);
      if (data is List) {
        return data.map((json) {
          return LessonBlock(
            id: json['id'] ?? 'block_${subjectId}_${DateTime.now().millisecondsSinceEpoch}_${json['order']}',
            subjectId: subjectId,
            lessonId: json['lessonId'] ?? 'lesson_general',
            type: _parseLessonBlockType(json['type']),
            content: json['content'] ?? '',
            order: json['order'] ?? 0,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  LessonBlockType _parseLessonBlockType(dynamic typeValue) {
    if (typeValue is int && typeValue >= 0 && typeValue < LessonBlockType.values.length) {
      return LessonBlockType.values[typeValue];
    }
    final typeStr = typeValue.toString().toLowerCase();
    if (typeStr.contains('text')) return LessonBlockType.text;
    if (typeStr.contains('example')) return LessonBlockType.example;
    if (typeStr.contains('exercise')) return LessonBlockType.exercise;
    if (typeStr.contains('slide')) return LessonBlockType.slide;
    if (typeStr.contains('quiz')) return LessonBlockType.quiz;
    if (typeStr.contains('summary')) return LessonBlockType.summary;
    return LessonBlockType.text;
  }

  Lesson _parseLesson(String response, String title, String subjectId, String topicId, int difficulty) {
    try {
      final data = jsonDecode(response);
      if (data is Map<String, dynamic> && data.containsKey('blocks')) {
        final blocks = (data['blocks'] as List)
            .map((b) => _parseLessonBlocks(b.toString(), subjectId))
            .expand((b) => b)
            .toList();

        return Lesson(
          id: 'lesson_${subjectId}_${DateTime.now().millisecondsSinceEpoch}',
          subjectId: subjectId,
          title: title,
          topicId: topicId,
          blocks: blocks,
          difficulty: difficulty,
          generatedBy: GeneratedBy.ai,
          createdAt: DateTime.now(),
          markscheme: data['markscheme'],
        );
      }
      
      final blocks = _parseLessonBlocks(response, subjectId);
      return Lesson(
        id: 'lesson_${subjectId}_${DateTime.now().millisecondsSinceEpoch}',
        subjectId: subjectId,
        title: title,
        topicId: topicId,
        blocks: blocks,
        difficulty: difficulty,
        generatedBy: GeneratedBy.ai,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error parsing lesson: $e');
      return _getMockLesson(title, subjectId, topicId, difficulty);
    }
  }

  Map<String, dynamic> _parseStudyPlan(String response, String subjectId) {
    try {
      final data = jsonDecode(response);
      if (data is Map<String, dynamic>) {
        data['subjectId'] = subjectId;
        return data;
      }
      return {'subjectId': subjectId, 'content': response};
    } catch (e) {
      return {'subjectId': subjectId, 'content': response};
    }
  }
  
  List<Question> _getMockQuestions(String topicTitle, int count, int difficulty, String subjectId) {
    return List.generate(count, (i) {
      return Question(
        id: 'mock_q_${subjectId}_$i',
        subjectId: subjectId,
        topicId: 'topic_1',
        text: 'Mock question about $topicTitle (Q$i) for subject $subjectId?',
        type: _getMockQuestionType(i),
        difficulty: difficulty,
        markscheme: 'Mock answer for question $i',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });
  }

  List<LessonBlock> _getMockLessonBlocks(String subjectId) {
    return [
      LessonBlock(
        id: 'mock_block_${subjectId}_1',
        subjectId: subjectId,
        lessonId: 'lesson_mock',
        type: LessonBlockType.text,
        content: 'This is a mock explanation block for subject $subjectId.',
        order: 0,
      ),
      LessonBlock(
        id: 'mock_block_${subjectId}_2',
        subjectId: subjectId,
        lessonId: 'lesson_mock',
        type: LessonBlockType.example,
        content: 'Example for subject $subjectId: This demonstrates the concept.',
        order: 1,
      ),
      LessonBlock(
        id: 'mock_block_${subjectId}_3',
        subjectId: subjectId,
        lessonId: 'lesson_mock',
        type: LessonBlockType.exercise,
        content: 'Exercise for subject $subjectId: Practice applying what you learned.',
        order: 2,
      ),
    ];
  }

  Lesson _getMockLesson(String title, String subjectId, String topicId, int difficulty) {
    return Lesson(
      id: 'mock_lesson_${subjectId}',
      subjectId: subjectId,
      title: title,
      topicId: topicId,
      blocks: _getMockLessonBlocks(subjectId),
      difficulty: difficulty,
      generatedBy: GeneratedBy.ai,
      createdAt: DateTime.now(),
    );
  }

  String _mockValidateAnswer(String subjectId) {
    return 'Answer validation mock result for subject $subjectId.';
  }

  Map<String, dynamic> _mockStudyPlan(String subjectId, String course, int days, int hoursPerDay) {
    return {
      'subjectId': subjectId,
      'course': course,
      'days': days,
      'hoursPerDay': hoursPerDay,
      'schedule': [
        {'day': 1, 'topic': 'Introduction', 'hours': hoursPerDay},
        {'day': 2, 'topic': 'Core Concepts', 'hours': hoursPerDay},
      ],
    };
  }

  QuestionType _getMockQuestionType(int index) {
    final types = QuestionType.values;
    return types[index % types.length];
  }
}
