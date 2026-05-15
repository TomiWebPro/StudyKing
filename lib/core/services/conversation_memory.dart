import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';

class ConversationMemory {
  final List<Map<String, String>> messages;
  final int maxTurns;
  final String? sessionId;
  final ConversationRepository? _repository;

  ConversationMemory({this.maxTurns = 20, this.sessionId, ConversationRepository? repository})
      : messages = [],
        _repository = repository;

  void addMessage(String role, String content) {
    messages.add({'role': role, 'content': content});
    if (messages.length > maxTurns * 2) {
      messages.removeRange(0, messages.length - maxTurns * 2);
    }
    _persistMessage(role, content);
  }

  void _persistMessage(String role, String content) {
    final sid = sessionId;
    final repo = _repository;
    if (repo == null || sid == null) return;
    final messageRole = switch (role) {
      'assistant' => MessageRole.tutor,
      'system' => MessageRole.system,
      _ => MessageRole.student,
    };
    repo.saveMessage(ConversationMessage(
      id: '${sid}_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sid,
      role: messageRole,
      type: MessageType.text,
      content: content,
      timestamp: DateTime.now(),
    ));
  }

  void addUserMessage(String content) => addMessage('user', content);
  void addAssistantMessage(String content) => addMessage('assistant', content);
  void addSystemMessage(String content) => addMessage('system', content);

  List<Map<String, String>> getHistory() => List.from(messages);

  void clear() => messages.clear();

  List<Map<String, String>> getRecent({int turns = 5}) {
    final recent = messages.length > turns * 2
        ? messages.sublist(messages.length - turns * 2)
        : messages;
    return List.from(recent);
  }

  Future<void> loadFromRepository() async {
    final sid = sessionId;
    final repo = _repository;
    if (repo == null || sid == null) return;
    final stored = await repo.getSessionMessages(sid);
    messages.clear();
    for (final msg in stored) {
      final role = switch (msg.role) {
        MessageRole.tutor || MessageRole.mentor => 'assistant',
        MessageRole.system => 'system',
        _ => 'user',
      };
      messages.add({'role': role, 'content': msg.content});
    }
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
