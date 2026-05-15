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
      _l10n.notificationTimeToReviewTitle;

  String notificationTimeToReviewBody(int days, String topic) =>
      _l10n.notificationTimeToReviewBody(days, topic);

  String notificationTakeABreakTitle() => _l10n.notificationTakeABreakTitle;

  String notificationTakeABreakBody(String hours) =>
      _l10n.notificationTakeABreakBody(hours);

  String notificationPlanAdjustmentTitle() =>
      _l10n.notificationPlanAdjustmentTitle;

  String notificationPlanAdjustmentBody(int days) =>
      _l10n.notificationPlanAdjustmentBody(days);

  String notificationUpcomingLessonTitle() =>
      _l10n.notificationUpcomingLessonTitle;

  String notificationUpcomingLessonBody(String lesson, String time) =>
      _l10n.notificationUpcomingLessonBody(lesson, time);

  String notificationTopicsNeedAttentionTitle() =>
      _l10n.notificationTopicsNeedAttentionTitle;

  String notificationTopicsNeedAttentionBody(String topics) =>
      _l10n.notificationTopicsNeedAttentionBody(topics);

  String notificationBadgeUnlockedTitle() =>
      _l10n.notificationBadgeUnlockedTitle;

  String notificationBadgeUnlockedBody(
          String badge, String description) =>
      _l10n.notificationBadgeUnlockedBody(badge, description);

  String channelGeneralName() => _l10n.notificationChannelGeneralName;

  String channelGeneralDesc() => _l10n.notificationChannelGeneralDesc;

  String channelDailyReminderName() =>
      _l10n.notificationChannelDailyReminderName;

  String channelDailyReminderDesc() =>
      _l10n.notificationChannelDailyReminderDesc;

  String channelRevisionName() => _l10n.notificationChannelRevisionName;

  String channelRevisionDesc() => _l10n.notificationChannelRevisionDesc;

  String channelWellbeingName() => _l10n.notificationChannelWellbeingName;

  String channelWellbeingDesc() => _l10n.notificationChannelWellbeingDesc;

  String channelPlanningName() => _l10n.notificationChannelPlanningName;

  String channelPlanningDesc() => _l10n.notificationChannelPlanningDesc;

  String channelLessonsName() => _l10n.notificationChannelLessonsName;

  String channelLessonsDesc() => _l10n.notificationChannelLessonsDesc;

  String channelMasteryName() => _l10n.notificationChannelMasteryName;

  String channelMasteryDesc() => _l10n.notificationChannelMasteryDesc;

  String channelBadgesName() => _l10n.notificationChannelBadgesName;

  String channelBadgesDesc() => _l10n.notificationChannelBadgesDesc;

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

  String recommendationAccuracyLow() => _l10n.recommendationAccuracyLow;

  String recommendationReviewBasics() => _l10n.recommendationReviewBasics;

  String recommendationExcellentProgress() =>
      _l10n.recommendationExcellentProgress;

  String recommendationChallengingPractice() =>
      _l10n.recommendationChallengingPractice;

  String recommendationLowHours() => _l10n.recommendationLowHours;

  String recommendationSetDailyGoal() => _l10n.recommendationSetDailyGoal;

  String recommendationNoActivity() => _l10n.recommendationNoActivity;

  String recommendationQuickReview() => _l10n.recommendationQuickReview;

  String recommendationWeakTopics(int count) =>
      _l10n.recommendationWeakTopics(count);

  String recommendationReviewWithTutor() =>
      _l10n.recommendationReviewWithTutor;

  String suggestionFundamentals() => _l10n.suggestionFundamentals;

  String suggestionPractice() => _l10n.suggestionPractice;

  String suggestionAdvanced() => _l10n.suggestionAdvanced;

  String shareSessionsText() => _l10n.shareSessionsText;
}
