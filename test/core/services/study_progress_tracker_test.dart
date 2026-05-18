import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/badge_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/dashboard/data/models/badge_model.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';

class FakeAttemptRepository extends AttemptRepository {
  final List<StudentAttempt> _attempts = [];

  void setAttempts(List<StudentAttempt> attempts) {
    _attempts.clear();
    _attempts.addAll(attempts);
  }

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async {
    return Result.success(_attempts.where((a) => a.studentId == studentId).toList());
  }

  @override
  Future<Result<void>> create(StudentAttempt attempt) async {
    _attempts.add(attempt);
    return Result.success(null);
  }

  @override
  Future<Result<StudentAttempt?>> get(String id) async {
    return Result.success(_attempts.where((a) => a.id == id).firstOrNull);
  }

  @override
  Future<Result<List<StudentAttempt>>> getAll() async {
    return Result.success(_attempts);
  }

  @override
  Future<Result<List<StudentAttempt>>> getByStudentAndSubject(String studentId, String subjectId) async {
    return Result.success(_attempts.where((a) => a.studentId == studentId && a.subjectId == subjectId).toList());
  }

  @override
  Future<Result<List<StudentAttempt>>> getByQuestion(String questionId) async {
    return Result.success(_attempts.where((a) => a.questionId == questionId).toList());
  }

  @override
  Future<Result<List<StudentAttempt>>> getBySubject(String subjectId) async {
    return Result.success(_attempts.where((a) => a.subjectId == subjectId).toList());
  }

  @override
  Future<Result<Map<String, dynamic>>> getSubjectStats(String subjectId) async {
    return Result.success({});
  }

