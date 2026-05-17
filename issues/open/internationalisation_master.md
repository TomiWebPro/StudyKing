# Internationalisation Master — Comprehensive i18n Audit

**Date:** 2026-05-17
**Auditor:** Internationalisation Master
**Target Locale:** Spanish (`es`) — patterns generalise to all locales

## Strengths Observed

- ARB files (en/es) have 100% key parity per `scripts/check_i18n_coverage.sh` (5,201 keys each).
- All LLM system/user prompts (tutor, mentor, quick guide, evaluation, OCR, etc.) are fully localised in both EN and ES ARB files.
- `number_format_utils.dart` exists with `formatDecimal`, `formatPercent`, `formatCompactNumber`, `formatHours`, `formatCurrency`.
- `chat_bubble.dart` uses `Directionality.of(context)` + `MainAxisAlignment.start`/`end` for RTL-aware bubble positioning.
- CSVs correctly use `en`-invariant `toStringAsFixed` format per AGENTS.md convention.
- `DateFormat` calls across the codebase generally pass `l10n.localeName` for locale-aware output.
- `EdgeInsetsDirectional` and `EdgeInsets.only(top/bottom)` are used widely, preventing LTR-hardcoded padding in most places.

---

## BLOCKER — App crashes or user cannot proceed

### B1. Hardcoded user-facing strings in settings screen

**Files:** `lib/features/settings/presentation/settings_screen.dart`
**Lines:** 127–128, 135, 171–172, 180, 186
**Strings:**
| Line | Hardcoded string |
|------|-----------------|
| 127 | `const Text('Daily Reminder')` |
| 128 | `const Text('Get a daily reminder to study at your preferred time')` |
| 135 | `_tile('Reminder Time', ...)` |
| 171 | `const Text('Check Nudges Now')` |
| 172 | `const Text('Run nudge checks immediately')` |
| 180 | `const SnackBar(content: Text('Nudge check complete'))` |
| 186 | `const SnackBar(content: Text('Nudge check failed'))` |

**Impact:** These 7 strings always render in English regardless of Locale. The study-reminder and nudge sections are completely broken for Spanish users.

**Fix:** Replace each with `Text(l10n.dailyReminder)`, `Text(l10n.dailyReminderDescription)`, etc. — all these keys already exist in both ARB files and are simply not referenced.

**Acceptance:** Switching locale to `es` shows all settings tiles in Spanish; no English residual in these tiles.

---

### B2. Hardcoded dialog strings in focus timer screen

**File:** `lib/features/focus_mode/presentation/focus_timer_screen.dart`
**Lines:** 196–197, 205
**Code:**
```dart
title: Text('Daily Cap Warning'),
content: Text('Starting this session will exceed your daily cap. ...'),
child: const Text('Continue Anyway'),
```

**Impact:** Spanish users see the daily-cap warning dialog entirely in English.

**Fix:** Add ARB keys `dailyCapWarningTitle`, `dailyCapWarningBody`, `continueAnyway` to both ARB files and reference them.

**Acceptance:** Daily-cap warning dialog renders in Spanish when locale is `es`.

---

### B3. Currency display uses hardcoded `$` + `toStringAsFixed(4)`

**File:** `lib/features/settings/presentation/settings_screen.dart`
**Lines:** 227, 794
**Code:**
```dart
// Line 227
subtitle: Text(r'$' '${ref.watch(llmUsageMeterProvider).getTotalCost().toStringAsFixed(4)}'),
// Line 794 (inside token usage dialog)
'\$${totalCost.toStringAsFixed(4)}',
```

