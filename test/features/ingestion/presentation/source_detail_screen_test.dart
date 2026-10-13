import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/ingestion/presentation/source_detail_screen.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../helpers/locale_switch_harness.dart';
import '../../../helpers/navigator_observer_helper.dart';

class _FakeSourceRepo extends SourceRepository {
  final Map<String, Source> _sources;
  bool _shouldThrow = false;
  bool _failOnSave = false;
  bool _createShouldFail = false;

  _FakeSourceRepo(this._sources);

  void setThrowOnGet(bool shouldThrow) => _shouldThrow = shouldThrow;
  void setFailOnSave(bool fail) => _failOnSave = fail;
  set createShouldFail(bool v) => _createShouldFail = v;

  @override
  Future<void> init() async {}

  @override
  Future<Result<Source?>> get(String key) async {
    if (_shouldThrow) throw Exception('Source fetch failed');
    return Result.success(_sources[key]);
  }

  @override
  Future<Result<List<Source>>> getAll() async => Result.success(_sources.values.toList());

  @override
  Future<Result<void>> create(Source source) async {
    if (_createShouldFail) return Result.failure('Hive write failed');
    _sources[source.id] = source;
    return Result.success(null);
  }

  @override
  Future<Result<void>> save(String key, Source item) async {
    if (_failOnSave) return Result.failure('Save failed');
    _sources[key] = item;
    return Result.success(null);
  }

  @override
  Future<Result<void>> delete(String key) async {
    _sources.remove(key);
    return Result.success(null);
  }
}

class _FakeSubjectRepo extends SubjectRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Subject>>> getAll() async => Result.success([]);

  @override
  Future<Result<Subject?>> get(String key) async => Result.success(null);
}

class _FakeTopicRepo extends TopicRepository {
  final List<Topic> _topics;

  _FakeTopicRepo([this._topics = const []]);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Topic>>> getAll() async => Result.success(_topics);

  @override
  Future<Result<List<Topic>>> getBySubject(String subjectId) async => Result.success(_topics);
}

class _FakeQuestionRepo extends QuestionRepository {
  final List<Question> _questions;

  _FakeQuestionRepo([this._questions = const []]);

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Question>>> getAll() async => Result.success(List.from(_questions));

  @override
  Future<Result<void>> delete(String key) async => Result.success(null);
}

Widget _buildWidget({
  required String sourceId,
  SourceRepository? sourceRepo,
  SubjectRepository? subjectRepo,
  TopicRepository? topicRepo,
  QuestionRepository? questionRepo,
  TestNavigatorObserver? navigatorObserver,
}) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      home: SourceDetailScreen(
        sourceId: sourceId,
        sourceRepo: sourceRepo,
        subjectRepo: subjectRepo,
        topicRepo: topicRepo,
        questionRepo: questionRepo,
      ),
    ),
  );
}

/// Pumps the app with SourceDetailScreen pushed over a home Scaffold, like
/// the real navigation stack. The home Scaffold stays mounted across the
/// delete-pop, so the delete SnackBar (and any queued error SnackBar shown
/// by the Undo action) keep a root Scaffold to present in.
Future<void> _pumpDetailOverHome(
  WidgetTester tester, {
  required _FakeSourceRepo sourceRepo,
}) async {
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => SourceDetailScreen(
                    sourceId: 'src1',
                    sourceRepo: sourceRepo,
                    subjectRepo: _FakeSubjectRepo(),
                    topicRepo: _FakeTopicRepo(),
                    questionRepo: _FakeQuestionRepo(),
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 1));
}

/// Runs the overflow-menu delete flow: open menu, tap Delete, confirm dialog.
/// Ends with pumpAndSettle so the popped route's exit animation completes and
/// the delete SnackBar (re-hosted by the still-mounted root Scaffold) is
/// on-screen and hittable.
Future<void> _deleteSourceViaMenu(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text('Delete').last);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.widgetWithText(FilledButton, 'Delete').last);
  await tester.pumpAndSettle();
}

