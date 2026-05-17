import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/models/subject_model.dart';

class FakeSubjectRepository extends SubjectRepository {
  final Map<String, Subject> _storage = {};

  @override
  Future<void> init() async {}

  void addSubject(Subject subject) {
    _storage[subject.id] = subject;
  }

  void clearStorage() {
    _storage.clear();
  }

  @override
  Future<Subject?> get(String key) async {
    return _storage[key];
  }

  @override
  Future<List<Subject>> getAll() async {
    return _storage.values.toList();
  }

  @override
  Future<void> save(String key, Subject item) async {
    _storage[key] = item;
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> create(Subject subject) async {
    _storage[subject.id] = subject;
  }

  @override
  Future<List<Subject>> getWithTopics(List<String> topicIds) async {
    return _storage.values
        .where((s) => s.topicIds.any((id) => topicIds.contains(id)))
        .toList();
  }

  @override
  Future<void> addTopicToSubject(String subjectId, String topicId) async {
    final subject = _storage[subjectId];
    if (subject != null) {
      if (subject.topicIds.contains(topicId)) return;
      _storage[subjectId] = subject.copyWith(
        topicIds: [...subject.topicIds, topicId],
      );
    }
  }

  @override
  Future<void> removeTopicFromSubject(String subjectId, String topicId) async {
    final subject = _storage[subjectId];
    if (subject != null) {
      _storage[subjectId] = subject.copyWith(
        topicIds: subject.topicIds.where((id) => id != topicId).toList(),
      );
    }
  }

  @override
  Future<Subject?> getByCode(String code) async {
    return _storage.values.where((s) => s.code == code).firstOrNull;
  }
}

Subject createTestSubject({
  String id = 'test-id',
  String name = 'Test Subject',
  String? description,
  String? syllabus,
  String? code,
  String? teacher,
  List<String>? topicIds,
  String color = '#2196F3',
  DateTime? createdAt,
  DateTime? examDate,
}) {
  return Subject(
    id: id,
    name: name,
    description: description,
    syllabus: syllabus,
    code: code,
    teacher: teacher,
    topicIds: topicIds,
    color: color,
    createdAt: createdAt,
    examDate: examDate,
  );
}

class TestSubjectsRepositoryNotifier extends SubjectsRepositoryNotifier {
  final FakeSubjectRepository _repo;

  TestSubjectsRepositoryNotifier(this._repo);

