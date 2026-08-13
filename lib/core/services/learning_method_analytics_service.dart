import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/learning_preference_model.dart';
import 'package:studyking/core/errors/result.dart';

class LearningMethodAnalyticsService {

  Box<LearningPreference>? _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(HiveBoxNames.learningPreferences)) {
      _box = await Hive.openBox<LearningPreference>(HiveBoxNames.learningPreferences);
    } else {
      _box = Hive.box<LearningPreference>(HiveBoxNames.learningPreferences);
    }
  }

  Box<LearningPreference> get _requireBox {
    if (_box == null || !_box!.isOpen) {
      throw StateError('LearningMethodAnalyticsService not initialized');
    }
    return _box!;
  }

  Future<Result<LearningPreference>> getPreference(String studentId) async {
    return Result.capture(() async {
      final box = _requireBox;
      final existing = box.get(studentId);
      if (existing != null) return existing;
      return LearningPreference.empty(studentId);
    }, context: 'getPreference');
  }

  Future<Result<void>> recordBlockTypeEngagement({
    required String studentId,
    required String blockType,
    required double quizScore,
  }) async {
    return Result.capture(() async {
      final box = _requireBox;
      final existing = box.get(studentId) ?? LearningPreference.empty(studentId);

      final scores = Map<String, double>.from(existing.methodEffectivenessScores);
      final currentScore = scores[blockType] ?? 0.0;
      final count = (currentScore * 100).round();
      final newScore = ((currentScore * count) + quizScore) / (count + 1);
      scores[blockType] = newScore;

      final preferred = scores.entries.fold<MapEntry<String, double>?>(
        null,
        (best, e) => best == null || e.value > best.value ? e : best,
      );

      await box.put(
        studentId,
        existing.copyWith(
          preferredBlockType: preferred?.key ?? existing.preferredBlockType,
          methodEffectivenessScores: scores,
        ),
      );
    }, context: 'recordBlockTypeEngagement');
  }

  Future<Result<void>> recordSessionDuration({
    required String studentId,
    required int durationMinutes,
    required double accuracyImprovement,
  }) async {
    return Result.capture(() async {
      final box = _requireBox;
      final existing = box.get(studentId) ?? LearningPreference.empty(studentId);

      final currentOptimal = existing.optimalSessionDurationMinutes;
      final improvementDelta = accuracyImprovement;

      int newOptimal;
      if (improvementDelta > 0.1) {
        newOptimal = currentOptimal;
      } else if (durationMinutes > currentOptimal + 5) {
        newOptimal = max(10, currentOptimal - 5);
      } else {
        newOptimal = min(60, currentOptimal + 5);
      }

      await box.put(
        studentId,
        existing.copyWith(optimalSessionDurationMinutes: newOptimal),
      );
    }, context: 'recordSessionDuration');
  }

  Future<Result<void>> recordVisualPreference({
    required String studentId,
    required bool usedSlides,
    required double quizScore,
  }) async {
    return Result.capture(() async {
      final box = _requireBox;
      final existing = box.get(studentId) ?? LearningPreference.empty(studentId);

      final visualKey = 'visual_${usedSlides ? "slides" : "text"}';
      final scores = Map<String, double>.from(existing.methodEffectivenessScores);
      final currentScore = scores[visualKey] ?? 0.0;
      final count = (currentScore * 100).round();
      final newScore = ((currentScore * count) + quizScore) / (count + 1);
      scores[visualKey] = newScore;

      final visualScore = scores['visual_slides'] ?? 0.0;
      final textScore = scores['visual_text'] ?? 0.0;
      final prefersVisual = visualScore > textScore && visualScore > 0.5;

      await box.put(
        studentId,
        existing.copyWith(
          prefersVisualExplanations: prefersVisual,
          methodEffectivenessScores: scores,
        ),
      );
    }, context: 'recordVisualPreference');
  }

  Future<Result<void>> recordSpacedRepetitionEffectiveness({
    required String studentId,
    required bool usedSpacedRepetition,
    required double retentionScore,
  }) async {
    return Result.capture(() async {
      final box = _requireBox;
      final existing = box.get(studentId) ?? LearningPreference.empty(studentId);

      final srKey = 'sr_adherence';
      final scores = Map<String, double>.from(existing.methodEffectivenessScores);
      final currentScore = scores[srKey] ?? 0.0;
      final count = (currentScore * 100).round();
      final newScore = ((currentScore * count) + retentionScore) / (count + 1);
      scores[srKey] = newScore;

      await box.put(
        studentId,
        existing.copyWith(
          spacedRepetitionEffectiveness: newScore,
          methodEffectivenessScores: scores,
        ),
      );
    }, context: 'recordSpacedRepetitionEffectiveness');
  }

  Future<Result<Map<String, dynamic>>> getLearningInsights(String studentId) async {
    return Result.capture(() async {
      final pref = (await getPreference(studentId)).data ?? LearningPreference.empty(studentId);

      final insights = <String, dynamic>{
        'preferredBlockType': pref.preferredBlockType,
        'optimalSessionMinutes': pref.optimalSessionDurationMinutes,
        'prefersVisual': pref.prefersVisualExplanations,
        'prefersStepByStep': pref.prefersStepByStep,
        'srEffectiveness': pref.spacedRepetitionEffectiveness,
        'methodScores': pref.methodEffectivenessScores,
        'hasData': pref.methodEffectivenessScores.isNotEmpty,
      };

      return insights;
    }, context: 'getLearningInsights');
  }

  Future<Result<List<LearningPreference>>> getAllPreferences() async {
    return Result.capture(() async {
      final box = _requireBox;
      return box.values.toList();
    }, context: 'getAllPreferences');
  }
}
