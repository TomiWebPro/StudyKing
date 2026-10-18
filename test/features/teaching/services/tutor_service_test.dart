import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/teaching/services/conversation_phase.dart';
import 'package:studyking/features/teaching/services/exercise_evaluator.dart';
import 'package:studyking/features/teaching/services/tutor_service.dart';
import 'package:studyking/features/teaching/data/models/evaluation_result.dart';
import 'package:uuid/uuid.dart';
import 'package:studyking/features/mentor/services/tools/pre_generate_lesson_tool.dart';
import 'package:studyking/features/lessons/services/lesson_agent_service.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/services/planner_service.dart';

final _logger = Logger('TutorServiceTest');

class FakeConversationRepository extends ConversationRepository {
  final List<ConversationMessage> _messages = [];

  @override
  Future<Result<void>> saveMessage(ConversationMessage message) async {
    _messages.add(message);
    return Result.success(null);
  }

  @override
  Future<Result<List<ConversationMessage>>> getSessionMessages(String sessionId) async {
    return Result.success(_messages.where((m) => m.sessionId == sessionId).toList());
  }
}

class FakeTutorSessionRepository extends TutorSessionRepository {
  final List<TutorSession> _sessions = [];

  @override
  Future<Result<void>> saveSession(TutorSession session) async {
    _sessions.add(session);
    return Result.success(null);
  }

  @override
  Future<Result<List<TutorSession>>> getStudentSessions(String studentId) async {
    return Result.success(_sessions.where((s) => s.studentId == studentId).toList());
  }

  @override
  Future<Result<Map<String, dynamic>>> getSessionStats(String studentId) async {
    final sessionsResult = await getStudentSessions(studentId);
    final sessions = sessionsResult.data!;
    final completed = sessions.where((s) => s.status == SessionStatus.completed);
    return Result.success({
      'totalSessions': sessions.length,
      'completedSessions': completed.length,
      'totalHours': completed.fold<double>(0, (sum, s) => sum + (s.startTime.difference(s.startTime).inMinutes / 60.0)),
      'totalQuestions': completed.fold<int>(0, (sum, s) => sum + s.questionsAsked),
      'averageAccuracy': completed.isEmpty
          ? 0.0
          : completed.fold<double>(0, (sum, s) => sum + s.accuracy) / completed.length,
    });
  }

  @override
  Future<Result<List<TutorSession>>> getActiveSessions() async {
    return Result.success(_sessions.where((s) => s.status == SessionStatus.inProgress).toList());
  }
}

class FakeLlmService extends LlmService {
  bool _shouldThrowOnChat = false;

