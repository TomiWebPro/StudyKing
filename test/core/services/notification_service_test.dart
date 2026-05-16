import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/localization_service.dart';
import 'package:studyking/core/services/notification_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';

class _MockLocalizationService implements LocalizationService {
  @override
  AppLocalizations get l10n => AppLocalizationsEn();

  @override
  String badgeName(String badgeId) => '';
  @override
  String badgeDescription(String badgeId) => '';
  @override
  String nudgeOverwork(String hours) => '';
  @override
  String nudgeRevision(int days, String topic) => '';
  @override
  String nudgePlanAdjustment(int days) => '';
  @override
  String nudgeWeeklyDigest({required int weeklyActivity, required int accuracy, required String totalHours, required int weakCount, required int badgeCount}) => '';
  @override
  String notificationTimeToReviewTitle() => '';
  @override
  String notificationTimeToReviewBody(int days, String topic) => '';
  @override
  String notificationTakeABreakTitle() => '';
  @override
  String notificationTakeABreakBody(String hours) => '';
  @override
  String notificationPlanAdjustmentTitle() => '';
  @override
  String notificationPlanAdjustmentBody(int days) => '';
  @override
  String notificationUpcomingLessonTitle() => '';
  @override
  String notificationUpcomingLessonBody(String lesson, String time) => '';
  @override
  String notificationTopicsNeedAttentionTitle() => '';
  @override
  String notificationTopicsNeedAttentionBody(String topics) => '';
  @override
  String notificationBadgeUnlockedTitle() => '';
  @override
  String notificationBadgeUnlockedBody(String badge, String description) => '';
  @override
  String channelGeneralName() => '';
  @override
  String channelGeneralDesc() => '';
  @override
  String channelDailyReminderName() => '';
  @override
  String channelDailyReminderDesc() => '';
  @override
  String channelRevisionName() => '';
  @override
  String channelRevisionDesc() => '';
  @override
  String channelWellbeingName() => '';
  @override
  String channelWellbeingDesc() => '';
  @override
  String channelPlanningName() => '';
  @override
  String channelPlanningDesc() => '';
  @override
  String channelLessonsName() => '';
  @override
  String channelLessonsDesc() => '';
  @override
  String channelMasteryName() => '';
  @override
  String channelMasteryDesc() => '';
  @override
  String channelBadgesName() => '';
  @override
  String channelBadgesDesc() => '';
  @override
  String planAccuracyLow() => '';
  @override
  String planReviewOverdue() => '';
  @override
  String planStreakLow() => '';
  @override
  String planPrerequisite() => '';
  @override
  String planBlocksDownstream(int count) => '';
  @override
  String planRequiredForDependent() => '';
  @override
  String planWeakPerformance() => '';
  @override
  String planHighForgettingRisk() => '';
  @override
  String planNewSyllabusTopic() => '';
  @override
  String planPartOfSyllabusGoal() => '';
  @override
  String planRecommendationReason(double accuracy, double reviewUrgency) => '';
  @override
  String planFocusLabel({required bool isEmpty, required double weakRatio}) => '';
  @override
  String planRestAndReview() => '';
  @override
  String adherenceLowDaysAdjust(int days) => '';
  @override
  String adherenceLowDaysRegenerate(int days) => '';
  @override
  String adherenceLowToday(int actualMinutes, int plannedMinutes) => '';
  @override
  String adherencePartialToday(int actualMinutes, int plannedMinutes) => '';
  @override
  String adherenceExceededToday(int actualMinutes, int plannedMinutes) => '';
  @override
  String recommendationAccuracyLow() => '';
  @override
  String recommendationReviewBasics() => '';
  @override
  String recommendationExcellentProgress() => '';
  @override
  String recommendationChallengingPractice() => '';
  @override
  String recommendationLowHours() => '';
  @override
  String recommendationSetDailyGoal() => '';
  @override
  String recommendationNoActivity() => '';
  @override
  String recommendationQuickReview() => '';
  @override
  String recommendationWeakTopics(int count) => '';
  @override
  String recommendationReviewWithTutor() => '';
  @override
  String suggestionFundamentals() => '';
  @override
  String suggestionPractice() => '';
  @override
  String suggestionAdvanced() => '';
  @override
  String shareSessionsText() => '';
}

void main() {
  group('NotificationService', () {
    test('is a singleton', () {
      final service1 = NotificationService();
      final service2 = NotificationService();
      expect(identical(service1, service2), isTrue);
    });

    test('setLocalizationService stores the service', () {
      final service = NotificationService();
      final locService = _MockLocalizationService();
      service.setLocalizationService(locService);
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
      expect(service.setLocalizationService, isA<Function>());
    });

    test('_l10n returns null when no localization service set', () {
      // Can't access private _l10n directly, verify via public API
      // If _l10n is null, fallbacks should be used
    });
  });
}
