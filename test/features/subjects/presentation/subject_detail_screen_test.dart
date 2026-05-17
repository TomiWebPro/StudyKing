import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/subjects/presentation/subject_detail_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../helpers/navigator_observer_helper.dart';

class _FakeSubjectRepository extends SubjectRepository {
  final Map<String, Subject> _subjects = {};
  bool _shouldThrowOnDelete = false;

  void addSubject(Subject subject) => _subjects[subject.id] = subject;
  void setThrowOnDelete(bool value) => _shouldThrowOnDelete = value;

  @override
  Future<Result<Subject?>> get(String key) async => Result.success(_subjects[key]);

  @override
  Future<Result<void>> delete(String key) async {
    if (_shouldThrowOnDelete) throw Exception('Delete failed');
    _subjects.remove(key);
    return Result.success(null);
  }
}

class _FakeSubjectsNotifier extends SubjectsRepositoryNotifier {
  final SubjectRepository _repo;
  _FakeSubjectsNotifier(this._repo);

  @override
  Future<SubjectRepository> build() async => _repo;
}

class _FakeSessionRepository extends SessionRepository {
  final List<Session>? _sessions;
  final bool _shouldThrow;

  _FakeSessionRepository(this._sessions) : _shouldThrow = false;

  _FakeSessionRepository.throwing() : _sessions = null, _shouldThrow = true;

  @override
  Future<Result<List<Session>>> getAll() async {
    if (_shouldThrow) throw Exception('Failed to load sessions');
    return Result.success(_sessions!);
  }
}

Session _session({
  required String id,
  required String subjectId,
  int questionsAnswered = 10,
  int correctAnswers = 8,
  int actualDurationMs = 3600000,
}) {
  return Session(
    id: id,
    studentId: 'student-1',
    subjectId: subjectId,
    type: SessionType.practice,
    startTime: DateTime(2024, 6, 15, 10, 30),
    actualDurationMs: actualDurationMs,
    questionsAnswered: questionsAnswered,
    correctAnswers: correctAnswers,
  );
}



Route<dynamic>? _testRoute(RouteSettings settings) {
  if (settings.name == AppRoutes.practiceSession) {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(body: Text('Practice Mock')),
      settings: settings,
    );
  }
  if (settings.name == AppRoutes.upload) {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(body: Text('Upload Mock')),
      settings: settings,
    );
  }
  if (settings.name == AppRoutes.dashboard) {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(body: Text('Dashboard Mock')),
      settings: settings,
    );
  }
  if (settings.name == AppRoutes.subjectSelection) {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(body: Text('Edit Subject Mock')),
      settings: settings,
    );
  }
  return null;
}

Widget _buildTestApp() {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateRoute: _testRoute,
      home: SubjectDetailScreen(
        args: const SubjectDetailArgs(
          subjectId: 'test-id',
          subjectName: 'Mathematics',
          subjectCode: 'MATH101',
          subjectColor: '#2196F3',
          subjectDescription: 'Mathematics course',
          subjectTeacher: 'Dr. Smith',
          topicIds: ['topic-1', 'topic-2'],
        ),
      ),
    ),
  );
}

Widget _buildTestAppMinimal() {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateRoute: _testRoute,
      home: SubjectDetailScreen(
        args: const SubjectDetailArgs(
          subjectId: 'test-id',
          subjectName: 'Physics',
          subjectColor: '#4CAF50',
          topicIds: [],
        ),
      ),
    ),
  );
}

Widget _buildTestAppWithObserver(TestNavigatorObserver observer) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: [observer],
      onGenerateRoute: _testRoute,
      home: SubjectDetailScreen(
        args: const SubjectDetailArgs(
          subjectId: 'test-id',
          subjectName: 'Mathematics',
          subjectCode: 'MATH101',
          subjectColor: '#2196F3',
          subjectDescription: 'Mathematics course',
          subjectTeacher: 'Dr. Smith',
          topicIds: ['topic-1', 'topic-2'],
        ),
      ),
    ),
  );
}

