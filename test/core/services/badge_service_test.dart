import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/services/badge_service.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/dashboard/data/models/badge_model.dart';
import 'package:studyking/features/dashboard/data/repositories/badge_repository.dart';

class _FakeBadgeRepository implements BadgeRepository {
  final List<BadgeModel> _badges = [];
  Map<String, BadgeModel> _badgeMap = {};
  bool _hasBadgeResult = false;
  int _badgeCount = 0;
  bool failGetByStudent = false;
  bool failGetBadgeMap = false;
  bool failHasBadge = false;
  bool failGetBadgeCount = false;

  @override
  bool get isOpen => true;

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<BadgeModel>>> getByStudent(String studentId) async {
    if (failGetByStudent) return Result.failure('getByStudent failed');
    return Result.success(List<BadgeModel>.from(_badges));
  }

  @override
  Future<Result<Map<String, BadgeModel>>> getBadgeMap(String studentId) async {
    if (failGetBadgeMap) return Result.failure('getBadgeMap failed');
    return Result.success(Map<String, BadgeModel>.from(_badgeMap));
  }

  @override
  Future<void> create(BadgeModel badge) async {
    _badges.add(badge);
    _badgeMap = {for (final b in _badges) b.id: b};
  }

  @override
  Future<Result<bool>> hasBadge(String studentId, String badgeId) async {
    if (failHasBadge) return Result.failure('hasBadge failed');
    return Result.success(_hasBadgeResult);
  }

  @override
  Future<Result<int>> getBadgeCount(String studentId) async {
    if (failGetBadgeCount) return Result.failure('getBadgeCount failed');
    return Result.success(_badgeCount);
  }

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

List<String> _capturedLogs = [];
void _installLogCapture() {
  _capturedLogs.clear();
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) _capturedLogs.add(message);
  };
}

void _uninstallLogCapture() {
  debugPrint = debugPrintThrottled;
}

