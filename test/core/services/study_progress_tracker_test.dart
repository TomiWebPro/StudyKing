import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/badge_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/dashboard/data/models/badge_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class FakeAttemptRepository extends AttemptRepository {
  final List<StudentAttempt> _attempts = [];
  bool shouldThrow = false;

  void setAttempts(List<StudentAttempt> attempts) {
    _attempts.clear();
    _attempts.addAll(attempts);
  }

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async {
    if (shouldThrow) return Result.failure('repo_error');
    return Result.success(_attempts.where((a) => a.studentId == studentId).toList());
  }

  @override
  Future<Result<void>> create(StudentAttempt attempt) async {
    if (shouldThrow) return Result.failure('repo_error');
    _attempts.add(attempt);
    return Result.success(null);
  }

  @override
  Future<Result<StudentAttempt?>> get(String id) async {
    if (shouldThrow) return Result.failure('repo_error');
    return Result.success(_attempts.where((a) => a.id == id).firstOrNull);
  }

  @override
  Future<Result<List<StudentAttempt>>> getAll() async {
    if (shouldThrow) return Result.failure('repo_error');
    return Result.success(_attempts);
  }

  @override
  Future<Result<List<StudentAttempt>>> getByStudentAndSubject(String studentId, String subjectId) async {
    if (shouldThrow) return Result.failure('repo_error');
    return Result.success(_attempts.where((a) => a.studentId == studentId && a.subjectId == subjectId).toList());
  }

  @override
  Future<Result<List<StudentAttempt>>> getByQuestion(String questionId) async {
    if (shouldThrow) return Result.failure('repo_error');
    return Result.success(_attempts.where((a) => a.questionId == questionId).toList());
  }

  @override
  Future<Result<List<StudentAttempt>>> getBySubject(String subjectId) async {
    if (shouldThrow) return Result.failure('repo_error');
    return Result.success(_attempts.where((a) => a.subjectId == subjectId).toList());
  }

  @override
  Future<Result<Map<String, dynamic>>> getSubjectStats(String subjectId) async {
    if (shouldThrow) return Result.failure('repo_error');
    return Result.success({});
  }

  @override
  Future<Result<void>> delete(String id) async {
    if (shouldThrow) return Result.failure('repo_error');
    _attempts.removeWhere((a) => a.id == id);
    return Result.success(null);
  }
}

class FakeSessionRepository extends SessionRepository {
  final List<Session> _sessions = [];

  void setSessions(List<Session> sessions) {
    _sessions.clear();
    _sessions.addAll(sessions);
  }

  @override
  Future<Result<List<Session>>> getByStudent(String studentId) async {
    return Result.success(
        _sessions.where((s) => s.studentId == studentId).toList());
  }
}

class FakeQuestionRepository extends QuestionRepository {
  final Map<String, Question> _questions = {};

  void addQuestion(Question question) {
    _questions[question.id] = question;
  }

  @override
  Future<Result<Question?>> get(String key) async {
    return Result.success(_questions[key]);
  }
}

Question _productionQuestion(String id, String topicId) {
  final now = DateTime.now();
  return Question(
    id: id,
    text: 'Question $id',
    type: QuestionType.singleChoice,
    subjectId: 'subject1',
    topicId: topicId,
    createdAt: now,
    updatedAt: now,
  );
}

class _BadgeModelAdapter extends TypeAdapter<BadgeModel> {
  @override
  final int typeId = 31;

  @override
  BadgeModel read(BinaryReader reader) {
    final id = reader.readString();
    final studentId = reader.readString();
    final name = reader.readString();
    final description = reader.readString();
    final iconName = reader.readString();
    final category = reader.readString();
    final unlockedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    Map<String, dynamic>? criteria;
    if (reader.readBool()) {
      criteria = Map<String, dynamic>.from(jsonDecode(reader.readString()) as Map);
    }
    return BadgeModel(
      id: id,
      studentId: studentId,
      name: name,
      description: description,
      iconName: iconName,
      category: category,
      unlockedAt: unlockedAt,
      criteria: criteria,
    );
  }

  @override
  void write(BinaryWriter writer, BadgeModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.studentId);
    writer.writeString(obj.name);
    writer.writeString(obj.description);
    writer.writeString(obj.iconName);
    writer.writeString(obj.category);
    writer.writeInt(obj.unlockedAt.millisecondsSinceEpoch);
    writer.writeBool(obj.criteria != null);
    if (obj.criteria != null) {
      writer.writeString(jsonEncode(obj.criteria));
    }
  }
}

