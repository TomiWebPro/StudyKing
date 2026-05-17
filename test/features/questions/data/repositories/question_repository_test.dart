import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/questions/data/models/markscheme_model.dart';
import 'package:studyking/core/data/enums.dart';

/// Fake Box`<Question>` with in-memory storage for happy-path testing.
class _FakeQuestionBox implements Box<Question> {
  final Map<dynamic, Question> _storage = {};

  @override
  Iterable<Question> get values => _storage.values;

  @override
  Question? get(dynamic key, {Question? defaultValue}) =>
      _storage[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, Question value) async {
    _storage[key.toString()] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _storage.remove(key.toString());
  }

  @override
  Future<int> clear() async {
    final count = _storage.length;
    _storage.clear();
    return count;
  }

  @override
  bool get isOpen => true;

  @override
  String get name => 'questions';

  @override
  int get length => _storage.length;

  @override
  bool get isNotEmpty => _storage.isNotEmpty;

  @override
  bool get isEmpty => _storage.isEmpty;

  @override
  bool containsKey(dynamic key) => _storage.containsKey(key.toString());

  @override
  Stream<BoxEvent> watch({dynamic key}) => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Box that reports isOpen == false to exercise the early-return failure paths.
class _UnopenableBox implements Box<Question> {
  @override
  bool get isOpen => false;

  @override
  String get name => 'questions';

  @override
  int get length => 0;

  @override
  bool get isNotEmpty => false;

  @override
  bool get isEmpty => true;

  @override
  Iterable<Question> get values => [];

  @override
  Question? get(dynamic key, {Question? defaultValue}) => defaultValue;

  @override
  Future<void> put(dynamic key, Question value) async {}

  @override
  Future<void> delete(dynamic key) async {}

  @override
  Future<int> clear() async => 0;

  @override
  bool containsKey(dynamic key) => false;

  @override
  Stream<BoxEvent> watch({dynamic key}) => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Box that throws on every read/write operation to exercise catch blocks.
class _ThrowingBox implements Box<Question> {
  @override
  bool get isOpen => true;

  @override
  String get name => 'questions';

  @override
  int get length => 0;

  @override
  bool get isNotEmpty => false;

  @override
  bool get isEmpty => true;

  @override
  Iterable<Question> get values => throw Exception('Box values error');

  @override
  Question? get(dynamic key, {Question? defaultValue}) =>
      throw Exception('Box get error');

  @override
  Future<void> put(dynamic key, Question value) async =>
      throw Exception('Box put error');

  @override
  Future<void> delete(dynamic key) async =>
      throw Exception('Box delete error');

  @override
  Future<int> clear() async => throw Exception('Box clear error');

  @override
  bool containsKey(dynamic key) => throw Exception('Box containsKey error');