  FakeLlmService()
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: '',
          ),
        );

  void setThrowOnChat() => _shouldThrowOnChat = true;

  @override
  Future<Result<String>> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async {
    if (_shouldThrowOnChat) throw Exception('LLM failure');
    return Result.success('{"goals":["Learn"],"sections":[{"title":"Intro","duration":10,"type":"explanation"}],"checkpoints":["ck"],"estimatedDifficulty":2}');
  }

  @override
  Stream<String> chatStream({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async* {
    yield 'Tutor response';
  }
}

class FakeExerciseEvaluator extends ExerciseEvaluator {
  double score;

  FakeExerciseEvaluator({this.score = 0.8})
      : super(
          llmService: FakeLlmService(),
          modelId: 'test-model',
          localeName: 'en',
        );

  @override
  Future<Result<EvaluationResult>> evaluate({
    required String question,
    required String studentAnswer,
    required String subjectId,
    required String topicTitle,
    String? systemPrompt,
    String? userPrompt,
  }) async {
    return Result.success(EvaluationResult(score: score, explanation: 'Good job.'));
  }
}

class FakePlanAdherenceOrchestrator extends PlanAdherenceOrchestrator {
  bool recordActivityCalled = false;
  String? lastStudentId;
  int? lastActualMinutes;
  int? lastActualQuestions;

  FakePlanAdherenceOrchestrator() : super();

  @override
  Future<Result<void>> recordActivity({
    required String studentId,
    required int actualMinutes,
    int actualQuestions = 0,
    String? planId,
  }) async {
    recordActivityCalled = true;
    lastStudentId = studentId;
    lastActualMinutes = actualMinutes;
    lastActualQuestions = actualQuestions;
    return Result.success(null);
  }
}

class FakeMasteryGraphService extends MasteryGraphService {
  final List<Map<String, dynamic>> recordedAttempts = [];
  List<MasteryState> weakTopicsToReturn = [];

  FakeMasteryGraphService();

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(
    String studentId, {
    String? subjectId,
  }) async {
    return Result.success(List<MasteryState>.from(weakTopicsToReturn));
  }

  @override
  Future<Result<void>> recordAttempt({
    required String studentId,
    required String topicId,
    required String questionId,
    required bool isCorrect,
    required int confidence,
    required int timeSpentMs,
    String? subjectId,
    String? subtopicId,
  }) async {
    recordedAttempts.add({
      'studentId': studentId,
      'topicId': topicId,
      'questionId': questionId,
      'isCorrect': isCorrect,
      'confidence': confidence,
      'timeSpentMs': timeSpentMs,
    });
    return Result.success(null);
  }
}

/// Hand-written fake of [PlannerService] that returns a fixed plan from
/// [loadExistingPlan] without touching Hive. Used to assert that
/// [TutorService.startLesson] forwards the student's syllabus goals to the
/// [ConversationManager] (teaching-syllabus-context solidification).
class FakePlannerService extends PlannerService {
  PersonalLearningPlan? plan;

  FakePlannerService([this.plan])
      : super(
          planOrchestrator: FakePlanAdherenceOrchestrator(),
          fixedStudentId: 'student-1',
        );

  @override
  Future<Result<PersonalLearningPlan?>> loadExistingPlan() async =>
      Result.success(plan);
}

class FixedClock extends Clock {
  final DateTime fixedTime;
  FixedClock(this.fixedTime);

  @override
  DateTime now() => fixedTime;
}

class FakeQuestionRepository extends QuestionRepository {
  final List<Question> _createdQuestions = [];

  List<Question> get createdQuestions => List.unmodifiable(_createdQuestions);

  @override
  Future<Result<void>> create(Question question) async {
    _createdQuestions.add(question);
    return Result.success(null);
  }
}

class FakeFailingLessonRepository extends LessonRepository {
  @override
  Future<Result<void>> create(Lesson lesson) async {
    return Result.failure('lesson box unavailable');
  }
}

class FakeSessionRepository extends SessionRepository {
  final List<Session> _savedSessions = [];

  List<Session> get savedSessions => List.unmodifiable(_savedSessions);

  @override
  @override
  Future<Result<void>> save(String key, Session session) async {
    _savedSessions.add(session);
    return Result.success(null);
  }

  @override
  Future<Result<List<Session>>> getAll() async {
    return Result.success(List.from(_savedSessions));
  }
}

class FakeSpacedRepetitionService extends SpacedRepetitionService {
  FakeSpacedRepetitionService()
      : super(
          questionRepo: QuestionRepository(),
          attemptRepo: AttemptRepository(),
        );

  @override
  Future<Result<List<Question>>> getTopicTimeDue(String topicId) async {
    return Result.success([]);
  }
}

class _TestLessonAdapter extends TypeAdapter<Lesson> {
  @override
  final int typeId = 7;

  @override
  Lesson read(BinaryReader reader) {
    final raw = reader.read() as Map;
    final map = <String, dynamic>{};
    for (final entry in raw.entries) {
      map['${entry.key}'] = entry.value;
    }
    return Lesson.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, Lesson obj) {
    writer.write(obj.toJson());
  }
}

class _TestLessonBlockAdapter extends TypeAdapter<LessonBlock> {
  @override
  final int typeId = 6;

  @override
  LessonBlock read(BinaryReader reader) {
    final raw = reader.read() as Map;
    final map = <String, dynamic>{};
    for (final entry in raw.entries) {
      map['${entry.key}'] = entry.value;
    }
    return LessonBlock.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, LessonBlock obj) {
    writer.write(obj.toJson());
  }
}

/// Mutable fake [LessonRepository] that captures created lessons for
/// inspection in tests — overrides persist calls instead of touching Hive.
class FakeLessonRepository extends LessonRepository {
  final List<Lesson> _created = [];

  List<Lesson> get createdLessons => List.unmodifiable(_created);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<void>> create(Lesson lesson) async {
    _created.add(lesson);
    return Result.success(null);
  }

  @override
  Future<Result<Lesson?>> get(String id) async {
    final matches = _created.where((l) => l.id == id);
    return Result.success(matches.isNotEmpty ? matches.first : null);
  }

  @override
  Future<Result<List<Lesson>>> getAll() async =>
      Result.success(List.from(_created));
}

/// Minimal LessonAgentService needed only to satisfy the
/// [PreGenerateLessonTool] constructor requirement — never invoked because
/// [FakePreGenerateLessonTool] overrides [execute].
class _FakeLessonAgentService extends LessonAgentService {
  _FakeLessonAgentService()
      : super(
          llmService: LlmService(
            config: const LlmConfiguration(
              provider: LlmProvider.openAI,
              apiKey: 'test',
            ),
          ),
          modelId: 'test',
          lessonRepository: LessonRepository(),
          database: DatabaseService(
            topicRepository: TopicRepository(),
            questionRepository: QuestionRepository(),
            attemptRepository: AttemptRepository(),
            lessonRepository: LessonRepository(),
            sessionRepository: SessionRepository(),
            subjectRepository: SubjectRepository(),
            conversationRepository: ConversationRepository(),
            tutorSessionRepository: TutorSessionRepository(),
          ),
        );
}

/// Fake [PreGenerateLessonTool] that overrides [execute] to produce a real
/// lesson with multiple block types (slides, examples, exercises, quizzes,
/// summary) and persist it to the provided [FakeLessonRepository].
///
/// Mirrors the contract of the real tool — returns a result map with
/// `success`, `lessonId`, `blockCount`, and `title` — but without any LLM
/// calls, budget checks, or task-manager involvement.
class FakePreGenerateLessonTool extends PreGenerateLessonTool {
  final FakeLessonRepository lessonRepository;
  final List<Map<String, dynamic>> executedArgs = [];

  FakePreGenerateLessonTool({
    required this.lessonRepository,
  }) : super(lessonAgentService: _FakeLessonAgentService());

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    executedArgs.add(Map<String, dynamic>.from(args));

    final subjectId = args['subjectId'] as String? ?? '';
    final topicId = args['topicId'] as String? ?? '';
    final topicTitle = args['topicTitle'] as String? ?? '';

    final lesson = Lesson(
      id: const Uuid().v4(),
      subjectId: subjectId,
      title: topicTitle,
      topicId: topicId,
      blocks: [
        LessonBlock(
          id: const Uuid().v4(),
          subjectId: subjectId,
          lessonId: '',
          type: LessonBlockType.text,
          content: 'Introduction to $topicTitle',
          order: 0,
        ),
        LessonBlock(
          id: const Uuid().v4(),
          subjectId: subjectId,
          lessonId: '',
          type: LessonBlockType.slide,
          content: 'Key concepts: $topicTitle',
          order: 1,
        ),
        LessonBlock(
          id: const Uuid().v4(),
          subjectId: subjectId,
          lessonId: '',
          type: LessonBlockType.example,
          content: 'Worked example for $topicTitle',
          order: 2,
        ),
        LessonBlock(
          id: const Uuid().v4(),
          subjectId: subjectId,
          lessonId: '',
          type: LessonBlockType.exercise,
          content: 'Practice problem on $topicTitle',
          answerKey: 'Correct answer',
          order: 3,
        ),
        LessonBlock(
          id: const Uuid().v4(),
          subjectId: subjectId,
          lessonId: '',
          type: LessonBlockType.quiz,
          content: 'Quiz: what is $topicTitle?',
          order: 4,
        ),
        LessonBlock(
          id: const Uuid().v4(),
          subjectId: subjectId,
          lessonId: '',
          type: LessonBlockType.summary,
          content: 'Recap of $topicTitle',
          order: 5,
        ),
      ],
      generatedBy: GeneratedBy.ai,
      createdAt: DateTime.now(),
    );

    await lessonRepository.init();
    await lessonRepository.create(lesson);

    return {
      'success': true,
      'lessonId': lesson.id,
      'blockCount': lesson.blocks.length,
      'title': lesson.title,
    };
  }
}

