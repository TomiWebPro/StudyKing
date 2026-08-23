import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/features/flashcards/data/adapters/flashcard_adapters.dart';
import 'package:studyking/features/flashcards/data/models/flashcard_model.dart';
import 'package:studyking/features/flashcards/data/repositories/flashcard_repository.dart';

late String _hivePath;
int _counter = 0;

Flashcard _card({
  String id = 'fc1',
  String sourceId = 's1',
  String topicId = 't1',
  String subjectId = 'sub1',
}) {
  final now = DateTime(2026, 7, 23);
  return Flashcard(
    id: id,
    sourceId: sourceId,
    topicId: topicId,
    subjectId: subjectId,
    front: 'Q: $id',
    back: 'A',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('fc_repo_test_');
    _hivePath = dir.path;
    Hive.init(_hivePath);
    Hive.registerAdapter(FlashcardAdapter());
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await Directory(_hivePath).delete(recursive: true);
  });

  group('happy path', () {
    late FlashcardRepository repo;
    late Box<Flashcard> box;

    setUp(() async {
      _counter++;
      box = await Hive.openBox<Flashcard>('fc_box_$_counter');
      repo = FlashcardRepository();
      repo.attachBox(box);
    });

    tearDown(() async {
      await box.close();
      await Hive.deleteBoxFromDisk('fc_box_$_counter');
    });

    test('create stores a flashcard', () async {
      final result = await repo.create(_card());
      expect(result.isSuccess, isTrue);
      expect((await repo.getAll()).data!.length, 1);
    });

    test('getBySource filters by sourceId', () async {
      await repo.create(_card(id: 'fc1', sourceId: 's1'));
      await repo.create(_card(id: 'fc2', sourceId: 's2'));
      final result = await repo.getBySource('s1');
      expect(result.data!.length, 1);
      expect(result.data!.first.sourceId, 's1');
    });

    test('getByTopic filters by topicId', () async {
      await repo.create(_card(id: 'fc1', topicId: 't1'));
      await repo.create(_card(id: 'fc2', topicId: 't2'));
      final result = await repo.getByTopic('t2');
      expect(result.data!.length, 1);
    });

    test('getBySubject filters by subjectId', () async {
      await repo.create(_card(id: 'fc1', subjectId: 'sub1'));
      await repo.create(_card(id: 'fc2', subjectId: 'sub2'));
      final result = await repo.getBySubject('sub1');
      expect(result.data!.length, 1);
    });

    test('getDueForReview returns cards with null or past nextReview', () async {
      await repo.create(_card(id: 'fc1'));
      await repo.create(_card(id: 'fc2').copyWith(nextReview: DateTime(2099, 1, 1)));
      final result = await repo.getDueForReview(asOf: DateTime(2026, 8, 1));
      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 1);
      expect(result.data!.first.id, 'fc1');
    });

    test('getDueCount counts due cards for a subject', () async {
      await repo.create(_card(id: 'fc1', subjectId: 'sub1'));
      await repo.create(_card(id: 'fc2', subjectId: 'sub1').copyWith(nextReview: DateTime(2099, 1, 1)));
      final result = await repo.getDueCount('sub1', asOf: DateTime(2026, 8, 1));
      expect(result.isSuccess, isTrue);
      expect(result.data, 1);
    });
  });

  group('init', () {
    test('init opens the flashcards box', () async {
      final repo = FlashcardRepository();
      if (Hive.isBoxOpen(HiveBoxNames.flashcards)) {
        await Hive.box(HiveBoxNames.flashcards).close();
        await Hive.deleteBoxFromDisk(HiveBoxNames.flashcards);
      }
      final result = await repo.init();
      expect(result.isSuccess, isTrue);
      expect(repo.isOpen, isTrue);
    });
  });

  group('failure paths', () {
    test('getBySource without open box returns failure', () async {
      await Hive.close();
      final repo = FlashcardRepository();
      final result = await repo.getBySource('s1');
      expect(result.isFailure, isTrue);
    });
  });
}
