import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/extraction/ocr_extractor.dart';
import 'package:studyking/features/ingestion/services/document_extractor.dart';

class _FakeOcrExtractor extends OcrExtractor {
  _FakeOcrExtractor() : super(modelId: 'test', localeName: 'en');

  @override
  Future<OcrExtractionResult> extractText({
    required String rawContent,
    required String? sourceUrl,
  }) async {
    return const OcrExtractionResult(
      text: '',
      extractionMethod: 'ocr_failed',
      errorMessage: 'Simulated OCR failure',
    );
  }
}

List<int> _createOdtArchive(String contentXml) {
  final encoder = ZipEncoder();
  final archive = Archive();
  final contentBytes = utf8.encode(contentXml);
  archive.addFile(ArchiveFile('content.xml', contentBytes.length, contentBytes));
  return encoder.encode(archive)!;
}

List<int> _createDocxArchive({
  String? documentXml,
  String? footnotesXml,
  String? relsXml,
}) {
  final encoder = ZipEncoder();
  final archive = Archive();

  final docBytes = utf8.encode(documentXml ?? '''
      <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
                  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
        <w:body>
          <w:p><w:r><w:t>Hello world</w:t></w:r></w:p>
        </w:body>
      </w:document>
    ''');
  archive.addFile(ArchiveFile('word/document.xml', docBytes.length, docBytes));

  if (footnotesXml != null) {
    final fnBytes = utf8.encode(footnotesXml);
    archive.addFile(ArchiveFile('word/footnotes.xml', fnBytes.length, fnBytes));
  }

  if (relsXml != null) {
    final relsBytes = utf8.encode(relsXml);
    archive.addFile(ArchiveFile('word/_rels/document.xml.rels', relsBytes.length, relsBytes));
  }

  return encoder.encode(archive)!;
}

List<int> _createDocxWithTable() {
  return _createDocxArchive(documentXml: '''
    <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
      <w:body>
        <w:tbl>
          <w:tr>
            <w:tc><w:p><w:r><w:t>Name</w:t></w:r></w:p></w:tc>
            <w:tc><w:p><w:r><w:t>Age</w:t></w:r></w:p></w:tc>
          </w:tr>
          <w:tr>
            <w:tc><w:p><w:r><w:t>Alice</w:t></w:r></w:p></w:tc>
            <w:tc><w:p><w:r><w:t>25</w:t></w:r></w:p></w:tc>
          </w:tr>
        </w:tbl>
      </w:body>
    </w:document>
  ''');
}

List<int> _createDocxWithFootnotes() {
  return _createDocxArchive(
    documentXml: '''
      <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
                  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
        <w:body>
          <w:p>
            <w:r><w:t>Some text</w:t></w:r>
            <w:r><w:footnoteReference w:id="1"/></w:r>
          </w:p>
        </w:body>
      </w:document>
    ''',
    footnotesXml: '''
      <w:footnotes xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
        <w:footnote w:id="1">
          <w:p><w:r><w:t>This is a footnote.</w:t></w:r></w:p>
        </w:footnote>
      </w:footnotes>
    ''',
  );
}

List<int> _createDocxWithImage() {
  return _createDocxArchive(
    documentXml: '''
      <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
                  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
                  xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
                  xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">
        <w:body>
          <w:p>
            <w:r>
              <w:t>Image below:</w:t>
            </w:r>
            <w:r>
              <w:drawing>
                <wp:inline>
                  <a:blip r:embed="rId1"/>
                </wp:inline>
              </w:drawing>
            </w:r>
          </w:p>
        </w:body>
      </w:document>
    ''',
    relsXml: '''
      <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/image1.png"/>
      </Relationships>
    ''',
  );
}

List<int> _createPptxWithImage() {
  final encoder = ZipEncoder();
  final archive = Archive();

  final slide1Bytes = utf8.encode('''
      <p:sld xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"
             xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
             xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
        <p:cSld>
          <p:spTree>
            <p:sp>
              <p:txBody>
                <a:p><a:r><a:t>Slide with image</a:t></a:r></a:p>
              </p:txBody>
            </p:sp>
            <p:pic>
              <p:blipFill>
                <a:blip r:embed="rId1"/>
              </p:blipFill>
            </p:pic>
          </p:spTree>
        </p:cSld>
      </p:sld>
    ''');
  archive.addFile(ArchiveFile('ppt/slides/slide1.xml', slide1Bytes.length, slide1Bytes));

  final rels1Bytes = utf8.encode('''
      <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/image1.png"/>
      </Relationships>
    ''');
  archive.addFile(ArchiveFile('ppt/_rels/presentation.xml.rels', rels1Bytes.length, rels1Bytes));

  return encoder.encode(archive)!;
}

