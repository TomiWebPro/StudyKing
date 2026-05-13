import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/data/models/subject_model.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/features/practice/presentation/practice_screen.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

const _kNoPracticeSessionsYet = 'No Practice Sessions Yet';
const _kAddSubjectsAndQuestions = 'Add subjects and questions to start practicing';
const _kAddSubject = 'Add Subject';
const _kPracticeModes = 'Practice Modes';
const _kQuickPractice = 'Quick Practice';
const _kSpacedRepetition = 'Spaced Repetition';
const _kTopicFocus = 'Topic Focus';
const _kWeakAreas = 'Weak Areas';
const _kPractice = 'Practice';
const _kNoSubjects = 'No Subjects';
const _kPracticeMode = 'Practice Mode';
const _kNoReviewsScheduled = 'No reviews scheduled.';
const _kNoTopicsAvailable = 'No topics available';
const _kNoWeakAreasFound = 'No weak areas found. Keep up the great work!';

class _MockSubjectBox {
  final Map<String, Subject> _storage = {};
  void addSubject(Subject s) => _storage[s.id] = s;
  Iterable<Subject> get values => _storage.values.toList();
  void clear() => _storage.clear();
}

class _FakeSubjectRepository extends SubjectRepository {
  final _MockSubjectBox _box;
  _FakeSubjectRepository(this._box) : super(subjectBox: null);

  @override
  Future<List<Subject>> getAll() async => _box.values.toList();
}

class _FakeQuestionRepository extends QuestionRepository {
  final List<Question> _questions;
  _FakeQuestionRepository(this._questions);

  @override
  Future<Result<List<Question>>> getAll() async {
    return Result.success(_questions);
  }

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async {
    return Result.success(_questions);
  }
}

class _FakeSpacedRepetitionRepository extends SpacedRepetitionRepository {
  final Map<String, int> _dueCounts;

  _FakeSpacedRepetitionRepository([this._dueCounts = const {}]);

  @override
  Future<Result<int>> getSubjectDueCount(String subjectId) async {
    return Result.success(_dueCounts[subjectId] ?? 0);
  }

  @override
  Future<Result<List<Question>>> getPracticeQuestions(String subjectId) async {
    return Result.success([]);
  }
}

class _FakeSubjectsRepositoryNotifier extends SubjectsRepositoryNotifier {
  final SubjectRepository repo;
  _FakeSubjectsRepositoryNotifier(this.repo);

  @override
  Future<SubjectRepository> build() async => repo;
}

class _FakeMasteryGraphService extends MasteryGraphService {
  final List<MasteryState> weakTopics;

  _FakeMasteryGraphService({
    this.weakTopics = const [],
  });

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return Result.success(weakTopics);
  }
}

Subject _subject({required String id, required String name, String? code}) {
  return Subject(id: id, name: name, code: code);
}

Widget _buildTestApp({
  required SubjectRepository subjectRepo,
  QuestionRepository? questionRepo,
  SpacedRepetitionRepository? srRepo,
  MasteryGraphService? masteryService,
}) {
  return ProviderScope(
    overrides: [
      subjectsRepositoryProvider.overrideWith(() => _FakeSubjectsRepositoryNotifier(subjectRepo)),
      questionRepositoryProvider.overrideWithValue(questionRepo ?? _FakeQuestionRepository([])),
      spacedRepetitionRepositoryProvider.overrideWithValue(srRepo ?? _FakeSpacedRepetitionRepository()),
      if (masteryService != null)
        masteryGraphServiceProvider.overrideWithValue(masteryService),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const PracticeScreen(),
    ),
  );
}

