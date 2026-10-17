import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import '../../../helpers/navigator_observer_helper.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_agent/idle_executor.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/ingestion/presentation/upload_screen.dart';
import 'package:studyking/features/ingestion/services/bulk_ingestion_service.dart';
import 'package:studyking/features/ingestion/services/content_pipeline.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/data/extraction/asr_engine.dart';
import 'package:studyking/core/data/extraction/ocr_engine.dart';
import 'package:studyking/features/ingestion/providers/ingestion_providers.dart' show whisperAsrEngineProvider, bulkIngestionServiceProvider;
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/providers/ocr_provider.dart' show ocrModeProvider;
import '../../../helpers/locale_switch_harness.dart';

class _FakeLlmService extends LlmService {
  _FakeLlmService()
      : super(
          config:
              LlmConfiguration(provider: LlmProvider.openRouter, apiKey: 'test'),
        );

  @override
  Future<Result<String>> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async {
    return Result.success('');
  }
}

class _FakeSourceRepo extends SourceRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> create(Source source) async => Result.success(null);

  @override
  Future<Result<void>> save(String key, Source item) async {
    return Result.success(null);
  }
}

class _FakeTopicRepo extends TopicRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);
}

class _FakeQuestionRepo extends QuestionRepository {
  @override
  Future<void> init() async {}
}

class _FakeContentPipeline extends ContentPipeline {
  _FakeContentPipeline()
      : super(
          llmService: _FakeLlmService(),
          sourceRepository: _FakeSourceRepo(),
          topicRepository: _FakeTopicRepo(),
          questionRepository: _FakeQuestionRepo(),
          transcriptionModelId: 'test-model',
          localeName: 'en',
        );

  bool processUploadCalled = false;
  String? lastTitle;
  String? lastContent;
  String? lastSourceUrl;
  bool fetchAndScrapeUrlCalled = false;
  String? lastFetchUrl;
  bool fetchAndScrapeReturnsSuccess = true;
  String? fetchAndScrapeContent;
  bool processUploadShouldThrow = false;

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
    if (processUploadShouldThrow) {
      throw Exception('Network error');
    }
    processUploadCalled = true;
    lastTitle = title;
    lastContent = content;
    lastSourceUrl = sourceUrl;
    return Result.success(Source(
      id: 'src_test',
      title: title,
      type: type,
      content: content,
      studentId: studentId,
    ));
  }

  @override
  Future<Result<Source>> processFullPipeline({
    required String title,
    required String content,
    required SourceType type,
    required String studentId,
    required String classificationModelId,
    required String summarizationModelId,
    required String generationModelId,
    String subjectId = '',
    String topicId = '',
    String syllabusId = '',
    String sourceUrl = '',
    String language = '',
    List<String> possibleTopics = const [],
    bool generateQuestions = false,
    bool generateLessons = false,
    bool generateSlideDecks = false,
    bool generateFlashcards = false,
    QuestionValidator? validator,
    List<String> allowedQuestionTypes = const ['singleChoice', 'multiChoice', 'typedAnswer', 'mathExpression', 'essay'],
    ProcessingProgressCallback? onProgress,
    String? existingSourceId,
    List<String> oldQuestionIds = const [],
  }) async {
    if (processUploadShouldThrow) {
      throw Exception('Network error');
    }
    processUploadCalled = true;
    lastTitle = title;
    lastContent = content;
    lastSourceUrl = sourceUrl;
    return Result.success(Source(
      id: existingSourceId ?? 'src_test',
      title: title,
      type: type,
      content: content,
      studentId: studentId,
    ));
  }

  @override
  Future<Result<String>> fetchAndScrapeUrl(String url) async {
    fetchAndScrapeUrlCalled = true;
    lastFetchUrl = url;
    if (fetchAndScrapeReturnsSuccess) {
      return Result.success(
          fetchAndScrapeContent ?? 'Fetched content for $url');
    } else {
      return Result.failure('Server error');
    }
  }
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

  @override
  Future<Result<Source>> processFullPipeline({
    required String title,
    required String content,
    required SourceType type,
    required String studentId,
    required String classificationModelId,
    required String summarizationModelId,
    required String generationModelId,
    String subjectId = '',
    String topicId = '',
    String syllabusId = '',
    String sourceUrl = '',
    String language = '',
    List<String> possibleTopics = const [],
    bool generateQuestions = false,
    bool generateLessons = false,
    bool generateSlideDecks = false,
    bool generateFlashcards = false,
    QuestionValidator? validator,
    List<String> allowedQuestionTypes = const ['singleChoice', 'multiChoice', 'typedAnswer', 'mathExpression', 'essay'],
    ProcessingProgressCallback? onProgress,
    String? existingSourceId,
    List<String> oldQuestionIds = const [],
  }) async {
    return Result.failure('Upload failed: server error');
  }
}

