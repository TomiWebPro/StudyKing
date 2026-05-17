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
    });

    test('fromJson handles null metadataJson', () {
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

    test('fromJson with missing tokenCount defaults to 0', () {
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

    test('fromJson with missing isStreaming defaults to false', () {
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
      expect(MessageType.values.length, 6);
      expect(MessageType.values[0], MessageType.text);
      expect(MessageType.values[1], MessageType.exercise);
      expect(MessageType.values[2], MessageType.quiz);
      expect(MessageType.values[3], MessageType.feedback);
      expect(MessageType.values[4], MessageType.plan);
      expect(MessageType.values[5], MessageType.system);
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
