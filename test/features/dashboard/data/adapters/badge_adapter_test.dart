import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/dashboard/data/adapters/badge_adapter.dart';
import 'package:studyking/features/dashboard/data/models/badge_model.dart';

late String _hivePath;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('badge_adapter_test_');
    _hivePath = dir.path;
    Hive.init(_hivePath);
    Hive.registerAdapter(BadgeModelAdapter());
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await Directory(_hivePath).delete(recursive: true);
  });

  group('BadgeModelAdapter', () {
    test('typeId is 8', () => expect(BadgeModelAdapter().typeId, 8));

    test('hashCode and equality', () {
      expect(BadgeModelAdapter().hashCode, BadgeModelAdapter().hashCode);
      expect(BadgeModelAdapter() == BadgeModelAdapter(), isTrue);
      expect(BadgeModelAdapter() == Object(), isFalse);
    });

    test('write/read round-trip', () async {
      final box = await Hive.openBox<BadgeModel>('badges_rt');
      final unlocked = DateTime(2026, 7, 23);
      final badge = BadgeModel(
        id: 'b1',
        studentId: 'stu1',
        name: 'First Step',
        description: 'Answered first question',
        iconName: 'emoji_events',
        category: 'milestone',
        unlockedAt: unlocked,
        criteria: {'totalAttempts': 1},
      );
      await box.put('b1', badge);
      final restored = box.get('b1')!;
      expect(restored.id, 'b1');
      expect(restored.name, 'First Step');
      expect(restored.category, 'milestone');
      expect(restored.unlockedAt, unlocked);
      expect(restored.criteria!['totalAttempts'], 1);
      await box.close();
    });

    test('write/read with defaults', () async {
      final box = await Hive.openBox<BadgeModel>('badges_def');
      final badge = BadgeModel(
        id: 'b2',
        studentId: 'stu1',
        name: 'Century',
        description: '100 questions',
      );
      await box.put('b2', badge);
      final restored = box.get('b2')!;
      expect(restored.iconName, 'emoji_events');
      expect(restored.category, 'general');
      expect(restored.criteria, isNull);
      await box.close();
    });
  });
}
