import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/sessions/data/adapters/session_adapter.dart';

void main() {
  group('SessionAdapter', () {
    test('typeId is 36', () {
      expect(SessionAdapter().typeId, 36);
    });

    test('adapter is SessionAdapter', () {
      expect(SessionAdapter(), isA<SessionAdapter>());
    });

    test('write/read round-trip with all fields', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(SessionAdapter());
      final adapter = SessionAdapter();
      final now = DateTime(2025, 6, 15, 10, 30, 0);
      final endTime = DateTime(2025, 6, 15, 11, 45, 0);
      final createdAt = DateTime(2025, 6, 15, 9, 0, 0);
      final source = Session(
        id: 'session-001',
        studentId: 'student-1',
        subjectId: 'subject-math',
        topicId: 'topic-algebra',
        type: SessionType.tutoring,
        startTime: now,
        endTime: endTime,
        plannedDurationMinutes: 90,
        actualDurationMs: 4500000,
        questionsAnswered: 15,
        correctAnswers: 12,
        completed: true,
        sourceId: 'source-abc',
        sourceIds: ['src-1', 'src-2'],
        lessonIds: ['lesson-1', 'lesson-2'],
        tags: ['algebra', 'equations'],
        createdAt: createdAt,
        tutorMetadata: TutorMetadata(
          topicTitle: 'Linear Equations',
          lessonPlanJson: '{"steps":[]}',
          confidenceRating: 4,
          tutorNotes: 'Student understood well',
          topicsCovered: ['solving', 'graphing'],
          totalMessages: 25,
          totalTokensUsed: 15000,
        ),
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, 'session-001');
      expect(restored.studentId, 'student-1');
      expect(restored.subjectId, 'subject-math');
      expect(restored.topicId, 'topic-algebra');
      expect(restored.type, SessionType.tutoring);
      expect(restored.startTime.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(restored.endTime!.millisecondsSinceEpoch, endTime.millisecondsSinceEpoch);
      expect(restored.plannedDurationMinutes, 90);
      expect(restored.actualDurationMs, 4500000);
      expect(restored.questionsAnswered, 15);
      expect(restored.correctAnswers, 12);
      expect(restored.completed, isTrue);
      expect(restored.sourceId, 'source-abc');
      expect(restored.sourceIds, ['src-1', 'src-2']);
      expect(restored.lessonIds, ['lesson-1', 'lesson-2']);
      expect(restored.tags, ['algebra', 'equations']);
      expect(restored.createdAt.millisecondsSinceEpoch, createdAt.millisecondsSinceEpoch);
      expect(restored.tutorMetadata!.topicTitle, 'Linear Equations');
      expect(restored.tutorMetadata!.lessonPlanJson, '{"steps":[]}');
      expect(restored.tutorMetadata!.confidenceRating, 4);
      expect(restored.tutorMetadata!.tutorNotes, 'Student understood well');
      expect(restored.tutorMetadata!.topicsCovered, ['solving', 'graphing']);
      expect(restored.tutorMetadata!.totalMessages, 25);
      expect(restored.tutorMetadata!.totalTokensUsed, 15000);
    });

    test('write/read with minimal fields (null optionals, defaults)', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(SessionAdapter());
      final adapter = SessionAdapter();
      final now = DateTime(2025, 3, 1);
      final source = Session(
        id: 'session-002',
        studentId: 'student-2',
        startTime: now,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, 'session-002');
      expect(restored.studentId, 'student-2');
      expect(restored.subjectId, isNull);
      expect(restored.topicId, isNull);
      expect(restored.type, SessionType.practice);
      expect(restored.endTime, isNull);
      expect(restored.plannedDurationMinutes, isNull);
      expect(restored.actualDurationMs, 0);
      expect(restored.questionsAnswered, 0);
      expect(restored.correctAnswers, 0);
      expect(restored.completed, isFalse);
      expect(restored.sourceId, isNull);
      expect(restored.sourceIds, isEmpty);
      expect(restored.lessonIds, isEmpty);
      expect(restored.tags, isEmpty);
      expect(restored.tutorMetadata, isNull);
    });

    test('write/read with null endTime', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(SessionAdapter());
      final adapter = SessionAdapter();
      final now = DateTime(2025, 4, 1);
      final source = Session(
        id: 's3', studentId: 's1', startTime: now,
        endTime: null,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.endTime, isNull);
    });

    test('read with missing createdAt field falls back to DateTime.now()', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(SessionAdapter());
      final adapter = SessionAdapter();
      final now = DateTime(2025, 6, 15);

      final writer = BinaryWriterImpl(registry);
      writer.writeByte(6);
      writer.writeByte(0); writer.write('test-id');
      writer.writeByte(1); writer.write('student-1');
      writer.writeByte(2); writer.write(null);
      writer.writeByte(3); writer.write(null);
      writer.writeByte(4); writer.write(SessionType.focus.index);
      writer.writeByte(5); writer.write(now.millisecondsSinceEpoch);

      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, 'test-id');
      expect(restored.studentId, 'student-1');
      expect(restored.createdAt, isNotNull);
      final diff = DateTime.now().difference(restored.createdAt);
      expect(diff.inSeconds, lessThan(5));
    });

    test('write/read with null sourceId', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(SessionAdapter());
      final adapter = SessionAdapter();
      final now = DateTime(2025, 4, 1);
      final source = Session(
        id: 's4', studentId: 's1', startTime: now,
        sourceId: null,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.sourceId, isNull);
    });

    test('write/read with null tutorMetadata', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(SessionAdapter());
      final adapter = SessionAdapter();
      final now = DateTime(2025, 4, 1);
      final source = Session(
        id: 's5', studentId: 's1', startTime: now,
        tutorMetadata: null,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.tutorMetadata, isNull);
    });

    test('write/read with null subjectId and topicId', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(SessionAdapter());
      final adapter = SessionAdapter();
      final now = DateTime(2025, 4, 1);
      final source = Session(
        id: 's6', studentId: 's1', startTime: now,
        subjectId: null, topicId: null,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.subjectId, isNull);
      expect(restored.topicId, isNull);
    });

    test('write/read with null plannedDurationMinutes', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(SessionAdapter());
      final adapter = SessionAdapter();
      final now = DateTime(2025, 4, 1);
      final source = Session(
        id: 's7', studentId: 's1', startTime: now,
        plannedDurationMinutes: null,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.plannedDurationMinutes, isNull);
    });

    test('write/read with empty lists', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(SessionAdapter());
      final adapter = SessionAdapter();
      final now = DateTime(2025, 4, 1);
      final source = Session(
        id: 's8', studentId: 's1', startTime: now,
        sourceIds: [], lessonIds: [], tags: [],
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.sourceIds, isEmpty);
      expect(restored.lessonIds, isEmpty);
      expect(restored.tags, isEmpty);
    });

    test('write/read for all SessionType values', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(SessionAdapter());
      final adapter = SessionAdapter();
      final now = DateTime(2025, 4, 1);

      for (final type in SessionType.values) {
        final source = Session(
          id: 's-type', studentId: 's1', startTime: now,
          type: type,
        );

        final writer = BinaryWriterImpl(registry);
        adapter.write(writer, source);
        final reader = BinaryReaderImpl(writer.toBytes(), registry);
        final restored = adapter.read(reader);

        expect(restored.type, type, reason: 'Failed for SessionType.${type.name}');
      }
    });

    test('write/read TutorMetadata with all fields null', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(SessionAdapter());
      final adapter = SessionAdapter();
      final now = DateTime(2025, 4, 1);
      final source = Session(
        id: 's9', studentId: 's1', startTime: now,
        tutorMetadata: TutorMetadata(
          topicTitle: null,
          lessonPlanJson: null,
          confidenceRating: 0,
          tutorNotes: null,
          topicsCovered: [],
          totalMessages: 0,
          totalTokensUsed: 0,
        ),
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.tutorMetadata!.topicTitle, isNull);
      expect(restored.tutorMetadata!.lessonPlanJson, isNull);
      expect(restored.tutorMetadata!.confidenceRating, 0);
      expect(restored.tutorMetadata!.tutorNotes, isNull);
      expect(restored.tutorMetadata!.topicsCovered, isEmpty);
      expect(restored.tutorMetadata!.totalMessages, 0);
      expect(restored.tutorMetadata!.totalTokensUsed, 0);
    });

    test('write/read with TutorMetadata empty topicsCovered', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(SessionAdapter());
      final adapter = SessionAdapter();
      final now = DateTime(2025, 4, 1);
      final source = Session(
        id: 's10', studentId: 's1', startTime: now,
        tutorMetadata: TutorMetadata(
          topicTitle: 'Test',
          topicsCovered: [],
        ),
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.tutorMetadata!.topicsCovered, isEmpty);
    });

    test('field order matches write sequence (toJson equality)', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(SessionAdapter());
      final adapter = SessionAdapter();
      final now = DateTime(2025, 6, 15);
      final source = Session(
        id: 'order-test',
        studentId: 'student',
        subjectId: null,
        topicId: null,
        type: SessionType.focus,
        startTime: now,
        endTime: null,
        plannedDurationMinutes: null,
        actualDurationMs: 0,
        questionsAnswered: 0,
        correctAnswers: 0,
        completed: false,
        sourceId: null,
        sourceIds: [],
        lessonIds: [],
        tags: [],
        createdAt: now,
        tutorMetadata: null,
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.id, source.id);
      expect(restored.studentId, source.studentId);
      expect(restored.type, source.type);
      expect(restored.startTime.millisecondsSinceEpoch, source.startTime.millisecondsSinceEpoch);
      expect(restored.createdAt.millisecondsSinceEpoch, source.createdAt.millisecondsSinceEpoch);
    });

    test('write/read with extreme numeric values', () {
      final registry = TypeRegistryImpl()
        ..registerAdapter(DateTimeWithTimezoneAdapter(), internal: true)
        ..registerAdapter(SessionAdapter());
      final adapter = SessionAdapter();
      final now = DateTime(2025, 4, 1);
      final source = Session(
        id: 's-extreme',
        studentId: 's1',
        startTime: now,
        endTime: now.add(const Duration(days: 365)),
        plannedDurationMinutes: 9999,
        actualDurationMs: 999999999,
        questionsAnswered: 999,
        correctAnswers: 0,
        completed: true,
        sourceIds: ['a', 'b', 'c', 'd', 'e'],
        lessonIds: ['l1'],
        tags: ['tag'],
        tutorMetadata: TutorMetadata(
          topicTitle: 'x' * 1000,
          confidenceRating: 5,
          totalMessages: 99999,
          totalTokensUsed: 999999999,
          topicsCovered: ['t1', 't2'],
        ),
      );

      final writer = BinaryWriterImpl(registry);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), registry);
      final restored = adapter.read(reader);

      expect(restored.plannedDurationMinutes, 9999);
      expect(restored.actualDurationMs, 999999999);
      expect(restored.questionsAnswered, 999);
      expect(restored.correctAnswers, 0);
      expect(restored.completed, isTrue);
      expect(restored.sourceIds, ['a', 'b', 'c', 'd', 'e']);
      expect(restored.lessonIds, ['l1']);
      expect(restored.tags, ['tag']);
      expect(restored.tutorMetadata!.topicTitle, 'x' * 1000);
      expect(restored.tutorMetadata!.confidenceRating, 5);
      expect(restored.tutorMetadata!.totalMessages, 99999);
      expect(restored.tutorMetadata!.totalTokensUsed, 999999999);
    });
  });
}
