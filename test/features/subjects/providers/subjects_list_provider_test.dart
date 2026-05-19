import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/subjects/providers/subjects_list_provider.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';

class _FakeSubjectRepository extends SubjectRepository {
  final Map<String, Subject> _storage = {};
  bool throwOnGetAll = false;

  @override
  Future<void> init() async {}

  @override
  Future<Result<Subject?>> get(String key) async =>
      Result.success(_storage[key]);

  @override
  Future<Result<List<Subject>>> getAll() async {
    if (throwOnGetAll) return Result.failure('get_all_failed');
    return Result.success(_storage.values.toList());
  }

  @override
  Future<Result<void>> put(String key, Subject item) async {
    _storage[key] = item;
    return Result.success(null);
  }

  @override
  Future<Result<void>> delete(String key) async {
    _storage.remove(key);
    return Result.success(null);
  }
}

class _FakeSessionRepository extends SessionRepository {
  final Map<String, Session> _storage = {};

  @override
  Future<Result<List<Session>>> getAll() async =>
      Result.success(_storage.values.toList());

  @override
  Future<Result<List<Session>>> getBySubject(String subjectId) async {
    final sessions =
        _storage.values.where((s) => s.subjectId == subjectId).toList();
    return Result.success(sessions);
  }

  void seed(Session session) => _storage[session.id] = session;
}

class _TestNotifier extends SubjectsRepositoryNotifier {
  final SubjectRepository _repo;

  _TestNotifier(this._repo);

  @override
  Future<SubjectRepository> build() async => _repo;
}

Subject _subject({
  required String id,
  String name = 'Test Subject',
}) {
  return Subject(id: id, name: name);
}

Session _session({
  required String id,
  required String subjectId,
}) {
  return Session(
    id: id,
    studentId: 'student-1',
    subjectId: subjectId,
    startTime: DateTime(2026, 5, 18),
  );
}

