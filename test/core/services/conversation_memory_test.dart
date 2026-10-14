import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/conversation_memory.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';

class _FakeConversationRepository extends ConversationRepository {
  final List<ConversationMessage> _saved = [];
  List<ConversationMessage>? getSessionMessagesResult;

  @override
  Future<Result<void>> saveMessage(ConversationMessage msg) async {
    _saved.add(msg);
    return Result.success(null);
  }

  @override
  Future<Result<List<ConversationMessage>>> getSessionMessages(String sessionId) async {
    return Result.success(getSessionMessagesResult ?? []);
  }
}

class _FailingConversationRepository extends ConversationRepository {
  final List<ConversationMessage> saveAttempts = [];

  @override
  Future<Result<void>> saveMessage(ConversationMessage msg) async {
    saveAttempts.add(msg);
    return Result.failure('Hive box not open');
  }

  @override
  Future<Result<List<ConversationMessage>>> getSessionMessages(String sessionId) async {
    return Result.success([]);
  }
}

/// Hand-written fake that mimics Hive's `put` semantics: saving a message
/// under an id that already exists overwrites the previous message, so
/// colliding ids silently lose the earlier message.
class _HiveConversationRepository extends ConversationRepository {
  final Map<String, ConversationMessage> _store = {};

  @override
  Future<Result<void>> saveMessage(ConversationMessage msg) async {
    _store[msg.id] = msg;
    return Result.success(null);
  }

