import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/ingestion/presentation/content_library_screen.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/questions/providers/question_providers.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/providers/subject_repository_provider.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../helpers/locale_switch_harness.dart';
import '../../../helpers/navigator_observer_helper.dart';

class _FakeSubjectRepo extends SubjectRepository {
  final List<Subject> _subjects;

  _FakeSubjectRepo(this._subjects);

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Subject>>> getAll() async => Result.success(_subjects);

  @override
  Future<Result<Subject?>> get(String key) async =>
      Result.success(_subjects.where((s) => s.id == key).firstOrNull);
}

class _FakeSourceRepo extends SourceRepository {
  final List<Source> _sources;
  bool _shouldThrow = false;

  _FakeSourceRepo(this._sources);

  void setThrowOnGetAll(bool shouldThrow) => _shouldThrow = shouldThrow;

  bool _createShouldFail = false;

  set createShouldFail(bool v) => _createShouldFail = v;

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Source>>> getAll() async {
    if (_shouldThrow) throw Exception('Source repo failed');
    return Result.success(List.from(_sources));
  }

  @override
  Future<Result<void>> delete(String key) async {
    _sources.removeWhere((s) => s.id == key);
    return Result.success(null);
  }

  @override
  Future<Result<void>> create(Source source) async {
    if (_createShouldFail) return Result.failure('Hive write failed');
    _sources.add(source);
    return Result.success(null);
  }

  @override
  Future<Result<void>> save(String key, Source item) async => Result.success(null);

  @override
  Future<Result<Source?>> get(String key) async =>
      Result.success(_sources.where((s) => s.id == key).firstOrNull);
}

class _FakeQuestionRepo extends QuestionRepository {
  bool deleteShouldFail = false;

  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> delete(String key) async {
    if (deleteShouldFail) return Result.failure('Hive write failed');
    return Result.success(null);
  }
}

Widget _buildWidget({
  SourceRepository? sourceRepo,
  QuestionRepository? questionRepo,
  SubjectRepository? subjectRepo,
  TestNavigatorObserver? navigatorObserver,
}) {
  final effectiveQuestionRepo = questionRepo ?? _FakeQuestionRepo();
  return ProviderScope(
    overrides: [
      if (sourceRepo != null) sourceRepositoryProvider.overrideWithValue(sourceRepo),
      questionRepositoryProvider.overrideWithValue(effectiveQuestionRepo),
      if (subjectRepo != null) subjectRepositoryProvider.overrideWithValue(subjectRepo),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      home: const ContentLibraryScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.sourceDetail) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('Source Detail')),
          );
        }
        if (settings.name == AppRoutes.upload) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('Upload')),
          );
        }
        return null;
      },
    ),
  );
}

