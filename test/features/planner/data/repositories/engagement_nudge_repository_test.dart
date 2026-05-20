import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';

class _FakeEngagementNudgeRepository extends EngagementNudgeRepository {
  final Map<String, EngagementNudgeModel> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> create(EngagementNudgeModel nudge) async {
    _storage[nudge.id] = nudge;
    return Result.success(null);
  }

  @override
  Future<Result<List<EngagementNudgeModel>>> getByStudent(String studentId) async {
    return Result.success(
      _storage.values
          .where((n) => n.studentId == studentId)
          .toList()
        ..sort((a, b) => b.sentAt.compareTo(a.sentAt)),
    );
  }

  @override
  Future<Result<List<EngagementNudgeModel>>> getRecentByStudent(
      String studentId, {int limit = 10}) async {
    final all = (await getByStudent(studentId)).data ?? [];
    return Result.success(all.take(limit).toList());
  }

  @override
  Future<Result<List<EngagementNudgeModel>>> getUnactedByStudent(
      String studentId) async {
    return Result.success(
      _storage.values
          .where((n) => n.studentId == studentId && !n.wasActedUpon)
          .toList()
        ..sort((a, b) => b.sentAt.compareTo(a.sentAt)),
    );
  }

  @override
  Future<Result<void>> markActedUpon(String id) async {
    final nudge = _storage[id];
    if (nudge != null) {
      _storage[id] = nudge.copyWith(
        wasActedUpon: true,
        actedUponAt: DateTime.now(),
      );
    }
    return Result.success(null);
  }

  @override
  Future<Result<int>> getTodayCount(String studentId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return Result.success(
      _storage.values
          .where((n) =>
              n.studentId == studentId && n.sentAt.isAfter(startOfDay))
          .length,
    );
  }

  @override
  Future<Result<List<EngagementNudgeModel>>> getByType(
      String studentId, String nudgeType) async {
    return Result.success(
      _storage.values
          .where((n) => n.studentId == studentId && n.nudgeType == nudgeType)
          .toList()
        ..sort((a, b) => b.sentAt.compareTo(a.sentAt)),
    );
  }