  @override
  Future<Result<List<ConversationMessage>>> getSessionMessages(String sessionId) async {
    final stored = _store.values
        .where((m) => m.sessionId == sessionId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return Result.success(stored);
  }

  int get storedMessageCount => _store.length;
}

void main() {
  group('ConversationMemory', () {
    test('starts with empty messages', () {
      final memory = ConversationMemory();
      expect(memory.messages, isEmpty);
      expect(memory.getHistory(), isEmpty);
    });

    test('addUserMessage adds message with student role', () async {
      final memory = ConversationMemory();
      await memory.addUserMessage('Hello');
      expect(memory.messages, hasLength(1));
      expect(memory.messages.first.role, equals(MessageRole.student));
      expect(memory.messages.first.content, equals('Hello'));
    });

    test('addAssistantMessage adds message with tutor role', () async {
      final memory = ConversationMemory();
      await memory.addAssistantMessage('Hi there');
      expect(memory.messages, hasLength(1));
      expect(memory.messages.first.role, equals(MessageRole.tutor));
      expect(memory.messages.first.content, equals('Hi there'));
    });

    test('addSystemMessage adds message with system role', () async {
      final memory = ConversationMemory();
      await memory.addSystemMessage('System instruction');
      expect(memory.messages, hasLength(1));
      expect(memory.messages.first.role, equals(MessageRole.system));
      expect(memory.messages.first.content, equals('System instruction'));
    });

    test('addMessage with user role maps to student', () async {
      final memory = ConversationMemory();
      await memory.addMessage('user', 'user text');
      expect(memory.messages.first.role, equals(MessageRole.student));
    });

    test('addMessage with unknown role maps to student', () async {
      final memory = ConversationMemory();
      await memory.addMessage('unknown', 'text');
      expect(memory.messages.first.role, equals(MessageRole.student));
    });

    test('getHistory returns a copy of messages', () async {
      final memory = ConversationMemory();
      await memory.addUserMessage('test');
      final history = memory.getHistory();
      expect(history, hasLength(1));
      history.clear();
      expect(memory.messages, hasLength(1));
    });

    test('clear removes all messages', () async {
      final memory = ConversationMemory();
      await memory.addUserMessage('a');
      await memory.addAssistantMessage('b');
      memory.clear();
      expect(memory.messages, isEmpty);
    });

    test('respects maxTurns and trims older messages', () async {
      final memory = ConversationMemory(maxTurns: 2);
      await memory.addUserMessage('msg1');
      await memory.addAssistantMessage('resp1');
      await memory.addUserMessage('msg2');
      await memory.addAssistantMessage('resp2');
      await memory.addUserMessage('msg3');
      expect(memory.messages.length, equals(5));
      expect(memory.messages.first.content, equals('resp1'));
      expect(memory.messages.last.content, contains('trimmed'));
    });

    test('does not trim when under maxTurns', () async {
      final memory = ConversationMemory(maxTurns: 5);
      await memory.addUserMessage('a');
      await memory.addAssistantMessage('b');
      expect(memory.messages, hasLength(2));
    });

    test('getRecent returns last N turns', () async {
      final memory = ConversationMemory();
      await memory.addUserMessage('1');
      await memory.addAssistantMessage('r1');
      await memory.addUserMessage('2');
      await memory.addAssistantMessage('r2');
      await memory.addUserMessage('3');

      final recent = memory.getRecent(turns: 1);
      expect(recent, hasLength(2));
      expect(recent.first.content, equals('r2'));
    });

    test('getRecent returns all when less than requested', () async {
      final memory = ConversationMemory();
      await memory.addUserMessage('only');
      final recent = memory.getRecent(turns: 10);
      expect(recent, hasLength(1));
    });

    test('fromConversationMessages converts to list of maps', () {
      final messages = [
        ConversationMessage(
          id: '1',
          sessionId: 's1',
          role: MessageRole.student,
          type: MessageType.text,
          content: 'Hello',
          timestamp: DateTime.now(),
        ),
        ConversationMessage(
          id: '2',
          sessionId: 's1',
          role: MessageRole.tutor,
          type: MessageType.text,
          content: 'Hi',
          timestamp: DateTime.now(),
        ),
        ConversationMessage(
          id: '3',
          sessionId: 's1',
          role: MessageRole.system,
          type: MessageType.text,
          content: 'sys',
          isStreaming: true,
          timestamp: DateTime.now(),
        ),
      ];

      final result = ConversationMemory.fromConversationMessages(messages);
      expect(result, hasLength(2));
      expect(result[0]['role'], equals('user'));
      expect(result[1]['role'], equals('assistant'));
    });

    test('fromConversationMessages maps mentor role to assistant', () {
      final messages = [
        ConversationMessage(
          id: '1',
          sessionId: 's1',
          role: MessageRole.mentor,
          type: MessageType.text,
          content: 'mentor msg',
          timestamp: DateTime.now(),
        ),
      ];
      final result = ConversationMemory.fromConversationMessages(messages);
      expect(result.first['role'], equals('assistant'));
    });

    test('getHistory returns messages in order', () async {
      final memory = ConversationMemory();
      await memory.addUserMessage('first');
      await memory.addAssistantMessage('second');
      final history = memory.getHistory();
      expect(history[0].content, equals('first'));
      expect(history[1].content, equals('second'));
    });

    group('with sessionId and repository', () {
      test('generates id using sessionId prefix', () async {
        final memory = ConversationMemory(sessionId: 'abc123');
        await memory.addUserMessage('test');
        expect(memory.messages.first.id, startsWith('abc123_'));
      });

      test('generates id with mem prefix when no sessionId', () async {
        final memory = ConversationMemory();
        await memory.addUserMessage('test');
        expect(memory.messages.first.id, startsWith('mem_'));
      });

      test('persists message via repository', () async {
        final repo = _FakeConversationRepository();
        final memory = ConversationMemory(
          sessionId: 'sess1',
          repository: repo,
        );
        await memory.addUserMessage('persist me');
        expect(repo._saved, hasLength(1));
        expect(repo._saved.first.content, equals('persist me'));
      });

      test('does not persist when repository is null', () async {
        final memory = ConversationMemory(sessionId: 'sess1');
        await memory.addUserMessage('no persist');
      });

      test('persists summary message via repository', () async {
        final repo = _FakeConversationRepository();
        final summaries = <List<ConversationMessage>>[];
        Future<String?> summarizer(List<ConversationMessage> msgs) async {
          summaries.add(msgs);
          return 'Summary of ${msgs.length} messages';
        }

        final memory = ConversationMemory(
          maxTurns: 5,
          repository: repo,
          summarizer: summarizer,
        );

        for (var i = 0; i < 12; i++) {
          await memory.addUserMessage('msg$i');
        }

        expect(summaries, isNotEmpty);
        expect(
          repo._saved.any((m) => m.content.contains('[Earlier conversation summary]')),
          isTrue,
        );
      });
    });

    group('persistence failure handling', () {
      final originalDebugPrint = debugPrint;
      final logs = <String>[];

      setUp(() {
        logs.clear();
        debugPrint = (String? message, {int? wrapWidth}) {
          logs.add(message ?? '');
        };
      });

      tearDown(() {
        debugPrint = originalDebugPrint;
      });

      test('logs a warning when repository save fails', () async {
        final repo = _FailingConversationRepository();
        final memory = ConversationMemory(
          sessionId: 'sess1',
          repository: repo,
        );

        final result = await memory.addUserMessage('persist me');

        expect(result.isSuccess, isTrue);
        expect(repo.saveAttempts, hasLength(1));
        expect(repo.saveAttempts.first.content, equals('persist me'));
        expect(
          logs.join('\n'),
          contains('Failed to persist conversation message'),
        );
      });

      test('keeps the message in memory when persistence fails', () async {
        final repo = _FailingConversationRepository();
        final memory = ConversationMemory(
          sessionId: 'sess1',
          repository: repo,
        );

        await memory.addUserMessage('still in memory');

        expect(memory.messages, hasLength(1));
        expect(memory.messages.first.content, equals('still in memory'));
      });

      test('does not log a persistence warning when save succeeds', () async {
        final repo = _FakeConversationRepository();
        final memory = ConversationMemory(
          sessionId: 'sess1',
          repository: repo,
        );

        await memory.addUserMessage('saved fine');

        expect(repo._saved, hasLength(1));
        expect(
          logs.where((l) => l.contains('Failed to persist')),
          isEmpty,
        );
      });
    });

    group('loadFromRepository', () {
      test('loads messages from repository', () async {
        final repo = _FakeConversationRepository();
        repo.getSessionMessagesResult = [
          ConversationMessage(
            id: 'm1',
            sessionId: 'sess1',
            role: MessageRole.student,
            type: MessageType.text,
            content: 'Hello',
            timestamp: DateTime.now(),
          ),
          ConversationMessage(
            id: 'm2',
            sessionId: 'sess1',
            role: MessageRole.tutor,
            type: MessageType.text,
            content: 'Hi there',
            timestamp: DateTime.now(),
          ),
        ];

        final memory = ConversationMemory(
          sessionId: 'sess1',
          repository: repo,
        );
        await memory.loadFromRepository();

        expect(memory.messages, hasLength(2));
        expect(memory.messages.first.content, equals('Hello'));
        expect(memory.messages.last.content, equals('Hi there'));
      });

      test('clears existing messages before loading', () async {
        final repo = _FakeConversationRepository();
        repo.getSessionMessagesResult = [
          ConversationMessage(
            id: 'm1',
            sessionId: 'sess1',
            role: MessageRole.student,
            type: MessageType.text,
            content: 'From repo',
            timestamp: DateTime.now(),
          ),
        ];

        final memory = ConversationMemory(
          sessionId: 'sess1',
          repository: repo,
        );
        await memory.addUserMessage('temp message');
        expect(memory.messages, hasLength(1));

        await memory.loadFromRepository();

        expect(memory.messages, hasLength(1));
        expect(memory.messages.first.content, equals('From repo'));
      });

      test('does nothing when sessionId is null', () async {
        final repo = _FakeConversationRepository();
        final memory = ConversationMemory(repository: repo);
        await memory.loadFromRepository();
        expect(memory.messages, isEmpty);
      });

      test('does nothing when repository is null', () async {
        final memory = ConversationMemory(sessionId: 'sess1');
        await memory.loadFromRepository();
        expect(memory.messages, isEmpty);
      });
    });

    group('message id uniqueness', () {
      test('rapidly added messages get unique ids', () async {
        final memory = ConversationMemory(
          sessionId: 'sess1',
          maxTurns: 500,
        );
        for (var i = 0; i < 500; i++) {
          await memory.addAssistantMessage('msg$i');
        }
        final ids = memory.messages.map((m) => m.id).toList();
        expect(ids.toSet().length, ids.length);
      });

      test('same-millisecond messages all persist and reload', () async {
        final repo = _HiveConversationRepository();
        final memory = ConversationMemory(
          sessionId: 'sess1',
          repository: repo,
          maxTurns: 500,
        );
        // A tight loop makes several messages land in the same
        // millisecond. Without a uniqueness component in the id, the
        // earlier ones are overwritten under the same Hive key and are
        // gone after a reload.
        for (var i = 0; i < 500; i++) {
          await memory.addAssistantMessage('msg$i');
        }
        expect(repo.storedMessageCount, 500);

        await memory.loadFromRepository();
        expect(memory.messages, hasLength(500));
      });
    });

    group('summarization', () {
      test('compresses old messages when summarizer is provided', () async {
        final summaries = <List<ConversationMessage>>[];
        Future<String?> summarizer(List<ConversationMessage> msgs) async {
          summaries.add(msgs);
          return 'Summary of ${msgs.length} messages';
        }

        final memory = ConversationMemory(
          maxTurns: 10,
          summarizer: summarizer,
        );

        for (var i = 0; i < 16; i++) {
          await memory.addUserMessage('msg$i');
        }

        expect(summaries, isNotEmpty);
        expect(
          memory.messages.first.content,
          contains('Summary of'),
        );
        expect(
          memory.messages.first.content,
          contains('[Earlier conversation summary]'),
        );
      });

      test('skips compression when no summarizer provided', () async {
        final memory = ConversationMemory(maxTurns: 10);
        for (var i = 0; i < 20; i++) {
          await memory.addUserMessage('msg$i');
        }

        expect(
          memory.messages.any((m) => m.content.contains('Summary')),
          isFalse,
        );
      });

      test('compression fails gracefully on summarizer error', () async {
        Future<String?> summarizer(List<ConversationMessage> msgs) async {
          throw Exception('LLM unavailable');
        }

        final memory = ConversationMemory(
          maxTurns: 10,
          summarizer: summarizer,
        );

        for (var i = 0; i < 20; i++) {
          await memory.addUserMessage('msg$i');
        }

        expect(
          memory.messages.any((m) => m.content.contains('Summary')),
          isFalse,
        );
      });

      test('compression fails gracefully when summarizer returns null', () async {
        Future<String?> summarizer(List<ConversationMessage> msgs) async => null;

        final memory = ConversationMemory(
          maxTurns: 10,
          summarizer: summarizer,
        );

        for (var i = 0; i < 20; i++) {
          await memory.addUserMessage('msg$i');
        }

        expect(
          memory.messages.any((m) => m.content.contains('Summary')),
          isFalse,
        );
      });

      test('preserves recent messages after compression', () async {
        Future<String?> summarizer(List<ConversationMessage> msgs) async {
          return 'Compressed summary';
        }

        final memory = ConversationMemory(
          maxTurns: 10,
          summarizer: summarizer,
        );

        for (var i = 0; i < 16; i++) {
          await memory.addUserMessage('msg$i');
        }

        final recentContents = memory.messages
            .where((m) => m.role == MessageRole.student)
            .map((m) => m.content)
            .toList();

        expect(recentContents, contains('msg15'));
        expect(recentContents, contains('msg14'));
      });

      test('drop summarization preserves semantic content when compression fails', () async {
        var callCount = 0;
        Future<String?> summarizer(List<ConversationMessage> msgs) async {
          callCount++;
          if (callCount == 1) {
            return null;
          }
          return 'Summary of ${msgs.length} dropped messages';
        }

        final memory = ConversationMemory(
          maxTurns: 10,
          summarizer: summarizer,
        );

        for (var i = 0; i < 22; i++) {
          await memory.addUserMessage('msg$i');
        }

        expect(
          memory.messages.any((m) => m.content.contains('Summary of')),
          isTrue,
        );
        expect(
          memory.messages.any((m) => m.content.contains('[Earlier conversation summary]')),
          isTrue,
        );
      });

      test('drop summarization falls back to truncation when summarizer returns null on drop', () async {
        Future<String?> summarizer(List<ConversationMessage> msgs) async => null;

        final memory = ConversationMemory(
          maxTurns: 10,
          summarizer: summarizer,
        );

        for (var i = 0; i < 22; i++) {
          await memory.addUserMessage('msg$i');
        }

        expect(
          memory.messages.any((m) => m.content.contains('trimmed')),
          isTrue,
        );
      });

      test('compression runs before hard-limit drop', () async {
        final summaries = <List<ConversationMessage>>[];

        Future<String?> summarizer(List<ConversationMessage> msgs) async {
          summaries.add(msgs);
          return 'Summary of ${msgs.length} messages';
        }

        final memory = ConversationMemory(
          maxTurns: 10,
          summarizer: summarizer,
        );

        for (var i = 0; i < 20; i++) {
          await memory.addUserMessage('msg$i');
        }

        expect(summaries, isNotEmpty);
        expect(
          memory.messages.first.content,
          contains('[Earlier conversation summary]'),
        );
        expect(
          memory.messages.length,
          lessThanOrEqualTo(20),
        );
      });
    });
  });
}
