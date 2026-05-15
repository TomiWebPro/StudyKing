import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/pdf_ingestion_service.dart';
import 'package:studyking/features/ingestion/presentation/upload_screen.dart';
import 'package:studyking/features/ingestion/services/content_pipeline.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeContentPipeline extends ContentPipeline {
  _FakeContentPipeline() : super(
    ingestionService: PdfIngestionService(apiKey: 'test-key'),
    sourceRepository: _FakeSourceRepo(),
    topicRepository: _FakeTopicRepo(),
  );

  bool processUploadCalled = false;
  String? lastTitle;
  String? lastContent;

  @override
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
    processUploadCalled = true;
    lastTitle = title;
    lastContent = content;
    return Result.success(Source(
      id: 'src_test',
      title: title,
      type: type,
      content: content,
      studentId: studentId,
    ));
  }
}

class _FakeSourceRepo extends SourceRepository {
  @override
  Future<void> init() async {}
  @override
  Future<void> create(Source source) async {}
}

class _FakeTopicRepo extends TopicRepository {
  @override
  Future<void> init() async {}
}

class _FailingPipeline extends _FakeContentPipeline {
  @override
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
    return Result.failure('Upload failed: server error');
  }
}

Widget _buildWidget({ContentPipeline? pipeline}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: UploadScreen(pipeline: pipeline),
  );
}

void main() {
  group('UploadScreen', () {
    Future<void> enterTextAndSubmit(WidgetTester tester, {String title = '', String content = ''}) async {
      if (title.isNotEmpty) {
        await tester.enterText(find.byType(TextField).first, title);
        await tester.pump();
      }
      if (content.isNotEmpty) {
        final contentFields = find.byType(TextField);
        await tester.enterText(contentFields.last, content);
        await tester.pump();
      }
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
    }

    testWidgets('renders title field and upload button', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      expect(find.text('Upload Content'), findsAtLeastNWidgets(1));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows error when title is empty on submit', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      await enterTextAndSubmit(tester);

      expect(find.text('Please fill in all required fields.'), findsOneWidget);
    });

    testWidgets('shows error when content is empty on submit', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      await enterTextAndSubmit(tester, title: 'Test Title');

      expect(find.text('Please fill in all required fields.'), findsOneWidget);
    });

    testWidgets('calls pipeline.processUpload with correct data', (tester) async {
      final pipeline = _FakeContentPipeline();

      await tester.pumpWidget(_buildWidget(pipeline: pipeline));
      await tester.pump();

      await enterTextAndSubmit(tester, title: 'My Notes', content: 'My study content here');

      await tester.pump();
      expect(pipeline.processUploadCalled, isTrue);
      expect(pipeline.lastTitle, 'My Notes');
      expect(pipeline.lastContent, 'My study content here');
    });

    testWidgets('shows success message after successful upload', (tester) async {
      final pipeline = _FakeContentPipeline();

      await tester.pumpWidget(_buildWidget(pipeline: pipeline));
      await tester.pump();

      await enterTextAndSubmit(tester, title: 'Title', content: 'Content');
      await tester.pump();

      expect(find.text('Content uploaded successfully!'), findsOneWidget);
    });

    testWidgets('switching to URL mode shows URL text field', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      await tester.ensureVisible(find.text('URL / Link'));
      await tester.pump();
      await tester.tap(find.text('URL / Link'));
      await tester.pump();

      expect(find.text('URL *'), findsOneWidget);
      expect(find.text('https://example.com/notes'), findsOneWidget);
    });

    testWidgets('shows error display container when error occurs', (tester) async {
      await tester.pumpWidget(_buildWidget(pipeline: _FailingPipeline()));
      await tester.pump();

      await enterTextAndSubmit(tester, title: 'Title', content: 'Content');

      expect(find.textContaining('Upload failed'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
