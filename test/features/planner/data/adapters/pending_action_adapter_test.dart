import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/planner/data/adapters/pending_action_adapter.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';

late String _hivePath;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('pa_adapter_test_');
    _hivePath = dir.path;
    Hive.init(_hivePath);
    Hive.registerAdapter(PendingActionModelAdapter());
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await Directory(_hivePath).delete(recursive: true);
  });

  group('PendingActionModelAdapter', () {
    test('typeId is 5', () => expect(PendingActionModelAdapter().typeId, 5));

    test('hashCode and equality', () {
      expect(PendingActionModelAdapter().hashCode, PendingActionModelAdapter().hashCode);
      expect(PendingActionModelAdapter() == PendingActionModelAdapter(), isTrue);
      expect(PendingActionModelAdapter() == Object(), isFalse);
    });

    test('write/read round-trip', () async {
      final box = await Hive.openBox<PendingActionModel>('pa_rt');
      final created = DateTime(2026, 7, 23);
      final action = PendingActionModel(
        id: 'pa1',
        studentId: 'stu1',
        actionType: 'reschedule',
        topicTitle: 'Photosynthesis',
        sessionId: 'sess1',
        payload: {'oldTime': '10:00', 'newTime': '12:00'},
        createdAt: created,
        status: 'pending',
      );
      await box.put('pa1', action);
      final restored = box.get('pa1')!;
      expect(restored.id, 'pa1');
      expect(restored.studentId, 'stu1');
      expect(restored.actionType, 'reschedule');
      expect(restored.topicTitle, 'Photosynthesis');
      expect(restored.sessionId, 'sess1');
      expect(restored.payload['oldTime'], '10:00');
      expect(restored.status, 'pending');
      await box.close();
    });

    test('write/read with defaults', () async {
      final box = await Hive.openBox<PendingActionModel>('pa_def');
      final action = PendingActionModel(
        id: 'pa2',
        studentId: 'stu1',
        actionType: 'schedule',
      );
      await box.put('pa2', action);
      final restored = box.get('pa2')!;
      expect(restored.actionType, 'schedule');
      expect(restored.topicTitle, '');
      expect(restored.payload, isEmpty);
      expect(restored.sessionId, isNull);
      expect(restored.status, 'pending');
      await box.close();
    });
  });
}
