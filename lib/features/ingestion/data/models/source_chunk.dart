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
