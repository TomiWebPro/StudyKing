import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/mentor/services/tools/revisit_sources_tool.dart';
import 'test_helpers.dart';

/// Hand-written fake [SourceRepository] (no mockito/mocktail) — AGENTS.md.
class FakeSourceRepository extends SourceRepository {
  final Map<String, Source> _byId = {};
  final List<Source> _all = [];
  bool failByStudent = false;

  FakeSourceRepository() : super();

  void add(Source source) {
    _byId[source.id] = source;
    _all.add(source);
  }

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<Source?>> get(String key) async =>
      Result.success(_byId[key]);

  @override
  Future<Result<List<Source>>> getByStudent(String studentId) async {
    if (failByStudent) return Result.failure('simulated getByStudent failure');
    return Result.success(
      _all.where((s) => s.studentId == studentId).toList(),
    );
  }

  @override
  Future<Result<List<Source>>> getAll() async => Result.success(_all);
}

void main() {
  group('RevisitSourcesTool', () {
    late FakeSourceRepository sourceRepo;
    late FakeStudentIdService studentIdService;

    setUp(() {
      sourceRepo = FakeSourceRepository();
      studentIdService = FakeStudentIdService('student-1');
    });

    group('tool metadata', () {
      test('name returns revisit_sources', () {
        final tool = RevisitSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        expect(tool.name, 'revisit_sources');
      });

      test('description is not empty and mentions sources', () {
        final tool = RevisitSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        expect(tool.description, isNotEmpty);
        expect(tool.description.toLowerCase(), contains('source'));
      });

      test('parameters declares optional fields and no required', () {
        final tool = RevisitSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final params = tool.parameters;
        expect(params['type'], 'object');
        expect(params['required'], isEmpty);
        final props = params['properties'] as Map<String, dynamic>;
        expect(props.keys.toSet(), containsAll(<String>{
          'limit',
          'offset',
          'subjectId',
        }));
        expect((props['limit'] as Map)['default'], 10);
        expect((props['offset'] as Map)['default'], 0);
      });
    });

    group('list mode', () {
      setUp(() {
        sourceRepo.add(Source(
          id: 'old',
          title: 'Old Notes',
          type: SourceType.pdf,
          chunks: '[]',
          studentId: 'student-1',
          subjectId: 'math',
          createdAt: DateTime(2024, 1, 1),
        ));
        sourceRepo.add(Source(
          id: 'new',
          title: 'New Notes',
          type: SourceType.pdf,
          chunks: '[]',
          studentId: 'student-1',
          subjectId: 'chem',
          createdAt: DateTime(2024, 6, 1),
        ));
        sourceRepo.add(Source(
          id: 'mid',
          title: 'Mid notes',
          type: SourceType.pdf,
          chunks: '[]',
          studentId: 'student-1',
          subjectId: 'math',
          createdAt: DateTime(2024, 3, 1),
        ));
      });

      test('lists sources sorted by createdAt descending (newest first)',
          () async {
        final tool = RevisitSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({});

        expect(result['success'], isTrue);
        expect(result['totalCount'], 3);
        final sources = result['sources'] as List;
        expect(sources[0]['id'], 'new');
        expect(sources[1]['id'], 'mid');
        expect(sources[2]['id'], 'old');
      });

      test('respects the limit parameter', () async {
        final tool = RevisitSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({'limit': 2});

        expect(result['sourceCount'], 2);
        expect(result['hasMore'], isTrue);
        final sources = result['sources'] as List;
        expect(sources[0]['id'], 'new');
        expect(sources[1]['id'], 'mid');
      });

      test('respects the offset parameter for pagination', () async {
        final tool = RevisitSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({'limit': 2, 'offset': 1});

        expect(result['sourceCount'], 2);
        expect(result['offset'], 1);
        expect(result['hasMore'], isFalse);
        final sources = result['sources'] as List;
        expect(sources[0]['id'], 'mid');
        expect(sources[1]['id'], 'old');
      });

      test('returns hasMore=false when offset is past the end', () async {
        final tool = RevisitSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({'limit': 10, 'offset': 10});

        expect(result['sourceCount'], 0);
        expect(result['hasMore'], isFalse);
        expect(result['sources'], isEmpty);
      });

      test('filters by subjectId when provided', () async {
        final tool = RevisitSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({'subjectId': 'math'});

        expect(result['success'], isTrue);
        expect(result['totalCount'], 2);
        final sources = result['sources'] as List;
        expect(sources[0]['id'], 'mid');
        expect(sources[1]['id'], 'old');
      });

      test('includes chunkCount in source entry', () async {
        sourceRepo.add(Source(
          id: 'with-chunks',
          title: 'Chunked Source',
          type: SourceType.pdf,
          chunks: '[{"chunkIndex":0,"text":"hello"},'
              '{"chunkIndex":1,"text":"world"}]',
          studentId: 'student-1',
          subjectId: 'math',
          createdAt: DateTime(2024, 7, 1),
        ));
        final tool = RevisitSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({});

        final entry = (result['sources'] as List)
            .firstWhere((s) => (s as Map)['id'] == 'with-chunks');
        expect(entry['chunkCount'], 2);
      });

      test('includes createdAt as ISO string in source entry', () async {
        final tool = RevisitSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({});

        final entry = (result['sources'] as List)
            .firstWhere((s) => (s as Map)['id'] == 'new');
        expect(entry['createdAt'], '2024-06-01T00:00:00.000');
      });

      test('omits createdAt when absent', () async {
        sourceRepo.add(Source(
          id: 'no-date',
          title: 'No Date',
          type: SourceType.pdf,
          chunks: '[]',
          studentId: 'student-1',
        ));
        final tool = RevisitSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({});

        final entry = (result['sources'] as List)
            .firstWhere((s) => (s as Map)['id'] == 'no-date');
        expect(entry.containsKey('createdAt'), isFalse);
      });
    });

    group('error handling', () {
      test('returns error when studentId cannot be resolved', () {
        final noIdService = FakeStudentIdService('');
        final tool = RevisitSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: noIdService,
        );
        expect(tool.execute({}), completes);
      });

      test('surfaces repo failure as success:false', () async {
        sourceRepo.failByStudent = true;
        final tool = RevisitSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({});

        expect(result['success'], isFalse);
        expect(result['error'], isNotEmpty);
      });

      test('returns empty list when student has no sources', () async {
        final tool = RevisitSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({});

        expect(result['success'], isTrue);
        expect(result['totalCount'], 0);
        expect(result['sourceCount'], 0);
        expect(result['sources'], isEmpty);
        expect(result['hasMore'], isFalse);
      });
    });
  });
}
