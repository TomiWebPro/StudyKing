import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/core/data/enums.dart';

void main() {
  group('Source', () {
    test('creates source with required fields', () {
      final source = Source(
        id: 'source-1',
        title: 'Math Textbook',
        type: SourceType.textbook,
      );
      expect(source.id, 'source-1');
      expect(source.title, 'Math Textbook');
      expect(source.type, SourceType.textbook);
      expect(source.content, '');
    });

    test('creates source with all fields', () {
      final source = Source(
        id: 'source-1',
        title: 'PDF Notes',
        type: SourceType.pdf,
        content: 'Chapter content',
      );
      expect(source.content, 'Chapter content');
    });

    test('creates source with different types', () {
      expect(Source(id: 's1', title: 't1', type: SourceType.pdf).type, SourceType.pdf);
      expect(Source(id: 's2', title: 't2', type: SourceType.syllabus).type, SourceType.syllabus);
      expect(Source(id: 's3', title: 't3', type: SourceType.video).type, SourceType.video);
      expect(Source(id: 's4', title: 't4', type: SourceType.lectureNotes).type, SourceType.lectureNotes);
      expect(Source(id: 's5', title: 't5', type: SourceType.externalResource).type, SourceType.externalResource);
    });
  });
}
