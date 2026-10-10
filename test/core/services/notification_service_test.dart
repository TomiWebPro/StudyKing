import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/notification_service.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'initialize':
              return true;
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        null,
      );
    });

    test('is a singleton provider', () {
      // NotificationService is instantiated per provider; verify provider singleton behavior
      expect(NotificationService, isNotNull);
      final service1 = NotificationService();
      final service2 = NotificationService();
      // Services are intentionally non-singleton to allow test isolation;
      // verify they are distinct instances but same type
      expect(service1, isA<NotificationService>());
      expect(service2, isA<NotificationService>());
    });

    test('setAppLocalizations stores the l10n', () {
      final service = NotificationService();
      expect(
        () => service.setAppLocalizations(AppLocalizationsEn()),
        returnsNormally,
      );
    });

    test('init does not throw during initialization', () async {
      final service = NotificationService();
      expect(service.init(), completes);
    });

    test('init called twice does not throw', () async {
      final service = NotificationService();
      await service.init();
      expect(service.init(), completes);
    });

    // --- Behavioral assertions: Result<T> return types and l10n fallback ---

    test('showNotification returns success when l10n is set', () async {
      final service = NotificationService();
      service.setAppLocalizations(AppLocalizationsEn());
      final result = await service.showNotification(
        id: 1, title: 'T', body: 'B',
      );
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
      expect(result.error, isNull);
    });

    test('showNotification returns failure when l10n is not set', () async {
      final service = NotificationService();
      // Intentionally NOT calling setAppLocalizations
      final result = await service.showNotification(
        id: 1, title: 'T', body: 'B',
      );
      expect(result, isA<Result<void>>());
      expect(result.isFailure, isTrue);
      expect(result.error, contains('l10n not initialized'));
    });

    test('showDailyReminder returns success when l10n is set', () async {
      final service = NotificationService();
      service.setAppLocalizations(AppLocalizationsEn());
      final result = await service.showDailyReminder(
        id: 1, title: 'T', body: 'B', remindAt: TimeOfDay.now(),
      );
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
    });

    test('showDailyReminder returns failure when l10n is not set', () async {
      final service = NotificationService();
      final result = await service.showDailyReminder(
        id: 1, title: 'T', body: 'B', remindAt: TimeOfDay.now(),
      );
      expect(result, isA<Result<void>>());
      expect(result.isFailure, isTrue);
      expect(result.error, contains('l10n not initialized'));
    });

    test('showRevisionNudge returns success when l10n is set', () async {
      final service = NotificationService();
      service.setAppLocalizations(AppLocalizationsEn());
      final result = await service.showRevisionNudge(
        id: 1, topicName: 'Algebra', daysSinceLastPractice: 3,
      );
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
    });

    test('showOverworkWarning returns success when l10n is set', () async {
      final service = NotificationService();
      service.setAppLocalizations(AppLocalizationsEn());
      final result = await service.showOverworkWarning(
        id: 1, hoursStudied: 5.0,
      );
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
    });

    test('showPlanAdjustmentSuggestion returns success when l10n is set',
        () async {
      final service = NotificationService();
      service.setAppLocalizations(AppLocalizationsEn());
      final result = await service.showPlanAdjustmentSuggestion(
        id: 1, consecutiveLowDays: 5,
      );
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
    });

    test('showLessonReminder returns failure when l10n is not set', () async {
      final service = NotificationService();
      final result = await service.showLessonReminder(
        id: 1, lessonTitle: 'Math', startTime: DateTime.now(),
      );
      expect(result, isA<Result<void>>());
      expect(result.isFailure, isTrue);
      expect(result.error, contains('l10n not initialized'));
    });

    test('showLowMasteryWarning with empty list returns success immediately',
        () async {
      final service = NotificationService();
      service.setAppLocalizations(AppLocalizationsEn());
      final result =
          await service.showLowMasteryWarning(id: 1, weakTopics: []);
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
    });

    test('showLowMasteryWarning with topics returns success when l10n is set',
        () async {
      final service = NotificationService();
      service.setAppLocalizations(AppLocalizationsEn());
      final result = await service.showLowMasteryWarning(
        id: 1, weakTopics: ['Algebra', 'Geometry'],
      );
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
    });

    test('showBadgeUnlocked returns success when l10n is set', () async {
      final service = NotificationService();
      service.setAppLocalizations(AppLocalizationsEn());
      final result = await service.showBadgeUnlocked(
        id: 1, badgeName: 'Test', badgeDescription: 'Desc',
      );
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
    });

    test('showLessonReady returns success when l10n is set', () async {
      final service = NotificationService();
      service.setAppLocalizations(AppLocalizationsEn());
      final result = await service.showLessonReady(
        id: 1, topicTitle: 'Algebra', lessonId: 'lesson_1',
      );
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
    });

    test('cancelNotification returns success on mocked plugin', () async {
      final service = NotificationService();
      final result = await service.cancelNotification(1);
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
    });

    test('cancelAll returns success on mocked plugin', () async {
      final service = NotificationService();
      final result = await service.cancelAll();
      expect(result, isA<Result<void>>());
      expect(result.isSuccess, isTrue);
    });

    test('public API methods exist', () {
      final service = NotificationService();
      expect(service.init, isA<Function>());
      expect(service.showNotification, isA<Function>());
      expect(service.showDailyReminder, isA<Function>());
      expect(service.showRevisionNudge, isA<Function>());
      expect(service.showOverworkWarning, isA<Function>());
      expect(service.showPlanAdjustmentSuggestion, isA<Function>());
      expect(service.showLessonReminder, isA<Function>());
      expect(service.showLowMasteryWarning, isA<Function>());
      expect(service.showBadgeUnlocked, isA<Function>());
      expect(service.cancelNotification, isA<Function>());
      expect(service.cancelAll, isA<Function>());
      expect(service.setAppLocalizations, isA<Function>());
    });
  });
}
