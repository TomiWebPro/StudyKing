import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/features/flashcards/data/adapters/flashcard_adapters.dart';
import 'package:studyking/features/flashcards/data/models/concept_map_model.dart';
import 'package:studyking/features/flashcards/data/repositories/concept_map_repository.dart';

late String _hivePath;
int _counter = 0;

ConceptMap _map(String id, String sourceId, String topicId) => ConceptMap(
      id: id,
      sourceId: sourceId,
      topicId: topicId,
      subjectId: 'sub1',
      title: 'Concept Map: $id',
      nodes: [ConceptNode(id: 'n1', label: 'A')],
      edges: [],
      createdAt: DateTime(2026, 7, 23),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('cm_repo_test_');
    _hivePath = dir.path;
    Hive.init(_hivePath);
    Hive.registerAdapter(ConceptMapAdapter());
    Hive.registerAdapter(ConceptNodeAdapter());
    Hive.registerAdapter(ConceptEdgeAdapter());
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await Directory(_hivePath).delete(recursive: true);
  });

  group('happy path', () {
    late ConceptMapRepository repo;
    late Box<ConceptMap> box;

    setUp(() async {
      _counter++;
      box = await Hive.openBox<ConceptMap>('cm_box_$_counter');
      repo = ConceptMapRepository();
      repo.attachBox(box);
    });

    tearDown(() async {
      await box.close();
      await Hive.deleteBoxFromDisk('cm_box_$_counter');
    });

    test('create stores a concept map', () async {
      final result = await repo.create(_map('cm1', 's1', 't1'));
      expect(result.isSuccess, isTrue);
      final all = (await repo.getAll()).data ?? [];
      expect(all.length, 1);
    });

    test('getBySource filters by sourceId', () async {
      await repo.create(_map('cm1', 's1', 't1'));
      await repo.create(_map('cm2', 's2', 't1'));
      final result = await repo.getBySource('s1');
      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 1);
      expect(result.data!.first.sourceId, 's1');
    });

    test('getByTopic filters by topicId', () async {
      await repo.create(_map('cm1', 's1', 't1'));
      await repo.create(_map('cm2', 's1', 't2'));
      final result = await repo.getByTopic('t2');
      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 1);
      expect(result.data!.first.topicId, 't2');
    });

    test('getBySource returns empty when no match', () async {
      await repo.create(_map('cm1', 's1', 't1'));
      final result = await repo.getBySource('missing');
      expect(result.isSuccess, isTrue);
      expect(result.data!, isEmpty);
    });
  });

  group('init', () {
    test('init opens the conceptMaps box', () async {
      final repo = ConceptMapRepository();
      if (Hive.isBoxOpen(HiveBoxNames.conceptMaps)) {
        await Hive.box(HiveBoxNames.conceptMaps).close();
        await Hive.deleteBoxFromDisk(HiveBoxNames.conceptMaps);
      }
      final result = await repo.init();
      expect(result.isSuccess, isTrue);
      expect(repo.isOpen, isTrue);
    });
  });

  group('failure paths', () {
    test('getBySource without open box returns failure', () async {
      await Hive.close();
      final repo = ConceptMapRepository();
      final result = await repo.getBySource('s1');
      expect(result.isFailure, isTrue);
    });
  });
}
