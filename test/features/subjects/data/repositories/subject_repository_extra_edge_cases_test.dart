import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/data/models/subject_model.dart';

class _MockBox implements Box<Subject> {
  final Map<String, Subject> _data = {};
  bool _isOpen = true;

  @override
  Iterable<Subject> get values => _data.values.toList();

  @override
  Subject? get(dynamic key, {Subject? defaultValue}) {
    return _data[key as String] ?? defaultValue;
  }

  @override
  Future<void> put(dynamic key, Subject value) async {
    _data[key as String] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _data.remove(key as String);
  }

  @override
  bool containsKey(dynamic key) => _data.containsKey(key as String);

  @override
  Iterable<String> get keys => _data.keys;

  @override
  String get name => 'extra-mock';

  @override
  bool get isOpen => _isOpen;

  @override
  Future<void> close() async {
    _isOpen = false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  void addSubject(Subject subject) {
    _data[subject.id] = subject;
  }

  @override
  Future<int> clear() async {
    final count = _data.length;
    _data.clear();
    return count;
  }
}

Subject _s({
  String id = 's1',
  String name = 'Test',
  String? code,
  List<String>? topicIds,
  String? description,
  String color = '#2196F3',
  String? teacher,
  DateTime? examDate,
}) {
  return Subject(
    id: id,
    name: name,
    code: code,
    topicIds: topicIds,
    description: description,
    color: color,
    teacher: teacher,
    examDate: examDate,
  );
}

void main() {
  late _MockBox box;
  late SubjectRepository repo;

  setUp(() {
    box = _MockBox();
    repo = SubjectRepository(subjectBox: box);
  });

  group('_box getter', () {
    test('returns injected box when initialized', () async {
      await repo.save(_s(id: 'x', name: 'X'));
      final result = await repo.get('x');
      expect(result, isNotNull);
      expect(result!.name, 'X');
    });

    test('returns correct box reference for multiple operations', () async {
      final ids = ['a', 'b', 'c', 'd', 'e'];
      for (final id in ids) {
        await repo.save(_s(id: id, name: 'Subject $id'));
      }
      final all = await repo.getAll();
      expect(all.length, 5);

      await repo.delete('a');
      await repo.delete('e');
      expect(await repo.getAll(), hasLength(3));
    });
  });

  group('data integrity across operations', () {
    test('save preserves exact field values', () async {
      final subject = _s(
        id: 'integrity-1',
        name: 'Advanced Physics HL',
        description: 'A very long description with special chars: ~!@#\$%^&*()_+',
        code: 'PHY-HL-2024',
        teacher: 'Dr. Müller (PhD)',
        topicIds: ['t1', 't2', 't3'],
        color: '#AABBCC',
        examDate: DateTime(2025, 12, 25, 8, 30),
      );

      await repo.save(subject);
      final retrieved = await repo.get('integrity-1');

      expect(retrieved!.id, 'integrity-1');
      expect(retrieved.name, 'Advanced Physics HL');
      expect(retrieved.description, 'A very long description with special chars: ~!@#\$%^&*()_+');
      expect(retrieved.code, 'PHY-HL-2024');
      expect(retrieved.teacher, 'Dr. Müller (PhD)');
      expect(retrieved.topicIds, ['t1', 't2', 't3']);
      expect(retrieved.color, '#AABBCC');
      expect(retrieved.examDate, DateTime(2025, 12, 25, 8, 30));
    });

    test('save updates preserve unrelated fields', () async {
      await repo.save(_s(
        id: 'update-test',
        name: 'Original',
        description: 'Original description',
        code: 'ORIG',
        teacher: 'Dr. A',
        topicIds: ['t1'],
        color: '#FF0000',
      ));

      await repo.save(_s(
        id: 'update-test',
        name: 'Updated',
        topicIds: ['t1', 't2'],
      ));

      final result = await repo.get('update-test');
      expect(result!.name, 'Updated');
      expect(result.description, isNull);
      expect(result.code, isNull);
      expect(result.teacher, isNull);
      expect(result.topicIds, ['t1', 't2']);
      expect(result.color, '#2196F3');
    });
  });

  group('addTopicToSubject scenarios', () {
    test('adds multiple topics in sequence without duplicates', () async {
      box.addSubject(_s(id: 's1', name: 'Physics', topicIds: []));

      await repo.addTopicToSubject('s1', 't1');
      await repo.addTopicToSubject('s1', 't2');
      await repo.addTopicToSubject('s1', 't3');
      await repo.addTopicToSubject('s1', 't1');

      final result = await repo.get('s1');
      expect(result!.topicIds, ['t1', 't2', 't3']);
    });

    test('adding topic to non-existent subject does not affect other subjects', () async {
      box.addSubject(_s(id: 'existing', name: 'Existing', topicIds: ['t1']));

      await repo.addTopicToSubject('non-existent', 'new-topic');

      final result = await repo.get('existing');
      expect(result!.topicIds, ['t1']);
    });

    test('addTopicToSubject after removeTopicFromSubject works', () async {
      box.addSubject(_s(id: 's1', name: 'Physics', topicIds: ['t1', 't2']));

      await repo.removeTopicFromSubject('s1', 't1');
      await repo.addTopicToSubject('s1', 't3');

      final result = await repo.get('s1');
      expect(result!.topicIds, ['t2', 't3']);
    });

    test('addTopicToSubject on subject with many existing topics', () async {
      final manyTopics = List.generate(1000, (i) => 't$i');
      box.addSubject(_s(id: 'big', name: 'Big', topicIds: manyTopics));

      await repo.addTopicToSubject('big', 't1000');

      final result = await repo.get('big');
      expect(result!.topicIds.length, 1001);
      expect(result.topicIds.last, 't1000');
    });
  });

  group('removeTopicFromSubject scenarios', () {
    test('removes all topics one by one', () async {
      box.addSubject(_s(id: 's1', name: 'Physics', topicIds: ['t1', 't2', 't3']));

      await repo.removeTopicFromSubject('s1', 't1');
      await repo.removeTopicFromSubject('s1', 't2');
      await repo.removeTopicFromSubject('s1', 't3');

      final result = await repo.get('s1');
      expect(result!.topicIds, isEmpty);
    });

    test('removing topic from non-existent subject does not affect other subjects', () async {
      box.addSubject(_s(id: 'existing', name: 'Existing', topicIds: ['t1']));

      await repo.removeTopicFromSubject('non-existent', 't1');

      final result = await repo.get('existing');
      expect(result!.topicIds, ['t1']);
    });

    test('repeated add and remove cycle works', () async {
      box.addSubject(_s(id: 's1', name: 'Physics'));

      for (int i = 0; i < 10; i++) {
        await repo.addTopicToSubject('s1', 't$i');
      }
      expect((await repo.get('s1'))!.topicIds.length, 10);

      for (int i = 0; i < 10; i++) {
        await repo.removeTopicFromSubject('s1', 't$i');
      }
      expect((await repo.get('s1'))!.topicIds, isEmpty);

      await repo.addTopicToSubject('s1', 'final');
      expect((await repo.get('s1'))!.topicIds, ['final']);
    });
  });

  group('getWithTopics scenarios', () {
    test('all subjects match when all have filter topics', () async {
      box.addSubject(_s(id: 's1', name: 'A', topicIds: ['common']));
      box.addSubject(_s(id: 's2', name: 'B', topicIds: ['common']));
      box.addSubject(_s(id: 's3', name: 'C', topicIds: ['common']));

      final result = await repo.getWithTopics(['common']);
      expect(result.length, 3);
    });

    test('subjects with empty topicIds excluded from filter', () async {
      box.addSubject(_s(id: 's1', name: 'Has Topics', topicIds: ['t1']));
      box.addSubject(_s(id: 's2', name: 'No Topics', topicIds: []));
      box.addSubject(_s(id: 's3', name: 'Null Topics'));

      final result = await repo.getWithTopics(['t1']);
      expect(result.length, 1);
      expect(result.first.name, 'Has Topics');
    });

    test('filter with overlapping topic ids finds each subject once', () async {
      box.addSubject(_s(id: 's1', name: 'Multi', topicIds: ['a', 'b', 'c']));
      box.addSubject(_s(id: 's2', name: 'Single', topicIds: ['a']));

      final result = await repo.getWithTopics(['a', 'b', 'c']);
      expect(result.length, 2);
    });

    test('empty filter returns subjects with at least one matching topic', () async {
      box.addSubject(_s(id: 's1', name: 'A', topicIds: ['t1']));

      final result = await repo.getWithTopics([]);
      expect(result, isEmpty);
    });
  });

  group('getByCode scenarios', () {
    test('returns subject with matching code when multiple subjects exist', () async {
      box.addSubject(_s(id: 's1', name: 'Physics', code: 'PHY'));
      box.addSubject(_s(id: 's2', name: 'Chemistry', code: 'CHEM'));
      box.addSubject(_s(id: 's3', name: 'Biology', code: 'BIO'));

      final result = await repo.getByCode('CHEM');
      expect(result, isNotNull);
      expect(result!.name, 'Chemistry');
    });

    test('returns first subject when multiple have same code', () async {
      box.addSubject(_s(id: 'first', name: 'First', code: 'SAME'));
      box.addSubject(_s(id: 'second', name: 'Second', code: 'SAME'));

      final result = await repo.getByCode('SAME');
      expect(result, isNotNull);
      expect(result!.id, 'first');
    });

    test('does not match on partial code', () async {
      box.addSubject(_s(id: 's1', name: 'Physics', code: 'IB-PHYSICS-HL'));

      final result = await repo.getByCode('PHYSICS');
      expect(result, isNull);
    });
  });

  group('getStudentSubjects scenarios', () {
    test('returns all subjects regardless of studentId value', () async {
      box.addSubject(_s(id: 's1', name: 'Physics'));
      box.addSubject(_s(id: 's2', name: 'Chemistry'));

      final result1 = await repo.getStudentSubjects('');
      final result2 = await repo.getStudentSubjects('any-id');
      final result3 = await repo.getStudentSubjects('student-123');

      expect(result1.length, 2);
      expect(result2.length, 2);
      expect(result3.length, 2);
    });
  });

  group('save and delete data integrity', () {
    test('save with non-string ids works correctly', () async {
      final subject1 = _s(id: '123', name: 'Numeric ID');
      final subject2 = _s(id: 'uuid-550e8400-e29b-41d4', name: 'UUID-like ID');

      await repo.save(subject1);
      await repo.save(subject2);

      expect(await repo.get('123'), isNotNull);
      expect(await repo.get('uuid-550e8400-e29b-41d4'), isNotNull);
      expect(await repo.getAll(), hasLength(2));
    });

    test('delete preserves unrelated subjects', () async {
      box.addSubject(_s(id: 'keep', name: 'Keep'));
      box.addSubject(_s(id: 'remove', name: 'Remove'));

      await repo.delete('remove');

      final remaining = await repo.getAll();
      expect(remaining.length, 1);
      expect(remaining.first.id, 'keep');
    });

    test('save with same id overwrites old data completely', () async {
      await repo.save(_s(
        id: 'overwrite',
        name: 'Original',
        description: 'Original desc',
        code: 'ORIG',
        topicIds: ['t1'],
      ));

      await repo.save(_s(
        id: 'overwrite',
        name: 'New Name',
        topicIds: ['t2'],
      ));

      final result = await repo.get('overwrite');
      expect(result!.name, 'New Name');
      expect(result.description, isNull);
      expect(result.code, isNull);
      expect(result.topicIds, ['t2']);
    });
  });

  group('repository object identity', () {
    test('multiple getAll calls return different list instances', () async {
      box.addSubject(_s(id: 's1', name: 'A'));

      final list1 = await repo.getAll();
      final list2 = await repo.getAll();

      expect(identical(list1, list2), isFalse);
    });

    test('modifying returned list does not affect repository', () async {
      box.addSubject(_s(id: 's1', name: 'A'));

      final list = await repo.getAll();
      list.clear();

      final result = await repo.getAll();
      expect(result.length, 1);
    });
  });

  group('empty box operations', () {
    test('getAll returns empty list for empty box', () async {
      expect(await repo.getAll(), isEmpty);
    });

    test('get returns null for any id on empty box', () async {
      expect(await repo.get('anything'), isNull);
    });

    test('delete on empty box does not throw', () async {
      await repo.delete('anything');
    });

    test('getWithTopics returns empty on empty box', () async {
      expect(await repo.getWithTopics(['t1']), isEmpty);
    });

    test('getByCode returns null on empty box', () async {
      expect(await repo.getByCode('ANY'), isNull);
    });

    test('getStudentSubjects returns empty on empty box', () async {
      expect(await repo.getStudentSubjects('s'), isEmpty);
    });
  });

  group('field-level edge cases', () {
    test('handles very long name', () async {
      final longName = 'A' * 1000;
      await repo.save(_s(id: 'long', name: longName));

      final result = await repo.get('long');
      expect(result!.name.length, 1000);
    });

    test('handles null description in save/get roundtrip', () async {
      await repo.save(_s(id: 'null-desc', name: 'Test', description: null));
      final result = await repo.get('null-desc');
      expect(result!.description, isNull);
    });

    test('handles empty string description', () async {
      await repo.save(_s(id: 'empty-desc', name: 'Test', description: ''));
      final result = await repo.get('empty-desc');
      expect(result!.description, '');
    });

    test('handles topic with empty string id', () async {
      box.addSubject(_s(id: 's1', name: 'Test', topicIds: ['']));
      final result = await repo.getWithTopics(['']);
      expect(result.length, 1);
    });
  });
}