void main() {
  setUpAll(() {
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(_TestLessonAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(_TestLessonBlockAdapter());
    }
  });

  group('TutorService', () {
    late String hivePath;
    late FakeConversationRepository conversationRepo;
    late FakeTutorSessionRepository tutorSessionRepo;
    late FakeQuestionRepository fakeQuestionRepo;
    late FakeSessionRepository fakeSessionRepo;
    late DatabaseService database;
    late FakeLlmService llmService;
    late FakeMasteryGraphService masteryService;
    late FakeExerciseEvaluator exerciseEvaluator;
    late TutorService tutorService;

    setUp(() async {
      hivePath = (await Directory.systemTemp.createTemp('tutor_svc_test_')).path;
      Hive.init(hivePath);
      conversationRepo = FakeConversationRepository();
      tutorSessionRepo = FakeTutorSessionRepository();
      fakeQuestionRepo = FakeQuestionRepository();
      fakeSessionRepo = FakeSessionRepository();
      database = DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: fakeQuestionRepo,
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: fakeSessionRepo,
        subjectRepository: SubjectRepository(),
        conversationRepository: conversationRepo,
        tutorSessionRepository: tutorSessionRepo,
      );
      llmService = FakeLlmService();
      masteryService = FakeMasteryGraphService();
      exerciseEvaluator = FakeExerciseEvaluator();
      final srService = FakeSpacedRepetitionService();
      tutorService = TutorService(
        database: database,
        llmService: llmService,
        masteryService: masteryService,
        spacedRepetitionService: srService,
        modelId: 'test-model',
        exerciseEvaluator: exerciseEvaluator,
        conversationRepository: conversationRepo,
        planOrchestrator: FakePlanAdherenceOrchestrator(),
      );
    });

    tearDown(() async {
      try {
        await Hive.close();
      } catch (e, st) {
        _logger.w('Cleanup failed on Hive.close: $e', e, st);
      }
      if (hivePath.isNotEmpty) {
        try {
          await Directory(hivePath).delete(recursive: true);
        } catch (e, st) {
          _logger.w('Cleanup failed on Directory.delete: $e', e, st);
        }
      }
    });

    group('initial state', () {
      test('currentManager is null initially', () {
        expect(tutorService.currentManager, isNull);
      });
    });

    group('startLesson', () {
      test('creates a ConversationManager and saves session', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          durationMinutes: 45,
          localeName: 'en',
        );

        expect(tutorService.currentManager, equals(manager));
        expect(manager.sessionId, startsWith('tutor_'));
        expect(manager.studentId, equals('student-1'));
      });

      test('saves session to repository', () async {
        await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          durationMinutes: 30,
          localeName: 'en',
        );

        expect(tutorSessionRepo._sessions.length, greaterThan(0));
        final saved = tutorSessionRepo._sessions.first;
        expect(saved.studentId, equals('student-1'));
        expect(saved.subjectId, equals('math'));
        expect(saved.topicId, equals('topic-1'));
        expect(saved.topicTitle, equals('Algebra'));
        expect(saved.status, equals(SessionStatus.inProgress));
        expect(saved.plannedDurationMinutes, equals(30));
      });

      test('updates session with lesson plan after generation', () async {
        await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );

        final sessions = tutorSessionRepo._sessions;
        expect(sessions.length, greaterThanOrEqualTo(2));
        final updated = sessions.last;
        expect(updated.lessonPlanJson, contains('goals'));
      });

      test('throws when LLM chat fails', () async {
        llmService.setThrowOnChat();
        expect(
          () async => await tutorService.startLesson(
            studentId: 'student-1',
            subjectId: 'math',
            topicId: 'topic-1',
            topicTitle: 'Algebra',
            localeName: 'en',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('rolls back session to cancelled and propagates error when LLM chat fails', () async {
        llmService.setThrowOnChat();
        await expectLater(
          tutorService.startLesson(
            studentId: 'student-1',
            subjectId: 'math',
            topicId: 'topic-1',
            topicTitle: 'Algebra',
            durationMinutes: 30,
            localeName: 'en',
          ),
          throwsA(isA<Exception>()),
        );
        // A failed lesson start must roll back: the last persisted
        // tutor session state is cancelled, not left inProgress.
        expect(
          tutorSessionRepo._sessions.last.status,
          equals(SessionStatus.cancelled),
        );
      });

      test('rolls back and propagates error when lesson persistence fails', () async {
        final failingService = TutorService(
          database: database,
          llmService: llmService,
          masteryService: masteryService,
          spacedRepetitionService: FakeSpacedRepetitionService(),
          modelId: 'test-model',
          exerciseEvaluator: exerciseEvaluator,
          conversationRepository: conversationRepo,
          lessonRepository: FakeFailingLessonRepository(),
          planOrchestrator: FakePlanAdherenceOrchestrator(),
        );

        await expectLater(
          failingService.startLesson(
            studentId: 'student-1',
            subjectId: 'math',
            topicId: 'topic-1',
            topicTitle: 'Algebra',
            durationMinutes: 30,
            localeName: 'en',
          ),
          throwsA(isA<StateError>()),
        );
        // A failed lesson write must not be masked as success: the
        // session is rolled back to cancelled, not left inProgress,
        // and no lesson/manager is adopted.
        expect(
          tutorSessionRepo._sessions.last.status,
          equals(SessionStatus.cancelled),
        );
        expect(failingService.currentManager, isNull);
      });

      test('injects mastery context when student has weak topics and history',
          () async {
        masteryService.weakTopicsToReturn = [
          MasteryState(
            studentId: 'student-1',
            topicId: 'weak_topic_id',
            accuracy: 0.4,
            totalAttempts: 6,
            lastAttempt: DateTime(2024, 1, 2),
            lastUpdated: DateTime(2024, 1, 2),
            weakSubtopics: ['decimals'],
            subjectId: 'math',
          ),
        ];
        tutorSessionRepo._sessions.add(
          TutorSession(
            id: 'prev-1',
            studentId: 'student-1',
            subjectId: 'math',
            topicId: 'topic-1',
            topicTitle: 'Previous Lesson',
            status: SessionStatus.completed,
            startTime: DateTime(2024, 1, 1),
            endTime: DateTime(2024, 1, 1, 0, 45),
            questionsAsked: 4,
            questionsCorrect: 1,
          ),
        );

        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          durationMinutes: 45,
          localeName: 'en',
        );

        expect(manager.masteryContext, isNotNull);
        expect(manager.masteryContext!, contains('weak areas to watch'));
        expect(manager.masteryContext!, contains('weak_topic_id'));
        expect(manager.masteryContext!, contains('Recent lesson history'));
        expect(manager.masteryContext!, contains('Previous Lesson'));
      });

      test('does not set masteryContext when student has no mastery data',
          () async {
        // Fresh student: empty weak topics, no history. Lesson must still start.
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          durationMinutes: 45,
          localeName: 'en',
        );

        expect(manager.masteryContext, isNull);
      });

      test('forwards planner syllabus goals to ConversationManager', () async {
        // Solidification for teaching-syllabus-context: TutorService.startLesson
        // must fetch the student's SyllabusGoal[] from PlannerService and pass
        // them as availableSyllabi so SyllabusSwitchParser receives a non-empty
        // title list (agent_must_read.md §100: "Student can dynamically switch
        // syllabi"). Previously the argument was omitted and defaulted to [].
        final plan = PersonalLearningPlan(
          studentId: 'student-1',
          generatedAt: DateTime(2024, 1, 1),
          dailyPlans: [],
          summary: PlanSummary(
            totalQuestions: 0,
            totalMinutes: 0,
            newTopics: 0,
            reviewTopics: 0,
            estimatedCoverage: 0.0,
            focusAreas: [],
          ),
          recommendations: [],
          metadata: {
            'syllabus_goals': [
              SyllabusGoal(subjectId: 'chem', subjectTitle: 'Chemistry').toJson(),
              SyllabusGoal(subjectId: 'phys', subjectTitle: 'Physics').toJson(),
            ],
          },
        );
        final service = TutorService(
          database: database,
          llmService: llmService,
          masteryService: masteryService,
          spacedRepetitionService: FakeSpacedRepetitionService(),
          modelId: 'test-model',
          exerciseEvaluator: exerciseEvaluator,
          conversationRepository: conversationRepo,
          planOrchestrator: FakePlanAdherenceOrchestrator(),
          plannerService: FakePlannerService(plan),
        );

        final manager = await service.startLesson(
          studentId: 'student-1',
          subjectId: 'chem',
          topicId: 'topic-1',
          topicTitle: 'Atoms',
          durationMinutes: 45,
          localeName: 'en',
        );

        // availableSyllabi is exactly the list the parser reads as
        // availableTitles (conversation_manager.dart:208). Non-empty here
        // means the previously-dead switch path is now reachable.
        expect(manager.availableSyllabi, isNotEmpty);
        expect(
          manager.availableSyllabi.map((g) => g.subjectTitle),
          containsAll(['Chemistry', 'Physics']),
        );
        expect(
          manager.availableSyllabi
              .firstWhere((g) => g.subjectTitle == 'Physics')
              .subjectId,
          equals('phys'),
        );
      });

      test('switches syllabus mid-lesson when planner provides goals', () async {
        // End-to-end solidification: with syllabi forwarded by TutorService,
        // a student syllabus-switch utterance is recognised by the parser and
        // the manager re-scopes — the behaviour that was dead when the title
        // list was always const [].
        final plan = PersonalLearningPlan(
          studentId: 'student-1',
          generatedAt: DateTime(2024, 1, 1),
          dailyPlans: [],
          summary: PlanSummary(
            totalQuestions: 0,
            totalMinutes: 0,
            newTopics: 0,
            reviewTopics: 0,
            estimatedCoverage: 0.0,
            focusAreas: [],
          ),
          recommendations: [],
          metadata: {
            'syllabus_goals': [
              SyllabusGoal(subjectId: 'chem', subjectTitle: 'Chemistry').toJson(),
              SyllabusGoal(subjectId: 'phys', subjectTitle: 'Physics').toJson(),
            ],
          },
        );
        final service = TutorService(
          database: database,
          llmService: llmService,
          masteryService: masteryService,
          spacedRepetitionService: FakeSpacedRepetitionService(),
          modelId: 'test-model',
          exerciseEvaluator: exerciseEvaluator,
          conversationRepository: conversationRepo,
          planOrchestrator: FakePlanAdherenceOrchestrator(),
          plannerService: FakePlannerService(plan),
        );

        final manager = await service.startLesson(
          studentId: 'student-1',
          subjectId: 'chem',
          topicId: 'topic-1',
          topicTitle: 'Atoms',
          durationMinutes: 45,
          localeName: 'en',
        );

        final responses = <String>[];
        await for (final chunk in manager.sendMessage('/syllabus Physics')) {
          responses.add(chunk);
        }
        expect(responses.join(), contains('Physics'));
        expect(manager.currentSyllabusId, equals('phys'));
        expect(manager.currentSyllabusTitle, equals('Physics'));
      });
    });

    group('endLesson', () {
      test('does nothing when no active lesson', () async {
        await tutorService.endLesson();
        expect(tutorService.currentManager, isNull);
      });

      test('saves messages to conversation repository', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await manager.sendMessage('Hello').toList();

        await tutorService.endLesson();

        expect(conversationRepo._messages.length, equals(2));
      });

      test('saves final session to repository', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await manager.sendMessage('Hello').toList();

        await tutorService.endLesson();

        final completedSessions = tutorSessionRepo._sessions
            .where((s) => s.status == SessionStatus.completed);
        expect(completedSessions.isNotEmpty, isTrue);
      });

      test('records attempt in mastery service when questions were asked', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await manager.sendMessage('Hello').toList();
        manager.recordCorrectAnswer();
        manager.recordCorrectAnswer();
        manager.recordIncorrectAnswer();

        await tutorService.endLesson();

        expect(masteryService.recordedAttempts.length, equals(1));
        expect(masteryService.recordedAttempts.first['studentId'], equals('student-1'));
        expect(masteryService.recordedAttempts.first['topicId'], equals('topic-1'));
        expect(masteryService.recordedAttempts.first['isCorrect'], isTrue);
      });

      test('preserves confidence rating correctly without overflow', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await manager.sendMessage('Hello').toList();
        manager.recordCorrectAnswer();
        manager.recordIncorrectAnswer();

        await tutorService.endLesson();

        final recordedConfidence = masteryService.recordedAttempts.first['confidence'] as int;
        // confidenceRating should be 0-5 range, not multiplied by 20
        // With 1/2 = 0.5 accuracy, confidence = (0.5 * 1.0).clamp(0,1) = 0.5
        // toSession: (0.5 * 5).round() = 3 (or 2)
        // endLesson: should use session.confidenceRating directly (no * 20)
        expect(recordedConfidence, inInclusiveRange(0, 5));
        // The old bug would produce confidence = 100 when there were 0 questions,
        // or with our test setup, the confidence should never exceed 5
        expect(recordedConfidence, lessThanOrEqualTo(5));
      });

      test('persists tutor exercise with default difficulty independent of eval score', () async {
        // Perfect answer: the old bug stored difficulty 5 (hardest).
        exerciseEvaluator.score = 1.0;
        var manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        manager.transitionToExercise();
        await manager.sendMessage('Solve: x + 1 = 2').toList();
        await tutorService.endLesson();

        // Struggling answer: the old bug stored difficulty 1 (easiest).
        exerciseEvaluator.score = 0.0;
        manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        manager.transitionToExercise();
        await manager.sendMessage('Solve: x + 2 = 3').toList();
        await tutorService.endLesson();

        expect(fakeQuestionRepo.createdQuestions.length, equals(2));
        for (final question in fakeQuestionRepo.createdQuestions) {
          // Difficulty is a property of the question itself, not of the
          // student's performance, so it must not vary with the eval score.
          expect(question.difficulty, equals(3));
        }
      });

      test('clears current manager', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await manager.sendMessage('Hello').toList();

        await tutorService.endLesson();

        expect(tutorService.currentManager, isNull);
      });

      test('does not record attempt when no questions were asked', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await manager.sendMessage('Hello').toList();

        await tutorService.endLesson();

        expect(masteryService.recordedAttempts, isEmpty);
      });

      test('forwards questionsAsked to adherence recordActivity', () async {
        // Solidification for tutor-lesson-questions-not-recorded-in-adherence:
        // vision requires all study activities (tutoring, practice, review) to
        // feed daily adherence totals. The tutor endLesson path was passing
        // only actualMinutes to recordActivity, leaving actualQuestions at 0.
        final fakePlan = FakePlanAdherenceOrchestrator();
        final service = TutorService(
          database: database,
          llmService: llmService,
          masteryService: masteryService,
          spacedRepetitionService: FakeSpacedRepetitionService(),
          modelId: 'test-model',
          exerciseEvaluator: exerciseEvaluator,
          conversationRepository: conversationRepo,
          planOrchestrator: fakePlan,
        );
        final manager = await service.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await manager.sendMessage('Hello').toList();
        manager.recordCorrectAnswer();
        manager.recordCorrectAnswer();
        manager.recordCorrectAnswer();

        await service.endLesson();

        expect(fakePlan.recordActivityCalled, isTrue);
        expect(fakePlan.lastStudentId, equals('student-1'));
        // actualQuestions must equal session.questionsAsked (== 3 correct
        // answers recorded), not the default 0 — matching the practice path.
        expect(fakePlan.lastActualQuestions, equals(3));
        expect(fakePlan.lastActualMinutes, greaterThan(0));
      });
    });

    group('getLessonHistory', () {
      test('returns empty list when no sessions exist', () async {
        final history = await tutorService.getLessonHistory('nonexistent');
        expect(history.isSuccess, isTrue);
        expect(history.data, isEmpty);
      });

      test('returns sessions for the given student', () async {
        await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );

        final history = await tutorService.getLessonHistory('student-1');
        expect(history.data!.isNotEmpty, isTrue);
        expect(history.data!.first.studentId, equals('student-1'));
      });
    });

    group('getSessionMessages', () {
      test('returns empty list when no messages exist', () async {
        final messages = await tutorService.getSessionMessages('session-1');
        expect(messages.isSuccess, isTrue);
        expect(messages.data, isEmpty);
      });
    });

    group('getStats', () {
      test('returns stats from repository', () async {
        await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );

        final stats = await tutorService.getStats('student-1');
        expect(stats.data!['totalSessions'], greaterThan(0));
        expect(stats.data, containsPair('completedSessions', 0));
      });
    });

    group('saveMessage', () {
      test('saves message to conversation repository', () async {
        final message = ConversationMessage(
          id: 'msg-1',
          sessionId: 'session-1',
          role: MessageRole.student,
          type: MessageType.text,
          content: 'Hello',
          timestamp: DateTime.now(),
        );

        final saveResult = await tutorService.saveMessage(message);
        expect(saveResult.isSuccess, isTrue);

        expect(conversationRepo._messages.length, equals(1));
        expect(conversationRepo._messages.first.id, equals('msg-1'));
      });
    });

    group('getActiveSession', () {
      test('returns null when no active sessions', () async {
        final session = await tutorService.getActiveSession();
        expect(session.isSuccess, isTrue);
        expect(session.data, isNull);
      });

      test('returns active session when one exists', () async {
        await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );

        final session = await tutorService.getActiveSession();
        expect(session.data, isNotNull);
        expect(session.data!.status, equals(SessionStatus.inProgress));
      });
    });

    group('recordAttempt accuracy threshold', () {
      test('records isCorrect=false when accuracy is <= 0.5', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await manager.sendMessage('Hello').toList();

        manager.recordCorrectAnswer();
        manager.recordIncorrectAnswer();

        await tutorService.endLesson();

        expect(masteryService.recordedAttempts.length, equals(1));
        expect(masteryService.recordedAttempts.first['isCorrect'], isFalse);
      });
    });

    group('_persistExercisesAsQuestions', () {
      test('persists exercise as question when exercises and evaluation exist', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await manager.sendMessage('Hello').toList();

        manager.phase = ConversationPhase.exercise;
        await manager.sendMessage('correct').toList();

        await tutorService.endLesson();

        expect(fakeQuestionRepo.createdQuestions.length, equals(1));
        final question = fakeQuestionRepo.createdQuestions.first;
        expect(question.text, isNotEmpty);
        expect(question.subjectId, equals('math'));
        expect(question.topicId, equals('topic-1'));
        expect(question.type, equals(QuestionType.typedAnswer));
        expect(question.explanation, contains('Good job'));
      });

      test('does not persist question when no exercises done', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await manager.sendMessage('Hello').toList();

        await tutorService.endLesson();

        expect(fakeQuestionRepo.createdQuestions, isEmpty);
      });

      test('does not persist question when exerciseCount is 0', () async {
        await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );

        await tutorService.endLesson();

        expect(fakeQuestionRepo.createdQuestions, isEmpty);
      });
    });

    group('endLesson session repository', () {
      test('creates a Session entry in session repository', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await manager.sendMessage('Hello').toList();

        await tutorService.endLesson();

        expect(fakeSessionRepo.savedSessions.length, equals(1));
        final session = fakeSessionRepo.savedSessions.first;
        expect(session.studentId, equals('student-1'));
        expect(session.subjectId, equals('math'));
        expect(session.topicId, equals('topic-1'));
        expect(session.type, equals(SessionType.tutoring));
        expect(session.completed, isTrue);
        expect(session.sourceId, startsWith('tutor_'));
      });
    });

    group('generateNextTopicLesson', () {
      late FakeLessonRepository fakeLessonRepo;

      setUp(() {
        fakeLessonRepo = FakeLessonRepository();
      });

      test(
          'produces lesson with blocks beyond LessonBlockType.text '
          'when tool is wired', () async {
        masteryService.weakTopicsToReturn = [
          MasteryState(
            studentId: 'student-1',
            topicId: 'weak_topic_id',
            lastAttempt: DateTime.now(),
            lastUpdated: DateTime.now(),
            subjectId: 'math',
          ),
        ];

        final fakeTool = FakePreGenerateLessonTool(
          lessonRepository: fakeLessonRepo,
        );

        final service = TutorService(
          database: database,
          llmService: llmService,
          masteryService: masteryService,
          spacedRepetitionService: FakeSpacedRepetitionService(),
          modelId: 'test-model',
          exerciseEvaluator: exerciseEvaluator,
          conversationRepository: conversationRepo,
          lessonRepository: fakeLessonRepo,
          planOrchestrator: FakePlanAdherenceOrchestrator(),
          preGenerateLessonTool: fakeTool,
        );

        final session = TutorSession(
          id: 'session-1',
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'current-topic',
          topicTitle: 'Current Topic',
          startTime: DateTime.now(),
        );

        final result = await service.generateNextTopicLesson(session);

        // The tool's execute() was invoked with the weak topic info.
        expect(fakeTool.executedArgs, isNotEmpty);
        expect(fakeTool.executedArgs.first['topicId'], equals('weak_topic_id'));
        expect(fakeTool.executedArgs.first['subjectId'], equals('math'));

        // Result map indicates success with block count.
        expect(result['success'], isTrue);
        expect(result['blockCount'], greaterThan(1));

        // The lesson persisted by the tool has blocks beyond text.
        final createdLessons = fakeLessonRepo.createdLessons;
        expect(createdLessons, isNotEmpty);
        final lesson = createdLessons.first;

        final blockTypes = lesson.blocks.map((b) => b.type).toSet();
        expect(blockTypes, contains(LessonBlockType.text));
        expect(blockTypes.any((t) => t != LessonBlockType.text), isTrue);
      });

      test('falls back to placeholder when tool is null', () async {
        masteryService.weakTopicsToReturn = [
          MasteryState(
            studentId: 'student-1',
            topicId: 'weak_topic_id',
            lastAttempt: DateTime.now(),
            lastUpdated: DateTime.now(),
            subjectId: 'math',
          ),
        ];

        final service = TutorService(
          database: database,
          llmService: llmService,
          masteryService: masteryService,
          spacedRepetitionService: FakeSpacedRepetitionService(),
          modelId: 'test-model',
          exerciseEvaluator: exerciseEvaluator,
          conversationRepository: conversationRepo,
          lessonRepository: fakeLessonRepo,
          planOrchestrator: FakePlanAdherenceOrchestrator(),
        );

        final session = TutorSession(
          id: 'session-1',
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'current-topic',
          topicTitle: 'Current Topic',
          startTime: DateTime.now(),
        );

        final result = await service.generateNextTopicLesson(session);

        expect(result['success'], isTrue);
        expect(result['lessonId'], isNotEmpty);

        final createdLessons = fakeLessonRepo.createdLessons;
        expect(createdLessons, isNotEmpty);
        final lesson = createdLessons.first;

        final blockTypes = lesson.blocks.map((b) => b.type).toSet();
        expect(blockTypes, equals({LessonBlockType.text}));
      });

      test('returns success without creating lesson when no weak topics',
          () async {
        masteryService.weakTopicsToReturn = [];

        final fakeTool = FakePreGenerateLessonTool(
          lessonRepository: fakeLessonRepo,
        );

        final service = TutorService(
          database: database,
          llmService: llmService,
          masteryService: masteryService,
          spacedRepetitionService: FakeSpacedRepetitionService(),
          modelId: 'test-model',
          exerciseEvaluator: exerciseEvaluator,
          conversationRepository: conversationRepo,
          lessonRepository: fakeLessonRepo,
          planOrchestrator: FakePlanAdherenceOrchestrator(),
          preGenerateLessonTool: fakeTool,
        );

        final session = TutorSession(
          id: 'session-1',
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'current-topic',
          topicTitle: 'Current Topic',
          startTime: DateTime.now(),
        );

        final result = await service.generateNextTopicLesson(session);

        expect(result['success'], isTrue);
        expect(fakeLessonRepo.createdLessons, isEmpty);
        expect(fakeTool.executedArgs, isEmpty);
      });
    });
  });
}
