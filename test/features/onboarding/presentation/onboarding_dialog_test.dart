import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/features/onboarding/presentation/onboarding_dialog.dart';

void main() {
  late String hivePath;

  setUp(() async {
    hivePath = (await Directory.systemTemp.createTemp('onboarding_test_')).path;
    Hive.init(hivePath);
  });

  tearDown(() async {
    await Hive.close();
    if (hivePath.isNotEmpty) {
      await Directory(hivePath).delete(recursive: true);
    }
  });

  group('OnboardingService', () {
    test('isOnboardingNeeded returns true when no values set', () async {
      final needed = await OnboardingService.isOnboardingNeeded();
      expect(needed, isTrue);
    });

    test('isOnboardingNeeded returns false after markCompleted', () async {
      await OnboardingService.markCompleted();
      final needed = await OnboardingService.isOnboardingNeeded();
      expect(needed, isFalse);
    });

    test('isOnboardingNeeded returns false after markDontShowAgain', () async {
      await OnboardingService.markDontShowAgain();
      final needed = await OnboardingService.isOnboardingNeeded();
      expect(needed, isFalse);
    });

    test('markCompleted persists the completion flag', () async {
      await OnboardingService.markCompleted();
      final needed = await OnboardingService.isOnboardingNeeded();
      expect(needed, isFalse);
    });

    test('markDontShowAgain persists the dont-show flag', () async {
      await OnboardingService.markDontShowAgain();
      final needed = await OnboardingService.isOnboardingNeeded();
      expect(needed, isFalse);
    });

    test('isFirstLaunch returns true when onboarding not yet completed', () async {
      final firstLaunch = await OnboardingService.isFirstLaunch();
      expect(firstLaunch, isTrue);
    });

    test('isFirstLaunch returns false after markCompleted', () async {
      await OnboardingService.markCompleted();
      final firstLaunch = await OnboardingService.isFirstLaunch();
      expect(firstLaunch, isFalse);
    });

    test('isOnboardingNeeded respects completed flag independently', () async {
      await OnboardingService.markCompleted();
      final firstLaunch = await OnboardingService.isFirstLaunch();
      expect(firstLaunch, isFalse);
    });

    test('isOnboardingNeeded reads from Hive settings box', () async {
      final box = await Hive.openBox(HiveBoxNames.settings);
      await box.put('onboarding_completed', true);
      await box.close();
      final needed = await OnboardingService.isOnboardingNeeded();
      expect(needed, isFalse);
    });

    test('isFirstLaunch returns true after markDontShowAgain', () async {
      await OnboardingService.markDontShowAgain();
      final firstLaunch = await OnboardingService.isFirstLaunch();
      expect(firstLaunch, isTrue);
    });

    test('markCompleted stores true under onboarding_completed key', () async {
      await OnboardingService.markCompleted();
      final box = await Hive.openBox(HiveBoxNames.settings);
      expect(box.get('onboarding_completed'), isTrue);
      await box.close();
    });

    test('markDontShowAgain stores true under onboarding_dont_show_again key', () async {
      await OnboardingService.markDontShowAgain();
      final box = await Hive.openBox(HiveBoxNames.settings);
      expect(box.get('onboarding_dont_show_again'), isTrue);
      await box.close();
    });

    test('isOnboardingNeeded returns true when both flags explicitly false', () async {
      final box = await Hive.openBox(HiveBoxNames.settings);
      await box.put('onboarding_completed', false);
      await box.put('onboarding_dont_show_again', false);
      await box.close();
      final needed = await OnboardingService.isOnboardingNeeded();
      expect(needed, isTrue);
    });
  });
}
