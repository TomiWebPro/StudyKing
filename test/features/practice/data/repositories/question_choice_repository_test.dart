import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/practice/data/repositories/question_choice_repository.dart';
import 'package:studyking/features/practice/data/models/answer_model.dart';

class _MockQuestionChoiceRepository extends QuestionChoiceRepository {
  final Map<String, QuestionChoice> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> create(QuestionChoice choice) async {
    _storage[choice.id] = choice;
    return Result.success(null);
  }

  @override
  Future<QuestionChoice?> get(String id) async {
    return _storage[id];
  }

  @override
  Future<Result<List<QuestionChoice>>> getByQuestion(String questionId) async {
    return Result.success(_storage.values.where((a) => a.questionId == questionId).toList());
  }
}

void main() {
  group('QuestionChoiceRepository', () {
    late _MockQuestionChoiceRepository repository;

    setUp(() {
      repository = _MockQuestionChoiceRepository();
    });

    group('create', () {
      test('stores a question choice', () async {
        final choice = QuestionChoice(id: 'a1', questionId: 'q1', text: 'Paris', isCorrect: true);
        await repository.create(choice);
        final stored = await repository.get('a1');
        expect(stored?.text, 'Paris');
      });
    });

    group('get', () {
      test('returns null for non-existent', () async {
        expect(await repository.get('none'), isNull);
      });

      test('returns stored choice', () async {
        final choice = QuestionChoice(id: 'a1', questionId: 'q1', text: 'Paris', isCorrect: true);
        await repository.create(choice);
        expect(await repository.get('a1'), isNotNull);
      });
    });

    group('getByQuestion', () {
      test('returns choices for question', () async {
        await repository.create(QuestionChoice(id: 'a1', questionId: 'q1', text: 'A', isCorrect: true));
        await repository.create(QuestionChoice(id: 'a2', questionId: 'q1', text: 'B', isCorrect: false));
        await repository.create(QuestionChoice(id: 'a3', questionId: 'q2', text: 'C', isCorrect: true));
        final result = await repository.getByQuestion('q1');
        expect(result.isSuccess, isTrue);
        expect(result.data!.length, 2);
      });

      test('returns empty list when no choices for question', () async {
        final result = await repository.getByQuestion('none');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });
  });

  group('QuestionChoiceRepository (init with real Hive)', () {
    late QuestionChoiceRepository repository;
    late String hivePath;

    setUpAll(() {
      Hive.registerAdapter(_TestQuestionChoiceAdapter());
    });

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('qc_repo_test_');
      hivePath = dir.path;
      Hive.init(hivePath);
      repository = QuestionChoiceRepository();
      await repository.init();
    });

    tearDown(() async {
      await repository.box.close();
      await Hive.deleteBoxFromDisk('answers');
    });

    test('init opens box and supports CRUD', () async {
      final choice = QuestionChoice(id: 'hive-1', questionId: 'q1', text: 'Paris', isCorrect: true);
      await repository.create(choice);
      final stored = await repository.get('hive-1');
      expect(stored, isNotNull);
      expect(stored!.text, 'Paris');
    });

    test('getByQuestion works after init', () async {
      await repository.create(QuestionChoice(id: 'c1', questionId: 'q1', text: 'A', isCorrect: true));
      await repository.create(QuestionChoice(id: 'c2', questionId: 'q1', text: 'B', isCorrect: false));
      final result = await repository.getByQuestion('q1');
      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(2));
    });
  });
}

class _TestQuestionChoiceAdapter extends TypeAdapter<QuestionChoice> {
  @override
  final int typeId = 3;

  @override
  QuestionChoice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuestionChoice(
      id: fields[0] as String,
      questionId: fields[1] as String,
      text: fields[2] as String,
      isCorrect: fields[3] as bool,
      explanation: fields[4] as String? ?? '',
      variantIds: (fields[5] as List?)?.cast<String>() ?? [],
      confidenceScore: (fields[6] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  void write(BinaryWriter writer, QuestionChoice obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.questionId)
      ..writeByte(2)
      ..write(obj.text)
      ..writeByte(3)
      ..write(obj.isCorrect)
      ..writeByte(4)
      ..write(obj.explanation)
      ..writeByte(5)
      ..write(obj.variantIds)
      ..writeByte(6)
      ..write(obj.confidenceScore);
  }
}
