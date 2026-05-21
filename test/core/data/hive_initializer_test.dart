import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_initializer.dart';

void main() {
  late String tempDirPath;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('hive_test_');
    tempDirPath = dir.path;
    Hive.init(tempDirPath);
    await HiveInitializer.initialize();
  });

  tearDownAll(() {
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

  group('HiveInitializer', () {
    test('initialize opens all expected boxes', () {
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
      expect(Hive.isBoxOpen('lessons'), isTrue);
      expect(Hive.isBoxOpen('sessions'), isTrue);
      expect(Hive.isBoxOpen('progress'), isTrue);
      expect(Hive.isBoxOpen('tasks'), isTrue);
      expect(Hive.isBoxOpen('conversations'), isTrue);
      expect(Hive.isBoxOpen('tutor_sessions'), isTrue);
      expect(Hive.isBoxOpen('plan_adherence_metrics'), isTrue);
      expect(Hive.isBoxOpen('mastery_improvement_metrics'), isTrue);
    });

    test('initialize registers adapters', () {
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
    });

    test('can re-initialize without error when adapters already registered', () async {
      await expectLater(HiveInitializer.initialize(), completes);
    });
  });
}
