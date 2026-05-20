import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider;
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/practice/presentation/screens/practice_screen.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/subjects/providers/subject_repository_provider.dart';
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider;
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
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
    options: [],
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
  _FakeAttemptRepository();

  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async {
    return Result.success(const []);
  }
}

class _FakeQuestionRepo extends QuestionRepository {
  final List<Question> _questions;
  _FakeQuestionRepo(this._questions);

  @override
  Future<Result<List<Question>>> getAll() async => Result.success(_questions);

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async {
    return Result.success(_questions.where((q) => q.subjectId == subjectId).toList());
  }
}

class _FakeSpacedRepetitionService extends SpacedRepetitionService {
  final Map<String, int> _dueCounts;
  final List<Question>? _questions;

  _FakeSpacedRepetitionService([this._dueCounts = const {}, this._questions])
      : super(questionRepo: _FakeQuestionRepo([]), attemptRepo: AttemptRepository());

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

class _FailingSubjectRepo extends SubjectRepository {
  @override
  Future<Result<List<Subject>>> getAll() async => Result.failure('Load failed');
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
      questionRepositoryProvider.overrideWithValue(questionRepo ?? _FakeQuestionRepo([_makeQuestion()])),
      spacedRepetitionServiceProvider.overrideWithValue(effectiveSrService),
      attemptRepositoryProvider.overrideWithValue(attemptRepo ?? _FakeAttemptRepository()),
      if (masteryService != null) masteryGraphServiceProvider.overrideWithValue(masteryService),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const PracticeScreen(),
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : const [],
      onGenerateRoute: (settings) {
        if (settings.name == '/practice-session') {
          return MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Practice Session Screen')));
        }
        if (settings.name == '/exam-session') {
          return MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Exam Session Screen')));
        }
        if (settings.name == '/question-bank') {
          return MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Question Bank Screen')));
        }
        if (settings.name == '/upload') {
          return MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Upload Screen')));
        }
        return null;
      },
    ),
  );
}

const _kSpacedRepetition = 'Spaced Repetition';
const _kExamMode = 'Exam Mode';
const _kAtRiskQuestions = 'At-Risk Questions';
const _kPractice = 'Practice';
const _kSourcePractice = 'Source Practice';
const _kExamHistory = 'Exam History';

void main() {
  group('PracticeScreen - more coverage', () {
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
}
