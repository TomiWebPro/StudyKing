import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/conversation_memory.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';

class _FakeConversationRepository extends ConversationRepository {
  final List<ConversationMessage> _saved = [];
  List<ConversationMessage>? getSessionMessagesResult;

  @override
  Future<void> saveMessage(ConversationMessage msg) async {
    _saved.add(msg);
  }

  @override
  Future<List<ConversationMessage>> getSessionMessages(String sessionId) async {
    return getSessionMessagesResult ?? [];
  }
}

void main() {
  group('ConversationMemory', () {
    test('starts with empty messages', () {
      final memory = ConversationMemory();
      expect(memory.messages, isEmpty);
      expect(memory.getHistory(), isEmpty);
    });

    test('addUserMessage adds message with student role', () {
      final memory = ConversationMemory();
      memory.addUserMessage('Hello');
      expect(memory.messages, hasLength(1));
      expect(memory.messages.first.role, equals(MessageRole.student));
      expect(memory.messages.first.content, equals('Hello'));
    });

    test('addAssistantMessage adds message with tutor role', () {
      final memory = ConversationMemory();
      memory.addAssistantMessage('Hi there');
      expect(memory.messages, hasLength(1));
      expect(memory.messages.first.role, equals(MessageRole.tutor));
      expect(memory.messages.first.content, equals('Hi there'));
    });

    test('addSystemMessage adds message with system role', () {
      final memory = ConversationMemory();
      memory.addSystemMessage('System instruction');
      expect(memory.messages, hasLength(1));
      expect(memory.messages.first.role, equals(MessageRole.system));
      expect(memory.messages.first.content, equals('System instruction'));
    });

    test('addMessage with user role maps to student', () {
      final memory = ConversationMemory();
      memory.addMessage('user', 'user text');
      expect(memory.messages.first.role, equals(MessageRole.student));
    });

    test('addMessage with unknown role maps to student', () {
      final memory = ConversationMemory();
      memory.addMessage('unknown', 'text');
      expect(memory.messages.first.role, equals(MessageRole.student));
    });

    test('getHistory returns a copy of messages', () {
      final memory = ConversationMemory();
      memory.addUserMessage('test');
      final history = memory.getHistory();
      expect(history, hasLength(1));
      history.clear();
      expect(memory.messages, hasLength(1));
    });

    test('clear removes all messages', () {
      final memory = ConversationMemory();
      memory.addUserMessage('a');
      memory.addAssistantMessage('b');
      memory.clear();
      expect(memory.messages, isEmpty);
    });

    test('respects maxTurns and trims older messages', () {
      final memory = ConversationMemory(maxTurns: 2);
      memory.addUserMessage('msg1');
      memory.addAssistantMessage('resp1');
      memory.addUserMessage('msg2');
      memory.addAssistantMessage('resp2');
      memory.addUserMessage('msg3');
      expect(memory.messages.length, equals(4));
      expect(memory.messages.first.content, equals('resp1'));
    });

    test('does not trim when under maxTurns', () {
      final memory = ConversationMemory(maxTurns: 5);
      memory.addUserMessage('a');
      memory.addAssistantMessage('b');
      expect(memory.messages, hasLength(2));
    });

    test('getRecent returns last N turns', () {
      final memory = ConversationMemory();
      memory.addUserMessage('1');
      memory.addAssistantMessage('r1');
      memory.addUserMessage('2');
      memory.addAssistantMessage('r2');
      memory.addUserMessage('3');

      final recent = memory.getRecent(turns: 1);
      expect(recent, hasLength(2));
      expect(recent.first.content, equals('r2'));
    });

    test('getRecent returns all when less than requested', () {
      final memory = ConversationMemory();
      memory.addUserMessage('only');
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

    test('getHistory returns messages in order', () {
      final memory = ConversationMemory();
      memory.addUserMessage('first');
      memory.addAssistantMessage('second');
      final history = memory.getHistory();
      expect(history[0].content, equals('first'));
      expect(history[1].content, equals('second'));
    });

    group('with sessionId and repository', () {
      test('generates id using sessionId prefix', () {
        final memory = ConversationMemory(sessionId: 'abc123');
        memory.addUserMessage('test');
        expect(memory.messages.first.id, startsWith('abc123_'));
      });

      test('generates id with mem prefix when no sessionId', () {
        final memory = ConversationMemory();
        memory.addUserMessage('test');
        expect(memory.messages.first.id, startsWith('mem_'));
      });

      test('persists message via repository', () {
        final repo = _FakeConversationRepository();
        final memory = ConversationMemory(
          sessionId: 'sess1',
          repository: repo,
        );
        memory.addUserMessage('persist me');
        expect(repo._saved, hasLength(1));
        expect(repo._saved.first.content, equals('persist me'));
      });

      test('does not persist when repository is null', () {
        final memory = ConversationMemory(sessionId: 'sess1');
        memory.addUserMessage('no persist');
      });
    });
  });
}
