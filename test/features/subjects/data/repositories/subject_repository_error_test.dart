import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/models/subject_model.dart';

Subject _s({
  String id = 's1',
  String name = 'Test',
  String? code,
  List<String>? topicIds,
  String? description,
}) {
  return Subject(
    id: id,
    name: name,
    code: code,
    topicIds: topicIds,
    description: description,
  );
}

class _Box implements Box<Subject> {
  final Map<String, Subject> _data = {};
  bool failOnValues = false;
  bool failOnGet = false;
  bool failOnPut = false;
  bool failOnDelete = false;

  void reset() {
    _data.clear();
    failOnValues = false;
    failOnGet = false;
    failOnPut = false;
    failOnDelete = false;
  }

  @override
  Iterable<Subject> get values {
    if (failOnValues) throw Exception('box values error');
    return _data.values.toList();
  }

  @override
  Subject? get(dynamic key, {Subject? defaultValue}) {
    if (failOnGet) throw Exception('box get error');
    return _data[key as String] ?? defaultValue;
  }

  @override
  Future<void> put(dynamic key, Subject value) async {
    if (failOnPut) throw Exception('box put error');
    _data[key as String] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    if (failOnDelete) throw Exception('box delete error');
    _data.remove(key as String);
  }

  @override
  bool containsKey(dynamic key) => _data.containsKey(key as String);

  @override
  Iterable<String> get keys => _data.keys;

  @override
  String get name => 'error-box';

  @override
  bool get isOpen => true;

  @override
  Future<void> close() async {}

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  late _Box box;
  late SubjectRepository repo;

  setUp(() {
    box = _Box();
    repo = SubjectRepository(subjectBox: box);
  });

  tearDown(() {
    box.reset();
  });

  group('error propagation from box operations', () {
    test('getAll propagates values error', () async {
      box.failOnValues = true;
      expect(repo.getAll(), throwsException);
    });

    test('get propagates get error', () async {
      box.failOnGet = true;
      expect(repo.get('x'), throwsException);
    });

    test('save propagates put error', () async {
      box.failOnPut = true;
      expect(repo.save(_s()), throwsException);
    });

    test('delete propagates delete error', () async {
      box.failOnDelete = true;
      expect(repo.delete('x'), throwsException);
    });

    test('getWithTopics propagates values error', () async {
      box.failOnValues = true;
      expect(repo.getWithTopics(['t1']), throwsException);
    });

    test('getByCode propagates values error', () async {
      box.failOnValues = true;
      expect(repo.getByCode('c'), throwsException);
    });

    test('getStudentSubjects propagates values error', () async {
      box.failOnValues = true;
      expect(repo.getStudentSubjects('s'), throwsException);
    });

    test('addTopicToSubject propagates get error', () async {
      box.failOnGet = true;
      expect(repo.addTopicToSubject('x', 't'), throwsException);
    });

    test('addTopicToSubject propagates put error from save', () async {
      box._data['s1'] = _s(id: 's1', name: 'Test', topicIds: ['t1']);
      box.failOnPut = true;
      expect(repo.addTopicToSubject('s1', 't2'), throwsException);
    });

    test('removeTopicFromSubject propagates get error', () async {
      box.failOnGet = true;
      expect(repo.removeTopicFromSubject('x', 't'), throwsException);
    });

    test('removeTopicFromSubject propagates put error from save', () async {
      box._data['s1'] = _s(id: 's1', name: 'Test', topicIds: ['t1']);
      box.failOnPut = true;
      expect(repo.removeTopicFromSubject('s1', 't1'), throwsException);
    });
  });

  group('recovery after box error', () {
    test('repository works after values error is resolved', () async {
      box.failOnValues = true;
      expect(repo.getAll(), throwsException);
      box.failOnValues = false;
      box._data['s1'] = _s(id: 's1', name: 'Physics');
      final result = await repo.getAll();
      expect(result.length, 1);
      expect(result.first.name, 'Physics');
    });

    test('repository works after put error is resolved', () async {
      box.failOnPut = true;
      expect(repo.save(_s(id: 's1', name: 'Physics')), throwsException);
      box.failOnPut = false;
      await repo.save(_s(id: 's1', name: 'Physics'));
      final result = await repo.get('s1');
      expect(result, isNotNull);
      expect(result!.name, 'Physics');
    });
  });

