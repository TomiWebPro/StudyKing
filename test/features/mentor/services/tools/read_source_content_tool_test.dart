import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/mentor/services/tools/read_source_content_tool.dart';
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

Source _source(
  String id,
  String title, {
  String chunks = '',
  String? extractionMeta,
  String extractedText = '',
  String studentId = 'student-1',
  String subjectId = '',
  String topicId = '',
}) =>
    Source(
      id: id,
      title: title,
      type: SourceType.pdf,
      chunks: chunks,
      extractionMeta: extractionMeta ?? '',
      extractedText: extractedText,
      studentId: studentId,
      subjectId: subjectId,
      topicId: topicId,
    );

List<Map<String, dynamic>> _chunkJson(
  int idx,
  int pageStart,
  int pageEnd,
  String text, {
  String? heading,
}) =>
    [
      {
        'chunkIndex': idx,
        'pageStart': pageStart,
        'pageEnd': pageEnd,
        'text': text,
        if (heading != null) 'heading': heading,
      },
    ];

String _chunksJson(List<Map<String, dynamic>> chunks) =>
    jsonEncode(chunks);

void main() {
  group('ReadSourceContentTool', () {
    late FakeSourceRepository sourceRepo;
    late FakeStudentIdService studentIdService;

    setUp(() {
      sourceRepo = FakeSourceRepository();
      studentIdService = FakeStudentIdService('student-1');
    });

    group('tool metadata', () {
      test('name returns read_source_content', () {
        final tool = ReadSourceContentTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        expect(tool.name, 'read_source_content');
      });

      test('description is not empty and mentions sources', () {
        final tool = ReadSourceContentTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        expect(tool.description, isNotEmpty);
        expect(tool.description.toLowerCase(), contains('source'));
      });

      test('parameters declares all optional fields and no required', () {
        final tool = ReadSourceContentTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final params = tool.parameters;
        expect(params['type'], 'object');
        expect(params['required'], isEmpty);
        final props = params['properties'] as Map<String, dynamic>;
        expect(
          props.keys.toSet(),
          containsAll(
            <String>{
              'sourceId',
              'startPage',
              'endPage',
              'chunkIndex',
              'maxChunks',
            },
          ),
        );
        expect((props['maxChunks'] as Map)['default'], 20);
      });
    });

    group('list mode (no sourceId)', () {
      test('lists the student sources with chunk counts and content flag', () async {
        sourceRepo.add(_source(
          's1',
          'Math Notes',
          chunks: _chunksJson([
            ..._chunkJson(0, 1, 3, 'Introduction'),
            ..._chunkJson(1, 4, 6, 'Algebra'),
          ]),
          extractedText: 'some extracted text',
          subjectId: 'subj1',
        ));
        sourceRepo.add(_source('s2', 'Chem Notes', chunks: _chunksJson([
          ..._chunkJson(0, 1, 2, 'Atoms'),
        ])));

        final tool = ReadSourceContentTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({});

        expect(result['success'], isTrue);
        expect(result['sourceCount'], 2);
        final sources = result['sources'] as List;
        expect(sources[0]['id'], 's1');
        expect(sources[0]['title'], 'Math Notes');
        expect(sources[0]['chunkCount'], 2);
        expect(sources[0]['hasContent'], isTrue);
        expect(sources[0]['subjectId'], 'subj1');
        expect(sources[1]['chunkCount'], 1);
      });

      test('returns empty list when student has no sources', () async {
        final tool = ReadSourceContentTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({});

        expect(result['success'], isTrue);
        expect(result['sourceCount'], 0);
        expect(result['sources'], isEmpty);
      });

      test('surfaces repo failure as success:false', () async {
        sourceRepo.failByStudent = true;
        final tool = ReadSourceContentTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({});

        expect(result['success'], isFalse);
        expect(result['error'], isNotEmpty);
      });
    });

    group('read mode', () {
      setUp(() {
        sourceRepo.add(_source(
          's1',
          'Math Textbook',
          chunks: _chunksJson([
            ..._chunkJson(0, 1, 3, 'Intro content', heading: 'Introduction'),
            ..._chunkJson(1, 4, 6, 'Algebra content', heading: 'Algebra'),
            ..._chunkJson(2, 7, 9, 'Conclusion content', heading: 'Conclusion'),
          ]),
          extractionMeta: jsonEncode({'pageCount': 9}),
          extractedText: 'full text',
          subjectId: 'subj1',
          topicId: 't1',
        ));
      });

      test('reads all chunks for a source with page refs', () async {
        final tool = ReadSourceContentTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({'sourceId': 's1'});

        expect(result['success'], isTrue);
        expect(result['sourceId'], 's1');
        expect(result['title'], 'Math Textbook');
        expect(result['type'], 'pdf');
        expect(result['subjectId'], 'subj1');
        expect(result['topicId'], 't1');
        expect(result['pageCount'], 9);
        expect(result['chunkCount'], 3);
        final chunks = result['chunks'] as List;
        expect(chunks.length, 3);
        expect(chunks[0]['chunkIndex'], 0);
        expect(chunks[0]['pageStart'], 1);
        expect(chunks[0]['pageEnd'], 3);
        expect(chunks[0]['heading'], 'Introduction');
        expect(chunks[0]['text'], 'Intro content');
      });

      test('filters by page range (inclusive)', () async {
        final tool = ReadSourceContentTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({
          'sourceId': 's1',
          'startPage': 4,
          'endPage': 6,
        });

        final chunks = result['chunks'] as List;
        expect(chunks.length, 1);
        expect(chunks[0]['pageStart'], 4);
        expect(chunks[0]['heading'], 'Algebra');
      });

      test('includes a chunk whose page span overlaps the range', () async {
        // A wide chunk spanning pages 1-6 should be returned for pages 3-4.
        sourceRepo = FakeSourceRepository()
          ..add(_source(
            'wide',
            'Wide',
            chunks: _chunksJson([
              ..._chunkJson(0, 1, 6, 'wide chunk', heading: 'Wide'),
            ]),
          ));
        final tool = ReadSourceContentTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({
          'sourceId': 'wide',
          'startPage': 3,
          'endPage': 4,
        });

        expect(result['success'], isTrue);
        expect((result['chunks'] as List).length, 1);
      });

      test('reads a single chunk by index', () async {
        final tool = ReadSourceContentTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({
          'sourceId': 's1',
          'chunkIndex': 1,
        });

        expect(result['success'], isTrue);
        final chunks = result['chunks'] as List;
        expect(chunks.length, 1);
        expect(chunks[0]['chunkIndex'], 1);
        expect(chunks[0]['heading'], 'Algebra');
      });

      test('returns error when chunkIndex is out of range', () async {
        final tool = ReadSourceContentTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({
          'sourceId': 's1',
          'chunkIndex': 99,
        });

        expect(result['success'], isNull);
        expect(result['error'], contains('not found'));
        expect(result['error'], contains('99'));
      });

      test('respects the maxChunks cap', () async {
        final tool = ReadSourceContentTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({
          'sourceId': 's1',
          'maxChunks': 2,
        });

        expect((result['chunks'] as List).length, 2);
      });

      test('returns error when source is not found', () async {
        final tool = ReadSourceContentTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({'sourceId': 'missing'});

        expect(result['error'], contains('not found'));
        expect(result['error'], contains('missing'));
      });

      test('parses pageCount from extractionMeta', () async {
        final tool = ReadSourceContentTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({'sourceId': 's1'});

        expect(result['pageCount'], 9);
      });

      test('omits pageCount when extractionMeta is absent', () async {
        sourceRepo = FakeSourceRepository()
          ..add(_source('bare', 'Bare', chunks: ''));
        final tool = ReadSourceContentTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({'sourceId': 'bare'});

        expect(result['success'], isTrue);
        expect(result.containsKey('pageCount'), isFalse);
        expect(result['chunkCount'], 0);
      });

      test('gracefully handles malformed chunks JSON', () async {
        sourceRepo = FakeSourceRepository()
          ..add(_source('corrupt', 'Corrupt', chunks: 'not valid json'));
        final tool = ReadSourceContentTool(
          sourceRepo: sourceRepo,
          studentIdService: studentIdService,
        );
        final result = await tool.execute({'sourceId': 'corrupt'});

        expect(result['success'], isTrue);
        expect(result['chunkCount'], 0);
        expect(result['chunks'], isEmpty);
      });
    });
  });
}
