import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/core/data/enums.dart';

class _MockSourceRepository extends SourceRepository {
  final Map<String, Source> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> create(Source source) async {
    _storage[source.id] = source;
  }

  @override
  Future<Source?> get(String id) async {
    return _storage[id];
  }

  @override
  Future<List<Source>> getAll() async {
    return _storage.values.toList();
  }

  @override
  Future<List<Source>> getBySubject(String subjectId) async {
    return _storage.values.where((s) => s.subjectId == subjectId).toList();
  }

  @override
  Future<List<Source>> getByTopic(String topicId) async {
    return _storage.values.where((s) => s.topicId == topicId).toList();
  }

  @override
  Future<List<Source>> getByStudent(String studentId) async {
    return _storage.values.where((s) => s.studentId == studentId).toList();
  }

  @override
  Future<void> delete(String id) async {
    _storage.remove(id);
  }

  @override
  Future<List<Source>> getByType(String sourceType) async {
    return _storage.values.where((s) => s.type.name == sourceType).toList();
  }
}

void main() {
  group('SourceRepository', () {
    late _MockSourceRepository repository;

    setUp(() {
      repository = _MockSourceRepository();
    });

    group('create', () {
      test('stores a source', () async {
        final source = Source(id: 's1', title: 'Test', type: SourceType.pdf);
        await repository.create(source);
        final stored = await repository.get('s1');
        expect(stored?.title, 'Test');
      });

      test('overwrites existing source with same id', () async {
        await repository.create(Source(id: 's1', title: 'Original', type: SourceType.pdf));
        await repository.create(Source(id: 's1', title: 'Updated', type: SourceType.pdf));
        expect((await repository.get('s1'))?.title, 'Updated');
      });
    });

    group('get', () {
      test('returns null for non-existent', () async {
        expect(await repository.get('none'), isNull);
      });

      test('returns stored source', () async {
        await repository.create(Source(id: 's1', title: 'Test', type: SourceType.pdf));
        final result = await repository.get('s1');
        expect(result, isNotNull);
        expect(result?.id, 's1');
      });
    });

    group('getAll', () {
      test('returns all sources', () async {
        await repository.create(Source(id: 's1', title: 'S1', type: SourceType.pdf));
        await repository.create(Source(id: 's2', title: 'S2', type: SourceType.textbook));
        expect((await repository.getAll()).length, 2);
      });

      test('returns empty when no sources', () async {
        expect(await repository.getAll(), isEmpty);
      });
    });

    group('getBySubject', () {
      test('returns sources for subject', () async {
        await repository.create(Source(id: 's1', title: 'S1', type: SourceType.pdf, subjectId: 'sub1'));
        await repository.create(Source(id: 's2', title: 'S2', type: SourceType.pdf, subjectId: 'sub1'));
        await repository.create(Source(id: 's3', title: 'S3', type: SourceType.pdf, subjectId: 'sub2'));
        expect((await repository.getBySubject('sub1')).length, 2);
      });

      test('returns empty for non-existent subject', () async {
        expect(await repository.getBySubject('none'), isEmpty);
      });
    });

    group('getByTopic', () {
      test('returns sources for topic', () async {
        await repository.create(Source(id: 's1', title: 'S1', type: SourceType.pdf, topicId: 't1'));
        await repository.create(Source(id: 's2', title: 'S2', type: SourceType.pdf, topicId: 't2'));
        expect((await repository.getByTopic('t1')).length, 1);
      });

      test('returns empty for non-existent topic', () async {
        expect(await repository.getByTopic('none'), isEmpty);
      });
    });

    group('getByStudent', () {
      test('returns sources for student', () async {
        await repository.create(Source(id: 's1', title: 'S1', type: SourceType.pdf, studentId: 'stu1'));
        await repository.create(Source(id: 's2', title: 'S2', type: SourceType.pdf, studentId: 'stu2'));
        expect((await repository.getByStudent('stu1')).length, 1);
      });

      test('returns empty for non-existent student', () async {
        expect(await repository.getByStudent('none'), isEmpty);
      });
    });

    group('delete', () {
      test('removes a source', () async {
        await repository.create(Source(id: 's1', title: 'S1', type: SourceType.pdf));
        await repository.delete('s1');
        expect(await repository.get('s1'), isNull);
      });

      test('does nothing for non-existent', () async {
        await repository.delete('none');
      });
    });

    group('getByType', () {
      test('returns sources of given type', () async {
        await repository.create(Source(id: 's1', title: 'S1', type: SourceType.pdf));
        await repository.create(Source(id: 's2', title: 'S2', type: SourceType.textbook));
        await repository.create(Source(id: 's3', title: 'S3', type: SourceType.pdf));
        expect((await repository.getByType('pdf')).length, 2);
        expect((await repository.getByType('textbook')).length, 1);
      });

      test('returns empty for non-existent type', () async {
        expect(await repository.getByType('video'), isEmpty);
      });
    });
  });
}
