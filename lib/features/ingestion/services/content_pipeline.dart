import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/repositories/source_repository.dart';
import 'package:studyking/core/services/pdf_ingestion_service.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/utils/logger.dart';

class ContentPipeline {
  final PdfIngestionService _ingestionService;
  final SourceRepository _sourceRepository;
  final TopicRepository _topicRepository;
  final Logger _logger = const Logger('ContentPipeline');

  ContentPipeline({
    required PdfIngestionService ingestionService,
    required SourceRepository sourceRepository,
    required TopicRepository topicRepository,
  })  : _ingestionService = ingestionService,
        _sourceRepository = sourceRepository,
        _topicRepository = topicRepository;

  Future<Result<Source>> processUpload({
    required String title,
    required String content,
    required SourceType type,
    required String studentId,
    String subjectId = '',
    String topicId = '',
    String syllabusId = '',
    String sourceUrl = '',
    String language = '',
  }) async {
    try {
      final source = Source(
        id: 'src_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        type: type,
        content: content,
        subjectId: subjectId,
        topicId: topicId,
        syllabusId: syllabusId,
        sourceUrl: sourceUrl,
        studentId: studentId,
        language: language,
      );

      await _sourceRepository.create(source);
      _logger.i('Source saved: ${source.id}');
      return Result.success(source);
    } catch (e) {
      _logger.e('Failed to save source', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<Source>> processAndClassify({
    required String title,
    required String content,
    required SourceType type,
    required String studentId,
    required List<String> possibleTopics,
    required String modelId,
    String subjectId = '',
    String sourceUrl = '',
    String language = '',
  }) async {
    final classifyResult = await _ingestionService.classifyTopic(
      content: content,
      possibleTopics: possibleTopics,
      modelId: modelId,
    );

    String topicId = '';
    if (classifyResult.isSuccess) {
      final topicTitle = classifyResult.data!;
      try {
        final topics = await _topicRepository.getAll();
        final match = topics.where((t) =>
            t.title.toLowerCase().contains(topicTitle.toLowerCase())).firstOrNull;
        if (match != null) {
          topicId = match.id;
        }
      } catch (e) {
        _logger.e('Failed to look up topic by title', e);
      }
    }

    return await processUpload(
      title: title,
      content: content,
      type: type,
      studentId: studentId,
      subjectId: subjectId,
      topicId: topicId,
      sourceUrl: sourceUrl,
      language: language,
    );
  }

}
