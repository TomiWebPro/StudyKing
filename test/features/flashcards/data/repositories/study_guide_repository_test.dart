import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/features/flashcards/data/adapters/flashcard_adapters.dart';
import 'package:studyking/features/flashcards/data/models/study_guide_model.dart';
import 'package:studyking/features/flashcards/data/repositories/study_guide_repository.dart';

late String _hivePath;
int _counter = 0;

StudyGuide _guide(String id, String sourceId, String topicId) => StudyGuide(
      id: id,
      sourceId: sourceId,
      topicId: topicId,
      subjectId: 'sub1',
      title: 'Study Guide: $id',
      content: 'content $id',
      createdAt: DateTime(2026, 7, 23),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('sg_repo_test_');
    _hivePath = dir.path;
    Hive.init(_hivePath);
    Hive.registerAdapter(StudyGuideAdapter());
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await Directory(_hivePath).delete(recursive: true);
  });

  group('happy path', () {
    late StudyGuideRepository repo;
    late Box<StudyGuide> box;

    setUp(() async {
      _counter++;
      box = await Hive.openBox<StudyGuide>('sg_box_$_counter');
      repo = StudyGuideRepository();
      repo.attachBox(box);
    });

    tearDown(() async {
      await box.close();
      await Hive.deleteBoxFromDisk('sg_box_$_counter');
    });

    test('create stores a study guide', () async {
      final result = await repo.create(_guide('sg1', 's1', 't1'));
      expect(result.isSuccess, isTrue);
      expect((await repo.getAll()).data!.length, 1);
    });

    test('getBySource filters by sourceId', () async {
      await repo.create(_guide('sg1', 's1', 't1'));
      await repo.create(_guide('sg2', 's2', 't1'));
      final result = await repo.getBySource('s1');
      expect(result.data!.length, 1);
      expect(result.data!.first.sourceId, 's1');
    });

    test('getByTopic filters by topicId', () async {
      await repo.create(_guide('sg1', 's1', 't1'));
      await repo.create(_guide('sg2', 's1', 't2'));
      final result = await repo.getByTopic('t2');
      expect(result.data!.length, 1);
    });
  });

  group('init', () {
    test('init opens the studyGuides box', () async {
      final repo = StudyGuideRepository();
      if (Hive.isBoxOpen(HiveBoxNames.studyGuides)) {
        await Hive.box(HiveBoxNames.studyGuides).close();
        await Hive.deleteBoxFromDisk(HiveBoxNames.studyGuides);
      }
      final result = await repo.init();
      expect(result.isSuccess, isTrue);
      expect(repo.isOpen, isTrue);
    });
  });

  group('failure paths', () {
    test('getBySource without open box returns failure', () async {
      await Hive.close();
      final repo = StudyGuideRepository();
      final result = await repo.getBySource('s1');
      expect(result.isFailure, isTrue);
    });
  });
}
