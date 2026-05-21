import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/subjects/providers/subject_repository_provider.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';

class FakeSubjectRepository extends SubjectRepository {
  final Map<String, Subject> _subjects = {};
  bool _shouldThrow = false;

  void setShouldThrow(bool value) => _shouldThrow = value;

  @override
  Future<void> init() async {}

  @override
  Future<Result<Subject?>> get(String key) async {
    if (_shouldThrow) return Result.failure('storage error');
    return Result.success(_subjects[key]);
  }

  @override
  Future<Result<List<Subject>>> getAll() async {
    if (_shouldThrow) return Result.failure('storage error');
    return Result.success(_subjects.values.toList());
  }

  @override
  Future<Result<void>> put(String key, Subject item) async {
    if (_shouldThrow) return Result.failure('storage error');
    _subjects[key] = item;
    return Result.success(null);
  }

  @override
  Future<Result<void>> delete(String key) async {
    if (_shouldThrow) return Result.failure('storage error');
    _subjects.remove(key);
    return Result.success(null);
  }
}

void main() {
  group('subjectRepositoryProvider', () {
    test('provides a SubjectRepository instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(subjectRepositoryProvider);
      expect(repo, isA<SubjectRepository>());
    });

    test('singleton behavior - same instance across reads', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final a = container.read(subjectRepositoryProvider);
      final b = container.read(subjectRepositoryProvider);
      expect(identical(a, b), isTrue);
    });

    test('can be overridden via ProviderScope', () {
      final fake = FakeSubjectRepository();
      final container = ProviderContainer(overrides: [
        subjectRepositoryProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      final repo = container.read(subjectRepositoryProvider);
      expect(repo, same(fake));
    });

    test('constructs without throwing', () {
      expect(() => SubjectRepository(), returnsNormally);
    });

    test('data flow - seed and retrieve through provider', () async {
      final fake = FakeSubjectRepository();
      final subject = Subject(id: 's1', name: 'Physics', syllabus: 'syl1');
      await fake.put('s1', subject);

      final container = ProviderContainer(overrides: [
        subjectRepositoryProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      final repo = container.read(subjectRepositoryProvider);
      final result = await repo.get('s1');
      expect(result.isSuccess, isTrue);
      expect(result.data!.name, 'Physics');
    });

    test('propagates errors from repository', () async {
      final fake = FakeSubjectRepository();
      fake.setShouldThrow(true);

      final container = ProviderContainer(overrides: [
        subjectRepositoryProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      final repo = container.read(subjectRepositoryProvider);
      final result = await repo.get('s1');
      expect(result.isFailure, isTrue);
    });

    test('getAll returns seeded subjects through provider', () async {
      final fake = FakeSubjectRepository();
      await fake.put('s1', Subject(id: 's1', name: 'Physics', syllabus: 'syl1'));
      await fake.put('s2', Subject(id: 's2', name: 'Chemistry', syllabus: 'syl1'));

      final container = ProviderContainer(overrides: [
        subjectRepositoryProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      final repo = container.read(subjectRepositoryProvider);
      final result = await repo.getAll();
      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(2));
    });
  });
}
