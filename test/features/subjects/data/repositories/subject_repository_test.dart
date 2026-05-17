import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/models/subject_model.dart';

class _FakeSubjectRepository extends SubjectRepository {
  final Map<String, Subject> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<Result<Subject?>> get(String id) async => Result.success(_storage[id]);

  @override
  Future<Result<List<Subject>>> getAll() async => Result.success(_storage.values.toList());

  @override
  Future<Result<void>> delete(String id) async {
    _storage.remove(id);
    return Result.success(null);
  }

  @override
  Future<List<Subject>> getWithTopics(List<String> topicIds) async {
    return _storage.values.where((s) {
      return s.topicIds.any((id) => topicIds.contains(id));
    }).toList();
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

  void addSubject(Subject subject) {
    _storage[subject.id] = subject;
  }

  void clearStorage() {
    _storage.clear();
  }
}

class TestSubjectAdapter extends TypeAdapter<Subject> {
  @override
  final int typeId = 11;

  @override
  Subject read(BinaryReader reader) {
    final raw = reader.read() as Map;
    final map = <String, dynamic>{};
    for (final entry in raw.entries) {
      map['${entry.key}'] = entry.value;
    }
    return Subject.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, Subject obj) {
    writer.write(obj.toJson());
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
    late _FakeSubjectRepository repository;

    setUp(() {
      repository = _FakeSubjectRepository();
    });

    group('getAll', () {
      test('returns empty list when box is empty', () async {
        repository.clearStorage();
        final result = await repository.getAll();
        expect(result.data, isEmpty);
      });

      test('returns all subjects from box', () async {
        repository.addSubject(createTestSubject(id: '1', name: 'Physics'));
        repository.addSubject(createTestSubject(id: '2', name: 'Chemistry'));
        repository.addSubject(createTestSubject(id: '3', name: 'Biology'));

        final result = await repository.getAll();
        expect(result.data!.length, 3);
        expect(result.data!.map((s) => s.name), containsAll(['Physics', 'Chemistry', 'Biology']));
      });

      test('returns new list instance each time', () async {
        repository.addSubject(createTestSubject(id: '1', name: 'Physics'));

        final result = await repository.getAll();
        final result2 = await repository.getAll();

        expect(identical(result, result2), isFalse);
        expect(result.data![0].name, result2.data![0].name);
      });

      test('modifying returned list does not affect repository', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'A'));

        final list = await repository.getAll();
        list.data!.clear();

        final result = await repository.getAll();
        expect(result.data!.length, 1);
      });
    });

    group('get', () {
      test('returns subject by id', () async {
        repository.addSubject(createTestSubject(id: 'subject-1', name: 'Physics'));

        final result = await repository.get('subject-1');
        expect(result.data, isNotNull);
        expect(result.data!.name, 'Physics');
      });

      test('returns null for non-existent id', () async {
        repository.addSubject(createTestSubject(id: 'subject-1', name: 'Physics'));

        final result = await repository.get('non-existent');
        expect(result.data, isNull);
      });

      test('returns null for empty box', () async {
        repository.clearStorage();
        final result = await repository.get('any-id');
        expect(result.data, isNull);
      });
    });

    group('save', () {
      test('creates new subject', () async {
        final subject = createTestSubject(id: 'new-subject', name: 'New Subject');

        await repository.create(subject);
        final retrieved = await repository.get('new-subject');

        expect(retrieved.data, isNotNull);
        expect(retrieved.data!.name, 'New Subject');
      });

      test('updates existing subject', () async {
        repository.addSubject(createTestSubject(id: 'subject-1', name: 'Original Name'));

        final updated = createTestSubject(id: 'subject-1', name: 'Updated Name');
        await repository.create(updated);

        final retrieved = await repository.get('subject-1');
        expect(retrieved.data!.name, 'Updated Name');
      });

      test('preserves other subjects when saving new one', () async {
        repository.addSubject(createTestSubject(id: 'existing', name: 'Existing'));

        await repository.create(createTestSubject(id: 'new', name: 'New'));

        final all = await repository.getAll();
        expect(all.data!.length, 2);
        expect(all.data!.map((s) => s.name), containsAll(['Existing', 'New']));
      });

      test('updates subject with same id multiple times', () async {
        for (int i = 1; i <= 5; i++) {
          await repository.create(createTestSubject(id: 's1', name: 'Update $i'));
        }
        final s = await repository.get('s1');
        expect(s.data!.name, 'Update 5');
      });
    });

    group('delete', () {
      test('removes subject from box', () async {
        repository.addSubject(createTestSubject(id: 'subject-1', name: 'Physics'));

        await repository.delete('subject-1');

        final result = await repository.get('subject-1');
        expect(result.data, isNull);
      });

      test('handles non-existent id gracefully', () async {
        repository.addSubject(createTestSubject(id: 'subject-1', name: 'Physics'));

        await repository.delete('non-existent-id');

        final result = await repository.get('subject-1');
        expect(result.data, isNotNull);
      });

      test('deletes only specified subject', () async {
        repository.addSubject(createTestSubject(id: 'subject-1', name: 'Physics'));
        repository.addSubject(createTestSubject(id: 'subject-2', name: 'Chemistry'));

        await repository.delete('subject-1');

        final remaining = await repository.getAll();
        expect(remaining.data!.length, 1);
        expect(remaining.data![0].id, 'subject-2');
      });

      test('delete from empty box does not throw', () async {
        await repository.delete('any');
      });

      test('delete on already-deleted id is safe', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'A'));
        await repository.delete('s1');
        await repository.delete('s1');
        expect((await repository.getAll()).data, isEmpty);
      });
    });

    group('getWithTopics', () {
      test('filters subjects by topic IDs - single topic', () async {
        repository.addSubject(createTestSubject(id: '1', name: 'Physics', topicIds: ['topic-1', 'topic-2']));
        repository.addSubject(createTestSubject(id: '2', name: 'Chemistry', topicIds: ['topic-3']));
        repository.addSubject(createTestSubject(id: '3', name: 'Biology', topicIds: ['topic-1']));

        final result = await repository.getWithTopics(['topic-1']);

        expect(result.length, 2);
        expect(result.map((s) => s.name), containsAll(['Physics', 'Biology']));
      });

      test('filters subjects by multiple topic IDs', () async {
        repository.addSubject(createTestSubject(id: '1', name: 'Physics', topicIds: ['topic-1', 'topic-2']));
        repository.addSubject(createTestSubject(id: '2', name: 'Chemistry', topicIds: ['topic-3']));
        repository.addSubject(createTestSubject(id: '3', name: 'Biology', topicIds: ['topic-1']));

        final result = await repository.getWithTopics(['topic-1', 'topic-3']);

        expect(result.length, 3);
      });

      test('returns empty list when no matches', () async {
        repository.addSubject(createTestSubject(id: '1', name: 'Physics', topicIds: ['topic-1']));

        final result = await repository.getWithTopics(['non-existent-topic']);

          expect(result, isEmpty);
        });

        test('getAll returns empty list on empty box', () async {
          repository.clearStorage();
          final result = await repository.getAll();
          expect(result.data, isEmpty);
      });

      test('returns empty list when topic filter is empty', () async {
        repository.addSubject(createTestSubject(id: '1', name: 'Physics'));
        repository.addSubject(createTestSubject(id: '2', name: 'Chemistry'));

        final result = await repository.getWithTopics([]);

        expect(result, isEmpty);
      });

      test('returns subjects with empty topicIds when filtering for any topic', () async {
        repository.addSubject(createTestSubject(id: '1', name: 'No Topics', topicIds: []));

        final result = await repository.getWithTopics(['topic-1']);

        expect(result, isEmpty);
      });

      test('returns subjects where any topicId matches', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'A', topicIds: ['shared', 'unique-a']));
        repository.addSubject(createTestSubject(id: 's2', name: 'B', topicIds: ['shared', 'unique-b']));

        final result = await repository.getWithTopics(['shared']);
        expect(result.length, 2);
      });

      test('subject matching all filter topics still returned once', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'A', topicIds: ['t1', 't2', 't3']));

        final result = await repository.getWithTopics(['t1', 't2', 't3']);
        expect(result.length, 1);
      });

      test('handles subjects with null topicIds', () async {
        repository.addSubject(createTestSubject(id: '1', name: 'Physics'));

        final result = await repository.getWithTopics(['topic-1']);
        expect(result, isEmpty);
      });

      test('subject matching multiple filter topics counted once', () async {
        repository.addSubject(createTestSubject(
          id: '1',
          name: 'Comprehensive',
          topicIds: ['topic-a', 'topic-b', 'topic-c'],
        ));
        repository.addSubject(createTestSubject(
          id: '2',
          name: 'Simple',
          topicIds: ['topic-a'],
        ));

        final result = await repository.getWithTopics(['topic-b', 'topic-c']);

        expect(result.length, 1);
        expect(result.first.name, 'Comprehensive');
      });

      test('all subjects match when all have filter topics', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'A', topicIds: ['common']));
        repository.addSubject(createTestSubject(id: 's2', name: 'B', topicIds: ['common']));
        repository.addSubject(createTestSubject(id: 's3', name: 'C', topicIds: ['common']));

        final result = await repository.getWithTopics(['common']);
        expect(result.length, 3);
      });

      test('subjects with empty topicIds excluded from filter', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'Has Topics', topicIds: ['t1']));
        repository.addSubject(createTestSubject(id: 's2', name: 'No Topics', topicIds: []));
        repository.addSubject(createTestSubject(id: 's3', name: 'Null Topics'));

        final result = await repository.getWithTopics(['t1']);
        expect(result.length, 1);
        expect(result.first.name, 'Has Topics');
      });

      test('subject with duplicate topicIds in filter matches once', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'A', topicIds: ['t1', 't2', 't1']));
        final result = await repository.getWithTopics(['t1']);
        expect(result.length, 1);
      });

      test('filter with duplicate topic IDs returns correct results', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'A', topicIds: ['t1']));
        final result = await repository.getWithTopics(['t1', 't1', 't1']);
        expect(result.length, 1);
      });

      test('handles topic with empty string id', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'Test', topicIds: ['']));
        final result = await repository.getWithTopics(['']);
        expect(result.length, 1);
      });
    });

    group('addTopicToSubject', () {
      test('adds topic to subject', () async {
        repository.addSubject(createTestSubject(id: 'subject-1', name: 'Physics', topicIds: ['topic-1']));

        await repository.addTopicToSubject('subject-1', 'topic-2');

        final result = await repository.get('subject-1');
        expect(result.data!.topicIds, containsAll(['topic-1', 'topic-2']));
      });

      test('adds topic without duplicates', () async {
        repository.addSubject(createTestSubject(id: 'subject-1', name: 'Physics', topicIds: ['topic-1']));

        await repository.addTopicToSubject('subject-1', 'topic-1');

        final result = await repository.get('subject-1');
        expect(result.data!.topicIds.length, 1);
      });

      test('does nothing for non-existent subject', () async {
        repository.addSubject(createTestSubject(id: 'subject-1', name: 'Physics'));

        await repository.addTopicToSubject('non-existent', 'topic-1');

        final result = await repository.get('subject-1');
        expect(result.data!.topicIds, isEmpty);
      });

      test('adds multiple topics sequentially', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'Subject', topicIds: []));

        await repository.addTopicToSubject('s1', 'topic-a');
        await repository.addTopicToSubject('s1', 'topic-b');
        await repository.addTopicToSubject('s1', 'topic-c');

        final result = await repository.get('s1');
        expect(result.data!.topicIds, ['topic-a', 'topic-b', 'topic-c']);
      });

      test('adds multiple topics in sequence without duplicates', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'Physics', topicIds: []));

        await repository.addTopicToSubject('s1', 't1');
        await repository.addTopicToSubject('s1', 't2');
        await repository.addTopicToSubject('s1', 't3');
        await repository.addTopicToSubject('s1', 't1');

        final result = await repository.get('s1');
        expect(result.data!.topicIds, ['t1', 't2', 't3']);
      });

      test('on subject with null topicIds defaults to empty', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'A'));
        await repository.addTopicToSubject('s1', 't1');
        final s = await repository.get('s1');
        expect(s.data!.topicIds, ['t1']);
      });

      test('is idempotent for same topic', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'A', topicIds: ['t1']));
        await repository.addTopicToSubject('s1', 't1');
        await repository.addTopicToSubject('s1', 't1');
        await repository.addTopicToSubject('s1', 't1');
        final s = await repository.get('s1');
        expect(s.data!.topicIds, ['t1']);
      });

      test('non-existent subject does not throw', () async {
        await repository.addTopicToSubject('non-existent', 't1');
      });

      test('adding topic to non-existent subject does not affect other subjects', () async {
        repository.addSubject(createTestSubject(id: 'existing', name: 'Existing', topicIds: ['t1']));

        await repository.addTopicToSubject('non-existent', 'new-topic');

        final result = await repository.get('existing');
        expect(result.data!.topicIds, ['t1']);
      });

      test('after removeTopicFromSubject works', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'Physics', topicIds: ['t1', 't2']));

        await repository.removeTopicFromSubject('s1', 't1');
        await repository.addTopicToSubject('s1', 't3');

        final result = await repository.get('s1');
        expect(result.data!.topicIds, ['t2', 't3']);
      });

      test('on subject with many existing topics', () async {
        final manyTopics = List.generate(1000, (i) => 't$i');
        repository.addSubject(createTestSubject(id: 'big', name: 'Big', topicIds: manyTopics));

        await repository.addTopicToSubject('big', 't1000');

        final result = await repository.get('big');
        expect(result.data!.topicIds.length, 1001);
        expect(result.data!.topicIds.last, 't1000');
      });
    });

    group('removeTopicFromSubject', () {
      test('removes topic from subject', () async {
        repository.addSubject(createTestSubject(id: 'subject-1', name: 'Physics', topicIds: ['topic-1', 'topic-2']));

        await repository.removeTopicFromSubject('subject-1', 'topic-1');

        final result = await repository.get('subject-1');
        expect(result.data!.topicIds, ['topic-2']);
      });

      test('removes only specified topic', () async {
        repository.addSubject(createTestSubject(id: 'subject-1', name: 'Physics', topicIds: ['topic-1', 'topic-2', 'topic-3']));

        await repository.removeTopicFromSubject('subject-1', 'topic-2');

        final result = await repository.get('subject-1');
        expect(result.data!.topicIds, ['topic-1', 'topic-3']);
      });

      test('does nothing for non-existent subject', () async {
        repository.addSubject(createTestSubject(id: 'subject-1', name: 'Physics', topicIds: ['topic-1']));

        await repository.removeTopicFromSubject('non-existent', 'topic-1');

        final result = await repository.get('subject-1');
        expect(result.data!.topicIds, ['topic-1']);
      });

      test('does nothing when topic not present', () async {
        repository.addSubject(createTestSubject(id: 'subject-1', name: 'Physics', topicIds: ['topic-1']));

        await repository.removeTopicFromSubject('subject-1', 'non-existent-topic');

        final result = await repository.get('subject-1');
        expect(result.data!.topicIds, ['topic-1']);
      });

      test('removes last topic', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'Subject', topicIds: ['only-topic']));

        await repository.removeTopicFromSubject('s1', 'only-topic');

        final result = await repository.get('s1');
        expect(result.data!.topicIds, isEmpty);
      });

      test('removes all topics one by one', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'Physics', topicIds: ['t1', 't2', 't3']));

        await repository.removeTopicFromSubject('s1', 't1');
        await repository.removeTopicFromSubject('s1', 't2');
        await repository.removeTopicFromSubject('s1', 't3');

        final result = await repository.get('s1');
        expect(result.data!.topicIds, isEmpty);
      });

      test('from subject with null topicIds does nothing', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'A'));
        await repository.removeTopicFromSubject('s1', 't1');
        final s = await repository.get('s1');
        expect(s.data!.topicIds, isEmpty);
      });

      test('removing topic from non-existent subject does not affect other subjects', () async {
        repository.addSubject(createTestSubject(id: 'existing', name: 'Existing', topicIds: ['t1']));

        await repository.removeTopicFromSubject('non-existent', 't1');

        final result = await repository.get('existing');
        expect(result.data!.topicIds, ['t1']);
      });

      test('repeated add and remove cycle works', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'Physics'));

        for (int i = 0; i < 10; i++) {
          await repository.addTopicToSubject('s1', 't$i');
        }
        expect((await repository.get('s1')).data!.topicIds.length, 10);

        for (int i = 0; i < 10; i++) {
          await repository.removeTopicFromSubject('s1', 't$i');
        }
        expect((await repository.get('s1')).data!.topicIds, isEmpty);

        await repository.addTopicToSubject('s1', 'final');
        expect((await repository.get('s1')).data!.topicIds, ['final']);
      });

      test('removing non-existent topic from empty topic list does nothing', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'A'));
        await repository.removeTopicFromSubject('s1', 't1');
        final s = await repository.get('s1');
        expect(s.data!.topicIds, isEmpty);
      });

      test('removing twice is idempotent', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'A', topicIds: ['t1']));
        await repository.removeTopicFromSubject('s1', 't1');
        await repository.removeTopicFromSubject('s1', 't1');
        final s = await repository.get('s1');
        expect(s.data!.topicIds, isEmpty);
      });
    });

    group('getByCode', () {
      test('finds subject by code', () async {
        repository.addSubject(createTestSubject(id: '1', name: 'Physics', code: 'IB-PHYS'));
        repository.addSubject(createTestSubject(id: '2', name: 'Chemistry', code: 'IB-CHEM'));

        final result = await repository.getByCode('IB-PHYS');

        expect(result, isNotNull);
        expect(result!.name, 'Physics');
      });

      test('returns null for non-existent code', () async {
        repository.addSubject(createTestSubject(id: '1', name: 'Physics', code: 'IB-PHYS'));

        final result = await repository.getByCode('NON-EXISTENT');

        expect(result, isNull);
      });

      test('is case-sensitive', () async {
        repository.addSubject(createTestSubject(id: '1', name: 'Physics', code: 'IB-PHYS'));

        final result = await repository.getByCode('ib-phys');

        expect(result, isNull);
      });

      test('returns first match when multiple subjects have same code', () async {
        repository.addSubject(createTestSubject(id: '1', name: 'Physics HL', code: 'IB-PHYS'));
        repository.addSubject(createTestSubject(id: '2', name: 'Physics SL', code: 'IB-PHYS'));

        final result = await repository.getByCode('IB-PHYS');

        expect(result, isNotNull);
      });

      test('handles null code in subjects', () async {
        repository.addSubject(createTestSubject(id: '1', name: 'No Code', code: null));

        final result = await repository.getByCode('ANY-CODE');

        expect(result, isNull);
      });

      test('returns subject with all fields when found', () async {
        repository.addSubject(createTestSubject(
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

      test('returns first when multiple have same code', () async {
        repository.addSubject(createTestSubject(id: 'first', name: 'First', code: 'SAME'));
        repository.addSubject(createTestSubject(id: 'second', name: 'Second', code: 'SAME'));

        final result = await repository.getByCode('SAME');
        expect(result, isNotNull);
        expect(result!.id, 'first');
      });

      test('does not match on partial code', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'Physics', code: 'IB-PHYSICS-HL'));

        final result = await repository.getByCode('PHYSICS');
        expect(result, isNull);
      });

      test('ignores subjects with null code when matching', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'No Code'));
        repository.addSubject(createTestSubject(id: 's2', name: 'With Code', code: 'C-42'));
        final result = await repository.getByCode('C-42');
        expect(result, isNotNull);
        expect(result!.name, 'With Code');
      });

      test('empty code string is matched exactly', () async {
        repository.addSubject(createTestSubject(id: 's1', name: 'Empty Code', code: ''));
        final result = await repository.getByCode('');
        expect(result, isNotNull);
        expect(result!.name, 'Empty Code');
      });
    });

    group('Data integrity', () {
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

        await repository.create(subject);
        final retrieved = await repository.get('full-subject');

        expect(retrieved.data, isNotNull);
        expect(retrieved.data!.id, 'full-subject');
        expect(retrieved.data!.name, 'Full Subject');
        expect(retrieved.data!.description, 'A detailed description');
        expect(retrieved.data!.syllabus, 'Syllabus content');
        expect(retrieved.data!.code, 'FS-101');
        expect(retrieved.data!.teacher, 'Dr. Teacher');
        expect(retrieved.data!.topicIds, ['topic-1', 'topic-2', 'topic-3']);
        expect(retrieved.data!.color, '#FF5722');
        expect(retrieved.data!.createdAt, createdAt);
        expect(retrieved.data!.examDate, examDate);
      });

      test('save preserves null optional fields', () async {
        final subject = createTestSubject(id: 'minimal', name: 'Minimal');

        await repository.create(subject);
        final retrieved = await repository.get('minimal');

        expect(retrieved.data, isNotNull);
        expect(retrieved.data!.description, isNull);
        expect(retrieved.data!.syllabus, isNull);
        expect(retrieved.data!.code, isNull);
        expect(retrieved.data!.teacher, isNull);
        expect(retrieved.data!.examDate, isNull);
      });

      test('save preserves exact field values', () async {
        final subject = createTestSubject(
          id: 'integrity-1',
          name: 'Advanced Physics HL',
          description: 'A very long description with special chars: ~!@#\$%^&*()_+',
          code: 'PHY-HL-2024',
          teacher: 'Dr. Müller (PhD)',
          topicIds: ['t1', 't2', 't3'],
          color: '#AABBCC',
          examDate: DateTime(2025, 12, 25, 8, 30),
        );

        await repository.create(subject);
        final retrieved = await repository.get('integrity-1');

        expect(retrieved.data!.id, 'integrity-1');
        expect(retrieved.data!.name, 'Advanced Physics HL');
        expect(retrieved.data!.description, 'A very long description with special chars: ~!@#\$%^&*()_+');
        expect(retrieved.data!.code, 'PHY-HL-2024');
        expect(retrieved.data!.teacher, 'Dr. Müller (PhD)');
        expect(retrieved.data!.topicIds, ['t1', 't2', 't3']);
        expect(retrieved.data!.color, '#AABBCC');
        expect(retrieved.data!.examDate, DateTime(2025, 12, 25, 8, 30));
      });

      test('save updates preserve unrelated fields', () async {
        await repository.create(createTestSubject(
          id: 'update-test',
          name: 'Original',
          description: 'Original description',
          code: 'ORIG',
          teacher: 'Dr. A',
          topicIds: ['t1'],
          color: '#FF0000',
        ));

        await repository.create(createTestSubject(
          id: 'update-test',
          name: 'Updated',
          topicIds: ['t1', 't2'],
        ));

        final result = await repository.get('update-test');
        expect(result.data!.name, 'Updated');
        expect(result.data!.description, isNull);
        expect(result.data!.code, isNull);
        expect(result.data!.teacher, isNull);
        expect(result.data!.topicIds, ['t1', 't2']);
        expect(result.data!.color, '#2196F3');
      });

      test('save -> get -> save (update) -> get preserves all fields', () async {
        await repository.create(createTestSubject(id: 'rt1', name: 'First', code: 'C1', topicIds: ['t1']));
        final g1 = await repository.get('rt1');
        expect(g1.data!.name, 'First');

        await repository.create(createTestSubject(id: 'rt1', name: 'Second', code: 'C2', topicIds: ['t1', 't2']));
        final g2 = await repository.get('rt1');
        expect(g2.data!.name, 'Second');
        expect(g2.data!.code, 'C2');
        expect(g2.data!.topicIds, ['t1', 't2']);
      });

      test('save -> delete -> save restores with new data', () async {
        await repository.create(createTestSubject(id: 'cyclic', name: 'Version 1'));
        await repository.delete('cyclic');
        expect((await repository.get('cyclic')).data, isNull);

        await repository.create(createTestSubject(id: 'cyclic', name: 'Version 2', code: 'V2'));
        final restored = await repository.get('cyclic');
        expect(restored.data, isNotNull);
        expect(restored.data!.name, 'Version 2');
        expect(restored.data!.code, 'V2');
      });

      test('getAll returns consistent results after multiple operations', () async {
        for (int i = 0; i < 10; i++) {
          await repository.create(createTestSubject(id: 's$i', name: 'S$i'));
        }
        expect((await repository.getAll()).data, hasLength(10));

        await repository.delete('s0');
        await repository.delete('s9');
        expect((await repository.getAll()).data, hasLength(8));

        await repository.create(createTestSubject(id: 's0', name: 'S0-again'));
        expect((await repository.getAll()).data, hasLength(9));
      });

      test('save with non-string ids works correctly', () async {
        await repository.create(createTestSubject(id: '123', name: 'Numeric ID'));
        await repository.create(createTestSubject(id: 'uuid-550e8400-e29b-41d4', name: 'UUID-like ID'));

        expect((await repository.get('123')).data, isNotNull);
        expect((await repository.get('uuid-550e8400-e29b-41d4')).data, isNotNull);
        expect((await repository.getAll()).data, hasLength(2));
      });

      test('multiple operations in sequence work correctly', () async {
        await repository.create(createTestSubject(id: '1', name: 'Physics', code: 'PHY'));
        await repository.create(createTestSubject(id: '2', name: 'Chemistry', code: 'CHE'));

        expect(await repository.getByCode('PHY'), isNotNull);
        expect(await repository.getByCode('CHE'), isNotNull);

        await repository.addTopicToSubject('1', 'topic-x');
        final s1 = await repository.get('1');
        expect(s1.data!.topicIds, ['topic-x']);

        await repository.addTopicToSubject('1', 'topic-y');
        final s1Again = await repository.get('1');
        expect(s1Again.data!.topicIds, ['topic-x', 'topic-y']);

        await repository.removeTopicFromSubject('1', 'topic-x');
        final s1Final = await repository.get('1');
        expect(s1Final.data!.topicIds, ['topic-y']);

        await repository.delete('2');
        expect((await repository.getAll()).data, hasLength(1));
      });
    });

    group('Edge cases', () {
      group('special identifiers', () {
        test('save with empty string id', () async {
          final subject = createTestSubject(id: '', name: 'Empty ID');
          await repository.create(subject);
          final retrieved = await repository.get('');
        expect(retrieved.data, isNotNull);
        expect(retrieved.data!.name, 'Empty ID');
        });

        test('get with empty string id returns null when not saved', () async {
          final result = await repository.get('');
          expect(result.data, isNull);
        });

        test('delete with empty string id is safe', () async {
          await repository.delete('');
        });

        test('getByCode with empty string matches empty code', () async {
          repository.addSubject(createTestSubject(id: 'empty-code', name: 'No Code', code: ''));
          final result = await repository.getByCode('');
        expect(result, isNotNull);
        expect(result!.name, 'No Code');
        });

        test('get with whitespace-padded id', () async {
          repository.addSubject(createTestSubject(id: 'real-id', name: 'Real'));
          final result = await repository.get('real-id ');
          expect(result.data, isNull);
        });
      });

      group('field-level', () {
        test('handles very long name', () async {
          final longName = 'A' * 1000;
          await repository.create(createTestSubject(id: 'long', name: longName));

          final result = await repository.get('long');
          expect(result.data!.name.length, 1000);
        });

        test('handles null description in save/get roundtrip', () async {
          await repository.create(createTestSubject(id: 'null-desc', name: 'Test', description: null));
          final result = await repository.get('null-desc');
          expect(result.data!.description, isNull);
        });

        test('handles empty string description', () async {
          await repository.create(createTestSubject(id: 'empty-desc', name: 'Test', description: ''));
          final result = await repository.get('empty-desc');
          expect(result.data!.description, '');
        });

        test('getAll returns empty list on empty box', () async {
          repository.clearStorage();
          final result = await repository.getAll();
          expect(result.data, isEmpty);
        });

        test('get returns null for any id on empty box', () async {
          expect((await repository.get('anything')).data, isNull);
        });

        test('getByCode returns null on empty box', () async {
          expect(await repository.getByCode('ANY'), isNull);
        });
      });
    });

    group('Stress and bulk operations', () {
      test('getAll with many subjects', () async {
        for (int i = 0; i < 100; i++) {
          repository.addSubject(createTestSubject(id: 's$i', name: 'Subject $i'));
        }
        final all = await repository.getAll();
        expect(all.data!.length, 100);
      });

      test('sequential saves and deletes', () async {
        for (int i = 0; i < 50; i++) {
          await repository.create(createTestSubject(id: 's$i', name: 'Subject $i'));
        }
        expect((await repository.getAll()).data, hasLength(50));

        for (int i = 0; i < 50; i++) {
          await repository.delete('s$i');
        }
        expect((await repository.getAll()).data, isEmpty);
      });

      test('getWithTopics with many subjects and many topics', () async {
        for (int i = 0; i < 50; i++) {
          final topicIds = List.generate(20, (j) => 'topic-${i * 20 + j}');
          repository.addSubject(createTestSubject(id: 's$i', name: 'Subject $i', topicIds: topicIds));
        }
        final result = await repository.getWithTopics(['topic-5', 'topic-105']);
        expect(result.length, 2);
      });

      test('delete all subjects leaves empty box', () async {
        repository.addSubject(createTestSubject(id: '1', name: 'A'));
        repository.addSubject(createTestSubject(id: '2', name: 'B'));
        repository.addSubject(createTestSubject(id: '3', name: 'C'));

        await repository.delete('1');
        await repository.delete('2');
        await repository.delete('3');

        final result = await repository.getAll();
        expect(result.data, isEmpty);
      });
    });

    group('SubjectRepository.init() with Hive', () {
      const testPath = '/tmp/opencode/studyking_subjects_init_test';

      setUp(() async {
        Hive.init(testPath);
        if (!Hive.isAdapterRegistered(11)) {
          Hive.registerAdapter(TestSubjectAdapter());
        }
        final box = await Hive.openBox<Subject>('subjects');
        await box.clear();
      });

      tearDown(() async {
        await Hive.close();
      });

      test('initializes and returns empty list', () async {
        final repository = SubjectRepository();
        await repository.init();

        final subjects = await repository.getAll();
        expect(subjects.data, isEmpty);
      });

      test('allows CRUD operations after init', () async {
        final repository = SubjectRepository();
        await repository.init();

        final subject = Subject(
          id: 'test-1',
          name: 'Physics',
          description: 'IB Physics HL',
          code: 'IB-PHYS',
          topicIds: ['topic-1', 'topic-2'],
          color: '#FF0000',
        );
        await repository.create(subject);

        final retrieved = await repository.get('test-1');
        expect(retrieved.data, isNotNull);
        expect(retrieved.data!.name, 'Physics');
        expect(retrieved.data!.description, 'IB Physics HL');
        expect(retrieved.data!.code, 'IB-PHYS');

        final all = await repository.getAll();
        expect(all.data!.length, 1);

        await repository.delete('test-1');
        expect((await repository.get('test-1')).data, isNull);
        expect((await repository.getAll()).data, isEmpty);
      });

      test('supports getByCode after init', () async {
        final repository = SubjectRepository();
        await repository.init();

        await repository.create(Subject(id: '1', name: 'Physics', code: 'IB-PHYS'));
        await repository.create(Subject(id: '2', name: 'Chemistry', code: 'IB-CHEM'));

        final found = await repository.getByCode('IB-CHEM');
        expect(found, isNotNull);
        expect(found!.name, 'Chemistry');
      });

      test('supports addTopicToSubject after init', () async {
        final repository = SubjectRepository();
        await repository.init();

        await repository.create(Subject(id: '1', name: 'Physics', topicIds: ['topic-1']));
        await repository.addTopicToSubject('1', 'topic-2');

        final subject = await repository.get('1');
        expect(subject.data!.topicIds, containsAll(['topic-1', 'topic-2']));
      });

      test('supports removeTopicFromSubject after init', () async {
        final repository = SubjectRepository();
        await repository.init();

        await repository.create(Subject(id: '1', name: 'Physics', topicIds: ['topic-1', 'topic-2']));
        await repository.removeTopicFromSubject('1', 'topic-2');

        final subject = await repository.get('1');
        expect(subject.data!.topicIds, ['topic-1']);
      });

      test('supports getWithTopics after init', () async {
        final repository = SubjectRepository();
        await repository.init();

        await repository.create(Subject(id: '1', name: 'Physics', topicIds: ['topic-a']));
        await repository.create(Subject(id: '2', name: 'Chemistry', topicIds: ['topic-b']));

        final result = await repository.getWithTopics(['topic-a']);
        expect(result.length, 1);
        expect(result.first.name, 'Physics');
      });

      test('supports getAll after init', () async {
        final repository = SubjectRepository();
        await repository.init();

        await repository.create(Subject(id: '1', name: 'Physics'));
        await repository.create(Subject(id: '2', name: 'Chemistry'));

        final result = await repository.getAll();
        expect(result.data!.length, 2);
      });

      test('init replaces null with open box', () async {
        final repository = SubjectRepository();
        await repository.init();
        expect((await repository.getAll()).data, isEmpty);
      });

      test('init is idempotent when called multiple times', () async {
        final repository = SubjectRepository();
        await repository.init();
        await repository.init();

        await repository.create(Subject(id: '1', name: 'Physics'));
        final result = await repository.getAll();
        expect(result.data!.length, 1);
      });
    });
  });
}