  group('getWithTopics edge cases', () {
    test('subject with duplicate topicIds in filter matches once', () async {
      box._data['s1'] = _s(id: 's1', name: 'A', topicIds: ['t1', 't2', 't1']);
      final result = await repo.getWithTopics(['t1']);
      expect(result.length, 1);
    });

    test('empty box with non-empty filter returns empty', () async {
      final result = await repo.getWithTopics(['t1', 't2']);
      expect(result, isEmpty);
    });

    test('no subjects match any filter topic', () async {
      box._data['s1'] = _s(id: 's1', name: 'A', topicIds: ['t1']);
      box._data['s2'] = _s(id: 's2', name: 'B', topicIds: ['t2']);
      final result = await repo.getWithTopics(['t99']);
      expect(result, isEmpty);
    });

    test('filter with duplicate topic IDs returns correct results', () async {
      box._data['s1'] = _s(id: 's1', name: 'A', topicIds: ['t1']);
      final result = await repo.getWithTopics(['t1', 't1', 't1']);
      expect(result.length, 1);
    });
  });

  group('addTopicToSubject edge cases', () {
    test('adding the same topic twice is idempotent', () async {
      box._data['s1'] = _s(id: 's1', name: 'A', topicIds: ['t1']);
      await repo.addTopicToSubject('s1', 't1');
      await repo.addTopicToSubject('s1', 't1');
      final s = await repo.get('s1');
      expect(s!.topicIds, ['t1']);
    });

    test('adding topic to subject with no initial topics', () async {
      box._data['s1'] = _s(id: 's1', name: 'A');
      await repo.addTopicToSubject('s1', 't1');
      final s = await repo.get('s1');
      expect(s!.topicIds, ['t1']);
    });

    test('addTopicToSubject on subject with many topics works', () async {
      final manyTopics = List.generate(100, (i) => 't$i');
      box._data['s1'] = _s(id: 's1', name: 'A', topicIds: manyTopics);
      await repo.addTopicToSubject('s1', 'new-topic');
      final s = await repo.get('s1');
      expect(s!.topicIds.length, 101);
      expect(s.topicIds.last, 'new-topic');
    });
  });

  group('removeTopicFromSubject edge cases', () {
    test('removing non-existent topic from empty topic list does nothing', () async {
      box._data['s1'] = _s(id: 's1', name: 'A');
      await repo.removeTopicFromSubject('s1', 't1');
      final s = await repo.get('s1');
      expect(s!.topicIds, isEmpty);
    });

    test('removing twice is idempotent', () async {
      box._data['s1'] = _s(id: 's1', name: 'A', topicIds: ['t1']);
      await repo.removeTopicFromSubject('s1', 't1');
      await repo.removeTopicFromSubject('s1', 't1');
      final s = await repo.get('s1');
      expect(s!.topicIds, isEmpty);
    });
  });

  group('getByCode edge cases', () {
    test('returns null when all subjects have null code', () async {
      box._data['s1'] = _s(id: 's1', name: 'A');
      box._data['s2'] = _s(id: 's2', name: 'B');
      final result = await repo.getByCode('ANY');
      expect(result, isNull);
    });

    test('returns first match when code appears multiple times', () async {
      box._data['s1'] = _s(id: 's1', name: 'First', code: 'SAME');
      box._data['s2'] = _s(id: 's2', name: 'Second', code: 'SAME');
      final result = await repo.getByCode('SAME');
      expect(result, isNotNull);
      expect(result!.name, 'First');
    });

    test('ignores subjects with null code when matching', () async {
      box._data['s1'] = _s(id: 's1', name: 'No Code');
      box._data['s2'] = _s(id: 's2', name: 'With Code', code: 'C-42');
      final result = await repo.getByCode('C-42');
      expect(result, isNotNull);
      expect(result!.name, 'With Code');
    });

    test('empty code string is matched exactly', () async {
      box._data['s1'] = _s(id: 's1', name: 'Empty Code', code: '');
      final result = await repo.getByCode('');
      expect(result, isNotNull);
      expect(result!.name, 'Empty Code');
    });
  });

  group('delete edge cases', () {
    test('delete from empty box does not throw', () async {
      await repo.delete('any');
    });

    test('delete on already-deleted id is safe', () async {
      box._data['s1'] = _s(id: 's1', name: 'A');
      await repo.delete('s1');
      await repo.delete('s1');
      expect(await repo.getAll(), isEmpty);
    });
  });

  group('save edge cases', () {
    test('save updates subject with same id multiple times', () async {
      for (int i = 1; i <= 5; i++) {
        await repo.save(_s(id: 's1', name: 'Update $i'));
      }
      final s = await repo.get('s1');
      expect(s!.name, 'Update 5');
    });
  });

  group('constructor edge cases', () {
    test('default constructor creates uninitialized repository', () {
      final r = SubjectRepository();
      expect(r.getAll, throwsA(isA<StateError>()));
    });

    test('constructor with explicit null creates uninitialized repository', () {
      final r = SubjectRepository(subjectBox: null);
      expect(r.getAll, throwsA(isA<StateError>()));
    });

    test('constructor with box creates ready repository', () async {
      final r = SubjectRepository(subjectBox: box);
      expect(await r.getAll(), isEmpty);
    });
  });
}
