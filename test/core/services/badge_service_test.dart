import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/services/badge_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/dashboard/data/models/badge_model.dart';
import 'package:studyking/features/dashboard/data/repositories/badge_repository.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';

class _FakeBadgeRepository implements BadgeRepository {
  final List<BadgeModel> _badges = [];
  Map<String, BadgeModel> _badgeMap = {};
  bool _hasBadgeResult = false;
  int _badgeCount = 0;

  @override
  Future<void> init() async {}

  @override
  Future<List<BadgeModel>> getByStudent(String studentId) async => _badges;

  @override
  Future<Map<String, BadgeModel>> getBadgeMap(String studentId) async => _badgeMap;

  @override
  Future<void> create(BadgeModel badge) async {
    _badges.add(badge);
    _badgeMap = {for (final b in _badges) b.name: b};
  }

  @override
  Future<bool> hasBadge(String studentId, String badgeId) async => _hasBadgeResult;

  @override
  Future<int> getBadgeCount(String studentId) async => _badgeCount;

  @override
  Future<void> openBox(String boxName) async {}

  @override
  void attachBox(Box<BadgeModel> box) {}

  @override
  Future<Result<void>> save(String key, BadgeModel item) async => Result.success(null);

  @override
  Future<Result<BadgeModel?>> get(String key) async => Result.success(null);

  @override
  Future<Result<List<BadgeModel>>> getAll() async => Result.success([]);

  @override
  Future<Result<void>> delete(String key) async => Result.success(null);

  @override
  List<BadgeModel> filterBy<K>(K Function(BadgeModel) getter, K value) => [];

  @override
  Future<Result<void>> put(String key, BadgeModel item) async => Result.success(null);

  @override
  Box<BadgeModel> get box => _box!;
  Box<BadgeModel>? _box;
}

class _FakeAttemptRepository extends AttemptRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);
  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async => Result.success([]);
  @override
  Future<Result<StudentAttempt?>> get(String id) async => Result.success(null);
  @override
  Future<Result<List<StudentAttempt>>> getAll() async => Result.success([]);
  @override
  Future<Result<List<StudentAttempt>>> getByStudentAndSubject(String studentId, String subjectId) async => Result.success([]);
  @override
  Future<Result<List<StudentAttempt>>> getByQuestion(String questionId) async => Result.success([]);
  @override
  Future<Result<List<StudentAttempt>>> getBySubject(String subjectId) async => Result.success([]);
  @override
  Future<Result<void>> create(StudentAttempt attempt) async => Result.success(null);
  @override
  Future<Result<Map<String, dynamic>>> getSubjectStats(String subjectId) async => Result.success({});
  @override
  Future<Result<void>> delete(String id) async => Result.success(null);
}

class _FakeBadgeTracker extends StudyProgressTracker {
  _FakeBadgeTracker() : super(attemptRepo: _FakeAttemptRepository());

  @override
  Future<Map<String, dynamic>> getOverallStats(String studentId) async {
    return {
      'totalAttempts': 0,
      'correctAttempts': 0,
      'accuracy': 0,
      'totalStudyTimeHours': 0.0,
      'weeklyActivity': 0,
      'dailyActivity': 0,
      'topicsStudied': 0,
    };
  }
}

void main() {
  group('BadgeService', () {
    late _FakeBadgeRepository mockRepo;
    late BadgeService service;

    setUp(() {
      mockRepo = _FakeBadgeRepository();
      service = BadgeService(
        repository: mockRepo,
        tracker: _FakeBadgeTracker(),
        notificationService: null,
      );
    });

    group('getBadges', () {
      test('returns empty list when no badges', () async {
        final badges = await service.getBadges('student1');
        expect(badges, isEmpty);
      });

      test('returns badges from repository', () async {
        mockRepo._badges.add(BadgeModel(
          id: 'first_attempt_student1', studentId: 'student1',
          name: 'First Step', description: 'First question',
        ));
        final badges = await service.getBadges('student1');
        expect(badges, hasLength(1));
        expect(badges.first.name, equals('First Step'));
      });
    });

    group('checkAndUnlockBadges', () {
      test('runs without errors with minimal stats', () async {
        final unlocked = await service.checkAndUnlockBadges('student1');
        expect(unlocked, isEmpty);
      });
    });

    group('hasBadge', () {
      test('returns true when badge exists', () async {
        mockRepo._hasBadgeResult = true;
        expect(await service.hasBadge('student1', 'century'), isTrue);
      });

      test('returns false when badge does not exist', () async {
        mockRepo._hasBadgeResult = false;
        expect(await service.hasBadge('student1', 'nonexistent'), isFalse);
      });
    });

    group('getBadgeCount', () {
      test('returns badge count from repository', () async {
        mockRepo._badgeCount = 3;
        expect(await service.getBadgeCount('student1'), equals(3));
      });
    });

    group('getBadgesByCategory', () {
      test('returns empty map when no badges', () async {
        final categorized = await service.getBadgesByCategory('student1');
        expect(categorized, isEmpty);
      });

      test('groups badges by category', () async {
        mockRepo._badges.addAll([
          BadgeModel(
            id: 'b1', studentId: 's1', name: 'First Step',
            description: 'd', category: 'milestone',
          ),
          BadgeModel(
            id: 'b2', studentId: 's1', name: 'Century',
            description: 'd', category: 'milestone',
          ),
          BadgeModel(
            id: 'b3', studentId: 's1', name: 'Gold',
            description: 'd', category: 'accuracy',
          ),
        ]);

        final categorized = await service.getBadgesByCategory('s1');

        expect(categorized.length, equals(2));
        expect(categorized['milestone']!.length, equals(2));
        expect(categorized['accuracy']!.length, equals(1));
      });
    });

    group('getLockedBadges', () {
      test('returns all definitions when no badges are earned', () async {
        final locked = await service.getLockedBadges('student1');
        expect(locked, hasLength(BadgeDefinitions.all.length));
      });

      test('excludes earned badges from locked list', () async {
        mockRepo._badgeMap = {
          'first_attempt': BadgeModel(
            id: 'fa_s1', studentId: 's1', name: 'FS', description: 'd',
          ),
        };
        final locked = await service.getLockedBadges('student1');
        expect(locked.length, lessThan(BadgeDefinitions.all.length));
      });
    });

    group('getBadgeStats', () {
      test('returns stats with zero unlocked badges', () async {
        final stats = await service.getBadgeStats('student1');
        expect(stats['total'], greaterThan(0));
        expect(stats['unlocked'], equals(0));
        expect(stats['locked'], greaterThan(0));
        expect(stats['completionPercentage'], equals(0.0));
      });

      test('returns stats with some unlocked badges', () async {
        mockRepo._badges.add(BadgeModel(
          id: 'b1', studentId: 's1', name: 'First Step', description: 'd',
        ));

        final stats = await service.getBadgeStats('s1');
        expect(stats['unlocked'], equals(1));
        expect(stats['locked'], equals(stats['total'] - 1));
      });
    });
  });
}
