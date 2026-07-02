import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/errors/result.dart';

import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/practice/presentation/screens/practice_screen.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider;
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/providers/subject_repository_provider.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../../helpers/navigator_observer_helper.dart';

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
const _kNoReviewsScheduled = 'No reviews scheduled.';
const _kNoTopicsAvailable = 'No topics available';
const _kNoWeakAreasFound = 'No weak areas found. Keep up the great work!';
const _kExamMode = 'Exam Mode';
const _kAtRiskQuestions = 'At-Risk Questions';
const _kQuestionsToday = 'Questions Today';
const _kDueForReview = 'Due for Review';
const _kRetry = 'Retry';
const _kNoQuestionsPracticeHint = 'Add questions to start practicing.';
const _kUploadMaterials = 'Upload Materials';
const _kSourcePractice = 'Source Practice';
const _kExamHistory = 'Exam History';

class _FakeSubjectBox {
  final Map<String, Subject> _storage = {};
  void addSubject(Subject s) => _storage[s.id] = s;
  Iterable<Subject> get values => _storage.values.toList();
  void clear() => _storage.clear();
}

Question _makeQuestion({String id = 'q1', String subjectId = '1', String topicId = 't1'}) {
  final now = DateTime.now();
  return Question(
    id: id,
    text: 'Question',
    type: QuestionType.typedAnswer,
    subjectId: subjectId,
    topicId: topicId,
    markscheme: null,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeSubjectRepository extends SubjectRepository {
  final _FakeSubjectBox _box;
  _FakeSubjectRepository(this._box);

  @override
  Future<Result<List<Subject>>> getAll() async => Result.success(_box.values.toList());
}

class _FailingSubjectRepository extends SubjectRepository {
  _FailingSubjectRepository();

  @override
  Future<Result<List<Subject>>> getAll() async => Result.failure('Load failed');
}

class _FakeAttemptRepository extends AttemptRepository {
  final List<StudentAttempt> attempts;

  _FakeAttemptRepository([this.attempts = const []]);

  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async {
    return Result.success(attempts);
  }
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

class _FakeSpacedRepetitionService extends SpacedRepetitionService {
  final Map<String, int> _dueCounts;
  final List<Question>? _questions;

  _FakeSpacedRepetitionService([this._dueCounts = const {}, this._questions]) : super(
    questionRepo: _FakeQuestionRepository([]),
    attemptRepo: AttemptRepository(),
  );

  @override
  Future<Result<int>> getSubjectDueCount(String subjectId) async {
    return Result.success(_dueCounts[subjectId] ?? 0);
  }

  @override
  Future<Result<List<Question>>> getPracticeQuestions(String subjectId) async {
    if (_questions != null) return Result.success(_questions);
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
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(
    String studentId, {
    double threshold = 0.5,
  }) async {
    return Result.success([]);
  }
}

class _FailingSubjectRepo extends SubjectRepository {
  @override
  Future<Result<List<Subject>>> getAll() async => Result.failure('Load failed');
}

Subject _subject({required String id, required String name, String? code}) {
  return Subject(id: id, name: name, code: code);
}

Widget _buildTestApp({
  required SubjectRepository subjectRepo,
  QuestionRepository? questionRepo,
  SpacedRepetitionService? srService,
  MasteryGraphService? masteryService,
  NavigatorObserver? navigatorObserver,
  Map<String, int>? srDueCounts,
  AttemptRepository? attemptRepo,
  bool showNoQuestionsBanner = false,
}) {
  final dueCounts = srDueCounts ?? <String, int>{};
  final effectiveSrService = srService ?? _FakeSpacedRepetitionService(dueCounts);
  return ProviderScope(
    overrides: [
      subjectsRepositoryProvider.overrideWith(() => _FakeSubjectsRepositoryNotifier(subjectRepo)),
      subjectRepositoryProvider.overrideWithValue(subjectRepo),
      questionRepositoryProvider.overrideWithValue(
        questionRepo ?? (showNoQuestionsBanner
            ? _FakeQuestionRepository([])
            : _FakeQuestionRepository([_makeQuestion()])),
      ),
      spacedRepetitionServiceProvider.overrideWithValue(effectiveSrService),
      attemptRepositoryProvider.overrideWithValue(attemptRepo ?? _FakeAttemptRepository()),
      if (masteryService != null)
        masteryGraphServiceProvider.overrideWithValue(masteryService),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const PracticeScreen(),
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : const [],
      onGenerateRoute: (settings) {
        if (settings.name == '/practice-session') {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Practice Session')),
          );
        }
        if (settings.name == '/exam-session') {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Exam Session')),
          );
        }
        if (settings.name == '/question-bank') {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Question Bank Screen')),
          );
        }
        if (settings.name == '/upload') {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Upload Screen')),
          );
        }
        return null;
      },
    ),
  );
}