class _DelayedPipeline extends _FakeContentPipeline {
  final Completer<void> completer = Completer<void>();

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
    await completer.future;
    return Result.success(Source(
      id: 'src_test',
      title: title,
      type: type,
      content: content,
      studentId: studentId,
    ));
  }

  @override
  Future<Result<Source>> processFullPipeline({
    required String title,
    required String content,
    required SourceType type,
    required String studentId,
    required String classificationModelId,
    required String summarizationModelId,
    required String generationModelId,
    String subjectId = '',
    String topicId = '',
    String syllabusId = '',
    String sourceUrl = '',
    String language = '',
    List<String> possibleTopics = const [],
    bool generateQuestions = false,
    bool generateLessons = false,
    bool generateSlideDecks = false,
    bool generateFlashcards = false,
    QuestionValidator? validator,
    List<String> allowedQuestionTypes = const ['singleChoice', 'multiChoice', 'typedAnswer', 'mathExpression', 'essay'],
    ProcessingProgressCallback? onProgress,
    String? existingSourceId,
    List<String> oldQuestionIds = const [],
  }) async {
    processUploadCalled = true;
    await completer.future;
    return Result.success(Source(
      id: existingSourceId ?? 'src_test',
      title: title,
      type: type,
      content: content,
      studentId: studentId,
    ));
  }
}

class _ThrowingFetchPipeline extends _FakeContentPipeline {
  @override
  Future<Result<String>> fetchAndScrapeUrl(String url) async {
    throw Exception('Network error');
  }
}

/// Fake [IdleExecutor] that executes tasks synchronously so widget tests
/// can observe the full effect of [BulkIngestionService.enqueueBulk] without
/// real delays.
class _SyncIdleExecutor extends IdleExecutor {
  @override
  Future<void> enqueue(
    String description,
    Future<void> Function() task, {
    bool requiresHeavy = false,
  }) async {
    await task();
  }
}

/// A [FilePickerPlatform] fake that returns a configurable number of files.
class _FakeMultiFilePicker extends FilePickerPlatform {
  final int fileCount;

  _FakeMultiFilePicker(this.fileCount);

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
  }) async {
    return FilePickerResult(
      List.generate(fileCount, (i) => PlatformFile(
            path: '/test/file_$i.pdf',
            name: 'file_$i.pdf',
            size: 1024,
          )),
    );
  }
}

/// Builds a widget with a [BulkIngestionService] wired in. The service uses
/// a fake pipeline and a synchronous idle executor so all processing happens
/// immediately during `pumpAndSettle`.
Widget _buildWidgetWithBulkService({
  required BulkIngestionService bulkService,
  ContentPipeline? pipeline,
  TestNavigatorObserver? navigatorObserver,
}) {
  return ProviderScope(
    overrides: [
      whisperAsrEngineProvider.overrideWithValue(NoopAsrEngine()),
      ocrModeProvider.overrideWith((ref) => OcrMode.hybrid),
      bulkIngestionServiceProvider.overrideWith((ref) => bulkService),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      home: UploadScreen(
        pipeline: pipeline,
        bulkIngestionService: bulkService,
        fixedModelId: 'test-model',
        fixedStudentId: 'test-student',
      ),
    ),
  );
}

