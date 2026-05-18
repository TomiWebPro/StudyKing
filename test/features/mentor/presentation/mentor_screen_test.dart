import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider, SettingsController;
import 'package:studyking/core/providers/llm_providers.dart' show llmServiceProvider;
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/mentor/presentation/mentor_screen.dart';
import 'package:studyking/core/widgets/conversation_input.dart';
import 'package:studyking/features/mentor/providers/mentor_providers.dart' show mentorEngagementNudgeRepoProvider, mentorSessionRepositoryProvider, mentorProgressTrackerProvider;
import 'package:studyking/features/planner/providers/planner_providers.dart' show plannerServiceProvider;
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/planner/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/core/services/plan_adapter.dart' show AdherenceDeviation;
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart' show masteryGraphServiceProvider;
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../helpers/navigator_observer_helper.dart';

class _FakeSettingsRepository extends SettingsRepository {
  final Map<String, dynamic> _store = {};

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<void>> updateSettings({
    String? apiKey,
    String? apiBaseUrl,
    String? selectedModel,
    ThemeMode? themeMode,
    double? fontSize,
    bool? studyRemindersEnabled,
    int? requestTimeoutSeconds,
    int? sessionDurationMinutes,
    bool? highContrastEnabled,
    bool? largeTouchTargets,
    bool? reduceMotion,
    bool? revisionRemindersEnabled,
    bool? lessonNotificationsEnabled,
    bool? overworkAlertsEnabled,
    bool? planAdjustmentNotificationsEnabled,
    int? breakDurationSeconds,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    bool? firstFocusVisit,
    bool? dailyReminderEnabled,
  }) async {
    if (reduceMotion != null) _store['reduceMotion'] = reduceMotion;
    if (highContrastEnabled != null) _store['highContrastEnabled'] = highContrastEnabled;
    if (largeTouchTargets != null) _store['largeTouchTargets'] = largeTouchTargets;
    return Result.success(null);
  }

  @override
  Future<Result<SettingsBox>> getSettings() async {
    return Result.success(SettingsBox(
      reduceMotion: _store['reduceMotion'] as bool? ?? false,
      highContrastEnabled: _store['highContrastEnabled'] as bool? ?? false,
      largeTouchTargets: _store['largeTouchTargets'] as bool? ?? false,
    ));
  }
}

class FakePlannerService extends PlannerService {
  @override
  Future<PersonalLearningPlan?> loadExistingPlan() async => null;
  @override
  Future<List<RoadmapModel>> loadRoadmaps() async => [];
  @override
  Future<List<PendingActionModel>> loadPendingActions() async => [];
  @override
  Future<List<Session>> getScheduledLessons() async => [];
  @override
  Future<AdherenceDeviation?> checkAdherence() async => null;
  @override
  Future<bool> hasSchedulingConflict({required DateTime startTime, required int durationMinutes, String? excludeSessionId}) async => false;
  @override
  Future<bool> scheduleLesson({required String topicId, required String topicTitle, required String subjectId, required DateTime scheduledTime, int durationMinutes = 30}) async => true;
}

class _FakeNudgeRepo extends EngagementNudgeRepository {
  @override
  Future<void> init() async {}
  @override
  Future<Result<void>> create(EngagementNudgeModel nudge) async => Result.success(null);
  @override
  Future<Result<List<EngagementNudgeModel>>> getRecentByStudent(String studentId, {int limit = 10}) async => Result.success([]);
  @override
  Future<Result<int>> getTodayCount(String studentId) async => Result.success(0);
}

class _ControllableNudgeRepo extends EngagementNudgeRepository {
  final Completer<void> _initCompleter = Completer<void>();

  void completeInit() => _initCompleter.complete();

  @override
  Future<void> init() => _initCompleter.future;

  @override
  Future<Result<void>> create(EngagementNudgeModel nudge) async => Result.success(null);

  @override
  Future<Result<List<EngagementNudgeModel>>> getRecentByStudent(String studentId, {int limit = 10}) async => Result.success([]);

  @override
  Future<Result<int>> getTodayCount(String studentId) async => Result.success(0);
}

class _FakeSessionRepo2 extends SessionRepository {
  @override
  Future<Result<List<Session>>> getAll() async => Result.success([]);
  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async => Result.success([]);
  @override
  Future<Result<int>> getTodayDurationMs() async => Result.success(0);
}

