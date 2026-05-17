# MentorService lacks locale support — AI mentor ignores user's language preference

## Context

The app has two AI chat features: **Quick Guide** (`lib/features/teaching/`) and **Mentor** (`lib/features/mentor/`). Quick Guide correctly uses a locale-aware system prompt via the ARB key `quickGuideSystemPrompt` (translated in both `app_en.arb` and `app_es.arb`). The Mentor, however, hardcodes an English-only system prompt and never receives locale information, so it always responds in English regardless of the user's selected language.

A Spanish-speaking user sees the entire UI in Spanish but gets English responses from the AI Mentor — a broken experience.

## Affected files

| File | Issue |
|---|---|
| `lib/features/mentor/services/mentor_service.dart:26-29` | `_mentorSystemPromptText` is hardcoded English. No locale parameter exists on the class. |
| `lib/features/mentor/services/mentor_service.dart:531-551` | `suggestNextAction()` returns hardcoded English messages (`"You haven't added any subjects yet..."`, `"You're doing well!..."`). |
| `lib/features/mentor/services/mentor_service.dart:571-574` | System message for rescheduling conflict is hardcoded English. |
| `lib/features/mentor/services/mentor_service.dart:595-598` | System message for pending reschedule confirmation is hardcoded English. |
| `lib/features/mentor/presentation/mentor_screen.dart:60-70` | `MentorService` is instantiated without locale — no way to pass `localeName` from `AppLocalizations`. |
| `lib/l10n/app_en.arb` | Missing `mentorSystemPrompt` key (only `quickGuideSystemPrompt` exists). |
| `lib/l10n/app_es.arb` | Missing `mentorSystemPrompt` key. |

## Rationale

1. **Bilingual inconsistency**: Quick Guide already respects locale (`quickGuideSystemPrompt` at ES line 2505); Mentor does not. Users who switch to Spanish get a mixed-language experience.
2. **Blocking future languages**: Since MentorService has no locale plumbing, adding French, German, etc. will require revisiting this same code. Fixing it now for Spanish establishes a reusable pattern.
3. **Hardcoded fallback strings**: `suggestNextAction()` is a user-facing method (`MentorAction.message` is eventually shown in the UI) but returns English-only text that bypasses `AppLocalizations` entirely.

## Acceptance criteria

1. Add a `mentorSystemPrompt` key to both `app_en.arb` and `app_es.arb` (mirroring the pattern of `quickGuideSystemPrompt`).
2. Add an optional `localeName` parameter to `MentorService` (defaulting to `'en'`).
3. Pass `localeName` from `MentorScreen` using `AppLocalizations.of(context)!.localeName` when constructing `MentorService`.
4. Replace the hardcoded `_mentorSystemPromptText` with the localized value from the ARB bundle (using a static helper or injection so the service can access the translation without a `BuildContext`).
5. Replace hardcoded English strings in `suggestNextAction()` with translated ARB lookups conditional on the stored `localeName`.
6. Verify that with the device locale set to Spanish (`es`), the AI Mentor greets and responds in Spanish.
7. Run `flutter gen-l10n` to regenerate localizations.
8. Update `test/features/mentor/services/mentor_service_test.dart` to cover the locale-aware path (e.g., inject `localeName: 'es'` and assert the prompt uses the Spanish ARB value).

## Prior art

- `quickGuideSystemPrompt` in `app_es.arb` (line 2505) shows the correct pattern: the system prompt is stored as an ARB string and the generated `AppLocalizations` class provides it per locale.
- The Mentor Service's `_memory.addSystemMessage(...)` calls on lines 571-574 and 595-598 can be refactored the same way.
