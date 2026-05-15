import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';

void main() {
  group('PendingActionModel', () {
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 5, 12, 10, 0, 0);
    });

    group('constructor', () {
      test('creates with required fields', () {
        final action = PendingActionModel(
          id: 'action-1',
          studentId: 'student-1',
          actionType: 'schedule',
        );
        expect(action.id, 'action-1');
        expect(action.studentId, 'student-1');
        expect(action.actionType, 'schedule');
        expect(action.topicTitle, '');
        expect(action.sessionId, isNull);
        expect(action.payload, {});
        expect(action.status, 'pending');
      });

      test('creates with all fields', () {
        final action = PendingActionModel(
          id: 'action-2',
          studentId: 'student-1',
          actionType: 'reschedule',
          topicTitle: 'Algebra',
          sessionId: 'session-1',
          payload: {'reason': 'conflict'},
          createdAt: now,
          status: 'completed',
        );
        expect(action.actionType, 'reschedule');
        expect(action.topicTitle, 'Algebra');
        expect(action.sessionId, 'session-1');
        expect(action.payload, {'reason': 'conflict'});
        expect(action.createdAt, now);
        expect(action.status, 'completed');
      });

      test('defaults createdAt to now', () {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final action = PendingActionModel(
          id: 'a1',
          studentId: 's1',
          actionType: 'schedule',
        );
        final after = DateTime.now().add(const Duration(seconds: 1));
        expect(action.createdAt.isAfter(before), isTrue);
        expect(action.createdAt.isBefore(after), isTrue);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final action = PendingActionModel(
          id: 'a1',
          studentId: 's1',
          actionType: 'schedule',
          topicTitle: 'Math',
          sessionId: 'sess-1',
          payload: {'k': 'v'},
          createdAt: now,
          status: 'pending',
        );
        final copy = action.copyWith();
        expect(copy.id, action.id);
        expect(copy.studentId, action.studentId);
        expect(copy.actionType, action.actionType);
        expect(copy.topicTitle, action.topicTitle);
        expect(copy.sessionId, action.sessionId);
        expect(copy.payload, action.payload);
        expect(copy.createdAt, action.createdAt);
        expect(copy.status, action.status);
      });

      test('updates specified fields', () {
        final action = PendingActionModel(
          id: 'a1',
          studentId: 's1',
          actionType: 'schedule',
        );
        final copy = action.copyWith(
          actionType: 'reschedule',
          status: 'completed',
          sessionId: 'sess-2',
        );
        expect(copy.actionType, 'reschedule');
        expect(copy.status, 'completed');
        expect(copy.sessionId, 'sess-2');
        expect(copy.id, 'a1');
      });

      test('updates payload', () {
        final action = PendingActionModel(
          id: 'a1',
          studentId: 's1',
          actionType: 'schedule',
        );
        final copy = action.copyWith(payload: {'new': 'data'});
        expect(copy.payload, {'new': 'data'});
      });
    });

    group('equality', () {
      test('uses identity-based equality', () {
        final a = PendingActionModel(id: 'a1', studentId: 's1', actionType: 's');
        final b = PendingActionModel(id: 'a1', studentId: 's1', actionType: 's');
        expect(a == b, isFalse);
        expect(a == a, isTrue);
      });

      test('hashCode is consistent', () {
        final obj = PendingActionModel(id: 'a1', studentId: 's1', actionType: 's');
        final hash = obj.hashCode;
        expect(obj.hashCode, hash);
      });
    });

    group('toString', () {
      test('includes class name', () {
        final obj = PendingActionModel(id: 'a1', studentId: 's1', actionType: 's');
        expect(obj.toString(), contains('PendingActionModel'));
      });
    });

    group('Hive type annotation', () {
      test('has correct Hive typeId', () {
        expect(PendingActionModel, isNotNull);
      });
    });
  });

  group('PendingActionType', () {
    test('has expected values', () {
      expect(PendingActionType.values, [
        PendingActionType.schedule,
        PendingActionType.reschedule,
        PendingActionType.planAdjustment,
      ]);
    });
  });
}
