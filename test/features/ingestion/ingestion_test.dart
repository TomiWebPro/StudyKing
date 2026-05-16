import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/ingestion/ingestion.dart';

void main() {
  group('ingestion barrel', () {
    test('exports SourceRepository', () => expect(SourceRepository, isNotNull));
    test('exports ContentPipeline', () => expect(ContentPipeline, isNotNull));
    test('exports UploadScreen', () => expect(UploadScreen, isNotNull));
  });
}
