import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
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
  Future<List<StudentAttempt>> getByStudent(String studentId) async {
    return _attempts.where((a) => a.studentId == studentId).toList();
  }

  @override
  Future<void> create(StudentAttempt attempt) async {
    _attempts.add(attempt);
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
  Future<List<StudentAttempt>> getByStudentAndSubject(String studentId, String subjectId) async {
    return _attempts.where((a) => a.studentId == studentId && a.subjectId == subjectId).toList();
  }

  @override
  Future<List<StudentAttempt>> getByQuestion(String questionId) async {
    return _attempts.where((a) => a.questionId == questionId).toList();
  }

  @override
  Future<List<StudentAttempt>> getBySubject(String subjectId) async {
    return _attempts.where((a) => a.subjectId == subjectId).toList();
  }

  @override
  Future<Map<String, dynamic>> getSubjectStats(String subjectId) async {
    return {};
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

void main() {
  group('StudyProgressTracker', () {
    late StudyProgressTracker tracker;
    late FakeAttemptRepository mockRepo;
    late FakeSessionRepository mockSessionRepo;

    setUp(() {
      mockRepo = FakeAttemptRepository();
      mockSessionRepo = FakeSessionRepository();
      tracker = StudyProgressTracker(
        attemptRepo: mockRepo,
        sessionRepo: mockSessionRepo,
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

        expect(stats['avgTimePerQuestion'], equals(7));
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
        expect(progress['accuracy'], equals(66));
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
      test('returns first attempt badge', () async {
        final now = DateTime.now();
        mockRepo.setAttempts([
          StudentAttempt(id: 'a1', studentId: 'student1', questionId: 'q1', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math'),
        ]);

        final badges = await tracker.getBadges('student1');

        expect(badges.any((b) => b['id'] == 'first_attempt'), isTrue);
      });

      test('returns century badge for 100+ attempts', () async {
        final now = DateTime.now();
        final attempts = List.generate(100, (i) => StudentAttempt(
          id: 'a$i', studentId: 'student1', questionId: 'q$i', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math',
        ));
        mockRepo.setAttempts(attempts);

        final badges = await tracker.getBadges('student1');

        expect(badges.any((b) => b['id'] == 'century'), isTrue);
      });

      test('returns accuracy gold badge for 90%+ accuracy', () async {
        final now = DateTime.now();
        final attempts = List.generate(10, (i) => StudentAttempt(
          id: 'a$i', studentId: 'student1', questionId: 'q$i', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math',
        ));
        mockRepo.setAttempts(attempts);

        final badges = await tracker.getBadges('student1');

        expect(badges.any((b) => b['id'] == 'accuracy_gold'), isTrue);
      });

      test('returns daily streak badge for 5+ daily attempts', () async {
        final now = DateTime.now();
        final attempts = List.generate(5, (i) => StudentAttempt(
          id: 'a$i', studentId: 'student1', questionId: 'q$i', isCorrect: true, timeSpentMs: 5000, timestamp: now, subjectId: 'math',
        ));
        mockRepo.setAttempts(attempts);

        final badges = await tracker.getBadges('student1');

        expect(badges.any((b) => b['id'] == 'daily_streak'), isTrue);
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