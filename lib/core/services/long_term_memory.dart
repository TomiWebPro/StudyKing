import 'dart:async';
import 'package:studyking/core/services/llm_agent/agent_memory.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';

class LongTermMemory {
  static final Logger _logger = const Logger('LongTermMemory');
  final AgentMemoryStore _store;
  final PendingActionRepository _pendingActionRepo;
  bool _initialized = false;

  LongTermMemory({
    AgentMemoryStore? store,
    PendingActionRepository? pendingActionRepo,
  })  : _store = store ?? AgentMemoryStore(),
        _pendingActionRepo = pendingActionRepo ?? PendingActionRepository();

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _store.init();
    await _pendingActionRepo.init();
  }

  String? recallFact(String studentId, String key) {
    return _store.recallFact(studentId, key);
  }

  Future<void> rememberFact(String studentId, String key, String value) async {
    await _store.rememberFact(studentId, key, value);
  }

  Future<void> storeStudentProfile(
      String studentId, Map<String, dynamic> profile) async {
    final existing = getStudentProfile(studentId) ?? {};
    existing.addAll(profile);
    await _store.storeStudentProfile(studentId, existing);
  }

  Map<String, dynamic>? getStudentProfile(String studentId) {
    return _store.getStudentProfile(studentId);
  }

  Future<void> storeSessionSummary(
      String studentId, String sessionId, String summary) async {
    await _store.storeSessionSummary(studentId, sessionId, summary);
  }

  String? getSessionSummary(String studentId, String sessionId) {
    return _store.getSessionSummary(studentId, sessionId);
  }

  Future<String> generateAndStoreSummary({
    required LlmService llmService,
    required String modelId,
    required String studentId,
    required String sessionId,
    required List<Map<String, String>> conversationMessages,
    String? topicTitle,
    int exerciseCount = 0,
    int correctCount = 0,
    double confidenceRating = 0.0,
  }) async {
    final prompt = _buildSummaryPrompt(
      topicTitle: topicTitle ?? 'General',
      exerciseCount: exerciseCount,
      correctCount: correctCount,
      confidenceRating: confidenceRating,
      conversationMessages: conversationMessages,
    );

    final result = await llmService.chat(
      message: prompt,
      modelId: modelId,
      systemPrompt: _summarySystemPrompt(),
      feature: 'long_term_memory_summary',
    );

    if (result.isFailure) {
      _logger.w('Failed to generate session summary', result.error);
      return '';
    }

    final summary = result.data!;
    await storeSessionSummary(studentId, sessionId, summary);
    return summary;
  }

  String _buildSummaryPrompt({
    required String topicTitle,
    required int exerciseCount,
    required int correctCount,
    required double confidenceRating,
    required List<Map<String, String>> conversationMessages,
  }) {
    final recentMessages = conversationMessages.length > 10
        ? conversationMessages.sublist(conversationMessages.length - 10)
        : conversationMessages;

    final messagesStr = recentMessages
        .map((m) => '[${m['role']}]: ${m['content']}')
        .join('\n');

    return 'Summarize this study session about "$topicTitle".\n'
        'Exercises: $exerciseCount, Correct: $correctCount\n'
        'Confidence: ${(confidenceRating * 100).round()}%\n\n'
        'Recent conversation:\n$messagesStr\n\n'
        'Include:\n'
        '1. Key topics covered and concepts discussed\n'
        '2. Student\'s apparent understanding and areas of difficulty\n'
        '3. Questions or exercises attempted and results\n'
        '4. Any specific preferences or feedback the student mentioned\n'
        '5. Recommended follow-up topics or actions\n\n'
        'Keep it concise and actionable.';
  }

  String _summarySystemPrompt() {
    return 'You are generating session summaries for a student\'s long-term memory. '
        'Write concise, structured summaries that will help a mentor or tutor '
        'quickly understand what was covered, how the student performed, '
        'and what should be followed up on.';
  }

  Future<void> addActionItem(String studentId, String actionType,
      {String topicTitle = '',
      String? sessionId,
      Map<String, dynamic> payload = const {}}) async {
    final action = PendingActionModel(
      id: 'ltm_${DateTime.now().millisecondsSinceEpoch}_$studentId',
      studentId: studentId,
      actionType: actionType,
      topicTitle: topicTitle,
      sessionId: sessionId,
      payload: payload,
    );
    await _pendingActionRepo.create(action);
  }

  Future<List<PendingActionModel>> getPendingActionItems(
      String studentId) async {
    final result = await _pendingActionRepo.getPending(studentId);
    return result.data ?? [];
  }

  Future<List<String>> getRecentStudentSummaries(
      String studentId, {int limit = 5}) async {
    final sessionIds = _store.getSessionIds(studentId);
    final recent = sessionIds.length > limit
        ? sessionIds.sublist(sessionIds.length - limit)
        : sessionIds;
    final summaries = <String>[];
    for (final sid in recent.reversed) {
      final summary = _store.getSessionSummary(studentId, sid);
      if (summary != null && summary.isNotEmpty) {
        summaries.add(summary);
      }
    }
    return summaries;
  }

  Future<String> buildMemoryContext(String studentId) async {
    final profile = getStudentProfile(studentId);
    final recentSummaries = await getRecentStudentSummaries(studentId);
    final pendingItems = await getPendingActionItems(studentId);

    final buffer = StringBuffer();
    buffer.writeln('=== LONG-TERM MEMORY CONTEXT ===');

    if (profile != null && profile.isNotEmpty) {
      buffer.writeln('Student Profile:');
      for (final entry in profile.entries) {
        buffer.writeln('  - ${entry.key}: ${entry.value}');
      }
    }

    if (recentSummaries.isNotEmpty) {
      buffer.writeln('\nRecent Session Summaries:');
      for (var i = 0; i < recentSummaries.length; i++) {
        buffer.writeln('  Summary ${i + 1}: ${recentSummaries[i]}');
      }
    }

    if (pendingItems.isNotEmpty) {
      buffer.writeln('\nPending Action Items:');
      for (final item in pendingItems) {
        buffer.writeln(
            '  - [${item.actionType}] ${item.topicTitle}: ${item.payload}');
      }
    }

    buffer.writeln('=== END LONG-TERM MEMORY CONTEXT ===');
    return buffer.toString();
  }

  Future<void> clearStudentMemory(String studentId) async {
    await _store.clearStudentMemory(studentId);
  }
}
