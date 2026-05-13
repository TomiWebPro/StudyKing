import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/repositories/source_repository.dart';
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
    });

    group('get', () {
      test('returns null for non-existent', () async {
        expect(await repository.get('none'), isNull);
      });
    });

    group('getAll', () {
      test('returns all sources', () async {
        await repository.create(Source(id: 's1', title: 'S1', type: SourceType.pdf));
        await repository.create(Source(id: 's2', title: 'S2', type: SourceType.textbook));
        expect((await repository.getAll()).length, 2);
      });
    });
  });
}