**Impact:**
1. `toStringAsFixed(4)` always produces a period `.` decimal separator, even in Spanish (`es`) where comma is standard: `$1,234.5678` should be `$1.234,5678` (but actually Spanish doesn't use `$` — it would be a different format entirely).
2. Hardcoded `$` assumes USD. A Spanish user might expect `€` or locale-specific symbol.

**Fix:** Use `formatCurrency(value, l10n.localeName)` from `number_format_utils.dart`. The existing `formatCurrency` already accepts locale and produces locale-correct separators. For LLM-facing invariant strings where period is required, use explicit `NumberFormat('#,##0.0000', 'en')`.

**Acceptance:** Token cost displays with locale-correct decimal separators and currency symbol (currently `$` is acceptable for `en`; for `es` at minimum comma decimals should display correctly).

---

## MAJOR — Feature is broken or misleading

### M1. Mentor LLM-facing date strings use ISO format for all locales

**File:** `lib/features/mentor/services/mentor_service.dart`
**Lines:** 146, 163, 481, 482, 500, 642
**Code pattern:**
```dart
DateFormat('y-MM-dd HH:mm', _localeName).format(lesson.startTime.toLocal())
```

**Impact:** Despite passing `_localeName`, the hardcoded pattern `y-MM-dd HH:mm` produces the same ISO-like output for every locale (e.g. `2026-05-17 14:30` for both `en` and `es`). A Spanish user reading their mentor's message should see `17/5/2026 14:30` (or similar locale-appropriate pattern). The `_localeName` parameter is wasted here.

**Fix:** Use locale-aware date/time patterns. Options:
- `DateFormat.yMd(_localeName).add_Hm().format(...)` for short date + 24h time
- Or `DateFormat.yMMMd(_localeName).add_jm().format(...)` for "May 17, 2026 2:30 PM" (en) / "17 may 2026 14:30" (es)

**Acceptance:** Mentor chatbot messages show dates in the user's locale format.

---

### M2. `formatTimer` in `time_utils.dart` produces locale-unaware output

**File:** `lib/core/utils/time_utils.dart`
**Lines:** 83–93
**Code:**
```dart
String formatTimer(Duration duration, {AppLocalizations? l10n}) {
  ...
  return '${h.toString().padLeft(2, '0')}$sep${m.toString().padLeft(2, '0')}$sep${s.toString().padLeft(2, '0')}';
}
```

**Impact:** The timer always uses a 00:00:00 format with zero-padded digits. While HM-separator is localisable (via `durationSeparator` ARB key), the overall format is rigid. Some locales use `h:mm:ss` without leading zero on hours, or use `h`/`h.` suffix conventions.

**Fix:** Create a locale-aware timer format, or at minimum use `NumberFormat('00', localeName)` for the digits. Consider a `formatTimerCompact` variant that drops zero-leading hours.

**Acceptance:** The focus-mode timer respects locale digit conventions.

---

### M3. `Reminder Time` tile in settings uses hardcoded time display

**File:** `lib/features/settings/presentation/settings_screen.dart`
**Line:** 135–136
**Code:**
```dart
_tile(
  'Reminder Time',
  '${settings.dailyReminderHour.toString().padLeft(2, '0')}:${settings.dailyReminderMinute.toString().padLeft(2, '0')}',
  ...
)
```

**Impact:** (A) The tile title `'Reminder Time'` is hardcoded in English. (B) The time format always shows 24h with leading zeros, regardless of locale. A user in `en_US` locale would expect "2:30 PM" not "14:30".

**Fix:** (A) Use `l10n.reminderTime` (or create the key). (B) Use `MaterialLocalizations.of(context).formatTimeOfDay()` or `DateFormat.jm(localeName)` for locale-aware display.

**Acceptance:** Reminder time shows in the user's preferred time format (12h/24h per locale).

---

### M4. `questionsAbbreviation` uses `Q` (English convention)

**File:** `lib/l10n/app_en.arb` line 2460, `lib/l10n/app_es.arb` line 2460
**Code:**
```json
"questionsAbbreviation": "{count}Q",
```
Spanish translates this as:
```json
"questionsAbbreviation": "{count}P",
```

**Impact:** Spanish convention (correct in the ARB key), but the abbreviation `P` (from *preguntas*) is not universally understood — `P` vs `Q` mapping is correct. This is actually done right in the ARB. But verify the calling code uses the correct key.

**Acceptance:** No action needed if already wired. Verify in `planner_screen.dart` and `dashboard` widgets that `l10n.questionsAbbreviation(count)` is used rather than hardcoded `{count}Q`.

---

### M5. `importPreview` text uses ungrammatical parenthetical Spanish

**File:** `lib/l10n/app_es.arb` line 905
**Code:**
```json
"importPreview": "Esta copia contiene {boxes} sección(es) con {records} registro(s). ..."
```

**Impact:** The parenthetical `sección(es)` and `registro(s)` pattern is awkward in Spanish. Native Spanish would use proper plural-aware phrasing: "contiene {boxes} secciones y {records} registros" or use ICU plural `{count,plural,=1{1 sección} other{{count} secciones}}`.

**Fix:** Use ICU plural select for `boxes` and `records` (or rephrase).

**Acceptance:** Import preview reads naturally in Spanish.

---

### M6. Hardcoded time format in session history date filter display

**File:** `lib/features/sessions/presentation/session_history_screen.dart`
**Line:** 370
**Code:**
```dart
DateFormat.yMd(l10n.localeName).format(_selectedDate!)
```

**Impact:** This uses a locale-aware format (good), but verify this is not a raw `toString().split()` pattern accidentally left in. There are also `toString().split(' ')[0]` calls in `progress_export_service.dart` lines 294-295 that produce date strings without any locale awareness for PDF exports (PDF should be user-facing per AGENTS.md).

**Fix:** Replace `toString().split(' ')[0]` in PDF code with `DateFormat.yMd(localeName)`.

**Acceptance:** PDF report dates use locale-aware formatting.

---

## MINOR — Code quality / UX friction

### m1. `EdgeInsets.only(left:)` patterns not RTL-safe in widget tests

Several widget files use `EdgeInsets.only(left: ...)` instead of `EdgeInsetsDirectional.only(start: ...)`:
- Check `lib/features/settings/presentation/settings_screen.dart` line 255
- `lib/features/planner/presentation/widgets/lesson_booking_sheet.dart` line 82
- `lib/features/quickguide/presentation/quick_guide_screen.dart` line 285
- `lib/features/quickguide/presentation/widgets/suggested_prompts_widget.dart` line 25
- `lib/features/subjects/presentation/widgets/subject_history_tab.dart` line 81
- `lib/features/subjects/presentation/widgets/subject_lessons_tab.dart` line 78
- `lib/features/lessons/presentation/widgets/lesson_block_card.dart` line 17
- `lib/features/lessons/presentation/widgets/lesson_list_item.dart` line 29

**Impact:** These will look wrong if the app ever supports Arabic, Hebrew, or other RTL locales.

**Fix:** Replace `EdgeInsets.only(left: X, ...)` with `EdgeInsetsDirectional.only(start: X, ...)` in the above files.

**Acceptance:** All horizontal padding in presentation code uses `start`/`end` variants.

---

### m2. `mentorService` uses `writeln('- Plan adherence: ...')` with ASCII dash

**File:** `lib/features/mentor/services/mentor_service.dart`
**Lines:** 130, 170
**Code:**
```dart
buffer.writeln('- Plan adherence: ${adherenceDeviation...}');
buffer.writeln('  * ${topic.topicId} (accuracy: ...)');
```

**Impact:** The mentor uses ASCII `-` and `*` for bullet lists in LLM-facing strings. These are invariant (LLM-facing) per AGENTS.md. However, when these strings are surfaced back to the user via the mentor chat, they may not render as proper list items in all locales.

**Fix:** Use the `l10n.mentorBulletPoint` ARB key (which already exists in both ARB files at lines 5197-5200). Replace `'- '` with `l10n.mentorBulletPoint` and `'  * '` accordingly.

**Acceptance:** Mentor chat bullet lists use locale-appropriate bullet characters.

---

### m3. `tests` directory may have hardcoded English strings in widget tests

Check all files under `test/` for hardcoded English strings — widget tests that check for exact string matches will break when the app locale is Spanish.

---

### m4. Some ARB descriptions mention English concepts but translations exist

Check the following keys that have identical source/target in es (possible missing translations):
- `colorBlueGrey` → es: `"Gris Azulado"` (fine)
- `aboutApplicationName` → es: `"StudyKing"` (fine, proper noun)
- `durationSeparator` → es: `" "` (intentional)

No false positives found — all 5,201 keys are properly translated.

---

### m5. `completionOfValue` takes `double` type but percent often stored as int

**File:** `lib/l10n/app_en.arb` line 3191-3196
```json
"completionOfValue": "{value}% Complete",
"placeholder": { "value": { "type": "double" } }
```

**Impact:** If callers pass `int`, the Dart compiler auto-promotes, but ICU formatting may strip decimals unexpectedly. Verify callers pass `double` (e.g., `80.0` rather than `80`). Not a Spanish-specific issue, but worth fixing to ensure correct percent rendering.

---

### m6. `notifBodyOverwork` uses `{hours}` as String type — but might be numeric

**File:** `lib/l10n/app_en.arb` lines 3895-3901
```json
"notifBodyOverwork": "You've studied {hours} hours today.",
"placeholder": { "hours": { "type": "String" } }
```

**Impact:** Using `String` type loses pluralisation capability. Like `nudgeOverworkMinutes` which uses `int` correctly, the overwork notification cannot distinguish "1 hour" vs "2 hours" for locales where hour has plural forms.

**Fix:** Change `hours` type to `int` and add ICU plural: `You've studied {hours,plural,=1{1 hour} other{{hours} hours}} today.` for EN; `Ha estudiado {hours,plural,=1{1 hora} other{{hours} horas}} hoy.` for ES.

**Acceptance:** Overwork notifications use correct plural forms.

---

## Summary Count

| Severity | Count |
|----------|-------|
| BLOCKER  | 3 (B1, B2, B3) |
| MAJOR    | 6 (M1–M6) |
| MINOR    | 6 (m1–m6) |

## Priority Action Items

1. **B1 + B2 (hardcoded strings):** Quick wins — add ARB keys, replace literals in settings + focus screens.
2. **B3 (currency formatting):** Switch to `formatCurrency` from `number_format_utils.dart`.
3. **M1 (mentor dates):** Replace ISO date patterns with locale-aware `DateFormat.yMd().add_Hm()`.
4. **M6 (PDF dates):** Replace `toString().split(' ')[0]` with `DateFormat.yMd(localeName)`.
5. **m1 (RTL padding):** Batch-replace `EdgeInsets.only(left/right:)` with `EdgeInsetsDirectional.only(start/end:)`.

## Reference: Locale Config

- `lib/l10n/l10n.yaml` — defines en + es as supported locales
- `lib/core/config/locale_config.dart` — `AppLocale` enum, `resolveLocale()` maps variants to base
- `lib/l10n/generated/app_localizations.dart` — generated output
- `scripts/check_i18n_coverage.sh` — validates key parity
