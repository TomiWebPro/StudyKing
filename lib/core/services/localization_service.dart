import '../../l10n/generated/app_localizations.dart';

class LocalizationService {
  final AppLocalizations _l10n;

  LocalizationService(this._l10n);

  AppLocalizations get l10n => _l10n;

  String badgeName(String badgeId) {
    return switch (badgeId) {
      'first_attempt' => _l10n.badgeFirstStepName,
      'century' => _l10n.badgeCenturyClubName,
      'accuracy_gold' => _l10n.badgeAccuracyGoldName,
      'daily_streak' => _l10n.badgeDailyScholarName,
      'ten_hours' => _l10n.badgeDedicatedLearnerName,
      'week_streak' => _l10n.badgeWeeklyWarriorName,
      _ => badgeId,
    };
  }

  String badgeDescription(String badgeId) {
    return switch (badgeId) {
      'first_attempt' => _l10n.badgeFirstStepDesc,
      'century' => _l10n.badgeCenturyClubDesc,
      'accuracy_gold' => _l10n.badgeAccuracyGoldDesc,
      'daily_streak' => _l10n.badgeDailyScholarDesc,
      'ten_hours' => _l10n.badgeDedicatedLearnerDesc,
      'week_streak' => _l10n.badgeWeeklyWarriorDesc,
      _ => '',
    };
  }

  String nudgeOverwork(String hours) => _l10n.nudgeOverwork(hours);

  String nudgeRevision(int days, String topic) =>
      _l10n.nudgeRevision(days, topic);

  String nudgePlanAdjustment(int days) =>
      _l10n.nudgePlanAdjustment(days);

  String nudgeWeeklyDigest({
    required int weeklyActivity,
    required int accuracy,
    required String totalHours,
    required int weakCount,
    required int badgeCount,
  }) =>
      _l10n.nudgeWeeklyDigest(
        weeklyActivity,
        accuracy,
        totalHours,
        weakCount,
        badgeCount,
      );

  String notificationTimeToReviewTitle() =>
      _l10n.notifTitleTimeToReview;

  String notificationTimeToReviewBody(int days, String topic) =>
      _l10n.notificationTimeToReviewBody(days, topic);

  String notificationTakeABreakTitle() => _l10n.notifTitleTakeBreak;

  String notificationTakeABreakBody(String hours) =>
      _l10n.notifBodyOverwork(hours);

  String notificationPlanAdjustmentTitle() =>
      _l10n.notifTitlePlanAdjustment;

  String notificationPlanAdjustmentBody(int days) =>
      _l10n.notifBodyPlanAdjustment(days);

  String notificationUpcomingLessonTitle() =>
      _l10n.notifTitleUpcomingLesson;

  String notificationUpcomingLessonBody(String lesson, String time) =>
      _l10n.notificationUpcomingLessonBody(lesson, time);

  String notificationTopicsNeedAttentionTitle() =>
      _l10n.notifTitleTopicsNeedAttention;

  String notificationTopicsNeedAttentionBody(String topics) =>
      _l10n.notifBodyLowMastery(topics);

  String notificationBadgeUnlockedTitle() =>
      _l10n.notifTitleBadgeUnlocked;

  String notificationBadgeUnlockedBody(
          String badge, String description) =>
      _l10n.notificationBadgeUnlockedBody(badge, description);

  String channelGeneralName() => _l10n.notifChannelGeneral;

  String channelGeneralDesc() => _l10n.notifChannelGeneralDesc;

  String channelDailyReminderName() =>
      _l10n.notifChannelDailyReminder;

  String channelDailyReminderDesc() =>
      _l10n.notifChannelDailyReminderDesc;

  String channelRevisionName() => _l10n.notifChannelRevision;

  String channelRevisionDesc() => _l10n.notifChannelRevisionDesc;

  String channelWellbeingName() => _l10n.notifChannelWellbeing;

  String channelWellbeingDesc() => _l10n.notifChannelWellbeingDesc;

