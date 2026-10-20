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
import 'package:studyking/core/data/models/topic_model.dart';
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
import 'package:studyking/core/services/llm_agent/agent_loop.dart';
import 'package:studyking/core/services/llm_agent/agent_memory.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/llm_agent/idle_executor.dart';
import 'package:studyking/core/services/llm_agent/llm_agent.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/prep_budget.dart' show PrepCategory;
import 'package:studyking/core/services/system_monitor_service.dart';

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
  int chatCalls = 0;

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
    String? taskType,
    String? sessionId,
  }) async {
    chatCalls++;
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
    String? taskType,
    String? sessionId,
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
  int checkAdherenceCallCount = 0;
  String? lastCheckAdherenceStudentId;

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

  @override
  Future<Result<AdherenceDeviation>> checkAdherence(String studentId) async {
    checkAdherenceCallCount++;
    lastCheckAdherenceStudentId = studentId;
    return Result.success(const AdherenceDeviation());
  }
}

class FakeMasteryGraphService extends MasteryGraphService {
  final List<Map<String, dynamic>> recordedAttempts = [];
  List<MasteryState> weakTopicsToReturn = [];
  int getWeakTopicsCallCount = 0;
  String? lastGetWeakTopicsStudentId;

  FakeMasteryGraphService();

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(
    String studentId, {
    String? subjectId,
  }) async {
    getWeakTopicsCallCount++;
    lastGetWeakTopicsStudentId = studentId;
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
  Future<Result<void>> save(String key, Session session) async {
    _savedSessions.add(session);
    return Result.success(null);
  }

  @override
  Future<Result<Session?>> get(String key) async {
    final matches = _savedSessions.where((s) => s.id == key);
    return Result.success(matches.isNotEmpty ? matches.first : null);
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

/// Hand-written fake [TopicRepository] that returns topics from an in-memory
/// map without touching Hive — used to verify TutorService resolves a
/// human-readable topic title before pre-generating lessons.
class FakeTopicRepository extends TopicRepository {
  final Map<String, Topic> _topics = {};

  void setTopic(Topic topic) {
    _topics[topic.id] = topic;
  }

  @override
  Future<Result<Topic?>> get(String key) async {
    return Result.success(_topics[key]);
  }

  @override
  Future<Result<void>> init() async => Result.success(null);
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

/// Captures a single `enqueuePrepTool` invocation so tests can assert on the
/// exact `feature`/`taskType`/`subjectId` attribution that TutorService hands
/// to the IdleExecutor.
class PrepTaskCapture {
  final String description;
  final bool requiresHeavy;
  final String feature;
  final String taskType;
  final String? subjectId;
  final int estimatedInputTokens;
  final int estimatedOutputTokens;

  PrepTaskCapture({
    required this.description,
    required this.requiresHeavy,
    required this.feature,
    required this.taskType,
    this.subjectId,
    this.estimatedInputTokens = 0,
    this.estimatedOutputTokens = 0,
  });
}

/// Hand-written fake [IdleExecutor] that records every `enqueuePrepTool` and
/// `enqueue` call in a list (mirroring [FakeIdleExecutor] from
/// `llm_agent_test.dart`) without executing any tasks. This lets TutorService
/// tests prove that `endLesson` → `_enqueueBackgroundTasks` → `LlmAgent.enqueuePrepTask`
/// lands three correctly-attributed prep tasks on the executor.
class CapturingIdleExecutor extends IdleExecutor {
  final List<PrepTaskCapture> capturedPrepTasks = [];
  final List<String> capturedEnqueuedDescriptions = [];
  bool disposed = false;

  @override
  Future<void> enqueuePrepTool(
    String description,
    Future<Map<String, dynamic>> Function() task, {
    required bool requiresHeavy,
    required String feature,
    required String taskType,
    String? subjectId,
    int estimatedInputTokens = 0,
    int estimatedOutputTokens = 0,
    String? jobId,
    String? payload,
  }) async {
    capturedPrepTasks.add(PrepTaskCapture(
      description: description,
      requiresHeavy: requiresHeavy,
      feature: feature,
      taskType: taskType,
      subjectId: subjectId,
      estimatedInputTokens: estimatedInputTokens,
      estimatedOutputTokens: estimatedOutputTokens,
    ));
  }

  @override
  Future<void> enqueue(
    String description,
    Future<void> Function() task, {
    bool requiresHeavy = false,
    String? jobId,
    String? payload,
  }) async {
    capturedEnqueuedDescriptions.add(description);
  }

  @override
  void dispose() {
    disposed = true;
  }
}

/// Hand-written fake [SystemMonitorService] with a mutable
/// `canRunHeavyPrepNow` flag, copied from `idle_executor_test.dart` so that
/// TutorService deferral tests can toggle CPU pressure at runtime.
class MutableFakeSystemMonitorService extends SystemMonitorService {
  bool canRunHeavyPrepNowValue;
  final int batteryLevelValue;
  final bool isChargingValue;
  final double cpuLoadValue;
  final bool isBatterySaverValue;
  final String? networkTypeValue;

  MutableFakeSystemMonitorService({
    this.canRunHeavyPrepNowValue = true,
    this.batteryLevelValue = -1,
    this.isChargingValue = false,
    this.cpuLoadValue = -1,
    this.isBatterySaverValue = false,
    this.networkTypeValue,
  });

  set canRunHeavyPrepNow(bool value) => canRunHeavyPrepNowValue = value;

  @override
  bool get canRunHeavyPrepNow => canRunHeavyPrepNowValue;

  @override
  int get batteryLevel => batteryLevelValue;

  @override
  bool get isCharging => isChargingValue;

  @override
  double get cpuLoad => cpuLoadValue;

  @override
  bool get isBatterySaver => isBatterySaverValue;

  @override
  String? get networkType => networkTypeValue;
}

/// Minimal [AgentLoop] stub that returns a canned [AgentResponse] without any
/// LLM calls — only needed here to satisfy [LlmAgent]'s constructor in
/// endLesson tests (the loop is never invoked; only `enqueuePrepTask` is).
class FakeAgentLoop extends AgentLoop {
  FakeAgentLoop()
      : super(
          llmService: FakeLlmService(),
          modelId: 'test-model',
          toolRegistry: ToolRegistry(),
        );

  @override
  Future<AgentResponse> run({
    required String userMessage,
    required String studentId,
    required String systemPrompt,
    String feature = 'agent',
    List<Map<String, String>>? history,
    String? sessionId,
  }) async {
    return AgentResponse(content: 'AI response', toolCalls: []);
  }
}

/// In-memory [AgentMemoryStore] for [LlmAgent] construction — mirrors
/// `FakeAgentMemoryStore` from `llm_agent_test.dart`.
class FakeAgentMemoryStore extends AgentMemoryStore {
  final Map<String, String> _facts = {};

  @override
  String? recallFact(String studentId, String key) => _facts['${studentId}_$key'];

  @override
  Future<void> rememberFact(String studentId, String key, String value) async {
    _facts['${studentId}_$key'] = value;
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

    group('startLesson with pre-generated lesson', () {
      /// A pre-generated lesson with multiple block types, persisted by the
      /// planner / PreGenerateLessonTool ahead of the scheduled time.
      Lesson buildPreGeneratedLesson() {
        const lessonId = 'pregen-lesson-1';
        return Lesson(
          id: lessonId,
          subjectId: 'math',
          title: 'Algebra',
          topicId: 'topic-1',
          blocks: [
            LessonBlock(
              id: 'b1',
              subjectId: 'math',
              lessonId: lessonId,
              type: LessonBlockType.slide,
              content: 'Pre-built slide: atoms',
              order: 0,
            ),
            LessonBlock(
              id: 'b2',
              subjectId: 'math',
              lessonId: lessonId,
              type: LessonBlockType.exercise,
              content: 'Pre-built exercise: solve',
              answerKey: 'x = 2',
              order: 1,
            ),
            LessonBlock(
              id: 'b3',
              subjectId: 'math',
              lessonId: lessonId,
              type: LessonBlockType.summary,
              content: 'Pre-built recap: key points',
              order: 2,
            ),
          ],
          difficulty: 3,
          generatedBy: GeneratedBy.ai,
          createdAt: DateTime.now(),
          validationStatus: ValidationStatus.pending,
        );
      }

      TutorService serviceWithFakeRepo(FakeLessonRepository fakeLessonRepo) {
        return TutorService(
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
      }

      test('reuses pre-generated lesson blocks and skips live LLM plan generation',
          () async {
        final fakeLessonRepo = FakeLessonRepository();
        final preLesson = buildPreGeneratedLesson();
        await fakeLessonRepo.create(preLesson);

        // Scheduled session carries the pre-generated lesson, marked ready.
        fakeSessionRepo.save(
          'scheduled-session-1',
          Session(
            id: 'scheduled-session-1',
            studentId: 'student-1',
            subjectId: 'math',
            topicId: 'topic-1',
            type: SessionType.tutoring,
            startTime: DateTime.now().subtract(const Duration(hours: 1)),
            completed: false,
            lessonReady: true,
            lessonIds: [preLesson.id],
            tutorMetadata: TutorMetadata(topicTitle: 'Algebra'),
          ),
        );

        final service = serviceWithFakeRepo(fakeLessonRepo);

        final callsBefore = llmService.chatCalls;
        final manager = await service.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          durationMinutes: 45,
          scheduledSessionId: 'scheduled-session-1',
          localeName: 'en',
        );

        // The pre-generated lesson's blocks are adopted verbatim (same ids),
        // not re-generated blocks with fresh uuids.
        expect(service.currentLessonBlocks, isNotNull);
        expect(service.currentLessonBlocks!.length, equals(3));
        expect(
          service.currentLessonBlocks!.map((b) => b.id),
          containsAll(['b1', 'b2', 'b3']),
        );
        expect(
          service.currentLessonBlocks!.map((b) => b.content),
          containsAll([
            'Pre-built slide: atoms',
            'Pre-built exercise: solve',
            'Pre-built recap: key points',
          ]),
        );

        // Vision Next-Term section 4.3: the pre-built blocks are serialised into
        // a "Current lesson plan" context on the manager so they reach the tutor
        // LLM prompt -- the prep tokens spent off-period are not wasted and a
        // student asking "show me the example from my lesson" gets the pre-built
        // artefact, not a fresh hallucination.
        expect(manager.lessonPlanContext, isNotNull);
        expect(manager.lessonPlanContext, contains('Current lesson plan'));
        expect(manager.lessonPlanContext, contains('Type: slide'));
        expect(manager.lessonPlanContext, contains('Type: exercise'));
        expect(manager.lessonPlanContext, contains('Type: summary'));
        expect(manager.lessonPlanContext, contains('Pre-built slide: atoms'));
        expect(manager.lessonPlanContext, contains('Pre-built exercise: solve'));

        // The live plan-generation LLM call was skipped: no LessonPlan is set
        // on the manager and the fake LLM chat was not invoked for it
        // (Vision Next-Term section 4.3 prep-vs-live token economy).
        expect(manager.lessonPlan, isNull);
        expect(llmService.chatCalls - callsBefore, equals(0));
        expect(service.currentManager, same(manager));
      });

      test('falls back to live generation when lessonReady is false', () async {
        final fakeLessonRepo = FakeLessonRepository();
        final preLesson = buildPreGeneratedLesson();
        await fakeLessonRepo.create(preLesson);

        // Scheduled session is NOT lesson-ready → must generate live.
        fakeSessionRepo.save(
          'scheduled-session-not-ready',
          Session(
            id: 'scheduled-session-not-ready',
            studentId: 'student-1',
            subjectId: 'math',
            topicId: 'topic-1',
            type: SessionType.tutoring,
            startTime: DateTime.now().subtract(const Duration(hours: 1)),
            completed: false,
            lessonReady: false,
            lessonIds: [],
            tutorMetadata: TutorMetadata(topicTitle: 'Algebra'),
          ),
        );

        final service = serviceWithFakeRepo(fakeLessonRepo);
        final callsBefore = llmService.chatCalls;
        final manager = await service.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          durationMinutes: 45,
          scheduledSessionId: 'scheduled-session-not-ready',
          localeName: 'en',
        );

        // Live path generated a plan via the LLM.
        expect(manager.lessonPlan, isNotNull);
        expect(llmService.chatCalls - callsBefore, greaterThan(0));
        // Even on the live path the adopted blocks are serialised into the
        // tutor prompt context (Vision Next-Term section 4.3).
        expect(manager.lessonPlanContext, isNotNull);
        expect(manager.lessonPlanContext, contains('Current lesson plan'));
        // The adopted blocks come from the freshly-generated live lesson
        // (new uuid ids), not the pre-generated lesson's original 'b1..' blocks.
        expect(
          service.currentLessonBlocks!.any((b) => b.id == 'b1'),
          isFalse,
        );
      });

      test('falls back to live generation when pre-generated lesson is missing',
          () async {
        final fakeLessonRepo = FakeLessonRepository();

        // Scheduled session is ready but references a lesson id that was
        // never persisted (e.g. cleared between prep and start). Must not
        // crash — gracefully fall back to live generation.
        fakeSessionRepo.save(
          'scheduled-session-missing',
          Session(
            id: 'scheduled-session-missing',
            studentId: 'student-1',
            subjectId: 'math',
            topicId: 'topic-1',
            type: SessionType.tutoring,
            startTime: DateTime.now().subtract(const Duration(hours: 1)),
            completed: false,
            lessonReady: true,
            lessonIds: ['does-not-exist'],
            tutorMetadata: TutorMetadata(topicTitle: 'Algebra'),
          ),
        );

        final service = serviceWithFakeRepo(fakeLessonRepo);
        final manager = await service.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          durationMinutes: 45,
          scheduledSessionId: 'scheduled-session-missing',
          localeName: 'en',
        );

        expect(manager.lessonPlan, isNotNull);
        expect(service.currentLessonBlocks, isNotNull);
        expect(service.currentLessonBlocks, isNotEmpty);
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

      // ─────────────────────────────────────────────────────────────
      // Post-lesson off-period prep deferral (Vision Next-Term §4.1/§4.3).
      // These tests prove that ending a tutoring lesson enqueues three
      // heavy prep tasks onto the IdleExecutor via LlmAgent.enqueuePrepTask,
      // and that the CPU-pressure gate defers them until the device is idle.
      // ─────────────────────────────────────────────────────────────

      test(
          'endLesson enqueues three prep tasks to IdleExecutor with '
          'correct feature/taskType/subjectId', () async {
        // LlmAgent backed by a capturing executor that records every
        // enqueuePrepTool call instead of executing.
        final capturingExecutor = CapturingIdleExecutor();
        final llmAgent = LlmAgent(
          loop: FakeAgentLoop(),
          toolRegistry: ToolRegistry(),
          memoryStore: FakeAgentMemoryStore(),
          idleExecutor: capturingExecutor,
          studentId: 'student-1',
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
          llmAgent: llmAgent,
        );

        final manager = await service.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await manager.sendMessage('Hello').toList();
        await service.endLesson();

        // _enqueueBackgroundTasks must land exactly three prep tasks.
        expect(capturingExecutor.capturedPrepTasks.length, equals(3));

        // Task 1 — post-lesson adherence check → background bucket.
        final adherenceTask = capturingExecutor.capturedPrepTasks[0];
        expect(
          adherenceTask.description,
          equals('Post-lesson adherence update'),
        );
        expect(
          adherenceTask.taskType,
          equals(PrepCategory.background.taskTypeKey),
          reason: 'adherence check must be attributed to the background bucket',
        );
        expect(
          adherenceTask.feature,
          equals(PrepCategory.background.taskTypeKey),
        );
        expect(adherenceTask.requiresHeavy, isTrue);
        expect(adherenceTask.subjectId, isNull);

        // Task 2 — weak-topic reanalysis → background bucket.
        final weakTopicTask = capturingExecutor.capturedPrepTasks[1];
        expect(
          weakTopicTask.description,
          equals('Post-lesson weak topic reanalysis'),
        );
        expect(
          weakTopicTask.taskType,
          equals(PrepCategory.background.taskTypeKey),
          reason: 'weak-topic reanalysis must be attributed to background',
        );
        expect(
          weakTopicTask.feature,
          equals(PrepCategory.background.taskTypeKey),
        );
        expect(weakTopicTask.requiresHeavy, isTrue);
        expect(weakTopicTask.subjectId, isNull);

        // Task 3 — next-topic lesson prep → lesson_prep bucket, bound to
        // the lesson's subject so the IdleExecutor can skip it when the
        // student paused that syllabus (Vision §4.2 per-subject opt-in).
        final nextTopicTask = capturingExecutor.capturedPrepTasks[2];
        expect(
          nextTopicTask.description,
          equals('Next topic lesson prep'),
        );
        expect(
          nextTopicTask.taskType,
          equals(PrepCategory.lessonPrep.taskTypeKey),
          reason: 'next-topic prep must be attributed to lesson_prep, '
              'not the generic background bucket',
        );
        expect(
          nextTopicTask.feature,
          equals(PrepCategory.lessonPrep.taskTypeKey),
        );
        expect(nextTopicTask.requiresHeavy, isTrue);
        expect(
          nextTopicTask.subjectId,
          equals('math'),
          reason: 'next-topic prep must carry the lesson subjectId',
        );

        // No background (non-prep) enqueue calls should also be made —
        // the three tasks are all prep tasks.
        expect(capturingExecutor.capturedEnqueuedDescriptions, isEmpty);
      });

      test(
          'endLesson defers heavy prep under CPU pressure and resumes '
          'on recovery', () async {
        // System starts under heavy load → heavy prep must defer.
        final monitor = MutableFakeSystemMonitorService(
          canRunHeavyPrepNowValue: false,
        );
        final taskManager = LlmTaskManager();
        final realExecutor = IdleExecutor(
          llmTaskManager: taskManager,
          systemMonitor: monitor,
        );

        final llmAgent = LlmAgent(
          loop: FakeAgentLoop(),
          toolRegistry: ToolRegistry(),
          memoryStore: FakeAgentMemoryStore(),
          idleExecutor: realExecutor,
          studentId: 'student-1',
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
          llmAgent: llmAgent,
        );

        final sessionManager = await service.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await sessionManager.sendMessage('Hello').toList();
        await service.endLesson();

        // Fire-and-forget enqueue calls from _enqueueBackgroundTasks
        // schedule _tryExecuteNext on the event loop; flush microtasks so
        // the deferral decision has been applied.
        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);

        // Under CPU pressure: all three tasks queued, none started.
        expect(realExecutor.hasPendingTasks, isTrue);
        expect(realExecutor.queue.length, equals(3));
        for (final task in realExecutor.queue) {
          expect(
            task.isCompleted,
            isFalse,
            reason: '${task.description} must not run under CPU pressure',
          );
          expect(
            task.isRunning,
            isFalse,
            reason: '${task.description} must not be running under CPU pressure',
          );
        }

        // System recovers — drain the deferred queue.
        monitor.canRunHeavyPrepNow = true;
        while (realExecutor.hasPendingTasks) {
          await realExecutor.processNext();
          // Allow post-task aggregation microtasks to settle.
          await Future.delayed(Duration.zero);
        }

        // All three tasks were attempted (completed or failed, not merely
        // deferred).
        expect(realExecutor.queue.length, equals(3));
        for (final task in realExecutor.queue) {
          expect(
            task.isRunning,
            isFalse,
            reason: '${task.description} should not still be running',
          );
          expect(
            task.isCompleted || task.error != null,
            isTrue,
            reason: '${task.description} should have been attempted, '
                'not left pending',
          );
        }

        realExecutor.dispose();
      });
    });

    // ─────────────────────────────────────────────────────────────
    // Task reconstruction after restore (Vision Next-Term §4.1/§4.2).
    // When the app restarts, idle tasks restored from the Hive box arrive
    // with taskFn == null (closures can't be serialised). The TutorService's
    // TaskReconstructor — registered when llmAgent is attached — must rebuild
    // the executable closure from the task's payload (kind + studentId) so
    // the task actually runs instead of being silently drained as a no-op.
    // ─────────────────────────────────────────────────────────────
    group('task reconstruction after restore', () {
      test(
          'set llmAgent registers a TaskReconstructor that rebuilds '
          'lesson_prep closures instead of draining them as no-ops', () async {
        var shouldDefer = true;
        final taskManager = LlmTaskManager();
        final executor = IdleExecutor(
          llmTaskManager: taskManager,
          shouldDeferForQuietHours: (_) => shouldDefer,
        );

        final llmAgent = LlmAgent(
          loop: FakeAgentLoop(),
          toolRegistry: ToolRegistry(),
          memoryStore: FakeAgentMemoryStore(),
          idleExecutor: executor,
          studentId: 'student-1',
        );

        // TutorService with a fake prep tool so we can verify the reconstructed
        // closure actually calls through to PreGenerateLessonTool.execute.
        final fakeLessonRepo = FakeLessonRepository();
        final fakeTool = FakePreGenerateLessonTool(
          lessonRepository: fakeLessonRepo,
        );
        final fakeTopicRepo = FakeTopicRepository();
        fakeTopicRepo.setTopic(Topic(
          id: 'weak_topic',
          subjectId: 'math',
          title: 'Weak Topic',
          description: '',
          syllabusText: '',
        ));

        masteryService.weakTopicsToReturn = [
          MasteryState(
            studentId: 'student-1',
            topicId: 'weak_topic',
            subjectId: 'math',
            lastAttempt: DateTime.now(),
            lastUpdated: DateTime.now(),
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
          topicRepository: fakeTopicRepo,
          planOrchestrator: FakePlanAdherenceOrchestrator(),
          preGenerateLessonTool: fakeTool,
        );

        // Setting llmAgent must register the TaskReconstructor.
        service.llmAgent = llmAgent;

        // Start + end a lesson so _enqueueBackgroundTasks enqueues three tasks,
        // all deferred by quiet-hours (shouldDefer = true).
        final mgr = await service.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await mgr.sendMessage('Hello').toList();
        await service.endLesson();

        // Flush fire-and-forget enqueue calls.
        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);

        expect(executor.queue.length, equals(3));

        // Simulate process restart: closures are not serialised, so null them
        // out — the TaskReconstructor must rebuild them at execution time.
        for (final task in executor.queue) {
          task.taskFn = null;
        }

        // Release quiet-hours so deferred tasks can run.
        shouldDefer = false;

        // Drain the queue — each task should be reconstructed by the
        // TaskReconstructor, NOT drained as a no-op.
        while (executor.hasPendingTasks) {
          await executor.processNext();
          await Future.delayed(Duration.zero);
        }

        final nextTopicTask = executor.queue.firstWhere(
          (t) => t.description == 'Next topic lesson prep',
        );
        // The task was reconstructed and executed, not silently drained.
        expect(nextTopicTask.isCompleted, isTrue);
        expect(nextTopicTask.error, isNull,
            reason: 'Reconstructed lesson_prep task should succeed');
        // The pre-generate tool was actually invoked by the reconstructed
        // closure — proving the closure was rebuilt, not drained.
        expect(fakeTool.executedArgs, isNotEmpty);
        expect(fakeTool.executedArgs.first['topicId'], equals('weak_topic'));
        expect(fakeTool.executedArgs.first['subjectId'], equals('math'));

        executor.dispose();
      });

      test(
          'restored background task (adherence check) is reconstructed and '
          'executed — not drained as a no-op', () async {
        var shouldDefer = true;
        final taskManager = LlmTaskManager();
        final executor = IdleExecutor(
          llmTaskManager: taskManager,
          shouldDeferForQuietHours: (_) => shouldDefer,
        );

        final llmAgent = LlmAgent(
          loop: FakeAgentLoop(),
          toolRegistry: ToolRegistry(),
          memoryStore: FakeAgentMemoryStore(),
          idleExecutor: executor,
          studentId: 'student-1',
        );

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

        service.llmAgent = llmAgent;

        final mgr = await service.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await mgr.sendMessage('Hello').toList();
        await service.endLesson();

        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);

        expect(executor.queue.length, equals(3));

        // Simulate process restart: null out all closures.
        for (final task in executor.queue) {
          task.taskFn = null;
        }

        shouldDefer = false;

        while (executor.hasPendingTasks) {
          await executor.processNext();
          await Future.delayed(Duration.zero);
        }

        // The adherence check task was reconstructed and checkAdherence was
        // actually called on the plan orchestrator — not silently drained.
        final adherenceTask = executor.queue.firstWhere(
          (t) => t.description == 'Post-lesson adherence update',
        );
        expect(adherenceTask.isCompleted, isTrue);
        expect(adherenceTask.error, isNull);
        expect(fakePlan.checkAdherenceCallCount, equals(1));
        expect(fakePlan.lastCheckAdherenceStudentId, equals('student-1'));

        executor.dispose();
      });

      test(
          'restored background task (weak topic reanalysis) is reconstructed '
          'and executed — not drained as a no-op', () async {
        var shouldDefer = true;
        final taskManager = LlmTaskManager();
        final executor = IdleExecutor(
          llmTaskManager: taskManager,
          shouldDeferForQuietHours: (_) => shouldDefer,
        );

        final llmAgent = LlmAgent(
          loop: FakeAgentLoop(),
          toolRegistry: ToolRegistry(),
          memoryStore: FakeAgentMemoryStore(),
          idleExecutor: executor,
          studentId: 'student-1',
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
        );

        service.llmAgent = llmAgent;

        final mgr = await service.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await mgr.sendMessage('Hello').toList();
        await service.endLesson();

        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);

        expect(executor.queue.length, equals(3));

        // Simulate process restart: null out all closures.
        for (final task in executor.queue) {
          task.taskFn = null;
        }

        shouldDefer = false;

        while (executor.hasPendingTasks) {
          await executor.processNext();
          await Future.delayed(Duration.zero);
        }

        final weakTopicTask = executor.queue.firstWhere(
          (t) => t.description == 'Post-lesson weak topic reanalysis',
        );
        expect(weakTopicTask.isCompleted, isTrue);
        expect(weakTopicTask.error, isNull);
        // The reconstructor called getWeakTopics on the mastery service.
        expect(masteryService.getWeakTopicsCallCount, greaterThan(0));

        executor.dispose();
      });

      test(
          'restored task with no recognisable payload is drained gracefully '
          '(no crash)', () async {
        var shouldDefer = true;
        final taskManager = LlmTaskManager();
        final executor = IdleExecutor(
          llmTaskManager: taskManager,
          shouldDeferForQuietHours: (_) => shouldDefer,
        );

        final llmAgent = LlmAgent(
          loop: FakeAgentLoop(),
          toolRegistry: ToolRegistry(),
          memoryStore: FakeAgentMemoryStore(),
          idleExecutor: executor,
          studentId: 'student-1',
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
        );

        service.llmAgent = llmAgent;

        // Enqueue a task with NO payload — simulating a task type the
        // reconstructor doesn't recognise (e.g. from an older app version).
        await service.llmAgent!.enqueuePrepTask(
          'Unknown prep task',
          () async => {'success': true},
          requiresHeavy: false,
          feature: PrepCategory.background.taskTypeKey,
          taskType: PrepCategory.background.taskTypeKey,
        );

        await Future.delayed(Duration.zero);
        expect(executor.queue.length, equals(1));

        // Simulate restart: null out the closure.
        executor.queue.first.taskFn = null;

        shouldDefer = false;
        await executor.processNext();
        await Future.delayed(Duration.zero);

        // Unknown task → reconstructor returns null → drained as no-op
        // (graceful, not a crash).
        final task = executor.queue.first;
        expect(task.isCompleted, isTrue);
        expect(task.error, isNull);

        executor.dispose();
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

      test('passes resolved human-readable topicTitle to the prep tool',
          () async {
        // Solidification for teaching-pregen-topic-title-is-topic-id:
        // generateNextTopicLesson must resolve a human-readable title from the
        // TopicRepository (not the bare topicId) before invoking the prep tool,
        // so pre-generated lessons surface with a real label like "Cell
        // Structure" instead of "weak_topic_id".
        masteryService.weakTopicsToReturn = [
          MasteryState(
            studentId: 'student-1',
            topicId: 'weak_topic_id',
            lastAttempt: DateTime.now(),
            lastUpdated: DateTime.now(),
            subjectId: 'math',
          ),
        ];

        final fakeTopicRepo = FakeTopicRepository();
        fakeTopicRepo.setTopic(Topic(
          id: 'weak_topic_id',
          subjectId: 'math',
          title: 'Cell Structure',
          description: '',
          syllabusText: '',
        ));

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
          topicRepository: fakeTopicRepo,
        );

        final session = TutorSession(
          id: 'session-1',
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'current-topic',
          topicTitle: 'Current Topic',
          startTime: DateTime.now(),
        );

        await service.generateNextTopicLesson(session);

        expect(fakeTool.executedArgs, isNotEmpty);
        // topicTitle must be the resolved human-readable title, not the bare
        // topicId that was previously passed (tutor_service.dart:547 bug).
        expect(fakeTool.executedArgs.first['topicTitle'],
            equals('Cell Structure'));
        // The persisted lesson's title is also human-readable (the tool
        // stores topicTitle as Lesson.title — lesson_agent_service.dart:62).
        expect(fakeLessonRepo.createdLessons.first.title,
            equals('Cell Structure'));
      });

      test(
          'falls back to labeled topicId when topic title cannot be resolved',
          () async {
        // When the topic is absent from the repository (e.g. not yet
        // catalogued), the title falls back to a clear subject/topic label
        // rather than silently using the bare opaque ID.
        masteryService.weakTopicsToReturn = [
          MasteryState(
            studentId: 'student-1',
            topicId: 'weak_topic_id',
            lastAttempt: DateTime.now(),
            lastUpdated: DateTime.now(),
            subjectId: 'math',
          ),
        ];

        final fakeTopicRepo = FakeTopicRepository(); // empty store

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
          topicRepository: fakeTopicRepo,
        );

        final session = TutorSession(
          id: 'session-1',
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'current-topic',
          topicTitle: 'Current Topic',
          startTime: DateTime.now(),
        );

        await service.generateNextTopicLesson(session);

        // Fallback label carries subject context: "math/weak_topic_id".
        expect(fakeTool.executedArgs.first['topicTitle'],
            equals('math/weak_topic_id'));
      });

      test(
          'placeholder lesson uses resolved topic title when tool is null',
          () async {
        // The no-tool placeholder path must also resolve the title (not just
        // the wired-tool path) so degraded environments degrade gracefully
        // without opaque IDs.
        masteryService.weakTopicsToReturn = [
          MasteryState(
            studentId: 'student-1',
            topicId: 'weak_topic_id',
            lastAttempt: DateTime.now(),
            lastUpdated: DateTime.now(),
            subjectId: 'math',
          ),
        ];

        final fakeTopicRepo = FakeTopicRepository();
        fakeTopicRepo.setTopic(Topic(
          id: 'weak_topic_id',
          subjectId: 'math',
          title: 'Cell Structure',
          description: '',
          syllabusText: '',
        ));

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
          topicRepository: fakeTopicRepo,
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
        final lesson = fakeLessonRepo.createdLessons.first;
        expect(lesson.title, equals('Cell Structure'));
        expect(lesson.blocks.first.content, contains('Cell Structure'));
      });
    });
  });
}