  @override
  Future<Result<void>> deleteOld(int daysOld) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysOld));
    final old = _storage.values.where((n) => n.sentAt.isBefore(cutoff)).toList();
    for (final n in old) {
      _storage.remove(n.id);
    }
    return Result.success(null);
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
    late _FakeEngagementNudgeRepository repository;

    setUp(() {
      repository = _FakeEngagementNudgeRepository();
    });

    group('save', () {
      test('stores a nudge', () async {
        final nudge = createTestNudge();
        await repository.create(nudge);
        final stored = await repository.getByStudent('student-1');
        expect(stored.data!.length, 1);
        expect(stored.data!.first.message, 'Time to revise!');
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
        expect(result.data!.length, 2);
        expect(result.data!.first.id, 'n2');
      });

      test('returns empty list for student with no nudges', () async {
        expect((await repository.getByStudent('none')).data, isEmpty);
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
        expect(result.data!.length, 3);
      });

      test('returns all when fewer than limit', () async {
        await repository.create(createTestNudge(id: 'n1', studentId: 's1'));
        expect((await repository.getRecentByStudent('s1')).data!.length, 1);
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
        expect(result.data!.length, 1);
        expect(result.data!.first.id, 'n2');
      });

      test('returns empty when all acted upon', () async {
        await repository.create(createTestNudge(
          id: 'n1', studentId: 's1', wasActedUpon: true));
        expect((await repository.getUnactedByStudent('s1')).data, isEmpty);
      });
    });

    group('markActedUpon', () {
      test('marks nudge as acted upon', () async {
        await repository.create(createTestNudge(id: 'n1', studentId: 's1'));
        await repository.markActedUpon('n1');
        final result = await repository.getByStudent('s1');
        expect(result.data!.first.wasActedUpon, isTrue);
        expect(result.data!.first.actedUponAt, isNotNull);
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
        expect((await repository.getTodayCount('s1')).data, 1);
      });

      test('returns zero when no nudges today', () async {
        await repository.create(createTestNudge(
          id: 'n1', studentId: 's1',
          sentAt: DateTime.now().subtract(const Duration(days: 1))));
        expect((await repository.getTodayCount('s1')).data, 0);
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
        expect(result.data!.length, 2);
        expect(result.data!.first.id, 'n3');
      });

      test('returns empty for non-existent type', () async {
        await repository.create(createTestNudge(id: 'n1', studentId: 's1'));
        expect((await repository.getByType('s1', 'nonexistent')).data, isEmpty);
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
        expect(result.data!.length, 1);
        expect(result.data!.first.id, 'n2');
      });

      test('keeps all when none are old enough', () async {
        await repository.create(createTestNudge(
          id: 'n1', studentId: 's1',
          sentAt: DateTime.now().subtract(const Duration(days: 1))));
        await repository.deleteOld(7);
        expect((await repository.getByStudent('s1')).data!.length, 1);
      });
    });
  });

  group('EngagementNudgeRepository (init with real Hive)', () {
    late EngagementNudgeRepository repository;
    late String hivePath;

    setUpAll(() {
      Hive.registerAdapter(_TestEngagementNudgeAdapter());
    });

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('nudge_repo_test_');
      hivePath = dir.path;
      Hive.init(hivePath);
      repository = EngagementNudgeRepository();
      await repository.init();
    });

    tearDown(() async {
      await repository.box.close();
      await Hive.deleteBoxFromDisk('engagement_nudges');
    });

    test('init opens box and supports CRUD', () async {
      final nudge = createTestNudge(id: 'hive-1', message: 'Hive test');
      await repository.create(nudge);
      final stored = await repository.getByStudent('student-1');
      expect(stored.data, hasLength(1));
      expect(stored.data!.first.message, 'Hive test');
    });

    test('getRecentByStudent works after init', () async {
      await repository.create(createTestNudge(id: 'n1', studentId: 's1'));
      await repository.create(createTestNudge(id: 'n2', studentId: 's1'));
      expect((await repository.getRecentByStudent('s1')).data, hasLength(2));
    });

    test('markActedUpon works after init', () async {
      await repository.create(createTestNudge(id: 'm1', studentId: 's1'));
      await repository.markActedUpon('m1');
      final result = await repository.getByStudent('s1');
      expect(result.data!.first.wasActedUpon, isTrue);
    });

    test('getUnactedByStudent returns only unacted nudges', () async {
      await repository.create(createTestNudge(id: 'u1', studentId: 's1', wasActedUpon: true));
      await repository.create(createTestNudge(id: 'u2', studentId: 's1'));
      final result = await repository.getUnactedByStudent('s1');
      expect(result.data!.length, 1);
      expect(result.data!.first.id, 'u2');
    });

    test('getTodayCount returns correct count', () async {
      await repository.create(createTestNudge(id: 'tc1', studentId: 's1', sentAt: DateTime.now()));
      await repository.create(createTestNudge(id: 'tc2', studentId: 's1', sentAt: DateTime.now().subtract(const Duration(days: 5))));
      expect((await repository.getTodayCount('s1')).data, 1);
    });

    test('getByType filters by nudge type', () async {
      await repository.create(createTestNudge(id: 'bt1', studentId: 's1', nudgeType: 'revision'));
      await repository.create(createTestNudge(id: 'bt2', studentId: 's1', nudgeType: 'overwork'));
      await repository.create(createTestNudge(id: 'bt3', studentId: 's1', nudgeType: 'revision'));
      final result = await repository.getByType('s1', 'revision');
      expect(result.data!.length, 2);
    });

    test('deleteOld removes older nudges', () async {
      await repository.create(createTestNudge(id: 'do1', studentId: 's1', sentAt: DateTime.now().subtract(const Duration(days: 10))));
      await repository.create(createTestNudge(id: 'do2', studentId: 's1', sentAt: DateTime.now().subtract(const Duration(days: 2))));
      await repository.deleteOld(7);
      final remaining = await repository.getByStudent('s1');
      expect(remaining.data!.length, 1);
      expect(remaining.data!.first.id, 'do2');
    });

    test('getByStudent sorts by sentAt descending', () async {
      final early = DateTime.now().subtract(const Duration(days: 5));
      final late = DateTime.now();
      await repository.create(createTestNudge(id: 's1a', studentId: 's1', sentAt: early));
      await repository.create(createTestNudge(id: 's1b', studentId: 's1', sentAt: late));
      final result = await repository.getByStudent('s1');
      expect(result.data!.first.id, 's1b');
    });
  });
}

class _TestEngagementNudgeAdapter extends TypeAdapter<EngagementNudgeModel> {
  @override
  final int typeId = 32;

  @override
  EngagementNudgeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EngagementNudgeModel(
      id: fields[0] as String,
      studentId: fields[1] as String,
      nudgeType: fields[2] as String,
      message: fields[3] as String,
      severity: fields[4] as String? ?? 'medium',
      topicId: fields[5] as String?,
      sentAt: fields[6] as DateTime,
      wasActedUpon: fields[7] as bool? ?? false,
      actedUponAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, EngagementNudgeModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.nudgeType)
      ..writeByte(3)
      ..write(obj.message)
      ..writeByte(4)
      ..write(obj.severity)
      ..writeByte(5)
      ..write(obj.topicId)
      ..writeByte(6)
      ..write(obj.sentAt)
      ..writeByte(7)
      ..write(obj.wasActedUpon)
      ..writeByte(8)
      ..write(obj.actedUponAt);
  }
}
