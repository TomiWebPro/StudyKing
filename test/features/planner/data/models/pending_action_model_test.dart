import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';

void main() {
  group('PendingActionModel', () {
    const id = 'action-1';
    const studentId = 'student-1';
    const actionType = 'schedule';
    const topicTitle = 'Kinematics';
    const sessionId = 'session-1';

    group('constructor', () {
      test('creates instance with required fields', () {
        final action = PendingActionModel(
          id: id, studentId: studentId, actionType: actionType,
        );
        expect(action.id, id);
        expect(action.studentId, studentId);
        expect(action.actionType, actionType);
        expect(action.topicTitle, '');
        expect(action.sessionId, isNull);
        expect(action.payload, {});
        expect(action.status, 'pending');
        expect(action.createdAt, isA<DateTime>());
      });

      test('accepts all optional fields', () {
        final now = DateTime(2026, 5, 16);
        final action = PendingActionModel(
          id: id, studentId: studentId, actionType: actionType,
          topicTitle: topicTitle, sessionId: sessionId,
          payload: {'key': 'value'}, createdAt: now, status: 'completed',
        );
        expect(action.topicTitle, topicTitle);
        expect(action.sessionId, sessionId);
        expect(action.payload, {'key': 'value'});
        expect(action.createdAt, now);
        expect(action.status, 'completed');
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final action = PendingActionModel(
          id: id, studentId: studentId, actionType: actionType,
        );
        final copy = action.copyWith();
        expect(copy.id, action.id);
        expect(copy.actionType, action.actionType);
        expect(copy.status, action.status);
      });

      test('updates specified fields', () {
        final action = PendingActionModel(
          id: id, studentId: studentId, actionType: actionType,
        );
        final copy = action.copyWith(status: 'cancelled', topicTitle: 'Dynamics');
        expect(copy.status, 'cancelled');
        expect(copy.topicTitle, 'Dynamics');
        expect(copy.actionType, actionType);
      });
    });

    group('createdAt default', () {
      test('defaults to DateTime.now', () {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final action = PendingActionModel(
          id: id, studentId: studentId, actionType: actionType,
        );
        final after = DateTime.now().add(const Duration(seconds: 1));
        expect(action.createdAt.isAfter(before), isTrue);
        expect(action.createdAt.isBefore(after), isTrue);
      });
    });

    group('PendingActionType enum', () {
      test('has correct values in order', () {
        expect(PendingActionType.values, [
          PendingActionType.schedule,
          PendingActionType.reschedule,
          PendingActionType.planAdjustment,
        ]);
      });
    });

    group('equality', () {
      test('identical instances are equal', () {
        final a = PendingActionModel(
          id: id, studentId: studentId, actionType: actionType,
        );
        expect(a == a, isTrue);
      });

      test('different instances are not equal', () {
        final a = PendingActionModel(
          id: id, studentId: studentId, actionType: actionType,
        );
        final b = PendingActionModel(
          id: 'other', studentId: studentId, actionType: actionType,
        );
        expect(a == b, isFalse);
      });

      test('hashCode is consistent', () {
        final a = PendingActionModel(
          id: id, studentId: studentId, actionType: actionType,
        );
        expect(a.hashCode, a.hashCode);
      });
    });
  });
}