void main() {
  group('BadgeService', () {
    late _FakeBadgeRepository mockRepo;
    late BadgeService service;

    setUp(() {
      mockRepo = _FakeBadgeRepository();
      service = BadgeService(
        repository: mockRepo,
        getStats: (studentId) async => Result.success({
          'totalAttempts': 0,
          'correctAttempts': 0,
          'accuracy': 0,
          'totalStudyTimeHours': 0.0,
          'weeklyActivity': 0,
          'dailyActivity': 0,
          'topicsStudied': 0,
        }),
        notificationService: null,
      );
    });

    group('getBadges', () {
      test('returns empty list when no badges', () async {
        final badges = await service.getBadges('student1');
        expect(badges.isSuccess, isTrue);
        expect(badges.data!, isEmpty);
      });

      test('returns badges from repository', () async {
        mockRepo._badges.add(BadgeModel(
          id: 'first_attempt_student1', studentId: 'student1',
          name: 'First Step', description: 'First question',
        ));
        final badges = await service.getBadges('student1');
        expect(badges.data!, hasLength(1));
        expect(badges.data!.first.name, equals('First Step'));
      });

      test('propagates failure when repository fails', () async {
        mockRepo.failGetByStudent = true;
        final result = await service.getBadges('student1');
        expect(result.isFailure, isTrue);
        expect(result.error, contains('getByStudent failed'));
      });

      test('behavioral: uses injected repository via override', () async {
        final custom = _FakeBadgeRepository();
        custom._badges.add(BadgeModel(
          id: 'custom_badge', studentId: 's1', name: 'Custom', description: 'd',
        ));
        final customService = BadgeService(
          repository: custom,
          getStats: (id) async => Result.success({}),
          notificationService: null,
        );
        final result = await customService.getBadges('s1');
        expect(result.isSuccess, isTrue);
        expect(result.data!.first.id, 'custom_badge');
      });
    });

    group('checkAndUnlockBadges', () {
      test('runs without errors with minimal stats', () async {
        final unlocked = await service.checkAndUnlockBadges('student1');
        expect(unlocked.isSuccess, isTrue);
        expect(unlocked.data!, isEmpty);
      });

      test('propagates getBadgeMap failure', () async {
        mockRepo.failGetBadgeMap = true;
        final result = await service.checkAndUnlockBadges('student1');
        expect(result.isFailure, isTrue);
      });
    });

    group('hasBadge', () {
      test('returns true when badge exists', () async {
        mockRepo._hasBadgeResult = true;
        expect((await service.hasBadge('student1', 'century')).data!, isTrue);
      });

      test('returns false when badge does not exist', () async {
        mockRepo._hasBadgeResult = false;
        expect((await service.hasBadge('student1', 'nonexistent')).data!, isFalse);
      });

      test('propagates failure when repository fails', () async {
        mockRepo.failHasBadge = true;
        final result = await service.hasBadge('student1', 'any');
        expect(result.isFailure, isTrue);
      });
    });

    group('getBadgeCount', () {
      test('returns badge count from repository', () async {
        mockRepo._badgeCount = 3;
        expect((await service.getBadgeCount('student1')).data!, equals(3));
      });

      test('propagates failure when repository fails', () async {
        mockRepo.failGetBadgeCount = true;
        final result = await service.getBadgeCount('student1');
        expect(result.isFailure, isTrue);
      });
    });

    group('getBadgesByCategory', () {
      test('returns empty map when no badges', () async {
        final categorized = await service.getBadgesByCategory('student1');
        expect(categorized.isSuccess, isTrue);
        expect(categorized.data!, isEmpty);
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

        expect(categorized.data!.length, equals(2));
        expect(categorized.data!['milestone']!.length, equals(2));
        expect(categorized.data!['accuracy']!.length, equals(1));
      });
    });

    group('getLockedBadges', () {
      test('returns all definitions when no badges are earned', () async {
        final locked = await service.getLockedBadges('student1');
        expect(locked.isSuccess, isTrue);
        expect(locked.data!, hasLength(BadgeDefinitions.all.length));
      });

      test('excludes earned badges from locked list', () async {
        mockRepo._badgeMap = {
          'first_attempt': BadgeModel(
            id: 'fa_s1', studentId: 's1', name: 'FS', description: 'd',
          ),
        };
        final locked = await service.getLockedBadges('student1');
        expect(locked.isSuccess, isTrue);
        expect(locked.data!.length, lessThan(BadgeDefinitions.all.length));
      });

      test('propagates failure when getBadgeMap fails', () async {
        mockRepo.failGetBadgeMap = true;
        final result = await service.getLockedBadges('student1');
        expect(result.isFailure, isTrue);
      });
    });

    group('getBadgeStats', () {
      test('returns stats with zero unlocked badges', () async {
        final stats = await service.getBadgeStats('student1');
        expect(stats.isSuccess, isTrue);
        expect(stats.data!['total'], greaterThan(0));
        expect(stats.data!['unlocked'], equals(0));
        expect(stats.data!['locked'], greaterThan(0));
        expect(stats.data!['completionPercentage'], equals(0.0));
      });

      test('returns stats with some unlocked badges', () async {
        mockRepo._badges.add(BadgeModel(
          id: 'b1', studentId: 's1', name: 'First Step', description: 'd',
        ));

        final stats = await service.getBadgeStats('s1');
        expect(stats.isSuccess, isTrue);
        expect(stats.data!['unlocked'], equals(1));
        expect(stats.data!['locked'], equals(stats.data!['total'] - 1));
      });
    });

    group('checkAndUnlockBadges with failing stats', () {
      test('logs warning, degrades gracefully and unlocks nothing when getStats fails', () async {
        _installLogCapture();
        addTearDown(_uninstallLogCapture);

        final failingService = BadgeService(
          repository: mockRepo,
          getStats: (studentId) async => Result.failure('stats unavailable'),
          notificationService: null,
        );

        final result = await failingService.checkAndUnlockBadges('student1');

        expect(result.isSuccess, isTrue);
        expect(result.data!, isEmpty);
        expect(
          _capturedLogs.any((l) => l.contains('[W]') && l.contains('getStats')),
          isTrue,
        );
      });
    });
  });
}