class FakeMasteryGraphService extends MasteryGraphService {
  List<MasteryState> _weakTopics = [];
  MasteryState? _topicMastery;
  List<MasteryState> _allMastery = [];

  void setWeakTopics(List<MasteryState> topics) {
    _weakTopics = topics;
  }

  void setTopicMastery(MasteryState state) {
    _topicMastery = state;
  }

  void setAllMastery(List<MasteryState> states) {
    _allMastery = states;
  }

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return Result.success(_weakTopics);
  }

  @override
  Future<Result<MasteryState>> getTopicMastery(String studentId, String topicId) async {
    if (_topicMastery != null) {
      return Result.success(_topicMastery!);
    }
    return Result.failure('No topic mastery set');
  }

  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) async {
    return Result.success(_allMastery);
  }

  @override
  Future<Result<void>> init() async => Result.success(null);
}

/// Independent ISO 8601 week-number computation (day-of-year
/// formula) used to cross-check the production implementation.
int _referenceIsoWeekNumber(DateTime date) {
  final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  final week = (dayOfYear - date.weekday + 10) ~/ 7;
  if (week < 1) {
    return _referenceIsoWeekNumber(DateTime(date.year - 1, 12, 31));
  }
  if (week > 52 && DateTime(date.year, 12, 31).weekday < DateTime.thursday) {
    return 1;
  }
  return week;
}

