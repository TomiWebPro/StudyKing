import 'dart:async';

import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';

class ConversationMemory {
  static final Logger _logger = const Logger('ConversationMemory');
  final List<ConversationMessage> messages;
  final int maxTurns;
  final String? sessionId;
  final ConversationRepository? _repository;
  bool _truncationNotified = false;

  ConversationMemory({this.maxTurns = 20, this.sessionId, ConversationRepository? repository})
      : messages = [],
        _repository = repository;

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

  void addMessage(String role, String content) {
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
    if (messages.length > maxTurns * 2) {
      messages.removeRange(0, messages.length - maxTurns * 2);
      if (!_truncationNotified) {
        _truncationNotified = true;
        final truncMsg = ConversationMessage(
          id: '${sessionId}_trunc_${DateTime.now().millisecondsSinceEpoch}',
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
    _persistMessage(msg);
    unawaited(_trimRepository());
  }

  void _persistMessage(ConversationMessage msg) {
    final repo = _repository;
    if (repo == null) return;
    repo.saveMessage(msg);
  }

  void addUserMessage(String content) => addMessage('user', content);
  void addAssistantMessage(String content) => addMessage('assistant', content);
  void addSystemMessage(String content) => addMessage('system', content);

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
