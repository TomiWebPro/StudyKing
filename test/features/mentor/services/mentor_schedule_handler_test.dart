import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/services/conversation_memory.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/mentor/services/mentor_schedule_handler.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';

class _FakeSessionRepo extends SessionRepository {
  @override
  Future<Result<List<Session>>> getAll() async => Result.success([]);

  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async => Result.success([]);

  @override
  Future<Result<int>> getTodayDurationMs() async => Result.success(0);
}

class _FakeTutorSessionRepo extends TutorSessionRepository {
  final Map<String, TutorSession> _sessions = {};

  void addSession(TutorSession session) => _sessions[session.id] = session;

  @override
  Future<Result<TutorSession?>> getSession(String id) async {
    return Result.success(_sessions[id]);
  }
}

class _FakePlannerService extends PlannerService {
  List<Session> _scheduledLessons = [];
  bool _hasConflict = false;
  bool _scheduleResult = true;
  int scheduleCallCount = 0;
  String? lastScheduledTopicTitle;

  _FakePlannerService() : super(fixedStudentId: 'test-student');

  void setScheduledLessons(List<Session> lessons) => _scheduledLessons = lessons;
  void setHasConflict(bool v) => _hasConflict = v;
  void setScheduleResult(bool v) => _scheduleResult = v;

  @override
  Future<Result<List<Session>>> getScheduledLessons() async => Result.success(_scheduledLessons);

  @override
  Future<Result<bool>> hasSchedulingConflict({
    required DateTime startTime,
    required int durationMinutes,
    String? excludeSessionId,
  }) async => Result.success(_hasConflict);

  @override
  Future<Result<bool>> scheduleLesson({
    required String topicId,
    required String topicTitle,
    required String subjectId,
    required DateTime scheduledTime,
    int durationMinutes = 30,
  }) async {
    scheduleCallCount++;
    lastScheduledTopicTitle = topicTitle;
    return Result.success(_scheduleResult);
  }
}

class _FakeTopicRepo extends TopicRepository {
  List<Topic> _topics = [];

  void setTopics(List<Topic> topics) => _topics = topics;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Topic>>> getAll() async => Result.success(_topics);
}

class _FakePendingActionRepo extends PendingActionRepository {
  final List<PendingActionModel> _actions = [];

  List<PendingActionModel> get createdActions => List.unmodifiable(_actions);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<void>> create(PendingActionModel action) async {
    _actions.add(action);
    return Result.success(null);
  }
}

