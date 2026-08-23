import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/lessons/data/adapters/lesson_adapter.dart';
import 'package:studyking/features/lessons/data/adapters/lesson_block_adapter.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';

class _LessonBlockTypeAdapter extends TypeAdapter<LessonBlockType> {
  @override
  final int typeId = 202;
  @override
  LessonBlockType read(BinaryReader r) => LessonBlockType.values[r.readByte()];
  @override
  void write(BinaryWriter w, LessonBlockType v) => w.writeByte(v.index);
}

class _SlideTypeAdapter extends TypeAdapter<SlideType> {
  @override
  final int typeId = 203;
  @override
  SlideType read(BinaryReader r) => SlideType.values[r.readByte()];
  @override
  void write(BinaryWriter w, SlideType v) => w.writeByte(v.index);
}

class _GeneratedByAdapter extends TypeAdapter<GeneratedBy> {
  @override
  final int typeId = 201;
  @override
  GeneratedBy read(BinaryReader r) => GeneratedBy.values[r.readByte()];
  @override
  void write(BinaryWriter w, GeneratedBy v) => w.writeByte(v.index);
}

late String _hivePath;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('lesson_adapter_test_');
    _hivePath = dir.path;
    Hive.init(_hivePath);
    Hive.registerAdapter(_LessonBlockTypeAdapter());
    Hive.registerAdapter(_SlideTypeAdapter());
    Hive.registerAdapter(_GeneratedByAdapter());
    Hive.registerAdapter(LessonBlockAdapter());
    Hive.registerAdapter(LessonAdapter());
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await Directory(_hivePath).delete(recursive: true);
  });

  group('LessonAdapter', () {
    test('typeId is 7', () => expect(LessonAdapter().typeId, 7));

    test('hashCode and equality', () {
      expect(LessonAdapter().hashCode, LessonAdapter().hashCode);
      expect(LessonAdapter() == LessonAdapter(), isTrue);
      expect(LessonAdapter() == Object(), isFalse);
    });

    test('write/read round-trip with blocks', () async {
      final box = await Hive.openBox<Lesson>('lessons_rt');
      final created = DateTime(2026, 7, 23);
      final lesson = Lesson(
        id: 'l1',
        subjectId: 'sub1',
        title: 'Intro to Cells',
        topicId: 't1',
        blocks: [
          LessonBlock(
            id: 'b1',
            subjectId: 'sub1',
            lessonId: 'l1',
            type: LessonBlockType.text,
            content: 'Welcome',
          ),
        ],
        difficulty: 2,
        generatedBy: GeneratedBy.ai,
        createdAt: created,
        markscheme: 'rubric',
        sessionId: 'sess1',
      );
      await box.put('l1', lesson);
      final restored = box.get('l1')!;
      expect(restored.id, 'l1');
      expect(restored.title, 'Intro to Cells');
      expect(restored.difficulty, 2);
      expect(restored.generatedBy, GeneratedBy.ai);
      expect(restored.blocks.length, 1);
      expect(restored.blocks.first.content, 'Welcome');
      expect(restored.markscheme, 'rubric');
      expect(restored.sessionId, 'sess1');
      await box.close();
    });

    test('write/read with default generatedBy', () async {
      final box = await Hive.openBox<Lesson>('lessons_def');
      final created = DateTime(2026, 7, 23);
      final lesson = Lesson(
        id: 'l2',
        subjectId: 'sub1',
        title: 'Basics',
        topicId: 't1',
        createdAt: created,
      );
      await box.put('l2', lesson);
      final restored = box.get('l2')!;
      expect(restored.generatedBy, GeneratedBy.manual);
      expect(restored.blocks, isEmpty);
      expect(restored.markscheme, isNull);
      await box.close();
    });
  });
}
