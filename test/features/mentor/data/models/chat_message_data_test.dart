import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/mentor/data/models/chat_message_data.dart';

void main() {
  group('ChatMessageData', () {
    test('creates with required message and isComplete', () {
      final message = ConversationMessage(
        id: 'msg-1',
        sessionId: 'session-1',
        role: MessageRole.mentor,
        type: MessageType.text,
        content: 'Hello student',
        timestamp: DateTime(2024, 6, 15),
      );
      final chatData = ChatMessageData(message: message, isComplete: true);

      expect(chatData.message.id, 'msg-1');
      expect(chatData.isComplete, isTrue);
    });

    test('creates with isComplete false', () {
      final message = ConversationMessage(
        id: 'msg-2',
        sessionId: 'session-1',
        role: MessageRole.student,
        type: MessageType.text,
        content: 'I need help',
        timestamp: DateTime(2024, 6, 15),
      );
      final chatData = ChatMessageData(message: message, isComplete: false);

      expect(chatData.isComplete, isFalse);
    });

    test('wraps message with all fields including metadata', () {
      final message = ConversationMessage(
        id: 'msg-3',
        sessionId: 'session-1',
        role: MessageRole.tutor,
        type: MessageType.exercise,
        content: 'Solve: 2x + 3 = 7',
        metadataJson: '{"difficulty": "easy"}',
        timestamp: DateTime(2024, 6, 15, 10, 30),
        tokenCount: 15,
        isStreaming: false,
      );
      final chatData = ChatMessageData(message: message, isComplete: true);

      expect(chatData.message.metadataJson, '{"difficulty": "easy"}');
      expect(chatData.message.tokenCount, 15);
      expect(chatData.message.isStreaming, isFalse);
    });

    test('wraps message with streaming state', () {
      final message = ConversationMessage(
        id: 'msg-4',
        sessionId: 'session-1',
        role: MessageRole.system,
        type: MessageType.system,
        content: 'Thinking...',
        timestamp: DateTime(2024, 6, 15),
        isStreaming: true,
      );
      final chatData = ChatMessageData(message: message, isComplete: false);

      expect(chatData.message.isStreaming, isTrue);
    });

    test('wraps message with toolCall type and tool fields', () {
      final message = ConversationMessage(
        id: 'msg-tc1',
        sessionId: 'session-1',
        role: MessageRole.tutor,
        type: MessageType.toolCall,
        content: 'Searching questions...',
        timestamp: DateTime(2024, 6, 15),
        toolCallId: 'call-1',
        toolName: 'searchQuestions',
        toolArguments: '{"keyword": "algebra"}',
      );
      final chatData = ChatMessageData(message: message, isComplete: true);

      expect(chatData.message.type, MessageType.toolCall);
      expect(chatData.message.toolCallId, 'call-1');
      expect(chatData.message.toolName, 'searchQuestions');
      expect(chatData.message.toolArguments, '{"keyword": "algebra"}');
    });

    test('wraps message with toolResult type', () {
      final message = ConversationMessage(
        id: 'msg-tr1',
        sessionId: 'session-1',
        role: MessageRole.tutor,
        type: MessageType.toolResult,
        content: 'Found 3 questions',
        timestamp: DateTime(2024, 6, 15),
        toolResult: '{"count": 3}',
      );
      final chatData = ChatMessageData(message: message, isComplete: true);

      expect(chatData.message.type, MessageType.toolResult);
      expect(chatData.message.toolResult, '{"count": 3}');
    });

    test('wraps message with quiz type', () {
      final message = ConversationMessage(
        id: 'msg-qz',
        sessionId: 'session-1',
        role: MessageRole.mentor,
        type: MessageType.quiz,
        content: 'What is 2+2?',
        timestamp: DateTime(2024, 6, 15),
      );
      final chatData = ChatMessageData(message: message, isComplete: true);

      expect(chatData.message.type, MessageType.quiz);
      expect(chatData.message.content, 'What is 2+2?');
    });

    test('wraps message with feedback type', () {
      final message = ConversationMessage(
        id: 'msg-fb',
        sessionId: 'session-1',
        role: MessageRole.mentor,
        type: MessageType.feedback,
        content: 'Correct answer!',
        timestamp: DateTime(2024, 6, 15),
      );
      final chatData = ChatMessageData(message: message, isComplete: true);

      expect(chatData.message.type, MessageType.feedback);
      expect(chatData.message.content, 'Correct answer!');
    });

    test('wraps message with plan type', () {
      final message = ConversationMessage(
        id: 'msg-pl',
        sessionId: 'session-1',
        role: MessageRole.mentor,
        type: MessageType.plan,
        content: 'Study plan for this week',
        timestamp: DateTime(2024, 6, 15),
      );
      final chatData = ChatMessageData(message: message, isComplete: true);

      expect(chatData.message.type, MessageType.plan);
      expect(chatData.message.content, 'Study plan for this week');
    });

    test('ChatMessageData hashCode is stable on same instance', () {
      final message = ConversationMessage(
        id: 'msg-hc',
        sessionId: 'session-1',
        role: MessageRole.mentor,
        type: MessageType.text,
        content: 'Hello',
        timestamp: DateTime(2024, 6, 15),
      );
      final a = ChatMessageData(message: message, isComplete: true);

      expect(a.hashCode, a.hashCode);
    });

    test('wraps message with very long content', () {
      final longContent = 'A' * 10000;
      final message = ConversationMessage(
        id: 'msg-long',
        sessionId: 'session-1',
        role: MessageRole.mentor,
        type: MessageType.text,
        content: longContent,
        timestamp: DateTime(2024, 6, 15),
      );
      final chatData = ChatMessageData(message: message, isComplete: true);

      expect(chatData.message.content.length, 10000);
    });

    test('wraps message with special characters', () {
      final message = ConversationMessage(
        id: 'msg-spec',
        sessionId: 'session-1',
        role: MessageRole.mentor,
        type: MessageType.text,
        content: 'Hello\nWorld\tTab',
        timestamp: DateTime(2024, 6, 15),
      );
      final chatData = ChatMessageData(message: message, isComplete: true);

      expect(chatData.message.content, 'Hello\nWorld\tTab');
    });
  });

  group('ConversationMessage JSON serialization', () {
    test('round-trip with all fields', () {
      final original = ConversationMessage(
        id: 'msg-5',
        sessionId: 'session-2',
        role: MessageRole.mentor,
        type: MessageType.plan,
        content: 'Study plan for this week',
        metadataJson: '{"planId": "plan-1"}',
        timestamp: DateTime(2024, 6, 15, 14, 0, 0, 0),
        tokenCount: 42,
        isStreaming: false,
      );

      final json = original.toJson();
      final restored = ConversationMessage.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.sessionId, original.sessionId);
      expect(restored.role, original.role);
      expect(restored.type, original.type);
      expect(restored.content, original.content);
      expect(restored.metadataJson, original.metadataJson);
      expect(restored.timestamp, original.timestamp);
      expect(restored.tokenCount, original.tokenCount);
      expect(restored.isStreaming, original.isStreaming);
    });

    test('round-trip with minimal fields', () {
      final original = ConversationMessage(
        id: 'msg-6',
        sessionId: 'session-3',
        role: MessageRole.student,
        type: MessageType.text,
        content: 'Hi',
        timestamp: DateTime(2024, 6, 15),
      );

      final json = original.toJson();
      final restored = ConversationMessage.fromJson(json);

      expect(restored.tokenCount, 0);
      expect(restored.isStreaming, isFalse);
      expect(restored.metadataJson, isNull);
      expect(restored.toolCallId, isNull);
      expect(restored.toolName, isNull);
      expect(restored.toolArguments, isNull);
      expect(restored.toolResult, isNull);
    });

    test('handles null metadataJson', () {
      final json = {
        'id': 'msg-7',
        'sessionId': 'session-4',
        'role': 'mentor',
        'type': 'feedback',
        'content': 'Good job',
        'metadataJson': null,
        'timestamp': '2024-06-15T10:00:00.000',
        'tokenCount': 5,
        'isStreaming': false,
      };

      final restored = ConversationMessage.fromJson(json);

      expect(restored.metadataJson, isNull);
      expect(restored.id, 'msg-7');
    });

    test('with missing tokenCount defaults to 0', () {
      final json = {
        'id': 'msg-8',
        'sessionId': 'session-5',
        'role': 'tutor',
        'type': 'text',
        'content': 'Hello',
        'metadataJson': null,
        'timestamp': '2024-06-15T10:00:00.000',
        'isStreaming': false,
      };

      final restored = ConversationMessage.fromJson(json);

      expect(restored.tokenCount, 0);
    });

    test('with missing isStreaming defaults to false', () {
      final json = {
        'id': 'msg-9',
        'sessionId': 'session-6',
        'role': 'student',
        'type': 'text',
        'content': 'OK',
        'metadataJson': null,
        'timestamp': '2024-06-15T10:00:00.000',
        'tokenCount': 3,
      };

      final restored = ConversationMessage.fromJson(json);

      expect(restored.isStreaming, isFalse);
    });

    test('round-trip with toolCall type', () {
      final original = ConversationMessage(
        id: 'msg-tc2',
        sessionId: 'session-7',
        role: MessageRole.tutor,
        type: MessageType.toolCall,
        content: 'Searching...',
        timestamp: DateTime(2024, 6, 15, 10, 0),
        toolCallId: 'call-42',
        toolName: 'searchQuestions',
        toolArguments: '{"keyword": "physics"}',
      );

      final json = original.toJson();
      final restored = ConversationMessage.fromJson(json);

      expect(restored.type, MessageType.toolCall);
      expect(restored.toolCallId, 'call-42');
      expect(restored.toolName, 'searchQuestions');
      expect(restored.toolArguments, '{"keyword": "physics"}');
      expect(restored.toolResult, isNull);
    });

    test('round-trip with toolResult type', () {
      final original = ConversationMessage(
        id: 'msg-tr2',
        sessionId: 'session-8',
        role: MessageRole.tutor,
        type: MessageType.toolResult,
        content: 'Done',
        timestamp: DateTime(2024, 6, 15, 11, 0),
        toolResult: '{"success": true}',
      );

      final json = original.toJson();
      final restored = ConversationMessage.fromJson(json);

      expect(restored.type, MessageType.toolResult);
      expect(restored.toolResult, '{"success": true}');
      expect(restored.toolCallId, isNull);
      expect(restored.toolName, isNull);
      expect(restored.toolArguments, isNull);
    });

    test('with missing tool fields defaults to null', () {
      final json = {
        'id': 'msg-tm',
        'sessionId': 'session-9',
        'role': 'tutor',
        'type': 'toolCall',
        'content': 'Thinking...',
        'metadataJson': null,
        'timestamp': '2024-06-15T12:00:00.000',
        'tokenCount': 0,
        'isStreaming': false,
      };

      final restored = ConversationMessage.fromJson(json);

      expect(restored.toolCallId, isNull);
      expect(restored.toolName, isNull);
      expect(restored.toolArguments, isNull);
      expect(restored.toolResult, isNull);
    });

    test('fromJson throws on unknown role', () {
      final json = {
        'id': 'msg-err',
        'sessionId': 'session-err',
        'role': 'alien',
        'type': 'text',
        'content': 'bad',
        'metadataJson': null,
        'timestamp': '2024-06-15T12:00:00.000',
        'tokenCount': 0,
        'isStreaming': false,
      };

      expect(
        () => ConversationMessage.fromJson(json),
        throwsA(isA<StateError>()),
      );
    });

    test('fromJson throws on unknown type', () {
      final json = {
        'id': 'msg-err2',
        'sessionId': 'session-err2',
        'role': 'tutor',
        'type': 'unknown_type',
        'content': 'bad',
        'metadataJson': null,
        'timestamp': '2024-06-15T12:00:00.000',
        'tokenCount': 0,
        'isStreaming': false,
      };

      expect(
        () => ConversationMessage.fromJson(json),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('ConversationMessage.copyWith', () {
    test('returns identical message when no arguments given', () {
      final original = ConversationMessage(
        id: 'msg-cw1',
        sessionId: 's1',
        role: MessageRole.mentor,
        type: MessageType.text,
        content: 'Hello',
        timestamp: DateTime(2024, 6, 15),
      );

      final copied = original.copyWith();

      expect(copied.id, original.id);
      expect(copied.sessionId, original.sessionId);
      expect(copied.role, original.role);
      expect(copied.type, original.type);
      expect(copied.content, original.content);
      expect(copied.timestamp, original.timestamp);
    });

    test('overrides specified fields', () {
      final original = ConversationMessage(
        id: 'msg-cw2',
        sessionId: 's1',
        role: MessageRole.mentor,
        type: MessageType.text,
        content: 'Hello',
        timestamp: DateTime(2024, 6, 15),
      );

      final copied = original.copyWith(
        content: 'Updated',
        type: MessageType.plan,
      );

      expect(copied.content, 'Updated');
      expect(copied.type, MessageType.plan);
      expect(copied.id, original.id);
      expect(copied.sessionId, original.sessionId);
    });

    test('overrides tool fields', () {
      final original = ConversationMessage(
        id: 'msg-cw3',
        sessionId: 's1',
        role: MessageRole.tutor,
        type: MessageType.toolCall,
        content: 'Search',
        timestamp: DateTime(2024, 6, 15),
      );

      final copied = original.copyWith(
        toolCallId: 'call-99',
        toolName: 'getWeather',
        toolArguments: '{"city": "London"}',
      );

      expect(copied.toolCallId, 'call-99');
      expect(copied.toolName, 'getWeather');
      expect(copied.toolArguments, '{"city": "London"}');
      expect(copied.toolResult, isNull);
    });

    test('overrides metadataJson', () {
      final original = ConversationMessage(
        id: 'msg-cw4',
        sessionId: 's1',
        role: MessageRole.mentor,
        type: MessageType.text,
        content: 'Hi',
        timestamp: DateTime(2024, 6, 15),
      );

      final copied = original.copyWith(metadataJson: '{"key": "val"}');

      expect(copied.metadataJson, '{"key": "val"}');
    });

    test('overrides boolean and numeric fields', () {
      final original = ConversationMessage(
        id: 'msg-cw5',
        sessionId: 's1',
        role: MessageRole.mentor,
        type: MessageType.text,
        content: 'Hi',
        timestamp: DateTime(2024, 6, 15),
      );

      final copied = original.copyWith(
        tokenCount: 100,
        isStreaming: true,
      );

      expect(copied.tokenCount, 100);
      expect(copied.isStreaming, isTrue);
    });
  });

  group('MessageRole enum', () {
    test('has all expected values', () {
      expect(MessageRole.values.length, 4);
      expect(MessageRole.values[0], MessageRole.system);
      expect(MessageRole.values[1], MessageRole.tutor);
      expect(MessageRole.values[2], MessageRole.student);
      expect(MessageRole.values[3], MessageRole.mentor);
    });

    test('fromJson parses role names correctly', () {
      for (final role in MessageRole.values) {
        final json = {
          'id': 'msg-r',
          'sessionId': 's',
          'role': role.name,
          'type': 'text',
          'content': 'test',
          'metadataJson': null,
          'timestamp': '2024-06-15T10:00:00.000',
          'tokenCount': 0,
          'isStreaming': false,
        };
        final restored = ConversationMessage.fromJson(json);
        expect(restored.role, role);
      }
    });
  });

  group('MessageType enum', () {
    test('has all expected values', () {
      expect(MessageType.values.length, 8);
      expect(MessageType.values[0], MessageType.text);
      expect(MessageType.values[1], MessageType.exercise);
      expect(MessageType.values[2], MessageType.quiz);
      expect(MessageType.values[3], MessageType.feedback);
      expect(MessageType.values[4], MessageType.plan);
      expect(MessageType.values[5], MessageType.system);
      expect(MessageType.values[6], MessageType.toolCall);
      expect(MessageType.values[7], MessageType.toolResult);
    });

    test('fromJson parses type names correctly', () {
      for (final type in MessageType.values) {
        final json = {
          'id': 'msg-t',
          'sessionId': 's',
          'role': 'tutor',
          'type': type.name,
          'content': 'test',
          'metadataJson': null,
          'timestamp': '2024-06-15T10:00:00.000',
          'tokenCount': 0,
          'isStreaming': false,
        };
        final restored = ConversationMessage.fromJson(json);
        expect(restored.type, type);
      }
    });
  });
}
