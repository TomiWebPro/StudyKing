# Dry-Run Result: Existing User Adjusting Pace, Adding Subjects, Switching Providers

**Source scenario:** `dry-run-test/scenario_existing_user_pace_subjects_provider.md`
**Verification date:** 2026-05-19
**Validator:** Dry-Run Result Validator

---

## Summary

The dry-run scenario contained **multiple factual errors** — several features it claimed were missing or broken have in fact been implemented (pace slider, cancel/reschedule lesson buttons, subject editing, multi-subject plan generation, PDF/JSON export on dashboard). The actual remaining issues are concentrated in **Step 3 (AI provider switching)** and minor UX concerns in Steps 1 and 7.

| Step | Dry-Run Verdict | Actual Verdict | Change |
|---|---|---|---|
| 1. Dashboard returning user | PASS | PASS | No change (minor note added) |
| 2. Adjust study pace | PARTIAL | **PASS** | Was already implemented |
| 3. Switch AI provider | FAIL (MAJOR) | **FAIL (MAJOR)** | Confirmed, but details differ from scenario |
| 4. Cancel/reschedule lesson | FAIL (BLOCKER) | **PASS** | Was already implemented |
| 5. Multi-subject plans | PARTIAL | **PASS** | Was already implemented |
| 6. Edit/delete subject | FAIL (MAJOR/FAIL) | **PASS** | Was already implemented |
| 7. Export | PARTIAL | **PARTIAL** | Confirmed, but details differ from scenario |

---

## BLOCKER Issues

*(None found. Cancel/reschedule, subject deletion all work correctly.)*

---

## MAJOR Issues

### M-1: Provider dropdown does not update Riverpod providers in-memory until save

**Files:**
- `lib/features/settings/presentation/api_config_screen.dart:321-336` (dropdown `onChanged`)
- `lib/features/settings/presentation/api_config_screen.dart:67-83` (`_saveKeys`)
- `lib/core/providers/app_providers.dart:129-135` (provider definitions)

**Description:**
When the user changes the AI provider dropdown on the ApiConfig screen, the `onChanged` handler only updates local `_selectedProvider` state and the `_baseUrlController` text field. It does **not** update the Riverpod providers in-memory (`llmProviderProvider`, `selectedModelProvider`, `apiKeyProvider`, `apiBaseUrlProvider`). These are only written on explicit "Save" button press.

This creates two problems:

1. **Stale provider/model until save**: If the user changes the dropdown to "Ollama" but navigates directly to "AI Model" selection without pressing Save first, the AI model selection sheet reads `llmProviderProvider` (still the old provider) and `selectedModelProvider` (still the old model). The user sees stale data and could make incompatible selections.

2. **Changes lost on navigate-back**: If the user changes the dropdown and uses system back navigation instead of the back arrow in the AppBar (which pops with a result), their dropdown change is silently discarded. The Save button is the only way to persist, but there is no unsaved-changes warning.

**Rationale for MAJOR severity:**
The described flow in the dry-run scenario — change provider, save, then go to AI Model — works correctly because `_saveKeys()` (line 75) resets `selectedModelProvider` to `''` and downstream providers use `defaultModelForProvider()` as fallback. So the worst-case silent-failure scenario from the scenario does **not** occur. However, the pre-save navigation gap and the stale-provider risk are genuine behavioral bugs.

**Acceptance criteria:**
- [ ] Provider dropdown `onChanged` should immediately update `llmProviderProvider` (or at minimum, navigating to AI Model should read the local `_selectedProvider` instead of the saved provider)
- [ ] Navigating away from ApiConfigScreen with unsaved changes should show a confirmation dialog
- [ ] If a user does reach AI Model selection with a changed but unsaved provider, the model list should reflect the new (local) provider, not the saved one

### M-2: Code-test mismatch for base URL auto-fill on provider change

**Files:**
- `lib/features/settings/presentation/api_config_screen.dart:321-336`
- `test/features/settings/presentation/api_config_screen_test.dart:647-674`

