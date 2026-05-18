import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/teaching/data/adapters/conversation_message_adapter.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';

class _FakeConversationBox implements Box<ConversationMessage> {
  final Map<dynamic, ConversationMessage> _storage = {};

  @override
  Iterable<ConversationMessage> get values => _storage.values;

  @override
  int get length => _storage.length;

  @override
  bool get isEmpty => _storage.isEmpty;

  @override
  bool get isNotEmpty => _storage.isNotEmpty;

  @override
  bool get isOpen => true;

  @override
  String get name => 'conversations';

  @override
  ConversationMessage? get(dynamic key, {ConversationMessage? defaultValue}) =>
      _storage[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, ConversationMessage value) async {
    _storage[key] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {
    for (final key in keys) {
      _storage.remove(key);
    }
  }

  @override
  Future<int> clear() async {
    final count = _storage.length;
    _storage.clear();
    return count;
  }

  @override
  bool containsKey(dynamic key) => _storage.containsKey(key);

  @override
  Stream<BoxEvent> watch({dynamic key}) => const Stream.empty();

  @override
  Map<dynamic, ConversationMessage> toMap() => Map.from(_storage);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestConversationRepository extends ConversationRepository {
  final _FakeConversationBox _fakeBox;

  _TestConversationRepository(this._fakeBox);

  @override
  Future<Result<void>> deleteSessionMessages(String sessionId) async {
    final toDelete = _fakeBox.toMap().entries
        .where((e) => e.value.sessionId == sessionId)
        .map((e) => e.key)
        .toList();
    await box.deleteAll(toDelete);
    return Result.success(null);
  }
}

class _ErrorFakeConversationBox implements Box<ConversationMessage> {
  final Map<dynamic, ConversationMessage> _storage = {};
  bool throwOnPut = false;
  bool throwOnGet = false;
  bool throwOnDelete = false;
  bool throwOnValues = false;
  bool throwOnClear = false;
  bool throwOnDeleteAll = false;

  @override
  Iterable<ConversationMessage> get values {
    if (throwOnValues) throw Exception('values error');
    return _storage.values;
  }

  @override
  int get length => _storage.length;

  @override
  bool get isEmpty => _storage.isEmpty;

  @override
  bool get isNotEmpty => _storage.isNotEmpty;

  @override
  bool get isOpen => true;

  @override
  String get name => 'conversations_error';

  @override
  ConversationMessage? get(dynamic key, {ConversationMessage? defaultValue}) {
    if (throwOnGet) throw Exception('get error');
    return _storage[key] ?? defaultValue;
  }

  @override
  Future<void> put(dynamic key, ConversationMessage value) async {
    if (throwOnPut) throw Exception('put error');
    _storage[key] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    if (throwOnDelete) throw Exception('delete error');
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {
    if (throwOnDeleteAll) throw Exception('deleteAll error');
    for (final key in keys) {
      _storage.remove(key);
    }
  }

  @override
  Future<int> clear() async {
    if (throwOnClear) throw Exception('clear error');
    final count = _storage.length;
    _storage.clear();
    return count;
  }

  @override
  bool containsKey(dynamic key) => _storage.containsKey(key);

  @override
  Stream<BoxEvent> watch({dynamic key}) => const Stream.empty();

  @override
  Map<dynamic, ConversationMessage> toMap() => Map.from(_storage);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ConversationRepository (attached to fake box)', () {
    late _FakeConversationBox fakeBox;
    late ConversationRepository repository;
    final now = DateTime(2025, 1, 15, 10, 0, 0);

    setUp(() {
      fakeBox = _FakeConversationBox();
      repository = ConversationRepository();
      repository.attachBox(fakeBox);
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

    group('create', () {
      test('stores a message via create alias', () async {
        final msg = createMessage();
        final result = await repository.create(msg);
        expect(result.isSuccess, true);
        expect((await repository.getMessage('msg-1')).data?.content, 'Hello');
      });

      test('create is equivalent to saveMessage', () async {
        final msg = createMessage();
        final createResult = await repository.create(msg);
        final saveResult = await repository.saveMessage(createMessage(id: 'msg-2'));
        expect(createResult.isSuccess, true);
        expect(saveResult.isSuccess, true);
      });
    });

    group('saveMessage', () {
      test('stores a message', () async {
        final msg = createMessage();
        final result = await repository.saveMessage(msg);
        expect(result.isSuccess, true);
        expect((await repository.getMessage('msg-1')).data?.content, 'Hello');
      });

      test('overwrites existing message with same id', () async {
        final msg1 = createMessage(content: 'First');
        final msg2 = createMessage(content: 'Second');
        await repository.saveMessage(msg1);
        await repository.saveMessage(msg2);
        expect((await repository.getMessage('msg-1')).data?.content, 'Second');
      });

      test('returns Result<void> type', () async {
        final msg = createMessage();
        final result = await repository.saveMessage(msg);
        expect(result, isA<SuccessResult<void>>());
      });
    });

    group('getMessage', () {
      test('returns Result with null data for non-existent message', () async {
        final result = await repository.getMessage('none');
        expect(result, isA<SuccessResult<ConversationMessage?>>());
        expect(result.data, isNull);
      });

      test('returns stored message with Result type', () async {
        final msg = createMessage();
        await repository.saveMessage(msg);
        final result = await repository.getMessage('msg-1');
        expect(result.isSuccess, true);
        expect(result.data, isNotNull);
        expect(result.data!.id, 'msg-1');
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
        final messagesResult = await repository.getSessionMessages('s1');
        expect(messagesResult.isSuccess, true);
        final messages = messagesResult.data!;
        expect(messages.length, 3);
        expect(messages[0].content, 'First');
        expect(messages[1].content, 'Second');
        expect(messages[2].content, 'Third');
      });

      test('filters by session id', () async {
        await repository.saveMessage(createMessage(id: 'm1', sessionId: 's1'));
        await repository.saveMessage(createMessage(id: 'm2', sessionId: 's2'));
        expect((await repository.getSessionMessages('s1')).data!.length, 1);
        expect((await repository.getSessionMessages('s2')).data!.length, 1);
      });

      test('returns empty list for session with no messages', () async {
        expect((await repository.getSessionMessages('empty')).data, isEmpty);
      });

      test('returns Result wrapping the list', () async {
        final result = await repository.getSessionMessages('empty');
        expect(result, isA<SuccessResult<List<ConversationMessage>>>());
        expect(result.data, isEmpty);
      });
    });

    group('deleteMessage', () {
      test('deletes a single message', () async {
        final msg = createMessage();
        await repository.saveMessage(msg);
        final deleteResult = await repository.deleteMessage('msg-1');
        expect(deleteResult.isSuccess, true);
        expect((await repository.getMessage('msg-1')).data, isNull);
      });

      test('does nothing for non-existent message', () async {
        final result = await repository.deleteMessage('non-existent');
        expect(result.isSuccess, true);
      });

      test('returns Result<void> type', () async {
        final result = await repository.deleteMessage('non-existent');
        expect(result, isA<SuccessResult<void>>());
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
        final recentResult = await repository.getRecentMessages(limit: 5);
        expect(recentResult.isSuccess, true);
        final recent = recentResult.data!;
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
        final recentResult = await repository.getRecentMessages(limit: 10, sessionId: 's1');
        expect(recentResult.isSuccess, true);
        final recent = recentResult.data!;
        expect(recent.length, 5);
        for (final msg in recent) {
          expect(msg.sessionId, 's1');
        }
      });

      test('returns all when fewer than limit', () async {
        await repository.saveMessage(createMessage(id: 'm1'));
        await repository.saveMessage(createMessage(id: 'm2'));
        final recentResult = await repository.getRecentMessages(limit: 10);
        expect(recentResult.isSuccess, true);
        final recent = recentResult.data!;
        expect(recent.length, 2);
      });

      test('returns empty when no messages', () async {
        expect((await repository.getRecentMessages()).data, isEmpty);
      });

      test('sorts most recent first within sessionId filter', () async {
        await repository.saveMessage(createMessage(
          id: 'm1', sessionId: 's1', content: 'Old',
          timestamp: now.subtract(const Duration(hours: 2)),
        ));
        await repository.saveMessage(createMessage(
          id: 'm2', sessionId: 's1', content: 'New',
          timestamp: now,
        ));
        final recentResult = await repository.getRecentMessages(limit: 10, sessionId: 's1');
        expect(recentResult.isSuccess, true);
        final recent = recentResult.data!;
        expect(recent.length, 2);
        expect(recent[0].content, 'New');
        expect(recent[1].content, 'Old');
      });

      test('returns empty for limit of 0', () async {
        await repository.saveMessage(createMessage(id: 'm1'));
        final result = await repository.getRecentMessages(limit: 0);
        expect(result.isSuccess, true);
        expect(result.data, isEmpty);
      });

      test('returns empty for sessionId with no matches', () async {
        await repository.saveMessage(createMessage(id: 'm1', sessionId: 's1'));
        final result = await repository.getRecentMessages(limit: 10, sessionId: 'nonexistent');
        expect(result.isSuccess, true);
        expect(result.data, isEmpty);
      });
    });

    group('clearAll', () {
      test('removes all messages', () async {
        await repository.saveMessage(createMessage(id: 'm1'));
        await repository.saveMessage(createMessage(id: 'm2'));
        final result = await repository.clearAll();
        expect(result.isSuccess, true);
        expect((await repository.getMessage('m1')).data, isNull);
        expect((await repository.getMessage('m2')).data, isNull);
      });

      test('works on empty repository', () async {
        final result = await repository.clearAll();
        expect(result.isSuccess, true);
        expect((await repository.getRecentMessages()).data, isEmpty);
      });
    });

    group('deleteSessionMessages', () {
      late _TestConversationRepository testRepo;

      setUp(() {
        testRepo = _TestConversationRepository(fakeBox);
        testRepo.attachBox(fakeBox);
      });

      test('deletes all messages for a session', () async {
        await testRepo.saveMessage(createMessage(id: 'm1', sessionId: 's1'));
        await testRepo.saveMessage(createMessage(id: 'm2', sessionId: 's1'));
        await testRepo.saveMessage(createMessage(id: 'm3', sessionId: 's2'));
        final result = await testRepo.deleteSessionMessages('s1');
        expect(result.isSuccess, true);
        expect((await testRepo.getMessage('m1')).data, isNull);
        expect((await testRepo.getMessage('m2')).data, isNull);
        expect((await testRepo.getMessage('m3')).data, isNotNull);
      });

      test('does nothing for non-existent session', () async {
        await testRepo.saveMessage(createMessage(id: 'm1', sessionId: 's1'));
        final result = await testRepo.deleteSessionMessages('non-existent');
        expect(result.isSuccess, true);
        expect((await testRepo.getMessage('m1')).data, isNotNull);
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
    });

    test('init can be called multiple times without error', () async {
      await hiveRepo.init();
      await hiveRepo.init();
    });

    group('CRUD operations', () {
      test('saves and retrieves a message', () async {
        final msg = hiveMsg();
        final saveResult = await hiveRepo.saveMessage(msg);
        expect(saveResult.isSuccess, true);
        final retrieved = await hiveRepo.getMessage('msg-1');
        expect(retrieved, isNotNull);
        expect(retrieved.data!.content, 'Hello');
        expect(retrieved.data!.role, MessageRole.tutor);
        expect(retrieved.data!.type, MessageType.text);
      });

      test('getMessage returns Result with null data for non-existent id', () async {
        final result = await hiveRepo.getMessage('non-existent');
        expect(result, isA<SuccessResult<ConversationMessage?>>());
        expect(result.data, isNull);
      });

      test('saveMessage overwrites existing message with same id', () async {
        final msg1 = hiveMsg(content: 'First');
        final msg2 = hiveMsg(content: 'Second');
        await hiveRepo.saveMessage(msg1);
        await hiveRepo.saveMessage(msg2);
        expect((await hiveRepo.getMessage('msg-1')).data?.content, 'Second');
      });

      test('create alias stores a message', () async {
        final msg = hiveMsg(id: 'create-msg');
        final result = await hiveRepo.create(msg);
        expect(result.isSuccess, true);
        expect((await hiveRepo.getMessage('create-msg')).data?.content, 'Hello');
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
        final messagesResult = await hiveRepo.getSessionMessages('s1');
        expect(messagesResult.isSuccess, true);
        final messages = messagesResult.data!;
        expect(messages.length, 3);
        expect(messages[0].content, 'First');
        expect(messages[1].content, 'Second');
        expect(messages[2].content, 'Third');
      });

      test('filters by session id', () async {
        await hiveRepo.saveMessage(hiveMsg(id: 'm1', sessionId: 's1'));
        await hiveRepo.saveMessage(hiveMsg(id: 'm2', sessionId: 's2'));
        expect((await hiveRepo.getSessionMessages('s1')).data!.length, 1);
        expect((await hiveRepo.getSessionMessages('s2')).data!.length, 1);
      });

      test('returns empty list for session with no messages', () async {
        expect((await hiveRepo.getSessionMessages('empty')).data, isEmpty);
      });
    });

    group('deleteSessionMessages', () {
      test('deletes all messages for a session', () async {
        await hiveRepo.saveMessage(hiveMsg(id: 'm1', sessionId: 's1'));
        await hiveRepo.saveMessage(hiveMsg(id: 'm2', sessionId: 's1'));
        await hiveRepo.saveMessage(hiveMsg(id: 'm3', sessionId: 's2'));
        final result = await hiveRepo.deleteSessionMessages('s1');
        expect(result.isSuccess, true);
        expect((await hiveRepo.getMessage('m1')).data, isNull);
        expect((await hiveRepo.getMessage('m2')).data, isNull);
        expect((await hiveRepo.getMessage('m3')).data, isNotNull);
      });

      test('does nothing for non-existent session', () async {
        await hiveRepo.saveMessage(hiveMsg(id: 'm1', sessionId: 's1'));
        final result = await hiveRepo.deleteSessionMessages('non-existent');
        expect(result.isSuccess, true);
        expect((await hiveRepo.getMessage('m1')).data, isNotNull);
      });
    });

    group('deleteMessage', () {
      test('deletes a single message', () async {
        await hiveRepo.saveMessage(hiveMsg());
        final result = await hiveRepo.deleteMessage('msg-1');
        expect(result.isSuccess, true);
        expect((await hiveRepo.getMessage('msg-1')).data, isNull);
      });

      test('does nothing for non-existent message', () async {
        final result = await hiveRepo.deleteMessage('non-existent');
        expect(result.isSuccess, true);
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
        final recentResult = await hiveRepo.getRecentMessages(limit: 5);
        expect(recentResult.isSuccess, true);
        final recent = recentResult.data!;
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
        final recentResult = await hiveRepo.getRecentMessages(limit: 10, sessionId: 's1');
        expect(recentResult.isSuccess, true);
        final recent = recentResult.data!;
        expect(recent.length, 5);
        for (final msg in recent) {
          expect(msg.sessionId, 's1');
        }
      });

      test('returns all when fewer than limit', () async {
        await hiveRepo.saveMessage(hiveMsg(id: 'm1'));
        await hiveRepo.saveMessage(hiveMsg(id: 'm2'));
        final recentResult = await hiveRepo.getRecentMessages(limit: 10);
        expect(recentResult.isSuccess, true);
        final recent = recentResult.data!;
        expect(recent.length, 2);
      });

      test('returns empty when no messages', () async {
        expect((await hiveRepo.getRecentMessages()).data, isEmpty);
      });

      test('returns empty for limit of 0', () async {
        await hiveRepo.saveMessage(hiveMsg(id: 'm1'));
        final result = await hiveRepo.getRecentMessages(limit: 0);
        expect(result.isSuccess, true);
        expect(result.data, isEmpty);
      });
    });

    group('clearAll', () {
      test('removes all messages', () async {
        await hiveRepo.saveMessage(hiveMsg(id: 'm1'));
        await hiveRepo.saveMessage(hiveMsg(id: 'm2'));
        final result = await hiveRepo.clearAll();
        expect(result.isSuccess, true);
        expect((await hiveRepo.getMessage('m1')).data, isNull);
        expect((await hiveRepo.getMessage('m2')).data, isNull);
      });

      test('works on empty repository', () async {
        final result = await hiveRepo.clearAll();
        expect(result.isSuccess, true);
        expect((await hiveRepo.getRecentMessages()).data, isEmpty);
      });
    });
  });

  group('ConversationRepository error handling', () {
    late _ErrorFakeConversationBox errorBox;
    late ConversationRepository repository;

    setUp(() {
      errorBox = _ErrorFakeConversationBox();
      repository = ConversationRepository();
      repository.attachBox(errorBox);
    });

    group('saveMessage', () {
      test('returns failure when box.put throws', () async {
        errorBox.throwOnPut = true;
        final msg = ConversationMessage(
          id: 'msg-1',
          sessionId: 's1',
          role: MessageRole.tutor,
          type: MessageType.text,
          content: 'Hello',
          timestamp: DateTime(2025, 1, 15),
        );
        final result = await repository.saveMessage(msg);
        expect(result.isFailure, true);
        expect(result.error, contains('Failed to put'));
      });
    });

    group('create', () {
      test('returns failure when box.put throws', () async {
        errorBox.throwOnPut = true;
        final msg = ConversationMessage(
          id: 'msg-1',
          sessionId: 's1',
          role: MessageRole.tutor,
          type: MessageType.text,
          content: 'Hello',
          timestamp: DateTime(2025, 1, 15),
        );
        final result = await repository.create(msg);
        expect(result.isFailure, true);
        expect(result.error, contains('Failed to put'));
      });
    });

    group('getMessage', () {
      test('returns failure when box.get throws', () async {
        errorBox.throwOnGet = true;
        final result = await repository.getMessage('any');
        expect(result.isFailure, true);
        expect(result.error, contains('Failed to get'));
      });
    });

    group('deleteMessage', () {
      test('returns failure when box.delete throws', () async {
        errorBox.throwOnDelete = true;
        final result = await repository.deleteMessage('any');
        expect(result.isFailure, true);
        expect(result.error, contains('Failed to delete'));
      });
    });

    group('getSessionMessages', () {
      test('returns failure when box.values throws', () async {
        errorBox.throwOnValues = true;
        final result = await repository.getSessionMessages('s1');
        expect(result.isFailure, true);
      });
    });

    group('getRecentMessages', () {
      test('returns failure when box.values throws', () async {
        errorBox.throwOnValues = true;
        final result = await repository.getRecentMessages();
        expect(result.isFailure, true);
      });

      test('returns failure when box.values throws with sessionId filter', () async {
        errorBox.throwOnValues = true;
        final result = await repository.getRecentMessages(sessionId: 's1');
        expect(result.isFailure, true);
      });
    });

    group('deleteSessionMessages', () {
      test('returns failure when box.deleteAll throws', () async {
        errorBox.throwOnDeleteAll = true;
        final result = await repository.deleteSessionMessages('s1');
        expect(result.isFailure, true);
      });
    });

    group('clearAll', () {
      test('returns failure when box.clear throws', () async {
        errorBox.throwOnClear = true;
        final result = await repository.clearAll();
        expect(result.isFailure, true);
      });
    });
  });
}
