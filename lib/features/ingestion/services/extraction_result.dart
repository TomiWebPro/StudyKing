import 'dart:convert';

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
    return meta;
  }

  /// Serializes chunks to a valid JSON string that [SourceChunk.parse] can
  /// round-trip. Returns `''` when there are no chunks so the storage column
  /// stays empty (not `'[]'`).
  String chunksToJson() {
    if (chunks.isEmpty) return '';
    return jsonEncode(chunks.map((c) => c.toJson()).toList());
  }
}
