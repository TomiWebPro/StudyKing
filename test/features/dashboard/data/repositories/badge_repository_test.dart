import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/dashboard/data/models/badge_model.dart';
import 'package:studyking/features/dashboard/data/repositories/badge_repository.dart';

class _FakeBadgeBox implements Box<BadgeModel> {
  final Map<dynamic, BadgeModel> _storage = {};

  @override
  Iterable<BadgeModel> get values => _storage.values;

  @override
  BadgeModel? get(dynamic key, {BadgeModel? defaultValue}) =>
      _storage[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, BadgeModel value) async {
    _storage[key.toString()] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _storage.remove(key.toString());
  }

  @override
  Future<int> clear() async {
    final count = _storage.length;
    _storage.clear();
    return count;
  }

  @override
  bool get isOpen => true;

  @override
  String get name => 'badges';

  @override
  int get length => _storage.length;

  @override
  bool get isNotEmpty => _storage.isNotEmpty;

  @override
  bool get isEmpty => _storage.isEmpty;

  @override
  bool containsKey(dynamic key) => _storage.containsKey(key.toString());

  @override
  Stream<BoxEvent> watch({dynamic key}) => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  group('BadgeRepository (attached to fake box)', () {
    late BadgeRepository repository;
    late _FakeBadgeBox fakeBox;

    setUp(() {
      repository = BadgeRepository();
      fakeBox = _FakeBadgeBox();
      repository.attachBox(fakeBox);
    });

    group('create', () {
      test('stores a badge', () async {
        final badge = createTestBadge();
        await repository.create(badge);
        final stored = await repository.get(badge.id);
        expect(stored, isNotNull);
        expect(stored?.name, 'First Step');
      });

      test('overwrites existing badge with same id', () async {
        await repository.create(createTestBadge(id: 'badge-1', name: 'Original'));
        await repository.create(createTestBadge(id: 'badge-1', name: 'Updated'));
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

      test('orders by unlockedAt descending with multiple badges', () async {
        final first = DateTime(2024, 3, 1);
        final second = DateTime(2024, 2, 1);
        final third = DateTime(2024, 1, 1);
        await repository.create(createTestBadge(
            id: 'b1', studentId: 's1', unlockedAt: third));
        await repository.create(createTestBadge(
            id: 'b2', studentId: 's1', unlockedAt: second));
        await repository.create(createTestBadge(
            id: 'b3', studentId: 's1', unlockedAt: first));
        final result = await repository.getByStudent('s1');
        expect(result[0].id, 'b3');
        expect(result[1].id, 'b2');
        expect(result[2].id, 'b1');
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
        await repository.create(createTestBadge(
            id: 'b1', studentId: 's1', name: 'First'));
        await repository.create(createTestBadge(
            id: 'b2', studentId: 's1', name: 'Second'));
        await repository.create(createTestBadge(
            id: 'b3', studentId: 's2'));
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
        await repository.create(createTestBadge(
            id: 'b1', studentId: 's1'));
        await repository.create(createTestBadge(
            id: 'b2', studentId: 's1'));
        await repository.create(createTestBadge(
            id: 'b3', studentId: 's2'));
        expect(await repository.getBadgeCount('s1'), 2);
      });

      test('returns zero when student has no badges', () async {
        expect(await repository.getBadgeCount('none'), 0);
      });

      test('counts multiple badges for same student', () async {
        for (int i = 1; i <= 5; i++) {
          await repository.create(createTestBadge(
              id: 'b$i', studentId: 's1'));
        }
        expect(await repository.getBadgeCount('s1'), 5);
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