  @override
  Future<SubjectRepository> build() async {
    await Future.delayed(const Duration(milliseconds: 10));
    return _repo;
  }
}

class FailingSubjectsRepositoryNotifier extends SubjectsRepositoryNotifier {
  @override
  Future<SubjectRepository> build() async {
    await Future.delayed(const Duration(milliseconds: 10));
    throw Exception('Failed to initialize repository');
  }
}

void main() {
  group('SubjectsRepositoryNotifier', () {
    group('initialization', () {
      test('creates repository and returns it from build', () async {
        final fakeRepo = FakeSubjectRepository();
        fakeRepo.addSubject(createTestSubject(id: 'subj-1', name: 'Physics'));

        final notifier = TestSubjectsRepositoryNotifier(fakeRepo);
        final result = await notifier.build();

        expect(result, isA<SubjectRepository>());
        final allSubjects = await result.getAll();
        expect(allSubjects.length, 1);
        expect(allSubjects.first.name, 'Physics');
      });

      test('build returns repository withinitialized data', () async {
        final fakeRepo = FakeSubjectRepository();
        fakeRepo.addSubject(createTestSubject(id: 'subj-1', name: 'Chemistry'));

        final notifier = TestSubjectsRepositoryNotifier(fakeRepo);
        final result = await notifier.build();

        final allSubjects = await result.getAll();
        expect(allSubjects.length, 1);
        expect(allSubjects.first.name, 'Chemistry');
      });
    });

    group('subjectsRepositoryProvider', () {
      test('provider returns AsyncValue with data after build', () async {
        final fakeRepo = FakeSubjectRepository();
        fakeRepo.addSubject(createTestSubject(id: 'subj-1', name: 'Physics'));
        
        final container = ProviderContainer(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => TestSubjectsRepositoryNotifier(fakeRepo)),
          ],
        );

        container.read(subjectsRepositoryProvider);
        
        await expectLater(
          container.read(subjectsRepositoryProvider.future),
          completes,
        );
        
        container.dispose();
      });

      test('provider returns AsyncValue with loading state initially', () {
        final fakeRepo = FakeSubjectRepository();
        final container = ProviderContainer(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => TestSubjectsRepositoryNotifier(fakeRepo)),
          ],
        );

        final asyncValue = container.read(subjectsRepositoryProvider);

        expect(asyncValue.isLoading, isTrue);
        container.dispose();
      });

      test('provider returns AsyncValue with error on failure', () async {
        final container = ProviderContainer(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => FailingSubjectsRepositoryNotifier()),
          ],
        );

        try {
          await container.read(subjectsRepositoryProvider.future);
        } catch (_) {}

        final asyncValue = container.read(subjectsRepositoryProvider);
        expect(asyncValue.hasError, isTrue);
        container.dispose();
      });
    });

    group('repository operations via provider', () {
      late ProviderContainer container;
      late FakeSubjectRepository fakeRepo;

      setUp(() {
        fakeRepo = FakeSubjectRepository();
        container = ProviderContainer(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => TestSubjectsRepositoryNotifier(fakeRepo)),
          ],
        );
      });

      tearDown(() {
        container.dispose();
      });

      test('can get all subjects', () async {
        fakeRepo.addSubject(createTestSubject(id: '1', name: 'Physics'));
        fakeRepo.addSubject(createTestSubject(id: '2', name: 'Chemistry'));

        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        final subjects = await repo.getAll();

        expect(subjects.length, 2);
      });

      test('can get subject by id', () async {
        fakeRepo.addSubject(createTestSubject(id: 'subj-1', name: 'Physics'));

        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        final subject = await repo.get('subj-1');

        expect(subject, isNotNull);
        expect(subject!.name, 'Physics');
      });

      test('can save subject', () async {
        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        final newSubject = createTestSubject(id: 'new-subj', name: 'Biology');
        await repo.create(newSubject);

        final retrieved = await repo.get('new-subj');
        expect(retrieved, isNotNull);
        expect(retrieved!.name, 'Biology');
      });

      test('can delete subject', () async {
        fakeRepo.addSubject(createTestSubject(id: 'subj-1', name: 'Physics'));

        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        await repo.delete('subj-1');

        final result = await repo.get('subj-1');
        expect(result, isNull);
      });

      test('can filter subjects by topics', () async {
        fakeRepo.addSubject(createTestSubject(id: '1', name: 'Physics', topicIds: ['topic-1', 'topic-2']));
        fakeRepo.addSubject(createTestSubject(id: '2', name: 'Chemistry', topicIds: ['topic-3']));

        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        final filtered = await repo.getWithTopics(['topic-1']);

        expect(filtered.length, 1);
        expect(filtered.first.name, 'Physics');
      });

      test('can get subject by code', () async {
        fakeRepo.addSubject(createTestSubject(id: '1', name: 'Physics', code: 'IB-PHYS'));

        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        final subject = await repo.getByCode('IB-PHYS');

        expect(subject, isNotNull);
        expect(subject!.name, 'Physics');
      });

      test('can add topic to subject', () async {
        fakeRepo.addSubject(createTestSubject(id: 'subj-1', name: 'Physics', topicIds: ['topic-1']));

        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        await repo.addTopicToSubject('subj-1', 'topic-2');

        final subject = await repo.get('subj-1');
        expect(subject!.topicIds, containsAll(['topic-1', 'topic-2']));
      });

      test('can remove topic from subject', () async {
        fakeRepo.addSubject(createTestSubject(id: 'subj-1', name: 'Physics', topicIds: ['topic-1', 'topic-2']));

        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        await repo.removeTopicFromSubject('subj-1', 'topic-1');

        final subject = await repo.get('subj-1');
        expect(subject!.topicIds, ['topic-2']);
      });
    });

    group('AsyncNotifier behavior', () {
      test('state updates reflect in provider', () async {
        final fakeRepo = FakeSubjectRepository();
        fakeRepo.addSubject(createTestSubject(id: 'subj-1', name: 'Physics'));
        
        final container = ProviderContainer(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => TestSubjectsRepositoryNotifier(fakeRepo)),
          ],
        );

        await container.read(subjectsRepositoryProvider.future);
        
        final repo = container.read(subjectsRepositoryProvider).valueOrNull;
        expect(repo, isNotNull);
        container.dispose();
      });

      test('handles empty repository', () async {
        final fakeRepo = FakeSubjectRepository();
        
        final container = ProviderContainer(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => TestSubjectsRepositoryNotifier(fakeRepo)),
          ],
        );

        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        final subjects = await repo.getAll();

        expect(subjects, isEmpty);
        container.dispose();
      });
    });

    group('error handling', () {
      test('handles get failure gracefully', () async {
        final fakeRepo = FakeSubjectRepository();
        fakeRepo.addSubject(createTestSubject(id: 'subj-1', name: 'Physics'));
        
        final container = ProviderContainer(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => TestSubjectsRepositoryNotifier(fakeRepo)),
          ],
        );

        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        final result = await repo.get('non-existent');

        expect(result, isNull);
        container.dispose();
      });

      test('handles delete non-existent gracefully', () async {
        final fakeRepo = FakeSubjectRepository();
        fakeRepo.addSubject(createTestSubject(id: 'subj-1', name: 'Physics'));
        
        final container = ProviderContainer(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => TestSubjectsRepositoryNotifier(fakeRepo)),
          ],
        );

        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        await repo.delete('non-existent');
        
        final remaining = await repo.getAll();
        expect(remaining.length, 1);
        container.dispose();
      });

      test('handles getWithTopics on empty repository', () async {
        final fakeRepo = FakeSubjectRepository();
        
        final container = ProviderContainer(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => TestSubjectsRepositoryNotifier(fakeRepo)),
          ],
        );

        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        final result = await repo.getWithTopics(['topic-1']);

        expect(result, isEmpty);
        container.dispose();
      });

      test('handles getByCode for non-existent code', () async {
        final fakeRepo = FakeSubjectRepository();
        fakeRepo.addSubject(createTestSubject(id: 'subj-1', name: 'Physics', code: 'IB-PHYS'));
        
        final container = ProviderContainer(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => TestSubjectsRepositoryNotifier(fakeRepo)),
          ],
        );

        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        final result = await repo.getByCode('NON-EXISTENT');

        expect(result, isNull);
        container.dispose();
      });
    });

    group('getAll via repository', () {
      late ProviderContainer container;
      late FakeSubjectRepository fakeRepo;

      setUp(() {
        fakeRepo = FakeSubjectRepository();
        container = ProviderContainer(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => TestSubjectsRepositoryNotifier(fakeRepo)),
          ],
        );
      });

      tearDown(() {
        container.dispose();
      });

      test('returns all subjects', () async {
        fakeRepo.addSubject(createTestSubject(id: '1', name: 'Physics'));
        fakeRepo.addSubject(createTestSubject(id: '2', name: 'Chemistry'));

        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        final subjects = await repo.getAll();

        expect(subjects.length, 2);
      });
    });
  });
}