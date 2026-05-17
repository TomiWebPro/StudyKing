import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/features/onboarding/presentation/onboarding_dialog.dart';
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
  late String hivePath;

  setUp(() async {
    hivePath = (await Directory.systemTemp.createTemp('onboarding_minimal_')).path;
    Hive.init(hivePath);
  });

  tearDown(() async {
    await Hive.close();
    if (hivePath.isNotEmpty) {
      await Directory(hivePath).delete(recursive: true);
    }
  });

  testWidgets('minimal onboarding test', (tester) async {
    await tester.pumpWidget(_buildTestApp(const OnboardingDialog()));
    await tester.pump();
    await tester.tap(find.text('Get Started'));
    await tester.pump();
    await tester.runAsync(() async {
      final box = await Hive.openBox(HiveBoxNames.settings);
      expect(box.get('onboarding_completed'), isTrue);
    });
  });
}
