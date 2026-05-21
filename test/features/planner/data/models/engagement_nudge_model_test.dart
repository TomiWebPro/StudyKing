import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';

void main() {
  group('EngagementNudgeModel', () {
    final now = DateTime(2026, 5, 16);
    const id = 'nudge-1';
    const studentId = 'student-1';
    const nudgeType = 'overwork';
    const message = 'You have studied 5 hours today, take a break!';
    const severity = 'high';
    const topicId = 'topic-1';

    group('constructor', () {
      test('creates instance with required fields', () {
        final nudge = EngagementNudgeModel(
          id: id,
          studentId: studentId,
          nudgeType: nudgeType,
          message: message,
        );

        expect(nudge.id, id);
        expect(nudge.studentId, studentId);
        expect(nudge.nudgeType, nudgeType);
        expect(nudge.message, message);
        expect(nudge.severity, 'medium');
        expect(nudge.topicId, isNull);
        expect(nudge.wasActedUpon, isFalse);
        expect(nudge.actedUponAt, isNull);
        expect(nudge.sentAt, isA<DateTime>());
      });

      test('accepts all optional fields', () {
        final nudge = EngagementNudgeModel(
          id: id,
          studentId: studentId,
          nudgeType: nudgeType,
          message: message,
          severity: severity,
          topicId: topicId,
          sentAt: now,
          wasActedUpon: true,
          actedUponAt: now,
        );

        expect(nudge.severity, severity);
        expect(nudge.topicId, topicId);
        expect(nudge.sentAt, now);
        expect(nudge.wasActedUpon, isTrue);
        expect(nudge.actedUponAt, now);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final nudge = EngagementNudgeModel(
          id: id, studentId: studentId, nudgeType: nudgeType, message: message,
        );
        final copy = nudge.copyWith();
        expect(copy.id, nudge.id);
        expect(copy.message, nudge.message);
        expect(copy.severity, nudge.severity);
      });

      test('updates specified fields', () {
        final nudge = EngagementNudgeModel(
          id: id, studentId: studentId, nudgeType: nudgeType, message: message,
        );
        final copy = nudge.copyWith(severity: severity, wasActedUpon: true);
        expect(copy.severity, severity);
        expect(copy.wasActedUpon, isTrue);
        expect(copy.message, message);
      });
    });

    group('NudgeType enum', () {
      test('has correct values in order', () {
        expect(NudgeType.values, [
          NudgeType.overwork,
          NudgeType.revision,
          NudgeType.planAdjustment,
          NudgeType.lessonReminder,
          NudgeType.autoRegeneration,
        ]);
      });
    });

    group('NudgeSeverity enum', () {
      test('has correct values in order', () {
        expect(NudgeSeverity.values, [
          NudgeSeverity.low,
          NudgeSeverity.medium,
          NudgeSeverity.high,
        ]);
      });
    });

    group('sentAt default', () {
      test('defaults to DateTime.now on creation', () {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final nudge = EngagementNudgeModel(
          id: id, studentId: studentId, nudgeType: nudgeType, message: message,
        );
        final after = DateTime.now().add(const Duration(seconds: 1));
        expect(nudge.sentAt.isAfter(before), isTrue);
        expect(nudge.sentAt.isBefore(after), isTrue);
      });
    });

    group('equality', () {
      test('identical instances are equal', () {
        final a = EngagementNudgeModel(
          id: id, studentId: studentId, nudgeType: nudgeType, message: message,
        );
        expect(a == a, isTrue);
      });

      test('different instances are not equal', () {
        final a = EngagementNudgeModel(
          id: id, studentId: studentId, nudgeType: nudgeType, message: message,
        );
        final b = EngagementNudgeModel(
          id: 'other', studentId: studentId, nudgeType: nudgeType, message: message,
        );
        expect(a == b, isFalse);
      });

      test('hashCode is consistent', () {
        final a = EngagementNudgeModel(
          id: id, studentId: studentId, nudgeType: nudgeType, message: message,
        );
        expect(a.hashCode, a.hashCode);
      });
    });

    group('serialization', () {
      test('toJson/fromJson round-trip preserves all fields', () {
        final now = DateTime(2026, 5, 19);
        final original = EngagementNudgeModel(
          id: 'rt-1',
          studentId: 'student-1',
          nudgeType: 'overwork',
          message: 'Take a break!',
          severity: 'high',
          topicId: 'topic-1',
          sentAt: now,
          wasActedUpon: true,
          actedUponAt: now,
        );
        final json = original.toJson();
        final restored = EngagementNudgeModel.fromJson(json);
        expect(restored.id, original.id);
        expect(restored.studentId, original.studentId);
        expect(restored.nudgeType, original.nudgeType);
        expect(restored.message, original.message);
        expect(restored.severity, original.severity);
        expect(restored.topicId, original.topicId);
        expect(restored.sentAt, original.sentAt);
        expect(restored.wasActedUpon, original.wasActedUpon);
        expect(restored.actedUponAt, original.actedUponAt);
      });

      test('toJson/fromJson round-trip with null optionals', () {
        final original = EngagementNudgeModel(
          id: 'rt-2',
          studentId: 'student-1',
          nudgeType: 'motivation',
          message: 'Keep going!',
        );
        final json = original.toJson();
        final restored = EngagementNudgeModel.fromJson(json);
        expect(restored.severity, 'medium');
        expect(restored.topicId, isNull);
        expect(restored.wasActedUpon, isFalse);
        expect(restored.actedUponAt, isNull);
      });
    });
  });
}
