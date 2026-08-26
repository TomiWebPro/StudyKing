import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/models/question_model.dart';

/// Minimal Hive TypeAdapter for Question (no .g.dart file exists for it).
class _TestQuestionAdapter extends TypeAdapter<Question> {
  @override
  final int typeId = 2;

  @override
  Question read(BinaryReader reader) {
    final raw = reader.read() as Map;
    return Question.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  void write(BinaryWriter writer, Question obj) {
    writer.write(obj.toJson());
  }
}

Question _createTestQuestion({
  String id = 'q-1',
  String text = 'Test question?',
}) {
  return Question(
    id: id,
    text: text,
    type: QuestionType.singleChoice,
    difficulty: 1,
    subjectId: 'subject-1',
    topicId: 'topic-1',
    createdAt: DateTime(2026, 5, 12),
    updatedAt: DateTime(2026, 5, 12),
  );
}

void main() {
  group('QuestionRepository.init() (real Hive)', () {
    late String hivePath;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final dir = await Directory.systemTemp.createTemp('hive_question_test_');
      hivePath = dir.path;
      Hive.init(hivePath);
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(_TestQuestionAdapter());
      }
    });

    tearDown(() async {
      await Hive.close();
      if (hivePath.isNotEmpty) {
        await Directory(hivePath).delete(recursive: true);
      }
    });

    test('initializes repository and opens the box', () async {
      final repo = QuestionRepository();
      await repo.init();
      expect(repo, isNotNull);
    });

    test('can create and retrieve after init', () async {
      final repo = QuestionRepository();
      await repo.init();
      final result = await repo.create(_createTestQuestion(id: 'init-q'));
      expect(result.isSuccess, isTrue);
      final stored = await repo.get('init-q');
      expect(stored.data, isNotNull);
      expect(stored.data!.id, 'init-q');
    });

    test('can getAll after init', () async {
      final repo = QuestionRepository();
      await repo.init();
      await repo.create(_createTestQuestion(id: 'a'));
      await repo.create(_createTestQuestion(id: 'b'));
      final all = await repo.getAll();
      expect(all.data!.length, 2);
    });

    group('variant family methods', () {
      test('getByVariantGroupId returns family members only', () async {
        final repo = QuestionRepository();
        await repo.init();
        final base = _createTestQuestion(id: 'base')
            .copyWith(variantGroupId: 'g1', variantIds: ['v1']);
        final variant = _createTestQuestion(id: 'v1')
            .copyWith(variantGroupId: 'g1', variantIds: ['base']);
        final other = _createTestQuestion(id: 'other')
            .copyWith(variantGroupId: 'g2');

        await repo.create(base);
        await repo.create(variant);
        await repo.create(other);

        final result = await repo.getByVariantGroupId('g1');
        expect(result.isSuccess, isTrue);
        expect(result.data!.map((q) => q.id).toList(), containsAll(['base', 'v1']));
        expect(result.data!.map((q) => q.id).toList(), isNot(contains('other')));
      });

      test('getByVariantGroupId returns empty for blank id', () async {
        final repo = QuestionRepository();
        await repo.init();
        final result = await repo.getByVariantGroupId('');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('linkVariant cross-links base and variant', () async {
        final repo = QuestionRepository();
        await repo.init();
        final base = _createTestQuestion(id: 'base');
        final variant = _createTestQuestion(id: 'v1');
        await repo.create(base);
        await repo.create(variant);

        final linkResult = await repo.linkVariant(
          baseId: 'base',
          variantId: 'v1',
          groupId: 'g-new',
        );
        expect(linkResult.isSuccess, isTrue);

        final updatedBase = (await repo.get('base')).data!;
        final updatedVariant = (await repo.get('v1')).data!;
        expect(updatedBase.variantIds, contains('v1'));
        expect(updatedVariant.variantGroupId, 'g-new');
        expect(updatedVariant.variantIds, contains('base'));
      });

      test('linkVariant rejects self-link', () async {
        final repo = QuestionRepository();
        await repo.init();
        await repo.create(_createTestQuestion(id: 'x'));
        final result = await repo.linkVariant(
          baseId: 'x',
          variantId: 'x',
          groupId: 'g',
        );
        expect(result.isFailure, isTrue);
      });

      test('getVariantFamily returns base + linked variant', () async {
        final repo = QuestionRepository();
        await repo.init();
        final base = _createTestQuestion(id: 'base')
            .copyWith(variantGroupId: 'g1', variantIds: ['v1']);
        final variant = _createTestQuestion(id: 'v1')
            .copyWith(variantGroupId: 'g1', variantIds: ['base']);
        await repo.create(base);
        await repo.create(variant);

        final result = await repo.getVariantFamily('base');
        expect(result.isSuccess, isTrue);
        expect(result.data!.length, 2);
      });
    });
  });
}