Widget _buildWidget({ContentPipeline? pipeline, TestNavigatorObserver? navigatorObserver}) {
  return ProviderScope(
    overrides: [
      whisperAsrEngineProvider.overrideWithValue(NoopAsrEngine()),
      ocrModeProvider.overrideWith((ref) => OcrMode.hybrid),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      home: UploadScreen(pipeline: pipeline, fixedModelId: 'test-model', fixedStudentId: 'test-student'),
    ),
  );
}

void main() {
  group('UploadScreen', () {
    Future<void> enterTextAndSubmit(WidgetTester tester,
        {String title = '', String content = ''}) async {
      if (title.isNotEmpty) {
        await tester.enterText(find.byType(TextField).first, title);
        await tester.pump();
      }
      if (content.isNotEmpty) {
        final contentFields = find.byType(TextField);
        await tester.enterText(contentFields.last, content);
        await tester.pump();
      }
      final uploadButton = find.widgetWithText(FilledButton, 'Upload & Analyze');
      await tester.ensureVisible(uploadButton);
      await tester.pump();
      await tester.tap(uploadButton);
      await tester.pump();
    }

    Future<void> enterTextInLastField(
        WidgetTester tester, String text) async {
      final fields = find.byType(TextField);
      await tester.enterText(fields.last, text);
      await tester.pump();
    }

    group('rendering', () {
      testWidgets('renders title field and upload button', (tester) async {
        await tester.pumpWidget(_buildWidget());
        await tester.pump();

        expect(find.text('Upload Content'), findsAtLeastNWidgets(1));
        expect(find.text('Title *'), findsOneWidget);
        expect(find.text('e.g. Chapter 5 Notes'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Upload & Analyze'), findsOneWidget);
      });

      testWidgets('renders all input mode chips', (tester) async {
        await tester.pumpWidget(_buildWidget());
        await tester.pump();

        expect(find.text('Paste Text'), findsOneWidget);
        expect(find.text('URL / Link'), findsOneWidget);
        expect(find.text('File'), findsOneWidget);
        expect(find.text('Camera'), findsOneWidget);
      });

      testWidgets('renders subject dropdown with label', (tester) async {
        await tester.pumpWidget(_buildWidget());
        await tester.pump();

        expect(find.text('Subject (optional)'), findsOneWidget);
        expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      });

      testWidgets('renders text content field by default', (tester) async {
        await tester.pumpWidget(_buildWidget());
        await tester.pump();

        expect(find.text('Content *'), findsOneWidget);
        expect(find.text('Paste your study material here...'), findsOneWidget);
      });
    });

    group('validation', () {
      testWidgets('shows error when title is empty on submit',
          (tester) async {
        await tester.pumpWidget(_buildWidget());
        await tester.pump();

        await enterTextAndSubmit(tester);

        expect(
            find.text('Please fill in all required fields.'), findsOneWidget);
      });

      testWidgets('shows error when content is empty on submit',
          (tester) async {
        await tester.pumpWidget(_buildWidget());
        await tester.pump();

        await enterTextAndSubmit(tester, title: 'Test Title');

        expect(
            find.text('Please fill in all required fields.'), findsOneWidget);
      });
    });

    group('input mode switching', () {
      testWidgets('switching to URL mode shows URL text field',
          (tester) async {
        await tester.pumpWidget(_buildWidget());
        await tester.pump();

        await tester.ensureVisible(find.text('URL / Link'));
        await tester.pump();
        await tester.tap(find.text('URL / Link'));
        await tester.pump();

        expect(find.text('URL *'), findsOneWidget);
        expect(find.text('https://example.com/notes'), findsOneWidget);
      });

      testWidgets('switching back to paste mode hides URL field',
          (tester) async {
        await tester.pumpWidget(_buildWidget());
        await tester.pump();

        await tester.tap(find.text('URL / Link'));
        await tester.pump();
        expect(find.text('URL *'), findsOneWidget);

        await tester.tap(find.text('Paste Text'));
        await tester.pump();

        expect(find.text('Content *'), findsOneWidget);
      });

      testWidgets('URL mode shows Fetch & Scrape button with pipeline',
          (tester) async {
        await tester.pumpWidget(
            _buildWidget(pipeline: _FakeContentPipeline()));
        await tester.pump();

        await tester.tap(find.text('URL / Link'));
        await tester.pump();

        expect(find.text('Fetch & Scrape'), findsOneWidget);
      });
    });

    group('pipeline upload', () {
      testWidgets('calls pipeline.processUpload with correct data',
          (tester) async {
        final pipeline = _FakeContentPipeline();

        await tester.pumpWidget(_buildWidget(pipeline: pipeline));
        await tester.pump();

        await enterTextAndSubmit(
            tester, title: 'My Notes', content: 'My study content here');

        await tester.pump();
        expect(pipeline.processUploadCalled, isTrue);
        expect(pipeline.lastTitle, 'My Notes');
        expect(pipeline.lastContent, 'My study content here');
      });

      testWidgets('shows success message after successful upload',
          (tester) async {
        final pipeline = _FakeContentPipeline();

        await tester.pumpWidget(_buildWidget(pipeline: pipeline));
        await tester.pump();

        await enterTextAndSubmit(tester, title: 'Title', content: 'Content');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Content uploaded successfully!'), findsOneWidget);
      });

      testWidgets('shows error display container when pipeline fails',
          (tester) async {
        await tester.pumpWidget(
            _buildWidget(pipeline: _FailingPipeline()));
        await tester.pump();

        await enterTextAndSubmit(tester, title: 'Title', content: 'Content');

        expect(find.textContaining('Upload failed'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('shows uploading state with spinner', (tester) async {
        final pipeline = _DelayedPipeline();

        await tester.pumpWidget(_buildWidget(pipeline: pipeline));
        await tester.pump();

        await tester.enterText(find.byType(TextField).first, 'Test Title');
        await tester.pump();

        final contentFields = find.byType(TextField);
        await tester.enterText(contentFields.last, 'Test Content');
        await tester.pump();

        final uploadButton = find.widgetWithText(FilledButton, 'Upload & Analyze');
        await tester.ensureVisible(uploadButton);
        await tester.pump();
        await tester.tap(uploadButton);
        await tester.pump();

        expect(find.text('Uploading...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        pipeline.completer.complete();
        await tester.pump();

        expect(find.text('Content uploaded successfully!'), findsOneWidget);
      });
    });

    group('URL fetch', () {
      testWidgets('calls fetchAndScrapeUrl when Fetch & Scrape is tapped',
          (tester) async {
        final pipeline = _FakeContentPipeline();

        await tester.pumpWidget(_buildWidget(pipeline: pipeline));
        await tester.pump();

        await tester.tap(find.text('URL / Link'));
        await tester.pump();

        await enterTextInLastField(
            tester, 'https://example.com/notes');

        await tester.tap(find.text('Fetch & Scrape'));
        await tester.pump();

        expect(pipeline.fetchAndScrapeUrlCalled, isTrue);
        expect(pipeline.lastFetchUrl, 'https://example.com/notes');
      });

      testWidgets('shows success snackbar after successful URL fetch',
          (tester) async {
        final pipeline = _FakeContentPipeline();

        await tester.pumpWidget(_buildWidget(pipeline: pipeline));
        await tester.pump();

        await tester.tap(find.text('URL / Link'));
        await tester.pump();

        await enterTextInLastField(
            tester, 'https://example.com/notes');

        await tester.tap(find.text('Fetch & Scrape'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(
            find.text('URL content fetched successfully'), findsOneWidget);
      });

      testWidgets('shows error snackbar when URL fetch returns failure',
          (tester) async {
        final pipeline = _FakeContentPipeline();
        pipeline.fetchAndScrapeReturnsSuccess = false;

        await tester.pumpWidget(_buildWidget(pipeline: pipeline));
        await tester.pump();

        await tester.tap(find.text('URL / Link'));
        await tester.pump();

        await enterTextInLastField(
            tester, 'https://example.com/bad');

        await tester.tap(find.text('Fetch & Scrape'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Failed to fetch URL: Server error'),
            findsOneWidget);
      });

      testWidgets('shows error snackbar when URL fetch throws',
          (tester) async {
        final logs = <String>[];
        final original = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) logs.add(message);
        };
        try {
          final pipeline = _ThrowingFetchPipeline();

          await tester.pumpWidget(_buildWidget(pipeline: pipeline));
          await tester.pump();

          await tester.tap(find.text('URL / Link'));
          await tester.pump();

          await enterTextInLastField(
              tester, 'https://example.com/error');

          await tester.tap(find.text('Fetch & Scrape'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.text('URL fetch error: '), findsOneWidget);
          expect(
            logs.where((l) =>
                l.contains('[W]') && l.contains('URL content fetch failed')),
            isNotEmpty,
          );
        } finally {
          debugPrint = original;
        }
      });
    });

    group('subject loading', () {
      testWidgets('renders subject dropdown correctly', (tester) async {
        await tester.pumpWidget(_buildWidget());
        await tester.pump();

        expect(find.text('Subject (optional)'), findsOneWidget);
        expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      });
    });

    group('URL mode upload', () {
      testWidgets('uploads URL content through pipeline',
          (tester) async {
        final pipeline = _FakeContentPipeline();

        await tester.pumpWidget(_buildWidget(pipeline: pipeline));
        await tester.pump();

        // Switch to URL mode
        await tester.tap(find.text('URL / Link'));
        await tester.pump();

        // Enter title and URL
        await tester.enterText(find.byType(TextField).first, 'Web Notes');
        await tester.pump();

        await enterTextInLastField(tester, 'https://example.com/article');
        await tester.pump();

        // Submit via Upload & Analyze
        final uploadButton = find.widgetWithText(FilledButton, 'Upload & Analyze');
        await tester.ensureVisible(uploadButton);
        await tester.pump();
        await tester.tap(uploadButton);
        await tester.pump();

        expect(pipeline.processUploadCalled, isTrue);
        expect(pipeline.lastTitle, 'Web Notes');
        expect(pipeline.lastContent, 'https://example.com/article');
      });
    });

    group('submit failure handling', () {
      testWidgets('shows error when pipeline throws exception',
          (tester) async {
        final pipeline = _FakeContentPipeline();
        pipeline.processUploadShouldThrow = true;

        await tester.pumpWidget(_buildWidget(pipeline: pipeline));
        await tester.pump();

        await enterTextAndSubmit(tester, title: 'Title', content: 'Content');
        await tester.pump();

        expect(find.textContaining('Upload failed'), findsOneWidget);
      });
    });

    group('input mode button errors', () {
      testWidgets('tapping File button does not crash', (tester) async {
        await tester.pumpWidget(_buildWidget());
        await tester.pump();

        await tester.ensureVisible(find.text('File'));
        await tester.pump();

        await tester.tap(find.text('File'));
        await tester.pump();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        expect(find.text('Upload Content'), findsAtLeastNWidgets(1));
      });

      testWidgets('tapping Camera button does not crash', (tester) async {
        await tester.pumpWidget(_buildWidget());
        await tester.pump();

        await tester.ensureVisible(find.text('Camera'));
        await tester.pump();

        await tester.tap(find.text('Camera'));
        await tester.pump();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        expect(find.text('Upload Content'), findsAtLeastNWidgets(1));
      });
    });

    group('discard mid-upload', () {
      testWidgets('discarding mid-upload does not setState after dispose',
          (tester) async {
        final pipeline = _DelayedPipeline();

        await tester.pumpWidget(_buildWidget(pipeline: pipeline));
        await tester.pump();

        await tester.enterText(find.byType(TextField).first, 'Title');
        await tester.pump();
        await tester.enterText(find.byType(TextField).last, 'Content');
        await tester.pump();

        final uploadButton =
            find.widgetWithText(FilledButton, 'Upload & Analyze');
        await tester.ensureVisible(uploadButton);
        await tester.pump();
        await tester.tap(uploadButton);
        await tester.pump();

        expect(find.text('Uploading...'), findsOneWidget);

        // Simulate a back-button press while the upload is in flight.
        // maybePop consults PopScope (canPop: false while uploading),
        // which raises the discard dialog.
        final navigator =
            Navigator.of(tester.element(find.byType(UploadScreen)));
        await navigator.maybePop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Upload in Progress'), findsOneWidget);

        // Confirm discard: the in-flight upload keeps running while the
        // route pops.
        await tester.tap(find.widgetWithText(FilledButton, 'Discard'));
        await tester.pump();
        await tester.pumpAndSettle();

        // The route is popped and the State is disposed, but the upload
        // future is still pending.
        expect(find.byType(UploadScreen), findsNothing);

        // The in-flight upload completes after the pop. Without the
        // mounted guards this throws "setState() called after dispose()".
        pipeline.completer.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
      });
    });

    group('navigation', () {
      testWidgets('PopScope allows back navigation when idle', (tester) async {
        await tester.pumpWidget(_buildWidget());
        await tester.pump();

        // With PopScope(canPop=true), the back navigation is allowed
        // when not uploading (canPop: !_isUploading).
        expect(find.byType(UploadScreen), findsOneWidget);
      });
    });

    group('bulk ingestion', () {
      testWidgets('multi-pick enqueues N jobs and shows snackbar',
          (tester) async {
        final bulkService = BulkIngestionService(
          pipeline: _FakeContentPipeline(),
          idleExecutor: _SyncIdleExecutor(),
        );
        final previousPlatform = FilePickerPlatform.instance;
        FilePickerPlatform.instance = _FakeMultiFilePicker(5);

        try {
          await tester.pumpWidget(_buildWidgetWithBulkService(
            bulkService: bulkService,
          ));
          await tester.pump();

          // Tap the File button to open the picker (mocked to return 5 files).
          await tester.ensureVisible(find.text('File'));
          await tester.pump();
          await tester.tap(find.text('File'));
          await tester.pump();

          // The file picker returns 5 files and they are stored in _selectedFiles.
          // Now submit — files route to enqueueBulk via the bulk service.
          await tester.enterText(find.byType(TextField).first, 'Bulk Notes');
          await tester.pump();

          final uploadButton =
              find.widgetWithText(FilledButton, 'Upload & Analyze');
          await tester.ensureVisible(uploadButton);
          await tester.pump();
          await tester.tap(uploadButton);
          await tester.pump();
          await tester.pumpAndSettle();

          // All 5 jobs should be processed and enqueued.
          expect(bulkService.totalCount, 5);
          expect(bulkService.completedCount, 5);

          // Snackbar should mention the count.
          expect(
            find.textContaining('5 file'),
            findsOneWidget,
          );
        } finally {
          FilePickerPlatform.instance = previousPlatform;
        }
      });

      testWidgets('bulk upload clears the form after enqueueing',
          (tester) async {
        final bulkService = BulkIngestionService(
          pipeline: _FakeContentPipeline(),
          idleExecutor: _SyncIdleExecutor(),
        );
        final previousPlatform = FilePickerPlatform.instance;
        FilePickerPlatform.instance = _FakeMultiFilePicker(3);

        try {
          await tester.pumpWidget(_buildWidgetWithBulkService(
            bulkService: bulkService,
          ));
          await tester.pump();

          await tester.enterText(find.byType(TextField).first, 'Bulk Notes');
          await tester.pump();

          await tester.tap(find.text('File'));
          await tester.pump();

          final uploadButton =
              find.widgetWithText(FilledButton, 'Upload & Analyze');
          await tester.ensureVisible(uploadButton);
          await tester.pump();
          await tester.tap(uploadButton);
          await tester.pump();
          await tester.pumpAndSettle();

          // Form should be cleared — title field empty.
          expect(find.text('Bulk Notes'), findsNothing);
          expect(bulkService.totalCount, 3);
        } finally {
          FilePickerPlatform.instance = previousPlatform;
        }
      });

      testWidgets('PopScope allows navigation when only background jobs run',
          (tester) async {
        final bulkService = BulkIngestionService(
          pipeline: _FakeContentPipeline(),
          idleExecutor: _SyncIdleExecutor(),
        );
        final previousPlatform = FilePickerPlatform.instance;
        FilePickerPlatform.instance = _FakeMultiFilePicker(2);

        try {
          await tester.pumpWidget(_buildWidgetWithBulkService(
            bulkService: bulkService,
          ));
          await tester.pump();

          // Bulk upload returns immediately (background queue), so _isUploading
          // is false and canPop is true.
          expect(find.byType(UploadScreen), findsOneWidget);
        } finally {
          FilePickerPlatform.instance = previousPlatform;
        }
      });

      testWidgets('renders background jobs section when service has jobs',
          (tester) async {
        final bulkService = BulkIngestionService(
          pipeline: _FakeContentPipeline(),
          idleExecutor: _SyncIdleExecutor(),
        );

        // Pre-populate the service with a completed job.
        await bulkService.enqueueBulk(
          files: [
            BulkUploadFile(
              filePath: '/test/preexisting.pdf',
              fileName: 'preexisting.pdf',
              title: 'Pre-existing',
              sourceType: SourceType.pdf,
            ),
          ],
          studentId: 'test-student',
          classificationModelId: 'test-model',
          summarizationModelId: 'test-model',
          generationModelId: 'test-model',
        );

        await tester.pumpWidget(_buildWidgetWithBulkService(
          bulkService: bulkService,
        ));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Background Queue'), findsOneWidget);
        expect(find.text('preexisting.pdf'), findsOneWidget);
      });
    });
  });

  group('UploadScreen - locale switch', () {
    testWidgets('validation error message follows locale switch',
        (tester) async {
      final harnessKey = GlobalKey<LocaleSwitchHarnessState>();
      await tester.pumpWidget(LocaleSwitchHarness(
        key: harnessKey,
        child: ProviderScope(
          overrides: [
            whisperAsrEngineProvider.overrideWithValue(NoopAsrEngine()),
            ocrModeProvider.overrideWith((ref) => OcrMode.hybrid),
          ],
          child: const UploadScreen(
            fixedModelId: 'test-model',
            fixedStudentId: 'test-student',
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final uploadButton = find.widgetWithText(FilledButton, 'Upload & Analyze');
      await tester.ensureVisible(uploadButton);
      await tester.pump();
      await tester.tap(uploadButton);
      await tester.pumpAndSettle();

      expect(find.text('Please fill in all required fields.'), findsOneWidget);

      harnessKey.currentState!.switchLocale(const Locale('es'));
      await tester.pumpAndSettle();

      expect(
        find.text('Por favor complete todos los campos requeridos.'),
        findsOneWidget,
      );
      expect(find.text('Please fill in all required fields.'), findsNothing);
    });
  });
}
