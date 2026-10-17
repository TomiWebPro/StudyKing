import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/ingestion/data/models/source_chunk.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';

/// Lets the mentor agent **read ingested source material** — the actual
/// chapters, sections, and page-cited chunks that lessons and question banks
/// should be grounded in.
///
/// Context: Vision Next-Term §3.1 (context the LLM needed vs. what the prompt
/// provides) and §4.1 (PDF/textbook parsing → knowledge base: chunk → embed →
/// link to topics/syllabi). The mentor prompt already surfaces a *source
/// inventory* (titles only); this tool closes the gap by letting the agent open
/// a source and read its organised chunks with page references. Without it the
/// agent plans lessons and question banks from metadata while the material it
/// needs sits behind an unreadable JSON string (see
/// `issues/open/ingestion-no-source-content-reader-tool`).
///
/// This is a read-only lookup tool (no LLM spend), so it extends [AgentTool]
/// directly rather than [PrepTool].
class ReadSourceContentTool extends AgentTool {
  static final Logger _logger = const Logger('ReadSourceContentTool');

  final SourceRepository _sourceRepo;
  final StudentIdService _studentIdService;

  ReadSourceContentTool({
    required SourceRepository sourceRepo,
    required StudentIdService studentIdService,
  })  : _sourceRepo = sourceRepo,
        _studentIdService = studentIdService;

  @override
  String get name => 'read_source_content';

  @override
  String get description =>
      "List the student's ingested study materials or read the organised "
      'chunks/pages of a specific source so lessons and questions can be '
      'grounded in the actual material. Provide a sourceId to read content; '
      "omit it to list the student's sources.";

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'sourceId': {
            'type': 'string',
            'description':
                'ID of the source to read. Omit to list the student\'s sources.',
          },
          'startPage': {
            'type': 'integer',
            'description':
                'First page to read (1-based, inclusive). Requires sourceId.',
          },
          'endPage': {
            'type': 'integer',
            'description':
                'Last page to read (1-based, inclusive). Requires sourceId.',
          },
          'chunkIndex': {
            'type': 'integer',
            'description':
                'Read a single chunk by its index. Requires sourceId.',
          },
          'maxChunks': {
            'type': 'integer',
            'description': 'Maximum chunks to return when reading a range.',
            'default': 20,
          },
        },
        'required': [],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final sourceId = (args['sourceId'] as String?)?.trim() ?? '';

    if (sourceId.isEmpty) {
      return _listSources();
    }
    return _readSource(sourceId, args);
  }

  /// Lists the current student's ingested sources with bounded metadata so the
  /// agent can decide which source to open.
  Future<Map<String, dynamic>> _listSources() async {
    final studentId = _studentIdService.getStudentId().data ?? '';
    if (studentId.isEmpty) {
      return {'error': 'Unable to resolve studentId'};
    }

    final result = await _sourceRepo.getByStudent(studentId);
    if (result.isFailure) {
      _logger.w('Failed to load sources for student $studentId', result.error);
      return {
        'success': false,
        'error': result.error ?? 'Failed to load sources',
      };
    }

    final sources = result.data ?? [];
    final entries = sources.map(_sourceEntry).toList();
    return {
      'success': true,
      'sourceCount': entries.length,
      'sources': entries,
    };
  }

  /// Reads chunks/pages of a single source, optionally filtered by page range
  /// or a specific chunk index.
  Future<Map<String, dynamic>> _readSource(
    String sourceId,
    Map<String, dynamic> args,
  ) async {
    final result = await _sourceRepo.get(sourceId);
    if (result.isFailure || result.data == null) {
      _logger.w('Source not found: $sourceId', result.error);
      return {'error': 'Source not found: $sourceId'};
    }

    final source = result.data!;
    final chunks = SourceChunk.parse(source.chunks);

    // Single-chunk read by index.
    final requestedIndex = AgentTool.intArg(args, 'chunkIndex');
    if (requestedIndex != null) {
      final match = chunks
          .where((c) => c.chunkIndex == requestedIndex)
          .firstOrNull;
      if (match == null) {
        return {
          'error': 'chunkIndex $requestedIndex not found in source $sourceId '
              '(chunkCount: ${chunks.length})',
        };
      }
      return _buildReadResult(source, [match]);
    }

    // Page-range read. A chunk is included when its page span overlaps the
    // requested range. When per-page info is absent, fall back to chunk index.
    final startPage = AgentTool.intArg(args, 'startPage');
    final endPage = AgentTool.intArg(args, 'endPage');
    final maxChunks = AgentTool.intArg(args, 'maxChunks') ?? 20;

    Iterable<SourceChunk> filtered = chunks;
    if (startPage != null || endPage != null) {
      final start = startPage ?? 1;
      final end = endPage ?? start;
      filtered = chunks.where((c) => _pageOverlapsRange(c, start, end));
    }

    final selected = filtered.take(maxChunks).toList();
    return _buildReadResult(source, selected);
  }

  /// True when the chunk's page span overlaps [start, end] (1-based inclusive).
  bool _pageOverlapsRange(SourceChunk chunk, int start, int end) {
    final lo = chunk.pageStart ?? chunk.chunkIndex + 1;
    final hi = chunk.pageEnd ?? chunk.pageStart ?? lo;
    return lo <= end && hi >= start;
  }

  Map<String, dynamic> _buildReadResult(
    Source source,
    List<SourceChunk> chunks,
  ) {
    final pageCount = source.pageCount;
    return {
      'success': true,
      'sourceId': source.id,
      'title': source.title,
      'type': source.type.name,
      'subjectId': source.subjectId,
      'topicId': source.topicId,
      'status': source.processingStatus,
      if (pageCount != null) 'pageCount': pageCount,
      'chunkCount': chunks.length,
      'chunks': chunks.map(_chunkEntry).toList(),
    };
  }

  Map<String, dynamic> _chunkEntry(SourceChunk chunk) => {
        'chunkIndex': chunk.chunkIndex,
        if (chunk.pageStart != null) 'pageStart': chunk.pageStart,
        if (chunk.pageEnd != null) 'pageEnd': chunk.pageEnd,
        if (chunk.heading != null && chunk.heading!.isNotEmpty)
          'heading': chunk.heading,
        'text': chunk.text,
      };

  Map<String, dynamic> _sourceEntry(Source source) => {
        'id': source.id,
        'title': source.title,
        'type': source.type.name,
        'subjectId': source.subjectId,
        'topicId': source.topicId,
        'status': source.processingStatus,
        'chunkCount': SourceChunk.parse(source.chunks).length,
        'hasContent': source.extractedText.isNotEmpty,
      };

}
