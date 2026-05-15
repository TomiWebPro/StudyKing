import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_initializer.dart';

void main() {
  group('HiveInitializer', () {
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final dir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(dir.path);
    });

    tearDown(() {
      final boxes = [
        'question_evaluations', 'mastery_states', 'question_mastery_states',
        'topic_dependencies', 'learning_plans',
        'subjects', 'topics', 'questions', 'answers', 'sources',
        'attempts', 'lessonBlocks', 'lessons', 'sessions', 'progress', 'tasks',
        'conversations', 'tutor_sessions', 'plan_adherence_metrics',
        'mastery_improvement_metrics',
        'db_version',
      ];
      for (final box in boxes) {
        if (Hive.isBoxOpen(box)) {
          Hive.deleteBoxFromDisk(box);
        }
      }
    });

    test('initialize completes without error', () async {
      await expectLater(HiveInitializer.initialize(), completes);
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('initialize opens all expected boxes', () async {
      await HiveInitializer.initialize();

      expect(Hive.isBoxOpen('question_evaluations'), isTrue);
      expect(Hive.isBoxOpen('mastery_states'), isTrue);
      expect(Hive.isBoxOpen('question_mastery_states'), isTrue);
      expect(Hive.isBoxOpen('topic_dependencies'), isTrue);
      expect(Hive.isBoxOpen('learning_plans'), isTrue);
      expect(Hive.isBoxOpen('subjects'), isTrue);
      expect(Hive.isBoxOpen('topics'), isTrue);
      expect(Hive.isBoxOpen('questions'), isTrue);
      expect(Hive.isBoxOpen('answers'), isTrue);
      expect(Hive.isBoxOpen('sources'), isTrue);
      expect(Hive.isBoxOpen('attempts'), isTrue);
      expect(Hive.isBoxOpen('lessonBlocks'), isTrue);
      expect(Hive.isBoxOpen('lessons'), isTrue);
      expect(Hive.isBoxOpen('sessions'), isTrue);
      expect(Hive.isBoxOpen('progress'), isTrue);
      expect(Hive.isBoxOpen('tasks'), isTrue);
      expect(Hive.isBoxOpen('conversations'), isTrue);
      expect(Hive.isBoxOpen('tutor_sessions'), isTrue);
      expect(Hive.isBoxOpen('plan_adherence_metrics'), isTrue);
      expect(Hive.isBoxOpen('mastery_improvement_metrics'), isTrue);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('initialize registers adapters', () async {
      await HiveInitializer.initialize();

      expect(Hive.isAdapterRegistered(24), isTrue);
      expect(Hive.isAdapterRegistered(14), isTrue);
      expect(Hive.isAdapterRegistered(16), isTrue);
      expect(Hive.isAdapterRegistered(17), isTrue);
      expect(Hive.isAdapterRegistered(18), isTrue);
      expect(Hive.isAdapterRegistered(19), isTrue);
      expect(Hive.isAdapterRegistered(12), isTrue);
      expect(Hive.isAdapterRegistered(27), isTrue);
      expect(Hive.isAdapterRegistered(28), isTrue);
      expect(Hive.isAdapterRegistered(30), isTrue);
      expect(Hive.isAdapterRegistered(31), isTrue);
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
