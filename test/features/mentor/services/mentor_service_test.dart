import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/core/data/models/tutor_session_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/conversation_repository.dart';
import 'package:studyking/core/data/repositories/lesson_repository.dart';
import 'package:studyking/core/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/study_session_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/data/repositories/tutor_session_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/mentor/services/mentor_service.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/data/repositories/subject_repository.dart';

class FakeTutorSessionRepository extends TutorSessionRepository {
  final List<TutorSession> _sessions = [];

  void addSession(TutorSession session) => _sessions.add(session);

  @override
  Future<void> saveSession(TutorSession session) async {
    _sessions.add(session);
  }

  @override
  Future<List<TutorSession>> getStudentSessions(String studentId) async {
    return _sessions.where((s) => s.studentId == studentId).toList();
  }

  @override
  Future<TutorSession?> getSession(String id) async {
    try {
      return _sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}

class FakeStudySessionRepository extends StudySessionRepository {
  final List<StudySession> _sessions = [];

  void addSession(StudySession session) => _sessions.add(session);

  @override
  Future<List<StudySession>> getByStudent(String studentId) async {
    return _sessions.where((s) => s.studentId == studentId).toList();
  }
}

class FakeSubjectRepository extends SubjectRepository {
  final List<Subject> _subjects = [];

  void addSubject(Subject subject) => _subjects.add(subject);

  @override
  Future<List<Subject>> getAll() async => _subjects;
}

class FakeLlmService extends LlmService {
  FakeLlmService()
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: '',
          ),
        );

  @override
  Stream<String> chatStream({
    required String message,
    required String modelId,
    String? systemPrompt,
    ConversationMemory? memory,
    List<Map<String, String>>? history,
  }) async* {
    yield 'Mentor response';
  }
}

class FakeMasteryGraphService extends MasteryGraphService {
  Result<List<MasteryState>>? _weakTopicsResult;

  void setWeakTopicsResult(Result<List<MasteryState>> result) {
    _weakTopicsResult = result;
  }

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return _weakTopicsResult ?? Result.success([]);
  }
}

class FakeProgressTracker extends StudyProgressTracker {
  Map<String, dynamic> _stats = {
    'totalAttempts': 10,
    'correctAttempts': 7,
    'accuracy': 70,
    'avgTimePerQuestion': 30,
    'totalStudyTimeHours': '2.5',
    'weeklyActivity': 5,
    'dailyActivity': 2,
    'topicsStudied': 3,
  };
  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _badges = [];

  FakeProgressTracker({
    AttemptRepository? attemptRepo,
    super.masteryService,
  }) : super(
          attemptRepo: attemptRepo ?? AttemptRepository(),
        );

  void setStats(Map<String, dynamic> stats) => _stats = stats;
  void setRecommendations(List<Map<String, dynamic>> recs) =>
      _recommendations = recs;
  void setBadges(List<Map<String, dynamic>> badges) => _badges = badges;

  @override
  Future<Map<String, dynamic>> getOverallStats(String studentId) async {
    if (_stats.containsKey('throw')) throw Exception('Simulated error');
    return _stats;
  }

  @override
  Future<List<Map<String, dynamic>>> getRecommendations(
      String studentId) async => _recommendations;

  @override
  Future<List<Map<String, dynamic>>> getBadges(String studentId) async =>
      _badges;
}

MentorService createMentorService({
  DatabaseService? database,
  LlmService? llmService,
  MasteryGraphService? masteryService,
  StudyProgressTracker? progressTracker,
  String modelId = 'test-model',
  String studentId = 'test-student',
}) {
  final db = database ??
      DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: FakeStudySessionRepository(),
        subjectRepository: FakeSubjectRepository(),
        conversationRepository: ConversationRepository(),
        tutorSessionRepository: FakeTutorSessionRepository(),
      );
  final llm = llmService ?? FakeLlmService();
  final mastery = masteryService ?? FakeMasteryGraphService();
  final tracker = progressTracker ??
      FakeProgressTracker(
        attemptRepo: AttemptRepository(),
        masteryService: mastery,
      );
  return MentorService(
    database: db,
    llmService: llm,
    masteryService: mastery,
    progressTracker: tracker,
    modelId: modelId,
    studentId: studentId,
  );
}

