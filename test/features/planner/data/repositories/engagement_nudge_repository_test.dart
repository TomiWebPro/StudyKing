import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/core/data/models/engagement_nudge_model.dart';

class _MockEngagementNudgeRepository extends EngagementNudgeRepository {
  final Map<String, EngagementNudgeModel> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> create(EngagementNudgeModel nudge) async {
    _storage[nudge.id] = nudge;
  }

  @override
  Future<List<EngagementNudgeModel>> getByStudent(String studentId) async {
    return _storage.values
        .where((n) => n.studentId == studentId)
        .toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  @override
  Future<List<EngagementNudgeModel>> getRecentByStudent(
      String studentId, {int limit = 10}) async {
    final all = await getByStudent(studentId);
    return all.take(limit).toList();
  }

  @override
  Future<List<EngagementNudgeModel>> getUnactedByStudent(
      String studentId) async {
    return _storage.values
        .where((n) => n.studentId == studentId && !n.wasActedUpon)
        .toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  @override
  Future<void> markActedUpon(String id) async {
    final nudge = _storage[id];
    if (nudge != null) {
      _storage[id] = nudge.copyWith(
        wasActedUpon: true,
        actedUponAt: DateTime.now(),
      );
    }
  }

  @override
  Future<int> getTodayCount(String studentId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return _storage.values
        .where((n) =>
            n.studentId == studentId && n.sentAt.isAfter(startOfDay))
        .length;
  }

  @override
  Future<List<EngagementNudgeModel>> getByType(
      String studentId, String nudgeType) async {
    return _storage.values
        .where((n) => n.studentId == studentId && n.nudgeType == nudgeType)
        .toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  @override
  Future<void> deleteOld(int daysOld) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysOld));
    final old = _storage.values.where((n) => n.sentAt.isBefore(cutoff)).toList();
    for (final n in old) {
      _storage.remove(n.id);
    }
  }
}

EngagementNudgeModel createTestNudge({
  String id = 'nudge-1',
  String studentId = 'student-1',
  String nudgeType = 'revision',
  String message = 'Time to revise!',
  String severity = 'medium',
  String? topicId,
  DateTime? sentAt,
  bool wasActedUpon = false,
  DateTime? actedUponAt,
}) {
  return EngagementNudgeModel(
    id: id,
    studentId: studentId,
    nudgeType: nudgeType,
    message: message,
    severity: severity,
    topicId: topicId,
    sentAt: sentAt,
    wasActedUpon: wasActedUpon,
    actedUponAt: actedUponAt,
  );
}

