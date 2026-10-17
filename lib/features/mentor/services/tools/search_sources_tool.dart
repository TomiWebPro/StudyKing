import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/logger.dart';
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

    // Delegate chunk search to the repository (single source of truth shared
    // with MentorContextBuilder). Request limit+1 so we can detect whether more
    // matches exist beyond the requested limit.
    final result = await _sourceRepo.searchChunks(
      query,
      studentId,
      subjectId: subjectId,
      limit: limit + 1,
    );
    if (result.isFailure) {
      _logger.w(
        'Failed to search sources for query "$query"',
        result.error,
      );
      return {
        'success': false,
        'error': result.error ?? 'Failed to search sources',
      };
    }

    final matches = result.data ?? [];
    final hasMore = matches.length > limit;
    return _buildResult(
      query,
      matches.take(limit).map((m) => m.toMap()).toList(),
      hadMore: hasMore,
    );
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