void main() {
  group('DocumentExtractor', () {
    group('extractText', () {
      test('returns direct text for SourceType.pdf', () async {
        final extractor = DocumentExtractor(modelId: 'test-model', localeName: 'en');
        final result = await extractor.extractText(
          rawContent: 'pdf content',
          sourceType: SourceType.pdf,
        );
        expect(result.text, 'pdf content');
        expect(result.extractionMethod, 'pdf_text_direct');
      });

      test('returns direct text for SourceType.document', () async {
        final extractor = DocumentExtractor(modelId: 'test-model', localeName: 'en');
        final result = await extractor.extractText(
          rawContent: 'doc content',
          sourceType: SourceType.document,
        );
        expect(result.text, 'doc content');
      });

      test('returns direct text for SourceType.textbook', () async {
        final extractor = DocumentExtractor(modelId: 'test-model', localeName: 'en');
        final result = await extractor.extractText(
          rawContent: 'textbook content',
          sourceType: SourceType.textbook,
        );
        expect(result.text, 'textbook content');
      });

      test('returns direct text for SourceType.syllabus', () async {
        final extractor = DocumentExtractor(modelId: 'test-model', localeName: 'en');
        final result = await extractor.extractText(
          rawContent: 'syllabus content',
          sourceType: SourceType.syllabus,
        );
        expect(result.text, 'syllabus content');
      });

      test('returns direct text for SourceType.lectureNotes', () async {
        final extractor = DocumentExtractor(modelId: 'test-model', localeName: 'en');
        final result = await extractor.extractText(
          rawContent: 'notes content',
          sourceType: SourceType.lectureNotes,
        );
        expect(result.text, 'notes content');
      });

      test('returns direct text for SourceType.externalResource', () async {
        final extractor = DocumentExtractor(modelId: 'test-model', localeName: 'en');
        final result = await extractor.extractText(
          rawContent: 'resource content',
          sourceType: SourceType.externalResource,
        );
        expect(result.text, 'resource content');
      });

      test('strips HTML for SourceType.webPage', () async {
        final extractor = DocumentExtractor(modelId: 'test-model', localeName: 'en');
        final result = await extractor.extractText(
          rawContent: '<html><body><p>Hello world content here</p></body></html>',
          sourceType: SourceType.webPage,
        );
        expect(result.text, contains('Hello world content here'));
        expect(result.extractionMethod, 'html_stripped');
      });

      test('passes through non-HTML for SourceType.webPage', () async {
        final extractor = DocumentExtractor(modelId: 'test-model', localeName: 'en');
        final result = await extractor.extractText(
          rawContent: 'plain text content',
          sourceType: SourceType.webPage,
        );
        expect(result.text, 'plain text content');
        expect(result.extractionMethod, 'web_direct');
      });

      test('returns image file path for SourceType.image with file://', () async {
        final extractor = DocumentExtractor(modelId: 'test-model', localeName: 'en');
        final result = await extractor.extractText(
          rawContent: 'file:///path/to/image.png',
          sourceType: SourceType.image,
        );
        expect(result.text, 'file:///path/to/image.png');
        expect(result.extractionMethod, 'image_file');
        expect(result.mimeType, 'image/png');
      });

      test('returns image URL for SourceType.image with http URL', () async {
        final extractor = DocumentExtractor(modelId: 'test-model', localeName: 'en');
        final result = await extractor.extractText(
          rawContent: 'https://example.com/photo.jpg',
          sourceType: SourceType.image,
        );
        expect(result.text, 'https://example.com/photo.jpg');
        expect(result.extractionMethod, 'image_url');
      });

      test('returns video raw content for SourceType.video', () async {
        final extractor = DocumentExtractor(modelId: 'test-model', localeName: 'en');
        final result = await extractor.extractText(
          rawContent: 'transcript content',
          sourceType: SourceType.video,
        );
        expect(result.text, 'transcript content');
        expect(result.extractionMethod, 'video_raw');
      });

      test('detects YouTube URL for SourceType.video', () async {
        final extractor = DocumentExtractor(modelId: 'test-model', localeName: 'en');
        final result = await extractor.extractText(
          rawContent: 'https://youtube.com/watch?v=abc123',
          sourceType: SourceType.video,
        );
        expect(result.text, 'https://youtube.com/watch?v=abc123');
        expect(result.extractionMethod, 'youtube_url');
      });

      test('returns audio raw content for SourceType.audio', () async {
        final extractor = DocumentExtractor(modelId: 'test-model', localeName: 'en');
        final result = await extractor.extractText(
          rawContent: 'audio transcript',
          sourceType: SourceType.audio,
        );
        expect(result.text, 'audio transcript');
        expect(result.extractionMethod, 'audio_raw');
      });

      test('detects URL for SourceType.audio', () async {
        final extractor = DocumentExtractor(modelId: 'test-model', localeName: 'en');
        final result = await extractor.extractText(
          rawContent: 'https://example.com/audio.mp3',
          sourceType: SourceType.audio,
        );
        expect(result.text, 'https://example.com/audio.mp3');
        expect(result.extractionMethod, 'audio_url');
      });

      test('populates extraction metadata via toMetaJson', () async {
        final extractor = DocumentExtractor(modelId: 'test-model', localeName: 'en');
        final result = await extractor.extractText(
          rawContent: 'some content',
          sourceType: SourceType.pdf,
        );
        final meta = result.toMetaJson();
        expect(meta['extractionMethod'], isNotEmpty);
      });

      test('handles empty content gracefully', () async {
        final extractor = DocumentExtractor(modelId: 'test-model', localeName: 'en');
        final result = await extractor.extractText(
          rawContent: '',
          sourceType: SourceType.pdf,
        );
        expect(result.text, '');
        expect(result.extractionMethod, 'pdf_empty');
      });

      test('returns error when OCR extraction fails', () async {
        final extractor = DocumentExtractor(
          modelId: 'test-model',
          ocrExtractor: _FakeOcrExtractor(),
          localeName: 'en',
        );
        final result = await extractor.extractText(
          rawContent: 'test content',
          sourceType: SourceType.image,
        );
        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Simulated OCR failure'));
      });
    });

    group('estimateChunkCount', () {
      test('returns 0 for empty string', () {
        final extractor = DocumentExtractor(modelId: 'test-model', localeName: 'en');
        expect(extractor.estimateChunkCount(''), 0);
      });

      test('returns 1 for text shorter than chunkSize', () {
        final extractor = DocumentExtractor(modelId: 'test-model', localeName: 'en');
        expect(extractor.estimateChunkCount('hello'), 1);
      });

      test('returns 1 for text exactly fitting chunkSize', () {
        final extractor = DocumentExtractor(modelId: 'test-model', localeName: 'en');
        final text = 'a' * 2000;
        expect(extractor.estimateChunkCount(text), 1);
      });

      test('returns 2 for text at chunkSize boundary + 1', () {
        final extractor = DocumentExtractor(modelId: 'test-model', localeName: 'en');
        final text = 'a' * 2001;
        expect(extractor.estimateChunkCount(text), 2);
      });

      test('handles single character', () {
        final extractor = DocumentExtractor(modelId: 'test-model', localeName: 'en');
        expect(extractor.estimateChunkCount('x'), 1);
      });

      test('handles custom chunkSize', () {
        final extractor = DocumentExtractor(modelId: 'test-model', localeName: 'en');
        final text = 'a' * 500;
        expect(extractor.estimateChunkCount(text, chunkSize: 100), 5);
      });
    });

    group('stripHtmlToText', () {
      test('strips HTML tags from content', () {
        final result = DocumentExtractor.stripHtmlToText(
          '<html><body><p>This is a paragraph with enough text to pass the minimum length filter.</p></body></html>',
        );
        expect(result, 'This is a paragraph with enough text to pass the minimum length filter.');
      });

      test('removes script and style tags', () {
        final result = DocumentExtractor.stripHtmlToText(
          '<html><head><style>.css{color:red}</style></head><body><script>alert("x")</script><p>This is a paragraph with enough text to pass the minimum length filter.</p></body></html>',
        );
        expect(result, 'This is a paragraph with enough text to pass the minimum length filter.');
      });

      test('returns empty for HTML with no text', () {
        final result = DocumentExtractor.stripHtmlToText(
          '<html><head></head><body></body></html>',
        );
        expect(result, isEmpty);
      });
    });

    group('ODT extraction', () {
      test('extracts text from ODT archive via file path', () async {
        final odtBytes = _createOdtArchive('''
          <office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
                                  xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0">
            <office:body>
              <office:text>
                <text:p>Hello ODT world</text:p>
                <text:p>Second paragraph</text:p>
              </office:text>
            </office:body>
          </office:document-content>
        ''');

        final tmpDir = Directory.systemTemp.createTempSync('odt_test');
        final odtFile = File('${tmpDir.path}/test.odt');
        await odtFile.writeAsBytes(odtBytes);

        final extractor = DocumentExtractor(modelId: 'test', localeName: 'en');
        final result = await extractor.extractText(
          rawContent: 'file://${odtFile.path}',
          sourceType: SourceType.document,
        );

        expect(result.text, contains('Hello ODT world'));
        expect(result.text, contains('Second paragraph'));
        expect(result.extractionMethod, 'odt_parsed');

        await odtFile.delete();
        tmpDir.deleteSync();
      });
    });

    group('RTF extraction', () {
      test('extracts text from RTF content', () async {
        final rtfContent = r'{\rtf1\ansi Hello \b RTF\b0 world\par Second line}';

        final tmpDir = Directory.systemTemp.createTempSync('rtf_test');
        final rtfFile = File('${tmpDir.path}/test.rtf');
        await rtfFile.writeAsString(rtfContent);

        final extractor = DocumentExtractor(modelId: 'test', localeName: 'en');
        final result = await extractor.extractText(
          rawContent: 'file://${rtfFile.path}',
          sourceType: SourceType.document,
        );

        expect(result.text, contains('Hello'));
        expect(result.text, contains('RTF'));
        expect(result.text, contains('world'));
        expect(result.extractionMethod, 'rtf_parsed');

        await rtfFile.delete();
        tmpDir.deleteSync();
      });
    });

    group('DOCX table extraction', () {
      test('extracts tables as markdown', () async {
        final docxBytes = _createDocxWithTable();

        final tmpDir = Directory.systemTemp.createTempSync('docx_table_test');
        final docxFile = File('${tmpDir.path}/test.docx');
        await docxFile.writeAsBytes(docxBytes);

        final extractor = DocumentExtractor(modelId: 'test', localeName: 'en');
        final result = await extractor.extractText(
          rawContent: 'file://${docxFile.path}',
          sourceType: SourceType.document,
        );

        expect(result.text, contains('| Name | Age |'));
        expect(result.text, contains('|---'));
        expect(result.text, contains('| Alice | 25 |'));

        await docxFile.delete();
        tmpDir.deleteSync();
      });
    });

    group('DOCX footnote extraction', () {
      test('extracts footnotes with markers', () async {
        final docxBytes = _createDocxWithFootnotes();

        final tmpDir = Directory.systemTemp.createTempSync('docx_footnote_test');
        final docxFile = File('${tmpDir.path}/test.docx');
        await docxFile.writeAsBytes(docxBytes);

        final extractor = DocumentExtractor(modelId: 'test', localeName: 'en');
        final result = await extractor.extractText(
          rawContent: 'file://${docxFile.path}',
          sourceType: SourceType.document,
        );

        expect(result.text, contains('Some text'));
        expect(result.text, contains('[1]'));
        expect(result.text, contains('**Footnotes:**'));
        expect(result.text, contains('[1] This is a footnote.'));

        await docxFile.delete();
        tmpDir.deleteSync();
      });
    });

    group('DOCX image extraction', () {
      test('extracts embedded image references', () async {
        final docxBytes = _createDocxWithImage();

        final tmpDir = Directory.systemTemp.createTempSync('docx_image_test');
        final docxFile = File('${tmpDir.path}/test.docx');
        await docxFile.writeAsBytes(docxBytes);

        final extractor = DocumentExtractor(modelId: 'test', localeName: 'en');
        final result = await extractor.extractText(
          rawContent: 'file://${docxFile.path}',
          sourceType: SourceType.document,
        );

        expect(result.text, contains('Image below:'));
        expect(result.text, contains('[img:word/media/image1.png]'));
        expect(result.text, contains('**Embedded Images:**'));

        await docxFile.delete();
        tmpDir.deleteSync();
      });
    });

    group('PPTX image extraction', () {
      test('extracts embedded image references from slides', () async {
        final pptxBytes = _createPptxWithImage();

        final tmpDir = Directory.systemTemp.createTempSync('pptx_image_test');
        final pptxFile = File('${tmpDir.path}/test.pptx');
        await pptxFile.writeAsBytes(pptxBytes);

        final extractor = DocumentExtractor(modelId: 'test', localeName: 'en');
        final result = await extractor.extractText(
          rawContent: 'file://${pptxFile.path}',
          sourceType: SourceType.document,
        );

        expect(result.text, contains('Slide with image'));
        expect(result.text, contains('[img:ppt/media/image1.png]'));
        expect(result.text, contains('**Embedded Images:**'));

        await pptxFile.delete();
        tmpDir.deleteSync();
      });
    });
  });
}
