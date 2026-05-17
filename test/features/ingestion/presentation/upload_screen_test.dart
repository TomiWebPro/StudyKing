import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import '../../../helpers/navigator_observer_helper.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/ingestion/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/ingestion/presentation/upload_screen.dart';
import 'package:studyking/features/ingestion/services/content_pipeline.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

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
  Future<void> create(Source source) async {}

  @override
  Future<Result<void>> save(String key, Source item) async {
    return Result.success(null);
  }
}

class _FakeTopicRepo extends TopicRepository {
  @override
  Future<void> init() async {}
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
          modelId: 'test-model',
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
    required String modelId,
    String subjectId = '',
    String topicId = '',
    String syllabusId = '',
    String sourceUrl = '',
    String language = '',
    List<String> possibleTopics = const [],
    bool generateQuestions = false,
    QuestionValidator? validator,
    List<String> allowedQuestionTypes = const ['singleChoice', 'multiChoice', 'typedAnswer', 'mathExpression', 'essay'],
    ProcessingProgressCallback? onProgress,
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
    required String modelId,
    String subjectId = '',
    String topicId = '',
    String syllabusId = '',
    String sourceUrl = '',
    String language = '',
    List<String> possibleTopics = const [],
    bool generateQuestions = false,
    QuestionValidator? validator,
    List<String> allowedQuestionTypes = const ['singleChoice', 'multiChoice', 'typedAnswer', 'mathExpression', 'essay'],
    ProcessingProgressCallback? onProgress,
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
    required String modelId,
    String subjectId = '',
    String topicId = '',
    String syllabusId = '',
    String sourceUrl = '',
    String language = '',
    List<String> possibleTopics = const [],
    bool generateQuestions = false,
    QuestionValidator? validator,
    List<String> allowedQuestionTypes = const ['singleChoice', 'multiChoice', 'typedAnswer', 'mathExpression', 'essay'],
    ProcessingProgressCallback? onProgress,
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
}

class _ThrowingFetchPipeline extends _FakeContentPipeline {
  @override
  Future<Result<String>> fetchAndScrapeUrl(String url) async {
    throw Exception('Network error');
  }
}

Widget _buildWidget({ContentPipeline? pipeline, TestNavigatorObserver? navigatorObserver}) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      home: UploadScreen(pipeline: pipeline),
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
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
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
        expect(find.byType(ElevatedButton), findsOneWidget);
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

        expect(find.text('Content uploaded successfully!'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
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

        await tester.ensureVisible(find.byType(ElevatedButton));
        await tester.pump();
        await tester.tap(find.byType(ElevatedButton));
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

        expect(find.text('URL fetch error: Exception: Network error'),
            findsOneWidget);
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

        // Submit
        await tester.ensureVisible(find.byType(ElevatedButton));
        await tester.pump();
        await tester.tap(find.byType(ElevatedButton));
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

    group('navigation', () {
      testWidgets('navigator observes no pops initially', (tester) async {
        final observer = TestNavigatorObserver();
        await tester.pumpWidget(_buildWidget(navigatorObserver: observer));
        await tester.pump();

        expect(observer.poppedRoutes, isEmpty);
      });

      testWidgets('navigator pops via system back', (tester) async {
        final observer = TestNavigatorObserver();
        await tester.pumpWidget(_buildWidget(navigatorObserver: observer));
        await tester.pump();

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(observer.poppedRoutes, hasLength(1));
      });
    });
  });
}