void main() {
  group('EngagementNudgeRepository', () {
    late _MockEngagementNudgeRepository repository;

    setUp(() {
      repository = _MockEngagementNudgeRepository();
    });

    group('save', () {
      test('stores a nudge', () async {
        final nudge = createTestNudge();
        await repository.create(nudge);
        final stored = await repository.getByStudent('student-1');
        expect(stored.length, 1);
        expect(stored.first.message, 'Time to revise!');
      });
    });

    group('getByStudent', () {
      test('returns nudges sorted by sentAt descending', () async {
        final earlier = DateTime(2024, 1, 1);
        final later = DateTime(2024, 6, 1);
        await repository.create(createTestNudge(
          id: 'n1', studentId: 's1', sentAt: earlier));
        await repository.create(createTestNudge(
          id: 'n2', studentId: 's1', sentAt: later));
        await repository.create(createTestNudge(
          id: 'n3', studentId: 's2'));
        final result = await repository.getByStudent('s1');
        expect(result.length, 2);
        expect(result.first.id, 'n2');
      });

      test('returns empty list for student with no nudges', () async {
        expect(await repository.getByStudent('none'), isEmpty);
      });
    });

    group('getRecentByStudent', () {
      test('returns up to limit nudges sorted by sentAt descending', () async {
        for (int i = 0; i < 5; i++) {
          await repository.create(createTestNudge(
            id: 'n$i', studentId: 's1',
            sentAt: DateTime(2024, 1, 1 + i)));
        }
        final result = await repository.getRecentByStudent('s1', limit: 3);
        expect(result.length, 3);
      });

      test('returns all when fewer than limit', () async {
        await repository.create(createTestNudge(id: 'n1', studentId: 's1'));
        expect((await repository.getRecentByStudent('s1')).length, 1);
      });
    });

    group('getUnactedByStudent', () {
      test('returns only unacted nudges sorted by sentAt descending', () async {
        final earlier = DateTime(2024, 1, 1);
        final later = DateTime(2024, 6, 1);
        await repository.create(createTestNudge(
          id: 'n1', studentId: 's1', sentAt: earlier, wasActedUpon: true));
        await repository.create(createTestNudge(
          id: 'n2', studentId: 's1', sentAt: later));
        final result = await repository.getUnactedByStudent('s1');
        expect(result.length, 1);
        expect(result.first.id, 'n2');
      });

      test('returns empty when all acted upon', () async {
        await repository.create(createTestNudge(
          id: 'n1', studentId: 's1', wasActedUpon: true));
        expect(await repository.getUnactedByStudent('s1'), isEmpty);
      });
    });

    group('markActedUpon', () {
      test('marks nudge as acted upon', () async {
        await repository.create(createTestNudge(id: 'n1', studentId: 's1'));
        await repository.markActedUpon('n1');
        final result = await repository.getByStudent('s1');
        expect(result.first.wasActedUpon, isTrue);
        expect(result.first.actedUponAt, isNotNull);
      });

      test('does nothing for non-existent nudge', () async {
        await repository.markActedUpon('none');
      });
    });

    group('getTodayCount', () {
      test('returns count of nudges sent today', () async {
        await repository.create(createTestNudge(
          id: 'n1', studentId: 's1', sentAt: DateTime.now()));
        await repository.create(createTestNudge(
          id: 'n2', studentId: 's1',
          sentAt: DateTime.now().subtract(const Duration(days: 2))));
        expect(await repository.getTodayCount('s1'), 1);
      });

      test('returns zero when no nudges today', () async {
        await repository.create(createTestNudge(
          id: 'n1', studentId: 's1',
          sentAt: DateTime.now().subtract(const Duration(days: 1))));
        expect(await repository.getTodayCount('s1'), 0);
      });
    });

    group('getByType', () {
      test('returns nudges of given type sorted by sentAt descending', () async {
        await repository.create(createTestNudge(
          id: 'n1', studentId: 's1', nudgeType: 'revision',
          sentAt: DateTime(2024, 1, 1)));
        await repository.create(createTestNudge(
          id: 'n2', studentId: 's1', nudgeType: 'overwork',
          sentAt: DateTime(2024, 6, 1)));
        await repository.create(createTestNudge(
          id: 'n3', studentId: 's1', nudgeType: 'revision',
          sentAt: DateTime(2024, 3, 1)));
        final result = await repository.getByType('s1', 'revision');
        expect(result.length, 2);
        expect(result.first.id, 'n3');
      });

      test('returns empty for non-existent type', () async {
        await repository.create(createTestNudge(id: 'n1', studentId: 's1'));
        expect(await repository.getByType('s1', 'nonexistent'), isEmpty);
      });
    });

    group('deleteOld', () {
      test('deletes nudges older than given days', () async {
        await repository.create(createTestNudge(
          id: 'n1', studentId: 's1',
          sentAt: DateTime.now().subtract(const Duration(days: 10))));
        await repository.create(createTestNudge(
          id: 'n2', studentId: 's1',
          sentAt: DateTime.now().subtract(const Duration(days: 2))));
        await repository.deleteOld(7);
        final result = await repository.getByStudent('s1');
        expect(result.length, 1);
        expect(result.first.id, 'n2');
      });

      test('keeps all when none are old enough', () async {
        await repository.create(createTestNudge(
          id: 'n1', studentId: 's1',
          sentAt: DateTime.now().subtract(const Duration(days: 1))));
        await repository.deleteOld(7);
        expect((await repository.getByStudent('s1')).length, 1);
      });
    });
  });
}
