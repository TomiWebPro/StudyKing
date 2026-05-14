# Spanish Localisation Quality Audit — Register, Consistency, and Locale-Aware AI

## Context

Spanish (`es`) is the only non-English locale. `app_es.arb` has full key parity (3125 lines). The `i18n.md` documents formal *usted* register and consistency guidelines. A line-by-line comparison of `app_en.arb` vs `app_es.arb` and inspection of the Quick Guide feature reveal several concrete violations and one cross-cutting architectural bug that affects Spanish UX.

---

## Issue 1 — AI system prompt is always English, ignoring locale

**Affected file:** `lib/features/quickguide/presentation/quick_guide_screen.dart:128-131`

```dart
final effectiveSystem = widget.systemPrompt ??
    'You are StudyKing Quick Guide, a helpful AI study assistant. '
        'Provide concise, educational answers. Help with explanations, quiz questions, '
        'and math problems. Respond conversationally.';
```

The system prompt is hardcoded in English. When the app locale is `es`, the AI receives an English prompt and has no reason to reply in Spanish. The user sees English responses despite having Spanish selected.

**Rationale:** The system prompt must be built from `AppLocalizations` so the AI is instructed in the user's language. A new ARB key like `quickGuideSystemPrompt` should hold the locale-appropriate version and include instruction to answer in that language.

**Acceptance criteria:**
- Introduce a localised system prompt key `quickGuideSystemPrompt` in both `app_en.arb` and `app_es.arb` (e.g. English: *"You are ... Respond conversationally."*; Spanish: *"Eres la Guía Rápida de StudyKing... Responde en español de manera conversacional."*).
- Replace the hardcoded English string at `quick_guide_screen.dart:128-131` with `l10n.quickGuideSystemPrompt`.

---

## Issue 2 — Fallback response keyword matching is English-only

**Affected file:** `lib/features/quickguide/presentation/quick_guide_screen.dart:172-183`

```dart
String _fallbackResponse(String text) {
  final l10n = AppLocalizations.of(context)!;
  if (text.toLowerCase().contains('explain')) {
    return l10n.fallbackExplainResponse;
  } else if (text.toLowerCase().contains('question') || text.toLowerCase().contains('quiz')) {
    return l10n.fallbackQuizResponse;
  } else if (text.toLowerCase().contains('math') || text.toLowerCase().contains('calculate')) {
    return l10n.fallbackMathResponse;
  } else {
    return l10n.fallbackGeneralResponse;
  }
}
```

For a Spanish-speaking user, "explícame", "pregunta", "examen", "matemáticas", "calcular" will never match the English keywords, so every query falls through to `fallbackGeneralResponse`. The Spanish strings translated in `app_es.arb` (`fallbackExplainResponse`, `fallbackQuizResponse`, `fallbackMathResponse`) are **never reached** from the Spanish UI.

**Rationale:** Intent routing must be locale-aware. Either check translated prefix patterns from `AppLocalizations` or, better, delegate intent classification to the LLM itself (remove keyword heuristics entirely) and only use fallbacks on error.

**Acceptance criteria:**
- Remove English-only keyword matching, OR
- Add equivalent Spanish keywords (e.g. `'explíc'`, `'pregunt'`, `'examen'`, `'matemátic'`, `'calc'`) in parallel checks, OR
- Replace the heuristic entirely with a simple unconditional `fallbackGeneralResponse` (since the LLM will have been instructed via the localised system prompt from Issue 1).

---

## Issue 3 — Register violation: "Tu" instead of "Su" in mentor progress report title

**Affected file:** `lib/l10n/app_es.arb:2788`

```json
"mentorProgressReportTitle": "📊 **Tu Informe de Progreso de Estudio**\n"
```

The `i18n.md` explicitly mandates formal *usted* register ("su/sus", not "tu/tus"). This is the only occurrence of informal "Tu" found across the entire Spanish ARB.

**Rationale:** Inconsistency with documented convention. Native Spanish speakers expect formal register in an educational/academic app.

**Acceptance criteria:**
- Change to `"📊 **Su Informe de Progreso de Estudio**\n"` in `app_es.arb`.
- Verify no other stray informal address forms exist (search `app_es.arb` for `\btu\b`, `\btus\b`, `\bte\b` used as possessive/object pronouns).

---

## Issue 4 — Same English concept translated differently: "Mastered" → "Dominados" vs "Adquirido"

**Affected file:** `lib/l10n/app_es.arb`

| Key | Spanish value |
|-----|--------------|
| `"mastered"` (line 1665) | `"Dominados"` |
| `"masteredLabel"` (line 2273) | `"Adquirido"` |

Both translate the same English word "Mastered". The `i18n.md` guideline says *"Same English concept → same Spanish word"*.

**Rationale:** Users see "Dominados" in one context and "Adquirido" in another for the same concept. This is confusing and breaks the translation glossary.

**Acceptance criteria:**
- Choose one Spanish equivalent for "Mastered" (recommendation: "Dominados" is more natural in an educational context) and apply it consistently to both keys in `app_es.arb`.

---

## Issue 5 — Positive framing guideline violated in `weakAreasAccuracy`

**Affected file:** `lib/l10n/app_es.arb:1736`

```json
"weakAreasAccuracy": "Áreas Débiles (Precisión < 60%)"
```

The `i18n.md` guideline states: *"Positive framing. Prefer constructive language (e.g., 'Áreas por mejorar' over 'Áreas débiles')"*. All other "weak areas" keys use "Áreas por mejorar" (`weakAreas`, `weakLabel`).

**Rationale:** Inconsistency with both the guideline and the rest of the codebase.

**Acceptance criteria:**
- Change to `"Áreas por mejorar (Precisión < 60%)"` in `app_es.arb`.

---

## Issue 6 — `i18n.md` out of date: missing AI localisation guidance

**Affected file:** `docs/i18n.md`

The PR review checklist does not cover:
- AI system prompt localisation (Issue 1 above)
- Locale-aware fallback intent routing (Issue 2 above)
- The need for `pubspec.yaml` locale entries when adding new languages (currently only `en` and `es`)

**Rationale:** Contributors adding a third language will miss these requirements.

**Acceptance criteria:**
- Add a checklist item: *"AI system prompt key exists in the new locale's ARB and instructs the model to respond in that language."*
- Add a checklist item: *"Fallback intent routing (keyword matching) is updated to include the new locale's keywords or removed in favour of a locale-agnostic approach."*
- Verify `pubspec.yaml` `flutter:` section documents supported locales.

---

## Summary of affected files

| File | Issue |
|------|-------|
| `lib/l10n/app_es.arb` | Issues 3, 4, 5 |
| `lib/features/quickguide/presentation/quick_guide_screen.dart` | Issues 1, 2 |
| `docs/i18n.md` | Issue 6 |

No new ARB keys are strictly required except for `quickGuideSystemPrompt` (Issue 1). All other fixes are edits to existing values or documentation.
