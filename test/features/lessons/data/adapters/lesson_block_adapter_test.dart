import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/lessons/data/adapters/lesson_block_adapter.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';

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

late String _hivePath;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('lb_adapter_test_');
    _hivePath = dir.path;
    Hive.init(_hivePath);
    Hive.registerAdapter(_LessonBlockTypeAdapter());
    Hive.registerAdapter(_SlideTypeAdapter());
    Hive.registerAdapter(LessonBlockAdapter());
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await Directory(_hivePath).delete(recursive: true);
  });

  group('LessonBlockAdapter', () {
    test('typeId is 6', () => expect(LessonBlockAdapter().typeId, 6));

    test('hashCode and equality', () {
      expect(LessonBlockAdapter().hashCode, LessonBlockAdapter().hashCode);
      expect(LessonBlockAdapter() == LessonBlockAdapter(), isTrue);
      expect(LessonBlockAdapter() == Object(), isFalse);
    });

    test('write/read round-trip', () async {
      final box = await Hive.openBox<LessonBlock>('lb_rt');
      final block = LessonBlock(
        id: 'b1',
        subjectId: 'sub1',
        lessonId: 'l1',
        type: LessonBlockType.exercise,
        content: 'Solve 2+2',
        order: 2,
        answerKey: '4',
        chapterTitle: 'Chapter 1',
        sectionTitle: 'Section A',
        chapterOrder: 1,
        sectionOrder: 3,
        slideType: SlideType.formula,
      );
      await box.put('b1', block);
      final restored = box.get('b1')!;
      expect(restored.id, 'b1');
      expect(restored.type, LessonBlockType.exercise);
      expect(restored.content, 'Solve 2+2');
      expect(restored.order, 2);
      expect(restored.answerKey, '4');
      expect(restored.chapterTitle, 'Chapter 1');
      expect(restored.slideType, SlideType.formula);
      await box.close();
    });

    test('write/read with defaults', () async {
      final box = await Hive.openBox<LessonBlock>('lb_def');
      final block = LessonBlock(
        id: 'b2',
        subjectId: 'sub1',
        lessonId: 'l1',
        type: LessonBlockType.text,
        content: 'Intro',
      );
      await box.put('b2', block);
      final restored = box.get('b2')!;
      expect(restored.type, LessonBlockType.text);
      expect(restored.order, 0);
      expect(restored.answerKey, '');
      expect(restored.slideType, isNull);
      await box.close();
    });
  });
}
