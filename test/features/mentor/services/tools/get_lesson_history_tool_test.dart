import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/mentor/services/tools/get_lesson_history_tool.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'test_helpers.dart';

LessonBlock _block(String id, String lessonId) => LessonBlock(
      id: id,
      subjectId: 's1',
      lessonId: lessonId,
      type: LessonBlockType.text,
      content: 'content-$id',
      order: 1,
    );

Lesson _lesson(String id, DateTime createdAt, {int blocks = 1}) => Lesson(
      id: id,
      subjectId: 's1',
      title: 'Lesson $id',
      topicId: 't1',
      difficulty: 2,
      createdAt: createdAt,
      blocks: List.generate(
        blocks,
        (i) => _block('$id-b$i', id),
      ),
    );

void main() {
  group('GetLessonHistoryTool', () {
    late FakeStudentIdService studentIdService;
    late FakeLessonRepository lessonRepo;
    late FakeTutorSessionRepository sessionRepo;

    setUp(() {
      studentIdService = FakeStudentIdService('student-1');
      lessonRepo = FakeLessonRepository();
      sessionRepo = FakeTutorSessionRepository();
    });

    test('returns structured lesson data without content or performance',
        () async {
      lessonRepo = FakeLessonRepository([_lesson('l1', DateTime.now())]);
      final tool = GetLessonHistoryTool(
        lessonRepository: lessonRepo,
        tutorSessionRepository: sessionRepo,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({});

      final lessons = result['lessons'] as List;
      expect(lessons.length, equals(1));
      final first = lessons.first as Map<String, dynamic>;
      expect(first['id'], equals('l1'));
      expect(first['title'], equals('Lesson l1'));
      expect(first['subjectId'], equals('s1'));
      expect(first['topicId'], equals('t1'));
      expect(first['blocksCount'], equals(1));
      expect(first['blockTypes'], equals(['text']));
      expect(first['difficulty'], equals(2));
      expect(first.containsKey('performance'), isFalse);
      expect(first.containsKey('blocks'), isFalse);
    });

    test('includes performance when a tutor session is linked', () async {
      lessonRepo = FakeLessonRepository([_lesson('l1', DateTime.now())]);
      final session = TutorSession(
        id: 'sess1',
        studentId: 'student-1',
        subjectId: 's1',
        topicId: 't1',
        topicTitle: 'Topic',
        startTime: DateTime.now().subtract(const Duration(minutes: 10)),
        questionsAsked: 5,
        questionsCorrect: 4,
        tutorNotes: 'Good progress',
        lessonId: 'l1',
      );
      sessionRepo = FakeTutorSessionRepository([session]);

      final tool = GetLessonHistoryTool(
        lessonRepository: lessonRepo,
        tutorSessionRepository: sessionRepo,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({});
      final lessons = result['lessons'] as List;
      final first = lessons.first as Map<String, dynamic>;
      expect(first['performance'], isA<Map>());
      expect(first['performance']['questionsAsked'], equals(5));
      expect(first['performance']['questionsCorrect'], equals(4));
      expect(first['performance']['accuracy'], equals(0.8));
      expect(first['summary'], equals('Good progress'));
    });

    test('includes block content when includeContent is true', () async {
      lessonRepo = FakeLessonRepository([_lesson('l1', DateTime.now())]);
      final tool = GetLessonHistoryTool(
        lessonRepository: lessonRepo,
        tutorSessionRepository: sessionRepo,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({'includeContent': true});
      final lessons = result['lessons'] as List;
      final first = lessons.first as Map<String, dynamic>;
      final blocks = first['blocks'] as List;
      expect(blocks.length, equals(1));
      expect(blocks.first['content'], equals('content-l1-b0'));
    });

    test('filters by subjectId', () async {
      final other = _lesson('l2', DateTime.now())
          .copyWith(subjectId: 's2');
      lessonRepo = FakeLessonRepository([
        _lesson('l1', DateTime.now()),
        other,
      ]);
      final tool = GetLessonHistoryTool(
        lessonRepository: lessonRepo,
        tutorSessionRepository: sessionRepo,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({'subjectId': 's2'});
      final lessons = result['lessons'] as List;
      expect(lessons.length, equals(1));
      expect(lessons.first['id'], equals('l2'));
    });

    test('degrades gracefully when no lessons match', () async {
      final tool = GetLessonHistoryTool(
        lessonRepository: lessonRepo,
        tutorSessionRepository: sessionRepo,
        studentIdService: studentIdService,
      );

      final result = await tool.execute({});
      expect(result['lessons'], equals([]));
      expect(result['totalFound'], equals(0));
      expect(result['message'], contains('No lessons'));
    });
  });
}