void main() {
  final mockSources = [
    Source(
      id: 'src1',
      title: 'Physics Textbook',
      type: SourceType.pdf,
      subjectId: 'sub1',
      studentId: 'stu1',
      processingStatus: 'completed',
      createdAt: DateTime(2024, 1, 15),
    ),
    Source(
      id: 'src2',
      title: 'Chemistry Notes',
      type: SourceType.document,
      subjectId: 'sub2',
      studentId: 'stu1',
      processingStatus: 'pending',
      createdAt: DateTime(2024, 2, 20),
    ),
  ];

  final subjects = [
    Subject(id: 'sub1', name: 'Physics', color: 'blue', topicIds: []),
    Subject(id: 'sub2', name: 'Chemistry', color: 'green', topicIds: []),
  ];

  group('ContentLibraryScreen', () {
    testWidgets('renders content library list with mock source data', (tester) async {
      final sourceRepo = _FakeSourceRepo(mockSources);
      final subjectRepo = _FakeSubjectRepo(subjects);

      await tester.pumpWidget(_buildWidget(
        sourceRepo: sourceRepo,
        subjectRepo: subjectRepo,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Content Library'), findsOneWidget);
      expect(find.text('Physics Textbook'), findsOneWidget);
      expect(find.text('Chemistry Notes'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);
      expect(find.text('Chemistry'), findsOneWidget);
    });

    testWidgets('renders empty state when no sources exist', (tester) async {
      final sourceRepo = _FakeSourceRepo([]);
      final subjectRepo = _FakeSubjectRepo([]);

      await tester.pumpWidget(_buildWidget(
        sourceRepo: sourceRepo,
        subjectRepo: subjectRepo,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('No sources available'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
      expect(find.text('Upload Materials'), findsOneWidget);
    });

    testWidgets('renders error state when source repo throws', (tester) async {
      final sourceRepo = _FakeSourceRepo([]);
      sourceRepo.setThrowOnGetAll(true);
      final subjectRepo = _FakeSubjectRepo(subjects);

      await tester.pumpWidget(_buildWidget(
        sourceRepo: sourceRepo,
        subjectRepo: subjectRepo,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('uses NavigatorObserver to verify navigation on source tap', (tester) async {
      final navigatorObserver = TestNavigatorObserver();
      final sourceRepo = _FakeSourceRepo(mockSources);
      final subjectRepo = _FakeSubjectRepo(subjects);

      await tester.pumpWidget(_buildWidget(
        sourceRepo: sourceRepo,
        subjectRepo: subjectRepo,
        navigatorObserver: navigatorObserver,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Physics Textbook'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(navigatorObserver.pushedRoutes, isNotEmpty);
      final hasDetail = navigatorObserver.pushedRoutes.any((r) => r.settings.name == AppRoutes.sourceDetail);
      expect(hasDetail, isTrue);
    });

    testWidgets('delete source then undo restores it to the list', (tester) async {
      await tester.pumpWidget(_buildWidget(
        sourceRepo: _FakeSourceRepo(List.of(mockSources)),
        subjectRepo: _FakeSubjectRepo(subjects),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Physics Textbook'), findsOneWidget);

      // Swipe the first source tile (src1) to trigger delete.
      await tester.drag(find.byKey(const ValueKey('src1')), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Confirm the Dismissible's delete dialog.
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      // Confirm the screen's delete dialog.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Physics Textbook'), findsNothing);
      expect(find.text('Source deleted'), findsOneWidget);

      // Undo recreates the source and adds it back to the list.
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.text('Physics Textbook'), findsOneWidget);
    });

    testWidgets('undo does not restore source when recreate write fails', (tester) async {
      final sourceRepo = _FakeSourceRepo(List.of(mockSources));
      await tester.pumpWidget(_buildWidget(
        sourceRepo: sourceRepo,
        subjectRepo: _FakeSubjectRepo(subjects),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.drag(find.byKey(const ValueKey('src1')), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Physics Textbook'), findsNothing);

      // Simulate a failed Hive write for the recreate.
      sourceRepo.createShouldFail = true;
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      // Failed recreate: the source stays deleted and an error is shown.
      expect(find.text('Physics Textbook'), findsNothing);
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('delete source with also-delete-questions warns when question delete fails', (tester) async {
      final sourceWithQuestions = Source(
        id: 'src1',
        title: 'Physics Textbook',
        type: SourceType.pdf,
        subjectId: 'sub1',
        studentId: 'stu1',
        processingStatus: 'completed',
        createdAt: DateTime(2024, 1, 15),
        generatedQuestionIds: ['q1', 'q2'],
      );
      final questionRepo = _FakeQuestionRepo();
      await tester.pumpWidget(_buildWidget(
        sourceRepo: _FakeSourceRepo([sourceWithQuestions]),
        subjectRepo: _FakeSubjectRepo(subjects),
        questionRepo: questionRepo,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Physics Textbook'), findsOneWidget);

      // Swipe the source tile (src1) to trigger delete.
      await tester.drag(find.byKey(const ValueKey('src1')), const Offset(-500, 0));
      await tester.pumpAndSettle();
      // Confirm the Dismissible's delete dialog.
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      // Enable "also delete questions" in the screen's delete dialog.
      await tester.tap(
        find.widgetWithText(CheckboxListTile, 'Also delete questions generated from this source'),
      );
      await tester.pumpAndSettle();

      // Simulate a failing questions box.
      questionRepo.deleteShouldFail = true;
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      // The question-delete failures are surfaced, not silent.
      expect(find.text('Something went wrong'), findsOneWidget);
      // The source delete still proceeds.
      expect(find.text('Physics Textbook'), findsNothing);
      // After the warning's display time, the queued source-deleted message appears.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Source deleted'), findsOneWidget);
    });
  });

  group('ContentLibraryScreen - locale switch', () {
    testWidgets('error message follows locale switch', (tester) async {
      final sourceRepo = _FakeSourceRepo([]);
      sourceRepo.setThrowOnGetAll(true);
      final harnessKey = GlobalKey<LocaleSwitchHarnessState>();
      await tester.pumpWidget(LocaleSwitchHarness(
        key: harnessKey,
        child: ProviderScope(
          overrides: [
            sourceRepositoryProvider.overrideWithValue(sourceRepo),
            questionRepositoryProvider.overrideWithValue(_FakeQuestionRepo()),
            subjectRepositoryProvider.overrideWithValue(_FakeSubjectRepo(subjects)),
          ],
          child: const ContentLibraryScreen(),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      harnessKey.currentState!.switchLocale(const Locale('es'));
      await tester.pumpAndSettle();

      expect(find.text('Algo salió mal'), findsOneWidget);
      expect(find.text('Something went wrong'), findsNothing);
    });
  });
}
