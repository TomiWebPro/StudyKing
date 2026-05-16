import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';

void main() {
  group('ConversationMessage', () {
    final now = DateTime(2026, 5, 16);
    const id = 'msg-1';
    const sessionId = 'session-1';
    const content = 'Hello, tutor!';

    group('constructor', () {
      test('creates with required fields', () {
        final msg = ConversationMessage(
          id: id, sessionId: sessionId,
          role: MessageRole.student, type: MessageType.text,
          content: content, timestamp: now,
        );
        expect(msg.id, id);
        expect(msg.sessionId, sessionId);
        expect(msg.role, MessageRole.student);
        expect(msg.type, MessageType.text);
        expect(msg.content, content);
        expect(msg.timestamp, now);
        expect(msg.metadataJson, isNull);
        expect(msg.tokenCount, 0);
        expect(msg.isStreaming, isFalse);
      });

      test('accepts all optional fields', () {
        final msg = ConversationMessage(
          id: id, sessionId: sessionId,
          role: MessageRole.tutor, type: MessageType.feedback,
          content: 'Good job!', timestamp: now,
          metadataJson: '{"key": "value"}',
          tokenCount: 150, isStreaming: true,
        );
        expect(msg.role, MessageRole.tutor);
        expect(msg.type, MessageType.feedback);
        expect(msg.metadataJson, '{"key": "value"}');
        expect(msg.tokenCount, 150);
        expect(msg.isStreaming, isTrue);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final msg = ConversationMessage(
          id: id, sessionId: sessionId,
          role: MessageRole.system, type: MessageType.system,
          content: 'System message', timestamp: now,
          metadataJson: '{}', tokenCount: 10, isStreaming: false,
        );
        final json = msg.toJson();
        expect(json['id'], id);
        expect(json['sessionId'], sessionId);
        expect(json['role'], 'system');
        expect(json['type'], 'system');
        expect(json['content'], 'System message');
        expect(json['timestamp'], now.toIso8601String());
        expect(json['tokenCount'], 10);
        expect(json['isStreaming'], isFalse);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'id': id, 'sessionId': sessionId,
          'role': 'tutor', 'type': 'exercise',
          'content': 'Solve this', 'timestamp': now.toIso8601String(),
          'metadataJson': null, 'tokenCount': 50, 'isStreaming': false,
        };
        final msg = ConversationMessage.fromJson(json);
        expect(msg.id, id);
        expect(msg.role, MessageRole.tutor);
        expect(msg.type, MessageType.exercise);
        expect(msg.content, 'Solve this');
        expect(msg.tokenCount, 50);
      });

      test('handles missing optional fields', () {
        final json = {
          'id': id, 'sessionId': sessionId,
          'role': 'student', 'type': 'text',
          'content': content, 'timestamp': now.toIso8601String(),
        };
        final msg = ConversationMessage.fromJson(json);
        expect(msg.metadataJson, isNull);
        expect(msg.tokenCount, 0);
        expect(msg.isStreaming, isFalse);
      });
    });

    group('serialization roundtrip', () {
      test('preserves all fields', () {
        final original = ConversationMessage(
          id: id, sessionId: sessionId,
          role: MessageRole.mentor, type: MessageType.plan,
          content: 'Plan content', timestamp: now,
          tokenCount: 200,
        );
        final restored = ConversationMessage.fromJson(original.toJson());
        expect(restored.id, original.id);
        expect(restored.role, original.role);
        expect(restored.type, original.type);
        expect(restored.tokenCount, original.tokenCount);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final msg = ConversationMessage(
          id: id, sessionId: sessionId,
          role: MessageRole.student, type: MessageType.text,
          content: content, timestamp: now,
        );
        final copy = msg.copyWith();
        expect(copy.id, msg.id);
        expect(copy.content, msg.content);
      });

      test('updates specified fields', () {
        final msg = ConversationMessage(
          id: id, sessionId: sessionId,
          role: MessageRole.student, type: MessageType.text,
          content: content, timestamp: now,
        );
        final later = DateTime(2026, 5, 17);
        final copy = msg.copyWith(
          role: MessageRole.tutor, content: 'Updated', timestamp: later,
        );
        expect(copy.role, MessageRole.tutor);
        expect(copy.content, 'Updated');
        expect(copy.timestamp, later);
        expect(copy.id, id);
      });
    });

    group('equality', () {
      test('identical instances are equal', () {
        final a = ConversationMessage(
          id: id, sessionId: sessionId,
          role: MessageRole.student, type: MessageType.text,
          content: content, timestamp: now,
        );
        expect(a == a, isTrue);
      });

      test('different instances are not equal', () {
        final a = ConversationMessage(
          id: id, sessionId: sessionId,
          role: MessageRole.student, type: MessageType.text,
          content: content, timestamp: now,
        );
        final b = ConversationMessage(
          id: 'other', sessionId: sessionId,
          role: MessageRole.student, type: MessageType.text,
          content: content, timestamp: now,
        );
        expect(a == b, isFalse);
      });

      test('hashCode is consistent', () {
        final a = ConversationMessage(
          id: id, sessionId: sessionId,
          role: MessageRole.student, type: MessageType.text,
          content: content, timestamp: now,
        );
        expect(a.hashCode, a.hashCode);
      });
    });
  });

  group('MessageRole enum', () {
    test('has correct values in order', () {
      expect(MessageRole.values, [
        MessageRole.system,
        MessageRole.tutor,
        MessageRole.student,
        MessageRole.mentor,
      ]);
    });
  });

  group('MessageType enum', () {
    test('has correct values in order', () {
      expect(MessageType.values, [
        MessageType.text,
        MessageType.exercise,
        MessageType.quiz,
        MessageType.feedback,
        MessageType.plan,
        MessageType.system,
      ]);
    });
  });
}
