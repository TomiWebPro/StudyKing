import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider, SettingsController;
import 'package:studyking/core/providers/llm_providers.dart' show llmServiceProvider;
import 'package:studyking/features/practice/providers/practice_providers.dart' show masteryGraphServiceProvider;
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart' show plannerServiceProvider, plannerProvider;
import 'package:studyking/features/mentor/providers/mentor_providers.dart' show mentorEngagementNudgeRepoProvider, mentorSessionRepositoryProvider, mentorProgressTrackerProvider;
import 'package:studyking/features/mentor/presentation/mentor_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'mentor_screen_test_helpers.dart';

void main() {
  group('MentorScreen - Init Errors', () {
    testWidgets('init error shows error card with retry and settings buttons', (tester) async {
      final throwingRepo = ThrowingNudgeRepo();

      await tester.pumpWidget(buildMentorTestApp(nudgeRepo: throwingRepo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Go to Settings'), findsOneWidget);
      expect(find.textContaining('Mentor initialization failed'), findsOneWidget);
    });

    testWidgets('init error changes input hint text', (tester) async {
      final throwingRepo = ThrowingNudgeRepo();

      await tester.pumpWidget(buildMentorTestApp(nudgeRepo: throwingRepo));
      await tester.pumpAndSettle();

      expect(
        find.text('Connectivity issue — configure AI provider in Settings'),
        findsOneWidget,
      );
    });

    testWidgets('init error retry reinitializes and shows error again', (tester) async {
      final throwingRepo = ThrowingNudgeRepo();

      await tester.pumpWidget(buildMentorTestApp(nudgeRepo: throwingRepo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('init error settings button navigates to api config', (tester) async {
      final throwingRepo = ThrowingNudgeRepo();
      final navigatorRoutes = <String>[];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            llmServiceProvider.overrideWithValue(FakeLlmService()),
            settingsProvider.overrideWith(
              (ref) => SettingsController(FakeSettingsRepo()),
            ),
            plannerServiceProvider.overrideWithValue(FakePlannerService()),
            mentorEngagementNudgeRepoProvider.overrideWithValue(throwingRepo),
            mentorSessionRepositoryProvider.overrideWithValue(FakeSessionRepo()),
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

    testWidgets('conversation input is disabled during init error', (tester) async {
      final throwingRepo = ThrowingNudgeRepo();

      await tester.pumpWidget(buildMentorTestApp(nudgeRepo: throwingRepo));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('shows API key missing message when no API key configured', (tester) async {
      final noKeyService = FakeLlmService(hasApiKey: false);

      await tester.pumpWidget(buildMentorTestApp(llmService: noKeyService));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.textContaining('AI service not configured.'), findsOneWidget);
      expect(find.text('Go to Settings'), findsOneWidget);
    });

    testWidgets('progress report early return before initialization completes', (tester) async {
      final controllableRepo = ControllableNudgeRepo();

      await tester.pumpWidget(buildMentorTestApp(nudgeRepo: controllableRepo));
      await tester.pump();

      await tester.tap(find.byTooltip('Progress Report'));
      await tester.pump();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);

      controllableRepo.completeInit();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
    });
  });

  group('MentorScreen - Voice & Nudges', () {
    testWidgets('shows voice input button when voice is available', (tester) async {
      await tester.pumpWidget(buildMentorTestApp(
        voiceService: FakeVoiceService(available: true),
      ));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Voice Input'), findsOneWidget);
    });

    testWidgets('voice input button hidden when voice not available', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Voice Input'), findsNothing);
    });

    testWidgets('voice button shows mic icon when listening', (tester) async {
      await tester.pumpWidget(buildMentorTestApp(
        voiceService: FakeVoiceService(available: true, listening: true),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('voice button starts listening on tap when available', (tester) async {
      final voiceService = FakeControllableVoiceService(available: true);

      await tester.pumpWidget(buildMentorTestApp(voiceService: voiceService));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.mic_none), findsOneWidget);

      await tester.tap(find.byTooltip('Voice Input'));
      await tester.pump();

      expect(voiceService.isListening, isTrue);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('voice button stops listening on second tap', (tester) async {
      final voiceService = FakeControllableVoiceService(available: true);

      await tester.pumpWidget(buildMentorTestApp(voiceService: voiceService));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Voice Input'));
      await tester.pump();
      expect(voiceService.isListening, isTrue);

      await tester.tap(find.byTooltip('Voice Input'));
      await tester.pump();
      expect(voiceService.isListening, isFalse);
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
    });

    testWidgets('loads unread nudges after initialization', (tester) async {
      await tester.pumpWidget(buildMentorTestApp(
        nudgeRepo: NudgeReturningRepo(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('--- While you were away ---'), findsOneWidget);
      expect(find.text('Time to study!'), findsOneWidget);
      expect(find.text('--- End of pending messages ---'), findsOneWidget);
    });

    testWidgets('nudge loading exception does not crash the screen', (tester) async {
      await tester.pumpWidget(buildMentorTestApp(
        nudgeRepo: NudgeThrowingRepo(),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
      expect(find.text('AI Mentor'), findsWidgets);
    });
  });

  group('MentorScreen - Scheduling & Planning', () {
    testWidgets('sending schedule message shows schedule dialog', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'I want to schedule a lesson about algebra');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(AlertDialog).evaluate().isNotEmpty) break;
      }

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('schedule dialog cancel returns to chat', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'I want to schedule a lesson about algebra');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(AlertDialog).evaluate().isNotEmpty) break;
      }

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('schedule confirmation dialog confirm schedules lesson', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'schedule a lesson about algebra');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(AlertDialog).evaluate().isNotEmpty) break;
      }

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Lesson on "algebra" scheduled for'), findsOneWidget);
    });

    testWidgets('sends message with schedule intent and dialog shows topic', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'schedule a lesson about calculus');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(AlertDialog).evaluate().isNotEmpty) break;
      }

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('plan message triggers roadmap confirmation dialog', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'plan for learning calculus in 30 days');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.text('Create Roadmap').evaluate().isNotEmpty) break;
      }

      expect(find.text('Create Roadmap'), findsOneWidget);
      expect(find.textContaining('30-day learning roadmap'), findsOneWidget);
    });

    testWidgets('roadmap dialog confirm creates roadmap and shows success', (tester) async {
      final plannerNotifier = FakePlannerNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            llmServiceProvider.overrideWithValue(FakeLlmService()),
            settingsProvider.overrideWith(
              (ref) => SettingsController(FakeSettingsRepo()),
            ),
            plannerServiceProvider.overrideWithValue(FakePlannerService()),
            plannerProvider.overrideWith((ref) => plannerNotifier),
            mentorEngagementNudgeRepoProvider.overrideWithValue(FakeNudgeRepo()),
            mentorSessionRepositoryProvider.overrideWithValue(FakeSessionRepo()),
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
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'plan for learning calculus in 30 days');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));

      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.text('Create Roadmap').evaluate().isNotEmpty) break;
      }

      expect(find.text('Create Roadmap'), findsOneWidget);

      await tester.tap(find.text('Create Roadmap'));
      await tester.pumpAndSettle();

      expect(plannerNotifier.didCreateRoadmap, isTrue);
      expect(plannerNotifier.createdGoal, 'learning calculus');
      expect(plannerNotifier.createdDays, 30);
      expect(find.textContaining('Roadmap created'), findsWidgets);
    });

    testWidgets('plan without goal shows plan days message', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'plan 60 days');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.textContaining('Mentor response').evaluate().isNotEmpty) break;
      }

      expect(find.textContaining('Mentor response'), findsOneWidget);
    });
  });

  group('MentorScreen - Suggested Actions', () {
    testWidgets('suggested action card appears after initialization', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      expect(
        find.textContaining("You haven't added any subjects yet"),
        findsOneWidget,
      );
    });

    testWidgets('suggested action card can be dismissed', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);

      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
    });

    testWidgets('suggested action error card shown when service fails', (tester) async {
      await tester.pumpWidget(buildMentorTestApp(
        progressTracker: ThrowingProgressTracker(),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('An error occurred. Please try again.'), findsOneWidget);
    });

    testWidgets('suggested action error card retry reattempts loading', (tester) async {
      await tester.pumpWidget(buildMentorTestApp(
        progressTracker: ThrowingProgressTracker(),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('An error occurred. Please try again.'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('MentorScreen - Weak Topic Errors', () {
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
              (ref) => SettingsController(FakeSettingsRepo()),
            ),
            plannerServiceProvider.overrideWithValue(FakePlannerService()),
            mentorEngagementNudgeRepoProvider.overrideWithValue(FakeNudgeRepo()),
            mentorSessionRepositoryProvider.overrideWithValue(FakeSessionRepo()),
            masteryGraphServiceProvider.overrideWithValue(masteryGraph),
            mentorProgressTrackerProvider.overrideWithValue(FakeProgressTracker()),
            topicRepositoryProvider.overrideWithValue(FakeTopicRepoNoSubject()),
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
              (ref) => SettingsController(FakeSettingsRepo()),
            ),
            plannerServiceProvider.overrideWithValue(FakePlannerService()),
            mentorEngagementNudgeRepoProvider.overrideWithValue(FakeNudgeRepo()),
            mentorSessionRepositoryProvider.overrideWithValue(FakeSessionRepo()),
            masteryGraphServiceProvider.overrideWithValue(masteryGraph),
            mentorProgressTrackerProvider.overrideWithValue(FakeProgressTracker()),
            topicRepositoryProvider.overrideWithValue(FakeTopicRepoThrowing()),
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
  });
}
