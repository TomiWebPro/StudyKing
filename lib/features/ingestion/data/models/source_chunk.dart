import 'dart:convert';

import 'package:studyking/core/utils/logger.dart';

class SourceChunk {
  static final Logger _logger = const Logger('SourceChunk');

  final int chunkIndex;
  final int? pageStart;
  final int? pageEnd;
  final String text;
  final String? heading;

  SourceChunk({
    required this.chunkIndex,
    this.pageStart,
    this.pageEnd,
    required this.text,
    this.heading,
  });

  Map<String, dynamic> toJson() => {
    'chunkIndex': chunkIndex,
    'pageStart': pageStart,
    'pageEnd': pageEnd,
    'text': text,
    'heading': heading,
  };

  factory SourceChunk.fromJson(Map<String, dynamic> json) => SourceChunk(
    chunkIndex: json['chunkIndex'] as int,
    pageStart: json['pageStart'] as int?,
    pageEnd: json['pageEnd'] as int?,
    text: json['text'] as String? ?? '',
    heading: json['heading'] as String?,
  );

  /// Parses the persisted `chunks` JSON string of a [Source] back into
  /// [SourceChunk] objects. Returns an empty list for absent/empty/malformed
  /// JSON rather than throwing, so a corrupted source never blocks the UI or
  /// the agent.
  static List<SourceChunk> parse(String json) {
    if (json.isEmpty) return const [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((m) => SourceChunk.fromJson(m))
            .toList(growable: false);
      }
    } catch (e, stack) {
      _logger.w('Failed to parse chunks JSON', e, stack);
    }
    return const [];
  }
}

/// A single chunk-level search match returned by [SourceRepository.searchChunks].
///
/// Carries enough provenance (source ID + page range + heading) for the mentor
/// LLM to cite where an excerpt came from in its grounded answers. This is the
/// typed analogue of the map produced by `SearchSourcesTool.execute`, so both
/// the reactive agent tool and the proactive mentor-context injection share a
/// single search path (Vision Next-Term §3.1 / §4.1 — the mentor should be
/// able to "find and quote the relevant chunk").
class SourceChunkSearchMatch {
  final String sourceId;
  final String sourceTitle;
  final String sourceType;
  final String? subjectId;
  final String? topicId;
  final String? topicConfidence;
  final int chunkIndex;
  final int? pageStart;
  final int? pageEnd;
  final String? heading;
  final String excerpt;

  SourceChunkSearchMatch({
    required this.sourceId,
    required this.sourceTitle,
    required this.sourceType,
    this.subjectId,
    this.topicId,
    this.topicConfidence,
    required this.chunkIndex,
    this.pageStart,
    this.pageEnd,
    this.heading,
    required this.excerpt,
  });

  /// Serialises to the map format expected by the agent tool result contract
  /// (kept compatible with the previous `SearchSourcesTool` output).
  Map<String, dynamic> toMap() => {
        'sourceId': sourceId,
        'title': sourceTitle,
        'type': sourceType,
        'chunkIndex': chunkIndex,
        if (pageStart != null) 'pageStart': pageStart,
        if (pageEnd != null) 'pageEnd': pageEnd,
        if (heading != null && heading!.isNotEmpty) 'heading': heading,
        'excerpt': excerpt,
        if (subjectId != null && subjectId!.isNotEmpty) 'subjectId': subjectId,
        if (topicId != null && topicId!.isNotEmpty) 'topicId': topicId,
        if (topicConfidence != null && topicConfidence!.isNotEmpty) 'topicConfidence': topicConfidence,
      };
}
