import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/features/subjects/data/adapters/topic_adapter.dart';

late String _hivePath;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('topic_adapter_test_');
    _hivePath = dir.path;
    Hive.init(_hivePath);
    Hive.registerAdapter(TopicAdapter());
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await Directory(_hivePath).delete(recursive: true);
  });

  group('TopicAdapter', () {
    test('typeId is 0', () => expect(TopicAdapter().typeId, 0));

    test('hashCode and equality', () {
      expect(TopicAdapter().hashCode, TopicAdapter().hashCode);
      expect(TopicAdapter() == TopicAdapter(), isTrue);
      expect(TopicAdapter() == Object(), isFalse);
    });

    test('write/read round-trip', () async {
      final box = await Hive.openBox<Topic>('topics_rt');
      final topic = Topic(
        id: 't1',
        subjectId: 'sub1',
        title: 'Cell Biology',
        description: 'Study of cells',
        parentId: 't0',
        sortOrder: 2,
        syllabusText: 'Chapter 1',
        childTopicIds: ['t2', 't3'],
      );
      await box.put('t1', topic);
      final restored = box.get('t1')!;
      expect(restored.id, 't1');
      expect(restored.subjectId, 'sub1');
      expect(restored.title, 'Cell Biology');
      expect(restored.parentId, 't0');
      expect(restored.sortOrder, 2);
      expect(restored.syllabusText, 'Chapter 1');
      expect(restored.childTopicIds, ['t2', 't3']);
      await box.close();
    });

    test('write/read with defaults', () async {
      final box = await Hive.openBox<Topic>('topics_def');
      final topic = Topic(
        id: 't2',
        subjectId: 'sub1',
        title: 'Genetics',
        description: 'DNA',
        syllabusText: 'Chapter 2',
      );
      await box.put('t2', topic);
      final restored = box.get('t2')!;
      expect(restored.title, 'Genetics');
      expect(restored.sortOrder, 0);
      expect(restored.childTopicIds, isEmpty);
      expect(restored.parentId, isNull);
      await box.close();
    });
  });
}