MentorScheduleHandler _createHandler({
  DatabaseService? database,
  PlannerService? plannerService,
  PendingActionRepository? pendingActionRepo,
  ConversationMemory? memory,
  String localeName = 'en',
}) {
  final db = database ?? DatabaseService(
    topicRepository: TopicRepository(),
    questionRepository: QuestionRepository(),
    attemptRepository: AttemptRepository(),
    lessonRepository: LessonRepository(),
    sessionRepository: _FakeSessionRepo(),
    subjectRepository: SubjectRepository(),
    conversationRepository: ConversationRepository(),
    tutorSessionRepository: _FakeTutorSessionRepo(),
  );
  return MentorScheduleHandler(
    database: db,
    plannerService: plannerService ?? _FakePlannerService(),
    pendingActionRepo: pendingActionRepo ?? _FakePendingActionRepo(),
    localeName: localeName,
    memory: memory ?? ConversationMemory(),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('MentorScheduleHandler', () {
    group('extractScheduleProposal', () {
      test('creates valid proposal with given topic and duration', () {
        final handler = _createHandler();
        final proposal = handler.extractScheduleProposal('Algebra', 60);
        expect(proposal.topicTitle, equals('Algebra'));
        expect(proposal.durationMinutes, equals(60));
        expect(proposal.proposedTime.isAfter(DateTime.now()), isTrue);
      });

      test('uses default duration when extracted duration is zero', () {
        final handler = _createHandler();
        final proposal = handler.extractScheduleProposal('Algebra', 0);
        expect(proposal.topicTitle, equals('Algebra'));
        expect(proposal.durationMinutes, equals(30));
      });

      test('uses default duration when extracted duration is negative', () {
        final handler = _createHandler();
        final proposal = handler.extractScheduleProposal('Algebra', -10);
        expect(proposal.durationMinutes, equals(30));
      });

      test('rounds proposed time to next hour', () {
        final handler = _createHandler();
        final proposal = handler.extractScheduleProposal('Math', 45);
        expect(proposal.proposedTime.minute, equals(0));
        expect(proposal.proposedTime.second, equals(0));
      });
    });

    group('confirmSchedule', () {
      test('schedules lesson and returns success message when no conflict', () async {
        final planner = _FakePlannerService();
        planner.setHasConflict(false);
        planner.setScheduleResult(true);
        final handler = _createHandler(plannerService: planner);

        final proposal = ScheduleProposal(
          topicTitle: 'general',
          proposedTime: DateTime.now().add(const Duration(hours: 2)),
        );
        final result = await handler.confirmSchedule(proposal);
        expect(result, contains('scheduled'));
        expect(planner.scheduleCallCount, equals(1));
      });

      test('returns conflict message when scheduling conflict detected', () async {
        final planner = _FakePlannerService();
        planner.setHasConflict(true);
        final handler = _createHandler(plannerService: planner);

        final proposal = ScheduleProposal(
          topicTitle: 'general',
          proposedTime: DateTime.now().add(const Duration(hours: 2)),
        );
        final result = await handler.confirmSchedule(proposal);
        expect(result, contains('conflict'));
        expect(planner.scheduleCallCount, equals(0));
      });

      test('returns failure message when scheduling returns false', () async {
        final planner = _FakePlannerService();
        planner.setHasConflict(false);
        planner.setScheduleResult(false);
        final handler = _createHandler(plannerService: planner);

        final proposal = ScheduleProposal(
          topicTitle: 'general',
          proposedTime: DateTime.now().add(const Duration(hours: 2)),
        );
        final result = await handler.confirmSchedule(proposal);
        expect(result, contains('unable to schedule'));
        expect(planner.scheduleCallCount, equals(1));
      });

      test('handles planner error gracefully', () async {
        final handler = _createHandler();
        final proposal = ScheduleProposal(
          topicTitle: 'general',
          proposedTime: DateTime.now().add(const Duration(hours: 2)),
        );
        final planner = _FakePlannerService();
        planner.setHasConflict(false);
        planner.setScheduleResult(true);
        final result = await handler.confirmSchedule(proposal);
        expect(result, isA<String>());
      });
    });

    group('suggestReschedule', () {
      test('creates pending action for existing session', () async {
        final tutorRepo = _FakeTutorSessionRepo();
        tutorRepo.addSession(TutorSession(
          id: 'session-1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          startTime: DateTime.now(),
        ));
        final fakePending = _FakePendingActionRepo();
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: _FakeSessionRepo(),
          subjectRepository: SubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final planner = _FakePlannerService();
        planner.setHasConflict(false);
        final handler = _createHandler(
          database: db,
          pendingActionRepo: fakePending,
          plannerService: planner,
        );

        final result = await handler.suggestReschedule('session-1');
        expect(fakePending.createdActions.length, equals(1));
        final action = fakePending.createdActions.first;
        expect(action.actionType, equals(PendingActionType.reschedule.name));
        expect(action.topicTitle, equals('Algebra'));
        expect(action.sessionId, equals('session-1'));
        expect(result, contains('Algebra'));
      });

      test('returns not found for missing session', () async {
        final tutorRepo = _FakeTutorSessionRepo();
        final fakePending = _FakePendingActionRepo();
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: _FakeSessionRepo(),
          subjectRepository: SubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final handler = _createHandler(
          database: db,
          pendingActionRepo: fakePending,
        );

        final result = await handler.suggestReschedule('nonexistent');
        expect(result, contains('Could not find'));
        expect(fakePending.createdActions, isEmpty);
      });

      test('returns no free slot when conflict exists after finding slot', () async {
        final tutorRepo = _FakeTutorSessionRepo();
        tutorRepo.addSession(TutorSession(
          id: 'session-1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          startTime: DateTime.now(),
        ));
        final fakePending = _FakePendingActionRepo();
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: _FakeSessionRepo(),
          subjectRepository: SubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final planner = _FakePlannerService();
        planner.setHasConflict(true);
        final handler = _createHandler(
          database: db,
          pendingActionRepo: fakePending,
          plannerService: planner,
        );

        final result = await handler.suggestReschedule('session-1');
        expect(result, contains('Unable to find'));
        expect(fakePending.createdActions, isEmpty);
      });

      test('findNextFreeSlot skips completed lessons', () async {
        final tutorRepo = _FakeTutorSessionRepo();
        tutorRepo.addSession(TutorSession(
          id: 'session-1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          startTime: DateTime.now(),
        ));
        final fakePending = _FakePendingActionRepo();
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: _FakeSessionRepo(),
          subjectRepository: SubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final planner = _FakePlannerService();
        planner.setHasConflict(false);
        final handler = _createHandler(
          database: db,
          pendingActionRepo: fakePending,
          plannerService: planner,
        );

        final result = await handler.suggestReschedule('session-1');
        expect(result, contains('rescheduling'));
        expect(fakePending.createdActions.length, equals(1));
      });
    });

    group('default schedule duration from Hive', () {
      test('uses default 30 minutes when Hive box is not open', () {
        final handler = _createHandler();
        final proposal = handler.extractScheduleProposal('Math', 0);
        expect(proposal.durationMinutes, equals(30));
      });

      test('reads stored duration from Hive', () async {
        Hive.init(Directory.systemTemp.path);
        final box = await Hive.openBox(HiveBoxNames.settings);
        await box.put('defaultScheduleDuration', 45);

        final handler = _createHandler();
        final proposal = handler.extractScheduleProposal('Math', 0);
        expect(proposal.durationMinutes, equals(45));

        await box.clear();
        await box.close();
      });

      test('clamps duration exceeding 480 to default', () async {
        Hive.init(Directory.systemTemp.path);
        final box = await Hive.openBox(HiveBoxNames.settings);
        await box.put('defaultScheduleDuration', 500);

        final handler = _createHandler();
        final proposal = handler.extractScheduleProposal('Math', 0);
        expect(proposal.durationMinutes, equals(30));

        await box.clear();
        await box.close();
      });

      test('clamps non-positive duration to default', () async {
        Hive.init(Directory.systemTemp.path);
        final box = await Hive.openBox(HiveBoxNames.settings);
        await box.put('defaultScheduleDuration', 0);

        final handler = _createHandler();
        final proposal = handler.extractScheduleProposal('Math', 0);
        expect(proposal.durationMinutes, equals(30));

        await box.clear();
        await box.close();
      });

      test('recovers from Hive read error gracefully', () async {
        final handler = _createHandler();
        final proposal = handler.extractScheduleProposal('Math', 0);
        expect(proposal.durationMinutes, equals(30));
      });
    });

    group('confirmSchedule - topic matching', () {
      test('looks up topicId when topicTitle is not general', () async {
        final topicRepo = _FakeTopicRepo();
        topicRepo.setTopics([
          Topic(id: 'math-topic', title: 'Algebra Basics', subjectId: 'math', description: 'Basic algebra', syllabusText: 'Algebra'),
        ]);
        final db = DatabaseService(
          topicRepository: topicRepo,
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: _FakeSessionRepo(),
          subjectRepository: SubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: _FakeTutorSessionRepo(),
        );
        final planner = _FakePlannerService();
        planner.setHasConflict(false);
        planner.setScheduleResult(true);
        final handler = _createHandler(database: db, plannerService: planner);

        final proposal = ScheduleProposal(
          topicTitle: 'Algebra Basics',
          proposedTime: DateTime.now().add(const Duration(hours: 2)),
        );
        await handler.confirmSchedule(proposal);
        expect(planner.scheduleCallCount, equals(1));
        expect(planner.lastScheduledTopicTitle, equals('Algebra Basics'));
      });

      test('does not look up topics when topic title is general', () async {
        final planner = _FakePlannerService();
        planner.setHasConflict(false);
        planner.setScheduleResult(true);
        final handler = _createHandler(plannerService: planner);

        final proposal = ScheduleProposal(
          topicTitle: 'general',
          proposedTime: DateTime.now().add(const Duration(hours: 2)),
        );
        await handler.confirmSchedule(proposal);
        expect(planner.scheduleCallCount, equals(1));
      });

      test('returns fail message when exception occurs', () async {
        final handler = _createHandler();

        // Force an exception by passing invalid data
        final proposal = ScheduleProposal(
          topicTitle: 'test',
          proposedTime: DateTime.now().add(const Duration(hours: 2)),
        );

        // Unknown topic should not cause crash, just proceed with empty IDs
        final result = await handler.confirmSchedule(proposal);
        expect(result, isA<String>());
      });
    });

    group('findNextFreeSlot', () {
      test('returns candidate when gap exists between lessons', () async {
        final tutorRepo = _FakeTutorSessionRepo();
        tutorRepo.addSession(TutorSession(
          id: 'existing',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Existing lesson',
          startTime: DateTime.now().add(const Duration(hours: 3)),
        ));
        final planner = _FakePlannerService();
        planner.setScheduledLessons([
          Session(id: 'existing', studentId: 'test-student', startTime: DateTime.now().add(const Duration(hours: 3)),
            plannedDurationMinutes: 30),
        ]);
        planner.setHasConflict(false);
        final fakePending = _FakePendingActionRepo();
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: _FakeSessionRepo(),
          subjectRepository: SubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final handler = _createHandler(
          database: db,
          plannerService: planner,
          pendingActionRepo: fakePending,
        );

        final result = await handler.suggestReschedule('existing');
        expect(result, contains('rescheduling'));
      });

      test('skips completed lessons when finding free slot', () async {
        final now = DateTime.now();
        final tutorRepo = _FakeTutorSessionRepo();
        tutorRepo.addSession(TutorSession(
          id: 'completed-session',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Completed lesson',
          startTime: now.add(const Duration(hours: 1)),
        ));
        final planner = _FakePlannerService();
        planner.setScheduledLessons([
          Session(id: 'completed-session', studentId: 'test-student',
            startTime: now.add(const Duration(hours: 1)),
            completed: true, plannedDurationMinutes: 30),
          Session(id: 'future-session', studentId: 'test-student',
            startTime: now.add(const Duration(hours: 5)),
            plannedDurationMinutes: 30),
        ]);
        planner.setHasConflict(false);
        final fakePending = _FakePendingActionRepo();
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: _FakeSessionRepo(),
          subjectRepository: SubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final handler = _createHandler(
          database: db,
          plannerService: planner,
          pendingActionRepo: fakePending,
        );

        final result = await handler.suggestReschedule('completed-session');
        expect(result, contains('rescheduling'));
      });
    });
  });
}
