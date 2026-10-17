import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/models/source_chunk.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';

/// Lets the mentor agent **surface recently uploaded or accessed ingested
/// materials** as a paged list, so the mentor can say "let's revisit the
/// textbook you uploaded last week" instead of relying on the student to
/// re-state the source ID.
///
/// Vision Next-Term §3 / scenario_ingestion_pdf_to_knowledge_base Step 5:
/// "revisit view of all materials." Before this tool the mentor could only
/// [ReadSourceContentTool] list all sources at once (no pagination, no sort,
/// no recency ordering). This tool closes the conversational revisit gap.
///
/// This is a read-only lookup tool (no LLM spend), so it extends [AgentTool]
/// directly rather than [PrepTool].
class RevisitSourcesTool extends AgentTool {
  static final Logger _logger = const Logger('RevisitSourcesTool');

  final SourceRepository _sourceRepo;
  final StudentIdService _studentIdService;

  RevisitSourcesTool({
    required SourceRepository sourceRepo,
    required StudentIdService studentIdService,
  })  : _sourceRepo = sourceRepo,
        _studentIdService = studentIdService;

  @override
  String get name => 'revisit_sources';

  @override
  String get description =>
      'List the student\'s ingested study materials (textbooks, notes, '
      'question banks, syllabi, media) as a paged, recency-ordered view. '
      'Use this when the student asks to revisit previously uploaded sources '
      'or when planning lessons from material they already have.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'limit': {
            'type': 'integer',
            'description': 'Maximum number of sources to return.',
            'default': 10,
          },
          'offset': {
            'type': 'integer',
            'description': 'Number of sources to skip (for pagination).',
            'default': 0,
          },
          'subjectId': {
            'type': 'string',
            'description':
                'Optional subject ID to limit the listing to one subject.',
          },
        },
        'required': [],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final limit = AgentTool.intArg(args, 'limit') ?? 10;
    final offset = AgentTool.intArg(args, 'offset') ?? 0;
    final subjectId = (args['subjectId'] as String?)?.trim() ?? '';

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

    // Sort by recency: createdAt desc, falling back to id for stability.
    List<Source> sorted = List.of(sources)
      ..sort((a, b) {
        final ta = a.createdAt ?? DateTime.fromMicrosecondsSinceEpoch(0);
        final tb = b.createdAt ?? DateTime.fromMicrosecondsSinceEpoch(0);
        final cmp = tb.compareTo(ta);
        return cmp != 0 ? cmp : a.id.compareTo(b.id);
      });

    if (subjectId.isNotEmpty) {
      sorted = sorted.where((s) => s.subjectId == subjectId).toList();
    }

    final total = sorted.length;
    final paged = sorted.skip(offset).take(limit).toList();
    final hasMore = offset + paged.length < total;

    return {
      'success': true,
      'sourceCount': paged.length,
      'totalCount': total,
      'offset': offset,
      'limit': limit,
      'hasMore': hasMore,
      'sources': paged.map((s) => _sourceEntry(s)).toList(),
    };
  }

  Map<String, dynamic> _sourceEntry(Source source) => {
        'id': source.id,
        'title': source.title,
        'type': source.type.name,
        'status': source.processingStatus,
        'subjects': source.subjectId,
        'topicId': source.topicId,
        'chunkCount': SourceChunk.parse(source.chunks).length,
        if (source.createdAt != null)
          'createdAt': source.createdAt!.toIso8601String(),
      };
}
