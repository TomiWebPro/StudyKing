import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/features/mentor/services/tools/get_lesson_history_tool.dart';
import '../../../../helpers/fakes.dart';

class FakeLessonRepository extends LessonRepository {
  final List<Lesson> _lessons = [];

  void addLesson(Lesson lesson) => _lessons.add(lesson);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Lesson>>> getAll() async =>
      Result.success(List.from(_lessons));

  @override
  Future<Result<List<Lesson>>> getBySubject(String subjectId) async =>
      Result.success(_lessons.where((l) => l.subjectId == subjectId).toList());

  @override
  Future<Result<List<Lesson>>> getByTopic(String topicId) async =>
      Result.success(_lessons.where((l) => l.topicId == topicId).toList());

  @override
  Future<Result<List<Lesson>>> getBySubjectAndTopic(
          String subjectId, String topicId) async =>
      Result.success(_lessons
          .where((l) => l.subjectId == subjectId && l.topicId == topicId)
          .toList());
}

class FakeTutorSessionRepositoryForLessonHistory extends TutorSessionRepository {
  final List<TutorSession> _sessions = [];

  void addSession(TutorSession session) => _sessions.add(session);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<TutorSession>>> getAllSessions() async =>
      Result.success(List.from(_sessions));

  @override
  Future<Result<List<TutorSession>>> getStudentSessions(
          String studentId) async =>
      Result.success(
          _sessions.where((s) => s.studentId == studentId).toList());
}

Lesson _createLesson({
  String id = 'lesson-1',
  String subjectId = 'subj-1',
  String topicId = 'topic-1',
  String title = 'Test Lesson',
  DateTime? createdAt,
  List<LessonBlock>? blocks,
}) {
  return Lesson(
    id: id,
    subjectId: subjectId,
    title: title,
    topicId: topicId,
    createdAt: createdAt ?? DateTime.now(),
    blocks: blocks ?? [
      LessonBlock(
        id: 'block-1',
        subjectId: subjectId,
        lessonId: id,
        type: LessonBlockType.text,
        content: 'Test content',
        order: 0,
      ),
    ],
  );
}

TutorSession _createSession({
  String id = 'session-1',
  String lessonId = 'lesson-1',
  int questionsAsked = 5,
  int questionsCorrect = 3,
  String? tutorNotes,
}) {
  return TutorSession(
    id: id,
    studentId: 'student-1',
    subjectId: 'subj-1',
    topicId: 'topic-1',
    topicTitle: 'Test Topic',
    startTime: DateTime.now(),
    lessonId: lessonId,
    questionsAsked: questionsAsked,
    questionsCorrect: questionsCorrect,
    tutorNotes: tutorNotes,
  );
}

