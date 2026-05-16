# Internationalisation Master: Spanish Localisation Audit & Architecture Improvements

## Summary

The app has a solid foundation with Flutter's ARB-based l10n system (908 keys each in `app_en.arb` and `app_es.arb`), but contains structural issues that make adding new locales unnecessarily expensive and risk translation drift. This issue addresses three high-value improvements: deduplication of redundant keys, placeholder metadata fixes, and hardcoded string migration.

---

## Issue 1: 79 Groups of Duplicate Translation Keys (160 keys total)

### Context
Across both ARB files, 79 groups of keys share identical values. For example:
- `notifChannelBadges`, `notificationChannelBadgesName` → same value
- `planAccuracyLow`, `planExplanationAccuracyBelow60` → same value
- `adherenceLow7Days`, `adherenceLowDaysAdjust` → same value

### Rationale
Every duplicated key must be translated separately for each new locale. This doubles the translation budget for 160 keys and creates a maintenance liability: when one copy is updated, the other is forgotten, leading to inconsistent UI text.

### Affected files
- `lib/l10n/app_en.arb`
- `lib/l10n/app_es.arb`

### Action
Consolidate each group into a single key and update all Dart references. Key groups to merge (non-exhaustive):
| Keep | Remove |
|---|---|
| `aiTutor` | `teachingMode` |
| `planAccuracyLow` | `planExplanationAccuracyBelow60` |
| `planAtRisk` | `planExplanationAtRisk` |
| `planDeveloping` | `planExplanationDeveloping` |
| `planGoodProgress` | `planExplanationGoodProgress` |
| `planHighMastery` | `planExplanationHighMastery` |
| `planLowStreak` | `planExplanationLowStreak` |
| `planNeedsAttention` | `planExplanationNeedsAttention` |
| `planOverdueReview` | `planExplanationOverdueReview` |
| `planPrerequisite` | `planExplanationPrerequisite` |
| `adherenceLowDaysAdjust` | `adherenceLow7Days` |
| `adherenceLowDaysRegenerate` | `adherenceLow3Days` |
| `notifChannelGeneral` | `notificationChannelGeneralName` |
| `notifChannelGeneralDesc` | `notificationChannelGeneralDesc` |
| `notifChannelBadges` | `notificationChannelBadgesName` |
| `notifChannelMastery` | `notificationChannelMasteryName` |
| `notifChannelWellbeing` | `notificationChannelWellbeingName` |
| `notifChannelPlanning` | `notificationChannelPlanningName` |
| `notifChannelRevision` | `notificationChannelRevisionName` |
| `notifChannelLessons` | `notificationChannelLessonsName` / `lessonNotifications` |
| `notifChannelDailyReminder` | `notificationChannelDailyReminderName` |
| `notifChannelDailyReminderDesc` | `notificationChannelDailyReminderDesc` |
| `notifTitleTimeToReview` | `notificationTimeToReviewTitle` |
| `notifTitleTakeBreak` | `notificationTakeABreakTitle` |
| `notifBodyOverwork` | `notificationTakeABreakBody` |
| `notifTitlePlanAdjustment` | `notificationPlanAdjustmentTitle` |
| `notifBodyPlanAdjustment` | `notificationPlanAdjustmentBody` |
| `notifTitleUpcomingLesson` | `notificationUpcomingLessonTitle` |
| `notifTitleTopicsNeedAttention` | `notificationTopicsNeedAttentionTitle` |
| `notifBodyLowMastery` | `notificationTopicsNeedAttentionBody` |
| `notifTitleBadgeUnlocked` | `notificationBadgeUnlockedTitle` |
| `recommendAccuracyBelow60` | `recommendationAccuracyLow` |
| `recommendReviewBasics` | `recommendationReviewBasics` |
| `recommendAccuracyExcellent` | `recommendationExcellentProgress` |
| `recommendChallengingQuestions` | `recommendationChallengingPractice` |
| `recommendConsistency` | `recommendationLowHours` |
| `recommendSetDailyGoal` | `recommendationSetDailyGoal` |
| `recommendNoActivity` | `recommendationNoActivity` |
| `recommendQuickReview` | `recommendationQuickReview` |
| `recommendWeakTopics` | `recommendationWeakTopics` |
| `recommendAiTutor` | `recommendationReviewWithTutor` |
| `adapSuggestionFundamentals` | `suggestionFundamentals` |
| `adapSuggestionMorePractice` | `suggestionPractice` |
| `adapSuggestionAdvancedTopics` | `suggestionAdvanced` |

