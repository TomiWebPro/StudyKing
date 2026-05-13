import 'package:hive_flutter/hive_flutter.dart';
import '../models/conversation_message_model.dart';

class ConversationRepository {
  Box<ConversationMessage>? _messageBox;

  ConversationRepository({Box<ConversationMessage>? messageBox})
      : _messageBox = messageBox;

  Future<void> init() async {
    _messageBox = await Hive.openBox<ConversationMessage>('conversations');
  }

  Box<ConversationMessage> get _box {
    if (_messageBox == null) {
      throw StateError('ConversationRepository not initialized');
    }
    return _messageBox!;
  }

  Future<void> saveMessage(ConversationMessage message) async {
    await _box.put(message.id, message);
  }

  Future<ConversationMessage?> getMessage(String id) async {
    return _box.get(id);
  }

  Future<List<ConversationMessage>> getSessionMessages(String sessionId) async {
    final all = _box.values.toList();
    all.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return all.where((m) => m.sessionId == sessionId).toList();
  }

  Future<void> deleteSessionMessages(String sessionId) async {
    final toDelete = _box.values
        .where((m) => m.sessionId == sessionId)
        .map((m) => m.key)
        .toList();
    await _box.deleteAll(toDelete);
  }

  Future<void> deleteMessage(String id) async {
    await _box.delete(id);
  }

  Future<List<ConversationMessage>> getRecentMessages({
    int limit = 10,
    String? sessionId,
  }) async {
    var messages = _box.values.toList();
    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (sessionId != null) {
      messages = messages.where((m) => m.sessionId == sessionId).toList();
    }
    return messages.take(limit).toList();
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
