import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/models/subject_model.dart';

class MockComprehensiveBox implements Box<Subject> {
  final Map<String, Subject> _storage = {};
  bool _isOpen = true;
  bool failOnValues = false;
  bool failOnGet = false;
  bool failOnPut = false;
  bool failOnDelete = false;

  @override
  Iterable<Subject> get values {
    if (failOnValues) throw Exception('box values error');
    return _storage.values.toList();
  }

  @override
  Subject? get(dynamic key, {Subject? defaultValue}) {
    if (failOnGet) throw Exception('box get error');
    return _storage[key as String] ?? defaultValue;
  }

  @override
  Future<void> put(dynamic key, Subject value) async {
    if (failOnPut) throw Exception('box put error');
    _storage[key as String] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    if (failOnDelete) throw Exception('box delete error');
    _storage.remove(key as String);
  }

  @override
  bool containsKey(dynamic key) => _storage.containsKey(key as String);

  @override
  Iterable<String> get keys => _storage.keys;

  @override
  String get name => 'comprehensive-mock-box';

  @override
  bool get isOpen => _isOpen;

  @override
  Future<void> close() async {
    _isOpen = false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  void addSubject(Subject subject) {
    _storage[subject.id] = subject;
  }

  void clearStorage() {
    _storage.clear();
  }
}

Subject _subject({
  String id = 's1',
  String name = 'Test',
  String? code,
  List<String>? topicIds,
  String? description,
  String? syllabus,
  String? teacher,
  String color = '#2196F3',
  DateTime? createdAt,
  DateTime? examDate,
}) {
  return Subject(
    id: id,
    name: name,
    code: code,
    topicIds: topicIds,
    description: description,
    syllabus: syllabus,
    teacher: teacher,
    color: color,
    createdAt: createdAt,
    examDate: examDate,
  );
}

void main() {
  late MockComprehensiveBox box;
  late SubjectRepository repo;

  setUp(() {
    box = MockComprehensiveBox();
    repo = SubjectRepository(subjectBox: box);
  });

  group('_box getter behavior', () {
    test('getter returns the injected box when initialized', () async {
      await repo.save(_subject(id: 'test', name: 'Test'));
      final saved = await repo.get('test');
      expect(saved, isNotNull);
    });

    test('getter throws StateError when box is null for getAll', () {
      final r = SubjectRepository(subjectBox: null);
      expect(r.getAll, throwsA(isA<StateError>()));
    });

    test('StateError message is descriptive for all methods', () {
      final r = SubjectRepository(subjectBox: null);
      expect(
        () => r.getAll(),
        throwsA(
          predicate((e) => e.toString().contains('SubjectRepository not initialized')),
        ),
      );
    });
  });

  group('init() method edge cases', () {
    test('init() replaces injected box', () async {
      final injected = MockComprehensiveBox();
      injected.addSubject(_subject(id: 'pre-existing', name: 'Pre-existing'));
      final r = SubjectRepository(subjectBox: injected);

      final before = await r.getAll();
      expect(before.length, 1);

      final freshBox = MockComprehensiveBox();
      final r2 = SubjectRepository(subjectBox: freshBox);
      await r2.save(_subject(id: 'new', name: 'New'));

      final after = await r2.getAll();
      expect(after.length, 1);
      expect(after.first.name, 'New');
    });

    test('init does not affect an already-ready repository', () async {
      box.addSubject(_subject(id: 'existing', name: 'Existing'));
      await repo.save(_subject(id: 'new-one', name: 'New'));

      final all = await repo.getAll();
      expect(all.length, 2);
    });
  });

  group('CRUD with empty and special identifiers', () {
    test('save with empty string id', () async {
      final subject = _subject(id: '', name: 'Empty ID');
      await repo.save(subject);
      final retrieved = await repo.get('');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Empty ID');
    });

    test('get with empty string id returns null when not saved', () async {
      final result = await repo.get('');
      expect(result, isNull);
    });

    test('delete with empty string id is safe', () async {
      await repo.delete('');
    });

    test('getByCode with empty string matches empty code', () async {
      box.addSubject(_subject(id: 'empty-code', name: 'No Code', code: ''));
      final result = await repo.getByCode('');
      expect(result, isNotNull);
      expect(result!.name, 'No Code');
    });

    test('getById with whitespace-padded id', () async {
      box.addSubject(_subject(id: 'real-id', name: 'Real'));
      final result = await repo.get('real-id ');
      expect(result, isNull);
    });
  });

  group('stress and bulk operations', () {
    test('getAll with many subjects', () async {
      for (int i = 0; i < 100; i++) {
        box.addSubject(_subject(id: 's$i', name: 'Subject $i'));
      }
      final all = await repo.getAll();
      expect(all.length, 100);
    });

    test('sequential saves and deletes', () async {
      for (int i = 0; i < 50; i++) {
        await repo.save(_subject(id: 's$i', name: 'Subject $i'));
      }
      expect(await repo.getAll(), hasLength(50));

      for (int i = 0; i < 50; i++) {
        await repo.delete('s$i');
      }
      expect(await repo.getAll(), isEmpty);
    });

    test('getWithTopics with many subjects and many topics', () async {
      for (int i = 0; i < 50; i++) {
        final topicIds = List.generate(20, (j) => 'topic-${i * 20 + j}');
        box.addSubject(_subject(id: 's$i', name: 'Subject $i', topicIds: topicIds));
      }
      final result = await repo.getWithTopics(['topic-5', 'topic-105']);
      expect(result.length, 2);
    });

    test('addTopicToSubject adds to subject with many existing topics', () async {
      final manyTopics = List.generate(500, (i) => 't$i');
      box.addSubject(_subject(id: 'big', name: 'Big', topicIds: manyTopics));
      await repo.addTopicToSubject('big', 't500');
      final s = await repo.get('big');
      expect(s!.topicIds.length, 501);
      expect(s.topicIds.last, 't500');
    });
  });

  group('getWithTopics extra edge cases', () {
    test('returns subjects where any topicId matches', () async {
      box.addSubject(_subject(id: 's1', name: 'A', topicIds: ['shared', 'unique-a']));
      box.addSubject(_subject(id: 's2', name: 'B', topicIds: ['shared', 'unique-b']));

      final result = await repo.getWithTopics(['shared']);
      expect(result.length, 2);
    });

    test('returns empty for empty topicIds list in all subjects', () async {
      box.addSubject(_subject(id: 's1', name: 'A', topicIds: []));
      box.addSubject(_subject(id: 's2', name: 'B', topicIds: []));

      final result = await repo.getWithTopics(['anything']);
      expect(result, isEmpty);
    });

    test('subject matching all filter topics still returned once', () async {
      box.addSubject(_subject(id: 's1', name: 'A', topicIds: ['t1', 't2', 't3']));

      final result = await repo.getWithTopics(['t1', 't2', 't3']);
      expect(result.length, 1);
    });
  });

  group('addTopicToSubject extra edge cases', () {
    test('addTopicToSubject on subject with null topicIds defaults to empty', () async {
      box.addSubject(_subject(id: 's1', name: 'A'));
      await repo.addTopicToSubject('s1', 't1');
      final s = await repo.get('s1');
      expect(s!.topicIds, ['t1']);
    });

    test('addTopicToSubject is idempotent for same topic', () async {
      box.addSubject(_subject(id: 's1', name: 'A', topicIds: ['t1']));
      await repo.addTopicToSubject('s1', 't1');
      await repo.addTopicToSubject('s1', 't1');
      await repo.addTopicToSubject('s1', 't1');
      final s = await repo.get('s1');
      expect(s!.topicIds, ['t1']);
    });

    test('addTopicToSubject non-existent subject does not throw', () async {
      await repo.addTopicToSubject('non-existent', 't1');
    });
  });

  group('removeTopicFromSubject extra edge cases', () {
    test('removing last topic leaves empty list', () async {
      box.addSubject(_subject(id: 's1', name: 'A', topicIds: ['only']));
      await repo.removeTopicFromSubject('s1', 'only');
      final s = await repo.get('s1');
      expect(s!.topicIds, isEmpty);
    });

    test('removing topic from subject with null topicIds does nothing', () async {
      box.addSubject(_subject(id: 's1', name: 'A'));
      await repo.removeTopicFromSubject('s1', 't1');
      final s = await repo.get('s1');
      expect(s!.topicIds, isEmpty);
    });
  });

  group('getByCode extra edge cases', () {
    test('subjects with same code as another field value not miscounted', () async {
      box.addSubject(_subject(id: 's1', name: 'Physics', code: 'PHY'));
      box.addSubject(_subject(id: 's2', name: 'Chemistry', code: 'CHEM'));
      final result = await repo.getByCode('PHY');
      expect(result, isNotNull);
      expect(result!.name, 'Physics');
    });
  });

  group('round-trip and state consistency', () {
    test('save -> get -> save (update) -> get preserves all fields', () async {
      final s1 = _subject(id: 'rt1', name: 'First', code: 'C1', topicIds: ['t1']);
      await repo.save(s1);
      final g1 = await repo.get('rt1');
      expect(g1!.name, 'First');

      final s2 = _subject(id: 'rt1', name: 'Second', code: 'C2', topicIds: ['t1', 't2']);
      await repo.save(s2);
      final g2 = await repo.get('rt1');
      expect(g2!.name, 'Second');
      expect(g2!.code, 'C2');
      expect(g2!.topicIds, ['t1', 't2']);
    });

    test('save -> delete -> save restores with new data', () async {
      await repo.save(_subject(id: 'cyclic', name: 'Version 1'));
      await repo.delete('cyclic');
      expect(await repo.get('cyclic'), isNull);

      await repo.save(_subject(id: 'cyclic', name: 'Version 2', code: 'V2'));
      final restored = await repo.get('cyclic');
      expect(restored, isNotNull);
      expect(restored!.name, 'Version 2');
      expect(restored.code, 'V2');
    });

    test('getAll returns consistent results after multiple operations', () async {
      for (int i = 0; i < 10; i++) {
        await repo.save(_subject(id: 's$i', name: 'S$i'));
      }
      expect(await repo.getAll(), hasLength(10));

      await repo.delete('s0');
      await repo.delete('s9');
      expect(await repo.getAll(), hasLength(8));

      await repo.save(_subject(id: 's0', name: 'S0-again'));
      expect(await repo.getAll(), hasLength(9));
    });

    test('getStudentSubjects returns same as getAll', () async {
      box.addSubject(_subject(id: 'a', name: 'A'));
      box.addSubject(_subject(id: 'b', name: 'B'));

      final all = await repo.getAll();
      final student = await repo.getStudentSubjects('student-x');

      expect(student.length, all.length);
      expect(student.map((s) => s.id), unorderedEquals(all.map((s) => s.id)));
    });
  });

  group('box interaction error propagation', () {
    test('getAll propagates box exception', () {
      box.failOnValues = true;
      expect(repo.getAll(), throwsException);
    });

    test('get propagates box exception', () {
      box.failOnGet = true;
      expect(repo.get('x'), throwsException);
    });

    test('save propagates box exception', () {
      box.failOnPut = true;
      expect(repo.save(_subject()), throwsException);
    });

    test('delete propagates box exception', () {
      box.failOnDelete = true;
      expect(repo.delete('x'), throwsException);
    });

    test('getWithTopics propagates box values exception', () {
      box.failOnValues = true;
      expect(repo.getWithTopics(['t1']), throwsException);
    });

    test('getByCode propagates box values exception', () {
      box.failOnValues = true;
      expect(repo.getByCode('c'), throwsException);
    });

    test('getStudentSubjects propagates box values exception', () {
      box.failOnValues = true;
      expect(repo.getStudentSubjects('s'), throwsException);
    });

    test('addTopicToSubject propagates box get exception', () {
      box.failOnGet = true;
      expect(repo.addTopicToSubject('x', 't'), throwsException);
    });

    test('addTopicToSubject propagates box put exception from save', () async {
      box.addSubject(_subject(id: 's1', name: 'Test', topicIds: ['t1']));
      box.failOnPut = true;
      expect(repo.addTopicToSubject('s1', 't2'), throwsException);
    });

    test('removeTopicFromSubject propagates box get exception', () {
      box.failOnGet = true;
      expect(repo.removeTopicFromSubject('x', 't'), throwsException);
    });

    test('removeTopicFromSubject propagates box put exception from save', () async {
      box.addSubject(_subject(id: 's1', name: 'Test', topicIds: ['t1']));
      box.failOnPut = true;
      expect(repo.removeTopicFromSubject('s1', 't1'), throwsException);
    });
  });
}