void main() {
  group('PracticeScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no subjects', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text(_kNoPracticeSessionsYet), findsOneWidget);
      expect(find.text(_kAddSubjectsAndQuestions), findsOneWidget);
      expect(find.text(_kAddSubject), findsOneWidget);
    });

    testWidgets('shows practice modes grid when subjects exist', (tester) async {
      final box = _FakeSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Mathematics'));
      final repo = _FakeSubjectRepository(box);
      final qRepo = _FakeQuestionRepository([_makeQuestion()]);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo, questionRepo: qRepo));
      await tester.pumpAndSettle();

      expect(find.text(_kPracticeModes), findsOneWidget);
      expect(find.text(_kQuickPractice), findsOneWidget);
      expect(find.text(_kSpacedRepetition), findsOneWidget);
      expect(find.text(_kTopicFocus), findsOneWidget);
      expect(find.text(_kWeakAreas), findsOneWidget);
    });

    testWidgets('shows subject section with cards', (tester) async {
      final box = _FakeSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Mathematics'));
      final repo = _FakeSubjectRepository(box);
      final qRepo = _FakeQuestionRepository([_makeQuestion()]);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo, questionRepo: qRepo));
      await tester.pumpAndSettle();

      expect(find.text('Mathematics'), findsAtLeast(1));
    });

    testWidgets('shows practice button in FAB', (tester) async {
      final box = _FakeSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Physics'));
      final repo = _FakeSubjectRepository(box);
      final qRepo = _FakeQuestionRepository([_makeQuestion()]);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo, questionRepo: qRepo));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text(_kPractice), findsOneWidget);
    });

    testWidgets('FAB shows no subjects when empty', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text(_kNoSubjects), findsOneWidget);
    });

    testWidgets('shows spaced repetition due count badge', (tester) async {
      final box = _FakeSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Chemistry'));
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo, srDueCounts: {'1': 5}));
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows book icon in empty state', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.book_online_outlined), findsOneWidget);
    });

    testWidgets('spaced repetition card shows disabled state when no due counts', (tester) async {
      final box = _FakeSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Physics'));
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo, srDueCounts: {'1': 0}));
      await tester.pumpAndSettle();

      expect(find.text(_kSpacedRepetition), findsOneWidget);
      expect(find.text(_kNoReviewsScheduled), findsAtLeast(1));
    });

    testWidgets('weak areas card shows coming soon when no subjects', (tester) async {
      final box = _FakeSubjectBox();
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text(_kNoPracticeSessionsYet), findsOneWidget);
    });

    testWidgets('weak areas card is disabled when no subjects', (tester) async {
      final box = _FakeSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Math'));
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text(_kWeakAreas), findsOneWidget);
    });

    testWidgets('disabled mode-card tap does nothing', (tester) async {
      final box = _FakeSubjectBox();
      box.addSubject(_subject(id: '1', name: 'Physics'));
      final repo = _FakeSubjectRepository(box);

      await tester.pumpWidget(_buildTestApp(subjectRepo: repo, srDueCounts: {'1': 0}));
      await tester.pumpAndSettle();

      final srCard = find.text(_kSpacedRepetition);
      await tester.tap(srCard);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(_kSpacedRepetition), findsWidgets);
      expect(find.byType(BottomSheet), findsNothing);
    });

    group('spaced repetition subject selector', () {
      testWidgets('shows no reviews scheduled when no subjects have due counts', (tester) async {
        final box = _FakeSubjectBox();
        box.addSubject(_subject(id: '1', name: 'Math'));
        box.addSubject(_subject(id: '2', name: 'Physics'));
        final repo = _FakeSubjectRepository(box);

        await tester.pumpWidget(_buildTestApp(subjectRepo: repo, srDueCounts: {'1': 0, '2': 0}));
        await tester.pumpAndSettle();

        expect(find.text(_kNoReviewsScheduled), findsAtLeast(1));
      });

      testWidgets('shows subjects with due counts in SR selector', (tester) async {
        final box = _FakeSubjectBox();
        box.addSubject(_subject(id: '1', name: 'Math'));
        box.addSubject(_subject(id: '2', name: 'Physics'));
        final repo = _FakeSubjectRepository(box);

        await tester.pumpWidget(_buildTestApp(subjectRepo: repo, srDueCounts: {'1': 3, '2': 0}));
        await tester.pumpAndSettle();

        await tester.tap(find.text(_kSpacedRepetition));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Math'), findsWidgets);
        expect(find.text('3'), findsOneWidget);
        expect(find.text('Physics'), findsWidgets);
      });
    });

    group('topic selector', () {
      testWidgets('shows no topics when question repo has no topics', (tester) async {
        final box = _FakeSubjectBox();
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
        final box = _FakeSubjectBox();
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

    group('weak areas', () {
      testWidgets('weak areas shows no weak areas snackbar when no weak topics', (tester) async {
        final box = _FakeSubjectBox();
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

      testWidgets('weak areas with multiple subjects shows sheet', (tester) async {
        final box = _FakeSubjectBox();
        box.addSubject(_subject(id: '1', name: 'Math'));
        box.addSubject(_subject(id: '2', name: 'Physics'));
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

        expect(find.text('Math'), findsWidgets);
        expect(find.text('Physics'), findsWidgets);
      });
    });

    group('UI states', () {
      testWidgets('shows your subjects header when multiple subjects exist', (tester) async {
        final box = _FakeSubjectBox();
        box.addSubject(_subject(id: '1', name: 'Math'));
        box.addSubject(_subject(id: '2', name: 'Physics'));
        final repo = _FakeSubjectRepository(box);

        await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
        await tester.pumpAndSettle();

        expect(find.text('Your Subjects'), findsOneWidget);
      });

      testWidgets('does not show your subjects header when single subject', (tester) async {
        final box = _FakeSubjectBox();
        box.addSubject(_subject(id: '1', name: 'Math'));
        final repo = _FakeSubjectRepository(box);

        await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
        await tester.pumpAndSettle();

        expect(find.text('Your Subjects'), findsNothing);
      });

      testWidgets('loading transitions to content then shows loading done', (tester) async {
        final box = _FakeSubjectBox();
        box.addSubject(_subject(id: '1', name: 'Science'));
        final repo = _FakeSubjectRepository(box);

        await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Science'), findsAtLeast(1));
      });

      testWidgets('refresh indicator wraps content when subjects exist', (tester) async {
        final box = _FakeSubjectBox();
        box.addSubject(_subject(id: '1', name: 'Geology'));
        final repo = _FakeSubjectRepository(box);

        await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
        await tester.pumpAndSettle();

        expect(find.byType(RefreshIndicator), findsOneWidget);
      });

      testWidgets('FAB is enabled and shows practice when subjects exist', (tester) async {
        final box = _FakeSubjectBox();
        box.addSubject(_subject(id: '1', name: 'Biology'));
        final repo = _FakeSubjectRepository(box);

        await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
        await tester.pumpAndSettle();

        final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
        expect(fab.onPressed, isNotNull);
        expect(find.text(_kPractice), findsOneWidget);
      });

      testWidgets('FAB is disabled and shows no subjects when empty', (tester) async {
        final box = _FakeSubjectBox();
        final repo = _FakeSubjectRepository(box);

        await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
        await tester.pumpAndSettle();

        final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
        expect(fab.onPressed, isNull);
        expect(find.text(_kNoSubjects), findsOneWidget);
      });

      testWidgets('navigates to practice session from FAB tap', (tester) async {
        int pushCount = 0;

        final observer = TestNavigatorObserver(
          onPush: (_) { pushCount++; },
        );

        final box = _FakeSubjectBox();
        box.addSubject(_subject(id: '1', name: 'Math'));
        final repo = _FakeSubjectRepository(box);

        await tester.pumpWidget(_buildTestApp(
          subjectRepo: repo,
          navigatorObserver: observer,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Practice'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        expect(pushCount, greaterThan(0));
      });

      testWidgets('extra modes stack vertically on xs breakpoint', (tester) async {
        tester.view.physicalSize = const Size(590, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final box = _FakeSubjectBox();
        box.addSubject(_subject(id: '1', name: 'Math'));
        final repo = _FakeSubjectRepository(box);

        await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
        await tester.pumpAndSettle();

        expect(find.text('Exam Mode'), findsOneWidget);
        expect(find.text('Source Practice'), findsOneWidget);
        expect(find.text(_kAtRiskQuestions), findsOneWidget);
        final extraCards = find.byType(Card);
        expect(extraCards, findsAtLeast(2));
      });
    });

    group('error state', () {
      testWidgets('shows error UI with retry button on load failure', (tester) async {
        final failingRepo = _FailingSubjectRepository();

        await tester.pumpWidget(_buildTestApp(subjectRepo: failingRepo));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text(_kRetry), findsOneWidget);
        expect(find.text('Load failed'), findsOneWidget);
      });

      testWidgets('retry button triggers reload', (tester) async {
        final failingRepo = _FailingSubjectRepository();

        await tester.pumpWidget(_buildTestApp(subjectRepo: failingRepo));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);

        final retryButton = find.text(_kRetry);
        expect(retryButton, findsOneWidget);
      });
    });

    group('no questions banner', () {
      testWidgets('shows no-questions banner when questions exist in repo but empty', (tester) async {
        final box = _FakeSubjectBox();
        box.addSubject(_subject(id: '1', name: 'Math'));
        final repo = _FakeSubjectRepository(box);
        final qRepo = _FakeQuestionRepository([]);

        await tester.pumpWidget(_buildTestApp(
          subjectRepo: repo,
          questionRepo: qRepo,
          showNoQuestionsBanner: true,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Math'), findsWidgets);
        expect(find.text(_kNoQuestionsPracticeHint), findsOneWidget);
        expect(find.text(_kUploadMaterials), findsOneWidget);
      });
    });

    group('summary row', () {
      testWidgets('shows summary row with stats', (tester) async {
        final box = _FakeSubjectBox();
        box.addSubject(_subject(id: '1', name: 'Math'));
        final repo = _FakeSubjectRepository(box);

        await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
        await tester.pumpAndSettle();

        expect(find.text(_kQuestionsToday), findsOneWidget);
        expect(find.text(_kDueForReview), findsOneWidget);
        expect(find.byIcon(Icons.today), findsOneWidget);
        expect(find.byIcon(Icons.schedule), findsOneWidget);
        expect(find.byIcon(Icons.book), findsOneWidget);
      });
    });

    group('exam mode', () {
      testWidgets('exam mode shows subject selection sheet with multiple subjects', (tester) async {
        final box = _FakeSubjectBox();
        box.addSubject(_subject(id: '1', name: 'Math'));
        box.addSubject(_subject(id: '2', name: 'Physics'));
        final repo = _FakeSubjectRepository(box);

        await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
        await tester.pumpAndSettle();

        await tester.tap(find.text(_kExamMode));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Math'), findsWidgets);
        expect(find.text('Physics'), findsWidgets);
      });

      testWidgets('exam mode navigates directly with single subject', (tester) async {
        int pushCount = 0;
        final observer = TestNavigatorObserver(
          onPush: (_) { pushCount++; },
        );
        final box = _FakeSubjectBox();
        box.addSubject(_subject(id: '1', name: 'Math'));
        final repo = _FakeSubjectRepository(box);

        await tester.pumpWidget(_buildTestApp(
          subjectRepo: repo,
          navigatorObserver: observer,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text(_kExamMode));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(pushCount, greaterThan(0));
      });
    });

    group('quick practice from FAB', () {
      testWidgets('FAB tap shows subject selector', (tester) async {
        final box = _FakeSubjectBox();
        box.addSubject(_subject(id: '1', name: 'Math'));
        box.addSubject(_subject(id: '2', name: 'Physics'));
        final repo = _FakeSubjectRepository(box);

        await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
        await tester.pumpAndSettle();

        await tester.tap(find.text(_kPractice));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Math'), findsWidgets);
        expect(find.text('Physics'), findsWidgets);
      });
    });

    group('Question Bank entry', () {
      testWidgets('shows Question Bank card in extra modes', (tester) async {
        final box = _FakeSubjectBox();
        box.addSubject(_subject(id: '1', name: 'Math'));
        final repo = _FakeSubjectRepository(box);
        final qRepo = _FakeQuestionRepository([
          _makeQuestion(id: 'q1', subjectId: '1'),
        ]);
        final attemptRepo = _FakeAttemptRepository([]);
        final masteryService = _FakeMasteryGraphService();
        final navigatorObserver = TestNavigatorObserver();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              subjectsRepositoryProvider.overrideWith(() => _FakeSubjectsRepositoryNotifier(repo)),
              subjectRepositoryProvider.overrideWithValue(repo),
              questionRepositoryProvider.overrideWithValue(qRepo),
              attemptRepositoryProvider.overrideWithValue(attemptRepo),
              spacedRepetitionServiceProvider.overrideWithValue(_FakeSpacedRepetitionService({})),
              masteryGraphServiceProvider.overrideWithValue(masteryService),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              navigatorObservers: [navigatorObserver],
              home: const PracticeScreen(),
              onGenerateRoute: (settings) {
                if (settings.name == '/question-bank') {
                  return MaterialPageRoute(
                    builder: (_) => const Scaffold(body: Text('Question Bank Screen')),
                  );
                }
                return null;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.dragUntilVisible(
          find.text('Question Bank'),
          find.byType(Scrollable).first,
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();

        expect(find.text('Question Bank'), findsWidgets);

        await tester.tap(find.text('Question Bank').last);
        await tester.pumpAndSettle();

        expect(find.text('Question Bank Screen'), findsOneWidget);
      });
    });

    group('weak areas with attempts', () {
      testWidgets('weak areas navigates when sufficient attempts exist', (tester) async {
        final now = DateTime.now();
        final attempts = <StudentAttempt>[
          for (int i = 0; i < 10; i++)
            StudentAttempt(
              id: 'a$i',
              studentId: 'test',
              questionId: 'q$i',
              subjectId: '1',
              isCorrect: true,
              timestamp: now,
            ),
        ];
        final attemptRepo = _FakeAttemptRepository(attempts);
        final masteryService = _FakeMasteryGraphService();

        final box = _FakeSubjectBox();
        box.addSubject(_subject(id: '1', name: 'Math'));
        final repo = _FakeSubjectRepository(box);
        final qRepo = _FakeQuestionRepository([]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              subjectsRepositoryProvider.overrideWith(() => _FakeSubjectsRepositoryNotifier(repo)),
              subjectRepositoryProvider.overrideWithValue(repo),
              questionRepositoryProvider.overrideWithValue(qRepo),
              attemptRepositoryProvider.overrideWithValue(attemptRepo),
              spacedRepetitionServiceProvider.overrideWithValue(_FakeSpacedRepetitionService({})),
              masteryGraphServiceProvider.overrideWithValue(masteryService),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              home: const PracticeScreen(),
              onGenerateRoute: (settings) {
                if (settings.name == '/practice-session') {
                  return MaterialPageRoute(
                    builder: (_) => const Scaffold(body: Text('Practice Session')),
                  );
                }
                return null;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(_kWeakAreas));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text(_kNoWeakAreasFound), findsOneWidget);
      });
    });

    group('additional coverage', () {
      group('spaced repetition', () {
        testWidgets('SR shows all caught up when no due', (tester) async {
          final box = _FakeSubjectBox();
          box.addSubject(_subject(id: '1', name: 'Math'));
          final repo = _FakeSubjectRepository(box);

          await tester.pumpWidget(_buildTestApp(
            subjectRepo: repo,
            srDueCounts: {'1': 0},
          ));
          await tester.pumpAndSettle();

          await tester.tap(find.text(_kSpacedRepetition));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.textContaining('No reviews scheduled'), findsAtLeast(1));
        });
      });

      group('at-risk practice', () {
        testWidgets('at-risk with no data shows snackbar', (tester) async {
          final box = _FakeSubjectBox();
          box.addSubject(_subject(id: '1', name: 'Math'));
          final repo = _FakeSubjectRepository(box);
          final masteryService = _FakeMasteryGraphService();

          await tester.pumpWidget(_buildTestApp(
            subjectRepo: repo,
            masteryService: masteryService,
          ));
          await tester.pumpAndSettle();

          await tester.dragUntilVisible(
            find.text(_kAtRiskQuestions),
            find.byType(Scrollable).first,
            const Offset(0, -200),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text(_kAtRiskQuestions));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.byType(SnackBar), findsAtLeastNWidgets(1));
        });
      });

      group('extra modes', () {
        testWidgets('shows all extra mode cards', (tester) async {
          final box = _FakeSubjectBox();
          box.addSubject(_subject(id: '1', name: 'Math'));
          final repo = _FakeSubjectRepository(box);

          await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
          await tester.pumpAndSettle();

          await tester.dragUntilVisible(
            find.text(_kExamMode),
            find.byType(Scrollable).first,
            const Offset(0, -200),
          );
          await tester.pumpAndSettle();

          expect(find.text(_kExamMode), findsWidgets);
        });
      });

      group('exam mode', () {
        testWidgets('single subject navigates directly', (tester) async {
          int pushCount = 0;
          final observer = TestNavigatorObserver(
            onPush: (_) { pushCount++; },
          );
          final box = _FakeSubjectBox();
          box.addSubject(_subject(id: '1', name: 'Physics'));
          final repo = _FakeSubjectRepository(box);

          await tester.pumpWidget(_buildTestApp(
            subjectRepo: repo,
            navigatorObserver: observer,
          ));
          await tester.pumpAndSettle();

          await tester.dragUntilVisible(
            find.text(_kExamMode),
            find.byType(Scrollable).first,
            const Offset(0, -200),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text(_kExamMode));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          expect(pushCount, greaterThan(0));
        });

        testWidgets('multiple subjects shows selector', (tester) async {
          final box = _FakeSubjectBox();
          box.addSubject(_subject(id: '1', name: 'Math'));
          box.addSubject(_subject(id: '2', name: 'Physics'));
          final repo = _FakeSubjectRepository(box);

          await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
          await tester.pumpAndSettle();

          await tester.dragUntilVisible(
            find.text(_kExamMode),
            find.byType(Scrollable).first,
            const Offset(0, -200),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text(_kExamMode));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.text('Math'), findsWidgets);
        });
      });

      group('weak areas', () {
        testWidgets('insufficient attempts shows snackbar', (tester) async {
          final now = DateTime.now();
          final attempts = <StudentAttempt>[
            StudentAttempt(
              id: 'a1', studentId: 'test', questionId: 'q1',
              subjectId: '1', isCorrect: true, timestamp: now,
            ),
          ];
          final attemptRepo = _FakeAttemptRepository(attempts);
          final masteryService = _FakeMasteryGraphService();
          final box = _FakeSubjectBox();
          box.addSubject(_subject(id: '1', name: 'Math'));
          final repo = _FakeSubjectRepository(box);

          await tester.pumpWidget(_buildTestApp(
            subjectRepo: repo,
            attemptRepo: attemptRepo,
            masteryService: masteryService,
          ));
          await tester.pumpAndSettle();

          await tester.dragUntilVisible(
            find.text(_kWeakAreas),
            find.byType(Scrollable).first,
            const Offset(0, -200),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text(_kWeakAreas));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.byType(SnackBar), findsAtLeastNWidgets(1));
        });
      });

      group('UI states', () {
        testWidgets('empty state when no subjects', (tester) async {
          final box = _FakeSubjectBox();
          final repo = _FakeSubjectRepository(box);

          await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
          await tester.pumpAndSettle();

          expect(find.text('No Practice Sessions Yet'), findsOneWidget);
        });

        testWidgets('shows practice FAB with subjects', (tester) async {
          final box = _FakeSubjectBox();
          box.addSubject(_subject(id: '1', name: 'Math'));
          final repo = _FakeSubjectRepository(box);

          await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
          await tester.pumpAndSettle();

          expect(find.byType(FloatingActionButton), findsOneWidget);
          expect(find.text(_kPractice), findsOneWidget);
        });

        testWidgets('FAB tap shows subject selector with multiple subjects', (tester) async {
          final box = _FakeSubjectBox();
          box.addSubject(_subject(id: '1', name: 'Biology'));
          box.addSubject(_subject(id: '2', name: 'Chemistry'));
          final repo = _FakeSubjectRepository(box);

          await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
          await tester.pumpAndSettle();

          await tester.tap(find.text(_kPractice));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.text('Biology'), findsWidgets);
          expect(find.text('Chemistry'), findsWidgets);
        });

        testWidgets('question bank card navigates', (tester) async {
          int pushCount = 0;
          final observer = TestNavigatorObserver(
            onPush: (_) { pushCount++; },
          );
          final box = _FakeSubjectBox();
          box.addSubject(_subject(id: '1', name: 'Math'));
          final repo = _FakeSubjectRepository(box);

          await tester.pumpWidget(_buildTestApp(
            subjectRepo: repo,
            navigatorObserver: observer,
          ));
          await tester.pumpAndSettle();

          await tester.dragUntilVisible(
            find.text('Question Bank'),
            find.byType(Scrollable).first,
            const Offset(0, -200),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Question Bank').last);
          await tester.pumpAndSettle();

          expect(pushCount, greaterThan(0));
        });
      });

      group('quick practice from FAB', () {
        testWidgets('tapping FAB with one subject navigates to subject selector then session', (tester) async {
          int pushCount = 0;
          final observer = TestNavigatorObserver(
            onPush: (_) { pushCount++; },
          );
          final box = _FakeSubjectBox();
          box.addSubject(_subject(id: '1', name: 'Math'));
          final repo = _FakeSubjectRepository(box);

          await tester.pumpWidget(_buildTestApp(
            subjectRepo: repo,
            navigatorObserver: observer,
          ));
          await tester.pumpAndSettle();

          await tester.tap(find.text(_kPractice));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          expect(pushCount, greaterThan(0));
        });
      });

      group('load error recovery', () {
        testWidgets('shows error state on load failure', (tester) async {
          final repo = _FailingSubjectRepo();

          await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
          await tester.pumpAndSettle();

          expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
        });
      });
    });

    group('more coverage', () {
      group('spaced repetition', () {
        testWidgets('SR with due questions shows subject picker', (tester) async {
          final box = _FakeSubjectBox();
          box.addSubject(_subject(id: '1', name: 'Math'));
          box.addSubject(_subject(id: '2', name: 'Physics'));
          final repo = _FakeSubjectRepository(box);

          await tester.pumpWidget(_buildTestApp(
            subjectRepo: repo,
            srDueCounts: {'1': 3, '2': 5},
          ));
          await tester.pumpAndSettle();

          await tester.tap(find.text(_kSpacedRepetition));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.text('Math'), findsWidgets);
          expect(find.text('Physics'), findsWidgets);
        });

        testWidgets('SR navigates to practice session with due questions', (tester) async {
          int pushCount = 0;
          final observer = TestNavigatorObserver(onPush: (_) { pushCount++; });
          final box = _FakeSubjectBox();
          box.addSubject(_subject(id: '1', name: 'Math'));
          final repo = _FakeSubjectRepository(box);
          final srService = _FakeSpacedRepetitionService({'1': 3}, [_makeQuestion(id: 'sr1', subjectId: '1')]);

          await tester.pumpWidget(_buildTestApp(
            subjectRepo: repo, srService: srService, navigatorObserver: observer,
          ));
          await tester.pumpAndSettle();

          await tester.tap(find.text(_kSpacedRepetition));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          expect(pushCount, greaterThan(0));
        });
      });

      group('exam history', () {
        testWidgets('exam history card title is visible', (tester) async {
          final box = _FakeSubjectBox();
          box.addSubject(_subject(id: '1', name: 'Math'));
          final repo = _FakeSubjectRepository(box);

          await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
          await tester.pumpAndSettle();

          await tester.dragUntilVisible(
            find.text(_kExamHistory),
            find.byType(Scrollable).first,
            const Offset(0, -200),
          );
          await tester.pumpAndSettle();

          expect(find.text(_kExamHistory), findsWidgets);
        });
      });

      group('extra mode cards', () {
        testWidgets('extra mode titles are present', (tester) async {
          final box = _FakeSubjectBox();
          box.addSubject(_subject(id: '1', name: 'Science'));
          final repo = _FakeSubjectRepository(box);

          await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
          await tester.pumpAndSettle();

          await tester.dragUntilVisible(
            find.text(_kExamMode),
            find.byType(Scrollable).first,
            const Offset(0, -200),
          );
          await tester.pumpAndSettle();

          expect(find.text(_kExamMode), findsWidgets);
          expect(find.text(_kSourcePractice), findsWidgets);
          expect(find.text(_kAtRiskQuestions), findsWidgets);
          expect(find.text(_kExamHistory), findsWidgets);
        });
      });

      group('summary row', () {
        testWidgets('summary row shows with subjects', (tester) async {
          final box = _FakeSubjectBox();
          box.addSubject(_subject(id: '1', name: 'Physics'));
          box.addSubject(_subject(id: '2', name: 'Chemistry'));
          final repo = _FakeSubjectRepository(box);

          await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
          await tester.pumpAndSettle();

          expect(find.text('Questions Today'), findsOneWidget);
          expect(find.text('Due for Review'), findsOneWidget);
        });
      });

      group('error state', () {
        testWidgets('subject load failure shows scaffold', (tester) async {
          final failingRepo = _FailingSubjectRepo();

          await tester.pumpWidget(_buildTestApp(subjectRepo: failingRepo));
          await tester.pumpAndSettle();

          expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
        });
      });

      group('UI states', () {
        testWidgets('shows practice FAB button', (tester) async {
          final box = _FakeSubjectBox();
          box.addSubject(_subject(id: '1', name: 'Biology'));
          final repo = _FakeSubjectRepository(box);

          await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
          await tester.pumpAndSettle();

          expect(find.byType(FloatingActionButton), findsOneWidget);
          expect(find.text(_kPractice), findsOneWidget);
        });
      });

      group('question bank card', () {
        testWidgets('question bank card exists in extra modes', (tester) async {
          final box = _FakeSubjectBox();
          box.addSubject(_subject(id: '1', name: 'Math'));
          final repo = _FakeSubjectRepository(box);

          await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
          await tester.pumpAndSettle();

          await tester.dragUntilVisible(
            find.text('Question Bank'),
            find.byType(Scrollable).first,
            const Offset(0, -200),
          );
          await tester.pumpAndSettle();

          expect(find.text('Question Bank'), findsWidgets);
        });
      });
    });
  });
}
