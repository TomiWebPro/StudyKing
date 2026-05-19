import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
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

class _FakeSourceRepo extends SourceRepository {
  final List<Source> _sources;
  bool shouldThrow = false;

  _FakeSourceRepo(this._sources);

  @override
  Future<void> init() async {
    if (shouldThrow) throw Exception('init error');
  }

  @override
  Future<Result<List<Source>>> getAll() async {
    if (shouldThrow) return Result.failure('storage error');
    return Result.success(List.from(_sources));
  }

  @override
  Future<Result<Source?>> get(String key) async {
    if (shouldThrow) return Result.failure('storage error');
    return Result.success(_sources.where((s) => s.id == key).firstOrNull);
  }

  @override
  Future<Result<void>> save(String key, Source item) async {
    if (shouldThrow) return Result.failure('storage error');
    _sources.removeWhere((s) => s.id == item.id);
    _sources.add(item);
    return Result.success(null);
  }

  @override
  Future<Result<void>> delete(String key) async {
    if (shouldThrow) return Result.failure('storage error');
    _sources.removeWhere((s) => s.id == key);
    return Result.success(null);
  }

  @override
  Future<void> create(Source source) async {
    if (shouldThrow) throw Exception('storage error');
    _sources.add(source);
  }

  @override
  Future<List<Source>> getBySubject(String subjectId) async {
    return _sources.where((s) => s.subjectId == subjectId).toList();
  }

  @override
  Future<List<Source>> getByTopic(String topicId) async {
    return _sources.where((s) => s.topicId == topicId).toList();
  }

  @override
  Future<List<Source>> getByStudent(String studentId) async {
    return _sources.where((s) => s.studentId == studentId).toList();
  }

  @override
  Future<List<Source>> getByType(String sourceType) async {
    return _sources.where((s) => s.type.name == sourceType).toList();
  }

  @override
  Future<List<Source>> getByStatus(ProcessingStatus status) async {
    return _sources.where((s) => s.statusEnum == status).toList();
  }
}

