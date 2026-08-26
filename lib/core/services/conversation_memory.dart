import 'dart:async';

import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';

/// Callback that summarises a batch of older messages into a single
/// compressed context string. Returns null if summarisation is not available.
typedef ConversationSummarizer = Future<String?> Function(
  List<ConversationMessage> messages,
);

class ConversationMemory {
  static final Logger _logger = const Logger('ConversationMemory');
  static const double _compressionThreshold = 0.8;

  final List<ConversationMessage> messages;
  final int maxTurns;
  final String? sessionId;
  final ConversationRepository? _repository;
  final ConversationSummarizer? _summarizer;
  bool _truncationNotified = false;

  ConversationMemory({
    this.maxTurns = 20,
    this.sessionId,
    ConversationRepository? repository,
    ConversationSummarizer? summarizer,
  })  : messages = [],
        _repository = repository,
        _summarizer = summarizer;

  Future<void> _trimRepository() async {
    final repo = _repository;
    final sid = sessionId;
    if (repo == null || sid == null) return;
    final result = await Result.capture(() async {
      final storedResult = await repo.getSessionMessages(sid);
      final stored = storedResult.data ?? [];
      if (stored.length > maxTurns * 2) {
        final toRemove = stored.sublist(0, stored.length - maxTurns * 2);
        for (final msg in toRemove) {
          await repo.deleteMessage(msg.id);
        }
      }
    }, context: '_trimRepository');
    if (result.isFailure) {
      _logger.w('Failed to trim repository: ${result.error}');
    }
  }

  Future<Result<void>> addMessage(String role, String content) async {
    return Result.capture(() async {
      final messageRole = switch (role) {
        'assistant' => MessageRole.tutor,
        'system' => MessageRole.system,
        _ => MessageRole.student,
      };
      final msg = ConversationMessage(
        id: '${sessionId ?? 'mem'}_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId ?? '',
        role: messageRole,
        type: MessageType.text,
        content: content,
        timestamp: DateTime.now(),
      );
      messages.add(msg);

      final threshold = (maxTurns * 2 * _compressionThreshold).toInt();
      if (messages.length >= threshold) {
        await _compressOldMessages();
      }
      if (messages.length > maxTurns * 2) {
        await _dropOldestMessages();
      }

      _persistMessage(msg);
      unawaited(_trimRepository());
    }, context: 'addMessage');
  }

  Future<void> _compressOldMessages() async {
    final summarizer = _summarizer;
    if (summarizer == null) return;

    final maxKeep = (maxTurns * 2 * 0.5).toInt();
    if (messages.length <= maxKeep) return;

    final countToSummarise = messages.length - maxKeep;
    final toSummarise = messages.sublist(0, countToSummarise);

    try {
      final summary = await summarizer(toSummarise);
      if (summary == null || summary.isEmpty) return;

      final summaryMsg = ConversationMessage(
        id: '${sessionId ?? 'mem'}_summary_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId ?? '',
        role: MessageRole.system,
        type: MessageType.system,
        content: '[Earlier conversation summary]\n$summary',
        timestamp: DateTime.now(),
      );

      messages.removeRange(0, countToSummarise);
      messages.insert(0, summaryMsg);
      _persistMessage(summaryMsg);

      _logger.i('Compressed ${toSummarise.length} messages into summary');
    } catch (e) {
      _logger.w('Failed to compress messages: $e');
    }
  }

  Future<void> _dropOldestMessages() async {
    final kept = messages.length - maxTurns * 2;
    if (kept <= 0) return;

    final toDrop = messages.sublist(0, kept);

    final summary = await _summarizeBatch(toDrop);
    if (summary != null && summary.isNotEmpty) {
      final summaryMsg = ConversationMessage(
        id: '${sessionId ?? 'mem'}_drop_summary_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId ?? '',
        role: MessageRole.system,
        type: MessageType.system,
        content: '[Earlier conversation summary]\n$summary',
        timestamp: DateTime.now(),
      );
      messages.removeRange(0, kept);
      messages.insert(0, summaryMsg);
      _persistMessage(summaryMsg);
      _logger.i('Summarised ${toDrop.length} dropped messages into summary');
    } else {
      messages.removeRange(0, kept);
      if (!_truncationNotified) {
        _truncationNotified = true;
        final truncMsg = ConversationMessage(
          id: '${sessionId ?? 'mem'}_trunc_${DateTime.now().millisecondsSinceEpoch}',
          sessionId: sessionId ?? '',
          role: MessageRole.system,
          type: MessageType.system,
          content: 'Conversation history trimmed. Older messages are no longer visible to the AI.',
          timestamp: DateTime.now(),
        );
        messages.add(truncMsg);
        _persistMessage(truncMsg);
      }
    }
  }

  Future<String?> _summarizeBatch(List<ConversationMessage> messages) async {
    final summarizer = _summarizer;
    if (summarizer == null) return null;
    try {
      return await summarizer(messages);
    } catch (e) {
      _logger.w('Failed to summarise batch: $e');
      return null;
    }
  }

  void _persistMessage(ConversationMessage msg) {
    final repo = _repository;
    if (repo == null) return;
    repo.saveMessage(msg);
  }

  Future<Result<void>> addUserMessage(String content) => addMessage('user', content);
  Future<Result<void>> addAssistantMessage(String content) => addMessage('assistant', content);
  Future<Result<void>> addSystemMessage(String content) => addMessage('system', content);

  List<ConversationMessage> getHistory() => List.from(messages);

  void clear() => messages.clear();

  List<ConversationMessage> getRecent({int turns = 5}) {
    final recent = messages.length > turns * 2
        ? messages.sublist(messages.length - turns * 2)
        : messages;
    return List.from(recent);
  }

  Future<void> loadFromRepository() async {
    final sid = sessionId;
    final repo = _repository;
    if (repo == null || sid == null) return;
    final storedResult = await repo.getSessionMessages(sid);
    final stored = storedResult.data ?? [];
    messages.clear();
    messages.addAll(stored);
  }

  static List<Map<String, String>> fromConversationMessages(
    List<ConversationMessage> messages,
  ) {
    return messages
        .where((m) => !m.isStreaming)
        .map((m) => {
              'role': m.role == MessageRole.tutor || m.role == MessageRole.mentor
                  ? 'assistant'
                  : m.role == MessageRole.system
                      ? 'system'
                      : 'user',
              'content': m.content,
            })
        .toList();
  }
}
