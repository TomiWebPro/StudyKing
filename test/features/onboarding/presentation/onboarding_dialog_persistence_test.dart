import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/onboarding/presentation/onboarding_dialog.dart';
import 'package:studyking/features/onboarding/services/onboarding_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget widget) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: widget),
  );
}

void main() {
  late Map<String, dynamic> storage;

  setUp(() {
    storage = <String, dynamic>{};
    OnboardingService.setTestStorage(storage);
  });

  tearDown(() {
    OnboardingService.setTestStorage(null);
  });

  testWidgets('minimal onboarding test', (tester) async {
    await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
    await tester.pump();
    await tester.tap(find.text('Get Started'));
    await tester.pump();

    expect(storage['onboarding_completed'], isTrue);
  });
}
