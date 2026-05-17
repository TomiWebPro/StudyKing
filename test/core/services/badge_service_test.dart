import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/services/badge_service.dart';
import 'package:studyking/features/dashboard/data/models/badge_model.dart';
import 'package:studyking/features/dashboard/data/repositories/badge_repository.dart';

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
  Future<void> save(String key, BadgeModel item) async {}

  @override
  Future<BadgeModel?> get(String key) async => null;

  @override
  Future<List<BadgeModel>> getAll() async => [];

  @override
  Future<void> delete(String key) async {}

  @override
  List<BadgeModel> filterBy<K>(K Function(BadgeModel) getter, K value) => [];

  @override
  Box<BadgeModel> get box => _box!;
  Box<BadgeModel>? _box;
}

class _FakeStudyProgressTracker {
  final Map<String, dynamic> overallStats;

  _FakeStudyProgressTracker(this.overallStats);

  Future<Map<String, dynamic>> getOverallStats(String studentId) async => overallStats;
}

class _FakeNotificationService {
  bool badgeUnlockedCalled = false;

  Future<void> showBadgeUnlocked({
    required int id,
    required String badgeName,
    required String badgeDescription,
  }) async {
    badgeUnlockedCalled = true;
  }
}

void main() {
  group('BadgeService', () {
    late _FakeBadgeRepository mockRepo;
    late _FakeStudyProgressTracker mockTracker;
    late _FakeNotificationService mockNotif;
    late BadgeService service;

    setUp(() {
      mockRepo = _FakeBadgeRepository();
      mockTracker = _FakeStudyProgressTracker({
        'totalAttempts': 0, 'correctAttempts': 0, 'accuracy': 0,
        'totalStudyTimeHours': 0, 'weeklyActivity': 0, 'dailyActivity': 0, 'topicsStudied': 0,
      });
      mockNotif = _FakeNotificationService();
      service = BadgeService(
        repository: mockRepo,
        tracker: mockTracker as dynamic,
        notificationService: mockNotif as dynamic,
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
      test('unlocks first_attempt badge when totalAttempts >= 1', () async {
        mockTracker = _FakeStudyProgressTracker({
          'totalAttempts': 1, 'correctAttempts': 1, 'accuracy': 100,
          'totalStudyTimeHours': 0, 'weeklyActivity': 0, 'dailyActivity': 0, 'topicsStudied': 1,
        });
        service = BadgeService(
          repository: mockRepo,
          tracker: mockTracker as dynamic,
          notificationService: mockNotif as dynamic,
        );
        final unlocked = await service.checkAndUnlockBadges('student1');
        expect(unlocked, hasLength(1));
        expect(unlocked.first.name, equals('First Step'));
        expect(mockNotif.badgeUnlockedCalled, isTrue);
      });

      test('does not unlock already earned badges', () async {
        mockRepo._badgeMap = {
          'first_attempt': BadgeModel(id: 'fa_s1', studentId: 's1', name: 'FS', description: 'd'),
        };
        mockTracker = _FakeStudyProgressTracker({
          'totalAttempts': 100, 'correctAttempts': 50, 'accuracy': 50,
          'totalStudyTimeHours': 5, 'weeklyActivity': 3, 'dailyActivity': 1, 'topicsStudied': 2,
        });
        service = BadgeService(
          repository: mockRepo,
          tracker: mockTracker as dynamic,
          notificationService: mockNotif as dynamic,
        );
        final unlocked = await service.checkAndUnlockBadges('student1');
        expect(unlocked.where((b) => b.name == 'FS'), isEmpty);
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

    group('getLockedBadges', () {
      test('returns all badges when none are earned', () async {
        final locked = await service.getLockedBadges('student1');
        expect(locked, hasLength(BadgeDefinitions.all.length));
      });
    });
  });
}
