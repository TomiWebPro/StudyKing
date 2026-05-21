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

    group('serialization', () {
      test('toJson/fromJson round-trip preserves all fields', () {
        final now = DateTime(2026, 5, 19);
        final original = PendingActionModel(
          id: 'rt-1',
          studentId: 'student-1',
          actionType: 'schedule',
          topicTitle: 'Kinematics',
          sessionId: 'session-1',
          payload: {'key': 'value'},
          createdAt: now,
          status: 'completed',
        );
        final json = original.toJson();
        final restored = PendingActionModel.fromJson(json);
        expect(restored.id, original.id);
        expect(restored.studentId, original.studentId);
        expect(restored.actionType, original.actionType);
        expect(restored.topicTitle, original.topicTitle);
        expect(restored.sessionId, original.sessionId);
        expect(restored.payload, original.payload);
        expect(restored.createdAt, original.createdAt);
        expect(restored.status, original.status);
      });

      test('toJson/fromJson round-trip with defaults', () {
        final original = PendingActionModel(
          id: 'rt-2',
          studentId: 'student-1',
          actionType: 'reschedule',
        );
        final json = original.toJson();
        final restored = PendingActionModel.fromJson(json);
        expect(restored.topicTitle, '');
        expect(restored.sessionId, isNull);
        expect(restored.payload, {});
        expect(restored.status, 'pending');
      });
    });

    group('edge cases', () {
      test('handles null sessionId and topicTitle default', () {
        final action = PendingActionModel(
          id: 'ec-1', studentId: 's1', actionType: 'schedule',
          sessionId: null, topicTitle: '',
        );
        expect(action.sessionId, isNull);
        expect(action.topicTitle, '');
      });

      test('handles empty payload', () {
        final action = PendingActionModel(
          id: 'ec-2', studentId: 's1', actionType: 'reschedule',
          payload: {},
        );
        expect(action.payload, {});
      });

      test('handles empty lists in payload', () {
        final action = PendingActionModel(
          id: 'ec-3', studentId: 's1', actionType: 'planAdjustment',
          payload: {'items': <String>[]},
        );
        expect(action.payload['items'], isEmpty);
      });

      test('handles very long topicTitle', () {
        final longTopic = 'a' * 5000;
        final action = PendingActionModel(
          id: 'ec-4', studentId: 's1', actionType: 'schedule',
          topicTitle: longTopic,
        );
        expect(action.topicTitle.length, 5000);
      });
    });
  });
}
