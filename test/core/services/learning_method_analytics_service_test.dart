import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/adapters/learning_preference_adapter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/learning_preference_model.dart';
import 'package:studyking/core/services/learning_method_analytics_service.dart';

late String _hivePath;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('lma_test_');
    _hivePath = dir.path;
    Hive.init(_hivePath);
    Hive.registerAdapter(LearningPreferenceAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await Hive.deleteFromDisk();
    } catch (_) {
      // best-effort cleanup
    }
    await Directory(_hivePath).delete(recursive: true);
  });

  group('happy path', () {
    late LearningMethodAnalyticsService service;

    setUp(() async {
      service = LearningMethodAnalyticsService();
      await service.init();
      final box = Hive.box<LearningPreference>(HiveBoxNames.learningPreferences);
      await box.clear();
    });

    test('getPreference returns empty preference for new student', () async {
      final result = await service.getPreference('stu1');
      expect(result.isSuccess, isTrue);
      expect(result.data!.studentId, 'stu1');
      expect(result.data!.methodEffectivenessScores, isEmpty);
    });

    test('recordBlockTypeEngagement updates scores and preferred type', () async {
      await service.recordBlockTypeEngagement(
        studentId: 'stu1',
        blockType: 'quiz',
        quizScore: 1.0,
      );
      final pref = (await service.getPreference('stu1')).data!;
      expect(pref.methodEffectivenessScores['quiz'], 1.0);
      expect(pref.preferredBlockType, 'quiz');
    });

    test('recordBlockTypeEngagement averages across calls and keeps best', () async {
      await service.recordBlockTypeEngagement(
        studentId: 'stu1',
        blockType: 'quiz',
        quizScore: 1.0,
      );
      await service.recordBlockTypeEngagement(
        studentId: 'stu1',
        blockType: 'exercise',
        quizScore: 0.0,
      );
      final pref = (await service.getPreference('stu1')).data!;
      // quiz stays at 1.0 (only the recorded blockType is averaged);
      // exercise is recorded once with score 0.0.
      expect(pref.methodEffectivenessScores['quiz'], 1.0);
      expect(pref.methodEffectivenessScores['exercise'], 0.0);
      expect(pref.preferredBlockType, 'quiz');
    });

    test('recordSessionDuration decreases optimal when too long', () async {
      await service.recordSessionDuration(
        studentId: 'stu1',
        durationMinutes: 60,
        accuracyImprovement: 0.0,
      );
      final pref = (await service.getPreference('stu1')).data!;
      expect(pref.optimalSessionDurationMinutes, 20);
    });

    test('recordSessionDuration keeps optimal on strong improvement', () async {
      await service.recordSessionDuration(
        studentId: 'stu1',
        durationMinutes: 60,
        accuracyImprovement: 0.5,
      );
      final pref = (await service.getPreference('stu1')).data!;
      expect(pref.optimalSessionDurationMinutes, 25);
    });

    test('recordVisualPreference sets prefersVisual for high slide score', () async {
      await service.recordVisualPreference(
        studentId: 'stu1',
        usedSlides: true,
        quizScore: 1.0,
      );
      final pref = (await service.getPreference('stu1')).data!;
      expect(pref.methodEffectivenessScores['visual_slides'], 1.0);
      expect(pref.prefersVisualExplanations, isTrue);
    });

    test('recordSpacedRepetitionEffectiveness records sr score', () async {
      await service.recordSpacedRepetitionEffectiveness(
        studentId: 'stu1',
        usedSpacedRepetition: true,
        retentionScore: 0.9,
      );
      final pref = (await service.getPreference('stu1')).data!;
      expect(pref.spacedRepetitionEffectiveness, 0.9);
    });

    test('getLearningInsights reports hasData after recording', () async {
      await service.recordBlockTypeEngagement(
        studentId: 'stu1',
        blockType: 'quiz',
        quizScore: 0.8,
      );
      final result = await service.getLearningInsights('stu1');
      expect(result.isSuccess, isTrue);
      final insights = result.data!;
      expect(insights['hasData'], isTrue);
      expect(insights['preferredBlockType'], 'quiz');
    });

    test('getAllPreferences returns stored preferences', () async {
      await service.recordBlockTypeEngagement(
        studentId: 'stu1',
        blockType: 'quiz',
        quizScore: 0.8,
      );
      final result = await service.getAllPreferences();
      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 1);
    });
  });

  group('failure paths', () {
    test('getPreference before init returns failure', () async {
      final service = LearningMethodAnalyticsService();
      final result = await service.getPreference('stu1');
      expect(result.isFailure, isTrue);
    });
  });
}
