import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/onboarding/presentation/onboarding_dialog.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/routes/app_router.dart';

Widget _buildTestApp(Widget widget) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: widget),
    routes: {
      AppRoutes.subjectSelection: (_) => const Scaffold(
            body: Center(child: Text('Subject Selection')),
          ),
      AppRoutes.quickGuide: (_) => const Scaffold(
            body: Center(child: Text('Quick Guide')),
          ),
      AppRoutes.apiConfig: (_) => const Scaffold(
            body: Center(child: Text('API Config')),
          ),
    },
  );
}

void main() {
  late String hivePath;

  setUp(() async {
    hivePath = (await Directory.systemTemp.createTemp('onboarding_widget_test_')).path;
    Hive.init(hivePath);
  });

  tearDown(() async {
    await Hive.close();
    if (hivePath.isNotEmpty) {
      await Directory(hivePath).delete(recursive: true);
    }
  });

  group('OnboardingDialog', () {
    testWidgets('renders welcome title', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      expect(find.text('Welcome to StudyKing'), findsOneWidget);
    });

    testWidgets('renders feature titles', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      expect(find.text('Subjects'), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
      expect(find.text('Mentor'), findsOneWidget);
      expect(find.text('Focus Mode'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('renders feature descriptions', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      expect(
        find.text('Add and organize your subjects and topics'),
        findsOneWidget,
      );
      expect(
        find.text('Practice with adaptive questions and spaced repetition'),
        findsOneWidget,
      );
      expect(
        find.text('Get personalized study recommendations and nudges'),
        findsOneWidget,
      );
      expect(
        find.text('Stay focused with Pomodoro-style study sessions'),
        findsOneWidget,
      );
      expect(
        find.text('Configure API keys, appearance, and preferences'),
        findsOneWidget,
      );
    });

    testWidgets('renders action buttons', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      expect(find.text('Add Subject'), findsOneWidget);
      expect(find.text('Quick Guide'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('shows dont-show-again checkbox', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      expect(find.text("Don't show again"), findsOneWidget);
    });

    testWidgets('renders API key notice', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      expect(
        find.text('Note: AI features require an API key. Configure one in Settings.'),
        findsOneWidget,
      );
    });

    testWidgets('renders rocket icon', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      expect(find.byIcon(Icons.rocket_launch), findsOneWidget);
    });

    testWidgets('checkbox starts unchecked', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      final checkbox = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(checkbox.value, isFalse);
    });

    testWidgets('checkbox toggles to checked on tap', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      await tester.tap(find.text("Don't show again"));
      await tester.pump();
      final checkbox = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(checkbox.value, isTrue);
    });

    testWidgets('checkbox toggles back to unchecked on double tap', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      await tester.tap(find.text("Don't show again"));
      await tester.pump();
      await tester.tap(find.text("Don't show again"));
      await tester.pump();
      final checkbox = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(checkbox.value, isFalse);
    });

    testWidgets('Get Started calls markCompleted', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
    });

    testWidgets('Add Subject navigates to subject selection', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const OnboardingDialog(),
        routes: {
          AppRoutes.subjectSelection: (_) => const Scaffold(
                body: Center(child: Text('Subject Selection')),
              ),
          AppRoutes.quickGuide: (_) => const Scaffold(
                body: Center(child: Text('Quick Guide')),
              ),
        },
      ));
      await tester.pump();
      await tester.tap(find.text('Add Subject'));
      await tester.pumpAndSettle();
      expect(find.text('Subject Selection'), findsOneWidget);
    });

    testWidgets('Quick Guide navigates to quick guide screen', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const OnboardingDialog(),
        routes: {
          AppRoutes.subjectSelection: (_) => const Scaffold(
                body: Center(child: Text('Subject Selection')),
              ),
          AppRoutes.quickGuide: (_) => const Scaffold(
                body: Center(child: Text('Quick Guide')),
              ),
        },
      ));
      await tester.pump();
      await tester.tap(find.text('Quick Guide'));
      await tester.pumpAndSettle();
      expect(find.text('Quick Guide'), findsOneWidget);
    });

    testWidgets('Add Subject with dont-show-again checked calls markDontShowAgain', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const OnboardingDialog(),
        routes: {
          AppRoutes.subjectSelection: (_) => const Scaffold(
                body: Center(child: Text('Subject Selection')),
              ),
          AppRoutes.quickGuide: (_) => const Scaffold(
                body: Center(child: Text('Quick Guide')),
              ),
        },
      ));
      await tester.pump();
      await tester.tap(find.text("Don't show again"));
      await tester.pump();
      await tester.tap(find.text('Add Subject'));
      await tester.pumpAndSettle();
      expect(find.text('Subject Selection'), findsOneWidget);
    });

    testWidgets('Quick Guide with dont-show-again checked calls markDontShowAgain', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const OnboardingDialog(),
        routes: {
          AppRoutes.subjectSelection: (_) => const Scaffold(
                body: Center(child: Text('Subject Selection')),
              ),
          AppRoutes.quickGuide: (_) => const Scaffold(
                body: Center(child: Text('Quick Guide')),
              ),
        },
      ));
      await tester.pump();
      await tester.tap(find.text("Don't show again"));
      await tester.pump();
      await tester.tap(find.text('Quick Guide'));
      await tester.pumpAndSettle();
      expect(find.text('Quick Guide'), findsOneWidget);
    });
  });

  group('ApiKeyBanner', () {
    testWidgets('renders localized api key message', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ApiKeyBanner(onDismiss: () {}),
      ));
      await tester.pump();
      expect(
        find.text('StudyKing needs an API key to use AI features. Configure one now.'),
        findsOneWidget,
      );
    });

    testWidgets('renders Configure Now and Dismiss buttons', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ApiKeyBanner(onDismiss: () {}),
      ));
      await tester.pump();
      expect(find.text('Configure Now'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
    });

    testWidgets('calls onDismiss when Dismiss is tapped', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(_buildTestApp(
        ApiKeyBanner(onDismiss: () => dismissed = true),
      ));
      await tester.pump();
      await tester.tap(find.text('Dismiss'));
      expect(dismissed, isTrue);
    });

    testWidgets('Configure Now navigates to api config', (tester) async {
      final observer = NavigatorObserver();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        navigatorObservers: [observer],
          home: Scaffold(
            body: ApiKeyBanner(onDismiss: () {}),
          ),
        routes: {
          AppRoutes.apiConfig: (_) => const Scaffold(
                body: Center(child: Text('API Config')),
              ),
        },
      ));
      await tester.pump();
      await tester.tap(find.text('Configure Now'));
      await tester.pumpAndSettle();
      expect(find.text('API Config'), findsOneWidget);
    });

    testWidgets('renders key icon', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ApiKeyBanner(onDismiss: () {}),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.key), findsOneWidget);
    });
  });

  group('LocalDataNotice', () {
    testWidgets('renders localized title', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LocalDataNotice()));
      await tester.pump();
      expect(find.text('Local Data Storage'), findsOneWidget);
    });

    testWidgets('renders localized description', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LocalDataNotice()));
      await tester.pump();
      expect(
        find.textContaining('StudyKing stores all your data locally on this device'),
        findsOneWidget,
      );
    });

    testWidgets('renders I Understand button', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LocalDataNotice()));
      await tester.pump();
      expect(find.text('I Understand'), findsOneWidget);
    });

    testWidgets('tapping I Understand pops the dialog', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LocalDataNotice()));
      await tester.pump();
      await tester.tap(find.text('I Understand'));
      await tester.pumpAndSettle();
    });
  });
}
