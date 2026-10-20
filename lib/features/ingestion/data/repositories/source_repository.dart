import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/string_extensions.dart';
import 'package:studyking/features/ingestion/data/models/source_chunk.dart';

class SourceRepository extends Repository<Source> {
  SourceRepository() : super(boxName: HiveBoxNames.sources);

  static final Logger _logger = const Logger('SourceRepository');

  Future<void> init() async {
    await openBox(HiveBoxNames.sources);
  }

  Future<void> _ensureReady() async {
    if (!isOpen) await init();
  }

  Future<Result<void>> create(Source source) async {
    await _ensureReady();
    final result = await save(source.id, source);
    if (result.isFailure) {
      _logger.w('Failed to create source ${source.id}', result.error);
    }
    return result;
  }

  Future<Result<List<Source>>> getBySubject(String subjectId) async {
    try {
      await _ensureReady();
      return Result.success(filterBy((s) => s.subjectId, subjectId));
    } catch (e) {
      _logger.w('Failed to get sources by subject: $e', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Source>>> getByTopic(String topicId) async {
    try {
      await _ensureReady();
      return Result.success(filterBy((s) => s.topicId, topicId));
    } catch (e) {
      _logger.w('Failed to get sources by topic: $e', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Source>>> getByStudent(String studentId) async {
    try {
      await _ensureReady();
      return Result.success(filterBy((s) => s.studentId, studentId));
    } catch (e) {
      _logger.w('Failed to get sources by student: $e', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Source>>> getByType(String sourceType) async {
    try {
      await _ensureReady();
      return Result.success(box.values.where((s) => s.type.name == sourceType).toList());
    } catch (e) {
      _logger.w('Failed to get sources by type: $e', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Source>>> getByStatus(ProcessingStatus status) async {
    try {
      await _ensureReady();
      return Result.success(box.values.where((s) => s.statusEnum == status).toList());
    } catch (e) {
      _logger.w('Failed to get sources by status: $e', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Source>>> getPending() async {
    return getByStatus(ProcessingStatus.pending);
  }

  Future<Result<List<Source>>> getFailed() async {
    return getByStatus(ProcessingStatus.failed);
  }

  Future<Result<List<Source>>> getCompleted() async {
    return getByStatus(ProcessingStatus.completed);
  }

  /// Upper bound on the number of excerpt characters injected for a matching
  /// chunk so the mentor prompt stays bounded.
  static const int _maxExcerptLength = 300;

  /// Searches the chunks of all of a student's ingested sources for [query].
  ///
  /// Returns bounded excerpts (source ID + page range + heading) so the mentor
  /// context builder can proactively inject relevant textbook material —
  /// Vision Next-Term §3.1 / §4.1 (scenario_ingestion_pdf_to_knowledge_base
  /// Step 3: "the mentor should find and quote the relevant chunk").
  ///
  /// Uses normalised-substring matching over chunk text — the same strategy as
  /// `SearchSourcesTool` — so the repository and the agent tool share one search
  /// path. Semantic / embedding search is a planned future enhancement.
  Future<Result<List<SourceChunkSearchMatch>>> searchChunks(
    String query,
    String studentId, {
    String? subjectId,
    int limit = 10,
  }) async {
    try {
      final result = await getByStudent(studentId);
      if (result.isFailure) {
        return Result.failure(result.error ?? 'Failed to load sources for search');
      }
      final sources = result.data ?? [];
      final normalizedQuery = query.normalized;
      if (normalizedQuery.isEmpty || sources.isEmpty) {
        return Result.success(const []);
      }
      return Result.success(
        _searchChunks(sources, normalizedQuery, subjectId, limit),
      );
    } catch (e, stack) {
      _logger.w('Failed to search chunks for query "$query"', e, stack);
      return Result.failure(e.toString());
    }
  }

  List<SourceChunkSearchMatch> _searchChunks(
    List<Source> sources,
    String normalizedQuery,
    String? subjectId,
    int limit,
  ) {
    final matches = <SourceChunkSearchMatch>[];
    for (final source in sources) {
      if (subjectId != null &&
          subjectId.isNotEmpty &&
          source.subjectId != subjectId) {
        continue;
      }
      final chunks = SourceChunk.parse(source.chunks);
      for (final chunk in chunks) {
        final text = chunk.text;
        if (text.normalized.contains(normalizedQuery)) {
          matches.add(SourceChunkSearchMatch(
            sourceId: source.id,
            sourceTitle: source.title,
            sourceType: source.type.name,
            subjectId: source.subjectId.isNotEmpty ? source.subjectId : null,
            topicId: source.topicId.isNotEmpty ? source.topicId : null,
            topicConfidence: source.topicConfidence.isNotEmpty ? source.topicConfidence : null,
            chunkIndex: chunk.chunkIndex,
            pageStart: chunk.pageStart,
            pageEnd: chunk.pageEnd,
            heading: chunk.heading,
            excerpt: _boundedExcerpt(text, _maxExcerptLength),
          ));
          if (matches.length >= limit) return matches;
        }
      }
    }
    return matches;
  }

  /// Truncates [text] to [maxLength] characters (trimmed) and appends an
  /// ellipsis so chunk excerpts stay digestible for the agent prompt.
  static String _boundedExcerpt(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength).trimRight()}…';
  }
}
