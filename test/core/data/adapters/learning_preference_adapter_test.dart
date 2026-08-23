import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/adapters/learning_preference_adapter.dart';
import 'package:studyking/core/data/models/learning_preference_model.dart';

late String _hivePath;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('lp_adapter_test_');
    _hivePath = dir.path;
    Hive.init(_hivePath);
    Hive.registerAdapter(LearningPreferenceAdapter());
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await Directory(_hivePath).delete(recursive: true);
  });

  group('LearningPreferenceAdapter', () {
    test('typeId is 43', () => expect(LearningPreferenceAdapter().typeId, 43));

    test('hashCode and equality', () {
      expect(LearningPreferenceAdapter().hashCode, LearningPreferenceAdapter().hashCode);
      expect(LearningPreferenceAdapter() == LearningPreferenceAdapter(), isTrue);
      expect(LearningPreferenceAdapter() == Object(), isFalse);
    });

    test('write/read round-trip', () async {
      final box = await Hive.openBox<LearningPreference>('lp_rt');
      final updated = DateTime(2026, 7, 23);
      final pref = LearningPreference(
        studentId: 'stu1',
        preferredBlockType: 'quiz',
        optimalSessionDurationMinutes: 40,
        prefersVisualExplanations: true,
        prefersStepByStep: false,
        spacedRepetitionEffectiveness: 0.8,
        methodEffectivenessScores: {'quiz': 0.7, 'exercise': 0.5},
        lastUpdated: updated,
      );
      await box.put('stu1', pref);
      final restored = box.get('stu1')!;
      expect(restored.studentId, 'stu1');
      expect(restored.preferredBlockType, 'quiz');
      expect(restored.optimalSessionDurationMinutes, 40);
      expect(restored.prefersVisualExplanations, isTrue);
      expect(restored.prefersStepByStep, isFalse);
      expect(restored.spacedRepetitionEffectiveness, 0.8);
      expect(restored.methodEffectivenessScores['quiz'], 0.7);
      expect(restored.lastUpdated, updated);
      await box.close();
    });

    test('write/read with defaults', () async {
      final box = await Hive.openBox<LearningPreference>('lp_def');
      final pref = LearningPreference(
        studentId: 'stu2',
        lastUpdated: DateTime(2026, 7, 23),
      );
      await box.put('stu2', pref);
      final restored = box.get('stu2')!;
      expect(restored.preferredBlockType, 'exercise');
      expect(restored.optimalSessionDurationMinutes, 25);
      expect(restored.prefersVisualExplanations, isFalse);
      expect(restored.prefersStepByStep, isTrue);
      expect(restored.spacedRepetitionEffectiveness, 0.0);
      expect(restored.methodEffectivenessScores, isEmpty);
      await box.close();
    });
  });
}