void main() {
  group('PracticeScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no subjects', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text(_kNoPracticeSessionsYet), findsOneWidget);
      expect(find.text(_kAddSubjectsAndQuestions), findsOneWidget);
      expect(find.text(_kAddSubject), findsOneWidget);
    });

    testWidgets('shows practice modes grid when subjects exist', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Mathematics'));
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text(_kPracticeModes), findsOneWidget);
      expect(find.text(_kQuickPractice), findsOneWidget);
      expect(find.text(_kSpacedRepetition), findsOneWidget);
      expect(find.text(_kTopicFocus), findsOneWidget);
      expect(find.text(_kWeakAreas), findsOneWidget);
    });

    testWidgets('shows subject section with cards', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Mathematics'));
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Mathematics'), findsAtLeast(1));
    });

    testWidgets('shows practice button in FAB', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Physics'));
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text(_kPractice), findsOneWidget);
    });

    testWidgets('tune icon opens practice mode dialog for multiple subjects', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Math'));
      box.addSubject(_subject(id: '2', name: 'Physics'));
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(_kPracticeMode), findsAtLeast(1));
    });

    testWidgets('FAB shows no subjects when empty', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text(_kNoSubjects), findsOneWidget);
    });

    testWidgets('shows spaced repetition due count badge', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Chemistry'));
      final repo = _FakeSubjectRepository(box);
      final srRepo = _FakeSpacedRepetitionRepository({'1': 5});

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo, srRepo: srRepo));
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows book icon in empty state', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.book_online_outlined), findsOneWidget);
    });

    testWidgets('spaced repetition card shows disabled state when no due counts', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Physics'));
      final repo = _FakeSubjectRepository(box);
      final srRepo = _FakeSpacedRepetitionRepository({'1': 0});

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo, srRepo: srRepo));
      await tester.pumpAndSettle();

      expect(find.text(_kSpacedRepetition), findsOneWidget);
      expect(find.text(_kNoReviewsScheduled), findsAtLeast(1));
    });

    testWidgets('weak areas card shows coming soon when no subjects', (tester) async {
      final box = _MockSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text(_kNoPracticeSessionsYet), findsOneWidget);
    });

    testWidgets('weak areas card is disabled when no subjects', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Math'));
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text(_kWeakAreas), findsOneWidget);
    });

    testWidgets('disabled mode-card tap does nothing', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Physics'));
      final repo = _FakeSubjectRepository(box);
      final srRepo = _FakeSpacedRepetitionRepository({'1': 0});

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo, srRepo: srRepo));
      await tester.pumpAndSettle();

      // Spaced Repetition card should be disabled (no due counts)
      final srCard = find.text(_kSpacedRepetition);
      await tester.tap(srCard);
      await tester.pump(const Duration(milliseconds: 500));

      // No bottom sheet should appear
      expect(find.text(_kSpacedRepetition), findsWidgets);
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('PracticeScreen - spaced repetition subject selector', () {
    testWidgets('shows no reviews scheduled when no subjects have due counts', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Math'));
      box.addSubject(_subject(id: '2', name: 'Physics'));
      final repo = _FakeSubjectRepository(box);
      final srRepo = _FakeSpacedRepetitionRepository({'1': 0, '2': 0});

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo, srRepo: srRepo));
      await tester.pumpAndSettle();

      expect(find.text(_kNoReviewsScheduled), findsAtLeast(1));
    });

    testWidgets('shows subjects with due counts in SR selector', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Math'));
      box.addSubject(_subject(id: '2', name: 'Physics'));
      final repo = _FakeSubjectRepository(box);
      final srRepo = _FakeSpacedRepetitionRepository({'1': 3, '2': 0});

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo, srRepo: srRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text(_kSpacedRepetition));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Math'), findsWidgets);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Physics'), findsWidgets);
    });
  });

  group('PracticeScreen - topic selector', () {
    testWidgets('shows no topics when question repo has no topics', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Math'));
      final repo = _FakeSubjectRepository(box);
      final qRepo = _FakeQuestionRepository([]);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo, questionRepo: qRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text(_kTopicFocus));
      await tester.pump();

      expect(find.text(_kNoTopicsAvailable), findsOneWidget);
    });

    testWidgets('shows topic bottom sheet when topics available', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Math'));
      final repo = _FakeSubjectRepository(box);
      final now = DateTime.now();
      final qRepo = _FakeQuestionRepository([
        Question(
          id: 'q1', text: 'Q1', type: QuestionType.typedAnswer,
          subjectId: '1', topicId: 'topic-1', topic: 'Algebra',
          markscheme: null,
          createdAt: now, updatedAt: now,
        ),
        Question(
          id: 'q2', text: 'Q2', type: QuestionType.typedAnswer,
          subjectId: '1', topicId: 'topic-2', topic: 'Geometry',
          markscheme: null,
          createdAt: now, updatedAt: now,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo, questionRepo: qRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text(_kTopicFocus));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Algebra'), findsWidgets);
      expect(find.text('Geometry'), findsWidgets);
    });
  });

  group('PracticeScreen - weak areas', () {
    testWidgets('weak areas practice with single subject launches session', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Math'));
      final repo = _FakeSubjectRepository(box);
      final now = DateTime.now();
      final qRepo = _FakeQuestionRepository([
        Question(
          id: 'q1', text: 'Weak Q', type: QuestionType.typedAnswer,
          subjectId: '1', topicId: 'weak-topic', markscheme: null,
          createdAt: now, updatedAt: now,
        ),
      ]);
      final masteryService = _FakeMasteryGraphService(
        weakTopics: [
          MasteryState(
            studentId: 'student-1', topicId: 'weak-topic',
            masteryLevel: MasteryLevel.novice,
            accuracy: 0.3, reviewUrgency: 0.9,
            lastAttempt: now.subtract(const Duration(days: 7)),
            lastUpdated: now.subtract(const Duration(days: 7)),
          ),
        ],
      );

      await tester.pumpWidget(_buildTestApp(
        subjectRepo: repo,
        questionRepo: qRepo,
        masteryService: masteryService,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text(_kWeakAreas));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should navigate to PracticeSessionScreen
      expect(find.text('Weak Q'), findsOneWidget);
    });

    testWidgets('weak areas shows no weak areas snackbar when no weak topics', (tester) async {
      final box = _MockSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Math'));
      final repo = _FakeSubjectRepository(box);
      final masteryService = _FakeMasteryGraphService();
      final qRepo = _FakeQuestionRepository([]);

      await tester.pumpWidget(_buildTestApp(
        subjectRepo: repo,
        questionRepo: qRepo,
        masteryService: masteryService,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text(_kWeakAreas));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(_kNoWeakAreasFound), findsOneWidget);
    });
  });
}
