import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/onboarding/presentation/onboarding_dialog.dart';
import 'package:studyking/features/onboarding/services/onboarding_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp({NavigatorObserver? observer}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    navigatorObservers: observer != null ? [observer] : [],
    home: const OnboardingDialog(),
    routes: {
      AppRoutes.subjectSelection: (_) => const Scaffold(
            body: Center(child: Text('Subject Selection Screen')),
          ),
      AppRoutes.quickGuide: (_) => const Scaffold(
            body: Center(child: Text('Quick Guide Screen')),
          ),
    },
  );
}

void main() {
  group('Onboarding → App flow', () {
    setUp(() {
      OnboardingService.setTestStorage({});
    });

    tearDown(() {
      OnboardingService.setTestStorage(null);
    });

    testWidgets('completing onboarding via Get Started persists completed flag',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.byType(OnboardingDialog), findsOneWidget);

      await tester.tap(find.text('Get Started'));
      await tester.pump();

      expect(await OnboardingService.isOnboardingNeeded(), isFalse);
    });

    testWidgets('completing onboarding via Add Subject navigates to subject selection',
        (tester) async {
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(_buildTestApp(observer: observer));
      await tester.pump();

      await tester.tap(find.text('Add Subject'));
      await tester.pumpAndSettle();

      expect(observer.pushedRoutes.length, greaterThanOrEqualTo(1));
      expect(observer.pushedRoutes.last.settings.name, AppRoutes.subjectSelection);
      expect(find.text('Subject Selection Screen'), findsOneWidget);
      expect(await OnboardingService.isOnboardingNeeded(), isFalse);
    });

    testWidgets('completing onboarding via Quick Guide navigates and persists',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.tap(find.text('Quick Guide'));
      await tester.pumpAndSettle();

      expect(find.text('Quick Guide Screen'), findsOneWidget);
      expect(await OnboardingService.isOnboardingNeeded(), isFalse);
    });

    testWidgets('dont-show-again checkbox persists dontShowAgain flag via Add Subject',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.tap(find.text("Don't show again"));
      await tester.pump();

      await tester.tap(find.text('Add Subject'));
      await tester.pumpAndSettle();

      expect(await OnboardingService.isOnboardingNeeded(), isFalse);
    });

    testWidgets('dont-show-again checkbox with Get Started marks completed',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.tap(find.text("Don't show again"));
      await tester.pump();

      await tester.tap(find.text('Get Started'));
      await tester.pump();

      expect(await OnboardingService.isOnboardingNeeded(), isFalse);
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