  @override
  Stream<BoxEvent> watch({dynamic key}) => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Question createTestQuestion({
  String id = 'q-1',
  String text = 'Test question?',
  QuestionType type = QuestionType.singleChoice,
  int difficulty = 1,
  String subjectId = 'subject-1',
  String topicId = 'topic-1',
  Markscheme? markscheme,
}) {
  return Question(
    id: id,
    text: text,
    type: type,
    difficulty: difficulty,
    subjectId: subjectId,
    topicId: topicId,
    markscheme: markscheme,
    createdAt: DateTime(2026, 5, 12),
    updatedAt: DateTime(2026, 5, 12),
  );
}

Markscheme createTestMarkscheme({String answer = 'Paris'}) {
  return Markscheme(correctAnswer: answer);
}

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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ===========================================================================
  // Unit tests — real QuestionRepository wired to a fake Hive box
  // ===========================================================================
  group('QuestionRepository (attached to fake box)', () {
    late QuestionRepository repository;
    late _FakeQuestionBox fakeBox;

    setUp(() {
      repository = QuestionRepository();
      fakeBox = _FakeQuestionBox();
      repository.attachBox(fakeBox);
    });

    // -----------------------------------------------------------------------
    // init (with a box already attached, init is a no-op)
    // -----------------------------------------------------------------------
    // init() calls Hive.openBox which requires Hive to be initialized.
    // Error handling is tested via the real-Hive init group below.

    // -----------------------------------------------------------------------
    // create
    // -----------------------------------------------------------------------
    group('create', () {
      test('stores a question and returns success', () async {
        final question = createTestQuestion();
        final result = await repository.create(question);
        expect(result.isSuccess, isTrue);
        final stored = await repository.get('q-1');
        expect(stored, isNotNull);
        expect(stored!.id, 'q-1');
      });

      test('stores question with all fields', () async {
        final ms = createTestMarkscheme();
        final question = createTestQuestion(
          id: 'full',
          text: 'Full question?',
          type: QuestionType.multiChoice,
          difficulty: 3,
          subjectId: 'sub-99',
          topicId: 'topic-99',
          markscheme: ms,
        );
        final result = await repository.create(question);
        expect(result.isSuccess, isTrue);
        final stored = await repository.get('full');
        expect(stored!.text, 'Full question?');
        expect(stored.type, QuestionType.multiChoice);
        expect(stored.difficulty, 3);
        expect(stored.subjectId, 'sub-99');
        expect(stored.topicId, 'topic-99');
        expect(stored.markscheme?.correctAnswer, 'Paris');
      });

      test('overwrites existing question with same id', () async {
        await repository.create(
          createTestQuestion(id: 'dup', text: 'First'),
        );
        await repository.create(
          createTestQuestion(id: 'dup', text: 'Second'),
        );
        final stored = await repository.get('dup');
        expect(stored!.text, 'Second');
      });

      test('returns failure when box.put throws', () async {
        final repo = QuestionRepository();
        repo.attachBox(_ThrowingBox());
        final result = await repo.create(createTestQuestion());
        expect(result.isFailure, isTrue);
        expect(result.error, 'Exception: Box put error');
      });
    });

    // -----------------------------------------------------------------------
    // get (inherited from Repository)
    // -----------------------------------------------------------------------
    group('get', () {
      test('returns question by id', () async {
        await repository.create(createTestQuestion());
        final stored = await repository.get('q-1');
        expect(stored, isNotNull);
        expect(stored!.text, 'Test question?');
      });

      test('returns null for missing question', () async {
        expect(await repository.get('not-found'), isNull);
      });

      test('returns null when box is empty', () async {
        expect(await repository.get('any'), isNull);
      });
    });

    // -----------------------------------------------------------------------
    // getAll (inherited from Repository)
    // -----------------------------------------------------------------------
    group('getAll', () {
      test('returns all questions', () async {
        await repository.create(createTestQuestion(id: 'q1'));
        await repository.create(createTestQuestion(id: 'q2'));
        final questions = await repository.getAll();
        expect(questions.length, 2);
      });

      test('returns empty when no questions', () async {
        expect(await repository.getAll(), isEmpty);
      });

      test('preserves insertion order', () async {
        await repository.create(createTestQuestion(id: 'a'));
        await repository.create(createTestQuestion(id: 'b'));
        await repository.create(createTestQuestion(id: 'c'));
        final all = await repository.getAll();
        expect(all.map((q) => q.id).toList(), ['a', 'b', 'c']);
      });
    });

    // -----------------------------------------------------------------------
    // getByTopic
    // -----------------------------------------------------------------------
    group('getByTopic', () {
      test('returns questions for topic', () async {
        await repository.create(createTestQuestion(id: 'q1', topicId: 't1'));
        await repository.create(createTestQuestion(id: 'q2', topicId: 't1'));
        await repository.create(createTestQuestion(id: 'q3', topicId: 't2'));
        final result = await repository.getByTopic('t1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 2);
        expect(result.data?.every((q) => q.topicId == 't1'), isTrue);
      });

      test('returns empty for non-existent topic', () async {
        final result = await repository.getByTopic('none');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('returns empty when no questions exist', () async {
        final result = await repository.getByTopic('t1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('returns failure when box is not open', () async {
        final repo = QuestionRepository();
        repo.attachBox(_UnopenableBox());
        final result = await repo.getByTopic('t1');
        expect(result.isFailure, isTrue);
        expect(result.error, 'Question_box_not_open');
      });

      test('returns failure when box.values throws', () async {
        final repo = QuestionRepository();
        repo.attachBox(_ThrowingBox());
        final result = await repo.getByTopic('t1');
        expect(result.isFailure, isTrue);
        expect(result.error, 'Exception: Box values error');
      });
    });

    // -----------------------------------------------------------------------
    // getBySubject
    // -----------------------------------------------------------------------
    group('getBySubject', () {
      test('returns questions for subject', () async {
        await repository.create(createTestQuestion(id: 'q1', subjectId: 's1'));
        await repository.create(createTestQuestion(id: 'q2', subjectId: 's1'));
        await repository.create(createTestQuestion(id: 'q3', subjectId: 's2'));
        final result = await repository.getBySubject('s1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 2);
        expect(result.data?.every((q) => q.subjectId == 's1'), isTrue);
      });

      test('returns empty for non-existent subject', () async {
        final result = await repository.getBySubject('none');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('returns empty when no questions exist', () async {
        final result = await repository.getBySubject('s1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('returns failure when box is not open', () async {
        final repo = QuestionRepository();
        repo.attachBox(_UnopenableBox());
        final result = await repo.getBySubject('s1');
        expect(result.isFailure, isTrue);
        expect(result.error, 'Question_bank_not_open');
      });

      test('returns failure when box.values throws', () async {
        final repo = QuestionRepository();
        repo.attachBox(_ThrowingBox());
        final result = await repo.getBySubject('s1');
        expect(result.isFailure, isTrue);
        expect(result.error, 'Exception: Box values error');
      });
    });

    // -----------------------------------------------------------------------
    // getBySubjectAndTopic
    // -----------------------------------------------------------------------
    group('getBySubjectAndTopic', () {
      test('returns filtered questions', () async {
        await repository.create(
          createTestQuestion(id: 'q1', subjectId: 's1', topicId: 't1'),
        );
        await repository.create(
          createTestQuestion(id: 'q2', subjectId: 's1', topicId: 't2'),
        );
        await repository.create(
          createTestQuestion(id: 'q3', subjectId: 's2', topicId: 't1'),
        );
        final result = await repository.getBySubjectAndTopic('s1', 't1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 1);
        expect(result.data?.first.id, 'q1');
      });

      test('returns empty when no match', () async {
        final result = await repository.getBySubjectAndTopic('s1', 't1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('prunes by topic after subject filter', () async {
        await repository.create(
          createTestQuestion(id: 'q1', subjectId: 's1', topicId: 't1'),
        );
        await repository.create(
          createTestQuestion(id: 'q2', subjectId: 's1', topicId: 't2'),
        );
        final result = await repository.getBySubjectAndTopic('s1', 't2');
        expect(result.data?.length, 1);
        expect(result.data?.first.id, 'q2');
      });

      test('returns failure when box is not open', () async {
        final repo = QuestionRepository();
        repo.attachBox(_UnopenableBox());
        final result = await repo.getBySubjectAndTopic('s1', 't1');
        expect(result.isFailure, isTrue);
        expect(result.error, 'Question_bank_not_open');
      });

      test('returns failure when box.values throws', () async {
        final repo = QuestionRepository();
        repo.attachBox(_ThrowingBox());
        final result = await repo.getBySubjectAndTopic('s1', 't1');
        expect(result.isFailure, isTrue);
        expect(result.error, 'Exception: Box values error');
      });
    });

    // -----------------------------------------------------------------------
    // getByType
    // -----------------------------------------------------------------------
    group('getByType', () {
      test('returns questions of specific type', () async {
        await repository.create(
          createTestQuestion(id: 'q1', type: QuestionType.singleChoice),
        );
        await repository.create(
          createTestQuestion(id: 'q2', type: QuestionType.multiChoice),
        );
        await repository.create(
          createTestQuestion(id: 'q3', type: QuestionType.singleChoice),
        );
        final result = await repository.getByType(QuestionType.singleChoice);
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 2);
        expect(result.data?.every((q) => q.type == QuestionType.singleChoice),
            isTrue);
      });

      test('returns empty for type with no questions', () async {
        final result = await repository.getByType(QuestionType.essay);
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('returns failure when box is not open', () async {
        final repo = QuestionRepository();
        repo.attachBox(_UnopenableBox());
        final result = await repo.getByType(QuestionType.singleChoice);
        expect(result.isFailure, isTrue);
        expect(result.error, 'Question_bank_not_open');
      });

      test('returns failure when box.values throws', () async {
        final repo = QuestionRepository();
        repo.attachBox(_ThrowingBox());
        final result = await repo.getByType(QuestionType.singleChoice);
        expect(result.isFailure, isTrue);
        expect(result.error, 'Exception: Box values error');
      });
    });

    // -----------------------------------------------------------------------
    // getBySubjectAndType
    // -----------------------------------------------------------------------
    group('getBySubjectAndType', () {
      test('returns filtered questions by subject and type', () async {
        await repository.create(
          createTestQuestion(
            id: 'q1',
            subjectId: 's1',
            type: QuestionType.singleChoice,
          ),
        );
        await repository.create(
          createTestQuestion(
            id: 'q2',
            subjectId: 's1',
            type: QuestionType.multiChoice,
          ),
        );
        await repository.create(
          createTestQuestion(
            id: 'q3',
            subjectId: 's2',
            type: QuestionType.singleChoice,
          ),
        );
        final result =
            await repository.getBySubjectAndType('s1', QuestionType.singleChoice);
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 1);
        expect(result.data?.first.id, 'q1');
      });

      test('returns empty when no match', () async {
        final result =
            await repository.getBySubjectAndType('s1', QuestionType.essay);
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('returns failure when box is not open', () async {
        final repo = QuestionRepository();
        repo.attachBox(_UnopenableBox());
        final result =
            await repo.getBySubjectAndType('s1', QuestionType.singleChoice);
        expect(result.isFailure, isTrue);
        expect(result.error, 'Question_bank_not_open');
      });

      test('returns failure when box.values throws', () async {
        final repo = QuestionRepository();
        repo.attachBox(_ThrowingBox());
        final result =
            await repo.getBySubjectAndType('s1', QuestionType.singleChoice);
        expect(result.isFailure, isTrue);
        expect(result.error, 'Exception: Box values error');
      });
    });

    // -----------------------------------------------------------------------
    // getQuestionsWithMarkschemes
    // -----------------------------------------------------------------------
    group('getQuestionsWithMarkschemes', () {
      test('returns questions with markscheme for subject', () async {
        final ms = createTestMarkscheme();
        await repository.create(
          createTestQuestion(id: 'q1', subjectId: 's1', markscheme: ms),
        );
        await repository.create(
          createTestQuestion(id: 'q2', subjectId: 's1', markscheme: ms),
        );
        await repository.create(createTestQuestion(id: 'q3', subjectId: 's1'));
        final result = await repository.getQuestionsWithMarkschemes('s1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 2);
        expect(result.data?.length, 2);
      });

      test('each result has matching question and markscheme', () async {
        final ms = createTestMarkscheme(answer: 'Berlin');
        await repository.create(
          createTestQuestion(id: 'q1', subjectId: 's1', markscheme: ms),
        );
        final result = await repository.getQuestionsWithMarkschemes('s1');
        expect(result.data?.first.question.id, 'q1');
        expect(result.data?.first.markscheme.correctAnswer, 'Berlin');
      });

      test('returns failure when no questions with markscheme', () async {
        await repository.create(createTestQuestion(id: 'q1', subjectId: 's1'));
        final result = await repository.getQuestionsWithMarkschemes('s1');
        expect(result.isFailure, isTrue);
      });

      test('returns failure when no questions for subject', () async {
        final result = await repository.getQuestionsWithMarkschemes('empty');
        expect(result.isFailure, isTrue);
      });

      test('returns failure when box is not open', () async {
        final repo = QuestionRepository();
        repo.attachBox(_UnopenableBox());
        final result = await repo.getQuestionsWithMarkschemes('s1');
        expect(result.isFailure, isTrue);
        expect(result.error, 'Question_bank_not_open');
      });

      test('returns failure when box.values throws', () async {
        final repo = QuestionRepository();
        repo.attachBox(_ThrowingBox());
        final result = await repo.getQuestionsWithMarkschemes('s1');
        expect(result.isFailure, isTrue);
        expect(result.error, 'Exception: Box values error');
      });
    });

    // -----------------------------------------------------------------------
    // updateMarkscheme
    // -----------------------------------------------------------------------
    group('updateMarkscheme', () {
      test('updates markscheme for existing question', () async {
        await repository.create(createTestQuestion(id: 'q1'));
        final markscheme = createTestMarkscheme();
        final result = await repository.updateMarkscheme('q1', markscheme);
        expect(result.isSuccess, isTrue);
        final stored = await repository.get('q1');
        expect(stored!.markscheme?.correctAnswer, 'Paris');
      });

      test('replaces existing markscheme', () async {
        await repository.create(
          createTestQuestion(
            id: 'q1',
            markscheme: createTestMarkscheme(answer: 'London'),
          ),
        );
        final result =
            await repository.updateMarkscheme('q1', createTestMarkscheme(answer: 'Rome'));
        expect(result.isSuccess, isTrue);
        final stored = await repository.get('q1');
        expect(stored!.markscheme?.correctAnswer, 'Rome');
      });

      test('returns failure for non-existent question', () async {
        final result =
            await repository.updateMarkscheme('none', createTestMarkscheme());
        expect(result.isFailure, isTrue);
      });

      test('returns failure when box.get throws', () async {
        final repo = QuestionRepository();
        repo.attachBox(_ThrowingBox());
        final result =
            await repo.updateMarkscheme('q1', createTestMarkscheme());
        expect(result.isFailure, isTrue);
        expect(result.error, 'Exception: Box get error');
      });
    });

    // -----------------------------------------------------------------------
    // delete (inherited from Repository)
    // -----------------------------------------------------------------------
    group('delete', () {
      test('removes question', () async {
        await repository.create(createTestQuestion(id: 'q1'));
        await repository.delete('q1');
        expect(await repository.get('q1'), isNull);
      });

      test('does not throw for non-existent question', () async {
        await repository.delete('none');
      });

      test('delete does not affect other questions', () async {
        await repository.create(createTestQuestion(id: 'keep'));
        await repository.create(createTestQuestion(id: 'remove'));
        await repository.delete('remove');
        final all = await repository.getAll();
        expect(all.length, 1);
        expect(all.first.id, 'keep');
      });
    });
  });

  // ===========================================================================
  // QuestionWithMarkscheme data class
  // ===========================================================================
  group('QuestionWithMarkscheme', () {
    test('holds question and markscheme', () {
      final q = createTestQuestion(id: 'q1');
      final ms = createTestMarkscheme();
      final qwm = QuestionWithMarkscheme(question: q, markscheme: ms);
      expect(qwm.question.id, 'q1');
      expect(qwm.markscheme.correctAnswer, 'Paris');
    });

    test('stores references (same objects)', () {
      final q = createTestQuestion(id: 'q1');
      final ms = createTestMarkscheme();
      final qwm = QuestionWithMarkscheme(question: q, markscheme: ms);
      expect(identical(qwm.question, q), isTrue);
      expect(identical(qwm.markscheme, ms), isTrue);
    });

    test('supports multiple instances', () {
      final q1 = createTestQuestion(id: 'a', text: 'Q1');
      final q2 = createTestQuestion(id: 'b', text: 'Q2');
      final ms1 = createTestMarkscheme(answer: 'A');
      final ms2 = createTestMarkscheme(answer: 'B');
      final qwm1 = QuestionWithMarkscheme(question: q1, markscheme: ms1);
      final qwm2 = QuestionWithMarkscheme(question: q2, markscheme: ms2);
      expect(qwm1.question.id, 'a');
      expect(qwm2.question.id, 'b');
      expect(qwm1.markscheme.correctAnswer, 'A');
      expect(qwm2.markscheme.correctAnswer, 'B');
    });
  });

  // ===========================================================================
  // Hive integration test for init()
  // ===========================================================================
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
      final result = await repo.create(createTestQuestion(id: 'init-q'));
      expect(result.isSuccess, isTrue);
      final stored = await repo.get('init-q');
      expect(stored, isNotNull);
      expect(stored!.id, 'init-q');
    });

    test('can getAll after init', () async {
      final repo = QuestionRepository();
      await repo.init();
      await repo.create(createTestQuestion(id: 'a'));
      await repo.create(createTestQuestion(id: 'b'));
      final all = await repo.getAll();
      expect(all.length, 2);
    });
  });
}
