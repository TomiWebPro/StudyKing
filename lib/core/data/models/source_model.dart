import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/utils/logger.dart';

@HiveType(typeId: 26)
class Source extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final SourceType type;

  @HiveField(3, defaultValue: '')
  final String content;

  @HiveField(4, defaultValue: '')
  final String subjectId;

  @HiveField(5, defaultValue: '')
  final String topicId;

  @HiveField(6, defaultValue: '')
  final String syllabusId;

  @HiveField(7, defaultValue: '')
  final String sourceUrl;

  @HiveField(8, defaultValue: '')
  final String studentId;

  @HiveField(9, defaultValue: '')
  final String language;

  @HiveField(10, defaultValue: '')
  final String summary;

  @HiveField(11, defaultValue: 'pending')
  final String processingStatus;

  @HiveField(12, defaultValue: '')
  final String extractedText;

  @HiveField(13, defaultValue: [])
  final List<String> generatedQuestionIds;

  @HiveField(14, defaultValue: '')
  final String extractionMethod;

  @HiveField(15, defaultValue: '')
  final String chunks;

  @HiveField(16, defaultValue: '')
  final String extractionMeta;

  @HiveField(17)
  final DateTime? createdAt;

  @HiveField(18, defaultValue: '')
  final String errorMessage;

  @HiveField(19, defaultValue: '')
  final String contentHash;

  @HiveField(20, defaultValue: [])
  final List<String> generatedFlashcardIds;

  @HiveField(21, defaultValue: '')
  final String generatedStudyGuideId;

  @HiveField(22, defaultValue: '')
  final String generatedConceptMapId;

  /// JSON-serialized figure metadata (bytes base64-encoded) extracted from the
  /// source. Figures are discovered during extraction (PDF `/XObject` images or
  /// embedded office assets) and surfaced in the source-revisit UX so students
  /// and the mentor agent can ground chart reconstruction on the original
  /// visuals (Vision Next-Term §4.1 / §24). Mirrors the `chunks` pattern: a
  /// single text column parsed via [SourceFigure.parse].
  @HiveField(23, defaultValue: '')
  final String figuresJson;

  Source({
    required this.id,
    required this.title,
    required this.type,
    this.content = '',
    this.subjectId = '',
    this.topicId = '',
    this.syllabusId = '',
    this.sourceUrl = '',
    this.studentId = '',
    this.language = '',
    this.summary = '',
    this.processingStatus = 'pending',
    this.extractedText = '',
    this.generatedQuestionIds = const [],
    this.extractionMethod = '',
    this.chunks = '',
    this.extractionMeta = '',
    this.createdAt,
    this.errorMessage = '',
    this.contentHash = '',
    this.generatedFlashcardIds = const [],
    this.generatedStudyGuideId = '',
    this.generatedConceptMapId = '',
    this.figuresJson = '',
  });

  ProcessingStatus get statusEnum => ProcessingStatus.values.firstWhere(
    (e) => e.name == processingStatus,
    orElse: () => ProcessingStatus.pending,
  );

  static final Logger _logger = const Logger('Source');

  /// Reads the recorded page count from the source's `extractionMeta` JSON, if
  /// present. Returns null when the meta is absent or unparseable.
  int? get pageCount {
    if (extractionMeta.isEmpty) return null;
    try {
      final decoded = jsonDecode(extractionMeta);
      if (decoded is Map && decoded['pageCount'] is int) {
        return decoded['pageCount'] as int;
      }
    } catch (e, stack) {
      _logger.w('Failed to parse extractionMeta for source $id', e, stack);
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.name,
    'content': content,
    'subjectId': subjectId,
    'topicId': topicId,
    'syllabusId': syllabusId,
    'sourceUrl': sourceUrl,
    'studentId': studentId,
    'language': language,
    'summary': summary,
    'processingStatus': processingStatus,
    'extractedText': extractedText,
    'generatedQuestionIds': generatedQuestionIds,
    'extractionMethod': extractionMethod,
    'chunks': chunks,
    'extractionMeta': extractionMeta,
    'createdAt': createdAt?.toIso8601String(),
    'errorMessage': errorMessage,
    'contentHash': contentHash,
    'generatedFlashcardIds': generatedFlashcardIds,
    'generatedStudyGuideId': generatedStudyGuideId,
    'generatedConceptMapId': generatedConceptMapId,
    'figuresJson': figuresJson,
  };

  factory Source.fromJson(Map<String, dynamic> json) => Source(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    type: SourceType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => SourceType.pdf,
    ),
    content: json['content'] as String? ?? '',
    subjectId: json['subjectId'] as String? ?? '',
    topicId: json['topicId'] as String? ?? '',
    syllabusId: json['syllabusId'] as String? ?? '',
    sourceUrl: json['sourceUrl'] as String? ?? '',
    studentId: json['studentId'] as String? ?? '',
    language: json['language'] as String? ?? '',
    summary: json['summary'] as String? ?? '',
    processingStatus: json['processingStatus'] as String? ?? 'pending',
    extractedText: json['extractedText'] as String? ?? '',
    generatedQuestionIds: (json['generatedQuestionIds'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
    extractionMethod: json['extractionMethod'] as String? ?? '',
    chunks: json['chunks'] as String? ?? '',
    extractionMeta: json['extractionMeta'] as String? ?? '',
    createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    errorMessage: json['errorMessage'] as String? ?? '',
    contentHash: json['contentHash'] as String? ?? '',
    generatedFlashcardIds: (json['generatedFlashcardIds'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
    generatedStudyGuideId: json['generatedStudyGuideId'] as String? ?? '',
    generatedConceptMapId: json['generatedConceptMapId'] as String? ?? '',
    figuresJson: json['figuresJson'] as String? ?? '',
  );

  Source copyWith({
    String? id,
    String? title,
    SourceType? type,
    String? content,
    String? subjectId,
    String? topicId,
    String? syllabusId,
    String? sourceUrl,
    String? studentId,
    String? language,
    String? summary,
    String? processingStatus,
    String? extractedText,
    List<String>? generatedQuestionIds,
    String? extractionMethod,
    String? chunks,
    String? extractionMeta,
    DateTime? createdAt,
    String? errorMessage,
    String? contentHash,
    List<String>? generatedFlashcardIds,
    String? generatedStudyGuideId,
    String? generatedConceptMapId,
    String? figuresJson,
  }) {
    return Source(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      content: content ?? this.content,
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      syllabusId: syllabusId ?? this.syllabusId,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      studentId: studentId ?? this.studentId,
      language: language ?? this.language,
      summary: summary ?? this.summary,
      processingStatus: processingStatus ?? this.processingStatus,
      extractedText: extractedText ?? this.extractedText,
      generatedQuestionIds: generatedQuestionIds ?? this.generatedQuestionIds,
      extractionMethod: extractionMethod ?? this.extractionMethod,
      chunks: chunks ?? this.chunks,
      extractionMeta: extractionMeta ?? this.extractionMeta,
      createdAt: createdAt ?? this.createdAt,
      errorMessage: errorMessage ?? this.errorMessage,
      contentHash: contentHash ?? this.contentHash,
      generatedFlashcardIds: generatedFlashcardIds ?? this.generatedFlashcardIds,
      generatedStudyGuideId: generatedStudyGuideId ?? this.generatedStudyGuideId,
      generatedConceptMapId: generatedConceptMapId ?? this.generatedConceptMapId,
      figuresJson: figuresJson ?? this.figuresJson,
    );
  }
}
