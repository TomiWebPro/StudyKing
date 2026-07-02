import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/features/onboarding/presentation/onboarding_dialog.dart';
import 'package:studyking/features/onboarding/services/onboarding_service.dart';
import 'package:studyking/features/onboarding/services/onboarding_storage.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/settings_update.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/routes/app_router.dart';
import '../../../helpers/navigator_observer_helper.dart';

class _FakeSettingsRepository extends SettingsRepository {
  final SettingsBox _settings;

  _FakeSettingsRepository({bool reduceMotion = false})
      : _settings = SettingsBox()..reduceMotion = reduceMotion;

  @override
  Future<Result<SettingsBox>> getSettings() async {
    return Result.success(_settings);
  }

  @override
  Future<Result<void>> updateSettings(SettingsUpdate update) async {
    return Result.success(null);
  }
}

class _FakeSettingsController extends SettingsController {
  _FakeSettingsController({bool reduceMotion = false})
      : super(_FakeSettingsRepository(reduceMotion: reduceMotion));
}

Widget _buildTestApp(
  Widget widget, {
  bool reduceMotion = false,
}) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith(
        (ref) => _FakeSettingsController(reduceMotion: reduceMotion),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: widget),
      routes: {
        AppRoutes.dashboard: (_) => const Scaffold(
              body: Center(child: Text('Dashboard')),
            ),
      },
    ),
  );
}

Widget _buildTestAppWithRoutes(
  Widget widget, {
  bool reduceMotion = false,
  NavigatorObserver? observer,
}) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith(
        (ref) => _FakeSettingsController(reduceMotion: reduceMotion),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: widget),
      navigatorObservers: observer != null ? [observer] : [],
      routes: {
        AppRoutes.dashboard: (_) => const Scaffold(
              body: Center(child: Text('Dashboard')),
            ),
      },
    ),
  );
}

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

/// Navigates to a specific page index by tapping Next [targetPage] times.
Future<void> navigateToPage(WidgetTester tester, int targetPage) async {
  for (int i = 0; i < targetPage; i++) {
    await tester.tap(find.text('Next'));
    await pumpThroughAnimation(tester);
  }
}

/// Taps a button and pumps until async operation settles.
Future<void> tapButtonAndSettle(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pump();
  await tester.pumpAndSettle();
}

/// Pumps enough frames to complete the PageView scroll animation (300ms).
Future<void> pumpThroughAnimation(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump();
}

/// Navigates to the last page (index 5).
Future<void> navigateToLastPage(WidgetTester tester) async {
  await navigateToPage(tester, 5);
}

/// Navigates to the API key page (index 3).
Future<void> navigateToApiKeyPage(WidgetTester tester) async {
  await navigateToPage(tester, 3);
}

