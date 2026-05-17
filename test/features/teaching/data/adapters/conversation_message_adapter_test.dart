import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:studyking/features/teaching/data/adapters/conversation_message_adapter.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/core/data/models/session_model.dart';

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

  group('ConversationMessageAdapter edge cases', () {
    test('write/read round-trip with empty string content', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(ConversationMessageAdapter());
      final adapter = ConversationMessageAdapter();
      final now = DateTime.now();
      final source = ConversationMessage(
        id: '',
        sessionId: '',
        role: MessageRole.system,
        type: MessageType.system,
        content: '',
        timestamp: now,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, '');
      expect(restored.sessionId, '');
      expect(restored.content, '');
    });

    test('write/read round-trip with unicode and special characters', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(ConversationMessageAdapter());
      final adapter = ConversationMessageAdapter();
      final now = DateTime.now();
      final source = ConversationMessage(
        id: 'msg-unicode',
        sessionId: 'sess-1',
        role: MessageRole.tutor,
        type: MessageType.text,
        content: 'Hello 世界 ñ ñ ñ © ®™ ± √ ∞ ≤ π 你好 👋 🌍',
        metadataJson: '{"emoji": "🎉"}',
        timestamp: now,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.content, 'Hello 世界 ñ ñ ñ © ®™ ± √ ∞ ≤ π 你好 👋 🌍');
      expect(restored.metadataJson, '{"emoji": "🎉"}');
    });

    test('write/read round-trip with epoch timestamp', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(ConversationMessageAdapter());
      final adapter = ConversationMessageAdapter();
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      final source = ConversationMessage(
        id: 'msg-epoch',
        sessionId: 'sess-1',
        role: MessageRole.system,
        type: MessageType.system,
        content: 'epoch',
        timestamp: epoch,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.timestamp, epoch);
    });

    test('write/read round-trip with far future timestamp', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(ConversationMessageAdapter());
      final adapter = ConversationMessageAdapter();
      final future = DateTime(2100, 12, 31, 23, 59, 59);
      final source = ConversationMessage(
        id: 'msg-future',
        sessionId: 'sess-1',
        role: MessageRole.tutor,
        type: MessageType.plan,
        content: 'future',
        timestamp: future,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.timestamp, future);
    });

    test('write/read round-trip with large content string', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(ConversationMessageAdapter());
      final adapter = ConversationMessageAdapter();
      final now = DateTime.now();
      final longContent = 'A' * 10000;
      final source = ConversationMessage(
        id: 'msg-long',
        sessionId: 'sess-1',
        role: MessageRole.tutor,
        type: MessageType.text,
        content: longContent,
        timestamp: now,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.content.length, 10000);
      expect(restored.content, longContent);
    });

    test('write/read round-trip with metadataJson as empty string', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(ConversationMessageAdapter());
      final adapter = ConversationMessageAdapter();
      final now = DateTime.now();
      final source = ConversationMessage(
        id: 'msg-empty-meta',
        sessionId: 'sess-1',
        role: MessageRole.student,
        type: MessageType.quiz,
        content: 'test',
        metadataJson: '',
        timestamp: now,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.metadataJson, '');
    });

    test('write/read round-trip with maximum tokenCount and isStreaming=true', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(ConversationMessageAdapter());
      final adapter = ConversationMessageAdapter();
      final now = DateTime.now();
      final source = ConversationMessage(
        id: 'msg-max',
        sessionId: 'sess-1',
        role: MessageRole.mentor,
        type: MessageType.feedback,
        content: 'max values',
        metadataJson: '{"key": "value"}',
        timestamp: now,
        tokenCount: 2147483647,
        isStreaming: true,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.tokenCount, 2147483647);
      expect(restored.isStreaming, isTrue);
    });
  });

  group('TutorSessionAdapter edge cases', () {
    test('write/read round-trip with empty strings for text fields', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(TutorSessionAdapter());
      final adapter = TutorSessionAdapter();
      final now = DateTime.now();
      final source = TutorSession(
        id: '',
        studentId: '',
        subjectId: '',
        topicId: '',
        topicTitle: '',
        startTime: now,
        tutorNotes: '',
        topicsCovered: [],
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, '');
      expect(restored.studentId, '');
      expect(restored.subjectId, '');
      expect(restored.topicId, '');
      expect(restored.topicTitle, '');
      expect(restored.tutorNotes, '');
    });

    test('write/read round-trip with maximum values', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(TutorSessionAdapter());
      final adapter = TutorSessionAdapter();
      final now = DateTime.now();
      final source = TutorSession(
        id: 'max-id',
        studentId: 'student-999',
        subjectId: 'subject-999',
        topicId: 'topic-999',
        topicTitle: 'Very Long Topic Title ' * 20,
        status: SessionStatus.completed,
        startTime: now,
        endTime: now.add(const Duration(hours: 2)),
        plannedDurationMinutes: 999,
        lessonPlanJson: '{"complex": "plan", "sections": [1, 2, 3]}',
        questionsAsked: 9999,
        questionsCorrect: 9500,
        confidenceRating: 5,
        tutorNotes: 'A' * 1000,
        topicsCovered: List.generate(50, (i) => 'topic-$i'),
        totalMessages: 99999,
        totalTokensUsed: 999999,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, 'max-id');
      expect(restored.plannedDurationMinutes, 999);
      expect(restored.questionsAsked, 9999);
      expect(restored.questionsCorrect, 9500);
      expect(restored.confidenceRating, 5);
      expect(restored.tutorNotes?.length, 1000);
      expect(restored.topicsCovered.length, 50);
      expect(restored.totalMessages, 99999);
      expect(restored.totalTokensUsed, 999999);
    });

    test('write/read round-trip with unicode text', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(TutorSessionAdapter());
      final adapter = TutorSessionAdapter();
      final now = DateTime.now();
      final source = TutorSession(
        id: 'sess-üñíçödé',
        studentId: 'stud-ñ',
        subjectId: 'sub-数学',
        topicId: 'topic-物理',
        topicTitle: 'Advanced 物理',
        status: SessionStatus.inProgress,
        startTime: now,
        tutorNotes: 'Estudiante habla español 中文',
        topicsCovered: ['力学', '热学'],
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, 'sess-üñíçödé');
      expect(restored.studentId, 'stud-ñ');
      expect(restored.subjectId, 'sub-数学');
      expect(restored.topicTitle, 'Advanced 物理');
      expect(restored.tutorNotes, 'Estudiante habla español 中文');
      expect(restored.topicsCovered, ['力学', '热学']);
    });

    test('write/read round-trip with epoch and far future timestamps', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(TutorSessionAdapter());
      final adapter = TutorSessionAdapter();
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      final farFuture = DateTime(2100, 1, 1);
      final source = TutorSession(
        id: 's1', studentId: 's', subjectId: 's',
        topicId: 't', topicTitle: 'T',
        startTime: epoch,
        endTime: farFuture,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.startTime, epoch);
      expect(restored.endTime, farFuture);
    });
  });
}
