import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/repositories/conversation_repository.dart';
import 'package:studyking/core/data/models/conversation_message_model.dart';

class _MockConversationRepository extends ConversationRepository {
  final Map<String, ConversationMessage> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> saveMessage(ConversationMessage message) async {
    _storage[message.id] = message;
  }

  @override
  Future<ConversationMessage?> getMessage(String id) async {
    return _storage[id];
  }

  @override
  Future<List<ConversationMessage>> getSessionMessages(String sessionId) async {
    final all = _storage.values.toList();
    all.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return all.where((m) => m.sessionId == sessionId).toList();
  }

  @override
  Future<void> deleteSessionMessages(String sessionId) async {
    _storage.removeWhere((key, m) => m.sessionId == sessionId);
  }

  @override
  Future<void> deleteMessage(String id) async {
    _storage.remove(id);
  }

  @override
  Future<List<ConversationMessage>> getRecentMessages({
    int limit = 10,
    String? sessionId,
  }) async {
    var messages = _storage.values.toList();
    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (sessionId != null) {
      messages = messages.where((m) => m.sessionId == sessionId).toList();
    }
    return messages.take(limit).toList();
  }

  @override
  Future<void> clearAll() async {
    _storage.clear();
  }
}

void main() {
  group('ConversationRepository', () {
    late _MockConversationRepository repository;
    final now = DateTime(2025, 1, 15, 10, 0, 0);

    setUp(() {
      repository = _MockConversationRepository();
    });

    ConversationMessage createMessage({
      String id = 'msg-1',
      String sessionId = 'session-1',
      MessageRole role = MessageRole.tutor,
      MessageType type = MessageType.text,
      String content = 'Hello',
      DateTime? timestamp,
    }) {
      return ConversationMessage(
        id: id,
        sessionId: sessionId,
        role: role,
        type: type,
        content: content,
        timestamp: timestamp ?? now,
      );
    }

    group('saveMessage', () {
      test('stores a message', () async {
        final msg = createMessage();
        await repository.saveMessage(msg);
        final stored = await repository.getMessage('msg-1');
        expect(stored?.content, 'Hello');
      });

      test('overwrites existing message with same id', () async {
        final msg1 = createMessage(content: 'First');
        final msg2 = createMessage(content: 'Second');
        await repository.saveMessage(msg1);
        await repository.saveMessage(msg2);
        final stored = await repository.getMessage('msg-1');
        expect(stored?.content, 'Second');
      });
    });

    group('getMessage', () {
      test('returns null for non-existent message', () async {
        expect(await repository.getMessage('none'), isNull);
      });

      test('returns stored message', () async {
        final msg = createMessage();
        await repository.saveMessage(msg);
        expect(await repository.getMessage('msg-1'), isNotNull);
      });
    });

    group('getSessionMessages', () {
      test('returns messages in chronological order', () async {
        final msg1 = createMessage(id: 'm1', sessionId: 's1', content: 'First', timestamp: now);
        final msg2 = createMessage(id: 'm2', sessionId: 's1', content: 'Second', timestamp: now.add(const Duration(seconds: 5)));
        final msg3 = createMessage(id: 'm3', sessionId: 's1', content: 'Third', timestamp: now.add(const Duration(seconds: 10)));
        await repository.saveMessage(msg3);
        await repository.saveMessage(msg1);
        await repository.saveMessage(msg2);
        final messages = await repository.getSessionMessages('s1');
        expect(messages.length, 3);
        expect(messages[0].content, 'First');
        expect(messages[1].content, 'Second');
        expect(messages[2].content, 'Third');
      });

      test('filters by session id', () async {
        await repository.saveMessage(createMessage(id: 'm1', sessionId: 's1'));
        await repository.saveMessage(createMessage(id: 'm2', sessionId: 's2'));
        expect((await repository.getSessionMessages('s1')).length, 1);
        expect((await repository.getSessionMessages('s2')).length, 1);
      });

      test('returns empty list for session with no messages', () async {
        expect(await repository.getSessionMessages('empty'), isEmpty);
      });
    });

    group('deleteSessionMessages', () {
      test('deletes all messages for a session', () async {
        await repository.saveMessage(createMessage(id: 'm1', sessionId: 's1'));
        await repository.saveMessage(createMessage(id: 'm2', sessionId: 's1'));
        await repository.saveMessage(createMessage(id: 'm3', sessionId: 's2'));
        await repository.deleteSessionMessages('s1');
        expect(await repository.getMessage('m1'), isNull);
        expect(await repository.getMessage('m2'), isNull);
        expect(await repository.getMessage('m3'), isNotNull);
      });

      test('does nothing for non-existent session', () async {
        await repository.saveMessage(createMessage(id: 'm1', sessionId: 's1'));
        await repository.deleteSessionMessages('non-existent');
        expect(await repository.getMessage('m1'), isNotNull);
      });
    });

    group('deleteMessage', () {
      test('deletes a single message', () async {
        final msg = createMessage();
        await repository.saveMessage(msg);
        await repository.deleteMessage('msg-1');
        expect(await repository.getMessage('msg-1'), isNull);
      });

      test('does nothing for non-existent message', () async {
        await repository.deleteMessage('non-existent');
      });
    });

    group('getRecentMessages', () {
      test('returns most recent messages limited by count', () async {
        for (var i = 0; i < 20; i++) {
          await repository.saveMessage(createMessage(
            id: 'm$i',
            content: 'Msg $i',
            timestamp: now.add(Duration(minutes: i)),
          ));
        }
        final recent = await repository.getRecentMessages(limit: 5);
        expect(recent.length, 5);
        expect(recent[0].content, 'Msg 19');
        expect(recent[4].content, 'Msg 15');
      });

      test('filters by sessionId when provided', () async {
        for (var i = 0; i < 5; i++) {
          await repository.saveMessage(createMessage(
            id: 's1_m$i', sessionId: 's1',
            timestamp: now.add(Duration(minutes: i)),
          ));
          await repository.saveMessage(createMessage(
            id: 's2_m$i', sessionId: 's2',
            timestamp: now.add(Duration(minutes: i)),
          ));
        }
        final recent = await repository.getRecentMessages(limit: 10, sessionId: 's1');
        expect(recent.length, 5);
        for (final msg in recent) {
          expect(msg.sessionId, 's1');
        }
      });

      test('returns all when fewer than limit', () async {
        await repository.saveMessage(createMessage(id: 'm1'));
        await repository.saveMessage(createMessage(id: 'm2'));
        final recent = await repository.getRecentMessages(limit: 10);
        expect(recent.length, 2);
      });

      test('returns empty when no messages', () async {
        expect(await repository.getRecentMessages(), isEmpty);
      });
    });

    group('clearAll', () {
      test('removes all messages', () async {
        await repository.saveMessage(createMessage(id: 'm1'));
        await repository.saveMessage(createMessage(id: 'm2'));
        await repository.clearAll();
        expect(await repository.getMessage('m1'), isNull);
        expect(await repository.getMessage('m2'), isNull);
      });
    });
  });
}