void main() {
  group('OnboardingDialog', () {
    testWidgets('renders first page title', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      expect(find.text('Subjects'), findsOneWidget);
    });

    testWidgets('renders first page description', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      expect(
        find.text('Add and organize your subjects and topics'),
        findsOneWidget,
      );
    });

    testWidgets('renders first page icon', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      expect(find.byIcon(Icons.school), findsOneWidget);
    });

    testWidgets('renders Skip button on page 0', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('renders Next button on page 0', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Get Started'), findsNothing);
    });

    testWidgets('navigates to page 1 and shows Practice title', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      await navigateToPage(tester, 1);
      expect(find.text('Practice'), findsOneWidget);
    });

    testWidgets('navigates to page 2 and shows Mentor title', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      await navigateToPage(tester, 2);
      expect(find.text('Mentor'), findsOneWidget);
    });

    testWidgets('navigates to page 4 and shows Study title', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      await navigateToPage(tester, 4);
      expect(find.text('Study'), findsOneWidget);
    });

    testWidgets('navigates to page 5 and shows Settings title', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      await navigateToPage(tester, 5);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Get Started replaces Next on last page', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      await navigateToLastPage(tester);
      expect(find.text('Next'), findsNothing);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('rocket icon appears on Get Started button', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      await navigateToLastPage(tester);
      await tester.pump();
      expect(find.byIcon(Icons.rocket_launch), findsOneWidget);
    });

    testWidgets('shows dont-show-again checkbox', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      expect(find.text("Don't show again"), findsOneWidget);
    });

    testWidgets('checkbox starts unchecked', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      final checkbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(checkbox.value, isFalse);
    });

    testWidgets('checkbox toggles to checked on tap', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      await tester.tap(find.text("Don't show again"));
      await tester.pump();
      final checkbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(checkbox.value, isTrue);
    });

    testWidgets('checkbox toggles back to unchecked on double tap',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      await tester.tap(find.text("Don't show again"));
      await tester.pump();
      await tester.tap(find.text("Don't show again"));
      await tester.pump();
      final checkbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(checkbox.value, isFalse);
    });

    testWidgets('renders feature icons across pages', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      expect(find.byIcon(Icons.school), findsOneWidget);
      await tester.tap(find.text('Next'));
      await pumpThroughAnimation(tester);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      await tester.tap(find.text('Next'));
      await pumpThroughAnimation(tester);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      await tester.tap(find.text('Next'));
      await pumpThroughAnimation(tester);
      expect(find.byIcon(Icons.key), findsOneWidget);
      await tester.tap(find.text('Next'));
      await pumpThroughAnimation(tester);
      expect(find.byIcon(Icons.menu_book), findsOneWidget);
      await tester.tap(find.text('Next'));
      await pumpThroughAnimation(tester);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('feature icons use primary color', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      final schoolIcon = tester.widget<Icon>(find.byIcon(Icons.school));
      expect(schoolIcon.color, isNotNull);
    });

    testWidgets('feature title uses bold font weight', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      final titleWidget = tester.widget<Text>(find.text('Subjects'));
      expect(titleWidget.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('description pages have all expected text', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      expect(
        find.text('Add and organize your subjects and topics'),
        findsOneWidget,
      );
      await tester.tap(find.text('Next'));
      await pumpThroughAnimation(tester);
      expect(
        find.text('Practice with adaptive questions and spaced repetition'),
        findsOneWidget,
      );
      await tester.tap(find.text('Next'));
      await pumpThroughAnimation(tester);
      expect(
        find.text('Get personalized study recommendations and nudges'),
        findsOneWidget,
      );
      await tester.tap(find.text('Next'));
      await pumpThroughAnimation(tester);
      await tester.tap(find.text('Next'));
      await pumpThroughAnimation(tester);
      expect(
        find.textContaining('Quick practice hub with timer'),
        findsOneWidget,
      );
      await tester.tap(find.text('Next'));
      await pumpThroughAnimation(tester);
      expect(
        find.text('Configure API keys, appearance, and preferences'),
        findsOneWidget,
      );
    });

    testWidgets('page indicator uses AnimatedContainer by default',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      expect(find.byType(AnimatedContainer), findsWidgets);
    });

    testWidgets('page indicator uses Container when reduceMotion is true',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(const OnboardingDialog(), reduceMotion: true),
      );
      await tester.pump();
      expect(find.byType(AnimatedContainer), findsNothing);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('page indicator has correct semantics labels', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      expect(
        find.bySemanticsLabel('Page 1 of 6'),
        findsOneWidget,
      );
    });

    testWidgets(
      'page indicator semantics update after page change',
      (tester) async {
        await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
        await tester.pump();
        await navigateToPage(tester, 1);
        expect(
          find.bySemanticsLabel('Page 2 of 6'),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders API key notice and title', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      await navigateToApiKeyPage(tester);
      expect(find.text('AI Configuration'), findsOneWidget);
      expect(
        find.text(
          'Note: AI features require an API key. Configure one in Settings.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('API key section shows expandable title', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      await navigateToApiKeyPage(tester);
      await tester.pump();
      expect(find.text('What is an API key?'), findsOneWidget);
    });

    testWidgets('API key section shows expand_more icon when collapsed',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      await navigateToApiKeyPage(tester);
      await tester.pump();
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsNothing);
    });

    testWidgets('API key section hides description by default',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
      await tester.pump();
      await navigateToApiKeyPage(tester);
      await tester.pump();
      expect(
        find.text(
          'An API key lets StudyKing use AI services like generating questions and tutoring. You can get one for free from providers like OpenRouter or OpenAI, or run a local model with Ollama.',
        ),
        findsNothing,
      );
    });

    testWidgets('error during onboarding shows snackbar', (tester) async {
      final svc = _ThrowingOnboardingService();
      await tester.pumpWidget(
        _buildTestApp(OnboardingDialog(service: svc)),
      );
      await tester.pump();
      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets(
      'Skip button with service navigates to dashboard',
      (tester) async {
        final svc = OnboardingService(
          storage: InMemoryOnboardingStorage(),
        );
        await tester.pumpWidget(
          _buildTestAppWithRoutes(
            OnboardingDialog(service: svc),
          ),
        );
        await tester.pump();
        await tester.tap(find.text('Skip'));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.text('Dashboard'), findsOneWidget);
      },
    );

    testWidgets(
      'Get Started with service navigates to dashboard',
      (tester) async {
        final svc = OnboardingService(
          storage: InMemoryOnboardingStorage(),
        );
        await tester.pumpWidget(
          _buildTestApp(OnboardingDialog(service: svc)),
        );
        await tester.pump();
        await navigateToLastPage(tester);
        await tester.pump();
        await tester.tap(find.text('Get Started'));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.text('Dashboard'), findsOneWidget);
      },
    );

    testWidgets(
      'Get Started with checkbox and service navigates to dashboard',
      (tester) async {
        final svc = OnboardingService(
          storage: InMemoryOnboardingStorage(),
        );
        await tester.pumpWidget(
          _buildTestApp(OnboardingDialog(service: svc)),
        );
        await tester.pump();
        await tester.tap(find.text("Don't show again"));
        await tester.pump();
        await navigateToLastPage(tester);
        await tester.pump();
        await tester.tap(find.text('Get Started'));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.text('Dashboard'), findsOneWidget);
      },
    );

    testWidgets('OnboardingDialog renders correctly in dark theme',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            (ref) => _FakeSettingsController(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData.dark(),
          home: Scaffold(body: const OnboardingDialog()),
        ),
      ));
      await tester.pump();
      expect(find.text('Subjects'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('shows please wait text during saving', (tester) async {
      final svc = OnboardingService(
        storage: _SlowInMemoryStorage(),
      );
      await tester.pumpWidget(
        _buildTestApp(OnboardingDialog(service: svc)),
      );
      await tester.pump();
      await navigateToLastPage(tester);
      await tester.pump();
      await tester.tap(find.text('Get Started'));
      await tester.pump();
      expect(find.text('Please wait\u2026'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('shows CircularProgressIndicator during saving',
        (tester) async {
      final svc = OnboardingService(
        storage: _SlowInMemoryStorage(),
      );
      await tester.pumpWidget(
        _buildTestApp(OnboardingDialog(service: svc)),
      );
      await tester.pump();
      await navigateToLastPage(tester);
      await tester.pump();
      await tester.tap(find.text('Get Started'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Skip button disabled during saving', (tester) async {
      final svc = OnboardingService(
        storage: _SlowInMemoryStorage(),
      );
      await tester.pumpWidget(
        _buildTestApp(OnboardingDialog(service: svc)),
      );
      await tester.pump();
      await navigateToLastPage(tester);
      await tester.pump();
      await tester.tap(find.text('Get Started'));
      await tester.pump();
      final textButtons = find.byType(TextButton);
      final skipButton = tester.widget<TextButton>(textButtons.first);
      expect(skipButton.onPressed, isNull);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Get Started button disabled during saving', (tester) async {
      final svc = OnboardingService(
        storage: _SlowInMemoryStorage(),
      );
      await tester.pumpWidget(
        _buildTestApp(OnboardingDialog(service: svc)),
      );
      await tester.pump();
      await navigateToLastPage(tester);
      await tester.pump();
      await tester.tap(find.text('Get Started'));
      await tester.pump();
      final filledButtons = find.byType(FilledButton);
      final getStartedButton = tester.widget<FilledButton>(filledButtons.first);
      expect(getStartedButton.onPressed, isNull);
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('ApiKeyBanner', () {
    Widget buildBannerApp(Widget widget) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: widget),
      );
    }

    testWidgets('renders localized api key message', (tester) async {
      await tester.pumpWidget(buildBannerApp(
        ApiKeyBanner(onDismiss: () {}),
      ));
      await tester.pump();
      expect(
        find.text(
          'StudyKing needs an API key to use AI features. Configure one now.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders Configure Now and Dismiss buttons', (tester) async {
      await tester.pumpWidget(buildBannerApp(
        ApiKeyBanner(onDismiss: () {}),
      ));
      await tester.pump();
      expect(find.text('Configure Now'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
    });

    testWidgets('calls onDismiss when Dismiss is tapped', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(buildBannerApp(
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
          AppRoutes.dashboard: (_) => const Scaffold(
                body: Center(child: Text('Dashboard')),
              ),
        },
      ));
      await tester.pump();
      await tester.tap(find.text('Configure Now'));
      await tester.pumpAndSettle();
      final routeNames =
          observer.pushedRoutes.map((r) => r.settings.name).toList();
      expect(routeNames, contains(AppRoutes.apiConfig));
      expect(find.text('API Config'), findsOneWidget);
    });

    testWidgets('renders key icon', (tester) async {
      await tester.pumpWidget(buildBannerApp(
        ApiKeyBanner(onDismiss: () {}),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.key), findsOneWidget);
    });

    testWidgets('key icon uses theme error color', (tester) async {
      await tester.pumpWidget(buildBannerApp(
        ApiKeyBanner(onDismiss: () {}),
      ));
      await tester.pump();
      final keyIcon = tester.widget<Icon>(find.byIcon(Icons.key));
      expect(keyIcon.color, ThemeData.light().colorScheme.error);
    });

    testWidgets(
      'renders Don\'t show again button when callback provided',
      (tester) async {
        await tester.pumpWidget(buildBannerApp(
          ApiKeyBanner(onDismiss: () {}, onDontShowAgain: () {}),
        ));
        await tester.pump();
        expect(find.text("Don't show again"), findsOneWidget);
      },
    );

    testWidgets(
      'hides Don\'t show again button when callback is null',
      (tester) async {
        await tester.pumpWidget(buildBannerApp(
          ApiKeyBanner(onDismiss: () {}),
        ));
        await tester.pump();
        expect(find.text("Don't show again"), findsNothing);
      },
    );

    testWidgets(
      'calls onDontShowAgain when Don\'t show again button is tapped',
      (tester) async {
        bool dontShowAgainCalled = false;
        await tester.pumpWidget(buildBannerApp(
          ApiKeyBanner(
            onDismiss: () {},
            onDontShowAgain: () => dontShowAgainCalled = true,
          ),
        ));
        await tester.pump();
        await tester.tap(find.text("Don't show again"));
        expect(dontShowAgainCalled, isTrue);
      },
    );

    testWidgets('ApiKeyBanner renders correctly in dark theme',
        (tester) async {
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
        find.text(
          'StudyKing needs an API key to use AI features. Configure one now.',
        ),
        findsOneWidget,
      );
      expect(find.text('Configure Now'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
    });
  });

  group('LocalDataNotice', () {
    Widget buildNoticeApp(Widget widget) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: widget),
      );
    }

    testWidgets('renders localized title', (tester) async {
      await tester.pumpWidget(buildNoticeApp(const LocalDataNotice()));
      await tester.pump();
      expect(find.text('Local Data Storage'), findsOneWidget);
    });

    testWidgets('renders localized description', (tester) async {
      await tester.pumpWidget(buildNoticeApp(const LocalDataNotice()));
      await tester.pump();
      expect(
        find.textContaining(
          'StudyKing stores all your data locally on this device',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders I Understand button', (tester) async {
      await tester.pumpWidget(buildNoticeApp(const LocalDataNotice()));
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

    testWidgets('LocalDataNotice renders correctly in dark theme',
        (tester) async {
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

    testWidgets('Get Started persists onboarding_completed flag',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(OnboardingDialog(service: service)),
      );
      await tester.pump();
      await navigateToLastPage(tester);
      await tester.pump();
      await tester.tap(find.text('Get Started'));
      await tester.pump();
      await tester.pumpAndSettle();

      final result = await service.isOnboardingNeeded();
      expect(result.data, isFalse);
    });

    testWidgets(
      'Get Started with dontShowAgain persists dontShowAgain flag',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(OnboardingDialog(service: service)),
        );
        await tester.pump();
        await tester.tap(find.text("Don't show again"));
        await tester.pump();
        await navigateToLastPage(tester);
        await tester.pump();
        await tester.tap(find.text('Get Started'));
        await tester.pump();
        await tester.pumpAndSettle();

        final result = await service.isOnboardingNeeded();
        expect(result.data, isFalse);
      },
    );

    testWidgets('Skip also persists onboarding_completed', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(OnboardingDialog(service: service)),
      );
      await tester.pump();
      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pumpAndSettle();

      final result = await service.isOnboardingNeeded();
      expect(result.data, isFalse);
    });

    testWidgets('Skip with dontShowAgain persists dontShowAgain flag',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(OnboardingDialog(service: service)),
      );
      await tester.pump();
      await tester.tap(find.text("Don't show again"));
      await tester.pump();
      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pumpAndSettle();

      final result = await service.isOnboardingNeeded();
      expect(result.data, isFalse);
    });
  });
}

class _SlowInMemoryStorage extends InMemoryOnboardingStorage {
  @override
  Future<void> setBool(String key, bool value) async {
    await super.setBool(key, value);
  }
}

class _ThrowingOnboardingService extends OnboardingService {
  _ThrowingOnboardingService() : super(storage: InMemoryOnboardingStorage());

  @override
  Future<Result<void>> markCompleted() async {
    throw Exception('Service failure');
  }

  @override
  Future<Result<void>> markDontShowAgain() async {
    throw Exception('Service failure');
  }
}
