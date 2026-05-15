import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/engagement_nudge_model.dart';

void main() {
  group('EngagementNudgeModel', () {
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 5, 12, 10, 0, 0);
    });

    group('constructor', () {
      test('creates with required fields', () {
        final nudge = EngagementNudgeModel(
          id: 'nudge-1',
          studentId: 'student-1',
          nudgeType: 'overwork',
          message: 'Take a break!',
        );
        expect(nudge.id, 'nudge-1');
        expect(nudge.studentId, 'student-1');
        expect(nudge.nudgeType, 'overwork');
        expect(nudge.message, 'Take a break!');
        expect(nudge.severity, 'medium');
        expect(nudge.topicId, isNull);
        expect(nudge.wasActedUpon, isFalse);
        expect(nudge.actedUponAt, isNull);
      });

      test('creates with all fields', () {
        final nudge = EngagementNudgeModel(
          id: 'nudge-2',
          studentId: 'student-1',
          nudgeType: 'revision',
          message: 'Time to revise!',
          severity: 'high',
          topicId: 'topic-1',
          sentAt: now,
          wasActedUpon: true,
          actedUponAt: now,
        );
        expect(nudge.nudgeType, 'revision');
        expect(nudge.severity, 'high');
        expect(nudge.topicId, 'topic-1');
        expect(nudge.sentAt, now);
        expect(nudge.wasActedUpon, isTrue);
        expect(nudge.actedUponAt, now);
      });

      test('defaults sentAt to now', () {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final nudge = EngagementNudgeModel(
          id: 'n1',
          studentId: 's1',
          nudgeType: 'overwork',
          message: 'M',
        );
        final after = DateTime.now().add(const Duration(seconds: 1));
        expect(nudge.sentAt.isAfter(before), isTrue);
        expect(nudge.sentAt.isBefore(after), isTrue);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final nudge = EngagementNudgeModel(
          id: 'n1',
          studentId: 's1',
          nudgeType: 'overwork',
          message: 'M',
          severity: 'high',
          topicId: 't1',
          sentAt: now,
          wasActedUpon: true,
          actedUponAt: now,
        );
        final copy = nudge.copyWith();
        expect(copy.id, nudge.id);
        expect(copy.studentId, nudge.studentId);
        expect(copy.nudgeType, nudge.nudgeType);
        expect(copy.message, nudge.message);
        expect(copy.severity, nudge.severity);
        expect(copy.topicId, nudge.topicId);
        expect(copy.sentAt, nudge.sentAt);
        expect(copy.wasActedUpon, nudge.wasActedUpon);
        expect(copy.actedUponAt, nudge.actedUponAt);
      });

      test('updates specified fields', () {
        final nudge = EngagementNudgeModel(
          id: 'n1',
          studentId: 's1',
          nudgeType: 'overwork',
          message: 'M',
        );
        final copy = nudge.copyWith(
          message: 'New message',
          severity: 'high',
          wasActedUpon: true,
        );
        expect(copy.message, 'New message');
        expect(copy.severity, 'high');
        expect(copy.wasActedUpon, isTrue);
        expect(copy.id, 'n1');
      });

      test('updates nullable fields', () {
        final nudge = EngagementNudgeModel(
          id: 'n1',
          studentId: 's1',
          nudgeType: 'overwork',
          message: 'M',
        );
        final copy = nudge.copyWith(
          topicId: 'topic-1',
          actedUponAt: now,
        );
        expect(copy.topicId, 'topic-1');
        expect(copy.actedUponAt, now);
      });
    });
  });

  group('NudgeType', () {
    test('has expected values', () {
      expect(NudgeType.values, [
        NudgeType.overwork,
        NudgeType.revision,
        NudgeType.planAdjustment,
        NudgeType.lessonReminder,
      ]);
    });
  });

  group('NudgeSeverity', () {
    test('has expected values', () {
      expect(NudgeSeverity.values, [
        NudgeSeverity.low,
        NudgeSeverity.medium,
        NudgeSeverity.high,
      ]);
    });
  });
}
