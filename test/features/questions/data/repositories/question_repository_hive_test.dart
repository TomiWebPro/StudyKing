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
  });
}
