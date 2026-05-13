import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:studyking/core/data/adapters/conversation_message_adapter.dart';
import 'package:studyking/core/data/models/conversation_message_model.dart';
import 'package:studyking/core/data/models/tutor_session_model.dart';

void main() {
  group('ConversationMessageAdapter', () {
    test('typeId is 27', () {
      expect(ConversationMessageAdapter().typeId, 27);
    });

    test('hashCode is consistent', () {
      final adapter = ConversationMessageAdapter();
      expect(adapter.hashCode, adapter.hashCode);
    });

    test('write/read round-trip with all fields', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(ConversationMessageAdapter());
      final adapter = ConversationMessageAdapter();
      final now = DateTime(2025, 1, 15, 10, 30, 0);
      final source = ConversationMessage(
        id: 'msg-1',
        sessionId: 'session-1',
        role: MessageRole.tutor,
        type: MessageType.text,
        content: 'Hello student',
        metadataJson: '{"key": "value"}',
        timestamp: now,
        tokenCount: 42,
        isStreaming: true,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, 'msg-1');
      expect(restored.sessionId, 'session-1');
      expect(restored.role, MessageRole.tutor);
      expect(restored.type, MessageType.text);
      expect(restored.content, 'Hello student');
      expect(restored.metadataJson, '{"key": "value"}');
      expect(restored.timestamp, now);
      expect(restored.tokenCount, 42);
      expect(restored.isStreaming, isTrue);
    });

    test('write/read round-trip with minimal fields', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(ConversationMessageAdapter());
      final adapter = ConversationMessageAdapter();
      final now = DateTime(2025, 1, 15);
      final source = ConversationMessage(
        id: 'msg-1',
        sessionId: 'session-1',
        role: MessageRole.student,
        type: MessageType.quiz,
        content: 'My answer',
        timestamp: now,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.metadataJson, isNull);
      expect(restored.tokenCount, 0);
      expect(restored.isStreaming, isFalse);
    });

    test('write/read round-trip with all role and type combinations', () {
      for (final role in MessageRole.values) {
        for (final type in MessageType.values) {
          final registry = TypeRegistryImpl()
            ..registerAdapter(ConversationMessageAdapter());
          final adapter = ConversationMessageAdapter();
          final now = DateTime.now();
          final source = ConversationMessage(
            id: 'msg',
            sessionId: 'sess',
            role: role,
            type: type,
            content: 'test',
            timestamp: now,
          );

          final writer = BinaryWriterImpl(registry);
          adapter.write(writer, source);
          final reader = BinaryReaderImpl(writer.toBytes(), registry);
          final restored = adapter.read(reader);

          expect(restored.role, role);
          expect(restored.type, type);
        }
      }
    });
  });

  group('TutorSessionAdapter', () {
    test('typeId is 28', () {
      expect(TutorSessionAdapter().typeId, 28);
    });

    test('hashCode is consistent', () {
      final adapter = TutorSessionAdapter();
      expect(adapter.hashCode, adapter.hashCode);
    });

    test('write/read round-trip with all fields', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(TutorSessionAdapter());
      final adapter = TutorSessionAdapter();
      final startTime = DateTime(2025, 1, 15, 10, 0, 0);
      final endTime = DateTime(2025, 1, 15, 10, 45, 0);
      final source = TutorSession(
        id: 'session-1',
        studentId: 'student-1',
        subjectId: 'subject-1',
        topicId: 'topic-1',
        topicTitle: 'Algebra',
        status: SessionStatus.completed,
        startTime: startTime,
        endTime: endTime,
        plannedDurationMinutes: 45,
        lessonPlanJson: '{"plan": "test"}',
        questionsAsked: 10,
        questionsCorrect: 7,
        confidenceRating: 4,
        tutorNotes: 'Good progress',
        topicsCovered: ['algebra', 'equations'],
        totalMessages: 25,
        totalTokensUsed: 5000,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, 'session-1');
      expect(restored.studentId, 'student-1');
      expect(restored.subjectId, 'subject-1');
      expect(restored.topicId, 'topic-1');
      expect(restored.topicTitle, 'Algebra');
      expect(restored.status, SessionStatus.completed);
      expect(restored.startTime, startTime);
      expect(restored.endTime, endTime);
      expect(restored.plannedDurationMinutes, 45);
      expect(restored.lessonPlanJson, '{"plan": "test"}');
      expect(restored.questionsAsked, 10);
      expect(restored.questionsCorrect, 7);
      expect(restored.confidenceRating, 4);
      expect(restored.tutorNotes, 'Good progress');
      expect(restored.topicsCovered, ['algebra', 'equations']);
      expect(restored.totalMessages, 25);
      expect(restored.totalTokensUsed, 5000);
    });

    test('write/read round-trip with minimal fields', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(TutorSessionAdapter());
      final adapter = TutorSessionAdapter();
      final now = DateTime.now();
      final source = TutorSession(
        id: 'session-1',
        studentId: 'student-1',
        subjectId: 'subject-1',
        topicId: 'topic-1',
        topicTitle: 'Algebra',
        startTime: now,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.status, SessionStatus.planned);
      expect(restored.endTime, isNull);
      expect(restored.plannedDurationMinutes, 45);
      expect(restored.lessonPlanJson, '{}');
      expect(restored.questionsAsked, 0);
      expect(restored.questionsCorrect, 0);
      expect(restored.confidenceRating, 0);
      expect(restored.tutorNotes, isNull);
      expect(restored.topicsCovered, []);
      expect(restored.totalMessages, 0);
      expect(restored.totalTokensUsed, 0);
    });

    test('write/read round-trip with all status values', () {
      for (final status in SessionStatus.values) {
        final registry = TypeRegistryImpl()
          ..registerAdapter(TutorSessionAdapter());
        final adapter = TutorSessionAdapter();
        final now = DateTime.now();
        final source = TutorSession(
          id: 's', studentId: 'stu', subjectId: 'sub',
          topicId: 't', topicTitle: 'T', status: status,
          startTime: now,
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.status, status);
      }
    });

    test('write/read round-trip with null endTime', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(TutorSessionAdapter());
      final adapter = TutorSessionAdapter();
      final now = DateTime.now();
      final source = TutorSession(
        id: 's', studentId: 'stu', subjectId: 'sub',
        topicId: 't', topicTitle: 'T', startTime: now,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.endTime, isNull);
    });
  });
}