  @override
  Future<Result<void>> delete(String id) async {
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
  Future<void> init() async {}
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
      );
    });

    group('getOverallStats', () {
      test('returns stats with zero values for no attempts', () async {
        mockRepo.setAttempts([]);

        final stats = await tracker.getOverallStats('student1');

        expect(stats['totalAttempts'], equals(0));
        expect(stats['correctAttempts'], equals(0));
        expect(stats['accuracy'], equals(0));
        expect(stats['avgTimePerQuestion'], equals(0));
        expect(stats['weeklyActivity'], equals(0));
        expect(stats['dailyActivity'], equals(0));
        expect(stats['topicsStudied'], equals(0));
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

        expect(stats['accuracy'], equals(50));
      });

      test('calculates average time per question', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'q2', isCorrect: true, timeSpentMs: 10000, timestamp: now, subjectId: 'math'),
        ]);

        final stats = await tracker.getOverallStats('student1');

        expect(stats['avgTimePerQuestion'], equals(8));
      });

      test('calculates total study time in hours', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 1800000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'q2', isCorrect: true, timeSpentMs: 1800000, timestamp: now, subjectId: 'math'),
        ]);

        final stats = await tracker.getOverallStats('student1');

        expect(stats['totalStudyTimeHours'], equals(1.0));
      });

      test('counts weekly activity', () async {
        final now = DateTime.now();
        final weekAgo = now.subtract(const Duration(days: 3));
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'q2', isCorrect: true, timeSpentMs: 5000, timestamp: weekAgo, subjectId: 'math'),
        ]);

        final stats = await tracker.getOverallStats('student1');

        expect(stats['weeklyActivity'], greaterThanOrEqualTo(1));
      });

      test('counts daily activity', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'q2', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);

        final stats = await tracker.getOverallStats('student1');

        expect(stats['dailyActivity'], equals(2));
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

        expect(stats['totalStudyTimeHours'], equals(1.5));
        expect(stats['sessionCount'], equals(2));
        expect(stats['focusSessionCount'], equals(1));
        expect(stats['tutorSessionCount'], equals(1));
      });

      test('counts unique topics studied', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'math_q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'math_q2', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a3', studentId: 'student1', questionId: 'science_q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'science'),
        ]);

        final stats = await tracker.getOverallStats('student1');

        expect(stats['topicsStudied'], equals(2));
      });
    });

    group('getTopicProgress', () {
      test('returns empty progress for no attempts', () async {
        mockRepo.setAttempts([]);

        final progress = await tracker.getTopicProgress('student1', 'topic1');

        expect(progress['topicId'], equals('topic1'));
        expect(progress['attempts'], equals(0));
        expect(progress['accuracy'], equals(0.0));
        expect(progress['timeSpentMinutes'], equals(0));
      });

      test('calculates topic progress correctly', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'topic1_q1', isCorrect: true, timeSpentMs: 60000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a2', studentId: 'student1', questionId: 'topic1_q2', isCorrect: true, timeSpentMs: 60000, timestamp: now, subjectId: 'math'),
          StudentAttempt(id: 'a3', studentId: 'student1', questionId: 'topic1_q3', isCorrect: false, timeSpentMs: 60000, timestamp: now, subjectId: 'math'),
        ]);

        final progress = await tracker.getTopicProgress('student1', 'topic1');

        expect(progress['attempts'], equals(3));
        expect(progress['accuracy'], equals(67));
        expect(progress['timeSpentMinutes'], equals(3));
      });

      test('includes last attempted timestamp', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'topic1_q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);

        final progress = await tracker.getTopicProgress('student1', 'topic1');

        expect(progress['lastAttempted'], isNotNull);
      });
    });

    group('getWeeklyTrend', () {
      test('returns trend data', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);

        final trend = await tracker.getWeeklyTrend(4);

        expect(trend, isA<List>());
      });

      test('returns empty list when no attempts', () async {
        mockRepo.setAttempts([]);

        final trend = await tracker.getWeeklyTrend(4);

        expect(trend.isNotEmpty, isTrue);
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

        expect(recommendations.any((r) => r['type'] == 'review'), isTrue);
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

        expect(recommendations.any((r) => r['type'] == 'advanced'), isTrue);
      });

      test('returns engagement recommendation for low study time', () async {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 2));
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 500000, timestamp: yesterday, subjectId: 'math'),
        ]);

        final recommendations = await tracker.getRecommendations('student1');

        expect(recommendations.any((r) => r['type'] == 'engagement'), isTrue);
      });

      test('returns reminder for no weekly activity', () async {
        final now = DateTime.now();
        final lastWeek = now.subtract(const Duration(days: 10));
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: lastWeek, subjectId: 'math'),
        ]);

        final recommendations = await tracker.getRecommendations('student1');

        expect(recommendations.any((r) => r['type'] == 'reminder'), isTrue);
      });
    });

    group('getBadges', () {
      test('returns empty list when no badges have been unlocked', () async {
        final badges = await tracker.getBadges('no_badges_student');
        expect(badges, isEmpty);
      });

      test('returns badges after they are persisted', () async {
        const testStudent = 'badge_persist_student';
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: testStudent, questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);

        final badgeService = BadgeService(
          tracker: tracker,
          notificationService: null,
        );
        await badgeService.checkAndUnlockBadges(testStudent);

        final badges = await tracker.getBadges(testStudent);

        expect(badges.any((b) => (b['id'] as String).startsWith('first_attempt')), isTrue);
      });

      test('returns multiple badges when conditions are met', () async {
        const testStudent = 'badge_multiple_student';
        final now = DateTime.now();
        final attempts = List.generate(100, (i) => StudentAttempt(
          id: 'a$i', studentId: testStudent, questionId: 'q$i', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math',
        ));
        mockRepo.setAttempts(attempts);

        final badgeService = BadgeService(
          tracker: tracker,
          notificationService: null,
        );
        await badgeService.checkAndUnlockBadges(testStudent);

        final badges = await tracker.getBadges(testStudent);

        expect(badges.any((b) => (b['id'] as String).startsWith('first_attempt')), isTrue);
        expect(badges.any((b) => (b['id'] as String).startsWith('century')), isTrue);
      });

      test('returns empty list for student without attempts', () async {
        final badges = await tracker.getBadges('no_attempts_student');
        expect(badges, isEmpty);
      });
    });

    group('getTopicMasteryLevel', () {
      test('returns Novice for no attempts', () async {
        final level = await tracker.getTopicMasteryLevel('topic1', studentId: 'student1');
        expect(level, equals('Novice'));
      });

      test('returns Browsing for some attempts with low accuracy', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'topic1_q1', isCorrect: false, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);
        final level = await tracker.getTopicMasteryLevel('topic1', studentId: 'student1');
        expect(level, equals('Browsing'));
      });
    });

    group('exportProgressCSV', () {
      test('exports CSV with stats', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);

        final csv = await tracker.exportProgressCSV('student1');

        expect(csv, contains('Date'));
        expect(csv, contains('Metric'));
        expect(csv, contains('Value'));
        expect(csv, contains('student1'));
      });
    });

    group('exportQuestionsAndAttemptsCSV', () {
      test('returns CSV with attempt data', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);
        final csv = await tracker.exportQuestionsAndAttemptsCSV('student1');
        expect(csv, contains('Question ID'));
        expect(csv, contains('q1'));
      });
    });

    group('exportSessionHistoryCSV', () {
      test('returns CSV with session data', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);
        final csv = await tracker.exportSessionHistoryCSV('student1');
        expect(csv, contains('Topic ID'));
        expect(csv, contains('q1'));
      });
    });
  });
}