Widget _buildTestAppWithSessionRepo(SessionRepository sessionRepo) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateRoute: _testRoute,
      home: SubjectDetailScreen(
        sessionRepository: sessionRepo,
        args: const SubjectDetailArgs(
          subjectId: 'test-id',
          subjectName: 'Mathematics',
          subjectCode: 'MATH101',
          subjectColor: '#2196F3',
          subjectDescription: 'Mathematics course',
          subjectTeacher: 'Dr. Smith',
          topicIds: ['topic-1', 'topic-2'],
        ),
      ),
    ),
  );
}

Widget _buildTestAppWithSubjectRepo(SubjectRepository subjectRepo) {
  return ProviderScope(
    overrides: [
      subjectsRepositoryProvider.overrideWith(() => _FakeSubjectsNotifier(subjectRepo)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateRoute: _testRoute,
      home: SubjectDetailScreen(
        args: const SubjectDetailArgs(
          subjectId: 'test-id',
          subjectName: 'Mathematics',
          subjectCode: 'MATH101',
          subjectColor: '#2196F3',
          subjectDescription: 'Mathematics course',
          subjectTeacher: 'Dr. Smith',
          topicIds: ['topic-1', 'topic-2'],
        ),
      ),
    ),
  );
}

void main() {
  group('SubjectDetailScreen', () {
    testWidgets('renders subject name in sliver header', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(SliverAppBar), findsOneWidget);
    });

    testWidgets('renders tab bar with 4 tabs', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(4));
    });

    testWidgets('renders more option icon', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('tab labels are present on TabBar', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('Lessons'), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);
    });

    testWidgets('lessons tab shows empty state', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('No lessons yet'), findsOneWidget);
    });

    testWidgets('practice tab shows practice buttons', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.tap(find.text('Practice'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Start Practice'), findsOneWidget);
      expect(find.byIcon(Icons.repeat), findsOneWidget);
    });

    testWidgets('history tab shows empty state', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.tap(find.text('History'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('No sessions yet'), findsOneWidget);
    });

    testWidgets('start practice navigates to practice session', (tester) async {
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(_buildTestAppWithObserver(observer));
      await tester.pump();

      await tester.tap(find.text('Practice'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Start Practice'));
      await tester.pumpAndSettle();

      expect(observer.pushedRoutes, hasLength(1));
      expect(observer.pushedRoutes.first.settings.name, AppRoutes.practiceSession);
    });

    testWidgets('practice mode navigates to spaced repetition', (tester) async {
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(_buildTestAppWithObserver(observer));
      await tester.pump();

      await tester.tap(find.text('Practice'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Practice Mode').last);
      await tester.pumpAndSettle();

      expect(observer.pushedRoutes, hasLength(1));
      expect(observer.pushedRoutes.first.settings.name, AppRoutes.practiceSession);
    });

    testWidgets('stats tab shows metric cards', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.tap(find.text('Stats'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Accuracy'), findsOneWidget);
      expect(find.text('Practice Progress'), findsOneWidget);
    });

    testWidgets('switches between all tabs', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      for (final tab in ['Lessons', 'Practice', 'History', 'Stats']) {
        await tester.tap(find.text(tab));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
      }
    });

    testWidgets('renders subject code when provided', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('MATH101'), findsOneWidget);
    });

    testWidgets('does not render subject code when null', (tester) async {
      await tester.pumpWidget(_buildTestAppMinimal());
      await tester.pump();

      expect(find.text('Physics'), findsAtLeast(1));
    });

    testWidgets('displays subject name in FlexibleSpaceBar title', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('Mathematics'), findsAtLeast(1));
    });

    testWidgets('first letter avatar shows correct letter', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('M'), findsOneWidget);
    });

    testWidgets('avatar letter uses Physics initial for minimal args', (tester) async {
      await tester.pumpWidget(_buildTestAppMinimal());
      await tester.pump();

      expect(find.text('P'), findsOneWidget);
    });

    testWidgets('bottom sheet shows upload and dashboard options', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      final iconButtons = find.byType(IconButton);
      IconButton? moreVert;
      for (final el in iconButtons.evaluate()) {
        final btn = el.widget as IconButton;
        if (btn.icon is Icon && (btn.icon as Icon).icon == Icons.more_vert) {
          moreVert = btn;
          break;
        }
      }

      moreVert!.onPressed!.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Upload Content'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Delete Subject'), findsOneWidget);
    });

    testWidgets('delete option in bottom sheet shows confirmation dialog', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      final iconButtons = find.byType(IconButton);
      IconButton? moreVert;
      for (final el in iconButtons.evaluate()) {
        final btn = el.widget as IconButton;
        if (btn.icon is Icon && (btn.icon as Icon).icon == Icons.more_vert) {
          moreVert = btn;
          break;
        }
      }

      moreVert!.onPressed!.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Delete Subject'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Delete Subject'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this subject? This will also delete all associated lessons and questions.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('delete dialog cancel button dismisses dialog', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      final iconButtons = find.byType(IconButton);
      IconButton? moreVert;
      for (final el in iconButtons.evaluate()) {
        final btn = el.widget as IconButton;
        if (btn.icon is Icon && (btn.icon as Icon).icon == Icons.more_vert) {
          moreVert = btn;
          break;
        }
      }

      moreVert!.onPressed!.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Delete Subject'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Are you sure you want to delete this subject? This will also delete all associated lessons and questions.'), findsNothing);
    });

    testWidgets('delete dialog delete button pops back', (tester) async {
      final subjectRepo = _FakeSubjectRepository();
      subjectRepo.addSubject(Subject(
        id: 'test-id',
        name: 'Mathematics',
        color: '#2196F3',
      ));
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(_buildTestAppWithSubjectRepo(subjectRepo));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => _FakeSubjectsNotifier(subjectRepo)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            navigatorObservers: [observer],
            onGenerateRoute: _testRoute,
            home: SubjectDetailScreen(
              args: const SubjectDetailArgs(
                subjectId: 'test-id',
                subjectName: 'Mathematics',
                subjectColor: '#2196F3',
                topicIds: [],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final iconButtons = find.byType(IconButton);
      IconButton? moreVert;
      for (final el in iconButtons.evaluate()) {
        final btn = el.widget as IconButton;
        if (btn.icon is Icon && (btn.icon as Icon).icon == Icons.more_vert) {
          moreVert = btn;
          break;
        }
      }

      moreVert!.onPressed!.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Delete Subject'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect((await subjectRepo.get('test-id')).data, isNull);
    });

    testWidgets('upload content in bottom sheet navigates to upload', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      final iconButtons = find.byType(IconButton);
      IconButton? moreVert;
      for (final el in iconButtons.evaluate()) {
        final btn = el.widget as IconButton;
        if (btn.icon is Icon && (btn.icon as Icon).icon == Icons.more_vert) {
          moreVert = btn;
          break;
        }
      }

      moreVert!.onPressed!.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Upload Content'));
      await tester.pumpAndSettle();

      expect(find.text('Upload Mock'), findsOneWidget);
    });

    testWidgets('dashboard in bottom sheet navigates to dashboard', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      final iconButtons = find.byType(IconButton);
      IconButton? moreVert;
      for (final el in iconButtons.evaluate()) {
        final btn = el.widget as IconButton;
        if (btn.icon is Icon && (btn.icon as Icon).icon == Icons.more_vert) {
          moreVert = btn;
          break;
        }
      }

      moreVert!.onPressed!.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard Mock'), findsOneWidget);
    });

    testWidgets('session details dialog shows session info with correct answers', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: 'test-id', correctAnswers: 8, questionsAnswered: 10, actualDurationMs: 3600000),
      ]);
      await tester.pumpWidget(_buildTestAppWithSessionRepo(repo));
      await tester.pump();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.text('Session 1'), findsOneWidget);

      await tester.tap(find.text('Session 1'));
      await tester.pumpAndSettle();

      expect(find.text('Session Details'), findsOneWidget);
    });

    testWidgets('session details dialog close button dismisses dialog', (tester) async {
      final repo = _FakeSessionRepository([
        _session(id: 's1', subjectId: 'test-id'),
      ]);
      await tester.pumpWidget(_buildTestAppWithSessionRepo(repo));
      await tester.pump();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Session 1'));
      await tester.pumpAndSettle();

      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Session Details'), findsNothing);
    });

    testWidgets('session details dialog handles zero correct answers', (tester) async {
      final repo = _FakeSessionRepository([
        Session(
          id: 's1',
          studentId: 'student-1',
          subjectId: 'test-id',
          type: SessionType.practice,
          startTime: DateTime(2024, 6, 15, 10, 30),
          actualDurationMs: 3600000,
          questionsAnswered: 10,
          correctAnswers: 0,
        ),
      ]);
      await tester.pumpWidget(_buildTestAppWithSessionRepo(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Session 1'));
      await tester.pumpAndSettle();

      expect(find.text('Session Details'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('Questions'), findsOneWidget);
    });

    testWidgets('history tab shows empty state when sessionRepository throws', (tester) async {
      final repo = _FakeSessionRepository.throwing();
      await tester.pumpWidget(_buildTestAppWithSessionRepo(repo));
      await tester.pump();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.text('No sessions yet'), findsOneWidget);
    });

    testWidgets('edit subject navigates to subject selection screen', (tester) async {
      final subjectRepo = _FakeSubjectRepository();
      subjectRepo.addSubject(Subject(
        id: 'test-id',
        name: 'Mathematics',
        color: '#2196F3',
      ));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => _FakeSubjectsNotifier(subjectRepo)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            onGenerateRoute: _testRoute,
            home: SubjectDetailScreen(
              args: const SubjectDetailArgs(
                subjectId: 'test-id',
                subjectName: 'Mathematics',
                subjectColor: '#2196F3',
                topicIds: ['topic-1'],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final iconButtons = find.byType(IconButton);
      IconButton? moreVert;
      for (final el in iconButtons.evaluate()) {
        final btn = el.widget as IconButton;
        if (btn.icon is Icon && (btn.icon as Icon).icon == Icons.more_vert) {
          moreVert = btn;
          break;
        }
      }

      moreVert!.onPressed!.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Edit Subject'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Edit Subject Mock'), findsOneWidget);
    });

    testWidgets('delete shows error snackbar on failure', (tester) async {
      final subjectRepo = _FakeSubjectRepository();
      subjectRepo.setThrowOnDelete(true);
      subjectRepo.addSubject(Subject(id: 'test-id', name: 'Mathematics', color: '#2196F3'));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subjectsRepositoryProvider.overrideWith(() => _FakeSubjectsNotifier(subjectRepo)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            onGenerateRoute: _testRoute,
            home: SubjectDetailScreen(
              args: const SubjectDetailArgs(
                subjectId: 'test-id',
                subjectName: 'Mathematics',
                subjectColor: '#2196F3',
                topicIds: [],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final iconButtons = find.byType(IconButton);
      IconButton? moreVert;
      for (final el in iconButtons.evaluate()) {
        final btn = el.widget as IconButton;
        if (btn.icon is Icon && (btn.icon as Icon).icon == Icons.more_vert) {
          moreVert = btn;
          break;
        }
      }

      moreVert!.onPressed!.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Delete Subject'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Error: Exception: Delete failed'), findsOneWidget);
    });
  });
}
