import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';

void main() {
  group('MessageRole', () {
    test('has all expected values', () {
      expect(MessageRole.values.length, 4);
      expect(MessageRole.system.index, 0);
      expect(MessageRole.tutor.index, 1);
      expect(MessageRole.student.index, 2);
      expect(MessageRole.mentor.index, 3);
    });
  });

  group('MessageType', () {
    test('has all expected values', () {
      expect(MessageType.values.length, 6);
      expect(MessageType.text.index, 0);
      expect(MessageType.exercise.index, 1);
      expect(MessageType.quiz.index, 2);
      expect(MessageType.feedback.index, 3);
      expect(MessageType.plan.index, 4);
      expect(MessageType.system.index, 5);
    });
  });

  group('ConversationMessage', () {
    final now = DateTime(2025, 1, 15, 10, 30, 0);

    test('creates with required fields', () {
      final msg = ConversationMessage(
        id: 'msg-1',
        sessionId: 'session-1',
        role: MessageRole.tutor,
        type: MessageType.text,
        content: 'Hello student',
        timestamp: now,
      );
      expect(msg.id, 'msg-1');
      expect(msg.sessionId, 'session-1');
      expect(msg.role, MessageRole.tutor);
      expect(msg.type, MessageType.text);
      expect(msg.content, 'Hello student');
      expect(msg.metadataJson, isNull);
      expect(msg.timestamp, now);
      expect(msg.tokenCount, 0);
      expect(msg.isStreaming, isFalse);
    });

    test('creates with all fields', () {
      final msg = ConversationMessage(
        id: 'msg-1',
        sessionId: 'session-1',
        role: MessageRole.student,
        type: MessageType.quiz,
        content: 'My answer',
        metadataJson: '{"key": "value"}',
        timestamp: now,
        tokenCount: 42,
        isStreaming: true,
      );
      expect(msg.metadataJson, '{"key": "value"}');
      expect(msg.tokenCount, 42);
      expect(msg.isStreaming, isTrue);
    });

    test('creates with all role variants', () {
      expect(
        ConversationMessage(id: '1', sessionId: 's1', role: MessageRole.system, type: MessageType.system, content: '', timestamp: now).role,
        MessageRole.system,
      );
      expect(
        ConversationMessage(id: '2', sessionId: 's1', role: MessageRole.tutor, type: MessageType.text, content: '', timestamp: now).role,
        MessageRole.tutor,
      );
      expect(
        ConversationMessage(id: '3', sessionId: 's1', role: MessageRole.student, type: MessageType.text, content: '', timestamp: now).role,
        MessageRole.student,
      );
      expect(
        ConversationMessage(id: '4', sessionId: 's1', role: MessageRole.mentor, type: MessageType.text, content: '', timestamp: now).role,
        MessageRole.mentor,
      );
    });

    test('creates with all type variants', () {
      expect(
        ConversationMessage(id: '1', sessionId: 's1', role: MessageRole.tutor, type: MessageType.text, content: '', timestamp: now).type,
        MessageType.text,
      );
      expect(
        ConversationMessage(id: '2', sessionId: 's1', role: MessageRole.tutor, type: MessageType.exercise, content: '', timestamp: now).type,
        MessageType.exercise,
      );
      expect(
        ConversationMessage(id: '3', sessionId: 's1', role: MessageRole.tutor, type: MessageType.quiz, content: '', timestamp: now).type,
        MessageType.quiz,
      );
      expect(
        ConversationMessage(id: '4', sessionId: 's1', role: MessageRole.tutor, type: MessageType.feedback, content: '', timestamp: now).type,
        MessageType.feedback,
      );
      expect(
        ConversationMessage(id: '5', sessionId: 's1', role: MessageRole.tutor, type: MessageType.plan, content: '', timestamp: now).type,
        MessageType.plan,
      );
      expect(
        ConversationMessage(id: '6', sessionId: 's1', role: MessageRole.tutor, type: MessageType.system, content: '', timestamp: now).type,
        MessageType.system,
      );
    });

    group('toJson', () {
      test('serializes all fields', () {
        final msg = ConversationMessage(
          id: 'msg-1',
          sessionId: 'session-1',
          role: MessageRole.tutor,
          type: MessageType.text,
          content: 'Hello',
          metadataJson: '{"k":"v"}',
          timestamp: now,
          tokenCount: 10,
          isStreaming: false,
        );
        final json = msg.toJson();
        expect(json['id'], 'msg-1');
        expect(json['sessionId'], 'session-1');
        expect(json['role'], 'tutor');
        expect(json['type'], 'text');
        expect(json['content'], 'Hello');
        expect(json['metadataJson'], '{"k":"v"}');
        expect(json['timestamp'], now.toIso8601String());
        expect(json['tokenCount'], 10);
        expect(json['isStreaming'], isFalse);
      });

      test('serializes with null metadata', () {
        final msg = ConversationMessage(
          id: 'msg-1', sessionId: 's1', role: MessageRole.student, type: MessageType.exercise, content: 'test', timestamp: now,
        );
        final json = msg.toJson();
        expect(json['metadataJson'], isNull);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'id': 'msg-1',
          'sessionId': 'session-1',
          'role': 'tutor',
          'type': 'text',
          'content': 'Hello',
          'metadataJson': '{"k":"v"}',
          'timestamp': now.toIso8601String(),
          'tokenCount': 10,
          'isStreaming': true,
        };
        final msg = ConversationMessage.fromJson(json);
        expect(msg.id, 'msg-1');
        expect(msg.role, MessageRole.tutor);
        expect(msg.type, MessageType.text);
        expect(msg.content, 'Hello');
        expect(msg.metadataJson, '{"k":"v"}');
        expect(msg.tokenCount, 10);
        expect(msg.isStreaming, isTrue);
      });

      test('deserializes with missing optionals', () {
        final json = {
          'id': 'msg-1',
          'sessionId': 'session-1',
          'role': 'student',
          'type': 'quiz',
          'content': 'Answer',
          'timestamp': now.toIso8601String(),
        };
        final msg = ConversationMessage.fromJson(json);
        expect(msg.metadataJson, isNull);
        expect(msg.tokenCount, 0);
        expect(msg.isStreaming, isFalse);
      });

      test('deserializes all roles and types', () {
        for (final role in MessageRole.values) {
          for (final type in MessageType.values) {
            final json = {
              'id': 'm', 'sessionId': 's', 'role': role.name, 'type': type.name,
              'content': 'test', 'timestamp': now.toIso8601String(),
            };
            final msg = ConversationMessage.fromJson(json);
            expect(msg.role, role);
            expect(msg.type, type);
          }
        }
      });
    });

    group('serialization roundtrip', () {
      test('toJson then fromJson preserves data', () {
        final original = ConversationMessage(
          id: 'msg-1',
          sessionId: 'session-1',
          role: MessageRole.tutor,
          type: MessageType.feedback,
          content: 'Good job!',
          metadataJson: '{"score": 85}',
          timestamp: now,
          tokenCount: 15,
          isStreaming: true,
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
    });

    group('copyWith', () {
      test('creates new instance with updated fields', () {
        final original = ConversationMessage(
          id: 'msg-1', sessionId: 's1', role: MessageRole.tutor, type: MessageType.text, content: 'Hello', timestamp: now,
        );
        final copy = original.copyWith(content: 'Updated', role: MessageRole.student);
        expect(copy.id, 'msg-1');
        expect(copy.content, 'Updated');
        expect(copy.role, MessageRole.student);
        expect(original.content, 'Hello');
        expect(original.role, MessageRole.tutor);
      });

      test('copyWith preserves original values when no args', () {
        final original = ConversationMessage(
          id: 'msg-1', sessionId: 's1', role: MessageRole.tutor, type: MessageType.text, content: 'Hello', timestamp: now, tokenCount: 5,
        );
        final copy = original.copyWith();
        expect(copy.id, original.id);
        expect(copy.sessionId, original.sessionId);
        expect(copy.role, original.role);
        expect(copy.type, original.type);
        expect(copy.content, original.content);
        expect(copy.timestamp, original.timestamp);
        expect(copy.tokenCount, original.tokenCount);
      });

      test('copyWith updates all fields', () {
        final original = ConversationMessage(
          id: 'msg-1', sessionId: 's1', role: MessageRole.tutor, type: MessageType.text, content: 'Hello', timestamp: now,
        );
        final newTime = DateTime(2025, 6, 1);
        final copy = original.copyWith(
          id: 'msg-2',
          sessionId: 's2',
          role: MessageRole.student,
          type: MessageType.quiz,
          content: 'Answer',
          metadataJson: '{}',
          timestamp: newTime,
          tokenCount: 99,
          isStreaming: true,
        );
        expect(copy.id, 'msg-2');
        expect(copy.sessionId, 's2');
        expect(copy.role, MessageRole.student);
        expect(copy.type, MessageType.quiz);
        expect(copy.content, 'Answer');
        expect(copy.metadataJson, '{}');
        expect(copy.timestamp, newTime);
        expect(copy.tokenCount, 99);
        expect(copy.isStreaming, isTrue);
      });
    });

    group('equality', () {
      test('uses identity-based equality', () {
        final a = ConversationMessage(id: 'a', sessionId: 's1', role: MessageRole.tutor, type: MessageType.text, content: 'Hello', timestamp: now);
        final b = ConversationMessage(id: 'b', sessionId: 's2', role: MessageRole.student, type: MessageType.quiz, content: 'Answer', timestamp: now);
        expect(a == b, isFalse);
        expect(a == a, isTrue);
      });

      test('hashCode is consistent', () {
        final obj = ConversationMessage(id: 'a', sessionId: 's1', role: MessageRole.tutor, type: MessageType.text, content: 'Hello', timestamp: now);
        final hash = obj.hashCode;
        expect(obj.hashCode, hash);
      });
    });

    group('toString', () {
      test('includes class name', () {
        final obj = ConversationMessage(id: 'a', sessionId: 's1', role: MessageRole.tutor, type: MessageType.text, content: 'Hello', timestamp: now);
        expect(obj.toString(), contains('ConversationMessage'));
      });
    });

    group('fromJson error handling', () {
      test('throws on invalid role string', () {
        final json = {
          'id': 'msg-1',
          'sessionId': 'session-1',
          'role': 'invalid_role',
          'type': 'text',
          'content': 'Hello',
          'timestamp': now.toIso8601String(),
        };
        expect(() => ConversationMessage.fromJson(json), throwsA(isA<StateError>()));
      });

      test('throws on invalid type string', () {
        final json = {
          'id': 'msg-1',
          'sessionId': 'session-1',
          'role': 'tutor',
          'type': 'invalid_type',
          'content': 'Hello',
          'timestamp': now.toIso8601String(),
        };
        expect(() => ConversationMessage.fromJson(json), throwsA(isA<StateError>()));
      });
    });
  });
}
