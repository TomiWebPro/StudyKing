import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/teaching/data/adapters/conversation_message_adapter.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';

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

  group('ConversationRepository Hive integration', () {
    late ConversationRepository hiveRepo;
    late String hivePath;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final dir = await Directory.systemTemp.createTemp('hive_conversation_test_');
      hivePath = dir.path;
      Hive.init(hivePath);
      if (!Hive.isAdapterRegistered(27)) {
        Hive.registerAdapter(ConversationMessageAdapter());
      }
      hiveRepo = ConversationRepository();
      await hiveRepo.init();
    });

    tearDown(() async {
      await Hive.close();
      if (hivePath.isNotEmpty) {
        await Directory(hivePath).delete(recursive: true);
      }
    });

    ConversationMessage hiveMsg({
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
        timestamp: timestamp ?? DateTime(2025, 1, 15, 10, 0, 0),
      );
    }

    test('init initializes successfully', () async {
      final repo = ConversationRepository();
      await repo.init();
      // No exception means success
    });

    test('init can be called multiple times without error', () async {
      await hiveRepo.init();
      await hiveRepo.init();
    });

    group('CRUD operations', () {
      test('saves and retrieves a message', () async {
        final msg = hiveMsg();
        await hiveRepo.saveMessage(msg);
        final retrieved = await hiveRepo.getMessage('msg-1');
        expect(retrieved, isNotNull);
        expect(retrieved!.content, 'Hello');
        expect(retrieved.role, MessageRole.tutor);
        expect(retrieved.type, MessageType.text);
      });

      test('getMessage returns null for non-existent id', () async {
        expect(await hiveRepo.getMessage('non-existent'), isNull);
      });

      test('saveMessage overwrites existing message with same id', () async {
        final msg1 = hiveMsg(content: 'First');
        final msg2 = hiveMsg(content: 'Second');
        await hiveRepo.saveMessage(msg1);
        await hiveRepo.saveMessage(msg2);
        final stored = await hiveRepo.getMessage('msg-1');
        expect(stored?.content, 'Second');
      });
    });

    group('getSessionMessages', () {
      test('returns messages in chronological order', () async {
        final now = DateTime(2025, 1, 15, 10, 0, 0);
        final m1 = hiveMsg(id: 'm1', sessionId: 's1', content: 'First', timestamp: now);
        final m2 = hiveMsg(id: 'm2', sessionId: 's1', content: 'Second', timestamp: now.add(const Duration(seconds: 5)));
        final m3 = hiveMsg(id: 'm3', sessionId: 's1', content: 'Third', timestamp: now.add(const Duration(seconds: 10)));
        await hiveRepo.saveMessage(m3);
        await hiveRepo.saveMessage(m1);
        await hiveRepo.saveMessage(m2);
        final messages = await hiveRepo.getSessionMessages('s1');
        expect(messages.length, 3);
        expect(messages[0].content, 'First');
        expect(messages[1].content, 'Second');
        expect(messages[2].content, 'Third');
      });

      test('filters by session id', () async {
        await hiveRepo.saveMessage(hiveMsg(id: 'm1', sessionId: 's1'));
        await hiveRepo.saveMessage(hiveMsg(id: 'm2', sessionId: 's2'));
        expect((await hiveRepo.getSessionMessages('s1')).length, 1);
        expect((await hiveRepo.getSessionMessages('s2')).length, 1);
      });

      test('returns empty list for session with no messages', () async {
        expect(await hiveRepo.getSessionMessages('empty'), isEmpty);
      });
    });

    group('deleteSessionMessages', () {
      test('deletes all messages for a session', () async {
        await hiveRepo.saveMessage(hiveMsg(id: 'm1', sessionId: 's1'));
        await hiveRepo.saveMessage(hiveMsg(id: 'm2', sessionId: 's1'));
        await hiveRepo.saveMessage(hiveMsg(id: 'm3', sessionId: 's2'));
        await hiveRepo.deleteSessionMessages('s1');
        expect(await hiveRepo.getMessage('m1'), isNull);
        expect(await hiveRepo.getMessage('m2'), isNull);
        expect(await hiveRepo.getMessage('m3'), isNotNull);
      });

      test('does nothing for non-existent session', () async {
        await hiveRepo.saveMessage(hiveMsg(id: 'm1', sessionId: 's1'));
        await hiveRepo.deleteSessionMessages('non-existent');
        expect(await hiveRepo.getMessage('m1'), isNotNull);
      });
    });

    group('deleteMessage', () {
      test('deletes a single message', () async {
        await hiveRepo.saveMessage(hiveMsg());
        await hiveRepo.deleteMessage('msg-1');
        expect(await hiveRepo.getMessage('msg-1'), isNull);
      });

      test('does nothing for non-existent message', () async {
        await hiveRepo.deleteMessage('non-existent');
      });
    });

    group('getRecentMessages', () {
      test('returns most recent messages limited by count', () async {
        final now = DateTime(2025, 1, 15, 10, 0, 0);
        for (var i = 0; i < 20; i++) {
          await hiveRepo.saveMessage(hiveMsg(
            id: 'm$i',
            content: 'Msg $i',
            timestamp: now.add(Duration(minutes: i)),
          ));
        }
        final recent = await hiveRepo.getRecentMessages(limit: 5);
        expect(recent.length, 5);
        expect(recent[0].content, 'Msg 19');
        expect(recent[4].content, 'Msg 15');
      });

      test('filters by sessionId when provided', () async {
        final now = DateTime(2025, 1, 15, 10, 0, 0);
        for (var i = 0; i < 5; i++) {
          await hiveRepo.saveMessage(hiveMsg(
            id: 's1_m$i', sessionId: 's1',
            timestamp: now.add(Duration(minutes: i)),
          ));
          await hiveRepo.saveMessage(hiveMsg(
            id: 's2_m$i', sessionId: 's2',
            timestamp: now.add(Duration(minutes: i)),
          ));
        }
        final recent = await hiveRepo.getRecentMessages(limit: 10, sessionId: 's1');
        expect(recent.length, 5);
        for (final msg in recent) {
          expect(msg.sessionId, 's1');
        }
      });

      test('returns all when fewer than limit', () async {
        await hiveRepo.saveMessage(hiveMsg(id: 'm1'));
        await hiveRepo.saveMessage(hiveMsg(id: 'm2'));
        final recent = await hiveRepo.getRecentMessages(limit: 10);
        expect(recent.length, 2);
      });

      test('returns empty when no messages', () async {
        expect(await hiveRepo.getRecentMessages(), isEmpty);
      });
    });

    group('clearAll', () {
      test('removes all messages', () async {
        await hiveRepo.saveMessage(hiveMsg(id: 'm1'));
        await hiveRepo.saveMessage(hiveMsg(id: 'm2'));
        await hiveRepo.clearAll();
        expect(await hiveRepo.getMessage('m1'), isNull);
        expect(await hiveRepo.getMessage('m2'), isNull);
      });
    });
  });
}
