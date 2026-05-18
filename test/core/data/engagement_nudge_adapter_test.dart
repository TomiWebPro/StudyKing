import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/engagement_nudge_adapter.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';
import '../../helpers/hive_test_utils.dart';

void main() {
  group('EngagementNudgeModelAdapter', () {
    test('has correct typeId', () {
      final adapter = EngagementNudgeModelAdapter();
      expect(adapter.typeId, 32);
    });

    test('is a TypeAdapter<EngagementNudgeModel>', () {
      final adapter = EngagementNudgeModelAdapter();
      expect(adapter, isA<TypeAdapter<EngagementNudgeModel>>());
    });

    test('read and write round-trips with all fields', () {
      final adapter = EngagementNudgeModelAdapter();
      final now = DateTime.utc(2024, 7, 10, 14, 30);
      final nudge = EngagementNudgeModel(
        id: 'nudge1',
        studentId: 'student1',
        nudgeType: 'revision',
        message: 'Time to review physics',
        severity: 'high',
        topicId: 'topic1',
        sentAt: now,
        wasActedUpon: true,
        actedUponAt: now.add(const Duration(hours: 1)),
      );

      final writeCache = <int, dynamic>{};
      final writer = TestBinaryWriter(writeCache);
      adapter.write(writer, nudge);

      final reader = TestBinaryReader(writeCache);
      final restored = adapter.read(reader);

      expect(restored.id, nudge.id);
      expect(restored.studentId, nudge.studentId);
      expect(restored.nudgeType, nudge.nudgeType);
      expect(restored.message, nudge.message);
      expect(restored.severity, nudge.severity);
      expect(restored.topicId, nudge.topicId);
      expect(restored.sentAt, nudge.sentAt);
      expect(restored.wasActedUpon, nudge.wasActedUpon);
      expect(restored.actedUponAt, nudge.actedUponAt);
    });

    test('read and write round-trips with default values', () {
      final adapter = EngagementNudgeModelAdapter();
      final now = DateTime.utc(2024, 7, 10, 14, 30);
      final nudge = EngagementNudgeModel(
        id: 'nudge2',
        studentId: 'student2',
        nudgeType: 'wellbeing',
        message: 'Take a break',
        sentAt: now,
      );

      final writeCache = <int, dynamic>{};
      final writer = TestBinaryWriter(writeCache);
      adapter.write(writer, nudge);

      final reader = TestBinaryReader(writeCache);
      final restored = adapter.read(reader);

      expect(restored.id, nudge.id);
      expect(restored.studentId, nudge.studentId);
      expect(restored.nudgeType, nudge.nudgeType);
      expect(restored.message, nudge.message);
      expect(restored.severity, 'medium');
      expect(restored.topicId, isNull);
      expect(restored.wasActedUpon, false);
      expect(restored.actedUponAt, isNull);
    });

    test('read and write round-trips with null topicId and actedUponAt', () {
      final adapter = EngagementNudgeModelAdapter();
      final now = DateTime.utc(2024, 7, 10, 14, 30);
      final nudge = EngagementNudgeModel(
        id: 'nudge3',
        studentId: 'student3',
        nudgeType: 'plan_adjustment',
        message: 'Plan updated',
        severity: 'low',
        topicId: null,
        sentAt: now,
        wasActedUpon: false,
        actedUponAt: null,
      );

      final writeCache = <int, dynamic>{};
      final writer = TestBinaryWriter(writeCache);
      adapter.write(writer, nudge);

      final reader = TestBinaryReader(writeCache);
      final restored = adapter.read(reader);

      expect(restored.id, nudge.id);
      expect(restored.topicId, isNull);
      expect(restored.wasActedUpon, false);
      expect(restored.actedUponAt, isNull);
    });
  });
}
