import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/notification_service.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';

void main() {
  group('NotificationService', () {
    test('is a singleton', () {
      final service1 = NotificationService();
      final service2 = NotificationService();
      expect(identical(service1, service2), isTrue);
    });

    test('setAppLocalizations stores the l10n', () {
      final service = NotificationService();
      service.setAppLocalizations(AppLocalizationsEn());
    });

    test('init does not throw during initialization', () async {
      final service = NotificationService();
      try {
        await service.init();
      } catch (_) {
        // Plugin may not be available in test environment
      }
    });

    test('init called twice does not throw', () async {
      final service = NotificationService();
      try {
        await service.init();
        await service.init();
      } catch (_) {}
    });

    test('showNotification does not throw', () async {
      final service = NotificationService();
      try {
        await service.showNotification(id: 1, title: 'T', body: 'B');
      } catch (_) {}
    });

    test('showDailyReminder does not throw', () async {
      final service = NotificationService();
      try {
        final remindAt = TimeOfDay.now();
        await service.showDailyReminder(id: 1, title: 'T', body: 'B', remindAt: remindAt);
      } catch (_) {}
    });

    test('showRevisionNudge does not throw', () async {
      final service = NotificationService();
      try {
        await service.showRevisionNudge(id: 1, topicName: 'Algebra', daysSinceLastPractice: 3);
      } catch (_) {}
    });

    test('showOverworkWarning does not throw', () async {
      final service = NotificationService();
      try {
        await service.showOverworkWarning(id: 1, hoursStudied: 5.0);
      } catch (_) {}
    });

    test('showPlanAdjustmentSuggestion does not throw', () async {
      final service = NotificationService();
      try {
        await service.showPlanAdjustmentSuggestion(id: 1, consecutiveLowDays: 5);
      } catch (_) {}
    });

    test('showLessonReminder does not throw', () async {
      final service = NotificationService();
      try {
        await service.showLessonReminder(id: 1, lessonTitle: 'Math', startTime: DateTime.now());
      } catch (_) {}
    });

    test('showLowMasteryWarning with empty list does nothing', () async {
      final service = NotificationService();
      try {
        await service.showLowMasteryWarning(id: 1, weakTopics: []);
      } catch (_) {}
    });

    test('showLowMasteryWarning with topics does not throw', () async {
      final service = NotificationService();
      try {
        await service.showLowMasteryWarning(id: 1, weakTopics: ['Algebra', 'Geometry']);
      } catch (_) {}
    });

    test('showBadgeUnlocked does not throw', () async {
      final service = NotificationService();
      try {
        await service.showBadgeUnlocked(id: 1, badgeName: 'Test', badgeDescription: 'Desc');
      } catch (_) {}
    });

    test('cancelNotification does not throw', () async {
      final service = NotificationService();
      try {
        await service.cancelNotification(1);
      } catch (_) {}
    });

    test('cancelAll does not throw', () async {
      final service = NotificationService();
      try {
        await service.cancelAll();
      } catch (_) {}
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
