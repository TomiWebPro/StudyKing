import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/onboarding/presentation/onboarding_dialog.dart';
import 'package:studyking/features/onboarding/services/onboarding_service.dart';
import 'package:studyking/features/onboarding/services/onboarding_storage.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/routes/app_router.dart';
import '../../../helpers/navigator_observer_helper.dart';

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

/// Helper that pumps [child] shown via [showDialog] so [Navigator.pop] works.
Future<void> pumpShowDialog(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Builder(
      builder: (context) => Scaffold(
        body: ElevatedButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => child,
          ),
          child: const Text('Show'),
        ),
      ),
    ),
  ));
  await tester.pump();
  await tester.tap(find.text('Show'));
  await tester.pump();
}

void main() {
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

    testWidgets('Get Started closes the dialog', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      await tester.tap(find.text('Get Started'));
      await tester.pump();
      expect(find.byType(OnboardingDialog), findsNothing);
    });

    testWidgets('Get Started closes dialog even when checkbox is checked', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      await tester.tap(find.text("Don't show again"));
      await tester.pump();
      await tester.tap(find.text('Get Started'));
      await tester.pump();
      expect(find.byType(OnboardingDialog), findsNothing);
    });

    testWidgets('Add Subject navigates to subject selection', (tester) async {
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const OnboardingDialog(),
        navigatorObservers: [observer],
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
      expect(observer.pushedRoutes, hasLength(1));
      expect(observer.pushedRoutes.first.settings.name, AppRoutes.subjectSelection);
      expect(find.text('Subject Selection'), findsOneWidget);
    });

    testWidgets('Add Subject navigates to subject selection when checkbox unchecked', (tester) async {
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const OnboardingDialog(),
        navigatorObservers: [observer],
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
      expect(observer.pushedRoutes, hasLength(1));
      expect(observer.pushedRoutes.first.settings.name, AppRoutes.subjectSelection);
      expect(find.text('Subject Selection'), findsOneWidget);
    });

    testWidgets('Quick Guide navigates to quick guide screen', (tester) async {
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const OnboardingDialog(),
        navigatorObservers: [observer],
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
      expect(observer.pushedRoutes, hasLength(1));
      expect(observer.pushedRoutes.first.settings.name, AppRoutes.quickGuide);
    });

    testWidgets('Quick Guide navigates to quick guide screen when checkbox unchecked', (tester) async {
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const OnboardingDialog(),
        navigatorObservers: [observer],
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
      expect(observer.pushedRoutes, hasLength(1));
      expect(observer.pushedRoutes.first.settings.name, AppRoutes.quickGuide);
    });

    testWidgets('Add Subject navigates when dont-show-again checked', (tester) async {
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        navigatorObservers: [observer],
        home: Scaffold(body: const OnboardingDialog()),
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
      expect(observer.pushedRoutes, hasLength(1));
      expect(observer.pushedRoutes.first.settings.name, AppRoutes.subjectSelection);
    });

    testWidgets('Quick Guide navigates when dont-show-again checked', (tester) async {
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        navigatorObservers: [observer],
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
      expect(observer.pushedRoutes, hasLength(1));
      expect(observer.pushedRoutes.first.settings.name, AppRoutes.quickGuide);
    });

    testWidgets('feature icons use theme primary color', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      final featureIcons = find.byIcon(Icons.rocket_launch);
      final featureIcon = tester.widget<Icon>(featureIcons);
      expect(featureIcon.color, isNotNull);
    });

    testWidgets('renders all feature icons', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      expect(find.byIcon(Icons.school), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('each feature icon uses primary color', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      for (final icon in [
        Icons.school,
        Icons.play_arrow,
        Icons.auto_awesome,
        Icons.timer,
        Icons.settings,
      ]) {
        final iconWidget = tester.widget<Icon>(find.byIcon(icon));
        expect(iconWidget.color, isNotNull, reason: '$icon should have a color');
      }
    });

    testWidgets('feature titles use fontWeight w600', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      for (final title in ['Subjects', 'Practice', 'Mentor', 'Focus Mode', 'Settings']) {
        final textWidget = tester.widget<Text>(find.text(title));
        expect(textWidget.style?.fontWeight, FontWeight.w600);
      }
    });

    testWidgets('feature descriptions have a text style applied', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      for (final desc in [
        'Add and organize your subjects and topics',
        'Practice with adaptive questions and spaced repetition',
        'Get personalized study recommendations and nudges',
        'Stay focused with Pomodoro-style study sessions',
        'Configure API keys, appearance, and preferences',
      ]) {
        final textWidget = tester.widget<Text>(find.text(desc));
        expect(textWidget.style, isNotNull);
      }
    });

    testWidgets('API key notice uses error color', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      final noticeText = tester.widget<Text>(
        find.text('Note: AI features require an API key. Configure one in Settings.'),
      );
      expect(noticeText.style?.color, isNotNull);
    });

    testWidgets('Get Started closes dialog even with dont-show-again checked', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      await tester.tap(find.text("Don't show again"));
      await tester.pump();
      await tester.tap(find.text('Get Started'));
      await tester.pump();
      expect(find.byType(OnboardingDialog), findsNothing);
    });

    testWidgets('dialog renders rocket icon with theme primary color not null', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      final rocketIcon = tester.widget<Icon>(find.byIcon(Icons.rocket_launch));
      expect(rocketIcon.color, isNotNull);
    });

    testWidgets('OnboardingDialog renders correctly in dark theme', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData.dark(),
        home: Scaffold(body: const OnboardingDialog()),
      ));
      await tester.pump();
      expect(find.text('Welcome to StudyKing'), findsOneWidget);
      expect(find.text('Add Subject'), findsOneWidget);
      expect(find.text('Quick Guide'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
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
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
          home: Scaffold(
            body: ApiKeyBanner(onDismiss: () {}),
          ),
        navigatorObservers: [observer],
        routes: {
          AppRoutes.apiConfig: (_) => const Scaffold(
                body: Center(child: Text('API Config')),
              ),
        },
      ));
      await tester.pump();
      await tester.tap(find.text('Configure Now'));
      await tester.pumpAndSettle();
      expect(observer.pushedRoutes, hasLength(1));
      expect(observer.pushedRoutes.first.settings.name, AppRoutes.apiConfig);
      expect(find.text('API Config'), findsOneWidget);
    });

    testWidgets('renders key icon', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ApiKeyBanner(onDismiss: () {}),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.key), findsOneWidget);
    });

    testWidgets('key icon uses orange color', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ApiKeyBanner(onDismiss: () {}),
      ));
      await tester.pump();
      final keyIcon = tester.widget<Icon>(find.byIcon(Icons.key));
      expect(keyIcon.color, Colors.orange);
    });

    testWidgets('ApiKeyBanner renders correctly in dark theme', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData.dark(),
        home: Scaffold(
          body: ApiKeyBanner(onDismiss: () {}),
        ),
      ));
      await tester.pump();
      expect(
        find.text('StudyKing needs an API key to use AI features. Configure one now.'),
        findsOneWidget,
      );
      expect(find.text('Configure Now'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
    });

    testWidgets('ApiKeyBanner onDismiss is called from button callback', (tester) async {
      int dismissCount = 0;
      await tester.pumpWidget(_buildTestApp(
        ApiKeyBanner(onDismiss: () => dismissCount++),
      ));
      await tester.pump();
      await tester.tap(find.text('Dismiss'));
      expect(dismissCount, 1);
      expect(find.byType(MaterialBanner), findsOneWidget);
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
      await pumpShowDialog(tester, const LocalDataNotice());
      await tester.pump();
      expect(find.byType(LocalDataNotice), findsOneWidget);
      await tester.tap(find.text('I Understand'));
      await tester.pumpAndSettle();
      expect(find.byType(LocalDataNotice), findsNothing);
    });

    testWidgets('LocalDataNotice renders correctly in dark theme', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData.dark(),
        home: Scaffold(body: const LocalDataNotice()),
      ));
      await tester.pump();
      expect(find.text('Local Data Storage'), findsOneWidget);
      expect(find.text('I Understand'), findsOneWidget);
    });
  });

  group('persistence', () {
    late OnboardingService service;

    setUp(() {
      service = OnboardingService(storage: InMemoryOnboardingStorage());
    });

    testWidgets('Get Started persists onboarding_completed flag', (tester) async {
      await tester.pumpWidget(_buildTestApp(OnboardingDialog(service: service)));
      await tester.pump();
      await tester.tap(find.text('Get Started'));
      await tester.pump();

      final result = await service.isOnboardingNeeded();
      expect(result.data, isFalse);
    });
  });
}
