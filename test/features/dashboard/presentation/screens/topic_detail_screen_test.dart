import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/dashboard/presentation/screens/topic_detail_screen.dart';
import 'package:studyking/features/dashboard/providers/dashboard_data_providers.dart';
import 'package:studyking/features/dashboard/providers/dashboard_providers.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart'
    show masteryGraphServiceProvider, readinessScorerProvider;
import 'package:studyking/features/practice/services/readiness_scorer.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/questions/providers/question_providers.dart'
    show questionRepositoryProvider;
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

import '../../../../helpers/navigator_observer_helper.dart';

class _FakeTopicRepository extends TopicRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Topic>>> getAll() async =>
      Result.success([]);
}

class _FakeMasteryGraphService extends MasteryGraphService {
  final List<MasteryState> allMastery;

  _FakeMasteryGraphService({this.allMastery = const []});

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) async =>
      Result.success(allMastery);

  @override
  Future<Result<MasteryState>> getTopicMastery(String studentId, String topicId) async {
    final state = allMastery.where((s) => s.topicId == topicId).firstOrNull;
    if (state == null) return Result.failure('not found');
    return Result.success(state);
  }

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) async =>
      Result.success({});
}

class _FakeInstrumentationService extends InstrumentationService {
  _FakeInstrumentationService() : super(adherenceRepository: _FakeAdherenceRepo());

  @override
  Future<void> init() async {}
}

class _FakeAdherenceRepo extends PlanAdherenceRepository {
  @override
  Future<void> init() async {}

  @override
  Future<double> getAverageAdherence(String studentId) async => 0.0;

  @override
  Future<List<PlanAdherenceModel>> getWeekly(String studentId) async => [];
}

class _FakeQuestionRepo extends QuestionRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Question>>> getAll() async => Result.success([]);
}

class _FakeQuestionRepoWithQuestions extends QuestionRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Question>>> getAll() async => Result.success([
        Question(
          id: 'q1',
          text: 'Test question',
          type: QuestionType.singleChoice,
          subjectId: 'subject-1',
          topicId: 'topic-1',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
      ]);
}

class _FakeReadinessScorer extends ReadinessScorer {
  _FakeReadinessScorer() : super(masteryService: null, studentIdService: null);

  @override
  Future<List<ScoredQuestion>> scoreQuestions(List<Question> questions) async =>
      questions.map((q) => ScoredQuestion(question: q, score: 0.5)).toList();
}

class _FakeSessionRepo extends SessionRepository {
  @override
  Future<void> init() async {}
}

MasteryState _state({
  required String topicId,
  double accuracy = 0.5,
  int totalAttempts = 5,
  int correctAttempts = 3,
  MasteryLevel masteryLevel = MasteryLevel.developing,
  int currentStreak = 2,
  int bestStreak = 5,
  double readinessScore = 0.6,
  double confidenceTrend = 0.5,
  double forgettingRisk = 0.3,
  double reviewUrgency = 0.4,
  List<double> recentAccuracy = const [],
  List<int> recentConfidence = const [],
}) {
  return MasteryState(
    studentId: 'student-1',
    topicId: topicId,
    accuracy: accuracy,
    totalAttempts: totalAttempts,
    correctAttempts: correctAttempts,
    masteryLevel: masteryLevel,
    currentStreak: currentStreak,
    bestStreak: bestStreak,
    readinessScore: readinessScore,
    confidenceTrend: confidenceTrend,
    forgettingRisk: forgettingRisk,
    reviewUrgency: reviewUrgency,
    recentAccuracy: recentAccuracy,
    recentConfidence: recentConfidence,
    lastAttempt: DateTime(2025, 1, 1),
    lastUpdated: DateTime(2025, 1, 1),
  );
}

Widget _buildTestApp(
  Widget screen, {
  MasteryGraphService? masteryService,
}) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsController(SettingsRepository()),
      ),
      sessionRepositoryProvider.overrideWithValue(_FakeSessionRepo()),
      masteryGraphServiceProvider.overrideWithValue(
        masteryService ?? _FakeMasteryGraphService(),
      ),
      dashboardInstrumentationServiceProvider.overrideWithValue(
        _FakeInstrumentationService(),
      ),
      topicRepositoryProvider.overrideWithValue(_FakeTopicRepository()),
      engagementAdherenceRepoProvider.overrideWithValue(_FakeAdherenceRepo()),
      questionRepositoryProvider.overrideWithValue(_FakeQuestionRepo()),
      readinessScorerProvider.overrideWithValue(_FakeReadinessScorer()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: screen,
    ),
  );
}

