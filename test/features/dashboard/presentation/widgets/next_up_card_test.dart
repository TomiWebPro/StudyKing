import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/dashboard/presentation/widgets/next_up_card.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart'
    show masteryGraphServiceProvider;
import 'package:studyking/features/subjects/providers/subject_repository_provider.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../../helpers/navigator_observer_helper.dart';

class _FakeSubjectRepo extends SubjectRepository {
  final List<Subject> subjects;
  _FakeSubjectRepo(this.subjects);

  @override
  Future<Result<List<Subject>>> getAll() async => Result.success(subjects);
}

class _FakeMasteryService extends MasteryGraphService {
  final List<MasteryState> weakTopics;

  _FakeMasteryService({this.weakTopics = const []});


  @override
  Future<void> init() async {}

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return Result.success(weakTopics);
  }
}

class _FakePlannerService extends PlannerService {
  final List<Session> scheduledLessons;

  _FakePlannerService({this.scheduledLessons = const []});


  @override
  Future<Result<List<Session>>> getScheduledLessons() async => Result.success(scheduledLessons);
}

Session _makeSession({String id = 's1', String topicTitle = 'Algebra 101'}) {
  return Session(
    id: id,
    studentId: 'test',
    startTime: DateTime.now().add(const Duration(hours: 1)),
    plannedDurationMinutes: 30,
    type: SessionType.practice,
    tutorMetadata: TutorMetadata(topicTitle: topicTitle),
  );
}

Widget _buildTestApp({
  List<Subject> subjects = const [],
  int dueCount = 0,
  List<MasteryState> weakTopics = const [],
  List<Session> scheduledLessons = const [],
}) {
  return ProviderScope(
    overrides: [
      subjectRepositoryProvider.overrideWith((ref) => _FakeSubjectRepo(subjects)),
      masteryGraphServiceProvider.overrideWithValue(
        _FakeMasteryService(weakTopics: weakTopics),
      ),
      plannerServiceProvider.overrideWith(
        (ref) => _FakePlannerService(scheduledLessons: scheduledLessons),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: NextUpCard(studentId: 'test'),
      ),
    ),
  );
}

void main() {
  group('NextUpCard', () {
    testWidgets('renders with empty state when no data', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('renders NextUpCard without crashing', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(NextUpCard), findsOneWidget);
    });

    testWidgets('renders upcoming lesson tile when lessons exist', (tester) async {
      final lessons = [_makeSession()];
      await tester.pumpWidget(_buildTestApp(
        subjects: [Subject(id: 's1', name: 'Math', topicIds: [])],
        scheduledLessons: lessons,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Next Up'), findsOneWidget);
      expect(find.text('Algebra 101'), findsOneWidget);
      expect(find.text('1 upcoming lesson(s)'), findsOneWidget);
    });

    testWidgets('renders multiple upcoming lesson counts', (tester) async {
      final lessons = [
        _makeSession(id: 's1', topicTitle: 'Algebra 101'),
        _makeSession(id: 's2', topicTitle: 'Geometry'),
      ];
      await tester.pumpWidget(_buildTestApp(
        subjects: [Subject(id: 's1', name: 'Math', topicIds: [])],
        scheduledLessons: lessons,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('2 upcoming lesson(s)'), findsOneWidget);
    });

    testWidgets('renders due review count when dueCount > 0', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        subjects: [Subject(id: 's1', name: 'Math', topicIds: [])],
        dueCount: 3,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('3 review(s) due'), findsOneWidget);
      expect(find.text('Due for spaced repetition review'), findsOneWidget);
    });

    testWidgets('renders weak topics count when weak topics exist', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        subjects: [Subject(id: 's1', name: 'Math', topicIds: [])],
        weakTopics: [
          MasteryState(
            studentId: 'test',
            topicId: 't1',
            accuracy: 0.4,
            lastAttempt: DateTime.now(),
            lastUpdated: DateTime.now(),
            reviewUrgency: 0.8,
            readinessScore: 0.3,
          ),
        ],
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('1 weak topic(s)'), findsOneWidget);
    });

    testWidgets('navigates to planner when lesson tile is tapped', (tester) async {
      final observer = TestNavigatorObserver();
      final lessons = [_makeSession()];
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        navigatorObservers: [observer],
        home: ProviderScope(
          overrides: [
            subjectRepositoryProvider.overrideWith(
              (ref) => _FakeSubjectRepo([Subject(id: 's1', name: 'Math', topicIds: [])]),
            ),
            masteryGraphServiceProvider.overrideWithValue(
              _FakeMasteryService(),
            ),
            plannerServiceProvider.overrideWith(
              (ref) => _FakePlannerService(scheduledLessons: lessons),
            ),
          ],
          child: const NextUpCard(studentId: 'test'),
        ),
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.planner) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Planner Page')),
            );
          }
          return null;
        },
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Algebra 101'));
      await tester.pumpAndSettle();

      expect(observer.pushedRoutes.last.settings.name, AppRoutes.planner);
    });
  });
}