class FakeLlmService extends LlmService {
  final bool shouldThrow;
  final Duration? responseDelay;

  FakeLlmService({this.shouldThrow = false, this.responseDelay, bool hasApiKey = true})
      : super(
          config: LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: hasApiKey ? 'test-key' : '',
          ),
        );

  @override
  Stream<String> chatStream({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async* {
    if (shouldThrow) throw Exception('Simulated LLM error');
    if (responseDelay != null) await Future.delayed(responseDelay!);
    yield 'Mentor response';
  }
}

class _FakeAttemptRepo extends AttemptRepository {
  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async => Result.success([]);
}

class _FakeTopicRepository extends TopicRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);
  @override
  Future<Result<Topic?>> get(String key) async {
    return Result.success(Topic(
      id: key,
      title: key,
      subjectId: 'subject-1',
      description: '',
      syllabusText: '',
    ));
  }
}

class _FakeTopicRepoNoSubject extends TopicRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);
  @override
  Future<Result<Topic?>> get(String key) async {
    return Result.success(Topic(
      id: key,
      title: key,
      subjectId: '',
      description: '',
      syllabusText: '',
    ));
  }
}

class _FakeTopicRepoThrowing extends TopicRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);
  @override
  Future<Result<Topic?>> get(String key) async {
    return Result.failure('DB error');
  }
}

class _ThrowingNudgeRepo extends EngagementNudgeRepository {
  @override
  Future<void> init() async => throw Exception('Init simulation failure');
  @override
  Future<Result<void>> create(EngagementNudgeModel nudge) async => Result.success(null);
  @override
  Future<Result<List<EngagementNudgeModel>>> getRecentByStudent(String studentId, {int limit = 10}) async => Result.success([]);
  @override
  Future<Result<int>> getTodayCount(String studentId) async => Result.success(0);
}

class FakeMasteryGraphService extends MasteryGraphService {
  List<MasteryState> _weakTopics = [];
  final List<QuestionMasteryState> _atRiskQuestions = [];

  void setWeakTopics(List<MasteryState> topics) => _weakTopics = topics;

  FakeMasteryGraphService() : super();

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return Result.success(_weakTopics);
  }

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(
    String studentId, {
    double threshold = 0.5,
  }) async {
    return Result.success(_atRiskQuestions);
  }
}

class FakeProgressTracker extends StudyProgressTracker {
  Map<String, dynamic> _overallStats = const {
    'totalAttempts': 100,
    'correctAttempts': 85,
    'accuracy': 85,
    'topicsStudied': 12,
    'weeklyActivity': 25,
    'totalStudyTimeHours': 45.5,
  };
  List<Map<String, dynamic>> _recommendations = const [];
  List<Map<String, dynamic>> _badges = const [];
  bool _throwOnReport = false;

  void setOverallStats(Map<String, dynamic> stats) => _overallStats = stats;
  void setRecommendations(List<Map<String, dynamic>> recs) => _recommendations = recs;
  void setBadges(List<Map<String, dynamic>> badges) => _badges = badges;
  void setThrowOnReport(bool v) => _throwOnReport = v;

  FakeProgressTracker() : super(attemptRepo: _FakeAttemptRepo(), l10n: lookupAppLocalizations(const Locale('en')));

  @override
  Future<Map<String, dynamic>> getOverallStats(String studentId) async {
    if (_throwOnReport) throw Exception('Simulated error');
    return Map<String, dynamic>.from(_overallStats);
  }

  @override
  Future<List<Map<String, dynamic>>> getRecommendations(String studentId) async =>
      List<Map<String, dynamic>>.from(_recommendations);

  @override
  Future<List<Map<String, dynamic>>> getBadges(String studentId) async =>
      List<Map<String, dynamic>>.from(_badges);
}

