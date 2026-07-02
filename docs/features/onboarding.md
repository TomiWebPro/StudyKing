# Onboarding Feature

## Overview

The Onboarding feature introduces new users to the app through a multi-page dialog. It covers subjects, practice, mentor, AI configuration, focus mode, and settings. Users can skip onboarding or opt to never show it again. The feature persists completion state via Hive storage.

## Key Files

| Layer | Files |
|---|---|
| Services | `OnboardingService`, `OnboardingStorage` (abstract), `HiveOnboardingStorage`, `InMemoryOnboardingStorage` |
| Models | `OnboardingState` |
| Providers | `onboardingServiceProvider`, `onboardingNeededProvider`, `isFirstLaunchProvider` |
| Screens/Dialogs | `OnboardingDialog`, `ApiKeyBanner`, `LocalDataNotice` |

## Core Services

### OnboardingService

- `isOnboardingNeeded()` — Returns true if not completed and "don't show again" is unset
- `markCompleted()` — Persist onboarding as completed
- `markDontShowAgain()` — Persist "don't show again" preference
- `isFirstLaunch()` — Returns true if onboarding has never been completed
- `resetOnboarding()` — Reset both flags for testing

### OnboardingStorage

Abstract interface with `HiveOnboardingStorage` (production, uses `HiveBoxNames.settings`) and `InMemoryOnboardingStorage` (testing).

## Key Models

| Model | Purpose |
|---|---|
| `OnboardingState` | Tracks `completed` and `dontShowAgain` boolean flags with `isNeeded` and `isFirstLaunch` computed getters |

## Workflow

1. **Launch Check:** On app start, `onboardingNeededProvider` checks whether onboarding is required
2. **Dialog Display:** If needed, `OnboardingDialog` is shown as a modal with a `PageView` of feature introductions
3. **Page Navigation:** User taps "Next" through 6 pages (Subjects, Practice, Mentor, AI Config, Focus, Settings)
4. **API Key Page:** Shows expandable explanation of what an API key is and why it is needed
5. **Completion:** User taps "Get Started" or "Skip"; `OnboardingService.markCompleted()` or `markDontShowAgain()` is called
6. **Redirect:** After completion, user is navigated to the dashboard
7. **ApiKeyBanner:** A persistent banner shown when no API key is configured, linking to the API config screen
8. **LocalDataNotice:** Alert dialog explaining local data storage, shown on first data-sensitive operations

## Key UI Features

- **Page indicators** with animated dots (or static when reduceMotion is enabled)
- **"Don't show again"** checkbox on the last page
- **API key configuration** call-to-action directly from onboarding
