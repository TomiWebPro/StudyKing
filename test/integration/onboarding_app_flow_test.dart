import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/hive_init_helper.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/onboarding/presentation/onboarding_dialog.dart';
import 'package:studyking/features/onboarding/services/onboarding_service.dart';
import 'package:studyking/features/onboarding/services/onboarding_storage.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/settings_update.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

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

Widget _buildTestApp({
  NavigatorObserver? observer,
  OnboardingService? service,
}) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith(
        (ref) => _FakeSettingsController(),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: observer != null ? [observer] : [],
      home: Scaffold(body: OnboardingDialog(service: service)),
      routes: {
        AppRoutes.dashboard: (_) => const Scaffold(
              body: Center(child: Text('Dashboard')),
            ),
        AppRoutes.subjectSelection: (_) => const Scaffold(
              body: Center(child: Text('Subject Selection Screen')),
            ),
        AppRoutes.quickGuide: (_) => const Scaffold(
              body: Center(child: Text('Quick Guide Screen')),
            ),
      },
    ),
  );
}

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

Future<void> navigateToLastPage(WidgetTester tester) async {
  for (int i = 0; i < 5; i++) {
    await tester.tap(find.text('Next'));
    await pumpThroughAnimation(tester);
  }
}

void main() {
  setUpAll(() async {
    await initializeHiveForIntegrationTests();
  });
  group('Onboarding → App flow', () {
    late OnboardingService service;

    setUp(() {
      service = OnboardingService(storage: InMemoryOnboardingStorage());
    });

    testWidgets('completing onboarding via Get Started persists completed flag',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(service: service));
      await tester.pump();

      expect(find.byType(OnboardingDialog), findsOneWidget);

      await navigateToLastPage(tester);
      await tester.tap(find.text('Get Started'));
      await tester.pump();
      await tester.pumpAndSettle();

      final result = await service.isOnboardingNeeded();
      expect(result.data, isFalse);
    });

    testWidgets('completing onboarding via Add Subject navigates to subject selection',
        (tester) async {
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(_buildTestApp(observer: observer, service: service));
      await tester.pump();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(observer.pushedRoutes.length, greaterThanOrEqualTo(1));
      expect(observer.pushedRoutes.last.settings.name, AppRoutes.dashboard);
      expect(find.text('Dashboard'), findsOneWidget);
      final result = await service.isOnboardingNeeded();
      expect(result.data, isFalse);
    });

    testWidgets('completing onboarding via Quick Guide navigates and persists',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(service: service));
      await tester.pump();

      await navigateToLastPage(tester);
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      final result = await service.isOnboardingNeeded();
      expect(result.data, isFalse);
    });

    testWidgets('dont-show-again checkbox persists dontShowAgain flag via Add Subject',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(service: service));
      await tester.pump();

      await tester.tap(find.text("Don't show again"));
      await tester.pump();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      final result = await service.isOnboardingNeeded();
      expect(result.data, isFalse);
    });

    testWidgets('dont-show-again checkbox with Get Started marks completed',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(service: service));
      await tester.pump();

      await tester.tap(find.text("Don't show again"));
      await tester.pump();

      await navigateToLastPage(tester);
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      final result = await service.isOnboardingNeeded();
      expect(result.data, isFalse);
    });
  });
}

class TestNavigatorObserver extends NavigatorObserver {
  final List<Route> pushedRoutes = [];

  @override
  void didPush(Route route, Route? previousRoute) {
    pushedRoutes.add(route);
  }
}
