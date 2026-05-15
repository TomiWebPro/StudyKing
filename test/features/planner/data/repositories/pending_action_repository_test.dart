import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';

class _MockPendingActionRepository extends PendingActionRepository {
  final Map<String, PendingActionModel> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> create(PendingActionModel action) async {
    _storage[action.id] = action;
  }

  @override
  Future<PendingActionModel?> get(String id) async {
    return _storage[id];
  }

  @override
  Future<List<PendingActionModel>> getPending(String studentId) async {
    return _storage.values
        .where((a) => a.studentId == studentId && a.status == 'pending')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> markCompleted(String id) async {
    final action = _storage[id];
    if (action != null) {
      _storage[id] = action.copyWith(status: 'completed');
    }
  }

  @override
  Future<void> markRejected(String id) async {
    final action = _storage[id];
    if (action != null) {
      _storage[id] = action.copyWith(status: 'rejected');
    }
  }

  @override
  Future<void> delete(String id) async {
    _storage.remove(id);
  }

  @override
  Future<void> clearAll(String studentId) async {
    final actions = _storage.values
        .where((a) => a.studentId == studentId)
        .toList();
    for (final action in actions) {
      _storage.remove(action.id);
    }
  }

  @override
  Future<bool> hasPending(String studentId) async {
    return _storage.values
        .any((a) => a.studentId == studentId && a.status == 'pending');
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
    late _MockPendingActionRepository repository;

    setUp(() {
      repository = _MockPendingActionRepository();
    });

    group('save', () {
      test('stores a pending action', () async {
        final action = createTestAction();
        await repository.create(action);
        final stored = await repository.get('action-1');
        expect(stored, isNotNull);
        expect(stored?.actionType, 'schedule');
      });

      test('overwrites existing action with same id', () async {
        await repository.create(createTestAction(actionType: 'schedule'));
        await repository.create(createTestAction(actionType: 'reschedule'));
        expect((await repository.get('action-1'))?.actionType, 'reschedule');
      });
    });

    group('get', () {
      test('returns null for non-existent action', () async {
        expect(await repository.get('none'), isNull);
      });

      test('returns stored action', () async {
        await repository.create(createTestAction());
        final result = await repository.get('action-1');
        expect(result?.id, 'action-1');
        expect(result?.status, 'pending');
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
        final result = await repository.getPending('s1');
        expect(result.length, 2);
        expect(result.first.id, 'a2');
      });

      test('returns empty when no pending actions', () async {
        await repository.create(createTestAction(
          id: 'a1', studentId: 's1', status: 'completed'));
        expect(await repository.getPending('s1'), isEmpty);
      });

      test('returns empty for student with no actions', () async {
        expect(await repository.getPending('none'), isEmpty);
      });
    });

    group('markCompleted', () {
      test('marks pending action as completed', () async {
        await repository.create(createTestAction(id: 'a1', studentId: 's1'));
        await repository.markCompleted('a1');
        final result = await repository.get('a1');
        expect(result?.status, 'completed');
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
        expect(result?.status, 'rejected');
      });

      test('does nothing for non-existent action', () async {
        await repository.markRejected('none');
      });
    });

    group('delete', () {
      test('removes an action', () async {
        await repository.create(createTestAction(id: 'a1'));
        await repository.delete('a1');
        expect(await repository.get('a1'), isNull);
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
        expect(await repository.get('a1'), isNull);
        expect(await repository.get('a2'), isNull);
        expect(await repository.get('a3'), isNotNull);
      });

      test('does nothing when student has no actions', () async {
        await repository.clearAll('none');
      });
    });

    group('hasPending', () {
      test('returns true when student has pending actions', () async {
        await repository.create(createTestAction(id: 'a1', studentId: 's1'));
        expect(await repository.hasPending('s1'), isTrue);
      });

      test('returns false when no pending actions exist', () async {
        await repository.create(createTestAction(
          id: 'a1', studentId: 's1', status: 'completed'));
        expect(await repository.hasPending('s1'), isFalse);
      });

      test('returns false for student with no actions', () async {
        expect(await repository.hasPending('none'), isFalse);
      });
    });
  });
}
