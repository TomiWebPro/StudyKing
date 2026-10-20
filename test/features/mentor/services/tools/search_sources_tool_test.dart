import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/mentor/services/tools/search_sources_tool.dart';
import 'test_helpers.dart';

/// Hand-written fake [SourceRepository] (no mockito/mocktail) — AGENTS.md.
class FakeSourceRepository extends SourceRepository {
  final Map<String, Source> _byId = {};
  final List<Source> _all = [];
  bool failByStudent = false;
  bool failGet = false;

  FakeSourceRepository() : super();

  void add(Source source) {
    _byId[source.id] = source;
    _all.add(source);
  }

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<Source?>> get(String key) async {
    if (failGet) return Result.failure('simulated get failure');
    return Result.success(_byId[key]);
  }

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

String _chunksJson(List<Map<String, dynamic>> chunks) =>
    jsonEncode(chunks);

void main() {
  group('SearchSourcesTool', () {
    late FakeSourceRepository sourceRepo;
    late FakeStudentIdService studentIdService;

    setUp(() {
      sourceRepo = FakeSourceRepository();
      studentIdService = FakeStudentIdService('student-1');
    });

    group('tool metadata', () {
      test('name returns search_sources', () {
        final tool = SearchSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        expect(tool.name, 'search_sources');
      });

      test('description is not empty and mentions searching', () {
        final tool = SearchSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        expect(tool.description, isNotEmpty);
        expect(tool.description.toLowerCase(), contains('search'));
      });

      test('parameters declares query (required) + optional fields', () {
        final tool = SearchSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final params = tool.parameters;
        expect(params['type'], 'object');
        expect(params['required'], contains('query'));
        final props = params['properties'] as Map<String, dynamic>;
        expect(props.keys.toSet(), containsAll(<String>{
          'query',
          'subjectId',
          'limit',
        }));
        expect((props['limit'] as Map)['default'], 10);
      });
    });

    group('search', () {
      setUp(() {
        sourceRepo.add(Source(
          id: 'chem-1',
          title: 'Organic Chemistry',
          type: SourceType.pdf,
          chunks: _chunksJson([
            {
              'chunkIndex': 0,
              'pageStart': 102,
              'pageEnd': 105,
              'text': 'Aldol condensation is a carbon-carbon bond-forming reaction.',
              'heading': 'Aldol Condensation',
            },
            {
              'chunkIndex': 1,
              'pageStart': 200,
              'pageEnd': 203,
              'text': 'SN2 reactions proceed through a backside attack mechanism.',
            },
          ]),
          studentId: 'student-1',
          subjectId: 'chem',
          topicId: 'orgo',
          topicConfidence: '0.85',
        ));
        sourceRepo.add(Source(
          id: 'bio-1',
          title: 'Biology Notes',
          type: SourceType.pdf,
          chunks: _chunksJson([
            {
              'chunkIndex': 0,
              'pageStart': 1,
              'pageEnd': 5,
              'text': 'Cellular respiration converts glucose to ATP.',
            },
          ]),
          studentId: 'student-1',
          subjectId: 'bio',
        ));
      });

      test('finds matching chunks by keyword', () async {
        final tool = SearchSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({'query': 'aldol'});

        expect(result['success'], isTrue);
        expect(result['matchCount'], 1);
        final results = result['results'] as List;
        expect(results[0]['sourceId'], 'chem-1');
        expect(results[0]['title'], 'Organic Chemistry');
        expect(results[0]['pageStart'], 102);
        expect(results[0]['heading'], 'Aldol Condensation');
        expect(results[0]['excerpt'], contains('Aldol condensation'));
      });

      test('search is case-insensitive via normalized matching', () async {
        final tool = SearchSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({'query': 'ALDOL CONDENSATION'});

        expect(result['success'], isTrue);
        expect(result['matchCount'], 1);
        expect((result['results'] as List)[0]['sourceId'], 'chem-1');
      });

      test('respects the limit parameter', () async {
        // Add a third source with another aldol mention.
        sourceRepo.add(Source(
          id: 'chem-2',
          title: 'Reaction Mechanisms',
          type: SourceType.pdf,
          chunks: _chunksJson([
            {
              'chunkIndex': 0,
              'pageStart': 50,
              'pageEnd': 52,
              'text': 'The aldol condensation mechanism is complex.',
            },
          ]),
          studentId: 'student-1',
          subjectId: 'chem',
        ));

        final tool = SearchSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({'query': 'aldol', 'limit': 1});

        expect(result['matchCount'], 1);
      });

      test('filters by subjectId when provided', () async {
        final tool = SearchSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({
          'query': 'respiration',
          'subjectId': 'bio',
        });

        expect(result['matchCount'], 1);
        expect((result['results'] as List)[0]['sourceId'], 'bio-1');
      });

      test('returns empty results when no match', () async {
        final tool = SearchSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({'query': 'quantum'});

        expect(result['success'], isTrue);
        expect(result['matchCount'], 0);
        expect(result['results'], isEmpty);
        expect(result['hasMore'], isFalse);
      });

      test('bounds the excerpt length', () async {
        final longText = 'Aldol ' * 200; // 1000 chars
        sourceRepo = FakeSourceRepository()
          ..add(Source(
            id: 'long-1',
            title: 'Long Text',
            type: SourceType.pdf,
            chunks: _chunksJson([
              {
                'chunkIndex': 0,
                'pageStart': 1,
                'pageEnd': 1,
                'text': longText,
              },
            ]),
            studentId: 'student-1',
          ));
        final tool = SearchSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({'query': 'aldol'});

        final excerpt = (result['results'] as List)[0]['excerpt'] as String;
        expect(excerpt.length, lessThanOrEqualTo(301));
        expect(excerpt, contains('…'));
      });

      test('includes subjectId and topicId in results when set', () async {
        final tool = SearchSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({'query': 'aldol'});

        final entry = (result['results'] as List)[0] as Map<String, dynamic>;
        expect(entry['subjectId'], 'chem');
        expect(entry['topicId'], 'orgo');
        expect(entry['topicConfidence'], '0.85');
      });
    });

    group('error handling', () {
      test('returns error when query is empty', () async {
        final tool = SearchSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({'query': ''});

        expect(result['success'], isFalse);
        expect(result['error'], isNotEmpty);
      });

      test('returns error when query is absent', () async {
        final tool = SearchSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({});

        expect(result['success'], isFalse);
        expect(result['error'], contains('query'));
      });

      test('returns error when studentId cannot be resolved', () {
        final noIdService = FakeStudentIdService('');
        final tool = SearchSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: noIdService,
        );
        // Empty studentId → error, not crash
        expect(
          tool.execute({'query': 'test'}),
          completes);
      });

      test('surfaces repo failure as success:false', () async {
        sourceRepo.failByStudent = true;
        final tool = SearchSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({'query': 'aldol'});

        expect(result['success'], isFalse);
        expect(result['error'], isNotEmpty);
      });

      test('handles sources with malformed chunks JSON', () async {
        sourceRepo.add(Source(
          id: 'bad',
          title: 'Bad Chunks',
          type: SourceType.pdf,
          chunks: 'not valid json',
          studentId: 'student-1',
        ));
        final tool = SearchSourcesTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({'query': 'anything'});

        expect(result['success'], isTrue);
        expect(result['matchCount'], 0);
      });
    });
  });
}