void main() {
  late String hivePath;

  setUpAll(() {
    hivePath = Directory.systemTemp.createTempSync('tracker_test_').path;
    Hive.init(hivePath);
    Hive.registerAdapter(_BadgeModelAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
    if (hivePath.isNotEmpty) {
      await Directory(hivePath).delete(recursive: true);
    }
  });

  group('StudyProgressTracker', () {
    late StudyProgressTracker tracker;
    late FakeAttemptRepository mockRepo;
    late FakeSessionRepository mockSessionRepo;

    late FakeMasteryGraphService mockMasteryService;

    setUp(() {
      mockRepo = FakeAttemptRepository();
      mockSessionRepo = FakeSessionRepository();
      mockMasteryService = FakeMasteryGraphService();
      tracker = StudyProgressTracker(
        attemptRepo: mockRepo,
        sessionRepo: mockSessionRepo,
        masteryService: mockMasteryService,
        l10n: lookupAppLocalizations(const Locale('en')),
      );
    });

    group('getOverallStats', () {
      test('returns stats with zero values for no attempts', () async {
        mockRepo.setAttempts([]);

        final stats = await tracker.getOverallStats('student1');

        expect(stats.data!['totalAttempts'], equals(0));
        expect(stats.data!['correctAttempts'], equals(0));
        expect(stats.data!['accuracy'], equals(0));
        expect(stats.data!['avgTimePerQuestion'], equals(0));
        expect(stats.data!['weeklyActivity'], equals(0));
        expect(stats.data!['dailyActivity'], equals(0));
        expect(stats.data!['topicsStudied'], equals(0));
      });

      test('calculates correct accuracy', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'q2', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a3', studentId: 'student1', questionId: 'q3', isCorrect: false, timeSpentMs: 3000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a4', studentId: 'student1', questionId: 'q4', isCorrect: false, timeSpentMs: 3000, timestamp: now, subjectId: 'math'),
        ]);

        final stats = await tracker.getOverallStats('student1');

        expect(stats.data!['accuracy'], equals(50));
      });

      test('calculates average time per question', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'q2', isCorrect: true, timeSpentMs: 10000, timestamp: now, subjectId: 'math'),
        ]);

        final stats = await tracker.getOverallStats('student1');

        expect(stats.data!['avgTimePerQuestion'], equals(8));
      });

      test('calculates total study time in hours', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 1800000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'q2', isCorrect: true, timeSpentMs: 1800000, timestamp: now, subjectId: 'math'),
        ]);

        final stats = await tracker.getOverallStats('student1');

        expect(stats.data!['totalStudyTimeHours'], equals(1.0));
      });

      test('counts weekly activity', () async {
        final now = DateTime.now();
        final weekAgo = now.subtract(const Duration(days: 3));
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'q2', isCorrect: true, timeSpentMs: 5000, timestamp: weekAgo, subjectId: 'math'),
        ]);

        final stats = await tracker.getOverallStats('student1');

        expect(stats.data!['weeklyActivity'], greaterThanOrEqualTo(1));
      });

      test('counts daily activity', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'q2', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);

        final stats = await tracker.getOverallStats('student1');

        expect(stats.data!['dailyActivity'], equals(2));
      });

      test('includes session study time in total study time', () async {
        mockRepo.setAttempts([]);
        final now = DateTime.now();
        mockSessionRepo.setSessions([
          Session(
            id: 's1',
            studentId: 'student1',
            type: SessionType.focus,
            startTime: now,
            actualDurationMs: 3600000,
          ),
          Session(
            id: 's2',
            studentId: 'student1',
            type: SessionType.tutoring,
            startTime: now,
            actualDurationMs: 1800000,
          ),
        ]);

        final stats = await tracker.getOverallStats('student1');

        expect(stats.data!['totalStudyTimeHours'], equals(1.5));
        expect(stats.data!['sessionCount'], equals(2));
        expect(stats.data!['focusSessionCount'], equals(1));
        expect(stats.data!['tutorSessionCount'], equals(1));
      });

      test('counts unique topics studied', () async {
        final now = DateTime.now();
        final questionRepo = FakeQuestionRepository();
        questionRepo.addQuestion(_productionQuestion('q_1700000000000_0', 'topic_math'));
        questionRepo.addQuestion(_productionQuestion('q_1700000000001_0', 'topic_math'));
        questionRepo.addQuestion(_productionQuestion('q_1700000000002_0', 'topic_science'));
        tracker = StudyProgressTracker(
          attemptRepo: mockRepo,
          sessionRepo: mockSessionRepo,
          masteryService: mockMasteryService,
          questionRepo: questionRepo,
          l10n: lookupAppLocalizations(const Locale('en')),
        );
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q_1700000000000_0', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'q_1700000000001_0', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a3', studentId: 'student1', questionId: 'q_1700000000002_0', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'science'),
        ]);

        final stats = await tracker.getOverallStats('student1');

        expect(stats.data!['topicsStudied'], equals(2));
      });

      test('does not collapse production question IDs into a single topic (regression)', () async {
        // Production question IDs (IdGenerator.generate('q')) embed no topic
        // information, so the distinct-topic count must come from the joined
        // questions — not from the shared "q" ID prefix.
        final now = DateTime.now();
        final questionRepo = FakeQuestionRepository();
        questionRepo.addQuestion(_productionQuestion('q_1700000000000_0', 'topic_algebra'));
        questionRepo.addQuestion(_productionQuestion('q_1700000000001_0', 'topic_algebra'));
        questionRepo.addQuestion(_productionQuestion('q_1700000000002_0', 'topic_geometry'));
        questionRepo.addQuestion(_productionQuestion('q_1700000000003_0', 'topic_statistics'));
        tracker = StudyProgressTracker(
          attemptRepo: mockRepo,
          sessionRepo: mockSessionRepo,
          masteryService: mockMasteryService,
          questionRepo: questionRepo,
          l10n: lookupAppLocalizations(const Locale('en')),
        );
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q_1700000000000_0', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'q_1700000000001_0', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a3', studentId: 'student1', questionId: 'q_1700000000002_0', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a4', studentId: 'student1', questionId: 'q_1700000000003_0', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);

        final stats = await tracker.getOverallStats('student1');

        expect(stats.data!['topicsStudied'], equals(3));
      });

      test('counts the same topic once across multiple attempts', () async {
        final now = DateTime.now();
        final questionRepo = FakeQuestionRepository();
        questionRepo.addQuestion(_productionQuestion('q_1700000000000_0', 'topic_algebra'));
        questionRepo.addQuestion(_productionQuestion('q_1700000000001_0', 'topic_algebra'));
        tracker = StudyProgressTracker(
          attemptRepo: mockRepo,
          sessionRepo: mockSessionRepo,
          masteryService: mockMasteryService,
          questionRepo: questionRepo,
          l10n: lookupAppLocalizations(const Locale('en')),
        );
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q_1700000000000_0', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'q_1700000000001_0', isCorrect: false, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);

        final stats = await tracker.getOverallStats('student1');

        expect(stats.data!['topicsStudied'], equals(1));
      });

      test('falls back to question ID prefix when no question repository is wired', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'math_q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'science_q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'science'),
        ]);

        final stats = await tracker.getOverallStats('student1');

        expect(stats.data!['topicsStudied'], equals(2));
      });

      test('falls back to question ID prefix when questions cannot be resolved', () async {
        final now = DateTime.now();
        // Repository is wired but holds none of the attempted questions.
        tracker = StudyProgressTracker(
          attemptRepo: mockRepo,
          sessionRepo: mockSessionRepo,
          masteryService: mockMasteryService,
          questionRepo: FakeQuestionRepository(),
          l10n: lookupAppLocalizations(const Locale('en')),
        );
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'math_q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'science_q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'science'),
        ]);

        final stats = await tracker.getOverallStats('student1');

        expect(stats.data!['topicsStudied'], equals(2));
      });
    });

    group('getTopicProgress', () {
      test('returns empty progress for no attempts', () async {
        mockRepo.setAttempts([]);

        final progress = await tracker.getTopicProgress('student1', 'topic1');

        expect(progress.data!['topicId'], equals('topic1'));
        expect(progress.data!['attempts'], equals(0));
        expect(progress.data!['accuracy'], equals(0.0));
        expect(progress.data!['timeSpentMinutes'], equals(0));
      });

      test('calculates topic progress correctly', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'topic1_q1', isCorrect: true, timeSpentMs: 60000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'topic1_q2', isCorrect: true, timeSpentMs: 60000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a3', studentId: 'student1', questionId: 'topic1_q3', isCorrect: false, timeSpentMs: 60000, timestamp: now, subjectId: 'math'),
        ]);

        final progress = await tracker.getTopicProgress('student1', 'topic1');

        expect(progress.data!['attempts'], equals(3));
        expect(progress.data!['accuracy'], equals(67));
        expect(progress.data!['timeSpentMinutes'], equals(3));
      });

      test('includes last attempted timestamp', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'topic1_q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);

        final progress = await tracker.getTopicProgress('student1', 'topic1');

        expect(progress.data!['lastAttempted'], isNotNull);
      });

      test('reports the chronologically latest attempt as lastAttempted', () async {
        // Attempts are stored under keys '<questionId>_<timestamp>', so the
        // repository returns them grouped by question ID, not by time. The
        // chronologically latest attempt (10:00) belongs to the
        // lexicographically smaller question ID, so a `.last` would wrongly
        // report 09:00.
        final t10 = DateTime(2024, 1, 1, 10, 0);
        final t9 = DateTime(2024, 1, 1, 9, 0);
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'topic1_q_a', isCorrect: true, timeSpentMs: 5000, timestamp: t10, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'topic1_q_b', isCorrect: false, timeSpentMs: 5000, timestamp: t9, subjectId: 'math'),
        ]);

        final progress = await tracker.getTopicProgress('student1', 'topic1');

        expect(progress.data!['lastAttempted'], equals(t10.toIso8601String()));
      });

      test('resolves topic attempts through the question repository (production IDs)', () async {
        // Production question IDs (IdGenerator.generate('q')) embed no topic
        // information, so attempts must be joined to their questions to find
        // the topic's attempts.
        final now = DateTime.now();
        final questionRepo = FakeQuestionRepository();
        questionRepo.addQuestion(_productionQuestion('q_1700000000000_0', 'topic_algebra'));
        questionRepo.addQuestion(_productionQuestion('q_1700000000001_0', 'topic_algebra'));
        questionRepo.addQuestion(_productionQuestion('q_1700000000002_0', 'topic_geometry'));
        tracker = StudyProgressTracker(
          attemptRepo: mockRepo,
          sessionRepo: mockSessionRepo,
          masteryService: mockMasteryService,
          questionRepo: questionRepo,
          l10n: lookupAppLocalizations(const Locale('en')),
        );
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q_1700000000000_0', isCorrect: true, timeSpentMs: 60000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'q_1700000000001_0', isCorrect: false, timeSpentMs: 60000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a3', studentId: 'student1', questionId: 'q_1700000000002_0', isCorrect: true, timeSpentMs: 60000, timestamp: now, subjectId: 'math'),
        ]);

        final progress = await tracker.getTopicProgress('student1', 'topic_algebra');

        expect(progress.data!['attempts'], equals(2));
        expect(progress.data!['accuracy'], equals(50));
        expect(progress.data!['timeSpentMinutes'], equals(2));
      });

      test('excludes attempts belonging to other topics', () async {
        final now = DateTime.now();
        final questionRepo = FakeQuestionRepository();
        questionRepo.addQuestion(_productionQuestion('q_1700000000000_0', 'topic_algebra'));
        questionRepo.addQuestion(_productionQuestion('q_1700000000002_0', 'topic_geometry'));
        tracker = StudyProgressTracker(
          attemptRepo: mockRepo,
          sessionRepo: mockSessionRepo,
          masteryService: mockMasteryService,
          questionRepo: questionRepo,
          l10n: lookupAppLocalizations(const Locale('en')),
        );
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q_1700000000000_0', isCorrect: true, timeSpentMs: 60000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'q_1700000000002_0', isCorrect: true, timeSpentMs: 60000, timestamp: now, subjectId: 'math'),
        ]);

        final progress = await tracker.getTopicProgress('student1', 'topic_geometry');

        expect(progress.data!['attempts'], equals(1));
        expect(progress.data!['accuracy'], equals(100));
      });

      test('falls back to substring match when questions cannot be resolved', () async {
        final now = DateTime.now();
        // Repository is wired but holds none of the attempted questions.
        tracker = StudyProgressTracker(
          attemptRepo: mockRepo,
          sessionRepo: mockSessionRepo,
          masteryService: mockMasteryService,
          questionRepo: FakeQuestionRepository(),
          l10n: lookupAppLocalizations(const Locale('en')),
        );
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'topic1_q1', isCorrect: true, timeSpentMs: 60000, timestamp: now, subjectId: 'math'),
        ]);

        final progress = await tracker.getTopicProgress('student1', 'topic1');

        expect(progress.data!['attempts'], equals(1));
      });

      test('getTopicMasteryLevelEnum fallback uses joined topic stats', () async {
        // No mastery-graph entry: the level must come from the joined
        // topic stats — browsing (attempts >= 1), not novice.
        final now = DateTime.now();
        final questionRepo = FakeQuestionRepository();
        questionRepo.addQuestion(_productionQuestion('q_1700000000000_0', 'topic_algebra'));
        questionRepo.addQuestion(_productionQuestion('q_1700000000001_0', 'topic_algebra'));
        tracker = StudyProgressTracker(
          attemptRepo: mockRepo,
          sessionRepo: mockSessionRepo,
          masteryService: mockMasteryService,
          questionRepo: questionRepo,
          l10n: lookupAppLocalizations(const Locale('en')),
        );
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q_1700000000000_0', isCorrect: true, timeSpentMs: 60000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'q_1700000000001_0', isCorrect: false, timeSpentMs: 60000, timestamp: now, subjectId: 'math'),
        ]);

        final level = await tracker.getTopicMasteryLevelEnum('topic_algebra', studentId: 'student1');

        expect(level.data, equals(MasteryLevel.browsing));
      });
    });

    group('getWeeklyTrend', () {
      test('returns trend data', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);

        final trend = await tracker.getWeeklyTrend(4);

        expect(trend.data!, isA<List>());
      });

      test('counts boundary-band attempts in exactly one week (no double count)', () async {
        final now = DateTime.now();
        // 6.5 and 13.5 days ago sit inside the bands where the old
        // ±1-day slop windows of adjacent weeks overlapped, so they
        // used to be counted in two consecutive buckets at once.
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now.subtract(const Duration(days: 6, hours: 12)), subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'q2', isCorrect: false, timeSpentMs: 5000, timestamp: now.subtract(const Duration(days: 13, hours: 12)), subjectId: 'math'),
        ]);

        final trend = await tracker.getWeeklyTrend(4, studentId: 'student1');

        final counts = trend.data!.map((w) => w['attempts'] as int).toList();
        expect(counts.where((c) => c > 0), hasLength(2));
        expect(counts.reduce((a, b) => a + b), 2);
      });

      test('labels each week with its ISO week number, not the calendar month', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);

        final trend = await tracker.getWeeklyTrend(4, studentId: 'student1');

        for (var i = 0; i < trend.data!.length; i++) {
          final entry = trend.data![i];
          final weekStart = now.subtract(Duration(days: i * 7 + 6));
          expect(entry['weekNumber'], equals(_referenceIsoWeekNumber(weekStart)));
          expect(entry['weekNumber'], inInclusiveRange(1, 53));
        }
      });

      test('computes improvement over the previous week, not the current week',
          () async {
        final now = DateTime.now();
        // Accuracy rises over time: 0% (oldest) → 50% → 100% (current).
        // Each pair sits mid-window so it lands in exactly one week.
        mockRepo.setAttempts([
          // Current week (i = 0): 2/2 correct → 100%.
          StudentAttempt(id: 'c1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now.subtract(const Duration(days: 1)), subjectId: 'math'),
          StudentAttempt(id: 'c2', studentId: 'student1', questionId: 'q2', isCorrect: true, timeSpentMs: 5000, timestamp: now.subtract(const Duration(days: 2)), subjectId: 'math'),
          // One week ago (i = 1): 1/2 correct → 50%.
          StudentAttempt(id: 'w1', studentId: 'student1', questionId: 'q3', isCorrect: true, timeSpentMs: 5000, timestamp: now.subtract(const Duration(days: 8)), subjectId: 'math'),
          StudentAttempt(id: 'w2', studentId: 'student1', questionId: 'q4', isCorrect: false, timeSpentMs: 5000, timestamp: now.subtract(const Duration(days: 9)), subjectId: 'math'),
          // Two weeks ago (i = 2): 0/2 correct → 0%.
          StudentAttempt(id: 'o1', studentId: 'student1', questionId: 'q5', isCorrect: false, timeSpentMs: 5000, timestamp: now.subtract(const Duration(days: 15)), subjectId: 'math'),
          StudentAttempt(id: 'o2', studentId: 'student1', questionId: 'q6', isCorrect: false, timeSpentMs: 5000, timestamp: now.subtract(const Duration(days: 16)), subjectId: 'math'),
        ]);

        final trend = await tracker.getWeeklyTrend(3, studentId: 'student1');

        final improvements =
            trend.data!.map((w) => w['improvement'] as num).toList();
        // Current week (100%) vs one week ago (50%) → +50.
        expect(improvements[0], 50.0);
        // One week ago (50%) vs two weeks ago (0%) → +50.
        expect(improvements[1], 50.0);
        // Oldest week has no earlier period to compare against.
        expect(improvements[2], 0.0);
      });

      test('does not count future-dated attempts in the current week', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now.add(const Duration(hours: 1)), subjectId: 'math'),
        ]);

        final trend = await tracker.getWeeklyTrend(4, studentId: 'student1');

        final counts = trend.data!.map((w) => w['attempts'] as int).toList();
        expect(counts.reduce((a, b) => a + b), 0);
      });

      test('returns empty list when no attempts', () async {
        mockRepo.setAttempts([]);

        final trend = await tracker.getWeeklyTrend(4);

        expect(trend.data!.isNotEmpty, isTrue);
      });

      test('keeps strict most-recent-first order for large windows (no year-only re-sort)',
          () async {
        mockRepo.setAttempts([]);

        // 104 weeks always spans a >=52-week same-calendar-year
        // partition on every date, which is above the 34-element
        // threshold where Dart's unstable List.sort reorders
        // equal-key (same-year) entries. The loop must emit
        // entries in generation order (i = 0 is the current
        // week) because WeeklyChart labels bars by list index
        // and the CSV exporters emit rows in list order.
        final now = DateTime.now();
        final trend = await tracker.getWeeklyTrend(104, studentId: 'student1');

        expect(trend.data, hasLength(104));
        for (var i = 0; i < trend.data!.length; i++) {
          final entry = trend.data![i];
          final weekStart = now.subtract(Duration(days: i * 7 + 6));
          expect(entry['week'], equals(weekStart.year));
          expect(entry['month'], equals(weekStart.month));
          expect(
            entry['weekNumber'],
            equals(_referenceIsoWeekNumber(weekStart)),
          );
        }
      });
    });

    group('getRecommendations', () {
      test('returns review recommendation for low accuracy', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: false, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'q2', isCorrect: false, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a3', studentId: 'student1', questionId: 'q3', isCorrect: false, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a4', studentId: 'student1', questionId: 'q4', isCorrect: false, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a5', studentId: 'student1', questionId: 'q5', isCorrect: false, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);

        final recommendations = await tracker.getRecommendations('student1');

        expect(recommendations.data!.any((r) => r['type'] == 'review'), isTrue);
      });

      test('returns advanced recommendation for high accuracy', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'q2', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a3', studentId: 'student1', questionId: 'q3', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a4', studentId: 'student1', questionId: 'q4', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a5', studentId: 'student1', questionId: 'q5', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a6', studentId: 'student1', questionId: 'q6', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);

        final recommendations = await tracker.getRecommendations('student1');

        expect(recommendations.data!.any((r) => r['type'] == 'advanced'), isTrue);
      });

      test('returns engagement recommendation for low study time', () async {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 2));
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 500000, timestamp: yesterday, subjectId: 'math'),
        ]);

        final recommendations = await tracker.getRecommendations('student1');

        expect(recommendations.data!.any((r) => r['type'] == 'engagement'), isTrue);
      });

      test('returns reminder for no weekly activity', () async {
        final now = DateTime.now();
        final lastWeek = now.subtract(const Duration(days: 10));
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: lastWeek, subjectId: 'math'),
        ]);

        final recommendations = await tracker.getRecommendations('student1');

        expect(recommendations.data!.any((r) => r['type'] == 'reminder'), isTrue);
      });
    });

    group('getBadges', () {
      test('returns empty list when no badges have been unlocked', () async {
        final badges = await tracker.getBadges('no_badges_student');
        expect(badges.data!, isEmpty);
      });

      test('returns badges after they are persisted', () async {
        const testStudent = 'badge_persist_student';
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: testStudent, questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);

        final badgeService = BadgeService(
          getStats: tracker.getOverallStats,
          notificationService: null,
        );
        await badgeService.checkAndUnlockBadges(testStudent);

        final badges = await tracker.getBadges(testStudent);

        expect(badges.isSuccess, isTrue);
        expect(badges.data!.isNotEmpty, isTrue);
      });

      test('returns multiple badges when conditions are met', () async {
        const testStudent = 'badge_multiple_student';
        final now = DateTime.now();
        final attempts = List.generate(100, (i) => StudentAttempt(
          id: 'a$i', studentId: testStudent, questionId: 'q$i', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math',
        ));
        mockRepo.setAttempts(attempts);

        final badgeService = BadgeService(
          getStats: tracker.getOverallStats,
          notificationService: null,
        );
        await badgeService.checkAndUnlockBadges(testStudent);

        final badges = await tracker.getBadges(testStudent);

        expect(badges.isSuccess, isTrue);
        expect(badges.data!.length, greaterThanOrEqualTo(2));
      });

      test('returns empty list for student without attempts', () async {
        final badges = await tracker.getBadges('no_attempts_student');
        expect(badges.data!, isEmpty);
      });
    });

    group('getTopicMasteryLevel', () {
      test('returns Novice for no attempts', () async {
        final level = await tracker.getTopicMasteryLevel('topic1', studentId: 'student1');
        expect(level.data!, equals('Novice'));
      });

      test('returns Browsing for some attempts with low accuracy', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'topic1_q1', isCorrect: false, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);
        final level = await tracker.getTopicMasteryLevel('topic1', studentId: 'student1');
        expect(level.data!, equals('Browsing'));
      });
    });

    group('exportProgressCSV', () {
      test('exports CSV with stats', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);

        final csv = await tracker.exportProgressCSV('student1');

        expect(csv.data!, contains('Date'));
        expect(csv.data!, contains('Metric'));
        expect(csv.data!, contains('Value'));
        expect(csv.data!, contains('student1'));
      });

      test('weekly trend rows use the ISO week number in the Week column', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);

        final csv = await tracker.exportProgressCSV('student1');

        final weekStart = now.subtract(const Duration(days: 6));
        final expectedRow = '"student1",${weekStart.year}-W${_referenceIsoWeekNumber(weekStart)},"1"';
        expect(csv.data, contains(expectedRow));
      });
    });

    group('exportQuestionsAndAttemptsCSV', () {
      test('returns CSV with attempt data', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);
        final csv = await tracker.exportQuestionsAndAttemptsCSV('student1');
        expect(csv.data!, contains('Question ID'));
        expect(csv.data!, contains('q1'));
      });
    });

    group('error handling', () {
      test('getOverallStats propagates failure when repo throws', () async {
        mockRepo.shouldThrow = true;
        final stats = await tracker.getOverallStats('student1');
        expect(stats.isFailure, isTrue);
      });

      test('getTopicProgress propagates failure when repo throws', () async {
        mockRepo.shouldThrow = true;
        final progress = await tracker.getTopicProgress('student1', 'topic1');
        expect(progress.isFailure, isTrue);
      });

      test('getRecommendations propagates failure when repo throws', () async {
        mockRepo.shouldThrow = true;
        final recommendations = await tracker.getRecommendations('student1');
        expect(recommendations.isFailure, isTrue);
      });

      test('getWeeklyTrend propagates failure when repo throws', () async {
        mockRepo.shouldThrow = true;
        final trend = await tracker.getWeeklyTrend(4);
        expect(trend.isFailure, isTrue);
      });

      test('getWeeklyTrend returns empty but success when repo succeeds with no data', () async {
        mockRepo.setAttempts([]);
        final trend = await tracker.getWeeklyTrend(4);
        expect(trend.isSuccess, isTrue);
      });

      test('getBadges still succeeds when attempt repo fails (badgeService independent)', () async {
        mockRepo.shouldThrow = true;
        final badges = await tracker.getBadges('student1');
        expect(badges.isSuccess, isTrue);
      });

      test('exportProgressCSV propagates failure when repo throws', () async {
        mockRepo.shouldThrow = true;
        final csv = await tracker.exportProgressCSV('student1');
        expect(csv.isFailure, isTrue);
      });

      test('exportQuestionsAndAttemptsCSV propagates failure when repo throws', () async {
        mockRepo.shouldThrow = true;
        final csv = await tracker.exportQuestionsAndAttemptsCSV('student1');
        expect(csv.isFailure, isTrue);
      });

      test('exportSessionHistoryCSV propagates failure when repo throws', () async {
        mockRepo.shouldThrow = true;
        final csv = await tracker.exportSessionHistoryCSV('student1');
        expect(csv.isFailure, isTrue);
      });

      test('getTopicMasteryLevelEnum propagates failure when repo throws', () async {
        mockRepo.shouldThrow = true;
        final level = await tracker.getTopicMasteryLevelEnum('topic1', studentId: 'student1');
        expect(level.isFailure, isTrue);
      });
    });

    group('getDailyTrend', () {
      test('returns daily trend entries for given period', () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));

        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: yesterday.add(const Duration(hours: 10)), subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'q2', isCorrect: false, timeSpentMs: 3000, timestamp: yesterday.add(const Duration(hours: 14)), subjectId: 'math'),
          StudentAttempt(id: 'a3', studentId: 'student1', questionId: 'q3', isCorrect: true, timeSpentMs: 4000, timestamp: today.add(const Duration(hours: 8)), subjectId: 'math'),
        ]);

        final result = await tracker.getDailyTrend(7, studentId: 'student1');

        expect(result.isSuccess, isTrue);
        final trend = result.data!;
        expect(trend.length, equals(7));

        final yesterdayEntry = trend.firstWhere(
          (e) => (e['date'] as String).startsWith(yesterday.toIso8601String().substring(0, 10)),
          orElse: () => {},
        );
        expect(yesterdayEntry['attempts'], equals(2));
        expect(yesterdayEntry['accuracy'], equals(50));

        final todayEntry = trend.firstWhere(
          (e) => (e['date'] as String).startsWith(today.toIso8601String().substring(0, 10)),
          orElse: () => {},
        );
        expect(todayEntry['attempts'], equals(1));
        expect(todayEntry['accuracy'], equals(100));
      });

      test('returns zero attempts for days with no activity', () async {
        final result = await tracker.getDailyTrend(3, studentId: 'student1');

        expect(result.isSuccess, isTrue);
        final trend = result.data!;
        expect(trend.length, equals(3));
        for (final entry in trend) {
          expect(entry['attempts'], equals(0));
          expect(entry['compositeScore'], equals(0.0));
        }
      });

      test('computes composite score based on multiple factors', () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: today.add(const Duration(hours: 10)), subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'q2', isCorrect: true, timeSpentMs: 3000, timestamp: today.add(const Duration(hours: 11)), subjectId: 'math'),
        ]);

        final result = await tracker.getDailyTrend(1, studentId: 'student1');

        expect(result.isSuccess, isTrue);
        final entry = result.data!.first;
        expect(entry['attempts'], equals(2));
        expect(entry['accuracy'], equals(100));
        final composite = entry['compositeScore'] as double;
        expect(composite, greaterThan(0.0));
        expect(composite, lessThanOrEqualTo(1.0));
      });

      test('propagates failure when repo fails', () async {
        mockRepo.shouldThrow = true;
        final result = await tracker.getDailyTrend(7, studentId: 'student1');
        expect(result.isFailure, isTrue);
      });
    });

    group('exportSessionHistoryCSV', () {
      test('returns CSV with session data', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);
        final csv = await tracker.exportSessionHistoryCSV('student1');
        expect(csv.isSuccess, isTrue);
        expect(csv.data, contains('Topic ID'));
        expect(csv.data, contains('q1'));
      });
    });
  });
}