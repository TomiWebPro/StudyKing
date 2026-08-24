# Issue Discovery Log — 2026-08-24 (follow-up pass)

Run by the ISSUE-FINDER agent. No application code was modified; only this notes file.

## Toolchain
- `/opt/flutter/.installed` present → TOOLCHAIN_READY.
- `flutter analyze lib`: only the 3 known `use_build_context_synchronously` info lints (tracked by #6) — no new production lints.
- `flutter analyze test`: 1 error — `roadmap_adapter_test.dart` undefined `MilestoneModelAdapter` (already tracked by open issue #10). No new test lints.

## Conventions re-checked
- Public service/repo methods returning `Result<T>`: scope of open #9 (still open; not reopened).
- Module-level `const Logger(...)` declarations: scope of open #11 (not reopened).
- Empty `catch (_) {}` blocks: none found in `lib/` (scope of open #12).
- `.normalized` / `trim().toLowerCase()`: used correctly; no violations.
- User-facing `toStringAsFixed`: only in CSV exports, debug logs, and LLM-facing strings (all permitted by AGENTS.md). PDF exports use `formatPercent`/`formatDecimal` correctly.
- No `print(` in production. Barrel files are imported by production code (OK).
- Test coverage: only `.g.dart` generated files lack tests (expected); issue #7 closed.
- Provider-test behavioral bar: only `flashcard_providers_test` fails (open #13); all other provider tests have real behavioral assertions.

## New issues opened (5)
| # | Title | Label | Summary |
|---|-------|-------|---------|
| 23 | Surface spaced-repetition recall probability in UI (computeRecallProbability unused) | enhancement | `computeRecallProbability` is implemented but only exercised by its unit test; never surfaced to students. |
| 24 | Transcribe pasted online audio/video URLs during ingestion | enhancement | `WebScraper` only strips HTML; YouTube/MP3/MP4 URLs yield junk instead of transcription. |
| 25 | Add relative 'lessons remaining to mastery' indicator | enhancement | Vision requires this; no implementation exists anywhere in the app. |
| 26 | Support multiple independent study plans with an active-context switcher | enhancement | Currently a single global plan; no active-plan switcher across planner/mentor/dashboard/practice. |
| 27 | WeakAreasSheet should filter/annotate subjects by actual weak topics | bug | `WeakAreasSheet` merely delegates to `SubjectSelectionSheet` with all subjects, ignoring weak-topic data. |

## De-duplication
Cross-checked `gh issue list --repo TomiWebPro/StudyKing --state open` (#1–#22). Skipped as already covered:
- BuildContext across async gaps → #6
- flutter analyze lints in test files → #8
- missing test files / 27 uncovered sources → #7 (closed)
- public methods returning Result<T> → #9
- stale test fakes compilation → #3
- get_syllabus_structure_tool String-as-Map → #2
- non-exhaustive ProcessingStatus → #1
- unawaited Future in try → #4
- share_plus migration → #5
- roadmap_adapter_test error → #10
- module-level Logger → #11
- empty catch blocks → #12
- flashcard provider test behavioral bar → #13
- PDF regex extractor → #14
- web scraper HTML parser → #15
- rich-question stub validation → #16
- onboarding overflow → #17
- VoiceService Linux STT crash → #18
- profile avatar picker → #19
- task-specific LLM model routing → #20
- student feedback mechanism → #21
- question variant generation pipeline → #22

No duplicates were created.
