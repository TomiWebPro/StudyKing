import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/presentation/widgets/source_practice_sheet.dart';

void main() {
  group('SourceItemData', () {
    test('creates instance with correct field values', () {
      const item = SourceItemData(id: 's1', title: 'Test', questionCount: 10);
      expect(item.id, equals('s1'));
      expect(item.title, equals('Test'));
      expect(item.questionCount, equals(10));
    });
  });
}