void main() {
  final mockSource = Source(
    id: 'src1',
    title: 'Physics Textbook',
    type: SourceType.pdf,
    subjectId: 'sub1',
    studentId: 'stu1',
    processingStatus: 'completed',
    summary: 'This is a summary of physics concepts.',
    extractedText: 'Newton\'s laws of motion...',
    createdAt: DateTime(2024, 1, 15),
  );

  group('SourceDetailScreen', () {
    testWidgets('renders source detail with mock source data', (tester) async {
      final sourceRepo = _FakeSourceRepo({'src1': mockSource});

      await tester.pumpWidget(_buildWidget(
        sourceId: 'src1',
        sourceRepo: sourceRepo,
        subjectRepo: _FakeSubjectRepo(),
        topicRepo: _FakeTopicRepo(),
        questionRepo: _FakeQuestionRepo(),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Physics Textbook'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
      expect(find.textContaining('summary of physics'), findsOneWidget);
    });

    testWidgets('shows loading state initially', (tester) async {
      final sourceRepo = _FakeSourceRepo({'src1': mockSource});

      await tester.pumpWidget(_buildWidget(
        sourceId: 'src1',
        sourceRepo: sourceRepo,
        subjectRepo: _FakeSubjectRepo(),
        topicRepo: _FakeTopicRepo(),
        questionRepo: _FakeQuestionRepo(),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state when source not found', (tester) async {
      final sourceRepo = _FakeSourceRepo({});

      await tester.pumpWidget(_buildWidget(
        sourceId: 'nonexistent',
        sourceRepo: sourceRepo,
        subjectRepo: _FakeSubjectRepo(),
        topicRepo: _FakeTopicRepo(),
        questionRepo: _FakeQuestionRepo(),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Source not found'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows error state when source repo throws', (tester) async {
      final sourceRepo = _FakeSourceRepo({'src1': mockSource});
      sourceRepo.setThrowOnGet(true);

      await tester.pumpWidget(_buildWidget(
        sourceId: 'src1',
        sourceRepo: sourceRepo,
        subjectRepo: _FakeSubjectRepo(),
        topicRepo: _FakeTopicRepo(),
        questionRepo: _FakeQuestionRepo(),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('question subtitle shows localized difficulty word', (tester) async {
      final sourceWithQuestions = Source(
        id: 'src1',
        title: 'Physics Textbook',
        type: SourceType.pdf,
        subjectId: 'sub1',
        studentId: 'stu1',
        processingStatus: 'completed',
        generatedQuestionIds: ['sq1'],
        createdAt: DateTime(2024, 1, 15),
      );
      final generatedQuestion = Question(
        id: 'sq1',
        text: 'What is Newton\'s first law?',
        type: QuestionType.typedAnswer,
        difficulty: 2,
        subjectId: 'sub1',
        topicId: '',
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 15),
      );

      await tester.pumpWidget(_buildWidget(
        sourceId: 'src1',
        sourceRepo: _FakeSourceRepo({'src1': sourceWithQuestions}),
        subjectRepo: _FakeSubjectRepo(),
        topicRepo: _FakeTopicRepo(),
        questionRepo: _FakeQuestionRepo([generatedQuestion]),
      ));
      await tester.pump(const Duration(seconds: 1));

      // difficultyText is null, so the 1–3 int must map to the localized word.
      expect(find.text('Text Answer • Medium'), findsOneWidget);
      expect(find.textContaining('Difficulty: 2'), findsNothing);
    });

    testWidgets('uses NavigatorObserver for back-navigation on delete', (tester) async {
      final navigatorObserver = TestNavigatorObserver();
      final sourceRepo = _FakeSourceRepo({'src1': mockSource});

      await tester.pumpWidget(_buildWidget(
        sourceId: 'src1',
        sourceRepo: sourceRepo,
        subjectRepo: _FakeSubjectRepo(),
        topicRepo: _FakeTopicRepo(),
        questionRepo: _FakeQuestionRepo(),
        navigatorObserver: navigatorObserver,
      ));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Popup menu Delete (last Delete is the menu item, first is off-screen bottom button)
      await tester.tap(find.text('Delete').last);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Confirm dialog Delete button
      await tester.tap(find.widgetWithText(FilledButton, 'Delete').last);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(navigatorObserver.poppedRoutes, isNotEmpty);
    });

    testWidgets('updates topic chip when topic change save succeeds', (tester) async {
      final mechanics = Topic(
        id: 't1',
        subjectId: 'sub1',
        title: 'Mechanics',
        description: '',
        syllabusText: '',
      );
      final thermodynamics = Topic(
        id: 't2',
        subjectId: 'sub1',
        title: 'Thermodynamics',
        description: '',
        syllabusText: '',
      );
      final sourceWithTopic = Source(
        id: 'src1',
        title: 'Physics Textbook',
        type: SourceType.pdf,
        subjectId: 'sub1',
        studentId: 'stu1',
        processingStatus: 'completed',
        topicId: 't1',
        createdAt: DateTime(2024, 1, 15),
      );
      final sourceRepo = _FakeSourceRepo({'src1': sourceWithTopic});

      await tester.pumpWidget(_buildWidget(
        sourceId: 'src1',
        sourceRepo: sourceRepo,
        subjectRepo: _FakeSubjectRepo(),
        topicRepo: _FakeTopicRepo([mechanics, thermodynamics]),
        questionRepo: _FakeQuestionRepo(),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Mechanics'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thermodynamics'));
      await tester.pumpAndSettle();

      expect(find.text('Thermodynamics'), findsOneWidget);
      expect(find.text('Mechanics'), findsNothing);
    });

    testWidgets('topic change save failure shows error snackbar and keeps original topic', (tester) async {
      final mechanics = Topic(
        id: 't1',
        subjectId: 'sub1',
        title: 'Mechanics',
        description: '',
        syllabusText: '',
      );
      final thermodynamics = Topic(
        id: 't2',
        subjectId: 'sub1',
        title: 'Thermodynamics',
        description: '',
        syllabusText: '',
      );
      final sourceWithTopic = Source(
        id: 'src1',
        title: 'Physics Textbook',
        type: SourceType.pdf,
        subjectId: 'sub1',
        studentId: 'stu1',
        processingStatus: 'completed',
        topicId: 't1',
        createdAt: DateTime(2024, 1, 15),
      );
      final sourceRepo = _FakeSourceRepo({'src1': sourceWithTopic});
      sourceRepo.setFailOnSave(true);

      await tester.pumpWidget(_buildWidget(
        sourceId: 'src1',
        sourceRepo: sourceRepo,
        subjectRepo: _FakeSubjectRepo(),
        topicRepo: _FakeTopicRepo([mechanics, thermodynamics]),
        questionRepo: _FakeQuestionRepo(),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Mechanics'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thermodynamics'));
      await tester.pumpAndSettle();

      // Failure is surfaced, and the failed write is not applied to the UI.
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Thermodynamics'), findsNothing);
      expect(find.text('Mechanics'), findsOneWidget);
    });

    testWidgets('delete source then undo recreates it', (tester) async {
      final sourceRepo = _FakeSourceRepo({'src1': mockSource});
      await _pumpDetailOverHome(tester, sourceRepo: sourceRepo);

      expect(find.text('Physics Textbook'), findsOneWidget);

      await _deleteSourceViaMenu(tester);

      // The detail route popped, but the root home Scaffold keeps the
      // delete confirmation SnackBar (with its Undo action) visible.
      expect(find.text('Source deleted'), findsOneWidget);

      // Undo recreates the source in the repository.
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      final restored = await sourceRepo.get('src1');
      expect(restored.isSuccess, isTrue);
      expect(restored.data, isNotNull);
      expect(restored.data!.title, 'Physics Textbook');
    });

    testWidgets('undo shows error snackbar when recreate write fails',
        (tester) async {
      final sourceRepo = _FakeSourceRepo({'src1': mockSource});
      sourceRepo.createShouldFail = true;
      await _pumpDetailOverHome(tester, sourceRepo: sourceRepo);

      expect(find.text('Physics Textbook'), findsOneWidget);

      await _deleteSourceViaMenu(tester);

      expect(find.text('Source deleted'), findsOneWidget);

      // Undo: the recreate write fails, so the source stays deleted instead
      // of being silently reported as restored. Tapping the Undo action
      // closes the delete SnackBar, so the queued error SnackBar shows
      // immediately.
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      final restored = await sourceRepo.get('src1');
      expect(restored.data, isNull);
      expect(find.text('Something went wrong'), findsOneWidget);
    });
  });

  group('SourceDetailScreen - locale switch', () {
    testWidgets('source-not-found message follows locale switch',
        (tester) async {
      final harnessKey = GlobalKey<LocaleSwitchHarnessState>();
      await tester.pumpWidget(LocaleSwitchHarness(
        key: harnessKey,
        child: ProviderScope(
          child: SourceDetailScreen(
            sourceId: 'nonexistent',
            sourceRepo: _FakeSourceRepo({}),
            subjectRepo: _FakeSubjectRepo(),
            topicRepo: _FakeTopicRepo(),
            questionRepo: _FakeQuestionRepo(),
          ),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Source not found'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      harnessKey.currentState!.switchLocale(const Locale('es'));
      await tester.pumpAndSettle();

      expect(find.text('Fuente no encontrada'), findsOneWidget);
      expect(find.text('Source not found'), findsNothing);
    });

    testWidgets('unexpected-error message follows locale switch',
        (tester) async {
      final sourceRepo = _FakeSourceRepo({'src1': mockSource});
      sourceRepo.setThrowOnGet(true);
      final harnessKey = GlobalKey<LocaleSwitchHarnessState>();
      await tester.pumpWidget(LocaleSwitchHarness(
        key: harnessKey,
        child: ProviderScope(
          child: SourceDetailScreen(
            sourceId: 'src1',
            sourceRepo: sourceRepo,
            subjectRepo: _FakeSubjectRepo(),
            topicRepo: _FakeTopicRepo(),
            questionRepo: _FakeQuestionRepo(),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Something went wrong'), findsOneWidget);

      harnessKey.currentState!.switchLocale(const Locale('es'));
      await tester.pumpAndSettle();

      expect(find.text('Algo salió mal'), findsOneWidget);
      expect(find.text('Something went wrong'), findsNothing);
    });
  });
}