Widget _buildTestAppWithRoutes(
  Widget screen, {
  MasteryGraphService? masteryService,
  TestNavigatorObserver? navigatorObserver,
  QuestionRepository? questionRepository,
}) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsController(SettingsRepository()),
      ),
      sessionRepositoryProvider.overrideWithValue(_FakeSessionRepo()),
      masteryGraphServiceProvider.overrideWithValue(
        masteryService ?? _FakeMasteryGraphService(),
      ),
      dashboardInstrumentationServiceProvider.overrideWithValue(
        _FakeInstrumentationService(),
      ),
      topicRepositoryProvider.overrideWithValue(_FakeTopicRepository()),
      engagementAdherenceRepoProvider.overrideWithValue(_FakeAdherenceRepo()),
      questionRepositoryProvider.overrideWithValue(
        questionRepository ?? _FakeQuestionRepo(),
      ),
      readinessScorerProvider.overrideWithValue(_FakeReadinessScorer()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      home: screen,
      routes: {
        AppRoutes.practiceSession: (_) => const Scaffold(
          body: Text('Practice Session'),
        ),
      },
    ),
  );
}

void main() {
  group('TopicDetailScreen', () {
    testWidgets('shows no data message when topic not found in mastery', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const TopicDetailScreen(topicId: 'unknown-topic', studentId: 'student-1'),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('No topic data yet'), findsOneWidget);
    });

    testWidgets('displays accuracy stat for known topic', (tester) async {
      final service = _FakeMasteryGraphService(allMastery: [
        _state(topicId: 'topic-1', accuracy: 0.75),
      ]);

      await tester.pumpWidget(_buildTestApp(
        const TopicDetailScreen(topicId: 'topic-1', studentId: 'student-1'),
        masteryService: service,
      ));
      await tester.pumpAndSettle();

      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('displays total attempts', (tester) async {
      final service = _FakeMasteryGraphService(allMastery: [
        _state(topicId: 'topic-1', totalAttempts: 12),
      ]);

      await tester.pumpWidget(_buildTestApp(
        const TopicDetailScreen(topicId: 'topic-1', studentId: 'student-1'),
        masteryService: service,
      ));
      await tester.pumpAndSettle();

      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('displays correct answers count', (tester) async {
      final service = _FakeMasteryGraphService(allMastery: [
        _state(topicId: 'topic-1', correctAttempts: 8),
      ]);

      await tester.pumpWidget(_buildTestApp(
        const TopicDetailScreen(topicId: 'topic-1', studentId: 'student-1'),
        masteryService: service,
      ));
      await tester.pumpAndSettle();

      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('displays mastery level label', (tester) async {
      final service = _FakeMasteryGraphService(allMastery: [
        _state(topicId: 'topic-1', masteryLevel: MasteryLevel.proficient),
      ]);

      await tester.pumpWidget(_buildTestApp(
        const TopicDetailScreen(topicId: 'topic-1', studentId: 'student-1'),
        masteryService: service,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Proficient'), findsOneWidget);
    });

    testWidgets('displays current streak', (tester) async {
      final service = _FakeMasteryGraphService(allMastery: [
        _state(topicId: 'topic-1', currentStreak: 4),
      ]);

      await tester.pumpWidget(_buildTestApp(
        const TopicDetailScreen(topicId: 'topic-1', studentId: 'student-1'),
        masteryService: service,
      ));
      await tester.pumpAndSettle();

      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('displays readiness score', (tester) async {
      final service = _FakeMasteryGraphService(allMastery: [
        _state(topicId: 'topic-1', readinessScore: 0.85),
      ]);

      await tester.pumpWidget(_buildTestApp(
        const TopicDetailScreen(topicId: 'topic-1', studentId: 'student-1'),
        masteryService: service,
      ));
      await tester.pumpAndSettle();

      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('renders accuracy trend chart when enough data', (tester) async {
      final service = _FakeMasteryGraphService(allMastery: [
        _state(
          topicId: 'topic-1',
          recentAccuracy: [0.5, 0.6, 0.7, 0.8],
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(
        const TopicDetailScreen(topicId: 'topic-1', studentId: 'student-1'),
        masteryService: service,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Accuracy Trend'), findsOneWidget);
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });



    testWidgets('hides trend chart when recentAccuracy has fewer than 2 entries', (tester) async {
      final service = _FakeMasteryGraphService(allMastery: [
        _state(topicId: 'topic-1', recentAccuracy: [0.5]),
      ]);

      await tester.pumpWidget(_buildTestApp(
        const TopicDetailScreen(topicId: 'topic-1', studentId: 'student-1'),
        masteryService: service,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Accuracy Trend'), findsNothing);
    });

    testWidgets('app bar practice icon navigates to practice session', (tester) async {
      final service = _FakeMasteryGraphService(allMastery: [
        _state(topicId: 'topic-1'),
      ]);
      final observer = TestNavigatorObserver();

      await tester.pumpWidget(_buildTestAppWithRoutes(
        const TopicDetailScreen(topicId: 'topic-1', studentId: 'student-1'),
        masteryService: service,
        navigatorObserver: observer,
        questionRepository: _FakeQuestionRepoWithQuestions(),
      ));
      await tester.pumpAndSettle();

      final iconButton = find.byType(IconButton);
      expect(iconButton, findsOneWidget);
      await tester.tap(iconButton);
      await tester.pumpAndSettle();

      expect(
        observer.pushedRoutes.last.settings.name,
        AppRoutes.practiceSession,
      );
    });

    testWidgets('practice button navigates to practice session', (tester) async {
      final service = _FakeMasteryGraphService(allMastery: [
        _state(topicId: 'topic-1'),
      ]);
      final observer = TestNavigatorObserver();

      await tester.pumpWidget(_buildTestAppWithRoutes(
        const TopicDetailScreen(topicId: 'topic-1', studentId: 'student-1'),
        masteryService: service,
        navigatorObserver: observer,
        questionRepository: _FakeQuestionRepoWithQuestions(),
      ));
      await tester.pumpAndSettle();

      final practiceButton = find.text('Practice this topic');
      expect(practiceButton, findsOneWidget);

      await tester.tap(practiceButton);
      await tester.pumpAndSettle();

      expect(
        observer.pushedRoutes.last.settings.name,
        AppRoutes.practiceSession,
      );
    });

    testWidgets('displays best streak', (tester) async {
      final service = _FakeMasteryGraphService(allMastery: [
        _state(topicId: 'topic-1', bestStreak: 10),
      ]);

      await tester.pumpWidget(_buildTestApp(
        const TopicDetailScreen(topicId: 'topic-1', studentId: 'student-1'),
        masteryService: service,
      ));
      await tester.pumpAndSettle();

      expect(find.text('10'), findsOneWidget);
      expect(find.text('Best Streak'), findsOneWidget);
    });

    testWidgets('displays confidence percentage', (tester) async {
      final service = _FakeMasteryGraphService(allMastery: [
        _state(topicId: 'topic-1', confidenceTrend: 0.78),
      ]);

      await tester.pumpWidget(_buildTestApp(
        const TopicDetailScreen(topicId: 'topic-1', studentId: 'student-1'),
        masteryService: service,
      ));
      await tester.pumpAndSettle();

      expect(find.text('78%'), findsOneWidget);
    });

    testWidgets('displays forgetting risk', (tester) async {
      final service = _FakeMasteryGraphService(allMastery: [
        _state(topicId: 'topic-1', forgettingRisk: 0.25),
      ]);

      await tester.pumpWidget(_buildTestApp(
        const TopicDetailScreen(topicId: 'topic-1', studentId: 'student-1'),
        masteryService: service,
      ));
      await tester.pumpAndSettle();

      expect(find.text('25%'), findsOneWidget);
    });

    testWidgets('displays review urgency with normal value', (tester) async {
      final service = _FakeMasteryGraphService(allMastery: [
        _state(topicId: 'topic-1', reviewUrgency: 0.4),
      ]);

      await tester.pumpWidget(_buildTestApp(
        const TopicDetailScreen(topicId: 'topic-1', studentId: 'student-1'),
        masteryService: service,
      ));
      await tester.pumpAndSettle();

      expect(find.text('40%'), findsOneWidget);
    });

    testWidgets('displays review urgency with high value', (tester) async {
      final service = _FakeMasteryGraphService(allMastery: [
        _state(topicId: 'topic-1', reviewUrgency: 0.85),
      ]);

      await tester.pumpWidget(_buildTestApp(
        const TopicDetailScreen(topicId: 'topic-1', studentId: 'student-1'),
        masteryService: service,
      ));
      await tester.pumpAndSettle();

      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('displays last attempted and last updated dates', (tester) async {
      final service = _FakeMasteryGraphService(allMastery: [
        _state(topicId: 'topic-1'),
      ]);

      await tester.pumpWidget(_buildTestApp(
        const TopicDetailScreen(topicId: 'topic-1', studentId: 'student-1'),
        masteryService: service,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Last Attempted'), findsOneWidget);
      expect(find.textContaining('Last Updated'), findsOneWidget);
    });

    testWidgets('practice button shows snackbar when no questions available', (tester) async {
      final service = _FakeMasteryGraphService(allMastery: [
        _state(topicId: 'topic-1'),
      ]);

      await tester.pumpWidget(_buildTestAppWithRoutes(
        const TopicDetailScreen(topicId: 'topic-1', studentId: 'student-1'),
        masteryService: service,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Practice this topic'));
      await tester.pumpAndSettle();

      expect(find.text('No Questions Available'), findsOneWidget);
    });

    testWidgets('shows error state when provider throws', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(
              (ref) => SettingsController(SettingsRepository()),
            ),
            sessionRepositoryProvider.overrideWithValue(_FakeSessionRepo()),
            dashboardInstrumentationServiceProvider.overrideWithValue(
              _FakeInstrumentationService(),
            ),
            topicRepositoryProvider.overrideWithValue(_FakeTopicRepository()),
            engagementAdherenceRepoProvider.overrideWithValue(_FakeAdherenceRepo()),
            questionRepositoryProvider.overrideWithValue(_FakeQuestionRepo()),
            readinessScorerProvider.overrideWithValue(_FakeReadinessScorer()),
            masteryGraphServiceProvider.overrideWithValue(
              _FakeMasteryGraphService(),
            ),
            dashboardInitProvider.overrideWith(
              (ref) => Future.value(),
            ),
            dashboardAllMasteryProvider('student-1').overrideWith(
              (ref) => Future<List<MasteryState>>.error(Exception('Kaboom')),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const TopicDetailScreen(topicId: 'topic-1', studentId: 'student-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Kaboom'), findsOneWidget);
    });

    testWidgets('shows loading indicator when providers are loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(
              (ref) => SettingsController(SettingsRepository()),
            ),
            sessionRepositoryProvider.overrideWithValue(_FakeSessionRepo()),
            dashboardInitProvider.overrideWith(
              (ref) => Completer<void>().future,
            ),
            dashboardInstrumentationServiceProvider.overrideWithValue(
              _FakeInstrumentationService(),
            ),
            topicRepositoryProvider.overrideWithValue(_FakeTopicRepository()),
            engagementAdherenceRepoProvider.overrideWithValue(_FakeAdherenceRepo()),
            questionRepositoryProvider.overrideWithValue(_FakeQuestionRepo()),
            readinessScorerProvider.overrideWithValue(_FakeReadinessScorer()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const TopicDetailScreen(topicId: 'topic-1', studentId: 'student-1'),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders all mastery level labels', (tester) async {
      for (final entry in [
        (level: MasteryLevel.novice, label: 'Novice'),
        (level: MasteryLevel.browsing, label: 'Browsing'),
        (level: MasteryLevel.developing, label: 'Developing'),
        (level: MasteryLevel.proficient, label: 'Proficient'),
        (level: MasteryLevel.expert, label: 'Expert'),
      ]) {
        final service = _FakeMasteryGraphService(allMastery: [
          _state(topicId: 'topic-1', masteryLevel: entry.level),
        ]);

        await tester.pumpWidget(_buildTestApp(
          const TopicDetailScreen(topicId: 'topic-1', studentId: 'student-1'),
          masteryService: service,
        ));
        await tester.pumpAndSettle();

        expect(find.text(entry.label), findsOneWidget,
            reason: 'Expected to find "${entry.label}" for level ${entry.level}');
      }
    });

    testWidgets('shows topic id as fallback in app bar when topic name not in provider',
        (tester) async {
      final service = _FakeMasteryGraphService(allMastery: [
        _state(topicId: 'my-topic-id'),
      ]);

      await tester.pumpWidget(_buildTestApp(
        const TopicDetailScreen(topicId: 'my-topic-id', studentId: 'student-1'),
        masteryService: service,
      ));
      await tester.pumpAndSettle();

      expect(find.text('my-topic-id'), findsOneWidget);
    });

    testWidgets('handles null mastery state gracefully in body', (tester) async {
      final service = _FakeMasteryGraphService(allMastery: [
        _state(topicId: 'other-topic'),
      ]);

      await tester.pumpWidget(_buildTestApp(
        const TopicDetailScreen(topicId: 'topic-1', studentId: 'student-1'),
        masteryService: service,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('No topic data yet'), findsOneWidget);
    });
  });

  group('TopicDetailArgs', () {
    test('constructs with topicId and studentId', () {
      const args = TopicDetailArgs(topicId: 't1', studentId: 's1');
      expect(args.topicId, 't1');
      expect(args.studentId, 's1');
    });
  });
}