void main() {
  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('mentor_test_');
    Hive.init(dir.path);
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
  });

  group('MentorService', () {
    group('initial state', () {
      test('memory is a ConversationMemory', () {
        final service = createMentorService();
        expect(service.memory, isA<ConversationMemory>());
      });
    });

    group('chat - regular messages', () {
      late MentorService service;
      late FakeLlmService llmService;

      setUp(() {
        llmService = FakeLlmService();
        service = createMentorService(llmService: llmService);
      });

      test('sends regular message to LLM and returns chunks', () async {
        final chunks = await service.chat('Hello mentor').toList();
        expect(chunks, isNotEmpty);
        expect(chunks.first, equals('Mentor response'));
      });

      test('adds user and assistant messages to memory', () async {
        await service.chat('Hello').toList();
        final history = service.memory.getHistory();
        expect(history.length, equals(2));
        expect(history[0]['role'], equals('user'));
        expect(history[0]['content'], equals('Hello'));
        expect(history[1]['role'], equals('assistant'));
        expect(history[1]['content'], equals('Mentor response'));
      });
    });

    group('chat - all messages delegate to LLM', () {
      test('schedule keyword delegates to LLM', () async {
        final service = createMentorService();
        final chunks = await service.chat('schedule a lesson').toList();
        expect(chunks, isNotEmpty);
        expect(chunks.first, equals('Mentor response'));
      });

      test('progress keyword delegates to LLM', () async {
        final service = createMentorService();
        final chunks = await service.chat('show my progress').toList();
        expect(chunks.first, equals('Mentor response'));
      });

      test('inactivity keyword delegates to LLM', () async {
        final service = createMentorService();
        final chunks = await service.chat('i am inactive').toList();
        expect(chunks.first, equals('Mentor response'));
      });

      test('adds user and assistant messages to memory', () async {
        final service = createMentorService();
        await service.chat('schedule a lesson').toList();
        final history = service.memory.getHistory();
        expect(history.length, equals(2));
        expect(history[0]['role'], equals('user'));
        expect(history[1]['role'], equals('assistant'));
      });
    });

    group('suggestReschedule', () {
      test('stores pending action in repository', () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 'session-1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          startTime: DateTime.now(),
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        await service.suggestReschedule('session-1');
        final chatResult = await service.chat('hello').toList();
        expect(chatResult.first, equals('Mentor response'));
      });
    });

    group('getProgressReport', () {
      test('returns structured progress report with stats', () async {
        final tracker = FakeProgressTracker(attemptRepo: AttemptRepository());
        tracker.setStats({
          'totalAttempts': 20,
          'correctAttempts': 15,
          'accuracy': 75,
          'avgTimePerQuestion': 30,
          'totalStudyTimeHours': '3.0',
          'weeklyActivity': 8,
          'dailyActivity': 3,
          'topicsStudied': 5,
        });
        final service = createMentorService(progressTracker: tracker);

        final report = await service.getProgressReport();
        expect(report.accuracy, equals(75.0));
        expect(report.totalAttempts, equals(20));
        expect(report.correctAttempts, equals(15));
        expect(report.totalStudyTimeHours, equals('3.0'));
        expect(report.weeklyActivity, equals(8));
        expect(report.topicsStudied, equals(5));
      });

      test('includes weak topics in report', () async {
        final mastery = FakeMasteryGraphService();
        mastery.setWeakTopicsResult(Result.success([
          MasteryState(
            studentId: 'test-student',
            topicId: 'topic_weak',
            accuracy: 0.3,
            lastAttempt: DateTime.now(),
            lastUpdated: DateTime.now(),
          ),
        ]));
        final tracker = FakeProgressTracker(
          attemptRepo: AttemptRepository(),
          masteryService: mastery,
        );
        tracker.setStats({
          'totalAttempts': 10,
          'correctAttempts': 5,
          'accuracy': 50,
          'avgTimePerQuestion': 30,
          'totalStudyTimeHours': '1.0',
          'weeklyActivity': 2,
          'dailyActivity': 1,
          'topicsStudied': 2,
        });
        final service =
            createMentorService(masteryService: mastery, progressTracker: tracker);

        final report = await service.getProgressReport();
        expect(report.weakTopics.length, equals(1));
        expect(report.weakTopics.first.topicId, equals('topic_weak'));
      });

      test('throws on failure', () async {
        final errorTracker = FakeProgressTracker(attemptRepo: AttemptRepository());
        errorTracker.setStats({'throw': true});
        final service = createMentorService(progressTracker: errorTracker);

        expect(() => service.getProgressReport(), throwsA(isA<Exception>()));
      });
    });

    group('suggestNextAction', () {
      test('returns recommendation message when recommendations exist',
          () async {
        final tracker = FakeProgressTracker(attemptRepo: AttemptRepository());
        tracker.setRecommendations([
          {
            'type': 'review',
            'priority': 'high',
            'message': 'Focus on reviewing fundamentals',
            'action': 'Review',
          },
        ]);
        final service = createMentorService(progressTracker: tracker);

        final action = await service.suggestNextAction();
        expect(action.message, equals('Focus on reviewing fundamentals'));
      });

      test('returns subject setup message when no subjects', () async {
        final service = createMentorService();
        final action = await service.suggestNextAction();
        expect(action.message, contains("haven't added any subjects"));
      });

      test('returns generic message when recommendations and subjects exist',
          () async {
        final subjectRepo = FakeSubjectRepository();
        subjectRepo.addSubject(Subject(
          id: 'math',
          name: 'Mathematics',
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: subjectRepo,
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: FakeTutorSessionRepository(),
        );
        final service = createMentorService(database: db);

        final action = await service.suggestNextAction();
        expect(action.message, contains("You're doing well"));
      });
    });

    group('suggestReschedule', () {
      test('stores pending action and adds system message for existing session',
          () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 'session-1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          startTime: DateTime.now(),
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        await service.suggestReschedule('session-1');

        final history = service.memory.getHistory();
        expect(history.any((m) =>
            m['role'] == 'system' &&
            m['content']!.contains('Algebra')), isTrue);
      });

      test('does nothing when session not found', () async {
        final tutorRepo = FakeTutorSessionRepository();
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        await service.suggestReschedule('nonexistent');
        final history = service.memory.getHistory();
        expect(history.where((m) => m['role'] == 'system'), isEmpty);
      });

      test('adds system message about rescheduling to memory', () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 'session-1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          startTime: DateTime.now(),
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        await service.suggestReschedule('session-1');

        final history = service.memory.getHistory();
        expect(history.any((m) =>
            m['role'] == 'system' &&
            m['content']!.contains('Algebra')), isTrue);
      });
    });
  });
}
