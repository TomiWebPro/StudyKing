import 'dart:convert';
import 'dart:typed_data';

import 'package:studyking/core/utils/logger.dart';

/// A single image (figure, chart, diagram) extracted from an ingested source.
///
/// Figures are discovered during text extraction — from PDF `/XObject` image
/// streams or from embedded assets in office documents (DOCX/PPTX/ODT). Each
/// figure carries enough provenance (`pageNumber`, `caption`, `source`) for the
/// student to revisit it and for the mentor agent to ground chart
/// reconstruction on the original visual.
///
/// Figures are persisted on [Source] as a JSON string (`Source.figuresJson`)
/// with the pixel bytes base64-encoded — the same pattern used for `chunks`.
/// This keeps Hive's native storage simple (a single text field) while still
/// letting the figure survive ingestion end-to-end (Vision Next-Term §4.1).
class SourceFigure {
  static final Logger _logger = const Logger('SourceFigure');

  /// 1-based page number the figure appeared on, or 0 when unknown
  /// (e.g. office documents without reliable page mapping).
  final int pageNumber;

  /// Decoded pixel bytes of the figure. For JPEG images these are the raw
  /// JPEG file bytes; for FlateDecode images they are the decompressed pixels
  /// wrapped for the renderer. Empty when the bytes could not be recovered.
  final Uint8List bytes;

  /// Optional human-readable caption, e.g. "Figure 3: Carbon cycle".
  final String caption;

  /// MIME type such as `image/png` / `image/jpeg`, used by the renderer to
  /// decode the bytes.
  final String mimeType;

  /// Origin format: `pdf` | `docx` | `pptx` | `odt` | `...`.
  final String source;

  SourceFigure({
    required this.pageNumber,
    required this.bytes,
    this.caption = '',
    this.mimeType = '',
    this.source = '',
  });

  bool get hasBytes => bytes.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'pageNumber': pageNumber,
        'bytes': base64Encode(bytes),
        'caption': caption,
        'mimeType': mimeType,
        'source': source,
      };

  factory SourceFigure.fromJson(Map<String, dynamic> json) => SourceFigure(
        pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 0,
        bytes: _decodeBase64(json['bytes'] as String? ?? ''),
        caption: json['caption'] as String? ?? '',
        mimeType: json['mimeType'] as String? ?? '',
        source: json['source'] as String? ?? '',
      );

  static Uint8List _decodeBase64(String input) {
    if (input.isEmpty) return Uint8List(0);
    try {
      return base64Decode(input);
    } catch (e, stack) {
      _logger.w('Failed to decode figure base64 bytes', e, stack);
      return Uint8List(0);
    }
  }

  /// Serializes [figures] to a JSON string that [parse] can round-trip.
  /// Returns `''` when the list is empty so the storage column stays empty
  /// (not `'[]'`), matching the [SourceChunk] convention.
  static String encode(List<SourceFigure> figures) {
    if (figures.isEmpty) return '';
    return jsonEncode(figures.map((f) => f.toJson()).toList());
  }

  /// Parses the persisted `figuresJson` string of a [Source] back into
  /// [SourceFigure] objects. Returns an empty list for absent/empty/malformed
  /// JSON rather than throwing, so a corrupted source never blocks the UI.
  static List<SourceFigure> parse(String jsonString) {
    if (jsonString.isEmpty) return const [];
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((m) => SourceFigure.fromJson(m))
            .toList(growable: false);
      }
    } catch (e, stack) {
      _logger.w('Failed to parse figures JSON', e, stack);
    }
    return const <SourceFigure>[];
  }
}
