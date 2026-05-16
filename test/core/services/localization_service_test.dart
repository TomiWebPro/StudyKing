import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/utils/localization_helpers.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';

void main() {
  late AppLocalizationsEn l10n;

  setUp(() {
    l10n = AppLocalizationsEn();
  });

  group('badgeName', () {
    test('returns name for known badge IDs', () {
      expect(badgeName('first_attempt', l10n), equals(l10n.badgeFirstStepName));
      expect(badgeName('century', l10n), equals(l10n.badgeCenturyClubName));
      expect(badgeName('accuracy_gold', l10n), equals(l10n.badgeAccuracyGoldName));
      expect(badgeName('daily_streak', l10n), equals(l10n.badgeDailyScholarName));
      expect(badgeName('ten_hours', l10n), equals(l10n.badgeDedicatedLearnerName));
      expect(badgeName('week_streak', l10n), equals(l10n.badgeWeeklyWarriorName));
    });

    test('returns badgeId for unknown badge', () {
      expect(badgeName('unknown_badge', l10n), equals('unknown_badge'));
    });
  });

  group('badgeDescription', () {
    test('returns description for known badge IDs', () {
      expect(badgeDescription('first_attempt', l10n), equals(l10n.badgeFirstStepDesc));
      expect(badgeDescription('century', l10n), equals(l10n.badgeCenturyClubDesc));
      expect(badgeDescription('accuracy_gold', l10n), equals(l10n.badgeAccuracyGoldDesc));
      expect(badgeDescription('daily_streak', l10n), equals(l10n.badgeDailyScholarDesc));
      expect(badgeDescription('ten_hours', l10n), equals(l10n.badgeDedicatedLearnerDesc));
      expect(badgeDescription('week_streak', l10n), equals(l10n.badgeWeeklyWarriorDesc));
    });

    test('returns empty string for unknown badge', () {
      expect(badgeDescription('unknown', l10n), equals(''));
    });
  });

  group('planRecommendationReason', () {
    test('returns correct values based on accuracy', () {
      expect(planRecommendationReason(0.95, 0.0, l10n), equals(l10n.planHighMastery));
      expect(planRecommendationReason(0.85, 0.0, l10n), equals(l10n.planGoodProgress));
      expect(planRecommendationReason(0.7, 0.0, l10n), equals(l10n.planDeveloping));
      expect(planRecommendationReason(0.5, 0.8, l10n), equals(l10n.planAtRisk));
      expect(planRecommendationReason(0.5, 0.5, l10n), equals(l10n.planNeedsAttention));
    });
  });

  group('planFocusLabel', () {
    test('returns correct labels', () {
      expect(planFocusLabel(isEmpty: true, weakRatio: 0.0, l10n: l10n), equals(l10n.planGeneralReview));
      expect(planFocusLabel(isEmpty: false, weakRatio: 0.8, l10n: l10n), equals(l10n.planFocusWeakAreas));
      expect(planFocusLabel(isEmpty: false, weakRatio: 0.3, l10n: l10n), equals(l10n.planPracticeAndReview));
    });
  });
}
