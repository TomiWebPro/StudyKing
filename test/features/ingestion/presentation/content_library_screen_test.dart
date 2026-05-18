import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/ingestion/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/ingestion/presentation/content_library_screen.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
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

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Source>>> getAll() async {
    if (_shouldThrow) throw Exception('Source repo failed');
    return Result.success(_sources);
  }

  @override
  Future<Result<void>> delete(String key) async {
    _sources.removeWhere((s) => s.id == key);
    return Result.success(null);
  }

  @override
  Future<Result<void>> save(String key, Source item) async => Result.success(null);

  @override
  Future<Result<Source?>> get(String key) async =>
      Result.success(_sources.where((s) => s.id == key).firstOrNull);
}

Widget _buildWidget({
  SourceRepository? sourceRepo,
  QuestionRepository? questionRepo,
  SubjectRepository? subjectRepo,
  TestNavigatorObserver? navigatorObserver,
}) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      home: ContentLibraryScreen(
        sourceRepo: sourceRepo,
        questionRepo: questionRepo,
        subjectRepo: subjectRepo,
      ),
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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      expect(find.text('Exception: Source repo failed'), findsOneWidget);
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
      await tester.pumpAndSettle();

      await tester.tap(find.text('Physics Textbook'));
      await tester.pumpAndSettle();

      expect(navigatorObserver.pushedRoutes, isNotEmpty);
      final pushedRoute = navigatorObserver.pushedRoutes.first;
      expect(pushedRoute.settings.name, AppRoutes.sourceDetail);
    });
  });
}
