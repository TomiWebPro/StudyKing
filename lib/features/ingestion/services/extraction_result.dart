import 'dart:convert';

import 'package:studyking/core/data/models/source_figure.dart';
import 'package:studyking/features/ingestion/data/models/source_chunk.dart';

class ExtractionResult {
  final String text;
  final String extractionMethod;
  final int? pageCount;
  final double? ocrConfidence;
  final double? transcriptionConfidence;
  final int? durationSeconds;
  final String? mimeType;
  final String? errorMessage;
  final List<SourceChunk> chunks;

  /// Images (figures, charts, diagrams) discovered during extraction. `null`
  /// when the extractor does not collect figures; an empty list when the
  /// source had no figures. Persisted onto [Source.figuresJson] so figures
  /// survive ingestion (Vision Next-Term §4.1 / agent_must_read.md §24).
  final List<SourceFigure> figures;

  /// When `true`, the text was truncated to fit within the configured
  /// per-source character ceiling. The student should be told that content
  /// was cut off.
  final bool truncated;

  /// User-visible note explaining why truncation occurred (e.g. file too
  /// large). Set when [truncated] is `true`.
  final String? truncationNote;

  ExtractionResult({
    required this.text,
    this.extractionMethod = 'direct',
    this.pageCount,
    this.ocrConfidence,
    this.transcriptionConfidence,
    this.durationSeconds,
    this.mimeType,
    this.errorMessage,
    this.chunks = const [],
    this.figures = const [],
    this.truncated = false,
    this.truncationNote,
  });

  bool get isError => errorMessage != null;

  Map<String, dynamic> toMetaJson() {
    final meta = <String, dynamic>{
      'extractionMethod': extractionMethod,
    };
    if (pageCount != null) meta['pageCount'] = pageCount;
    if (ocrConfidence != null) meta['ocrConfidence'] = ocrConfidence;
    if (transcriptionConfidence != null) meta['transcriptionConfidence'] = transcriptionConfidence;
    if (durationSeconds != null) meta['durationSeconds'] = durationSeconds;
    if (mimeType != null) meta['mimeType'] = mimeType;
    if (errorMessage != null) meta['errorMessage'] = errorMessage;
    if (truncated) {
      meta['truncated'] = true;
      if (truncationNote != null) meta['truncationNote'] = truncationNote;
    }
    // Vision integrity: record how many figures survived extraction so the
    // mentor pipeline and tests can audit figure retention (agent_must_read.md
    // §24 / Vision Next-Term §4.1).
    if (figures.isNotEmpty) meta['figureCount'] = figures.length;
    return meta;
  }

  /// Serializes figures to a JSON string that [SourceFigure.parse] can
  /// round-trip. Returns `''` when there are no figures so the storage column
  /// stays empty (not `'[]'`), matching [SourceChunk] conventions.
  String figuresToJson() {
    if (figures.isEmpty) return '';
    return SourceFigure.encode(figures);
  }
  String chunksToJson() {
    if (chunks.isEmpty) return '';
    return jsonEncode(chunks.map((c) => c.toJson()).toList());
  }
}