void main() {
  group('subjectListProvider', () {
    test('returns subjects from repository', () async {
      final fakeRepo = _FakeSubjectRepository();
      await fakeRepo.put('s1', _subject(id: 's1', name: 'Math'));
      await fakeRepo.put('s2', _subject(id: 's2', name: 'Physics'));

      final container = ProviderContainer(overrides: [
        subjectsRepositoryProvider.overrideWith(
          () => _TestNotifier(fakeRepo),
        ),
      ]);
      addTearDown(container.dispose);

      final subjects = await container.read(subjectListProvider.future);

      expect(subjects, hasLength(2));
      expect(subjects[0].name, 'Math');
      expect(subjects[1].name, 'Physics');
    });

    test('returns empty list when repository has no subjects', () async {
      final fakeRepo = _FakeSubjectRepository();

      final container = ProviderContainer(overrides: [
        subjectsRepositoryProvider.overrideWith(
          () => _TestNotifier(fakeRepo),
        ),
      ]);
      addTearDown(container.dispose);

      final subjects = await container.read(subjectListProvider.future);

      expect(subjects, isEmpty);
    });

    test('returns empty list when repository returns null data', () async {
      final fakeRepo = _FakeSubjectRepository();

      final container = ProviderContainer(overrides: [
        subjectsRepositoryProvider.overrideWith(
          () => _TestNotifier(fakeRepo),
        ),
      ]);
      addTearDown(container.dispose);

      final subjects = await container.read(subjectListProvider.future);

      expect(subjects, isEmpty);
    });

    test('throws when repository getAll fails', () async {
      final fakeRepo = _FakeSubjectRepository();
      fakeRepo.throwOnGetAll = true;

      final container = ProviderContainer(overrides: [
        subjectsRepositoryProvider.overrideWith(
          () => _TestNotifier(fakeRepo),
        ),
      ]);
      addTearDown(container.dispose);

      expect(
        () => container.read(subjectListProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('injected fake repo is used by the provider', () async {
      final fakeRepo = _FakeSubjectRepository();
      await fakeRepo.put('s-injected', _subject(id: 's-injected', name: 'Injected'));

      final container = ProviderContainer(overrides: [
        subjectsRepositoryProvider.overrideWith(
          () => _TestNotifier(fakeRepo),
        ),
      ]);
      addTearDown(container.dispose);

      final subjects = await container.read(subjectListProvider.future);

      expect(subjects, hasLength(1));
      expect(subjects[0].id, 's-injected');
    });

    test('provider is loading before repo is ready', () {
      final fakeRepo = _FakeSubjectRepository();

      final container = ProviderContainer(overrides: [
        subjectsRepositoryProvider.overrideWith(
          () => _TestNotifier(fakeRepo),
        ),
      ]);
      addTearDown(container.dispose);

      expect(container.read(subjectListProvider).isLoading, isTrue);
    });
  });

  group('subjectSessionCountsProvider', () {
    test('returns correct session counts per subject', () async {
      final fakeRepo = _FakeSubjectRepository();
      await fakeRepo.put('s1', _subject(id: 's1', name: 'Math'));
      await fakeRepo.put('s2', _subject(id: 's2', name: 'Physics'));

      final fakeSessionRepo = _FakeSessionRepository();
      fakeSessionRepo.seed(_session(id: 'sess1', subjectId: 's1'));
      fakeSessionRepo.seed(_session(id: 'sess2', subjectId: 's1'));
      fakeSessionRepo.seed(_session(id: 'sess3', subjectId: 's2'));

      final container = ProviderContainer(overrides: [
        subjectsRepositoryProvider.overrideWith(
          () => _TestNotifier(fakeRepo),
        ),
        sessionRepositoryProvider.overrideWith((ref) => fakeSessionRepo),
      ]);
      addTearDown(container.dispose);

      final counts = await container.read(subjectSessionCountsProvider.future);

      expect(counts, hasLength(2));
      expect(counts['s1'], 2);
      expect(counts['s2'], 1);
    });

    test('returns zero counts when no sessions exist', () async {
      final fakeRepo = _FakeSubjectRepository();
      await fakeRepo.put('s1', _subject(id: 's1', name: 'Math'));

      final fakeSessionRepo = _FakeSessionRepository();

      final container = ProviderContainer(overrides: [
        subjectsRepositoryProvider.overrideWith(
          () => _TestNotifier(fakeRepo),
        ),
        sessionRepositoryProvider.overrideWith((ref) => fakeSessionRepo),
      ]);
      addTearDown(container.dispose);

      final counts = await container.read(subjectSessionCountsProvider.future);

      expect(counts, hasLength(1));
      expect(counts['s1'], 0);
    });

    test('returns empty map when no subjects exist', () async {
      final fakeRepo = _FakeSubjectRepository();
      final fakeSessionRepo = _FakeSessionRepository();

      final container = ProviderContainer(overrides: [
        subjectsRepositoryProvider.overrideWith(
          () => _TestNotifier(fakeRepo),
        ),
        sessionRepositoryProvider.overrideWith((ref) => fakeSessionRepo),
      ]);
      addTearDown(container.dispose);

      final counts = await container.read(subjectSessionCountsProvider.future);

      expect(counts, isEmpty);
    });

    test('injected session repo is used by the provider', () async {
      final fakeRepo = _FakeSubjectRepository();
      await fakeRepo.put('s1', _subject(id: 's1', name: 'Math'));

      final fakeSessionRepo = _FakeSessionRepository();
      fakeSessionRepo.seed(_session(id: 'sess1', subjectId: 's1'));

      final container = ProviderContainer(overrides: [
        subjectsRepositoryProvider.overrideWith(
          () => _TestNotifier(fakeRepo),
        ),
        sessionRepositoryProvider.overrideWith((ref) => fakeSessionRepo),
      ]);
      addTearDown(container.dispose);

      final counts = await container.read(subjectSessionCountsProvider.future);

      expect(counts['s1'], 1);
    });

    test('uses the same subject list as subjectListProvider', () async {
      final fakeRepo = _FakeSubjectRepository();
      await fakeRepo.put('s1', _subject(id: 's1', name: 'Math'));

      final fakeSessionRepo = _FakeSessionRepository();

      final container = ProviderContainer(overrides: [
        subjectsRepositoryProvider.overrideWith(
          () => _TestNotifier(fakeRepo),
        ),
        sessionRepositoryProvider.overrideWith((ref) => fakeSessionRepo),
      ]);
      addTearDown(container.dispose);

      final subjects = await container.read(subjectListProvider.future);
      final counts = await container.read(subjectSessionCountsProvider.future);

      expect(subjects, hasLength(1));
      expect(counts.keys, equals(subjects.map((s) => s.id).toSet()));
    });

    test('handles multiple sessions for the same subject', () async {
      final fakeRepo = _FakeSubjectRepository();
      await fakeRepo.put('s1', _subject(id: 's1', name: 'Math'));

      final fakeSessionRepo = _FakeSessionRepository();
      for (int i = 0; i < 10; i++) {
        fakeSessionRepo.seed(
          _session(id: 'sess$i', subjectId: 's1'),
        );
      }

      final container = ProviderContainer(overrides: [
        subjectsRepositoryProvider.overrideWith(
          () => _TestNotifier(fakeRepo),
        ),
        sessionRepositoryProvider.overrideWith((ref) => fakeSessionRepo),
      ]);
      addTearDown(container.dispose);

      final counts = await container.read(subjectSessionCountsProvider.future);

      expect(counts['s1'], 10);
    });
  });
}
