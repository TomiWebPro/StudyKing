import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider, SettingsController;
import 'package:studyking/core/providers/llm_providers.dart' show llmServiceProvider;
import 'package:studyking/features/practice/providers/practice_providers.dart' show masteryGraphServiceProvider;
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart' show plannerServiceProvider;
import 'package:studyking/features/mentor/providers/mentor_providers.dart' show mentorEngagementNudgeRepoProvider, mentorSessionRepositoryProvider, mentorProgressTrackerProvider;
import 'package:studyking/features/mentor/presentation/mentor_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'mentor_screen_test_helpers.dart';

void main() {
  group('MentorScreen - Progress Report', () {
    testWidgets('shows progress report dialog', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.text('Progress Report'), findsWidgets);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('progress report shows accuracy section', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.text('Accuracy'), findsWidgets);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('progress report shows stat rows', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
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

      await tester.pumpWidget(buildMentorTestApp(masteryGraph: masteryGraph));
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

      await tester.pumpWidget(buildMentorTestApp(progressTracker: progressTracker));
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

      await tester.pumpWidget(buildMentorTestApp(progressTracker: progressTracker));
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

      await tester.pumpWidget(buildMentorTestApp(progressTracker: progressTracker));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.text('Unable to generate progress report. Please try again later.'), findsOneWidget);
    });

    testWidgets('progress report dialog can be closed', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('progress report accuracy bar shows correct value', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
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

      await tester.pumpWidget(buildMentorTestApp(progressTracker: progressTracker));
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

      await tester.pumpWidget(buildMentorTestApp(progressTracker: progressTracker));
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
              (ref) => SettingsController(FakeSettingsRepo()),
            ),
            plannerServiceProvider.overrideWithValue(FakePlannerService()),
            mentorEngagementNudgeRepoProvider.overrideWithValue(FakeNudgeRepo()),
            mentorSessionRepositoryProvider.overrideWithValue(FakeSessionRepo()),
            masteryGraphServiceProvider.overrideWithValue(masteryGraph),
            mentorProgressTrackerProvider.overrideWithValue(FakeProgressTracker()),
            topicRepositoryProvider.overrideWithValue(FakeTopicRepo()),
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

      await tester.pumpWidget(buildMentorTestApp(
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

    testWidgets('progress report accuracy displays correct format for low accuracy', (tester) async {
      final progressTracker = FakeProgressTracker();
      progressTracker.setOverallStats({
        'totalAttempts': 10, 'correctAttempts': 1,
        'accuracy': 10, 'topicsStudied': 2,
        'weeklyActivity': 1, 'totalStudyTimeHours': 2.0,
      });

      await tester.pumpWidget(buildMentorTestApp(progressTracker: progressTracker));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.text('Accuracy'), findsWidgets);
      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, closeTo(0.10, 0.01));
    });

    testWidgets('progress report weak topic tap navigates correctly', (tester) async {
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
              (ref) => SettingsController(FakeSettingsRepo()),
            ),
            plannerServiceProvider.overrideWithValue(FakePlannerService()),
            mentorEngagementNudgeRepoProvider.overrideWithValue(FakeNudgeRepo()),
            mentorSessionRepositoryProvider.overrideWithValue(FakeSessionRepo()),
            masteryGraphServiceProvider.overrideWithValue(masteryGraph),
            mentorProgressTrackerProvider.overrideWithValue(FakeProgressTracker()),
            topicRepositoryProvider.overrideWithValue(FakeTopicRepo()),
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

    testWidgets('progress report hides badges section when empty', (tester) async {
      final progressTracker = FakeProgressTracker();
      progressTracker.setBadges([]);
      progressTracker.setOverallStats({
        'totalAttempts': 50, 'correctAttempts': 35,
        'accuracy': 70, 'topicsStudied': 8,
        'weeklyActivity': 15, 'totalStudyTimeHours': 30.0,
      });

      await tester.pumpWidget(buildMentorTestApp(progressTracker: progressTracker));
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

      await tester.pumpWidget(buildMentorTestApp(masteryGraph: masteryGraph));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.text('calculus'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('progress report stat rows display correct information', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.book_outlined), findsOneWidget);
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

      await tester.pumpWidget(buildMentorTestApp(
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

    testWidgets('progress report shows Unknown for topic with null data', (tester) async {
      final masteryGraph = FakeMasteryGraphService();
      final now = DateTime.now();
      masteryGraph.setWeakTopics([
        MasteryState(
          studentId: 'test', topicId: 'null-topic',
          accuracy: 0.35, lastAttempt: now, lastUpdated: now,
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            llmServiceProvider.overrideWithValue(FakeLlmService()),
            settingsProvider.overrideWith(
              (ref) => SettingsController(FakeSettingsRepo()),
            ),
            plannerServiceProvider.overrideWithValue(FakePlannerService()),
            mentorEngagementNudgeRepoProvider.overrideWithValue(FakeNudgeRepo()),
            mentorSessionRepositoryProvider.overrideWithValue(FakeSessionRepo()),
            masteryGraphServiceProvider.overrideWithValue(masteryGraph),
            mentorProgressTrackerProvider.overrideWithValue(FakeProgressTracker()),
            topicRepositoryProvider.overrideWithValue(FakeTopicRepoNullData()),
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

      expect(find.text('Unknown'), findsOneWidget);
    });

    testWidgets('progress report with recommendations enabled and disabled', (tester) async {
      final progressTracker = FakeProgressTracker();
      progressTracker.setRecommendations([
        {'type': 'review', 'priority': 'high', 'message': 'Review algebra'},
      ]);

      await tester.pumpWidget(buildMentorTestApp(progressTracker: progressTracker));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pumpAndSettle();

      expect(find.text('Recommendations'), findsOneWidget);
      expect(find.text('Review algebra'), findsWidgets);
    });
  });
}
