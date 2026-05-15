import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/data/repositories/badge_repository.dart';
import 'package:studyking/core/data/models/badge_model.dart';

class _MockBadgeRepository extends BadgeRepository {
  final Map<String, BadgeModel> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> create(BadgeModel badge) async {
    _storage[badge.id] = badge;
  }

  @override
  Future<BadgeModel?> get(String id) async {
    return _storage[id];
  }

  @override
  Future<List<BadgeModel>> getByStudent(String studentId) async {
    return _storage.values
        .where((b) => b.studentId == studentId)
        .toList()
      ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
  }

  @override
  Future<bool> hasBadge(String studentId, String badgeId) async {
    return _storage.values
        .any((b) => b.studentId == studentId && b.id == badgeId);
  }

  @override
  Future<Map<String, BadgeModel>> getBadgeMap(String studentId) async {
    final badges = await getByStudent(studentId);
    return {for (final b in badges) b.id: b};
  }

  @override
  Future<int> getBadgeCount(String studentId) async {
    return _storage.values
        .where((b) => b.studentId == studentId)
        .length;
  }

  @override
  Future<void> delete(String id) async {
    _storage.remove(id);
  }

  @override
  Future<List<BadgeModel>> getAll() async {
    return _storage.values.toList();
  }
}

BadgeModel createTestBadge({
  String id = 'badge-1',
  String studentId = 'student-1',
  String name = 'First Step',
  String description = 'Answered your first question!',
  String iconName = 'emoji_events',
  String category = 'milestone',
  DateTime? unlockedAt,
}) {
  return BadgeModel(
    id: id,
    studentId: studentId,
    name: name,
    description: description,
    iconName: iconName,
    category: category,
    unlockedAt: unlockedAt,
  );
}

void main() {
  group('BadgeRepository', () {
    late _MockBadgeRepository repository;

    setUp(() {
      repository = _MockBadgeRepository();
    });

    group('save', () {
      test('stores a badge', () async {
        final badge = createTestBadge();
        await repository.create(badge);
        final stored = await repository.get('badge-1');
        expect(stored, isNotNull);
        expect(stored?.name, 'First Step');
      });

      test('overwrites existing badge with same id', () async {
        await repository.create(createTestBadge(name: 'Original'));
        await repository.create(createTestBadge(name: 'Updated'));
        expect((await repository.get('badge-1'))?.name, 'Updated');
      });
    });

    group('get', () {
      test('returns null for non-existent badge', () async {
        expect(await repository.get('none'), isNull);
      });

      test('returns stored badge', () async {
        await repository.create(createTestBadge());
        final result = await repository.get('badge-1');
        expect(result?.id, 'badge-1');
        expect(result?.studentId, 'student-1');
        expect(result?.category, 'milestone');
      });
    });

    group('getByStudent', () {
      test('returns badges for student sorted by unlockedAt descending', () async {
        final earlier = DateTime(2024, 1, 1);
        final later = DateTime(2024, 6, 1);
        await repository.create(createTestBadge(
          id: 'b1', studentId: 's1', unlockedAt: earlier));
        await repository.create(createTestBadge(
          id: 'b2', studentId: 's1', unlockedAt: later));
        await repository.create(createTestBadge(
          id: 'b3', studentId: 's2'));
        final result = await repository.getByStudent('s1');
        expect(result.length, 2);
        expect(result.first.id, 'b2');
      });

      test('returns empty list for student with no badges', () async {
        expect(await repository.getByStudent('none'), isEmpty);
      });
    });

    group('hasBadge', () {
      test('returns true when student has the badge', () async {
        await repository.create(createTestBadge(id: 'b1', studentId: 's1'));
        expect(await repository.hasBadge('s1', 'b1'), isTrue);
      });

      test('returns false when student lacks the badge', () async {
        await repository.create(createTestBadge(id: 'b1', studentId: 's1'));
        expect(await repository.hasBadge('s1', 'b2'), isFalse);
      });

      test('returns false when different student has the badge', () async {
        await repository.create(createTestBadge(id: 'b1', studentId: 's1'));
        expect(await repository.hasBadge('s2', 'b1'), isFalse);
      });
    });

    group('getBadgeMap', () {
      test('returns map of badge id to badge for student', () async {
        await repository.create(createTestBadge(id: 'b1', studentId: 's1', name: 'First'));
        await repository.create(createTestBadge(id: 'b2', studentId: 's1', name: 'Second'));
        await repository.create(createTestBadge(id: 'b3', studentId: 's2'));
        final map = await repository.getBadgeMap('s1');
        expect(map.length, 2);
        expect(map['b1']?.name, 'First');
        expect(map['b2']?.name, 'Second');
        expect(map['b3'], isNull);
      });

      test('returns empty map when student has no badges', () async {
        expect(await repository.getBadgeMap('none'), isEmpty);
      });
    });

    group('getBadgeCount', () {
      test('returns correct count for student', () async {
        await repository.create(createTestBadge(id: 'b1', studentId: 's1'));
        await repository.create(createTestBadge(id: 'b2', studentId: 's1'));
        await repository.create(createTestBadge(id: 'b3', studentId: 's2'));
        expect(await repository.getBadgeCount('s1'), 2);
      });

      test('returns zero when student has no badges', () async {
        expect(await repository.getBadgeCount('none'), 0);
      });
    });

    group('getAll', () {
      test('returns all badges', () async {
        await repository.create(createTestBadge(id: 'b1'));
        await repository.create(createTestBadge(id: 'b2'));
        expect((await repository.getAll()).length, 2);
      });

      test('returns empty when no badges', () async {
        expect(await repository.getAll(), isEmpty);
      });
    });

    group('delete', () {
      test('removes a badge', () async {
        await repository.create(createTestBadge());
        await repository.delete('badge-1');
        expect(await repository.get('badge-1'), isNull);
      });

      test('does nothing for non-existent id', () async {
        await repository.delete('none');
      });
    });
  });
}
