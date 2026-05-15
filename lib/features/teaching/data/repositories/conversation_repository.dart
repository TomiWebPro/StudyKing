import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/core/data/repository.dart';

class ConversationRepository extends Repository<ConversationMessage> {
  Future<void> init() async {
    await openBox(HiveBoxNames.conversations);
  }

  Future<void> create(ConversationMessage message) async {
    await save(message.id, message);
  }

  Future<void> saveMessage(ConversationMessage message) async {
    await create(message);
  }

  Future<ConversationMessage?> getMessage(String id) async {
    return get(id);
  }

  Future<List<ConversationMessage>> getSessionMessages(String sessionId) async {
    final bySession = filterBy((m) => m.sessionId, sessionId)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return bySession;
  }

  Future<void> deleteSessionMessages(String sessionId) async {
    final toDelete = filterBy((m) => m.sessionId, sessionId)
        .map((m) => m.key)
        .toList();
    await box.deleteAll(toDelete);
  }

  Future<void> deleteMessage(String id) async {
    await delete(id);
  }

  Future<List<ConversationMessage>> getRecentMessages({
    int limit = 10,
    String? sessionId,
  }) async {
    if (sessionId != null) {
      final bySession = filterBy((m) => m.sessionId, sessionId)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return bySession.take(limit).toList();
    }
    var messages = box.values.toList();
    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return messages.take(limit).toList();
  }

  Future<void> clearAll() async {
    await box.clear();
  }
}
