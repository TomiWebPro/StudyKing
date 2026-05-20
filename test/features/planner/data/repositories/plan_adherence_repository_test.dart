import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/planner/data/adapters/plan_adherence_model_adapter.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/core/errors/result.dart';

class _FakePlanAdherenceRepository extends PlanAdherenceRepository {
  final Map<String, PlanAdherenceModel> _storage = {};

  @override
  Future<void> init() async {}

  bool get _isReady => true;

  @override
  Future<void> create(PlanAdherenceModel model) async {
    _storage[model.id] = model;
  }

  @override
  Future<Result<PlanAdherenceModel?>> get(String id) async {
    return Result.success(_storage[id]);
  }

  @override
  Future<List<PlanAdherenceModel>> getByStudent(String studentId) async {
    if (!_isReady) return [];
    final results = _storage.values
        .where((m) => m.studentId == studentId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return results;
  }

  @override
  Future<List<PlanAdherenceModel>> getByDateRange(
      String studentId, DateTime start, DateTime end) async {
    if (!_isReady) return [];
    return _storage.values
        .where((m) =>
            m.studentId == studentId &&
            m.date.isAfter(start) &&
            m.date.isBefore(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<List<PlanAdherenceModel>> getWeekly(String studentId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return getByDateRange(studentId, weekAgo, now);
  }

  @override
  Future<double> getAverageAdherence(String studentId) async {
    final metrics = await getByStudent(studentId);
    if (metrics.isEmpty) return 0.0;
    return metrics.fold<double>(0.0, (sum, m) => sum + m.adherenceScore) /
        metrics.length;
  }

  @override
  Future<int> getConsecutiveLowAdherenceDays(String studentId,
      {double threshold = 0.5}) async {
    final metrics = await getByStudent(studentId);
    int consecutive = 0;
    for (final metric in metrics) {
      if (metric.adherenceScore < threshold) {
        consecutive++;
      } else {
        break;
      }
    }
    return consecutive;
  }

  @override
  Future<PlanAdherenceModel?> getToday(String studentId) async {
    if (!_isReady) return null;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final todayMetrics = _storage.values.where((m) =>
        m.studentId == studentId &&
        m.date.isAfter(startOfDay) &&
        m.date.isBefore(endOfDay));
    return todayMetrics.isNotEmpty ? todayMetrics.first : null;
  }

  @override
  Future<Result<void>> delete(String id) async {
    _storage.remove(id);
    return Result.success(null);
  }

  @override
  Future<void> deleteByStudent(String studentId) async {
    if (!_isReady) return;
    final metrics = _storage.values
        .where((m) => m.studentId == studentId)
        .toList();
    for (final m in metrics) {
      _storage.remove(m.id);
    }
  }
}

PlanAdherenceModel createTestAdherence({
  String id = 'adherence-1',
  String studentId = 'student-1',
  DateTime? date,
  int plannedQuestions = 10,
  int actualQuestions = 8,
  int plannedMinutes = 60,
  int actualMinutes = 45,
  double adherenceScore = 0.8,
  String? planId,
  Map<String, dynamic>? metadata,
}) {
  return PlanAdherenceModel(
    id: id,
    studentId: studentId,
    date: date ?? DateTime(2024, 6, 1),
    plannedQuestions: plannedQuestions,
    actualQuestions: actualQuestions,
    plannedMinutes: plannedMinutes,
    actualMinutes: actualMinutes,
    adherenceScore: adherenceScore,
    planId: planId,
    metadata: metadata,
  );
}

void main() {
  group('PlanAdherenceRepository', () {
    late _FakePlanAdherenceRepository repository;

    setUp(() {
      repository = _FakePlanAdherenceRepository();
    });

    group('save', () {
      test('stores an adherence record', () async {
        final model = createTestAdherence();
        await repository.create(model);
        final stored = await repository.get('adherence-1');
        expect(stored.data, isNotNull);
        expect(stored.data?.adherenceScore, 0.8);
      });

      test('overwrites existing record with same id', () async {
        await repository.create(createTestAdherence(adherenceScore: 0.5));
        await repository.create(createTestAdherence(adherenceScore: 0.9));
        expect((await repository.get('adherence-1')).data?.adherenceScore, 0.9);
      });
    });

    group('get', () {
      test('returns null for non-existent record', () async {
        expect((await repository.get('none')).data, isNull);
      });

      test('returns stored record', () async {
        await repository.create(createTestAdherence());
        final result = await repository.get('adherence-1');
        expect(result.data?.id, 'adherence-1');
        expect(result.data?.studentId, 'student-1');
      });
    });

    group('getByStudent', () {
      test('returns records sorted by date descending', () async {
        final earlier = DateTime(2024, 1, 1);
        final later = DateTime(2024, 6, 1);
        await repository.create(createTestAdherence(
          id: 'a1', studentId: 's1', date: earlier));
        await repository.create(createTestAdherence(
          id: 'a2', studentId: 's1', date: later));
        await repository.create(createTestAdherence(
          id: 'a3', studentId: 's2'));
        final result = await repository.getByStudent('s1');
        expect(result.length, 2);
        expect(result.first.id, 'a2');
      });

      test('returns empty list for student with no records', () async {
        expect(await repository.getByStudent('none'), isEmpty);
      });
    });

    group('getByDateRange', () {
      test('returns records within date range', () async {
        await repository.create(createTestAdherence(
          id: 'a1', studentId: 's1', date: DateTime(2024, 5, 1)));
        await repository.create(createTestAdherence(
          id: 'a2', studentId: 's1', date: DateTime(2024, 6, 15)));
        await repository.create(createTestAdherence(
          id: 'a3', studentId: 's1', date: DateTime(2024, 7, 1)));
        final result = await repository.getByDateRange(
          's1',
          DateTime(2024, 6, 1),
          DateTime(2024, 7, 1),
        );
        expect(result.length, 1);
        expect(result.first.id, 'a2');
      });

      test('returns empty when no records in range', () async {
        await repository.create(createTestAdherence(
          id: 'a1', studentId: 's1', date: DateTime(2024, 1, 1)));
        final result = await repository.getByDateRange(
          's1',
          DateTime(2024, 6, 1),
          DateTime(2024, 7, 1),
        );
        expect(result, isEmpty);
      });
    });

    group('getWeekly', () {
      test('returns records from last 7 days', () async {
        await repository.create(createTestAdherence(
          id: 'a1', studentId: 's1',
          date: DateTime.now().subtract(const Duration(days: 3))));
        await repository.create(createTestAdherence(
          id: 'a2', studentId: 's1',
          date: DateTime.now().subtract(const Duration(days: 10))));
        final result = await repository.getWeekly('s1');
        expect(result.length, 1);
        expect(result.first.id, 'a1');
      });

      test('returns empty when no records in last week', () async {
        await repository.create(createTestAdherence(
          id: 'a1', studentId: 's1',
          date: DateTime.now().subtract(const Duration(days: 14))));
        expect(await repository.getWeekly('s1'), isEmpty);
      });
    });

    group('getAverageAdherence', () {
      test('returns average of adherence scores', () async {
        await repository.create(createTestAdherence(
          id: 'a1', studentId: 's1', adherenceScore: 0.8));
        await repository.create(createTestAdherence(
          id: 'a2', studentId: 's1', adherenceScore: 0.6));
        expect(await repository.getAverageAdherence('s1'), closeTo(0.7, 0.001));
      });

      test('returns 0.0 when no records', () async {
        expect(await repository.getAverageAdherence('none'), 0.0);
      });
    });

    group('getConsecutiveLowAdherenceDays', () {
      test('counts consecutive low adherence days', () async {
        await repository.create(createTestAdherence(
          id: 'a1', studentId: 's1', date: DateTime(2024, 6, 3),
          adherenceScore: 0.3));
        await repository.create(createTestAdherence(
          id: 'a2', studentId: 's1', date: DateTime(2024, 6, 2),
          adherenceScore: 0.4));
        await repository.create(createTestAdherence(
          id: 'a3', studentId: 's1', date: DateTime(2024, 6, 1),
          adherenceScore: 0.9));
        expect(
          await repository.getConsecutiveLowAdherenceDays('s1'), 2);
      });

      test('stops counting at first non-low day', () async {
        await repository.create(createTestAdherence(
          id: 'a1', studentId: 's1', date: DateTime(2024, 6, 3),
          adherenceScore: 0.9));
        await repository.create(createTestAdherence(
          id: 'a2', studentId: 's1', date: DateTime(2024, 6, 2),
          adherenceScore: 0.3));
        expect(
          await repository.getConsecutiveLowAdherenceDays('s1'), 0);
      });

      test('returns 0 when no records', () async {
        expect(
          await repository.getConsecutiveLowAdherenceDays('none'), 0);
      });
    });

    group('getToday', () {
      test('returns today record when it exists', () async {
        await repository.create(createTestAdherence(
          id: 'a1', studentId: 's1', date: DateTime.now()));
        final result = await repository.getToday('s1');
        expect(result, isNotNull);
        expect(result?.id, 'a1');
      });

      test('returns null when no today record', () async {
        await repository.create(createTestAdherence(
          id: 'a1', studentId: 's1',
          date: DateTime.now().subtract(const Duration(days: 1))));
        expect(await repository.getToday('s1'), isNull);
      });
    });

    group('delete', () {
      test('removes a record', () async {
        await repository.create(createTestAdherence(id: 'a1'));
        await repository.delete('a1');
        expect((await repository.get('a1')).data, isNull);
      });

      test('does nothing for non-existent id', () async {
        await repository.delete('none');
      });
    });

    group('deleteByStudent', () {
      test('removes all records for a student', () async {
        await repository.create(createTestAdherence(id: 'a1', studentId: 's1'));
        await repository.create(createTestAdherence(id: 'a2', studentId: 's1'));
        await repository.create(createTestAdherence(id: 'a3', studentId: 's2'));
        await repository.deleteByStudent('s1');
        expect((await repository.get('a1')).data, isNull);
        expect((await repository.get('a2')).data, isNull);
        expect((await repository.get('a3')).data, isNotNull);
      });

      test('does nothing when student has no records', () async {
        await repository.deleteByStudent('none');
      });
    });
  });

  group('error handling', () {
    test('getByStudent throws when box throws', () async {
      final repo = PlanAdherenceRepository();
      repo.attachBox(_ThrowingAdherenceBox());
      expect(() => repo.getByStudent('test'), throwsException);
    });

    test('create does not throw when box throws (caught by base)', () async {
      final repo = PlanAdherenceRepository();
      repo.attachBox(_ThrowingAdherenceBox());
      final model = createTestAdherence();
      await repo.create(model);
    });

    test('get returns failure when box throws', () async {
      final repo = PlanAdherenceRepository();
      repo.attachBox(_ThrowingAdherenceBox());
      final result = await repo.get('any');
      expect(result.isFailure, isTrue);
    });

    test('getByDateRange throws when box throws', () async {
      final repo = PlanAdherenceRepository();
      repo.attachBox(_ThrowingAdherenceBox());
      expect(
        () => repo.getByDateRange('test', DateTime(2024, 1, 1), DateTime(2024, 12, 31)),
        throwsException,
      );
    });

    test('getWeekly throws when box throws', () async {
      final repo = PlanAdherenceRepository();
      repo.attachBox(_ThrowingAdherenceBox());
      expect(() => repo.getWeekly('test'), throwsException);
    });

    test('getAverageAdherence throws when box throws', () async {
      final repo = PlanAdherenceRepository();
      repo.attachBox(_ThrowingAdherenceBox());
      expect(() => repo.getAverageAdherence('test'), throwsException);
    });

    test('getConsecutiveLowAdherenceDays throws when box throws', () async {
      final repo = PlanAdherenceRepository();
      repo.attachBox(_ThrowingAdherenceBox());
      expect(() => repo.getConsecutiveLowAdherenceDays('test'), throwsException);
    });

    test('getToday throws when box throws', () async {
      final repo = PlanAdherenceRepository();
      repo.attachBox(_ThrowingAdherenceBox());
      expect(() => repo.getToday('test'), throwsException);
    });

    test('deleteByStudent throws when box throws', () async {
      final repo = PlanAdherenceRepository();
      repo.attachBox(_ThrowingAdherenceBox());
      expect(() => repo.deleteByStudent('test'), throwsException);
    });
  });

  group('PlanAdherenceRepository (init with real Hive)', () {
    late PlanAdherenceRepository repository;
    late String hivePath;

    setUpAll(() {
      Hive.registerAdapter(PlanAdherenceModelAdapter());
    });

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('adherence_repo_test_');
      hivePath = dir.path;
      Hive.init(hivePath);
      repository = PlanAdherenceRepository();
      await repository.init();
    });

    tearDown(() async {
      await repository.box.close();
      await Hive.deleteBoxFromDisk('plan_adherence');
    });

    test('init opens box and supports CRUD', () async {
      final model = createTestAdherence(id: 'hive-1');
      await repository.create(model);
      final stored = await repository.get('hive-1');
      expect(stored.data, isNotNull);
      expect(stored.data!.adherenceScore, 0.8);
    });

    test('getByStudent works after init', () async {
      await repository.create(createTestAdherence(id: 'a1', studentId: 's1'));
      await repository.create(createTestAdherence(id: 'a2', studentId: 's1'));
      await repository.create(createTestAdherence(id: 'a3', studentId: 's2'));
      expect(await repository.getByStudent('s1'), hasLength(2));
    });

    test('delete works after init', () async {
      await repository.create(createTestAdherence(id: 'd1'));
      await repository.delete('d1');
      expect((await repository.get('d1')).data, isNull);
    });

    test('getByDateRange filters correctly', () async {
      await repository.create(createTestAdherence(
        id: 'd1', studentId: 's1', date: DateTime(2025, 6, 1)));
      await repository.create(createTestAdherence(
        id: 'd2', studentId: 's1', date: DateTime(2025, 6, 15)));
      await repository.create(createTestAdherence(
        id: 'd3', studentId: 's1', date: DateTime(2025, 7, 1)));
      final result = await repository.getByDateRange(
        's1', DateTime(2025, 6, 5), DateTime(2025, 6, 25));
      expect(result.length, 1);
      expect(result.first.id, 'd2');
    });

    test('getWeekly returns last 7 days', () async {
      await repository.create(createTestAdherence(
        id: 'w1', studentId: 's1', date: DateTime.now().subtract(const Duration(days: 2))));
      await repository.create(createTestAdherence(
        id: 'w2', studentId: 's1', date: DateTime.now().subtract(const Duration(days: 14))));
      final result = await repository.getWeekly('s1');
      expect(result.length, 1);
      expect(result.first.id, 'w1');
    });

    test('getAverageAdherence computes average', () async {
      await repository.create(createTestAdherence(id: 'avg1', studentId: 's1', adherenceScore: 0.8));
      await repository.create(createTestAdherence(id: 'avg2', studentId: 's1', adherenceScore: 0.6));
      final avg = await repository.getAverageAdherence('s1');
      expect(avg, closeTo(0.7, 0.001));
    });

    test('getConsecutiveLowAdherenceDays counts correctly', () async {
      final now = DateTime.now();
      await repository.create(createTestAdherence(
        id: 'c1', studentId: 's1', date: now, adherenceScore: 0.3));
      await repository.create(createTestAdherence(
        id: 'c2', studentId: 's1', date: now.subtract(const Duration(days: 1)), adherenceScore: 0.4));
      await repository.create(createTestAdherence(
        id: 'c3', studentId: 's1', date: now.subtract(const Duration(days: 2)), adherenceScore: 0.9));
      final consecutive = await repository.getConsecutiveLowAdherenceDays('s1');
      expect(consecutive, 2);
    });

    test('getToday returns today record', () async {
      await repository.create(createTestAdherence(id: 'td1', studentId: 's1', date: DateTime.now()));
      final today = await repository.getToday('s1');
      expect(today, isNotNull);
      expect(today!.id, 'td1');
    });

    test('deleteByStudent removes all records for student', () async {
      await repository.create(createTestAdherence(id: 'ds1', studentId: 's1'));
      await repository.create(createTestAdherence(id: 'ds2', studentId: 's1'));
      await repository.create(createTestAdherence(id: 'ds3', studentId: 's2'));
      await repository.deleteByStudent('s1');
      expect((await repository.get('ds1')).data, isNull);
      expect((await repository.get('ds2')).data, isNull);
      expect((await repository.get('ds3')).data, isNotNull);
    });
  });
}

class _ThrowingAdherenceBox implements Box<PlanAdherenceModel> {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw Exception('Simulated Hive error');
  }
}
