import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/core/errors/result.dart';

class _FakePendingActionRepository extends PendingActionRepository {
  final Map<String, PendingActionModel> _storage = {};

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<void>> create(PendingActionModel action) async {
    _storage[action.id] = action;
    return Result.success(null);
  }

  @override
  Future<Result<PendingActionModel?>> get(String id) async {
    return Result.success(_storage[id]);
  }

  @override
  Future<Result<List<PendingActionModel>>> getPending(String studentId) async {
    return Result.success(_storage.values
        .where((a) => a.studentId == studentId && a.status == 'pending')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  @override
  Future<Result<void>> markCompleted(String id) async {
    final action = _storage[id];
    if (action != null) {
      _storage[id] = action.copyWith(status: 'completed');
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> markRejected(String id) async {
    final action = _storage[id];
    if (action != null) {
      _storage[id] = action.copyWith(status: 'rejected');
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> delete(String id) async {
    _storage.remove(id);
    return Result.success(null);
  }

  @override
  Future<Result<void>> clearAll(String studentId) async {
    final actions = _storage.values
        .where((a) => a.studentId == studentId)
        .toList();
    for (final action in actions) {
      _storage.remove(action.id);
    }
    return Result.success(null);
  }

  @override
  Future<Result<bool>> hasPending(String studentId) async {
    return Result.success(_storage.values
        .any((a) => a.studentId == studentId && a.status == 'pending'));
  }
}

PendingActionModel createTestAction({
  String id = 'action-1',
  String studentId = 'student-1',
  String actionType = 'schedule',
  String topicTitle = 'Algebra',
  String? sessionId,
  Map<String, dynamic> payload = const {},
  DateTime? createdAt,
  String status = 'pending',
}) {
  return PendingActionModel(
    id: id,
    studentId: studentId,
    actionType: actionType,
    topicTitle: topicTitle,
    sessionId: sessionId,
    payload: payload,
    createdAt: createdAt,
    status: status,
  );
}

void main() {
  group('PendingActionRepository', () {
    late _FakePendingActionRepository repository;

    setUp(() {
      repository = _FakePendingActionRepository();
    });

    group('save', () {
      test('stores a pending action', () async {
        final action = createTestAction();
        await repository.create(action);
        final stored = await repository.get('action-1');
        expect(stored.data, isNotNull);
        expect(stored.data?.actionType, 'schedule');
      });

      test('overwrites existing action with same id', () async {
        await repository.create(createTestAction(actionType: 'schedule'));
        await repository.create(createTestAction(actionType: 'reschedule'));
        expect((await repository.get('action-1')).data?.actionType, 'reschedule');
      });
    });

    group('get', () {
      test('returns null for non-existent action', () async {
        expect((await repository.get('none')).data, isNull);
      });

      test('returns stored action', () async {
        await repository.create(createTestAction());
        final result = await repository.get('action-1');
        expect(result.data?.id, 'action-1');
        expect(result.data?.status, 'pending');
      });
    });

    group('getPending', () {
      test('returns pending actions sorted by createdAt descending', () async {
        final earlier = DateTime(2024, 1, 1);
        final later = DateTime(2024, 6, 1);
        await repository.create(createTestAction(
          id: 'a1', studentId: 's1', createdAt: earlier));
        await repository.create(createTestAction(
          id: 'a2', studentId: 's1', createdAt: later));
        await repository.create(createTestAction(
          id: 'a3', studentId: 's1', status: 'completed'));
        final result = (await repository.getPending('s1')).data!;
        expect(result.length, 2);
        expect(result.first.id, 'a2');
      });

      test('returns empty when no pending actions', () async {
        await repository.create(createTestAction(
          id: 'a1', studentId: 's1', status: 'completed'));
        expect((await repository.getPending('s1')).data, isEmpty);
      });

      test('returns empty for student with no actions', () async {
        expect((await repository.getPending('none')).data, isEmpty);
      });
    });

    group('markCompleted', () {
      test('marks pending action as completed', () async {
        await repository.create(createTestAction(id: 'a1', studentId: 's1'));
        await repository.markCompleted('a1');
        final result = await repository.get('a1');
        expect(result.data?.status, 'completed');
      });

      test('does nothing for non-existent action', () async {
        await repository.markCompleted('none');
      });
    });

    group('markRejected', () {
      test('marks pending action as rejected', () async {
        await repository.create(createTestAction(id: 'a1', studentId: 's1'));
        await repository.markRejected('a1');
        final result = await repository.get('a1');
        expect(result.data?.status, 'rejected');
      });

      test('does nothing for non-existent action', () async {
        await repository.markRejected('none');
      });
    });

    group('delete', () {
      test('removes an action', () async {
        await repository.create(createTestAction(id: 'a1'));
        await repository.delete('a1');
        expect((await repository.get('a1')).data, isNull);
      });

      test('does nothing for non-existent id', () async {
        await repository.delete('none');
      });
    });

    group('clearAll', () {
      test('removes all actions for a student', () async {
        await repository.create(createTestAction(id: 'a1', studentId: 's1'));
        await repository.create(createTestAction(id: 'a2', studentId: 's1'));
        await repository.create(createTestAction(id: 'a3', studentId: 's2'));
        await repository.clearAll('s1');
        expect((await repository.get('a1')).data, isNull);
        expect((await repository.get('a2')).data, isNull);
        expect((await repository.get('a3')).data, isNotNull);
      });

      test('does nothing when student has no actions', () async {
        await repository.clearAll('none');
      });
    });

    group('hasPending', () {
      test('returns true when student has pending actions', () async {
        await repository.create(createTestAction(id: 'a1', studentId: 's1'));
        expect((await repository.hasPending('s1')).data, isTrue);
      });

      test('returns false when no pending actions exist', () async {
        await repository.create(createTestAction(
          id: 'a1', studentId: 's1', status: 'completed'));
        expect((await repository.hasPending('s1')).data, isFalse);
      });

      test('returns false for student with no actions', () async {
        expect((await repository.hasPending('none')).data, isFalse);
      });
    });
  });

  group('PendingActionRepository (init with real Hive)', () {
    late PendingActionRepository repository;
    late String hivePath;

    setUpAll(() {
      Hive.registerAdapter(_TestPendingActionAdapter());
    });

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('pa_repo_test_');
      hivePath = dir.path;
      Hive.init(hivePath);
      repository = PendingActionRepository();
      await repository.init();
    });

    tearDown(() async {
      await repository.box.close();
      await Hive.deleteBoxFromDisk('pending_actions');
    });

    test('init opens box and supports CRUD', () async {
      final action = createTestAction(id: 'hive-1');
      await repository.create(action);
      final stored = await repository.get('hive-1');
      expect(stored.data, isNotNull);
      expect(stored.data!.actionType, 'schedule');
    });

    test('getPending works after init', () async {
      await repository.create(createTestAction(id: 'a1', studentId: 's1'));
      await repository.create(createTestAction(id: 'a2', studentId: 's1', status: 'completed'));
      expect((await repository.getPending('s1')).data, hasLength(1));
    });

    test('markCompleted works after init', () async {
      await repository.create(createTestAction(id: 'm1', studentId: 's1'));
      await repository.markCompleted('m1');
      final stored = await repository.get('m1');
      expect(stored.data?.status, 'completed');
    });

    test('markRejected works after init', () async {
      await repository.create(createTestAction(id: 'rj1', studentId: 's1'));
      await repository.markRejected('rj1');
      final stored = await repository.get('rj1');
      expect(stored.data?.status, 'rejected');
    });

    test('clearAll removes all actions for a student', () async {
      await repository.create(createTestAction(id: 'ca1', studentId: 's1'));
      await repository.create(createTestAction(id: 'ca2', studentId: 's1'));
      await repository.create(createTestAction(id: 'ca3', studentId: 's2'));
      await repository.clearAll('s1');
      expect((await repository.get('ca1')).data, isNull);
      expect((await repository.get('ca2')).data, isNull);
      expect((await repository.get('ca3')).data, isNotNull);
    });

    test('hasPending returns true when pending actions exist', () async {
      await repository.create(createTestAction(id: 'hp1', studentId: 's1'));
      expect((await repository.hasPending('s1')).data, isTrue);
    });

    test('hasPending returns false when only completed actions exist', () async {
      await repository.create(createTestAction(id: 'hp2', studentId: 's1', status: 'completed'));
      expect((await repository.hasPending('s1')).data, isFalse);
    });
  });
}

class _TestPendingActionAdapter extends TypeAdapter<PendingActionModel> {
  @override
  final int typeId = 5;

  @override
  PendingActionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingActionModel(
      id: fields[0] as String,
      studentId: fields[1] as String,
      actionType: fields[2] as String,
      topicTitle: fields[3] as String? ?? '',
      sessionId: fields[4] as String?,
      payload: (fields[5] as Map?)?.map((k, v) => MapEntry(k as String, v)) ?? {},
      createdAt: fields[6] as DateTime,
      status: fields[7] as String? ?? 'pending',
    );
  }

  @override
  void write(BinaryWriter writer, PendingActionModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.actionType)
      ..writeByte(3)
      ..write(obj.topicTitle)
      ..writeByte(4)
      ..write(obj.sessionId)
      ..writeByte(5)
      ..write(obj.payload)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.status);
  }
}
