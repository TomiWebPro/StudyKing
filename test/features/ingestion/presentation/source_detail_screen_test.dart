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
import '../../../helpers/navigator_observer_helper.dart';

class _FakeSourceRepo extends SourceRepository {
  final Map<String, Source> _sources;
  bool _shouldThrow = false;

  _FakeSourceRepo(this._sources);

  void setThrowOnGet(bool shouldThrow) => _shouldThrow = shouldThrow;

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
  Future<Result<void>> save(String key, Source item) async {
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
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Topic>>> getAll() async => Result.success([]);

  @override
  Future<Result<List<Topic>>> getBySubject(String subjectId) async => Result.success([]);
}

class _FakeQuestionRepo extends QuestionRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Question>>> getAll() async => Result.success([]);

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
      expect(find.text('src1'), findsOneWidget);
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

      expect(find.textContaining('Exception'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
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
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Delete').first);
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Delete').last);
      await tester.pump(const Duration(seconds: 1));

      expect(navigatorObserver.poppedRoutes, isNotEmpty);
    });
  });
}
