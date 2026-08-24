# Issue Finder Run — 2026-08-24 (pass 6)

Toolchain: ready (`/opt/flutter/.installed` present).
`flutter analyze` reported **No issues found!** — repo is lint-clean, so this pass focused on logic/robustness bugs not caught by the analyzer and not already in the 46 prior open issues.

## New issues opened (5)

| # | Title | Label |
|---|---|---|
| 47 | Mentor wellbeing safeguards and nudge rate-limit bypassed when no daily study cap is set (default) | bug |
| 48 | Late-night study detection misses sessions crossing midnight and early-morning sessions | bug |
| 49 | Fuzzy answer matching yields false positives (duplicate/extra words inflate ratio) | bug |
| 50 | LlmService.defaultSystemPromptForLocale throws for unsupported locales, crashing chat() | bug |
| 51 | LlmUsageMeter.init() crashes on a single malformed persisted usage record | bug |

## Evidence pointers
- 47: mentor_wellbeing_service.dart:41-45 & 54-55; settings_service.dart:7-15 (default cap 0)
- 48: mentor_wellbeing_service.dart:70; mentor_context_builder.dart:169; study_utils.dart:19
- 49: question_evaluation_model.dart:147-154
- 50: llm_chat_service.dart:100-102 (called at :334, :396, unwrapped)
- 51: llm_usage_meter.dart:46, 39-48, 60-66

## De-duplication
Checked `gh issue list --repo TomiWebPro/StudyKing --state open` (46 prior issues). None of the 5 above overlap existing titles (wellbeing/overwork exists as implemented features but the cap-default-disable and rate-limit bypass, cross-midnight late-night, fuzzy-match false positives, locale-fallback crash, and usage-meter crash were not previously filed).

## Skipped (already covered by prior issues)
- Module-level / inline Logger → #11, #35
- Empty catch blocks → #12
- toStringAsFixed in CSV/LLM/debug only (user-facing widgets use locale-aware helpers) → not a violation
- firstWhere/first unguarded → #43
- Repository() in build (dashboard/SubjectListScreen) → #40, #36; broader sweep considered but risked duplicate
- CSV exports invariant en format → by convention
