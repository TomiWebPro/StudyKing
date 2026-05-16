import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';

class ConversationMemory {
  final List<ConversationMessage> messages;
  final int maxTurns;
  final String? sessionId;
  final ConversationRepository? _repository;

  ConversationMemory({this.maxTurns = 20, this.sessionId, ConversationRepository? repository})
      : messages = [],
        _repository = repository;

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
    }
    _persistMessage(msg);
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
    final stored = await repo.getSessionMessages(sid);
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
