import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/questions/data/adapters/question_adapter.dart';

class _QuestionTypeAdapter extends TypeAdapter<QuestionType> {
  @override
  final int typeId = 200;

  @override
  QuestionType read(BinaryReader reader) =>
      QuestionType.values[reader.readByte()];

  @override
  void write(BinaryWriter writer, QuestionType obj) => writer.writeByte(obj.index);
}

late String _hivePath;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('q_adapter_test_');
    _hivePath = dir.path;
    Hive.init(_hivePath);
    Hive.registerAdapter(_QuestionTypeAdapter());
    Hive.registerAdapter(QuestionAdapter());
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await Directory(_hivePath).delete(recursive: true);
  });

  group('QuestionAdapter', () {
    test('typeId is 2', () {
      expect(QuestionAdapter().typeId, 2);
    });

    test('hashCode and equality', () {
      final a1 = QuestionAdapter();
      final a2 = QuestionAdapter();
      expect(a1.hashCode, a2.hashCode);
      expect(a1 == a2, isTrue);
      expect(a1 == Object(), isFalse);
    });

    test('write/read round-trip', () async {
      final box = await Hive.openBox<Question>('questions_rt');
      final created = DateTime(2026, 5, 12);
      final question = Question(
        id: 'q1',
        text: 'What is 2+2?',
        type: QuestionType.singleChoice,
        difficulty: 3,
        subjectId: 'sub1',
        topicId: 'top1',
        variantIds: ['v1', 'v2'],
        sourceIds: ['s1'],
        options: ['3', '4'],
        allowedAnswerTypes: 'typed',
        model: 'gpt',
        topic: 'Arithmetic',
        tags: ['math'],
        explanation: '2+2=4',
        difficultyText: 'easy',
        createdAt: created,
        updatedAt: created,
      );

      await box.put('q1', question);
      final restored = box.get('q1')!;

      expect(restored.id, 'q1');
      expect(restored.text, 'What is 2+2?');
      expect(restored.type, QuestionType.singleChoice);
      expect(restored.difficulty, 3);
      expect(restored.subjectId, 'sub1');
      expect(restored.topicId, 'top1');
      expect(restored == restored, isTrue);
      expect(restored.variantIds, ['v1', 'v2']);
      expect(restored.sourceIds, ['s1']);
      expect(restored.options, ['3', '4']);
      expect(restored.allowedAnswerTypes, 'typed');
      expect(restored.model, 'gpt');
      expect(restored.topic, 'Arithmetic');
      expect(restored.tags, ['math']);
      expect(restored.explanation, '2+2=4');
      expect(restored.difficultyText, 'easy');
      expect(restored.createdAt, created);
      expect(restored.markscheme, isNull);
      await box.close();
    });

    test('write/read round-trip preserves srDataJson', () async {
      final box = await Hive.openBox<Question>('questions_srdata');
      final created = DateTime(2026, 5, 12);
      final srDataJson =
          '{"repetitions":3,"easeFactor":2.6,"previousInterval":4.0,"lastReview":1747008000000}';
      final question = Question(
        id: 'q3',
        text: 'What is 3+3?',
        type: QuestionType.singleChoice,
        difficulty: 2,
        subjectId: 'sub3',
        topicId: 'top3',
        createdAt: created,
        updatedAt: created,
        nextReview: created.add(const Duration(days: 4)),
        srDataJson: srDataJson,
      );

      await box.put('q3', question);
      final restored = box.get('q3')!;

      expect(restored.srDataJson, srDataJson);
      expect(restored.nextReview, created.add(const Duration(days: 4)));
      await box.close();
    });

    test('write/read round-trip keeps srDataJson null when unset', () async {
      final box = await Hive.openBox<Question>('questions_srdata_null');
      final created = DateTime(2026, 5, 12);
      final question = Question(
        id: 'q4',
        text: 'What is 4+4?',
        type: QuestionType.singleChoice,
        subjectId: 'sub4',
        topicId: 'top4',
        createdAt: created,
        updatedAt: created,
      );

      await box.put('q4', question);
      final restored = box.get('q4')!;

      expect(restored.srDataJson, isNull);
      await box.close();
    });

    test('write/read with minimal fields uses defaults', () async {
      final box = await Hive.openBox<Question>('questions_min');
      final created = DateTime(2026, 5, 12);
      final question = Question(
        id: 'q2',
        text: 'Explain photosynthesis.',
        type: QuestionType.essay,
        subjectId: 'sub2',
        topicId: 'top2',
        createdAt: created,
        updatedAt: created,
      );

      await box.put('q2', question);
      final restored = box.get('q2')!;

      expect(restored.id, 'q2');
      expect(restored.type, QuestionType.essay);
      expect(restored.difficulty, 1);
      expect(restored.variantIds, isEmpty);
      expect(restored.sourceIds, isEmpty);
      expect(restored.options, isEmpty);
      expect(restored.tags, isEmpty);
      await box.close();
    });

    test('write/read round-trip preserves validationStatus approved', () async {
      final box = await Hive.openBox<Question>('questions_val_approved');
      final created = DateTime(2026, 5, 12);
      final question = Question(
        id: 'q5',
        text: 'What is 2+2?',
        type: QuestionType.singleChoice,
        subjectId: 'sub5',
        topicId: 'top5',
        createdAt: created,
        updatedAt: created,
        validationStatus: ValidationStatus.approved,
      );

      await box.put('q5', question);
      final restored = box.get('q5')!;

      expect(restored.validationStatus, ValidationStatus.approved);
      await box.close();
    });

    test('write/read round-trip defaults to pending when field absent', () async {
      final box = await Hive.openBox<Question>('questions_val_default');
      final created = DateTime(2026, 5, 12);
      final question = Question(
        id: 'q6',
        text: 'Explain photosynthesis.',
        type: QuestionType.essay,
        subjectId: 'sub6',
        topicId: 'top6',
        createdAt: created,
        updatedAt: created,
      );

      await box.put('q6', question);
      final restored = box.get('q6')!;

      expect(restored.validationStatus, ValidationStatus.pending);
      await box.close();
    });
  });
}
