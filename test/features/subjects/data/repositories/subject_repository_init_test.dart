import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/models/subject_model.dart';

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

void main() {
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

  group('SubjectRepository.init() with Hive', () {
    test('initializes and returns empty list', () async {
      final repository = SubjectRepository();
      await repository.init();

      final subjects = await repository.getAll();
      expect(subjects, isEmpty);
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
      await repository.save(subject);

      final retrieved = await repository.get('test-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Physics');
      expect(retrieved.description, 'IB Physics HL');
      expect(retrieved.code, 'IB-PHYS');

      final all = await repository.getAll();
      expect(all.length, 1);

      await repository.delete('test-1');
      expect(await repository.get('test-1'), isNull);
      expect(await repository.getAll(), isEmpty);
    });

    test('supports getByCode after init', () async {
      final repository = SubjectRepository();
      await repository.init();

      await repository.save(Subject(id: '1', name: 'Physics', code: 'IB-PHYS'));
      await repository.save(Subject(id: '2', name: 'Chemistry', code: 'IB-CHEM'));

      final found = await repository.getByCode('IB-CHEM');
      expect(found, isNotNull);
      expect(found!.name, 'Chemistry');
    });

    test('supports addTopicToSubject after init', () async {
      final repository = SubjectRepository();
      await repository.init();

      await repository.save(Subject(id: '1', name: 'Physics', topicIds: ['topic-1']));
      await repository.addTopicToSubject('1', 'topic-2');

      final subject = await repository.get('1');
      expect(subject!.topicIds, containsAll(['topic-1', 'topic-2']));
    });

    test('supports removeTopicFromSubject after init', () async {
      final repository = SubjectRepository();
      await repository.init();

      await repository.save(Subject(id: '1', name: 'Physics', topicIds: ['topic-1', 'topic-2']));
      await repository.removeTopicFromSubject('1', 'topic-2');

      final subject = await repository.get('1');
      expect(subject!.topicIds, ['topic-1']);
    });

    test('supports getWithTopics after init', () async {
      final repository = SubjectRepository();
      await repository.init();

      await repository.save(Subject(id: '1', name: 'Physics', topicIds: ['topic-a']));
      await repository.save(Subject(id: '2', name: 'Chemistry', topicIds: ['topic-b']));

      final result = await repository.getWithTopics(['topic-a']);
      expect(result.length, 1);
      expect(result.first.name, 'Physics');
    });

    test('supports getStudentSubjects after init', () async {
      final repository = SubjectRepository();
      await repository.init();

      await repository.save(Subject(id: '1', name: 'Physics'));
      await repository.save(Subject(id: '2', name: 'Chemistry'));

      final result = await repository.getStudentSubjects('student-1');
      expect(result.length, 2);
    });

    test('init replaces null _subjectBox with open box', () async {
      final repository = SubjectRepository();
      expect(repository.getAll, throwsA(isA<StateError>()));

      await repository.init();
      expect(await repository.getAll(), isEmpty);
    });

    test('init is idempotent when called multiple times', () async {
      final repository = SubjectRepository();
      await repository.init();
      await repository.init();

      await repository.save(Subject(id: '1', name: 'Physics'));
      final result = await repository.getAll();
      expect(result.length, 1);
    });
  });
}