---

## Issue 2: Missing Placeholder Types in Adherence Keys (Both Locales)

### Context
Three keys in both `app_en.arb` and `app_es.arb` define `placeholders` with **empty type metadata**:

```
"adherenceLowToday": { "actualMinutes": {}, "plannedMinutes": {} }
"adherencePartialToday": { "actualMinutes": {}, "plannedMinutes": {} }
"adherenceExceededToday": { "actualMinutes": {}, "plannedMinutes": {} }
```

### Rationale
ARB placeholders must declare a `type` (e.g. `"type": "int"` or `"type": "String"`) for the Flutter codegen to handle them correctly. Empty brace objects will cause the codegen (`flutter gen-l10n`) to emit a warning or silently produce incorrect type signatures (`dynamic` instead of typed parameters).

### Affected files
- `lib/l10n/app_en.arb` (lines 4225-4226, 4233-4234, 4241-4242)
- `lib/l10n/app_es.arb` (lines 4225-4226, 4233-4234, 4241-4242)

### Action
Add `"type": "int"` to each placeholder metadata entry.

---

## Issue 3: Hardcoded `'StudyKing'` in main.dart

### Context
`lib/main.dart:121` uses a raw string for the MaterialApp title:
```dart
title: 'StudyKing',
```

### Rationale
The app already defines `l10n.appTitle` (value: `"StudyKing"`) in both ARB files. Using the localised accessor ensures the title is consistent when the app name is ever localised, and avoids an untranslated string being visible in the Android task switcher / iOS app switcher.

### Affected files
- `lib/main.dart` (line 121)

### Action
Replace `title: 'StudyKing'` with `title: l10n.appTitle`.

---

## Issue 4: New Locale Onboarding Lacks Automation

### Context
The `l10n.yaml` comment block correctly documents the steps to add a new locale, but they are entirely manual:
1. Create a new `app_xx.arb` file
2. Edit `AppLocale` enum in `lib/core/config/locale_config.dart`
3. Add to `supported-locales` in `l10n.yaml`
4. Flutter codegen

### Rationale
Manual steps invite human error (forgetting to register the locale, missing an ARB key). An automated check would:
- Validate that every key in `app_en.arb` exists in the new locale's ARB
- Fail CI if translation coverage is below 100%

### Affected files
- `l10n.yaml`
- `lib/core/config/locale_config.dart`
- `lib/l10n/app_en.arb` (template, all others derive from it)

### Action
Add a CI script (e.g. in `scripts/check_i18n_coverage.sh`) that compares all locale ARB key sets against `app_en.arb` and fails on gaps. This is critical for upcoming locale additions (e.g. French, German, Japanese).

---

## Acceptance Criteria

- [ ] All 79 groups of duplicate translation keys consolidated into single keys; Dart references updated.
- [ ] `adherenceLowToday`, `adherencePartialToday`, `adherenceExceededToday` have correct `"type": "int"` on all placeholders in both EN and ES ARB files.
- [ ] `l10n.appTitle` used in `main.dart:121` instead of `'StudyKing'`.
- [ ] CI script added (`scripts/check_i18n_coverage.sh`) that validates 100% key parity between `app_en.arb` and all locale files.
- [ ] `flutter gen-l10n` completes without warnings.
- [ ] Spanish display is unchanged (values remain identical after deduplication, only key names change).