**Description:**
The ApiConfig screen code **always** overwrites the base URL on provider dropdown change (lines 325-335). However, the tests expect the opposite:
- `"selecting Ollama does not change non-empty base URL"` (test:647) expects a custom URL `https://custom.url` to remain unchanged when switching to Ollama
- `"selecting OpenAI does not change base URL"` (test:662) expects an empty URL to stay empty

These tests **will fail** against the current code. Either the code should conditionally overwrite (only when the field is empty or matches a known default), or the tests should be updated to match the unconditional-overwrite behavior. The unconditional behavior is arguably better UX (users should expect the default URL when switching providers), but the test mismatch is a quality regression.

**Acceptance criteria:**
- [ ] Either make base URL overwrite conditional (only when empty or matching a known default) and update tests to verify, or update tests to match the existing unconditional overwrite behavior
- [ ] Whichever path chosen, ensure tests consistently pass without skipping

---

## MINOR Issues

### m-1: No single "Export Full Report" button on Dashboard

**Files:**
- `lib/features/dashboard/presentation/widgets/export_section.dart:37-57`
- `lib/features/dashboard/presentation/widgets/export_section.dart:58-97`

**Description:**
The Dashboard `ExportSection` provides three separate format-specific buttons ("Export CSV", "Export PDF", "JSON") each of which exports the exact same comprehensive data in a different format. There is no single "Export Full Report" or "Export All" button that covers all use cases. A user must understand the difference between CSV, PDF, and JSON to choose, rather than having a single obvious action.

The section heading reads `l10n.exportComprehensiveReport` ("Export Full Progress Report") but this is a label, not a tappable button.

**Acceptance criteria:**
- [ ] Add a primary "Export Full Report" action that picks a sensible default format (e.g., PDF for printing/sharing) or shows a sub-menu

### m-2: "Instrumentation" export label is unclear

**Files:**
- `lib/features/dashboard/presentation/widgets/export_section.dart:85-96`

**Description:**
The "Instrumentation" button exports plan adherence + mastery improvement data as JSON. The term "Instrumentation" is developer-facing jargon. Most users will not understand what this exports or why they might need it.

**Acceptance criteria:**
- [ ] Rename the button label to something user-friendly (e.g., "Progress Analytics" or "Study Insights") and/or add a subtitle/tooltip explaining the contents

### m-3: SessionHistoryScreen export options don't match test expectations

**Files:**
- `lib/features/sessions/presentation/session_history_screen.dart:148-187`
- `test/features/sessions/presentation/session_history_screen_test.dart:506-575`

**Description:**
The SessionHistoryScreen export bottom sheet offers only 2 options: "Export CSV" (per-session data) and "Export Full Progress Report" (comprehensive CSV). However, tests expect up to 6 options including PDF and JSON variants for both session and comprehensive exports.

The underlying `SessionExportService` has `shareJSON()` and `sharePDF()` methods, and `ProgressExportService` has `shareComprehensiveJSON()` and `shareComprehensivePDF()`, but none of these are wired into the SessionHistoryScreen UI.

**Acceptance criteria:**
- [ ] Add PDF and JSON export options to the SessionHistoryScreen bottom sheet, or update the tests to match the current (reduced) set and document the rationale

### m-4: SummaryRow does not display total questions attempted

**Files:**
- `lib/features/dashboard/presentation/widgets/summary_row.dart:38-74`
- `lib/features/dashboard/data/models/dashboard_models.dart:40` (`OverallStats.totalAttempts`)

**Description:**
The `OverallStats` model carries `totalAttempts` (total questions answered), but the `SummaryRow` widget displays only 4 metrics: accuracy, study time, weekly activity, and topics studied. A returning user has no quick-glance count of how many questions they've attempted, even though the data is available.

The scenario's "{Expected}" column lists "total questions" as a desired summary metric.

**Acceptance criteria:**
- [ ] Add a 5th metric card to `SummaryRow` showing the total attempt count, using `formatCompactNumber()` for large numbers (or `formatDecimal()` depending on locale conventions)