void main() {
  group('QuestionProviders', () {
    group('questionRepositoryProvider', () {
      test('creates QuestionRepository', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repo = container.read(questionRepositoryProvider);
        expect(repo, isA<QuestionRepository>());
      });

      test('can be overridden with fake repo', () {
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

      test('override returns seeded data through repo', () async {
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

      test('is singleton', () {
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

    group('sourceRepositoryProvider', () {
      test('creates SourceRepository', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repo = container.read(sourceRepositoryProvider);
        expect(repo, isA<SourceRepository>());
      });

      test('is singleton', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final a = container.read(sourceRepositoryProvider);
        final b = container.read(sourceRepositoryProvider);
        expect(a, same(b));
      });

      test('can be overridden with fake repo', () {
        final fakeRepo = _FakeSourceRepo([]);
        final container = ProviderContainer(
          overrides: [
            sourceRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(sourceRepositoryProvider);
        expect(repo, same(fakeRepo));
      });

      test('behavioral: overridden repo returns seeded data through provider', () async {
        final sources = [
          Source(
            id: 'src-1',
            title: 'Algebra Textbook',
            type: SourceType.textbook,
            subjectId: 'math',
            topicId: 'algebra',
            studentId: 'stu-1',
            createdAt: DateTime(2026, 1, 1),
          ),
          Source(
            id: 'src-2',
            title: 'Chemistry Notes',
            type: SourceType.lectureNotes,
            subjectId: 'chem',
            topicId: 'basics',
            studentId: 'stu-1',
            createdAt: DateTime(2026, 1, 1),
          ),
        ];
        final fakeRepo = _FakeSourceRepo(sources);

        final container = ProviderContainer(
          overrides: [
            sourceRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(sourceRepositoryProvider);
        final allResult = await repo.getAll();
        expect(allResult.isSuccess, isTrue);
        expect(allResult.data, hasLength(2));
        expect(allResult.data![0].title, 'Algebra Textbook');
        expect(allResult.data![1].title, 'Chemistry Notes');
      });

      test('behavioral: overridden repo creates and retrieves source', () async {
        final fakeRepo = _FakeSourceRepo([]);
        final container = ProviderContainer(
          overrides: [
            sourceRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(sourceRepositoryProvider);
        await repo.create(Source(
          id: 'src-new',
          title: 'New Source',
          type: SourceType.pdf,
          subjectId: 'bio',
          studentId: 'stu-1',
          createdAt: DateTime(2026, 3, 15),
        ));

        final allResult = await repo.getAll();
        expect(allResult.isSuccess, isTrue);
        expect(allResult.data, hasLength(1));
        expect(allResult.data!.first.id, 'src-new');
        expect(allResult.data!.first.title, 'New Source');
      });

      test('behavioral: overridden repo supports getById', () async {
        final fakeRepo = _FakeSourceRepo([
          Source(
            id: 'src-find',
            title: 'Findable Source',
            type: SourceType.video,
            subjectId: 'physics',
            studentId: 'stu-1',
            createdAt: DateTime(2026, 2, 10),
          ),
        ]);
        final container = ProviderContainer(
          overrides: [
            sourceRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(sourceRepositoryProvider);
        final result = await repo.get('src-find');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.title, 'Findable Source');
      });

      test('behavioral: overridden repo returns null for missing id', () async {
        final fakeRepo = _FakeSourceRepo([]);
        final container = ProviderContainer(
          overrides: [
            sourceRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(sourceRepositoryProvider);
        final result = await repo.get('non-existent');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
      });

      test('behavioral: overridden repo filters by subject', () async {
        final fakeRepo = _FakeSourceRepo([
          Source(
            id: 's1', title: 'Math Doc', type: SourceType.pdf,
            subjectId: 'math', studentId: 'stu-1', createdAt: DateTime(2026, 1, 1),
          ),
          Source(
            id: 's2', title: 'Chem Doc', type: SourceType.pdf,
            subjectId: 'chem', studentId: 'stu-1', createdAt: DateTime(2026, 1, 1),
          ),
        ]);
        final container = ProviderContainer(
          overrides: [
            sourceRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(sourceRepositoryProvider);
        final mathSources = await repo.getBySubject('math');
        expect(mathSources, hasLength(1));
        expect(mathSources.first.id, 's1');
      });

      test('behavioral: overridden repo filters by type', () async {
        final fakeRepo = _FakeSourceRepo([
          Source(
            id: 's1', title: 'PDF Doc', type: SourceType.pdf,
            studentId: 'stu-1', createdAt: DateTime(2026, 1, 1),
          ),
          Source(
            id: 's2', title: 'Video', type: SourceType.video,
            studentId: 'stu-1', createdAt: DateTime(2026, 1, 1),
          ),
        ]);
        final container = ProviderContainer(
          overrides: [
            sourceRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(sourceRepositoryProvider);
        final pdfSources = await repo.getByType('pdf');
        expect(pdfSources, hasLength(1));
        expect(pdfSources.first.id, 's1');
      });

      test('handles error from repo getAll', () async {
        final fakeRepo = _FakeSourceRepo([]);
        fakeRepo.shouldThrow = true;

        final container = ProviderContainer(
          overrides: [
            sourceRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(sourceRepositoryProvider);
        final result = await repo.getAll();
        expect(result.isFailure, isTrue);
      });

      test('recovers after error', () async {
        final sources = [
          Source(
            id: 'src-rec',
            title: 'Recovered Source',
            type: SourceType.document,
            studentId: 'stu-1',
            createdAt: DateTime(2026, 1, 1),
          ),
        ];
        final fakeRepo = _FakeSourceRepo(sources);

        fakeRepo.shouldThrow = true;
        final container = ProviderContainer(
          overrides: [
            sourceRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(sourceRepositoryProvider);
        var result = await repo.getAll();
        expect(result.isFailure, isTrue);

        fakeRepo.shouldThrow = false;
        result = await repo.getAll();
        expect(result.isSuccess, isTrue);
        expect(result.data, hasLength(1));
        expect(result.data!.first.title, 'Recovered Source');
      });

      test('handles error on create', () async {
        final fakeRepo = _FakeSourceRepo([]);
        fakeRepo.shouldThrow = true;

        final container = ProviderContainer(
          overrides: [
            sourceRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(sourceRepositoryProvider);
        expect(
          () => repo.create(Source(
            id: 'fail-src',
            title: 'Failing Source',
            type: SourceType.pdf,
            studentId: 'stu-1',
            createdAt: DateTime(2026, 1, 1),
          )),
          throwsException,
        );
      });

      test('handles error on delete', () async {
        final fakeRepo = _FakeSourceRepo([
          Source(
            id: 'del-src',
            title: 'Source to Delete',
            type: SourceType.pdf,
            studentId: 'stu-1',
            createdAt: DateTime(2026, 1, 1),
          ),
        ]);
        fakeRepo.shouldThrow = true;

        final container = ProviderContainer(
          overrides: [
            sourceRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(sourceRepositoryProvider);
        final result = await repo.delete('del-src');
        expect(result.isFailure, isTrue);
      });
    });
  });
}
