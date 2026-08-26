import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/features/planner/data/repositories/plan_context_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('plan_context_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    if (Hive.isBoxOpen(HiveBoxNames.planContext)) {
      await Hive.deleteBoxFromDisk(HiveBoxNames.planContext);
    }
  });

  group('PlanContextRepository save/load round-trip', () {
    late PlanContextRepository repo;

    setUp(() async {
      repo = PlanContextRepository();
      final initResult = await repo.init();
      expect(initResult.isSuccess, isTrue);
    });

    test('getActivePlanId returns null when nothing stored', () async {
      final result = await repo.getActivePlanId('student-1');
      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });

    test('setActivePlanId then getActivePlanId round-trips', () async {
      final setResult = await repo.setActivePlanId('student-1', 'plan-42');
      expect(setResult.isSuccess, isTrue);

      final getResult = await repo.getActivePlanId('student-1');
      expect(getResult.isSuccess, isTrue);
      expect(getResult.data, equals('plan-42'));
    });

    test('setActivePlanId overwrites a previously stored id', () async {
      await repo.setActivePlanId('student-1', 'plan-1');
      await repo.setActivePlanId('student-1', 'plan-2');

      final getResult = await repo.getActivePlanId('student-1');
      expect(getResult.data, equals('plan-2'));
    });

    test('different students keep separate active plan ids', () async {
      await repo.setActivePlanId('student-1', 'plan-a');
      await repo.setActivePlanId('student-2', 'plan-b');

      final a = await repo.getActivePlanId('student-1');
      final b = await repo.getActivePlanId('student-2');
      expect(a.data, equals('plan-a'));
      expect(b.data, equals('plan-b'));
    });

    test('clearActivePlanId removes the stored id', () async {
      await repo.setActivePlanId('student-1', 'plan-42');
      final clearResult = await repo.clearActivePlanId('student-1');
      expect(clearResult.isSuccess, isTrue);

      final getResult = await repo.getActivePlanId('student-1');
      expect(getResult.data, isNull);
    });

    test('clearActivePlanId is idempotent for a missing key', () async {
      final clearResult = await repo.clearActivePlanId('never-set');
      expect(clearResult.isSuccess, isTrue);
    });

    test('persisted value survives a reopen of the box', () async {
      await repo.setActivePlanId('student-1', 'plan-persist');

      // Simulate an app restart: close the open box, then let a new
      // repository reopen it from disk.
      await Hive.box(HiveBoxNames.planContext).close();
      final reopened = PlanContextRepository();
      final reinit = await reopened.init();
      expect(reinit.isSuccess, isTrue);

      final getResult = await reopened.getActivePlanId('student-1');
      expect(getResult.data, equals('plan-persist'));
    });
  });

  group('PlanContextRepository Result failure handling', () {
    test('getActivePlanId fails when not initialized', () async {
      final repo = PlanContextRepository();
      final result = await repo.getActivePlanId('student-1');
      expect(result.isFailure, isTrue);
      expect(result.error, isNotNull);
    });

    test('setActivePlanId fails when not initialized', () async {
      final repo = PlanContextRepository();
      final result = await repo.setActivePlanId('student-1', 'plan-1');
      expect(result.isFailure, isTrue);
    });

    test('clearActivePlanId fails when not initialized', () async {
      final repo = PlanContextRepository();
      final result = await repo.clearActivePlanId('student-1');
      expect(result.isFailure, isTrue);
    });

    test('init succeeds when the box is already open', () async {
      final repo = PlanContextRepository();
      expect((await repo.init()).isSuccess, isTrue);
      // Second init should reuse the already-open box and still succeed.
      expect((await repo.init()).isSuccess, isTrue);
    });
  });
}
