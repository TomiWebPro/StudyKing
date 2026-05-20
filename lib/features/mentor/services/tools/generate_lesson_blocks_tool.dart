import 'package:flutter/material.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/features/lessons/services/lesson_agent_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class GenerateLessonBlocksTool extends AgentTool {
  final LessonAgentService _lessonAgentService;
  final String _localeName;

  GenerateLessonBlocksTool({required LessonAgentService lessonAgentService, String localeName = 'en'})
      : _lessonAgentService = lessonAgentService,
        _localeName = localeName;

  @override
  String get name => 'generate_lesson_blocks';

  @override
  String get description =>
      'Generate structured lesson blocks (slides, text, examples, exercises, quiz, summary) for a topic.';

  @override
  Map<String, dynamic> get parameters => {
    'type': 'object',
    'properties': {
      'subjectId': {'type': 'string', 'description': 'Subject ID'},
      'topicId': {'type': 'string', 'description': 'Topic ID'},
      'topicTitle': {'type': 'string', 'description': 'Topic title'},
      'localeName': {
        'type': 'string',
        'description': 'Locale for content',
        'default': 'en',
      },
    },
    'required': ['subjectId', 'topicId', 'topicTitle'],
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final lesson = await _lessonAgentService.generateLesson(
      subjectId: args['subjectId'] as String,
      topicId: args['topicId'] as String,
      topicTitle: args['topicTitle'] as String,
      localeName: (args['localeName'] as String?) ?? 'en',
    );

    final l10n = lookupAppLocalizations(Locale(_localeName));

    if (lesson == null) {
      return {'success': false, 'message': l10n.toolGenerateBlocksFail};
    }

    return {
      'success': true,
      'lessonId': lesson.id,
      'blockCount': lesson.blocks.length,
      'title': lesson.title,
    };
  }
}
