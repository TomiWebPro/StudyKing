import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/localization_service.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';

void main() {
  late AppLocalizationsEn l10n;
  late LocalizationService service;

  setUp(() {
    l10n = AppLocalizationsEn();
    service = LocalizationService(l10n);
  });

  group('badgeName', () {
    test('returns name for known badge IDs', () {
      expect(service.badgeName('first_attempt'), equals(l10n.badgeFirstStepName));
      expect(service.badgeName('century'), equals(l10n.badgeCenturyClubName));
      expect(service.badgeName('accuracy_gold'), equals(l10n.badgeAccuracyGoldName));
      expect(service.badgeName('daily_streak'), equals(l10n.badgeDailyScholarName));
      expect(service.badgeName('ten_hours'), equals(l10n.badgeDedicatedLearnerName));
      expect(service.badgeName('week_streak'), equals(l10n.badgeWeeklyWarriorName));
    });

    test('returns badgeId for unknown badge', () {
      expect(service.badgeName('unknown_badge'), equals('unknown_badge'));
    });
  });

  group('badgeDescription', () {
    test('returns description for known badge IDs', () {
      expect(service.badgeDescription('first_attempt'), equals(l10n.badgeFirstStepDesc));
      expect(service.badgeDescription('century'), equals(l10n.badgeCenturyClubDesc));
      expect(service.badgeDescription('accuracy_gold'), equals(l10n.badgeAccuracyGoldDesc));
      expect(service.badgeDescription('daily_streak'), equals(l10n.badgeDailyScholarDesc));
      expect(service.badgeDescription('ten_hours'), equals(l10n.badgeDedicatedLearnerDesc));
      expect(service.badgeDescription('week_streak'), equals(l10n.badgeWeeklyWarriorDesc));
    });

    test('returns empty string for unknown badge', () {
      expect(service.badgeDescription('unknown'), equals(''));
    });
  });

  group('nudge methods', () {
    test('nudgeOverwork', () {
      expect(service.nudgeOverwork('5.5'), equals(l10n.nudgeOverwork('5.5')));
    });

    test('nudgeRevision', () {
      expect(service.nudgeRevision(3, 'Algebra'), equals(l10n.nudgeRevision(3, 'Algebra')));
    });

    test('nudgePlanAdjustment', () {
      expect(service.nudgePlanAdjustment(5), equals(l10n.nudgePlanAdjustment(5)));
    });

    test('nudgeWeeklyDigest', () {
      final result = service.nudgeWeeklyDigest(
        weeklyActivity: 10, accuracy: 85, totalHours: '12.5', weakCount: 3, badgeCount: 5,
      );
      expect(result, equals(l10n.nudgeWeeklyDigest(10, 85, '12.5', 3, 5)));
    });
  });

  group('notification methods', () {
    test('notificationTimeToReviewTitle', () {
      expect(service.notificationTimeToReviewTitle(), equals(l10n.notifTitleTimeToReview));
    });

    test('notificationTimeToReviewBody', () {
      expect(service.notificationTimeToReviewBody(2, 'Math'), equals(l10n.notificationTimeToReviewBody(2, 'Math')));
    });

    test('notificationTakeABreakTitle', () {
      expect(service.notificationTakeABreakTitle(), equals(l10n.notifTitleTakeBreak));
    });

    test('notificationTakeABreakBody', () {
      expect(service.notificationTakeABreakBody('3.0'), equals(l10n.notifBodyOverwork('3.0')));
    });

    test('notificationUpcomingLessonTitle', () {
      expect(service.notificationUpcomingLessonTitle(), equals(l10n.notifTitleUpcomingLesson));
    });

    test('notificationBadgeUnlockedTitle', () {
      expect(service.notificationBadgeUnlockedTitle(), equals(l10n.notifTitleBadgeUnlocked));
    });
  });

  group('channel methods', () {
    test('channelGeneralName', () {
      expect(service.channelGeneralName(), equals(l10n.notifChannelGeneral));
    });

    test('channelBadgesDesc', () {
      expect(service.channelBadgesDesc(), equals(l10n.notifChannelBadgesDesc));
    });
  });

  group('plan methods', () {
    test('planRecommendationReason returns correct values based on accuracy', () {
      expect(service.planRecommendationReason(0.95, 0.0), equals(l10n.planHighMastery));
      expect(service.planRecommendationReason(0.85, 0.0), equals(l10n.planGoodProgress));
      expect(service.planRecommendationReason(0.7, 0.0), equals(l10n.planDeveloping));
      expect(service.planRecommendationReason(0.5, 0.8), equals(l10n.planAtRisk));
      expect(service.planRecommendationReason(0.5, 0.5), equals(l10n.planNeedsAttention));
    });

    test('planFocusLabel returns correct labels', () {
      expect(service.planFocusLabel(isEmpty: true, weakRatio: 0.0), equals(l10n.planGeneralReview));
      expect(service.planFocusLabel(isEmpty: false, weakRatio: 0.8), equals(l10n.planFocusWeakAreas));
      expect(service.planFocusLabel(isEmpty: false, weakRatio: 0.3), equals(l10n.planPracticeAndReview));
    });
  });

  group('adherence methods', () {
    test('adherenceLowDaysAdjust', () {
      expect(service.adherenceLowDaysAdjust(3), equals(l10n.adherenceLowDaysAdjust(3)));
    });

    test('adherenceLowDaysRegenerate', () {
      expect(service.adherenceLowDaysRegenerate(7), equals(l10n.adherenceLowDaysRegenerate(7)));
    });
  });

  group('recommendation methods', () {
    test('recommendationWeakTopics', () {
      expect(service.recommendationWeakTopics(5), equals(l10n.recommendWeakTopics(5)));
    });

    test('other recommendation methods return correct strings', () {
      expect(service.recommendationAccuracyLow(), equals(l10n.recommendAccuracyBelow60));
      expect(service.recommendationReviewBasics(), equals(l10n.recommendReviewBasics));
      expect(service.recommendationExcellentProgress(), equals(l10n.recommendAccuracyExcellent));
    });
  });

  group('suggestion methods', () {
    test('suggestionFundamentals', () {
      expect(service.suggestionFundamentals(), equals(l10n.adapSuggestionFundamentals));
    });

    test('suggestionPractice', () {
      expect(service.suggestionPractice(), equals(l10n.adapSuggestionMorePractice));
    });

    test('suggestionAdvanced', () {
      expect(service.suggestionAdvanced(), equals(l10n.adapSuggestionAdvancedTopics));
    });
  });

  test('l10n getter returns underlying AppLocalizations', () {
    expect(service.l10n, same(l10n));
  });
}
