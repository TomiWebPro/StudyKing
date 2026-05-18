import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/questions/providers/question_providers.dart';

class _FakeQuestionRepo extends QuestionRepository {
  final List<Question> _questions;
  bool shouldThrow = false;

  _FakeQuestionRepo(this._questions);

  @override
  Future<void> init() async {
    if (shouldThrow) throw Exception('init error');
  }

  @override
  Future<Result<List<Question>>> getAll() async {
    if (shouldThrow) return Result.failure('storage error');
    return Result.success(_questions);
  }

  @override
  Future<Result<Question?>> get(String key) async {
    if (shouldThrow) return Result.failure('storage error');
    return Result.success(_questions.where((q) => q.id == key).firstOrNull);
  }

  @override
  Future<Result<void>> save(String key, Question item) async {
    if (shouldThrow) return Result.failure('storage error');
    return Result.success(null);
  }

  @override
  Future<Result<void>> delete(String key) async {
    if (shouldThrow) return Result.failure('storage error');
    _questions.removeWhere((q) => q.id == key);
    return Result.success(null);
  }

  @override
  Future<Result<void>> create(Question question) async {
    if (shouldThrow) return Result.failure('storage error');
    _questions.add(question);
    return Result.success(null);
  }
}

void main() {
  group('QuestionProviders', () {
    test('questionRepositoryProvider creates QuestionRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(questionRepositoryProvider);
      expect(repo, isA<QuestionRepository>());
    });

    test('questionRepositoryProvider can be overridden with fake repo', () {
      final testQuestion = Question(
        id: 'test-q',
        text: 'Test question?',
        type: QuestionType.singleChoice,
        subjectId: 'sub-1',
        topicId: 'topic-1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final fakeRepo = _FakeQuestionRepo([testQuestion]);

      final container = ProviderContainer(
        overrides: [
          questionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(questionRepositoryProvider);
      final result = repo.get('test-q');
      expect(result, isA<Future<Result<Question?>>>());
    });

    test('questionRepositoryProvider override returns seeded data through repo', () async {
      final questions = [
        Question(
          id: 'q1',
          text: 'What is 2+2?',
          type: QuestionType.singleChoice,
          subjectId: 'math',
          topicId: 'arithmetic',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        Question(
          id: 'q2',
          text: 'What is water?',
          type: QuestionType.typedAnswer,
          subjectId: 'chem',
          topicId: 'basics',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];
      final fakeRepo = _FakeQuestionRepo(questions);

      final container = ProviderContainer(
        overrides: [
          questionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(questionRepositoryProvider);
      final allResult = await repo.getAll();
      expect(allResult.isSuccess, isTrue);
      expect(allResult.data!.length, 2);
      expect(allResult.data![0].text, 'What is 2+2?');
      expect(allResult.data![1].text, 'What is water?');
    });

    test('questionRepositoryProvider is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final a = container.read(questionRepositoryProvider);
      final b = container.read(questionRepositoryProvider);
      expect(a, same(b));
    });

    test('handles error from repo getAll', () async {
      final fakeRepo = _FakeQuestionRepo([]);
      fakeRepo.shouldThrow = true;

      final container = ProviderContainer(
        overrides: [
          questionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(questionRepositoryProvider);
      final result = await repo.getAll();
      expect(result.isFailure, isTrue);
    });

    test('recovers after error', () async {
      final questions = [
        Question(
          id: 'q1',
          text: 'Recovered question?',
          type: QuestionType.singleChoice,
          subjectId: 'sub-1',
          topicId: 'topic-1',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];
      final fakeRepo = _FakeQuestionRepo(questions);

      fakeRepo.shouldThrow = true;
      final container1 = ProviderContainer(
        overrides: [
          questionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container1.dispose);

      var repo = container1.read(questionRepositoryProvider);
      var result = await repo.getAll();
      expect(result.isFailure, isTrue);

      fakeRepo.shouldThrow = false;
      result = await repo.getAll();
      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 1);
      expect(result.data![0].text, 'Recovered question?');
    });
  });
}