void main() {
  group('GetLessonHistoryTool', () {
    late FakeLessonRepository fakeLessonRepo;
    late FakeTutorSessionRepositoryForLessonHistory fakeTutorSessionRepo;
    late FakeStudentIdService fakeStudentId;
    late GetLessonHistoryTool tool;

    setUp(() {
      fakeLessonRepo = FakeLessonRepository();
      fakeTutorSessionRepo = FakeTutorSessionRepositoryForLessonHistory();
      fakeStudentId = FakeStudentIdService()..setStudentId('student-1');
      tool = GetLessonHistoryTool(
        lessonRepository: fakeLessonRepo,
        tutorSessionRepository: fakeTutorSessionRepo,
        studentIdService: fakeStudentId,
      );
    });

    test('name returns get_lesson_history', () {
      expect(tool.name, 'get_lesson_history');
    });

    test('description is not empty', () {
      expect(tool.description, isNotEmpty);
    });

    test('parameters has correct JSON schema shape', () {
      final params = tool.parameters;
      expect(params['type'], 'object');
      expect(params['properties'], isA<Map>());
      expect(params['required'], []);
    });

    test('execute returns empty list when no lessons exist', () async {
      final result = await tool.execute({});

      expect(result['lessons'], isEmpty);
      expect(result['totalFound'], 0);
    });

    test('execute returns lessons sorted by date descending', () async {
      final lesson1 = _createLesson(
        id: 'lesson-1',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      );
      final lesson2 = _createLesson(
        id: 'lesson-2',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      fakeLessonRepo.addLesson(lesson1);
      fakeLessonRepo.addLesson(lesson2);

      final result = await tool.execute({});

      expect(result['lessons'], hasLength(2));
      expect(result['lessons'][0]['id'], 'lesson-2');
      expect(result['lessons'][1]['id'], 'lesson-1');
    });

    test('execute respects limit parameter', () async {
      for (var i = 0; i < 10; i++) {
        fakeLessonRepo.addLesson(_createLesson(
          id: 'lesson-$i',
          createdAt: DateTime.now().subtract(Duration(days: i)),
        ));
      }

      final result = await tool.execute({'limit': 3});

      expect(result['lessons'], hasLength(3));
    });

    test('execute filters by subjectId', () async {
      fakeLessonRepo.addLesson(_createLesson(
        id: 'lesson-1',
        subjectId: 'subj-math',
      ));
      fakeLessonRepo.addLesson(_createLesson(
        id: 'lesson-2',
        subjectId: 'subj-science',
      ));

      final result = await tool.execute({'subjectId': 'subj-math'});

      expect(result['lessons'], hasLength(1));
      expect(result['lessons'][0]['subjectId'], 'subj-math');
    });

    test('execute filters by topicId', () async {
      fakeLessonRepo.addLesson(_createLesson(
        id: 'lesson-1',
        topicId: 'topic-algebra',
      ));
      fakeLessonRepo.addLesson(_createLesson(
        id: 'lesson-2',
        topicId: 'topic-geometry',
      ));

      final result = await tool.execute({'topicId': 'topic-algebra'});

      expect(result['lessons'], hasLength(1));
      expect(result['lessons'][0]['topicId'], 'topic-algebra');
    });

    test('execute filters by both subjectId and topicId', () async {
      fakeLessonRepo.addLesson(_createLesson(
        id: 'lesson-1',
        subjectId: 'subj-math',
        topicId: 'topic-algebra',
      ));
      fakeLessonRepo.addLesson(_createLesson(
        id: 'lesson-2',
        subjectId: 'subj-math',
        topicId: 'topic-geometry',
      ));
      fakeLessonRepo.addLesson(_createLesson(
        id: 'lesson-3',
        subjectId: 'subj-science',
        topicId: 'topic-algebra',
      ));

      final result = await tool.execute({
        'subjectId': 'subj-math',
        'topicId': 'topic-algebra',
      });

      expect(result['lessons'], hasLength(1));
      expect(result['lessons'][0]['id'], 'lesson-1');
    });

    test('execute filters by daysBack', () async {
      fakeLessonRepo.addLesson(_createLesson(
        id: 'lesson-recent',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ));
      fakeLessonRepo.addLesson(_createLesson(
        id: 'lesson-old',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ));

      final result = await tool.execute({'daysBack': 30});

      expect(result['lessons'], hasLength(1));
      expect(result['lessons'][0]['id'], 'lesson-recent');
    });

    test('execute includes performance when session exists', () async {
      fakeLessonRepo.addLesson(_createLesson(id: 'lesson-1'));
      fakeTutorSessionRepo.addSession(_createSession(
        lessonId: 'lesson-1',
        questionsAsked: 10,
        questionsCorrect: 7,
      ));

      final result = await tool.execute({});

      expect(result['lessons'][0]['performance'], isNotNull);
      expect(result['lessons'][0]['performance']['questionsAsked'], 10);
      expect(result['lessons'][0]['performance']['questionsCorrect'], 7);
      expect(result['lessons'][0]['performance']['accuracy'], 0.7);
    });

    test('execute omits performance when no session exists', () async {
      fakeLessonRepo.addLesson(_createLesson(id: 'lesson-1'));

      final result = await tool.execute({});

      expect(result['lessons'][0]['performance'], isNull);
    });

    test('execute includes summary from tutorNotes', () async {
      fakeLessonRepo.addLesson(_createLesson(id: 'lesson-1'));
      fakeTutorSessionRepo.addSession(_createSession(
        lessonId: 'lesson-1',
        tutorNotes: 'Covered basic integration rules',
      ));

      final result = await tool.execute({});

      expect(result['lessons'][0]['summary'], 'Covered basic integration rules');
    });

    test('execute does not include summary when tutorNotes is null', () async {
      fakeLessonRepo.addLesson(_createLesson(id: 'lesson-1'));
      fakeTutorSessionRepo.addSession(_createSession(
        lessonId: 'lesson-1',
        tutorNotes: null,
      ));

      final result = await tool.execute({});

      expect(result['lessons'][0].containsKey('summary'), isFalse);
    });

    test('execute includes block types', () async {
      final blocks = [
        LessonBlock(
          id: 'block-1',
          subjectId: 'subj-1',
          lessonId: 'lesson-1',
          type: LessonBlockType.text,
          content: 'content',
          order: 0,
        ),
        LessonBlock(
          id: 'block-2',
          subjectId: 'subj-1',
          lessonId: 'lesson-1',
          type: LessonBlockType.quiz,
          content: 'quiz',
          order: 1,
        ),
      ];
      fakeLessonRepo.addLesson(_createLesson(id: 'lesson-1', blocks: blocks));

      final result = await tool.execute({});

      expect(result['lessons'][0]['blockTypes'], containsAll(['text', 'quiz']));
    });

    test('execute does not include content blocks by default', () async {
      fakeLessonRepo.addLesson(_createLesson(id: 'lesson-1'));

      final result = await tool.execute({});

      expect(result['lessons'][0].containsKey('blocks'), isFalse);
    });

    test('execute includes content blocks when includeContent is true', () async {
      fakeLessonRepo.addLesson(_createLesson(id: 'lesson-1'));

      final result = await tool.execute({'includeContent': true});

      expect(result['lessons'][0]['blocks'], isA<List>());
      expect(result['lessons'][0]['blocks'], hasLength(1));
      expect(result['lessons'][0]['blocks'][0]['content'], 'Test content');
    });

    test('execute returns correct totalFound count', () async {
      fakeLessonRepo.addLesson(_createLesson(id: 'lesson-1'));
      fakeLessonRepo.addLesson(_createLesson(id: 'lesson-2'));

      final result = await tool.execute({});

      expect(result['totalFound'], 2);
    });

    test('execute returns message when no lessons found', () async {
      final result = await tool.execute({});

      expect(result['message'], isNotNull);
      expect(result['message'], contains('No lessons found'));
    });
  });
}
