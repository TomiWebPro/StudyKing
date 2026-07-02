import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/practice/presentation/widgets/source_practice_sheet.dart';

void main() {
  group('SourceItemData', () {
    test('creates instance with default status', () {
      const item = SourceItemData(id: 's1', title: 'Test', questionCount: 0);
      expect(item.status, ProcessingStatus.completed);
    });

    test('creates instance with specified status', () {
      const item = SourceItemData(id: 's1', title: 'Test', questionCount: 5, status: ProcessingStatus.failed);
      expect(item.status, ProcessingStatus.failed);
      expect(item.questionCount, 5);
    });

    test('creates instance with all parameters', () {
      const item = SourceItemData(
        id: 'src-1',
        title: 'Chapter 5',
        questionCount: 12,
        status: ProcessingStatus.pending,
      );
      expect(item.id, 'src-1');
      expect(item.title, 'Chapter 5');
      expect(item.questionCount, 12);
      expect(item.status, ProcessingStatus.pending);
    });
  });
}