  String channelPlanningName() => _l10n.notifChannelPlanning;

  String channelPlanningDesc() => _l10n.notifChannelPlanningDesc;

  String channelLessonsName() => _l10n.notifChannelLessons;

  String channelLessonsDesc() => _l10n.notifChannelLessonsDesc;

  String channelMasteryName() => _l10n.notifChannelMastery;

  String channelMasteryDesc() => _l10n.notifChannelMasteryDesc;

  String channelBadgesName() => _l10n.notifChannelBadges;

  String channelBadgesDesc() => _l10n.notifChannelBadgesDesc;

  String planAccuracyLow() => _l10n.planAccuracyLow;

  String planReviewOverdue() => _l10n.planReviewOverdue;

  String planStreakLow() => _l10n.planStreakLow;

  String planPrerequisite() => _l10n.planPrerequisite;

  String planBlocksDownstream(int count) =>
      _l10n.planBlocksDownstream(count);

  String planRequiredForDependent() => _l10n.planRequiredForDependent;

  String planWeakPerformance() => _l10n.planWeakPerformance;

  String planHighForgettingRisk() => _l10n.planHighForgettingRisk;

  String planNewSyllabusTopic() => _l10n.planNewSyllabusTopic;

  String planPartOfSyllabusGoal() => _l10n.planPartOfSyllabusGoal;

  String planRecommendationReason(double accuracy, double reviewUrgency) {
    if (accuracy >= 0.9) return _l10n.planHighMastery;
    if (accuracy >= 0.8) return _l10n.planGoodProgress;
    if (accuracy >= 0.6) return _l10n.planDeveloping;
    if (reviewUrgency > 0.7) return _l10n.planAtRisk;
    return _l10n.planNeedsAttention;
  }

  String planFocusLabel({
    required bool isEmpty,
    required double weakRatio,
  }) {
    if (isEmpty) return _l10n.planGeneralReview;
    if (weakRatio > 0.5) return _l10n.planFocusWeakAreas;
    return _l10n.planPracticeAndReview;
  }

  String planRestAndReview() => _l10n.planRestAndReview;

  String adherenceLowDaysAdjust(int days) =>
      _l10n.adherenceLowDaysAdjust(days);

  String adherenceLowDaysRegenerate(int days) =>
      _l10n.adherenceLowDaysRegenerate(days);

  String adherenceLowToday(int actualMinutes, int plannedMinutes) =>
      _l10n.adherenceLowToday(actualMinutes, plannedMinutes);

  String adherencePartialToday(int actualMinutes, int plannedMinutes) =>
      _l10n.adherencePartialToday(actualMinutes, plannedMinutes);

  String adherenceExceededToday(int actualMinutes, int plannedMinutes) =>
      _l10n.adherenceExceededToday(actualMinutes, plannedMinutes);

  String recommendationAccuracyLow() => _l10n.recommendAccuracyBelow60;

  String recommendationReviewBasics() => _l10n.recommendReviewBasics;

  String recommendationExcellentProgress() =>
      _l10n.recommendAccuracyExcellent;

  String recommendationChallengingPractice() =>
      _l10n.recommendChallengingQuestions;

  String recommendationLowHours() => _l10n.recommendConsistency;

  String recommendationSetDailyGoal() => _l10n.recommendSetDailyGoal;

  String recommendationNoActivity() => _l10n.recommendNoActivity;

  String recommendationQuickReview() => _l10n.recommendQuickReview;

  String recommendationWeakTopics(int count) =>
      _l10n.recommendWeakTopics(count);

  String recommendationReviewWithTutor() =>
      _l10n.recommendAiTutor;

  String suggestionFundamentals() => _l10n.adapSuggestionFundamentals;

  String suggestionPractice() => _l10n.adapSuggestionMorePractice;

  String suggestionAdvanced() => _l10n.adapSuggestionAdvancedTopics;

  String shareSessionsText() => _l10n.shareSessionsText;
}
