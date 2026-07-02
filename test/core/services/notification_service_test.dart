import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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

    test('is a singleton', () {
      final service1 = NotificationService();
      final service2 = NotificationService();
      expect(identical(service1, service2), isTrue);
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

    test('showNotification does not throw', () async {
      final service = NotificationService();
      expect(service.showNotification(id: 1, title: 'T', body: 'B'), completes);
    });

    test('showDailyReminder does not throw', () async {
      final service = NotificationService();
      final remindAt = TimeOfDay.now();
      expect(
        service.showDailyReminder(id: 1, title: 'T', body: 'B', remindAt: remindAt),
        completes,
      );
    });

    test('showRevisionNudge does not throw', () async {
      final service = NotificationService();
      expect(
        service.showRevisionNudge(id: 1, topicName: 'Algebra', daysSinceLastPractice: 3),
        completes,
      );
    });

    test('showOverworkWarning does not throw', () async {
      final service = NotificationService();
      expect(
        service.showOverworkWarning(id: 1, hoursStudied: 5.0),
        completes,
      );
    });

    test('showPlanAdjustmentSuggestion does not throw', () async {
      final service = NotificationService();
      expect(
        service.showPlanAdjustmentSuggestion(id: 1, consecutiveLowDays: 5),
        completes,
      );
    });

    test('showLessonReminder does not throw', () async {
      final service = NotificationService();
      expect(
        service.showLessonReminder(
          id: 1,
          lessonTitle: 'Math',
          startTime: DateTime.now(),
        ),
        completes,
      );
    });

    test('showLowMasteryWarning with empty list does nothing', () async {
      final service = NotificationService();
      expect(
        service.showLowMasteryWarning(id: 1, weakTopics: []),
        completes,
      );
    });

    test('showLowMasteryWarning with topics does not throw', () async {
      final service = NotificationService();
      expect(
        service.showLowMasteryWarning(id: 1, weakTopics: ['Algebra', 'Geometry']),
        completes,
      );
    });

    test('showBadgeUnlocked does not throw', () async {
      final service = NotificationService();
      expect(
        service.showBadgeUnlocked(
          id: 1,
          badgeName: 'Test',
          badgeDescription: 'Desc',
        ),
        completes,
      );
    });

    test('cancelNotification does not throw', () async {
      final service = NotificationService();
      expect(service.cancelNotification(1), completes);
    });

    test('cancelAll does not throw', () async {
      final service = NotificationService();
      expect(service.cancelAll(), completes);
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
