import 'package:studyking/features/ingestion/data/models/source_chunk.dart';

class ExtractionResult {
  final String text;
  final String extractionMethod;
  final int? pageCount;
  final double? ocrConfidence;
  final int? durationSeconds;
  final String? mimeType;
  final List<SourceChunk> chunks;

  ExtractionResult({
    required this.text,
    this.extractionMethod = 'direct',
    this.pageCount,
    this.ocrConfidence,
    this.durationSeconds,
    this.mimeType,
    this.chunks = const [],
  });

  Map<String, dynamic> toMetaJson() {
    final meta = <String, dynamic>{
      'extractionMethod': extractionMethod,
    };
    if (pageCount != null) meta['pageCount'] = pageCount;
    if (ocrConfidence != null) meta['ocrConfidence'] = ocrConfidence;
    if (durationSeconds != null) meta['durationSeconds'] = durationSeconds;
    if (mimeType != null) meta['mimeType'] = mimeType;
    return meta;
  }

  String chunksToJson() {
    if (chunks.isEmpty) return '';
    return '[${chunks.map((c) => c.toJson()).join(',')}]';
  }
}