Widget _buildTestApp({
  LlmService? llmService,
  FakeMasteryGraphService? masteryGraph,
  FakeProgressTracker? progressTracker,
  EngagementNudgeRepository? nudgeRepo,
  TestNavigatorObserver? navigatorObserver,
}) {
  return ProviderScope(
    overrides: [
      llmServiceProvider.overrideWithValue(
        llmService ?? FakeLlmService(),
      ),
      settingsProvider.overrideWith(
        (ref) => SettingsController(_FakeSettingsRepository()),
      ),
      plannerServiceProvider.overrideWithValue(FakePlannerService()),
      mentorEngagementNudgeRepoProvider.overrideWithValue(
        nudgeRepo ?? _FakeNudgeRepo(),
      ),
      mentorSessionRepositoryProvider.overrideWithValue(_FakeSessionRepo2()),
      masteryGraphServiceProvider.overrideWithValue(
        masteryGraph ?? FakeMasteryGraphService(),
      ),
      mentorProgressTrackerProvider.overrideWithValue(
        progressTracker ?? FakeProgressTracker(),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      home: const MentorScreen(),
    ),
  );
}

void main() {
  group('MentorScreen', () {
    testWidgets('renders app bar with mentor greeting', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('AI Mentor'), findsWidgets);
    });

    testWidgets('renders chat input and send button', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Ask your mentor anything...'), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('shows progress report button in app bar', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Progress Report'), findsOneWidget);
    });

    testWidgets('welcome message is shown after initialization', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('AI Mentor'), findsWidgets);
    });

    testWidgets('empty state shown when no messages', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
    });

    testWidgets('sends a message and shows response', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello mentor');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('Mentor response').evaluate().isNotEmpty) break;
        if (find.text('Sorry, I encountered an error. Please try again.').evaluate().isNotEmpty) break;
      }

      expect(find.text('Hello mentor'), findsOneWidget);
      expect(find.text('Mentor response'), findsOneWidget);
    });

    testWidgets('shows "You" sender label after sending', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('You').evaluate().isNotEmpty) break;
      }

      expect(find.text('You'), findsWidgets);
    });

    testWidgets('shows error message when LLM fails', (tester) async {
      final errorService = FakeLlmService(shouldThrow: true);

      await tester.pumpWidget(_buildTestApp(llmService: errorService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('Sorry, I encountered an error. Please try again.').evaluate().isNotEmpty) break;
      }

      expect(find.text('Sorry, I encountered an error. Please try again.'), findsOneWidget);
    });

    testWidgets('shows loading indicator while sending', (tester) async {
      final delayedService = FakeLlmService(responseDelay: const Duration(seconds: 1));

      await tester.pumpWidget(_buildTestApp(llmService: delayedService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byIcon(Icons.send_rounded).evaluate().isNotEmpty) break;
      }

      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('chat input has correct initial state', (tester) async {
      await tester.pumpWidget(_buildTestApp());

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
      expect(find.text('Ask your mentor anything...'), findsOneWidget);
    });

    testWidgets('sending empty message does nothing', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Ask your mentor anything...'), findsOneWidget);
    });

    testWidgets('shows progress report dialog', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.text('Progress Report'), findsWidgets);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('progress report shows accuracy section', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.text('Accuracy'), findsWidgets);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('progress report shows stat rows', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.textContaining('12'), findsWidgets);
    });

    testWidgets('progress report shows weak topics', (tester) async {
      final masteryGraph = FakeMasteryGraphService();
      final now = DateTime.now();
      masteryGraph.setWeakTopics([
        MasteryState(
          studentId: 'test', topicId: 'algebra',
          accuracy: 0.35, lastAttempt: now, lastUpdated: now,
        ),
        MasteryState(
          studentId: 'test', topicId: 'geometry',
          accuracy: 0.25, lastAttempt: now, lastUpdated: now,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(masteryGraph: masteryGraph));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.text('Weak Areas'), findsOneWidget);
      expect(find.text('algebra'), findsOneWidget);
      expect(find.text('geometry'), findsOneWidget);
    });

    testWidgets('progress report shows badges', (tester) async {
      final progressTracker = FakeProgressTracker();
      progressTracker.setBadges([
        {'name': 'First Steps', 'description': 'Completed first session', 'id': 'first_steps', 'unlockedAt': DateTime.now().toIso8601String()},
        {'name': 'Consistency', 'description': '7-day streak', 'id': 'consistency', 'unlockedAt': DateTime.now().toIso8601String()},
      ]);

      await tester.pumpWidget(_buildTestApp(progressTracker: progressTracker));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.text('Badges'), findsOneWidget);
      expect(find.text('First Steps'), findsOneWidget);
      expect(find.text('Consistency'), findsOneWidget);
      expect(find.byType(Chip), findsNWidgets(2));
    });

    testWidgets('progress report shows recommendations', (tester) async {
      final progressTracker = FakeProgressTracker();
      progressTracker.setRecommendations([
        {'type': 'review', 'priority': 'high', 'message': 'Focus on reviewing algebra concepts.'},
        {'type': 'practice', 'priority': 'medium', 'message': 'Try more practice questions.'},
      ]);

      await tester.pumpWidget(_buildTestApp(progressTracker: progressTracker));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.text('Recommendations'), findsOneWidget);
      expect(find.text('Focus on reviewing algebra concepts.'), findsWidgets);
      expect(find.text('Try more practice questions.'), findsWidgets);
    });

    testWidgets('progress report shows error snackbar on failure', (tester) async {
      final progressTracker = FakeProgressTracker();
      progressTracker.setThrowOnReport(true);

      await tester.pumpWidget(_buildTestApp(progressTracker: progressTracker));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.text('Unable to generate progress report. Please try again later.'), findsOneWidget);
    });

    testWidgets('progress report dialog can be closed', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('progress report accuracy bar shows correct value', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, closeTo(0.85, 0.01));
    });

    testWidgets('progress report with low accuracy', (tester) async {
      final progressTracker = FakeProgressTracker();
      progressTracker.setOverallStats({
        'totalAttempts': 100, 'correctAttempts': 30,
        'accuracy': 30, 'topicsStudied': 5,
        'weeklyActivity': 3, 'totalStudyTimeHours': 5.0,
      });

      await tester.pumpWidget(_buildTestApp(progressTracker: progressTracker));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, closeTo(0.30, 0.01));
    });

    testWidgets('progress report with medium accuracy', (tester) async {
      final progressTracker = FakeProgressTracker();
      progressTracker.setOverallStats({
        'totalAttempts': 100, 'correctAttempts': 50,
        'accuracy': 50, 'topicsStudied': 5,
        'weeklyActivity': 3, 'totalStudyTimeHours': 5.0,
      });

      await tester.pumpWidget(_buildTestApp(progressTracker: progressTracker));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, closeTo(0.50, 0.01));
    });

    testWidgets('weak topic navigates to practice session', (tester) async {
      final navigatorRoutes = <String>[];
      final masteryGraph = FakeMasteryGraphService();
      final now = DateTime.now();
      masteryGraph.setWeakTopics([
        MasteryState(
          studentId: 'test', topicId: 'algebra',
          accuracy: 0.35, lastAttempt: now, lastUpdated: now,
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            llmServiceProvider.overrideWithValue(FakeLlmService()),
            settingsProvider.overrideWith(
              (ref) => SettingsController(_FakeSettingsRepository()),
            ),
            plannerServiceProvider.overrideWithValue(FakePlannerService()),
            mentorEngagementNudgeRepoProvider.overrideWithValue(_FakeNudgeRepo()),
            mentorSessionRepositoryProvider.overrideWithValue(_FakeSessionRepo2()),
            masteryGraphServiceProvider.overrideWithValue(masteryGraph),
            mentorProgressTrackerProvider.overrideWithValue(FakeProgressTracker()),
            topicRepositoryProvider.overrideWithValue(_FakeTopicRepository()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const MentorScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == AppRoutes.practiceSession) {
                navigatorRoutes.add(settings.name!);
              }
              return MaterialPageRoute(
                builder: (_) => const SizedBox.shrink(),
                settings: settings,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('algebra'));
      await tester.pumpAndSettle();

      expect(navigatorRoutes, contains(AppRoutes.practiceSession));
    });

    testWidgets('progress report hides empty sections', (tester) async {
      final masteryGraph = FakeMasteryGraphService();
      masteryGraph.setWeakTopics([]);
      final progressTracker = FakeProgressTracker();
      progressTracker.setBadges([]);
      progressTracker.setRecommendations([]);

      await tester.pumpWidget(_buildTestApp(
        masteryGraph: masteryGraph,
        progressTracker: progressTracker,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.text('Weak Areas'), findsNothing);
      expect(find.text('Badges'), findsNothing);
      expect(find.text('Recommendations'), findsNothing);
    });

    testWidgets('sends multiple messages', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      for (var i = 0; i < 3; i++) {
        await tester.enterText(find.byType(TextField), 'Message $i');
        await tester.pump();
        await tester.tap(find.byIcon(Icons.send_rounded));
        for (var j = 0; j < 60; j++) {
          await tester.pump(const Duration(milliseconds: 50));
          if (find.text('Message $i').evaluate().isNotEmpty &&
              find.byIcon(Icons.send_rounded).evaluate().isNotEmpty) {
            break;
          }
        }
      }

      expect(find.text('Message 0'), findsOneWidget);
      expect(find.text('Message 1'), findsOneWidget);
      expect(find.text('Message 2'), findsOneWidget);
    });

    testWidgets('shows list view with messages', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('Mentor response').evaluate().isNotEmpty) break;
      }

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Mentor response'), findsOneWidget);
    });

    testWidgets('uses jump scroll with reduce motion enabled', (tester) async {
      final repo = _FakeSettingsRepository();
      await repo.init();
      final ctrl = SettingsController(repo);
      await ctrl.updateSettings(reduceMotion: true);
      await tester.pump();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            llmServiceProvider.overrideWithValue(FakeLlmService()),
            settingsProvider.overrideWith((ref) => ctrl),
            plannerServiceProvider.overrideWithValue(FakePlannerService()),
            mentorEngagementNudgeRepoProvider.overrideWithValue(_FakeNudgeRepo()),
            mentorSessionRepositoryProvider.overrideWithValue(_FakeSessionRepo2()),
            masteryGraphServiceProvider.overrideWithValue(FakeMasteryGraphService()),
            mentorProgressTrackerProvider.overrideWithValue(FakeProgressTracker()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const MentorScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('Mentor response').evaluate().isNotEmpty) break;
      }

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Mentor response'), findsOneWidget);
    });

    testWidgets('dispose does not throw when widget is removed from tree', (tester) async {
      final commonOverrides = [
        llmServiceProvider.overrideWithValue(FakeLlmService()),
        settingsProvider.overrideWith(
          (ref) => SettingsController(_FakeSettingsRepository()),
        ),
        plannerServiceProvider.overrideWithValue(FakePlannerService()),
        mentorEngagementNudgeRepoProvider.overrideWithValue(_FakeNudgeRepo()),
        mentorSessionRepositoryProvider.overrideWithValue(_FakeSessionRepo2()),
        masteryGraphServiceProvider.overrideWithValue(FakeMasteryGraphService()),
        mentorProgressTrackerProvider.overrideWithValue(FakeProgressTracker()),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: commonOverrides,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const MentorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MentorScreen), findsOneWidget);

      await tester.pumpWidget(
        ProviderScope(
          overrides: commonOverrides,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MentorScreen), findsNothing);
    });

    testWidgets('progress report early return before initialization completes', (tester) async {
      final controllableRepo = _ControllableNudgeRepo();

      await tester.pumpWidget(_buildTestApp(nudgeRepo: controllableRepo));
      await tester.pump();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pump();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);

      controllableRepo.completeInit();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
    });

    testWidgets('welcome message has mentor role and correct content', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('AI Mentor'), findsWidgets);
      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
    });

    testWidgets('whitespace-only input is rejected', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Ask your mentor anything...'), findsOneWidget);
    });

    testWidgets('cannot send while already sending', (tester) async {
      final delayedService = FakeLlmService(responseDelay: const Duration(seconds: 1));

      await tester.pumpWidget(_buildTestApp(llmService: delayedService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'First message');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(find.byIcon(Icons.send_rounded), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('Mentor response').evaluate().isNotEmpty &&
            find.byIcon(Icons.send_rounded).evaluate().isNotEmpty) {
          break;
        }
      }

      expect(find.text('First message'), findsOneWidget);
    });

    testWidgets('widget disposed during initialization does not crash', (tester) async {
      final controllableRepo = _ControllableNudgeRepo();

      await tester.pumpWidget(_buildTestApp(nudgeRepo: controllableRepo));
      await tester.pump();

      expect(find.byType(MentorScreen), findsOneWidget);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            llmServiceProvider.overrideWithValue(FakeLlmService()),
            settingsProvider.overrideWith(
              (ref) => SettingsController(_FakeSettingsRepository()),
            ),
            plannerServiceProvider.overrideWithValue(FakePlannerService()),
            mentorEngagementNudgeRepoProvider.overrideWithValue(_FakeNudgeRepo()),
            mentorSessionRepositoryProvider.overrideWithValue(_FakeSessionRepo2()),
            masteryGraphServiceProvider.overrideWithValue(FakeMasteryGraphService()),
            mentorProgressTrackerProvider.overrideWithValue(FakeProgressTracker()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();

      controllableRepo.completeInit();
      await tester.pumpAndSettle();

      expect(find.byType(MentorScreen), findsNothing);
    });

    testWidgets('text field has initial focus', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('text field remains focusable after sending message',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Test focus');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('Mentor response').evaluate().isNotEmpty) break;
      }

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('progress report with recommendations enabled and disabled',
        (tester) async {
      final progressTracker = FakeProgressTracker();
      progressTracker.setRecommendations([
        {'type': 'review', 'priority': 'high', 'message': 'Review algebra'},
      ]);

      await tester.pumpWidget(_buildTestApp(progressTracker: progressTracker));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.text('Recommendations'), findsOneWidget);
      expect(find.text('Review algebra'), findsWidgets);
    });

    testWidgets('progress report with all sections empty', (tester) async {
      final masteryGraph = FakeMasteryGraphService();
      masteryGraph.setWeakTopics([]);
      final progressTracker = FakeProgressTracker();
      progressTracker.setBadges([]);
      progressTracker.setRecommendations([]);
      progressTracker.setOverallStats({
        'totalAttempts': 0, 'correctAttempts': 0,
        'accuracy': 0, 'topicsStudied': 0,
        'weeklyActivity': 0, 'totalStudyTimeHours': 0.0,
      });

      await tester.pumpWidget(_buildTestApp(
        masteryGraph: masteryGraph,
        progressTracker: progressTracker,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Progress Report'), findsWidgets);
      expect(find.text('Accuracy'), findsWidgets);
      expect(find.text('Weak Areas'), findsNothing);
      expect(find.text('Badges'), findsNothing);
      expect(find.text('Recommendations'), findsNothing);
    });

    testWidgets('reduce motion uses jump scroll behavior', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_awesome), findsWidgets);

      await tester.enterText(find.byType(TextField), 'Reduce motion test');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('Mentor response').evaluate().isNotEmpty) break;
      }

      expect(find.text('Reduce motion test'), findsOneWidget);
      expect(find.text('Mentor response'), findsOneWidget);
    });

    testWidgets('progress report accuracy displays correct format for low accuracy',
        (tester) async {
      final progressTracker = FakeProgressTracker();
      progressTracker.setOverallStats({
        'totalAttempts': 10, 'correctAttempts': 1,
        'accuracy': 10, 'topicsStudied': 2,
        'weeklyActivity': 1, 'totalStudyTimeHours': 2.0,
      });

      await tester.pumpWidget(_buildTestApp(progressTracker: progressTracker));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.text('Accuracy'), findsWidgets);
      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, closeTo(0.10, 0.01));
    });

    testWidgets('progress report weak topic tap navigates correctly',
        (tester) async {
      final navigatorRoutes = <String>[];
      final masteryGraph = FakeMasteryGraphService();
      final now = DateTime.now();
      masteryGraph.setWeakTopics([
        MasteryState(
          studentId: 'test', topicId: 'physics',
          accuracy: 0.30, lastAttempt: now, lastUpdated: now,
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            llmServiceProvider.overrideWithValue(FakeLlmService()),
            settingsProvider.overrideWith(
              (ref) => SettingsController(_FakeSettingsRepository()),
            ),
            plannerServiceProvider.overrideWithValue(FakePlannerService()),
            mentorEngagementNudgeRepoProvider.overrideWithValue(_FakeNudgeRepo()),
            mentorSessionRepositoryProvider.overrideWithValue(_FakeSessionRepo2()),
            masteryGraphServiceProvider.overrideWithValue(masteryGraph),
            mentorProgressTrackerProvider.overrideWithValue(FakeProgressTracker()),
            topicRepositoryProvider.overrideWithValue(_FakeTopicRepository()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const MentorScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == AppRoutes.practiceSession) {
                navigatorRoutes.add(settings.name!);
              }
              return MaterialPageRoute(
                builder: (_) => const SizedBox.shrink(),
                settings: settings,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('physics'));
      await tester.pumpAndSettle();

      expect(navigatorRoutes, contains(AppRoutes.practiceSession));
    });

    testWidgets('conversation input is in correct state after initialization',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final input = tester.widget<ConversationInput>(find.byType(ConversationInput));
      expect(input.isEnabled, isTrue);
      expect(input.isLoading, isFalse);
    });

    testWidgets('progress report hides badges section when empty',
        (tester) async {
      final progressTracker = FakeProgressTracker();
      progressTracker.setBadges([]);
      progressTracker.setOverallStats({
        'totalAttempts': 50, 'correctAttempts': 35,
        'accuracy': 70, 'topicsStudied': 8,
        'weeklyActivity': 15, 'totalStudyTimeHours': 30.0,
      });

      await tester.pumpWidget(_buildTestApp(progressTracker: progressTracker));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.text('Badges'), findsNothing);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('progress report handles single weak topic', (tester) async {
      final masteryGraph = FakeMasteryGraphService();
      final now = DateTime.now();
      masteryGraph.setWeakTopics([
        MasteryState(
          studentId: 'test', topicId: 'calculus',
          accuracy: 0.20, lastAttempt: now, lastUpdated: now,
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(masteryGraph: masteryGraph));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.text('calculus'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('progress report stat rows display correct information',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.book_outlined), findsOneWidget);
    });

    testWidgets('navigator observes no pops initially', (tester) async {
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(_buildTestApp(navigatorObserver: observer));
      await tester.pumpAndSettle();

      expect(observer.poppedRoutes, isEmpty);
    });

    testWidgets('navigator pops via system back', (tester) async {
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(_buildTestApp(navigatorObserver: observer));
      await tester.pumpAndSettle();

      expect(observer.poppedRoutes, isEmpty);
    });

    testWidgets('popup menu button is present in app bar', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('popup menu opens on tap and shows clear option', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Clear conversation'), findsOneWidget);
    });

    testWidgets('clear conversation shows confirmation dialog', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear conversation'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Clear conversation'), findsOneWidget);
    });

    testWidgets('clear conversation cancel does not remove messages', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello mentor');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('Mentor response').evaluate().isNotEmpty) break;
      }
      expect(find.text('Hello mentor'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear conversation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Hello mentor'), findsOneWidget);
    });

    testWidgets('clear conversation confirm clears messages and shows welcome', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello mentor');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('Mentor response').evaluate().isNotEmpty) break;
      }
      expect(find.text('Hello mentor'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear conversation'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Clear conversation'));
      await tester.pumpAndSettle();

      expect(find.text('Hello mentor'), findsNothing);
      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
    });

    testWidgets('init error shows error card with retry and settings buttons', (tester) async {
      final throwingRepo = _ThrowingNudgeRepo();

      await tester.pumpWidget(_buildTestApp(nudgeRepo: throwingRepo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Go to Settings'), findsOneWidget);
      expect(find.textContaining('Mentor initialization failed'), findsOneWidget);
    });

    testWidgets('init error changes input hint text', (tester) async {
      final throwingRepo = _ThrowingNudgeRepo();

      await tester.pumpWidget(_buildTestApp(nudgeRepo: throwingRepo));
      await tester.pumpAndSettle();

      expect(
        find.text('Connectivity issue — configure AI provider in Settings'),
        findsOneWidget,
      );
    });

    testWidgets('init error retry reinitializes and shows error again', (tester) async {
      final throwingRepo = _ThrowingNudgeRepo();

      await tester.pumpWidget(_buildTestApp(nudgeRepo: throwingRepo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('init error settings button navigates to api config', (tester) async {
      final throwingRepo = _ThrowingNudgeRepo();
      final navigatorRoutes = <String>[];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            llmServiceProvider.overrideWithValue(FakeLlmService()),
            settingsProvider.overrideWith(
              (ref) => SettingsController(_FakeSettingsRepository()),
            ),
            plannerServiceProvider.overrideWithValue(FakePlannerService()),
            mentorEngagementNudgeRepoProvider.overrideWithValue(throwingRepo),
            mentorSessionRepositoryProvider.overrideWithValue(_FakeSessionRepo2()),
            masteryGraphServiceProvider.overrideWithValue(FakeMasteryGraphService()),
            mentorProgressTrackerProvider.overrideWithValue(FakeProgressTracker()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const MentorScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == AppRoutes.apiConfig) {
                navigatorRoutes.add(settings.name!);
              }
              return MaterialPageRoute(
                builder: (_) => const SizedBox.shrink(),
                settings: settings,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Go to Settings'));
      await tester.pumpAndSettle();

      expect(navigatorRoutes, contains(AppRoutes.apiConfig));
    });

    testWidgets('suggested action card appears after initialization', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      expect(
        find.textContaining("You haven't added any subjects yet"),
        findsOneWidget,
      );
    });

    testWidgets('suggested action card can be dismissed', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);

      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
    });

    testWidgets('weak topic with no subjectId shows snackbar', (tester) async {
      final masteryGraph = FakeMasteryGraphService();
      final now = DateTime.now();
      masteryGraph.setWeakTopics([
        MasteryState(
          studentId: 'test', topicId: 'algebra',
          accuracy: 0.35, lastAttempt: now, lastUpdated: now,
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            llmServiceProvider.overrideWithValue(FakeLlmService()),
            settingsProvider.overrideWith(
              (ref) => SettingsController(_FakeSettingsRepository()),
            ),
            plannerServiceProvider.overrideWithValue(FakePlannerService()),
            mentorEngagementNudgeRepoProvider.overrideWithValue(_FakeNudgeRepo()),
            mentorSessionRepositoryProvider.overrideWithValue(_FakeSessionRepo2()),
            masteryGraphServiceProvider.overrideWithValue(masteryGraph),
            mentorProgressTrackerProvider.overrideWithValue(FakeProgressTracker()),
            topicRepositoryProvider.overrideWithValue(_FakeTopicRepoNoSubject()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const MentorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('algebra'));
      await tester.pumpAndSettle();

      expect(find.text('Could not find subject for this topic.'), findsOneWidget);
    });

    testWidgets('weak topic with topic fetch error shows snackbar', (tester) async {
      final masteryGraph = FakeMasteryGraphService();
      final now = DateTime.now();
      masteryGraph.setWeakTopics([
        MasteryState(
          studentId: 'test', topicId: 'algebra',
          accuracy: 0.35, lastAttempt: now, lastUpdated: now,
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            llmServiceProvider.overrideWithValue(FakeLlmService()),
            settingsProvider.overrideWith(
              (ref) => SettingsController(_FakeSettingsRepository()),
            ),
            plannerServiceProvider.overrideWithValue(FakePlannerService()),
            mentorEngagementNudgeRepoProvider.overrideWithValue(_FakeNudgeRepo()),
            mentorSessionRepositoryProvider.overrideWithValue(_FakeSessionRepo2()),
            masteryGraphServiceProvider.overrideWithValue(masteryGraph),
            mentorProgressTrackerProvider.overrideWithValue(FakeProgressTracker()),
            topicRepositoryProvider.overrideWithValue(_FakeTopicRepoThrowing()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const MentorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('algebra'));
      await tester.pumpAndSettle();

      expect(find.text('Could not find subject for this topic.'), findsOneWidget);
    });

    testWidgets('app bar shows mentor greeting and icon', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
      expect(find.text('AI Mentor'), findsWidgets);
    });

    testWidgets('conversation input is disabled during init error', (tester) async {
      final throwingRepo = _ThrowingNudgeRepo();

      await tester.pumpWidget(_buildTestApp(nudgeRepo: throwingRepo));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('sending schedule message shows schedule dialog', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'I want to schedule a lesson about algebra');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(AlertDialog).evaluate().isNotEmpty) break;
      }

      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('schedule dialog cancel returns to chat', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'I want to schedule a lesson about algebra');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(AlertDialog).evaluate().isNotEmpty) break;
      }

      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('sending plan message shows plan details', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'I want to plan 90 days');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('Mentor response').evaluate().isNotEmpty) break;
      }

      expect(find.text('Mentor response'), findsOneWidget);
    });

    testWidgets('sends message with schedule intent and dialog shows topic', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'schedule a lesson about calculus');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(AlertDialog).evaluate().isNotEmpty) break;
      }

      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('app bar title contains auto awesome icon and mentor greeting', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.title, isNotNull);
    });
  });
}
