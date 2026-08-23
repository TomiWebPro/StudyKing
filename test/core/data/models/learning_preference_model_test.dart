import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/learning_preference_model.dart';

void main() {
  group('LearningPreference model', () {
    test('empty factory uses defaults', () {
      final pref = LearningPreference.empty('stu1');
      expect(pref.studentId, 'stu1');
      expect(pref.preferredBlockType, 'exercise');
      expect(pref.optimalSessionDurationMinutes, 25);
      expect(pref.prefersVisualExplanations, isFalse);
      expect(pref.prefersStepByStep, isTrue);
      expect(pref.spacedRepetitionEffectiveness, 0.0);
      expect(pref.methodEffectivenessScores, isEmpty);
    });

    test('toMap and fromMap round-trip', () {
      final updated = DateTime(2026, 7, 23);
      final pref = LearningPreference(
        studentId: 'stu1',
        preferredBlockType: 'quiz',
        optimalSessionDurationMinutes: 40,
        prefersVisualExplanations: true,
        prefersStepByStep: false,
        spacedRepetitionEffectiveness: 0.8,
        methodEffectivenessScores: {'quiz': 0.7},
        lastUpdated: updated,
      );
      final map = pref.toMap();
      final restored = LearningPreference.fromMap(map);
      expect(restored.studentId, 'stu1');
      expect(restored.preferredBlockType, 'quiz');
      expect(restored.optimalSessionDurationMinutes, 40);
      expect(restored.prefersVisualExplanations, isTrue);
      expect(restored.prefersStepByStep, isFalse);
      expect(restored.spacedRepetitionEffectiveness, 0.8);
      expect(restored.methodEffectivenessScores['quiz'], 0.7);
      expect(restored.lastUpdated, updated);
    });

    test('copyWith overrides provided fields and refreshes lastUpdated', () {
      final pref = LearningPreference.empty('stu1');
      final updated = pref.copyWith(
        preferredBlockType: 'exercise',
        optimalSessionDurationMinutes: 50,
        prefersVisualExplanations: true,
      );
      expect(updated.preferredBlockType, 'exercise');
      expect(updated.optimalSessionDurationMinutes, 50);
      expect(updated.prefersVisualExplanations, isTrue);
      expect(updated.studentId, 'stu1');
      expect(updated.lastUpdated.isAfter(pref.lastUpdated), isTrue);
    });

    test('fromMap handles missing fields with defaults', () {
      final restored = LearningPreference.fromMap({'studentId': 'stu2'});
      expect(restored.studentId, 'stu2');
      expect(restored.preferredBlockType, 'exercise');
      expect(restored.optimalSessionDurationMinutes, 25);
    });
  });
}
