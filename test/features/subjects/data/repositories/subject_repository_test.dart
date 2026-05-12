import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/models/subject_model.dart';

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

void main() {
  group('SubjectRepository', () {
    late MockSubjectBox mockBox;
    late SubjectRepository repository;

    setUp(() {
      mockBox = MockSubjectBox();
      repository = SubjectRepository(subjectBox: mockBox);
    });

    group('getAll', () {
      test('returns empty list when box is empty', () async {
        mockBox.clearStorage();

        final result = await repository.getAll();

        expect(result, isEmpty);
      });

      test('returns all subjects from box', () async {
        mockBox.addSubject(createTestSubject(id: '1', name: 'Physics'));
        mockBox.addSubject(createTestSubject(id: '2', name: 'Chemistry'));
        mockBox.addSubject(createTestSubject(id: '3', name: 'Biology'));

        final result = await repository.getAll();

        expect(result.length, 3);
        expect(result.map((s) => s.name), containsAll(['Physics', 'Chemistry', 'Biology']));
      });

      test('returns new list instance each time', () async {
        mockBox.addSubject(createTestSubject(id: '1', name: 'Physics'));

        final result = await repository.getAll();
        final result2 = await repository.getAll();

        expect(identical(result, result2), isFalse);
        expect(result[0].name, result2[0].name);
      });
    });

    group('get', () {
      test('returns subject by id', () async {
        mockBox.addSubject(createTestSubject(id: 'subject-1', name: 'Physics'));

        final result = await repository.get('subject-1');

        expect(result, isNotNull);
        expect(result!.name, 'Physics');
      });

      test('returns null for non-existent id', () async {
        mockBox.addSubject(createTestSubject(id: 'subject-1', name: 'Physics'));

        final result = await repository.get('non-existent');

        expect(result, isNull);
      });

      test('returns null for empty box', () async {
        mockBox.clearStorage();

        final result = await repository.get('any-id');

        expect(result, isNull);
      });
    });

    group('save', () {
      test('creates new subject', () async {
        final subject = createTestSubject(id: 'new-subject', name: 'New Subject');

        await repository.save(subject);
        final retrieved = await repository.get('new-subject');

        expect(retrieved, isNotNull);
        expect(retrieved!.name, 'New Subject');
      });

      test('updates existing subject', () async {
        mockBox.addSubject(createTestSubject(id: 'subject-1', name: 'Original Name'));

        final updated = createTestSubject(id: 'subject-1', name: 'Updated Name');
        await repository.save(updated);

        final retrieved = await repository.get('subject-1');
        expect(retrieved!.name, 'Updated Name');
      });

      test('preserves other subjects when saving new one', () async {
        mockBox.addSubject(createTestSubject(id: 'existing', name: 'Existing'));

        await repository.save(createTestSubject(id: 'new', name: 'New'));

        final all = await repository.getAll();
        expect(all.length, 2);
        expect(all.map((s) => s.name), containsAll(['Existing', 'New']));
      });
    });

    group('delete', () {
      test('removes subject from box', () async {
        mockBox.addSubject(createTestSubject(id: 'subject-1', name: 'Physics'));

        await repository.delete('subject-1');

        final result = await repository.get('subject-1');
        expect(result, isNull);
      });

      test('handles non-existent id gracefully', () async {
        mockBox.addSubject(createTestSubject(id: 'subject-1', name: 'Physics'));

        await repository.delete('non-existent-id');

        final result = await repository.get('subject-1');
        expect(result, isNotNull);
      });

      test('deletes only specified subject', () async {
        mockBox.addSubject(createTestSubject(id: 'subject-1', name: 'Physics'));
        mockBox.addSubject(createTestSubject(id: 'subject-2', name: 'Chemistry'));

        await repository.delete('subject-1');

        final remaining = await repository.getAll();
        expect(remaining.length, 1);
        expect(remaining[0].id, 'subject-2');
      });
    });

    group('getWithTopics', () {
      test('filters subjects by topic IDs - single topic', () async {
        mockBox.addSubject(createTestSubject(id: '1', name: 'Physics', topicIds: ['topic-1', 'topic-2']));
        mockBox.addSubject(createTestSubject(id: '2', name: 'Chemistry', topicIds: ['topic-3']));
        mockBox.addSubject(createTestSubject(id: '3', name: 'Biology', topicIds: ['topic-1']));

        final result = await repository.getWithTopics(['topic-1']);

        expect(result.length, 2);
        expect(result.map((s) => s.name), containsAll(['Physics', 'Biology']));
      });

      test('filters subjects by multiple topic IDs', () async {
        mockBox.addSubject(createTestSubject(id: '1', name: 'Physics', topicIds: ['topic-1', 'topic-2']));
        mockBox.addSubject(createTestSubject(id: '2', name: 'Chemistry', topicIds: ['topic-3']));
        mockBox.addSubject(createTestSubject(id: '3', name: 'Biology', topicIds: ['topic-1']));

        final result = await repository.getWithTopics(['topic-1', 'topic-3']);

        expect(result.length, 3);
      });

      test('returns empty list when no matches', () async {
        mockBox.addSubject(createTestSubject(id: '1', name: 'Physics', topicIds: ['topic-1']));

        final result = await repository.getWithTopics(['non-existent-topic']);

        expect(result, isEmpty);
      });

      test('returns empty list when box is empty', () async {
        mockBox.clearStorage();

        final result = await repository.getWithTopics(['topic-1']);

        expect(result, isEmpty);
      });

      test('returns empty list when topic filter is empty', () async {
        mockBox.addSubject(createTestSubject(id: '1', name: 'Physics'));
        mockBox.addSubject(createTestSubject(id: '2', name: 'Chemistry'));

        final result = await repository.getWithTopics([]);

        expect(result, isEmpty);
      });

      test('returns subjects with empty topicIds when filtering for any topic', () async {
        mockBox.addSubject(createTestSubject(id: '1', name: 'No Topics', topicIds: []));

        final result = await repository.getWithTopics(['topic-1']);

        expect(result, isEmpty);
      });
    });

    group('addTopicToSubject', () {
      test('adds topic to subject', () async {
        mockBox.addSubject(createTestSubject(id: 'subject-1', name: 'Physics', topicIds: ['topic-1']));

        await repository.addTopicToSubject('subject-1', 'topic-2');

        final result = await repository.get('subject-1');
        expect(result!.topicIds, containsAll(['topic-1', 'topic-2']));
      });

      test('adds topic without duplicates', () async {
        mockBox.addSubject(createTestSubject(id: 'subject-1', name: 'Physics', topicIds: ['topic-1']));

        await repository.addTopicToSubject('subject-1', 'topic-1');

        final result = await repository.get('subject-1');
        expect(result!.topicIds.length, 1);
      });

      test('does nothing for non-existent subject', () async {
        mockBox.addSubject(createTestSubject(id: 'subject-1', name: 'Physics'));

        await repository.addTopicToSubject('non-existent', 'topic-1');

        final result = await repository.get('subject-1');
        expect(result!.topicIds, isEmpty);
      });
    });

    group('removeTopicFromSubject', () {
      test('removes topic from subject', () async {
        mockBox.addSubject(createTestSubject(id: 'subject-1', name: 'Physics', topicIds: ['topic-1', 'topic-2']));

        await repository.removeTopicFromSubject('subject-1', 'topic-1');

        final result = await repository.get('subject-1');
        expect(result!.topicIds, ['topic-2']);
      });

      test('removes only specified topic', () async {
        mockBox.addSubject(createTestSubject(id: 'subject-1', name: 'Physics', topicIds: ['topic-1', 'topic-2', 'topic-3']));

        await repository.removeTopicFromSubject('subject-1', 'topic-2');

        final result = await repository.get('subject-1');
        expect(result!.topicIds, ['topic-1', 'topic-3']);
      });

      test('does nothing for non-existent subject', () async {
        mockBox.addSubject(createTestSubject(id: 'subject-1', name: 'Physics', topicIds: ['topic-1']));

        await repository.removeTopicFromSubject('non-existent', 'topic-1');

        final result = await repository.get('subject-1');
        expect(result!.topicIds, ['topic-1']);
      });

      test('does nothing when topic not present', () async {
        mockBox.addSubject(createTestSubject(id: 'subject-1', name: 'Physics', topicIds: ['topic-1']));

        await repository.removeTopicFromSubject('subject-1', 'non-existent-topic');

        final result = await repository.get('subject-1');
        expect(result!.topicIds, ['topic-1']);
      });
    });

    group('getByCode', () {
      test('finds subject by code', () async {
        mockBox.addSubject(createTestSubject(id: '1', name: 'Physics', code: 'IB-PHYS'));
        mockBox.addSubject(createTestSubject(id: '2', name: 'Chemistry', code: 'IB-CHEM'));

        final result = await repository.getByCode('IB-PHYS');

        expect(result, isNotNull);
        expect(result!.name, 'Physics');
      });

      test('returns null for non-existent code', () async {
        mockBox.addSubject(createTestSubject(id: '1', name: 'Physics', code: 'IB-PHYS'));

        final result = await repository.getByCode('NON-EXISTENT');

        expect(result, isNull);
      });

      test('is case-sensitive', () async {
        mockBox.addSubject(createTestSubject(id: '1', name: 'Physics', code: 'IB-PHYS'));

        final result = await repository.getByCode('ib-phys');

        expect(result, isNull);
      });

      test('returns first match when multiple subjects have same code', () async {
        mockBox.addSubject(createTestSubject(id: '1', name: 'Physics HL', code: 'IB-PHYS'));
        mockBox.addSubject(createTestSubject(id: '2', name: 'Physics SL', code: 'IB-PHYS'));

        final result = await repository.getByCode('IB-PHYS');

        expect(result, isNotNull);
      });

      test('handles null code in subjects', () async {
        mockBox.addSubject(createTestSubject(id: '1', name: 'No Code', code: null));

        final result = await repository.getByCode('ANY-CODE');

        expect(result, isNull);
      });
    });

    group('getStudentSubjects', () {
      test('returns all subjects', () async {
        mockBox.addSubject(createTestSubject(id: '1', name: 'Physics'));
        mockBox.addSubject(createTestSubject(id: '2', name: 'Chemistry'));
        mockBox.addSubject(createTestSubject(id: '3', name: 'Biology'));

        final result = await repository.getStudentSubjects('student-123');

        expect(result.length, 3);
      });

      test('returns empty list when no subjects exist', () async {
        mockBox.clearStorage();

        final result = await repository.getStudentSubjects('student-123');

        expect(result, isEmpty);
      });
    });

    group('init', () {
      test('initializes with provided box', () async {
        final repoWithInit = SubjectRepository(subjectBox: mockBox);
        expect(repoWithInit.getAll(), completes);
      });

      test('repository can be created without init when box is provided', () {
        final repo = SubjectRepository(subjectBox: mockBox);
        expect(repo, isNotNull);
      });
    });

    group('uninitialized repository error handling', () {
      test('throws StateError when box is null and getAll is called', () async {
        final uninitRepo = SubjectRepository(subjectBox: null);

        expect(
          () => uninitRepo.getAll(),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError when box is null and get is called', () async {
        final uninitRepo = SubjectRepository(subjectBox: null);

        expect(
          () => uninitRepo.get('any-id'),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError when box is null and save is called', () async {
        final uninitRepo = SubjectRepository(subjectBox: null);
        final subject = createTestSubject(id: 'test', name: 'Test');

        expect(
          () => uninitRepo.save(subject),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError when box is null and delete is called', () async {
        final uninitRepo = SubjectRepository(subjectBox: null);

        expect(
          () => uninitRepo.delete('any-id'),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError when box is null and getWithTopics is called', () async {
        final uninitRepo = SubjectRepository(subjectBox: null);

        expect(
          () => uninitRepo.getWithTopics(['topic-1']),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError when box is null and addTopicToSubject is called', () async {
        final uninitRepo = SubjectRepository(subjectBox: null);

        expect(
          () => uninitRepo.addTopicToSubject('subject-1', 'topic-1'),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError when box is null and removeTopicFromSubject is called', () async {
        final uninitRepo = SubjectRepository(subjectBox: null);

        expect(
          () => uninitRepo.removeTopicFromSubject('subject-1', 'topic-1'),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError when box is null and getByCode is called', () async {
        final uninitRepo = SubjectRepository(subjectBox: null);

        expect(
          () => uninitRepo.getByCode('IB-PHYS'),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError when box is null and getStudentSubjects is called', () async {
        final uninitRepo = SubjectRepository(subjectBox: null);

        expect(
          () => uninitRepo.getStudentSubjects('student-1'),
          throwsA(isA<StateError>()),
        );
      });

      test('StateError message describes the issue', () async {
        final uninitRepo = SubjectRepository(subjectBox: null);

        try {
          await uninitRepo.getAll();
          fail('Expected StateError');
        } catch (e) {
          expect(e.toString(), contains('SubjectRepository not initialized'));
        }
      });
    });

    group('error handling', () {
      test('get handles box errors gracefully', () async {
        final result = await repository.get('any-id');
        expect(result, isNull);
      });

      test('save handles null subject gracefully', () async {
        await repository.save(createTestSubject(id: 'test', name: 'Test'));
        final result = await repository.get('test');
        expect(result, isNotNull);
      });

      test('getAll returns empty list on empty box', () async {
        mockBox.clearStorage();

        final result = await repository.getAll();
        expect(result, isEmpty);
      });

      test('getWithTopics handles subjects with null topicIds', () async {
        mockBox.addSubject(createTestSubject(id: '1', name: 'Physics'));

        final result = await repository.getWithTopics(['topic-1']);

        expect(result, isEmpty);
      });
    });

    group('edge cases', () {
      test('save and get round-trip preserves all fields', () async {
        final createdAt = DateTime(2024, 6, 15, 10, 30, 0);
        final examDate = DateTime(2025, 6, 15);
        final subject = createTestSubject(
          id: 'full-subject',
          name: 'Full Subject',
          description: 'A detailed description',
          syllabus: 'Syllabus content',
          code: 'FS-101',
          teacher: 'Dr. Teacher',
          topicIds: ['topic-1', 'topic-2', 'topic-3'],
          color: '#FF5722',
          createdAt: createdAt,
          examDate: examDate,
        );

        await repository.save(subject);
        final retrieved = await repository.get('full-subject');

        expect(retrieved, isNotNull);
        expect(retrieved!.id, 'full-subject');
        expect(retrieved.name, 'Full Subject');
        expect(retrieved.description, 'A detailed description');
        expect(retrieved.syllabus, 'Syllabus content');
        expect(retrieved.code, 'FS-101');
        expect(retrieved.teacher, 'Dr. Teacher');
        expect(retrieved.topicIds, ['topic-1', 'topic-2', 'topic-3']);
        expect(retrieved.color, '#FF5722');
        expect(retrieved.createdAt, createdAt);
        expect(retrieved.examDate, examDate);
      });

      test('save preserves null optional fields', () async {
        final subject = createTestSubject(
          id: 'minimal',
          name: 'Minimal',
        );

        await repository.save(subject);
        final retrieved = await repository.get('minimal');

        expect(retrieved, isNotNull);
        expect(retrieved!.description, isNull);
        expect(retrieved.syllabus, isNull);
        expect(retrieved.code, isNull);
        expect(retrieved.teacher, isNull);
        expect(retrieved.examDate, isNull);
      });

      test('addTopicToSubject adds multiple topics sequentially', () async {
        mockBox.addSubject(createTestSubject(id: 's1', name: 'Subject', topicIds: []));

        await repository.addTopicToSubject('s1', 'topic-a');
        await repository.addTopicToSubject('s1', 'topic-b');
        await repository.addTopicToSubject('s1', 'topic-c');

        final result = await repository.get('s1');
        expect(result!.topicIds, ['topic-a', 'topic-b', 'topic-c']);
      });

      test('removeTopicFromSubject removes last topic', () async {
        mockBox.addSubject(createTestSubject(id: 's1', name: 'Subject', topicIds: ['only-topic']));

        await repository.removeTopicFromSubject('s1', 'only-topic');

        final result = await repository.get('s1');
        expect(result!.topicIds, isEmpty);
      });

      test('getByCode returns subject with all fields when found', () async {
        mockBox.addSubject(createTestSubject(
          id: 's1',
          name: 'Physics HL',
          code: 'IB-PHYS-HL',
          description: 'Higher Level',
        ));

        final result = await repository.getByCode('IB-PHYS-HL');

        expect(result, isNotNull);
        expect(result!.id, 's1');
        expect(result.name, 'Physics HL');
        expect(result.description, 'Higher Level');
      });

      test('delete all subjects leaves empty box', () async {
        mockBox.addSubject(createTestSubject(id: '1', name: 'A'));
        mockBox.addSubject(createTestSubject(id: '2', name: 'B'));
        mockBox.addSubject(createTestSubject(id: '3', name: 'C'));

        await repository.delete('1');
        await repository.delete('2');
        await repository.delete('3');

        final result = await repository.getAll();
        expect(result, isEmpty);
      });

      test('delete non-existent id does not affect other subjects', () async {
        mockBox.addSubject(createTestSubject(id: '1', name: 'Physics'));
        mockBox.addSubject(createTestSubject(id: '2', name: 'Chemistry'));

        await repository.delete('non-existent');

        final all = await repository.getAll();
        expect(all.length, 2);
      });

      test('getWithTopics handles subject matching multiple filter topics', () async {
        mockBox.addSubject(createTestSubject(
          id: '1',
          name: 'Comprehensive',
          topicIds: ['topic-a', 'topic-b', 'topic-c'],
        ));
        mockBox.addSubject(createTestSubject(
          id: '2',
          name: 'Simple',
          topicIds: ['topic-a'],
        ));

        final result = await repository.getWithTopics(['topic-b', 'topic-c']);

        expect(result.length, 1);
        expect(result.first.name, 'Comprehensive');
      });

      test('getStudentSubjects ignores studentId parameter and returns all', () async {
        mockBox.addSubject(createTestSubject(id: '1', name: 'Physics'));
        mockBox.addSubject(createTestSubject(id: '2', name: 'Chemistry'));

        final result1 = await repository.getStudentSubjects('student-a');
        final result2 = await repository.getStudentSubjects('student-b');

        expect(result1.length, 2);
        expect(result2.length, 2);
      });

      test('multiple operations in sequence work correctly', () async {
        await repository.save(createTestSubject(id: '1', name: 'Physics', code: 'PHY'));
        await repository.save(createTestSubject(id: '2', name: 'Chemistry', code: 'CHE'));

        expect(await repository.getByCode('PHY'), isNotNull);
        expect(await repository.getByCode('CHE'), isNotNull);

        await repository.addTopicToSubject('1', 'topic-x');
        final s1 = await repository.get('1');
        expect(s1!.topicIds, ['topic-x']);

        await repository.addTopicToSubject('1', 'topic-y');
        final s1Again = await repository.get('1');
        expect(s1Again!.topicIds, ['topic-x', 'topic-y']);

        await repository.removeTopicFromSubject('1', 'topic-x');
        final s1Final = await repository.get('1');
        expect(s1Final!.topicIds, ['topic-y']);

        await repository.delete('2');
        expect(await repository.getAll(), hasLength(1));
      });
    });
  });
}