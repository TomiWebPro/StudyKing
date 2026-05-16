import '../../l10n/generated/app_localizations.dart';

String badgeName(String badgeId, AppLocalizations l10n) {
  return switch (badgeId) {
    'first_attempt' => l10n.badgeFirstStepName,
    'century' => l10n.badgeCenturyClubName,
    'accuracy_gold' => l10n.badgeAccuracyGoldName,
    'daily_streak' => l10n.badgeDailyScholarName,
    'ten_hours' => l10n.badgeDedicatedLearnerName,
    'week_streak' => l10n.badgeWeeklyWarriorName,
    _ => badgeId,
  };
}

String badgeDescription(String badgeId, AppLocalizations l10n) {
  return switch (badgeId) {
    'first_attempt' => l10n.badgeFirstStepDesc,
    'century' => l10n.badgeCenturyClubDesc,
    'accuracy_gold' => l10n.badgeAccuracyGoldDesc,
    'daily_streak' => l10n.badgeDailyScholarDesc,
    'ten_hours' => l10n.badgeDedicatedLearnerDesc,
    'week_streak' => l10n.badgeWeeklyWarriorDesc,
    _ => '',
  };
}

String planRecommendationReason(double accuracy, double reviewUrgency, AppLocalizations l10n) {
  if (accuracy >= 0.9) return l10n.planHighMastery;
  if (accuracy >= 0.8) return l10n.planGoodProgress;
  if (accuracy >= 0.6) return l10n.planDeveloping;
  if (reviewUrgency > 0.7) return l10n.planAtRisk;
  return l10n.planNeedsAttention;
}

String planFocusLabel({
  required bool isEmpty,
  required double weakRatio,
  required AppLocalizations l10n,
}) {
  if (isEmpty) return l10n.planGeneralReview;
  if (weakRatio > 0.5) return l10n.planFocusWeakAreas;
  return l10n.planPracticeAndReview;
}
