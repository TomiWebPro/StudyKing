# Issue Discovery Log — 2026-08-24 (issue-finder pass)

Run by the ISSUE-FINDER agent. No application code was modified; only this notes file.

## Toolchain
- `/opt/flutter/.installed` present → TOOLCHAIN_READY.
- `flutter analyze lib`: only the 3 known `use_build_context_synchronously` info lints (tracked by open issue #6) — no new production errors/warnings.
- `flutter analyze test`: No issues found! (roadmap_adapter_test error from #10 is now resolved.)

## Candidate issues investigated and REJECTED (false positives)
- **NotificationService stale locale**: suspected `_l10n` instance field never refreshed on locale switch. Verified FALSE — `engagement_scheduler.updateLocalization()` calls `setAppLocalizations()` and is invoked from `app_providers.dart:72/74`, `study_progress_provider.dart`, `mentor_providers.dart`, `dashboard_providers.dart`, and `main.dart:684` whenever `localeProvider` changes. No bug.
- **Unsafe `Result.data!` force-unwraps**: checked `mastery_graph_service.dart`, `shared_providers.dart`, `export_section.dart`, `focus_timer_screen.dart`. All `.data!` usages are preceded by `isFailure`/`isSuccess` guards. No crash bug.
- **User-facing `toStringAsFixed`**: only in CSV exports, debug logs, and LLM-facing prompts (all permitted by AGENTS.md). PDF exports use `formatPercent`/`formatDecimal`. OK.
- **Non-exhaustive switches**: remaining `switch` sites are Dart 3 exhaustive switch expressions (would not compile otherwise). #1 already covers the legacy `ProcessingStatus` switch.
- **Barrel files**: `widgets.dart`/`data.dart` are imported by production code. OK.
- **Token-usage task portal**: `lib/features/llm_tasks` already tracks and displays per-task token usage. Vision item satisfied.
- Empty `catch` blocks, module-level `const Logger`, `.normalized`, missing test files (#7 closed): all clean per prior passes.

## New issues opened (3)
| # | Title | Label |
|---|-------|-------|
| 28 | Log/surface swallowed Result failures hidden by `.data ?? default` fallbacks | bug |
| 29 | Add lesson recap / "how the class went" summary record | enhancement |
| 30 | Wire handwritten/canvas and vision-based (image) answer input into validation | enhancement |

## De-duplication
Cross-checked `gh issue list --repo TomiWebPro/StudyKing --state open` (#1–#27). Skipped as already covered: BuildContext async #6, analyze lints #8, missing tests #7 (closed), Result<T> return types #9, stale test fakes #3, syllabus tool #2, ProcessingStatus switch #1, unawaited Future #4, share_plus #5, roadmap_adapter_test #10, Logger static final #11, empty catch #12, flashcard provider test #13, PDF regex #14, web scraper #15, rich-question stub validation #16, onboarding overflow #17, VoiceService STT #18, avatar picker #19, model routing #20, feedback mechanism #21, variant generation #22, recall probability #23, URL transcription #24, lessons-remaining #25, multi-plan #26, weak areas sheet #27.

No duplicates were created. Used `bug`/`enhancement` labels (the repo has no `test`/`refactor` labels).
