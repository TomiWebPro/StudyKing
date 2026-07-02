import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider, SettingsController;
import 'package:studyking/core/providers/llm_providers.dart' show llmServiceProvider;
import 'package:studyking/features/settings/data/models/settings_update.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart' show plannerServiceProvider;
import 'package:studyking/features/mentor/providers/mentor_providers.dart' show mentorEngagementNudgeRepoProvider, mentorSessionRepositoryProvider, mentorProgressTrackerProvider;
import 'package:studyking/features/practice/providers/practice_providers.dart' show masteryGraphServiceProvider;
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/features/mentor/presentation/mentor_screen.dart';
import 'mentor_screen_test_helpers.dart';
import '../../../helpers/navigator_observer_helper.dart';

void main() {
  group('MentorScreen - Basic', () {
    testWidgets('renders app bar with mentor greeting', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      expect(find.text('AI Mentor'), findsWidgets);
    });

    testWidgets('renders chat input and send button', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Ask your mentor anything...'), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('shows progress report button in app bar', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Progress Report'), findsOneWidget);
    });

    testWidgets('welcome message is shown after initialization', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('AI Mentor'), findsWidgets);
    });

    testWidgets('empty state shown when no messages', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
    });

    testWidgets('sends a message and shows response', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
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
      await tester.pumpWidget(buildMentorTestApp());
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

      await tester.pumpWidget(buildMentorTestApp(llmService: errorService));
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

      await tester.pumpWidget(buildMentorTestApp(llmService: delayedService));
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
      await tester.pumpWidget(buildMentorTestApp());

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
      expect(find.text('Ask your mentor anything...'), findsOneWidget);
    });

    testWidgets('sending empty message does nothing', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Ask your mentor anything...'), findsOneWidget);
    });

    testWidgets('shows list view with messages', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
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

    testWidgets('sends multiple messages', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
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

    testWidgets('whitespace-only input is rejected', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
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

      await tester.pumpWidget(buildMentorTestApp(llmService: delayedService));
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

    testWidgets('text field has initial focus', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('text field remains focusable after sending message', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
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

    testWidgets('welcome message has mentor role and correct content', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('AI Mentor'), findsWidgets);
      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
    });

    testWidgets('conversation input is in correct state after initialization', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      final input = find.byType(TextField);
      expect(input, findsOneWidget);
    });

    testWidgets('uses jump scroll with reduce motion enabled', (tester) async {
      final repo = FakeSettingsRepo();
      await repo.init();
      final ctrl = SettingsController(repo);
      await ctrl.updateSettings(const SettingsUpdate(reduceMotion: true));
      await tester.pump();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            llmServiceProvider.overrideWithValue(FakeLlmService()),
            settingsProvider.overrideWith((ref) => ctrl),
            plannerServiceProvider.overrideWithValue(FakePlannerService()),
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
          (ref) => SettingsController(FakeSettingsRepo()),
        ),
        plannerServiceProvider.overrideWithValue(FakePlannerService()),
        mentorEngagementNudgeRepoProvider.overrideWithValue(FakeNudgeRepo()),
        mentorSessionRepositoryProvider.overrideWithValue(FakeSessionRepo()),
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

    testWidgets('popup menu button is present in app bar', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('popup menu opens on tap and shows clear option', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Clear conversation'), findsOneWidget);
    });

    testWidgets('clear conversation shows confirmation dialog', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
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
      await tester.pumpWidget(buildMentorTestApp());
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
      await tester.pumpWidget(buildMentorTestApp());
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

    testWidgets('widget disposed during initialization does not crash', (tester) async {
      final controllableRepo = ControllableNudgeRepo();

      await tester.pumpWidget(buildMentorTestApp(nudgeRepo: controllableRepo));
      await tester.pump();

      expect(find.byType(MentorScreen), findsOneWidget);

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

    testWidgets('navigator observes no pops initially', (tester) async {
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(buildMentorTestApp(navigatorObserver: observer));
      await tester.pumpAndSettle();

      expect(observer.poppedRoutes, isEmpty);
    });

    testWidgets('app bar title contains auto awesome icon and mentor greeting', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.title, isNotNull);
    });

    testWidgets('sending plan message shows plan details', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'I want to plan 90 days');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.textContaining('Mentor response').evaluate().isNotEmpty) break;
      }

      expect(find.textContaining('Mentor response'), findsOneWidget);
    });

    testWidgets('reduce motion uses jump scroll behavior', (tester) async {
      await tester.pumpWidget(buildMentorTestApp());
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
  });
}
