import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/models/lesson_recap_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/features/teaching/data/repositories/lesson_recap_repository.dart';
import 'package:studyking/features/teaching/services/prompts/prompts.dart';
import 'package:studyking/core/errors/result.dart';

/// Produces and persists a structured end-of-lesson recap ("how the class went").
///
/// The recap is derived from the conversation transcript and the session's
/// attempt data, generated via the LLM into a fixed JSON schema, and stored so
/// it can be surfaced from lesson history / detail screens.
class LessonRecapService {
  static final Logger _logger = const Logger('LessonRecapService');

  final LlmService _llmService;
  final String _modelId;
  final LessonRecapRepository _repository;
  final Clock _clock;
  final ConversationPromptSet _prompts;

  LessonRecapService({
    required LlmService llmService,
    required String modelId,
    required LessonRecapRepository repository,
    required String localeName,
    Clock? clock,
  })  : _llmService = llmService,
        _modelId = modelId,
        _repository = repository,
        _clock = clock ?? SystemClock(),
        _prompts = ConversationPromptSet(localeName: localeName);

  String get providerName => _llmService.config.provider.name;

  ConversationPromptSet _promptSetFor(String localeName) {
    if (localeName == _prompts.localeName) return _prompts;
    return ConversationPromptSet(localeName: localeName);
  }

  String _transcriptFrom(List<ConversationMessage> messages) {
    if (messages.isEmpty) return '(no transcript available)';
    return messages
        .map((m) => '[${m.role.name}]: ${m.content}')
        .join('\n');
  }

  LessonRecapModel _deriveFallbackRecap({
    required TutorSession session,
    required List<ConversationMessage> messages,
    required String id,
  }) {
    final transcript = _transcriptFrom(messages);
    final topicsCovered = session.topicsCovered.isNotEmpty
        ? session.topicsCovered
        : [session.topicTitle];
    final accuracy = session.questionsAsked > 0
        ? session.questionsCorrect / session.questionsAsked
        : 0.0;
    return LessonRecapModel(
      id: id,
      sessionId: session.id,
      lessonId: session.lessonId,
      studentId: session.studentId,
      subjectId: session.subjectId,
      topicId: session.topicId,
      topicTitle: session.topicTitle,
      topicsCovered: topicsCovered,
      struggles: const [],
      homework: const [],
      summary: 'Lesson on ${session.topicTitle} completed. '
          'The student answered ${session.questionsCorrect} of '
          '${session.questionsAsked} exercises correctly.'
          '${transcript.length > 200 ? ' ${transcript.substring(0, 200)}' : ''}',
      accuracy: accuracy,
      questionCount: session.questionsAsked,
      correctCount: session.questionsCorrect,
      confidenceRating: session.confidenceRating,
      participationMessages: session.totalMessages,
      generatedAt: _clock.now(),
      providerName: providerName,
    );
  }

  Map<String, dynamic>? _parseRecapJson(String raw) {
    try {
      var cleaned = raw.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '');
        final end = cleaned.lastIndexOf('```');
        if (end != -1) cleaned = cleaned.substring(0, end);
        cleaned = cleaned.trim();
      }
      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (e) {
      _logger.w('Failed to parse lesson recap JSON from LLM response', e);
    }
    return null;
  }

  LessonRecapModel _buildFromJson({
    required TutorSession session,
    required Map<String, dynamic> json,
    required String id,
  }) {
    List<String> readList(String key) {
      final value = json[key];
      if (value is List) {
        return value
            .where((e) => e != null)
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList();
      }
      if (value is String && value.trim().isNotEmpty) return [value.trim()];
      return [];
    }

    final accuracy = session.questionsAsked > 0
        ? session.questionsCorrect / session.questionsAsked
        : 0.0;

    return LessonRecapModel(
      id: id,
      sessionId: session.id,
      lessonId: session.lessonId,
      studentId: session.studentId,
      subjectId: session.subjectId,
      topicId: session.topicId,
      topicTitle: session.topicTitle,
      topicsCovered: readList('topicsCovered'),
      struggles: readList('struggles'),
      homework: readList('homework'),
      summary: (json['summary'] as String?)?.trim() ?? '',
      accuracy: accuracy,
      questionCount: session.questionsAsked,
      correctCount: session.questionsCorrect,
      confidenceRating: session.confidenceRating,
      participationMessages: session.totalMessages,
      generatedAt: _clock.now(),
      providerName: providerName,
    );
  }

  /// Generates (via LLM) and persists a structured recap for the given session.
  ///
  /// Falls back to a locally derived recap when the LLM call fails or returns
  /// no usable JSON, so a recap is always produced and stored.
  Future<Result<LessonRecapModel>> generateAndStoreRecap({
    required TutorSession session,
    required List<ConversationMessage> messages,
    String localeName = 'en',
  }) async {
    final id = const Uuid().v4();
    try {
      final entry = _promptSetFor(localeName).recap(
        topicTitle: session.topicTitle,
        exerciseCount: session.questionsAsked,
        correctCount: session.questionsCorrect,
        confidencePercent: session.confidenceRating * 20,
        conversation: _transcriptFrom(messages),
      );

      final result = await _llmService.chat(
        message: entry.userPrompt,
        modelId: _modelId,
        systemPrompt: entry.systemPrompt,
        feature: 'teaching_lesson_recap',
      );

      LessonRecapModel recap;
      if (result.isSuccess) {
        final parsed = _parseRecapJson(result.data!);
        recap = parsed != null
            ? _buildFromJson(session: session, json: parsed, id: id)
            : _deriveFallbackRecap(session: session, messages: messages, id: id);
      } else {
        _logger.w('LLM recap generation failed, using derived recap',
            result.error);
        recap = _deriveFallbackRecap(session: session, messages: messages, id: id);
      }

      final saveResult = await _repository.saveRecap(recap);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.error);
      }
      return Result.success(recap);
    } catch (e) {
      _logger.e('Unexpected error generating lesson recap', e);
      try {
        final fallback = _deriveFallbackRecap(
            session: session, messages: messages, id: id);
        await _repository.saveRecap(fallback);
        return Result.success(fallback);
      } catch (storeErr, stackTrace) {
        _logger.w('Failed to generate and store lesson recap', storeErr, stackTrace);
        return Result.failure('Failed to generate lesson recap: $storeErr');
      }
    }
  }

  Future<Result<LessonRecapModel?>> getRecapForSession(String sessionId) async {
    return _repository.getBySession(sessionId);
  }

  Future<Result<LessonRecapModel?>> getRecapForLesson(String lessonId) async {
    return _repository.getByLesson(lessonId);
  }

  Future<Result<List<LessonRecapModel>>> getStudentRecaps(
      String studentId) async {
    return _repository.getStudentRecaps(studentId);
  }

  Future<Result<void>> deleteForSession(String sessionId) async {
    return _repository.deleteForSession(sessionId);
  }
}
