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

    group('summarization', () {
      test('compresses old messages when summarizer is provided', () async {
        final summaries = <List<ConversationMessage>>[];
        final summarizer = (List<ConversationMessage> msgs) async {
          summaries.add(msgs);
          return 'Summary of ${msgs.length} messages';
        };

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
        final summarizer = (List<ConversationMessage> msgs) async {
          throw Exception('LLM unavailable');
        };

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
        final summarizer = (List<ConversationMessage> msgs) async => null;

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
        final summarizer = (List<ConversationMessage> msgs) async {
          return 'Compressed summary';
        };

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
        final summarizer = (List<ConversationMessage> msgs) async {
          callCount++;
          if (callCount == 1) {
            return null;
          }
          return 'Summary of ${msgs.length} dropped messages';
        };

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
        final summarizer = (List<ConversationMessage> msgs) async => null;

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

        final summarizer = (List<ConversationMessage> msgs) async {
          summaries.add(msgs);
          return 'Summary of ${msgs.length} messages';
        };

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
