import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/string_extensions.dart';
import 'package:studyking/features/ingestion/data/models/source_chunk.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';

/// Lets the mentor agent **search across ingested source material** by keyword,
/// returning chunks with source + page citations so the agent can ground
/// answers in the student's actual textbook content.
///
/// Vision Next-Term §1–§3 / scenario_ingestion_pdf_to_knowledge_base Step 3:
/// "Mentor can cite the textbook when answering questions." Before this tool
/// the mentor could only [ReadSourceContentTool] read a source whose ID and
/// page range were already known. This tool closes the conversational search
/// gap: "Where does my textbook discuss aldol condensation?"
///
/// This is a read-only lookup tool (no LLM spend), so it extends [AgentTool]
/// directly rather than [PrepTool].
class SearchSourcesTool extends AgentTool {
  static final Logger _logger = const Logger('SearchSourcesTool');

  final SourceRepository _sourceRepo;
  final StudentIdService _studentIdService;

  SearchSourcesTool({
    required SourceRepository sourceRepo,
    required StudentIdService studentIdService,
  })  : _sourceRepo = sourceRepo,
        _studentIdService = studentIdService;

  @override
  String get name => 'search_sources';

  @override
  String get description =>
      'Search across the student\'s ingested study materials (textbooks, '
      'notes, question banks, syllabi) for a keyword or phrase. Returns '
      'matching chunks with source ID, page citation, and bounded excerpt '
      'text so the mentor can cite the material when answering questions.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description':
                'Search keyword or phrase to find in source content.',
          },
          'subjectId': {
            'type': 'string',
            'description':
                'Optional subject ID to limit the search scope.',
          },
          'limit': {
            'type': 'integer',
            'description': 'Maximum number of matching chunks to return.',
            'default': 10,
          },
        },
        'required': ['query'],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final query = (args['query'] as String?)?.trim() ?? '';
    if (query.isEmpty) {
      return {
        'success': false,
        'error': 'query parameter is required',
      };
    }

    final subjectId = (args['subjectId'] as String?)?.trim() ?? '';
    final limit = AgentTool.intArg(args, 'limit') ?? 10;

    final studentId = _studentIdService.getStudentId().data ?? '';
    if (studentId.isEmpty) {
      return {
        'success': false,
        'error': 'Unable to resolve studentId',
      };
    }

    final result = await _sourceRepo.getByStudent(studentId);
    if (result.isFailure) {
      _logger.w(
        'Failed to load sources for student $studentId',
        result.error,
      );
      return {
        'success': false,
        'error': result.error ?? 'Failed to load sources',
      };
    }

    final sources = result.data ?? [];
    final normalizedQuery = query.normalized;

    // Bound the excerpt so responses stay digestible for the agent.
    const maxExcerptLength = 300;

    final matches = <Map<String, dynamic>>[];
    var hitLimit = false;
    for (final source in sources) {
      if (subjectId.isNotEmpty && source.subjectId != subjectId) continue;

      final chunks = SourceChunk.parse(source.chunks);
      for (final chunk in chunks) {
        final text = chunk.text;
        if (text.normalized.contains(normalizedQuery)) {
          matches.add({
            'sourceId': source.id,
            'title': source.title,
            'type': source.type.name,
            'chunkIndex': chunk.chunkIndex,
            if (chunk.pageStart != null) 'pageStart': chunk.pageStart,
            if (chunk.pageEnd != null) 'pageEnd': chunk.pageEnd,
            if (chunk.heading != null && chunk.heading!.isNotEmpty)
              'heading': chunk.heading,
            'excerpt': _boundedExcerpt(text, maxExcerptLength),
            if (source.subjectId.isNotEmpty) 'subjectId': source.subjectId,
            if (source.topicId.isNotEmpty) 'topicId': source.topicId,
          });
          if (matches.length >= limit) {
            hitLimit = true;
            break;
          }
        }
      }
      if (hitLimit) break;
    }

    return _buildResult(query, matches, hadMore: hitLimit);
  }

  String _boundedExcerpt(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength).trimRight()}…';
  }

  Map<String, dynamic> _buildResult(
    String query,
    List<Map<String, dynamic>> matches, {
    required bool hadMore,
  }) =>
      {
        'success': true,
        'query': query,
        'matchCount': matches.length,
        'hasMore': hadMore,
        'results': matches,
      };
}
