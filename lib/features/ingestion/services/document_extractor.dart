import 'package:studyking/core/data/enums.dart';

class DocumentExtractor {
  String extractText({
    required String rawContent,
    required SourceType sourceType,
  }) {
    switch (sourceType) {
      case SourceType.pdf:
      case SourceType.document:
      case SourceType.textbook:
      case SourceType.syllabus:
      case SourceType.lectureNotes:
      case SourceType.externalResource:
      case SourceType.webPage:
        return rawContent;
      case SourceType.image:
        return rawContent;
      case SourceType.video:
      case SourceType.audio:
        return rawContent;
    }
  }

  int estimateChunkCount(String text, {int chunkSize = 2000}) {
    if (text.isEmpty) return 0;
    return (text.length / chunkSize).ceil();
  }
}
