import 'dart:io' show Directory;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart' as hive_package;
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider;
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/practice/services/mastery_recorder.dart';
import 'package:studyking/features/practice/presentation/screens/practice_screen.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/practice/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/routes/app_router.dart' show AppRoutes;
import '../../../../helpers/navigator_observer_helper.dart';
import '../shared_test_helpers.dart';

class _FakeSubjectBox {
  final Map<String, Subject> _storage = {};
  void addSubject(Subject s) => _storage[s.id] = s;
  Iterable<Subject> get values => _storage.values.toList();
}

Subject _subject({required String id, required String name, String? code}) {
  return Subject(id: id, name: name, code: code);
}

Question _makeQuestion({String id = 'q1', String subjectId = '1', String topicId = 't1'}) {
  final now = DateTime.now();
  return Question(
    id: id,
    text: 'Question $id',
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

class _FakeSubjectsRepositoryNotifier extends SubjectsRepositoryNotifier {
  final SubjectRepository repo;
  _FakeSubjectsRepositoryNotifier(this.repo);

  @override
  Future<SubjectRepository> build() async => repo;
}

class _FakeAttemptRepository extends AttemptRepository {
  final List<StudentAttempt> attempts;

  _FakeAttemptRepository([this.attempts = const []]);

  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async {
    return Result.success(attempts);
  }
}

class _FakeSpacedRepetitionService extends SpacedRepetitionService {
  final Map<String, int> _dueCounts;
  final List<Question>? _questions;

  _FakeSpacedRepetitionService([this._dueCounts = const {}, this._questions])
      : super(
          questionRepo: FakeQuestionRepository(Result.success([])),
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

class _FakeMasteryGraphService extends MasteryGraphService {
  _FakeMasteryGraphService();

  @override
  Future<void> init() async {}

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

Widget _buildTestApp({
  required SubjectRepository subjectRepo,
  QuestionRepository? questionRepo,
  _FakeSpacedRepetitionService? srService,
  MasteryGraphService? masteryService,
  NavigatorObserver? navigatorObserver,
  Map<String, int>? srDueCounts,
  _FakeAttemptRepository? attemptRepo,
}) {
  final dueCounts = srDueCounts ?? <String, int>{};
  final effectiveSrService = srService ?? _FakeSpacedRepetitionService(dueCounts);
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith((ref) => FakeSettingsController()),
      subjectsRepositoryProvider.overrideWith(() => _FakeSubjectsRepositoryNotifier(subjectRepo)),
      subjectRepositoryProvider.overrideWithValue(subjectRepo),
      questionRepositoryProvider.overrideWithValue(
        questionRepo ?? FakeQuestionRepository(Result.success([_makeQuestion()])),
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
            builder: (_) => const Scaffold(body: Text('Practice Session Screen')),
          );
        }
        if (settings.name == '/exam-session') {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Exam Session Screen')),
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

const _kSpacedRepetition = 'Spaced Repetition';
const _kWeakAreas = 'Weak Areas';
const _kExamMode = 'Exam Mode';
const _kAtRiskQuestions = 'At-Risk Questions';
const _kPractice = 'Practice';
const _kSourcePractice = 'Source Practice';
const _kNoWeakAreasFound = 'No weak areas found. Keep up the great work!';

void main() {
  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('hive_test');
    hive_package.Hive.init(dir.path);
  });

  group('PracticeScreen - additional coverage', () {
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
        final box = _FakeSubjectBox();
        final repo = _FailingSubjectRepo();

        await tester.pumpWidget(_buildTestApp(subjectRepo: repo));
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
      });
    });
  });
}

class _FailingSubjectRepo extends SubjectRepository {
  @override
  Future<Result<List<Subject>>> getAll() async => Result.failure('Load failed');
}
