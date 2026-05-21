import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/teaching/data/adapters/tutor_session_adapter.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import '../../../../helpers/hive_test_utils.dart';

void main() {
  group('TutorSessionAdapter', () {
    test('has correct typeId', () {
      final adapter = TutorSessionAdapter();
      expect(adapter.typeId, 28);
    });

    test('is a TypeAdapter<TutorSession>', () {
      final adapter = TutorSessionAdapter();
      expect(adapter, isA<TypeAdapter<TutorSession>>());
    });

    test('read and write round-trips a TutorSession with all fields', () {
      final adapter = TutorSessionAdapter();
      final now = DateTime.utc(2024, 6, 15, 10, 30);
      final endTime = DateTime.utc(2024, 6, 15, 11, 45);
      final session = TutorSession(
        id: 'ts1',
        studentId: 'student1',
        subjectId: 'subj1',
        topicId: 'topic1',
        topicTitle: 'Linear Algebra',
        status: SessionStatus.completed,
        startTime: now,
        endTime: endTime,
        plannedDurationMinutes: 75,
        lessonPlanJson: '{"steps":[{"title":"Intro","duration":10}]}',
        questionsAsked: 10,
        questionsCorrect: 8,
        confidenceRating: 4,
        tutorNotes: 'Student understood concepts well',
        topicsCovered: ['matrices', 'vectors'],
        totalMessages: 30,
        totalTokensUsed: 5000,
        lessonId: 'lesson-1',
      );

      final writeCache = <int, dynamic>{};
      final writer = TestBinaryWriter(writeCache);
      adapter.write(writer, session);

      final reader = TestBinaryReader(writeCache);
      final restored = adapter.read(reader);

      expect(restored.id, session.id);
      expect(restored.studentId, session.studentId);
      expect(restored.subjectId, session.subjectId);
      expect(restored.topicId, session.topicId);
      expect(restored.topicTitle, session.topicTitle);
      expect(restored.status, session.status);
      expect(restored.startTime, session.startTime);
      expect(restored.endTime, session.endTime);
      expect(restored.plannedDurationMinutes, session.plannedDurationMinutes);
      expect(restored.lessonPlanJson, session.lessonPlanJson);
      expect(restored.questionsAsked, session.questionsAsked);
      expect(restored.questionsCorrect, session.questionsCorrect);
      expect(restored.confidenceRating, session.confidenceRating);
      expect(restored.tutorNotes, session.tutorNotes);
      expect(restored.topicsCovered, session.topicsCovered);
      expect(restored.totalMessages, session.totalMessages);
      expect(restored.totalTokensUsed, session.totalTokensUsed);
      expect(restored.lessonId, session.lessonId);
    });

    test('read and write round-trips with null endTime', () {
      final adapter = TutorSessionAdapter();
      final now = DateTime.utc(2024, 6, 15, 10, 0);
      final session = TutorSession(
        id: 'ts2',
        studentId: 'student1',
        subjectId: 'subj1',
        topicId: 'topic1',
        topicTitle: 'Calculus',
        startTime: now,
      );

      final writeCache = <int, dynamic>{};
      final writer = TestBinaryWriter(writeCache);
      adapter.write(writer, session);

      final reader = TestBinaryReader(writeCache);
      final restored = adapter.read(reader);

      expect(restored.id, session.id);
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
      expect(restored.lessonId, isNull);
    });

    test('read and write round-trips with null tutorNotes and no lessonId', () {
      final adapter = TutorSessionAdapter();
      final now = DateTime.utc(2024, 6, 15, 10, 0);
      final session = TutorSession(
        id: 'ts3',
        studentId: 'student1',
        subjectId: 'subj1',
        topicId: 'topic1',
        topicTitle: 'Geometry',
        status: SessionStatus.planned,
        startTime: now,
        tutorNotes: null,
        lessonId: null,
        topicsCovered: [],
      );

      final writeCache = <int, dynamic>{};
      final writer = TestBinaryWriter(writeCache);
      adapter.write(writer, session);

      final reader = TestBinaryReader(writeCache);
      final restored = adapter.read(reader);

      expect(restored.id, session.id);
      expect(restored.status, SessionStatus.planned);
      expect(restored.tutorNotes, isNull);
      expect(restored.lessonId, isNull);
      expect(restored.topicsCovered, isEmpty);
    });

    test('read and write round-trips with empty topicsCovered', () {
      final adapter = TutorSessionAdapter();
      final now = DateTime.utc(2024, 6, 15, 10, 0);
      final session = TutorSession(
        id: 'ts4',
        studentId: 'student1',
        subjectId: 'subj1',
        topicId: 'topic1',
        topicTitle: 'Algebra',
        startTime: now,
        topicsCovered: [],
      );

      final writeCache = <int, dynamic>{};
      final writer = TestBinaryWriter(writeCache);
      adapter.write(writer, session);

      final reader = TestBinaryReader(writeCache);
      final restored = adapter.read(reader);

      expect(restored.topicsCovered, isEmpty);
    });

    test('read and write round-trips with all SessionStatus values', () {
      final adapter = TutorSessionAdapter();
      final now = DateTime.utc(2024, 6, 15, 10, 0);

      for (final status in SessionStatus.values) {
        final session = TutorSession(
          id: 'ts-status',
          studentId: 'student1',
          subjectId: 'subj1',
          topicId: 'topic1',
          topicTitle: 'Test',
          status: status,
          startTime: now,
        );

        final writeCache = <int, dynamic>{};
        final writer = TestBinaryWriter(writeCache);
        adapter.write(writer, session);

        final reader = TestBinaryReader(writeCache);
        final restored = adapter.read(reader);

        expect(restored.status, status,
            reason: 'Failed for SessionStatus.${status.name}');
      }
    });
  });
}
