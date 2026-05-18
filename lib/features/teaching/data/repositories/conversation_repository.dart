import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/core/data/repository.dart';

class ConversationRepository extends Repository<ConversationMessage> {
  Future<void> init() async {
    await openBox(HiveBoxNames.conversations);
  }

  Future<Result<void>> create(ConversationMessage message) async {
    return super.put(message.id, message);
  }

  Future<Result<void>> saveMessage(ConversationMessage message) async {
    return create(message);
  }

  Future<Result<ConversationMessage?>> getMessage(String id) async {
    return super.get(id);
  }

  Future<Result<List<ConversationMessage>>> getSessionMessages(
      String sessionId) async {
    return Result.capture(() async {
      final bySession = filterBy((m) => m.sessionId, sessionId)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return bySession;
    }, context: 'getSessionMessages');
  }

  Future<Result<void>> deleteSessionMessages(String sessionId) async {
    return Result.capture(() async {
      final toDelete = filterBy((m) => m.sessionId, sessionId)
          .map((m) => m.key)
          .toList();
      await box.deleteAll(toDelete);
    }, context: 'deleteSessionMessages');
  }

  Future<Result<void>> deleteMessage(String id) async {
    return super.delete(id);
  }

  Future<Result<List<ConversationMessage>>> getRecentMessages({
    int limit = 10,
    String? sessionId,
  }) async {
    return Result.capture(() async {
      if (sessionId != null) {
        final bySession = filterBy((m) => m.sessionId, sessionId)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return bySession.take(limit).toList();
      }
      var messages = box.values.toList();
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return messages.take(limit).toList();
    }, context: 'getRecentMessages');
  }

  Future<Result<void>> clearAll() async {
    return Result.capture(() async {
      await box.clear();
    }, context: 'clearAll');
  }
}
