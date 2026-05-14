import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/core/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/models/subject_model.dart';

class MockSubjectBox implements Box<Subject> {
  final Map<String, Subject> _storage = {};
  bool _isOpen = true;

  @override
  Iterable<Subject> get values => _storage.values.toList();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final memberName = invocation.memberName.toString();

    if (memberName.contains('get(')) {
      final key = invocation.positionalArguments[0] as String;
      return _storage[key];
    } else if (memberName.contains('put(')) {
      final key = invocation.positionalArguments[0] as String;
      final value = invocation.positionalArguments[1] as Subject;
      _storage[key] = value;
      return Future.value();
    } else if (memberName.contains('delete(')) {
      final key = invocation.positionalArguments[0] as String;
      _storage.remove(key);
      return Future.value();
    } else if (memberName.contains('get isOpen')) {
      return _isOpen;
    }

    return super.noSuchMethod(invocation);
  }

  void addSubject(Subject subject) {
    _storage[subject.id] = subject;
  }

  void clearStorage() {
    _storage.clear();
  }

  @override
  Future<void> close() async {
    _isOpen = false;
  }

  @override
  bool get isOpen => _isOpen;

  @override
  String get name => 'mock-subjects-box';

  @override
  Iterable<String> get keys => _storage.keys;

  @override
  Subject? get(dynamic key, {Subject? defaultValue}) {
    return _storage[key as String] ?? defaultValue;
  }

  @override
  Future<void> put(dynamic key, Subject value) async {
    _storage[key as String] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _storage.remove(key as String);
  }

  @override
  bool containsKey(dynamic key) {
    return _storage.containsKey(key as String);
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

class MockSubjectRepository extends SubjectRepository {
  MockSubjectRepository(MockSubjectBox subjectBox) : super(subjectBox: subjectBox);

  @override
  Future<void> init() async {}
}

class TestSubjectsRepositoryNotifier extends SubjectsRepositoryNotifier {
  final MockSubjectBox _mockBox;

  TestSubjectsRepositoryNotifier(this._mockBox);

  @override
  Future<SubjectRepository> build() async {
    await Future.delayed(const Duration(milliseconds: 10));
    return MockSubjectRepository(_mockBox);
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
        final mockBox = MockSubjectBox();
        mockBox.addSubject(createTestSubject(id: 'subj-1', name: 'Physics'));

        final notifier = TestSubjectsRepositoryNotifier(mockBox);
        final result = await notifier.build();

        expect(result, isA<SubjectRepository>());
        final allSubjects = await result.getAll();
        expect(allSubjects.length, 1);
        expect(allSubjects.first.name, 'Physics');
      });

      test('build returns repository withinitialized data', () async {
        final mockBox = MockSubjectBox();
        mockBox.addSubject(createTestSubject(id: 'subj-1', name: 'Chemistry'));

        final notifier = TestSubjectsRepositoryNotifier(mockBox);
        final result = await notifier.build();

        final allSubjects = await result.getAll();
        expect(allSubjects.length, 1);
        expect(allSubjects.first.name, 'Chemistry');
      });
    });

    group('subjectsRepositoryProvider', () {
      test('provider returns AsyncValue with data after build', () async {
        final mockBox = MockSubjectBox();
        mockBox.addSubject(createTestSubject(id: 'subj-1', name: 'Physics'));
        
        final container = ProviderContainer(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => TestSubjectsRepositoryNotifier(mockBox)),
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
        final mockBox = MockSubjectBox();
        final container = ProviderContainer(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => TestSubjectsRepositoryNotifier(mockBox)),
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
      late MockSubjectBox mockBox;

      setUp(() {
        mockBox = MockSubjectBox();
        container = ProviderContainer(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => TestSubjectsRepositoryNotifier(mockBox)),
          ],
        );
      });

      tearDown(() {
        container.dispose();
      });

      test('can get all subjects', () async {
        mockBox.addSubject(createTestSubject(id: '1', name: 'Physics'));
        mockBox.addSubject(createTestSubject(id: '2', name: 'Chemistry'));

        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        final subjects = await repo.getAll();

        expect(subjects.length, 2);
      });

      test('can get subject by id', () async {
        mockBox.addSubject(createTestSubject(id: 'subj-1', name: 'Physics'));

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
        await repo.save(newSubject);

        final retrieved = await repo.get('new-subj');
        expect(retrieved, isNotNull);
        expect(retrieved!.name, 'Biology');
      });

      test('can delete subject', () async {
        mockBox.addSubject(createTestSubject(id: 'subj-1', name: 'Physics'));

        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        await repo.delete('subj-1');

        final result = await repo.get('subj-1');
        expect(result, isNull);
      });

      test('can filter subjects by topics', () async {
        mockBox.addSubject(createTestSubject(id: '1', name: 'Physics', topicIds: ['topic-1', 'topic-2']));
        mockBox.addSubject(createTestSubject(id: '2', name: 'Chemistry', topicIds: ['topic-3']));

        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        final filtered = await repo.getWithTopics(['topic-1']);

        expect(filtered.length, 1);
        expect(filtered.first.name, 'Physics');
      });

      test('can get subject by code', () async {
        mockBox.addSubject(createTestSubject(id: '1', name: 'Physics', code: 'IB-PHYS'));

        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        final subject = await repo.getByCode('IB-PHYS');

        expect(subject, isNotNull);
        expect(subject!.name, 'Physics');
      });

      test('can add topic to subject', () async {
        mockBox.addSubject(createTestSubject(id: 'subj-1', name: 'Physics', topicIds: ['topic-1']));

        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        await repo.addTopicToSubject('subj-1', 'topic-2');

        final subject = await repo.get('subj-1');
        expect(subject!.topicIds, containsAll(['topic-1', 'topic-2']));
      });

      test('can remove topic from subject', () async {
        mockBox.addSubject(createTestSubject(id: 'subj-1', name: 'Physics', topicIds: ['topic-1', 'topic-2']));

        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        await repo.removeTopicFromSubject('subj-1', 'topic-1');

        final subject = await repo.get('subj-1');
        expect(subject!.topicIds, ['topic-2']);
      });
    });

    group('AsyncNotifier behavior', () {
      test('state updates reflect in provider', () async {
        final mockBox = MockSubjectBox();
        mockBox.addSubject(createTestSubject(id: 'subj-1', name: 'Physics'));
        
        final container = ProviderContainer(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => TestSubjectsRepositoryNotifier(mockBox)),
          ],
        );

        await container.read(subjectsRepositoryProvider.future);
        
        final repo = container.read(subjectsRepositoryProvider).valueOrNull;
        expect(repo, isNotNull);
        container.dispose();
      });

      test('handles empty repository', () async {
        final mockBox = MockSubjectBox();
        
        final container = ProviderContainer(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => TestSubjectsRepositoryNotifier(mockBox)),
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
        final mockBox = MockSubjectBox();
        mockBox.addSubject(createTestSubject(id: 'subj-1', name: 'Physics'));
        
        final container = ProviderContainer(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => TestSubjectsRepositoryNotifier(mockBox)),
          ],
        );

        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        final result = await repo.get('non-existent');

        expect(result, isNull);
        container.dispose();
      });

      test('handles delete non-existent gracefully', () async {
        final mockBox = MockSubjectBox();
        mockBox.addSubject(createTestSubject(id: 'subj-1', name: 'Physics'));
        
        final container = ProviderContainer(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => TestSubjectsRepositoryNotifier(mockBox)),
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
        final mockBox = MockSubjectBox();
        
        final container = ProviderContainer(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => TestSubjectsRepositoryNotifier(mockBox)),
          ],
        );

        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        final result = await repo.getWithTopics(['topic-1']);

        expect(result, isEmpty);
        container.dispose();
      });

      test('handles getByCode for non-existent code', () async {
        final mockBox = MockSubjectBox();
        mockBox.addSubject(createTestSubject(id: 'subj-1', name: 'Physics', code: 'IB-PHYS'));
        
        final container = ProviderContainer(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => TestSubjectsRepositoryNotifier(mockBox)),
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
      late MockSubjectBox mockBox;

      setUp(() {
        mockBox = MockSubjectBox();
        container = ProviderContainer(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => TestSubjectsRepositoryNotifier(mockBox)),
          ],
        );
      });

      tearDown(() {
        container.dispose();
      });

      test('returns all subjects', () async {
        mockBox.addSubject(createTestSubject(id: '1', name: 'Physics'));
        mockBox.addSubject(createTestSubject(id: '2', name: 'Chemistry'));

        await container.read(subjectsRepositoryProvider.future);
        final repo = container.read(subjectsRepositoryProvider).value!;
        
        final subjects = await repo.getAll();

        expect(subjects.length, 2);
      });
    });
  });
}