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
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider, sourceRepositoryProvider;
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
    return Result.success(List.from(_questions));
  }

  @override
  Future<Result<Question?>> get(String key) async =>
      Result.success(_questions.where((q) => q.id == key).firstOrNull);

  @override
  Future<Result<void>> save(String key, Question item) async {
    final index = _questions.indexWhere((q) => q.id == key);
    if (index != -1) {
      _questions[index] = item;
    } else {
      _questions.add(item);
    }
    return Result.success(null);
  }

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
  Future<Result<List<Subject>>> getAll() async => Result.success(List.from(_subjects));

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
  Future<Result<List<Topic>>> getAll() async => Result.success(List.from(_topics));

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
  Future<Result<List<Source>>> getAll() async => Result.success(List.from(_sources));
}

Widget _buildWidget({
  QuestionRepository? questionRepo,
  SubjectRepository? subjectRepo,
  TopicRepository? topicRepo,
  SourceRepository? sourceRepo,
  TestNavigatorObserver? navigatorObserver,
  String? initialQuestionId,
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
      home: QuestionBankScreen(initialQuestionId: initialQuestionId),
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
    sourceIds: ['src1'],
    difficultyText: 'medium',
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
  Question(
    id: 'q3',
    text: 'Solve for x: 2x + 3 = 7',
    type: QuestionType.mathExpression,
    difficulty: 3,
    subjectId: 'sub1',
    topicId: 't1',
    sourceIds: ['src2', 'src3'],
    difficultyText: 'hard',
    createdAt: DateTime(2024, 3, 10),
    updatedAt: DateTime(2024, 3, 10),
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

final sources = [
  Source(id: 'src1', title: 'Physics Textbook', type: SourceType.textbook, subjectId: 'sub1', studentId: 'stu1', createdAt: DateTime(2024, 1, 1)),
  Source(id: 'src2', title: 'Khan Academy', type: SourceType.video, subjectId: 'sub1', studentId: 'stu1', createdAt: DateTime(2024, 1, 1)),
  Source(id: 'src3', title: 'Practice Worksheets', type: SourceType.pdf, subjectId: 'sub1', studentId: 'stu1', createdAt: DateTime(2024, 1, 1)),
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
      expect(find.text('Solve for x: 2x + 3 = 7'), findsOneWidget);
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
      expect(find.text('Solve for x: 2x + 3 = 7'), findsNothing);
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

    testWidgets('displays question count', (tester) async {
      await tester.pumpWidget(_buildWidget(
        questionRepo: _FakeQuestionRepo(mockQuestions),
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Questions: 3'), findsOneWidget);
    });

    testWidgets('question cards display subject and topic names', (tester) async {
      await tester.pumpWidget(_buildWidget(
        questionRepo: _FakeQuestionRepo(mockQuestions),
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Physics'), findsWidgets);
      expect(find.text('Chemistry'), findsWidgets);
      expect(find.text('Mechanics'), findsWidgets);
      expect(find.text('Water Chemistry'), findsWidgets);
    });

    testWidgets('question cards display source count', (tester) async {
      await tester.pumpWidget(_buildWidget(
        questionRepo: _FakeQuestionRepo(mockQuestions),
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo(sources),
      ));
      await tester.pumpAndSettle();

      expect(find.text('1 source'), findsWidgets);
      expect(find.text('2 sources'), findsWidgets);
    });

    testWidgets('question cards show type chips', (tester) async {
      await tester.pumpWidget(_buildWidget(
        questionRepo: _FakeQuestionRepo(mockQuestions),
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Multiple Choice'), findsOneWidget);
      expect(find.text('Text Answer'), findsOneWidget);
      expect(find.text('Math'), findsOneWidget);
    });

    testWidgets('question cards show difficulty chips', (tester) async {
      await tester.pumpWidget(_buildWidget(
        questionRepo: _FakeQuestionRepo(mockQuestions),
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Difficulty: 1'), findsOneWidget);
      expect(find.text('Difficulty: 2'), findsOneWidget);
      expect(find.text('Difficulty: 3'), findsOneWidget);
    });

    testWidgets('popup menu is present on each question card', (tester) async {
      await tester.pumpWidget(_buildWidget(
        questionRepo: _FakeQuestionRepo(mockQuestions),
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      final popupMenus = find.byType(PopupMenuButton<String>);
      expect(popupMenus, findsNWidgets(3));
    });

    testWidgets('all three filter chips are displayed', (tester) async {
      await tester.pumpWidget(_buildWidget(
        questionRepo: _FakeQuestionRepo(mockQuestions),
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo(sources),
      ));
      await tester.pumpAndSettle();

      expect(find.text('All subjects'), findsWidgets);
      expect(find.text('All types'), findsOneWidget);
      expect(find.text('All sources'), findsOneWidget);
    });

    testWidgets('FloatingActionButton is present', (tester) async {
      await tester.pumpWidget(_buildWidget(
        questionRepo: _FakeQuestionRepo(mockQuestions),
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('selection mode toggle and cancel', (tester) async {
      await tester.pumpWidget(_buildWidget(
        questionRepo: _FakeQuestionRepo(mockQuestions),
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Select multiple'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Cancel selection'), findsOneWidget);
      expect(find.byTooltip('Delete selected'), findsOneWidget);

      await tester.tap(find.byTooltip('Cancel selection'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Select multiple'), findsOneWidget);
    });

    testWidgets('selecting question in selection mode shows checkbox', (tester) async {
      await tester.pumpWidget(_buildWidget(
        questionRepo: _FakeQuestionRepo(mockQuestions),
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Select multiple'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('What is Newton\'s first law?'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_box), findsOneWidget);
    });

    testWidgets('edit question dialog changes text', (tester) async {
      final repo = _FakeQuestionRepo(List.from(mockQuestions));
      await tester.pumpWidget(_buildWidget(
        questionRepo: repo,
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('What is Newton\'s first law?'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Question'), findsOneWidget);

      final textField = find.widgetWithText(TextField, 'What is Newton\'s first law?');
      await tester.enterText(textField, 'What is Newton\'s third law?');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('What is Newton\'s third law?'), findsOneWidget);
      expect(find.text('What is Newton\'s first law?'), findsNothing);
    });

    testWidgets('popup menu shows edit and delete options', (tester) async {
      await tester.pumpWidget(_buildWidget(
        questionRepo: _FakeQuestionRepo(mockQuestions),
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('subject filter filters questions to show only selected subject', (tester) async {
      await tester.pumpWidget(_buildWidget(
        questionRepo: _FakeQuestionRepo(mockQuestions),
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('All subjects').last);
      await tester.pumpAndSettle();

      final physicsTile = find.widgetWithText(ListTile, 'Physics');
      await tester.tap(physicsTile);
      await tester.pumpAndSettle();

      expect(find.text('What is Newton\'s first law?'), findsOneWidget);
      expect(find.text('Solve for x: 2x + 3 = 7'), findsOneWidget);
      expect(find.text('What is the chemical formula for water?'), findsNothing);
    });

    testWidgets('type filter chip is present and tappable', (tester) async {
      await tester.pumpWidget(_buildWidget(
        questionRepo: _FakeQuestionRepo(mockQuestions),
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('All types'), findsOneWidget);
    });

    testWidgets('source filter filters questions', (tester) async {
      await tester.pumpWidget(_buildWidget(
        questionRepo: _FakeQuestionRepo(mockQuestions),
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo(sources),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('All sources'));
      await tester.pumpAndSettle();

      final physicsTile = find.widgetWithText(ListTile, 'Physics Textbook');
      await tester.tap(physicsTile);
      await tester.pumpAndSettle();

      expect(find.text('What is Newton\'s first law?'), findsOneWidget);
      expect(find.text('What is the chemical formula for water?'), findsNothing);
      expect(find.text('Solve for x: 2x + 3 = 7'), findsNothing);
    });

    testWidgets('RefreshIndicator is present', (tester) async {
      await tester.pumpWidget(_buildWidget(
        questionRepo: _FakeQuestionRepo(mockQuestions),
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('question cards show Manual chip', (tester) async {
      await tester.pumpWidget(_buildWidget(
        questionRepo: _FakeQuestionRepo(mockQuestions),
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Manual'), findsWidgets);
    });

    testWidgets('search text field filters and restores on clear', (tester) async {
      await tester.pumpWidget(_buildWidget(
        questionRepo: _FakeQuestionRepo(mockQuestions),
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Newton');
      await tester.pumpAndSettle();

      expect(find.text('What is Newton\'s first law?'), findsOneWidget);
      expect(find.text('What is the chemical formula for water?'), findsNothing);
      expect(find.text('Solve for x: 2x + 3 = 7'), findsNothing);

      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      expect(find.text('What is Newton\'s first law?'), findsOneWidget);
      expect(find.text('What is the chemical formula for water?'), findsOneWidget);
      expect(find.text('Solve for x: 2x + 3 = 7'), findsOneWidget);
    });

    testWidgets('filter by subject and search together', (tester) async {
      await tester.pumpWidget(_buildWidget(
        questionRepo: _FakeQuestionRepo(mockQuestions),
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Solve');
      await tester.pumpAndSettle();

      await tester.tap(find.text('All subjects').last);
      await tester.pumpAndSettle();

      final physicsTile = find.widgetWithText(ListTile, 'Physics');
      await tester.tap(physicsTile);
      await tester.pumpAndSettle();

      expect(find.text('Solve for x: 2x + 3 = 7'), findsOneWidget);
      expect(find.text('Questions: 1'), findsOneWidget);
    });

    testWidgets('error state retry recovers after error', (tester) async {
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

      questionRepo.setShouldThrow(false);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('What is Newton\'s first law?'), findsOneWidget);
      expect(find.text('What is the chemical formula for water?'), findsOneWidget);
      expect(find.text('Solve for x: 2x + 3 = 7'), findsOneWidget);
    });

    testWidgets('delete question through popup menu with confirmation', (tester) async {
      final repo = _FakeQuestionRepo(List.from(mockQuestions));
      await tester.pumpWidget(_buildWidget(
        questionRepo: repo,
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('What is Newton\'s first law?'), findsOneWidget);

      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(find.text('Delete Question'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this question?'), findsOneWidget);

      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();

      expect(find.text('What is Newton\'s first law?'), findsNothing);
      expect(find.text('Questions: 2'), findsOneWidget);
    });

    testWidgets('multi-select delete removes selected questions', (tester) async {
      final repo = _FakeQuestionRepo(List.from(mockQuestions));
      await tester.pumpWidget(_buildWidget(
        questionRepo: repo,
        subjectRepo: _FakeSubjectRepo(subjects),
        topicRepo: _FakeTopicRepo(topics),
        sourceRepo: _FakeSourceRepo([]),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Select multiple'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('What is Newton\'s first law?'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Solve for x: 2x + 3 = 7'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete selected'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Questions'), findsOneWidget);

      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();

      expect(find.text('What is Newton\'s first law?'), findsNothing);
      expect(find.text('Solve for x: 2x + 3 = 7'), findsNothing);
      expect(find.text('What is the chemical formula for water?'), findsOneWidget);
      expect(find.text('Questions: 1'), findsOneWidget);
    });
  });
}
