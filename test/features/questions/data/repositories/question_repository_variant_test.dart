import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';

/// In-memory fake `Box<Question>` supporting the operations the variant family
/// repository methods rely on: [values], [get], and [put].
class _FakeQuestionBox implements Box<Question> {
  final Map<dynamic, Question> _storage = {};

  @override
  Iterable<Question> get values => _storage.values;

  @override
  Question? get(dynamic key, {Question? defaultValue}) =>
      _storage[key.toString()] ?? defaultValue;

  @override
  Future<void> put(dynamic key, Question value) async {
    _storage[key.toString()] = value;
  }

  @override
  Future<void> delete(dynamic key) async => _storage.remove(key.toString());

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

Question _q(
  String id, {
  String variantGroupId = '',
  List<String> variantIds = const [],
}) {
  return Question(
    id: id,
    text: 'Q $id',
    type: QuestionType.singleChoice,
    subjectId: 's',
    topicId: 't',
    variantGroupId: variantGroupId,
    variantIds: variantIds,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('QuestionRepository variant family methods', () {
    late QuestionRepository repository;
    late _FakeQuestionBox fakeBox;

    setUp(() {
      repository = QuestionRepository();
      fakeBox = _FakeQuestionBox();
      repository.attachBox(fakeBox);
    });

    test('getByVariantGroupId returns only members of the group', () async {
      await repository.create(_q('base', variantGroupId: 'g1'));
      await repository.create(_q('v1', variantGroupId: 'g1'));
      await repository.create(_q('v2', variantGroupId: 'g1'));
      await repository.create(_q('other', variantGroupId: 'g2'));

      final result = await repository.getByVariantGroupId('g1');

      expect(result.isSuccess, isTrue);
      expect(result.data!.map((q) => q.id).toList()..sort(),
          ['base', 'v1', 'v2']);
    });

    test('getByVariantGroupId returns empty for unknown/empty group', () async {
      expect((await repository.getByVariantGroupId('')).data, isEmpty);
      expect((await repository.getByVariantGroupId('nope')).data, isEmpty);
    });

    test('getVariantFamily returns base plus linked variants', () async {
      await repository.create(
        _q('base', variantGroupId: 'g1', variantIds: ['v1']),
      );
      await repository.create(_q('v1', variantGroupId: 'g1'));

      final result = await repository.getVariantFamily('base');

      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 2);
      expect(result.data!.map((q) => q.id), contains('base'));
      expect(result.data!.map((q) => q.id), contains('v1'));
    });

    test('getVariantFamily fails when base is missing', () async {
      final result = await repository.getVariantFamily('ghost');
      expect(result.isFailure, isTrue);
    });

    test('linkVariant cross-links base and variant', () async {
      await repository.create(_q('base'));
      await repository.create(_q('v1'));

      final linkResult = await repository.linkVariant(
        baseId: 'base',
        variantId: 'v1',
        groupId: 'g-new',
      );
      expect(linkResult.isSuccess, isTrue);

      final base = (await repository.get('base')).data!;
      final variant = (await repository.get('v1')).data!;

      expect(base.variantIds, contains('v1'));
      expect(base.variantGroupId, 'g-new');
      expect(variant.variantGroupId, 'g-new');
      expect(variant.variantIds, contains('base'));
    });

    test('linkVariant rejects linking a question to itself', () async {
      await repository.create(_q('base'));
      final result = await repository.linkVariant(
        baseId: 'base',
        variantId: 'base',
        groupId: 'g',
      );
      expect(result.isFailure, isTrue);
    });

    test('linkVariant fails when a participant is missing', () async {
      await repository.create(_q('base'));
      final result = await repository.linkVariant(
        baseId: 'base',
        variantId: 'missing',
        groupId: 'g',
      );
      expect(result.isFailure, isTrue);
    });

    test('getByVariantGroupId fails when box is closed', () async {
      final closed = QuestionRepository()
        ..attachBox(_ClosedBox());
      final result = await closed.getByVariantGroupId('g1');
      expect(result.isFailure, isTrue);
    });
  });
}

class _ClosedBox implements Box<Question> {
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
  Iterable<Question> get values => const [];

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
