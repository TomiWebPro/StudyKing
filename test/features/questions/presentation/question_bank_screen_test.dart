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
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/questions/presentation/question_bank_screen.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../helpers/navigator_observer_helper.dart';

class _FakeQuestionRepo extends QuestionRepository {
  final List<Question> _questions;
  bool _shouldThrow = false;

  _FakeQuestionRepo(this._questions);

  void setShouldThrow(bool v) => _shouldThrow = v;

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Question>>> getAll() async {
    if (_shouldThrow) throw Exception('Question repo failed');
    return Result.success(_questions);
  }

  @override
  Future<Result<Question?>> get(String key) async =>
      Result.success(_questions.where((q) => q.id == key).firstOrNull);

  @override
  Future<Result<void>> save(String key, Question item) async => Result.success(null);

  @override
  Future<Result<void>> delete(String key) async {
    _questions.removeWhere((q) => q.id == key);
    return Result.success(null);
  }
}

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

class _FakeTopicRepo extends TopicRepository {
  final List<Topic> _topics;

  _FakeTopicRepo(this._topics);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Topic>>> getAll() async => Result.success(_topics);

  @override
  Future<Result<List<Topic>>> getBySubject(String subjectId) async =>
      Result.success(_topics.where((t) => t.subjectId == subjectId).toList());
}

class _FakeSourceRepo extends SourceRepository {
  final List<Source> _sources;

  _FakeSourceRepo(this._sources);

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Source>>> getAll() async => Result.success(_sources);
}

Widget _buildWidget({
  QuestionRepository? questionRepo,
  SubjectRepository? subjectRepo,
  TopicRepository? topicRepo,
  SourceRepository? sourceRepo,
  TestNavigatorObserver? navigatorObserver,
}) {
  return ProviderScope(
    overrides: [
      if (questionRepo != null)
        questionRepositoryProvider.overrideWithValue(questionRepo),
      if (subjectRepo != null)
        subjectRepositoryProvider.overrideWithValue(subjectRepo),
      if (topicRepo != null)
        topicRepositoryProvider.overrideWithValue(topicRepo),
      if (sourceRepo != null)
        sourceRepositoryProvider.overrideWithValue(sourceRepo),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      home: QuestionBankScreen(),
    ),
  );
}

final mockQuestions = [
  Question(
    id: 'q1',
    text: 'What is Newton\'s first law?',
    type: QuestionType.singleChoice,
    difficulty: 2,
    subjectId: 'sub1',
    topicId: 't1',
    difficultyText: 'easy',
    createdAt: DateTime(2024, 1, 15),
    updatedAt: DateTime(2024, 1, 15),
  ),
  Question(
    id: 'q2',
    text: 'What is the chemical formula for water?',
    type: QuestionType.typedAnswer,
    difficulty: 1,
    subjectId: 'sub2',
    topicId: 't2',
    difficultyText: 'easy',
    createdAt: DateTime(2024, 2, 20),
    updatedAt: DateTime(2024, 2, 20),
  ),
];

final subjects = [
  Subject(id: 'sub1', name: 'Physics', color: 'blue', topicIds: []),
  Subject(id: 'sub2', name: 'Chemistry', color: 'green', topicIds: []),
];

final topics = [
  Topic(id: 't1', subjectId: 'sub1', title: 'Mechanics', description: '', sortOrder: 1, syllabusText: ''),
  Topic(id: 't2', subjectId: 'sub2', title: 'Water Chemistry', description: '', sortOrder: 1, syllabusText: ''),
];

void main() {
  group('QuestionBankScreen', () {
    testWidgets('renders question list with mock data', (tester) async {
      await tester.pumpWidget(_buildWidget(
        questionRepo: _FakeQuestionRepo(mockQuestions),
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Question Bank'), findsOneWidget);
      expect(find.text('What is Newton\'s first law?'), findsOneWidget);
      expect(find.text('What is the chemical formula for water?'), findsOneWidget);
    });

    testWidgets('renders empty state when no questions', (tester) async {
      await tester.pumpWidget(_buildWidget(
        questionRepo: _FakeQuestionRepo([]),
        subjectRepo: _FakeSubjectRepo([]),
        topicRepo: _FakeTopicRepo([]),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No Questions Available'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('filters questions by search query', (tester) async {
      await tester.pumpWidget(_buildWidget(
        questionRepo: _FakeQuestionRepo(mockQuestions),
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Newton');
      await tester.pumpAndSettle();

      expect(find.text('What is Newton\'s first law?'), findsOneWidget);
      expect(find.text('What is the chemical formula for water?'), findsNothing);
    });

    testWidgets('shows subject filter chip and can open subject filter bottom sheet', (tester) async {
      await tester.pumpWidget(_buildWidget(
        questionRepo: _FakeQuestionRepo(mockQuestions),
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('All subjects'), findsWidgets);

      await tester.tap(find.text('All subjects').last);
      await tester.pumpAndSettle();

      expect(find.text('Physics'), findsWidgets);
      expect(find.text('Chemistry'), findsWidgets);
    });

    testWidgets('error state renders retry button', (tester) async {
      final questionRepo = _FakeQuestionRepo(mockQuestions);
      questionRepo.setShouldThrow(true);

      await tester.pumpWidget(_buildWidget(
        questionRepo: questionRepo,
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('create dialog shows answer options for single choice type', (tester) async {
      final repo = _FakeQuestionRepo(mockQuestions);
      await tester.pumpWidget(_buildWidget(
        questionRepo: repo,
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Create Question'), findsOneWidget);
      expect(find.text('Answer Options'), findsOneWidget);
      expect(find.text('Add Option'), findsWidgets);
    });
  });
}
