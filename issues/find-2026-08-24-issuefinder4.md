# Issue Discovery Log — 2026-08-24 (issue-finder pass 4)

Run by the ISSUE-FINDER agent. No application code was modified; only this notes file.

## Toolchain
- `/opt/flutter/.installed` present → TOOLCHAIN_READY.
- `flutter analyze`: **No issues found!** (consistent with prior passes; lints in #1–#13 resolved/closed).
- No `print(` in lib/, no `TODO`/`FIXME` in lib/ (only ARB translation strings match), `toStringAsFixed`
  only in CSV/LLM/debug (permitted by AGENTS.md).

## Existing open issues reviewed (did NOT duplicate #1–#36)
Cross-checked `gh issue list --repo TomiWebPro/StudyKing --state open` (#1–#36). Verified as NOT gaps:
- Missing test files: re-audited all 177 source files under `lib/features/*/...` and `lib/core/**`; every
  source has a corresponding `*_test.dart` → issue #7 genuinely closed.
- Provider behavioral-assertion bar: sampled all 32 provider test files; each has a real behavioral
  assertion beyond isA/isNotNull → only #13 still open.
- `.data!` force-unwraps: audited ~15 samples; all guarded by isFailure/isSuccess → no new crash bug.
- Logger static-final / empty catch / `.normalized` / barrel files: clean per prior passes.

## New issues opened (5)
| # | Title | Label | Summary |
|---|-------|-------|---------|
| 37 | Add Hive schema versioning and migration safety for model evolution | bug | All boxes opened with default version=1, no migrator; schema changes risk HiveError / silent data corruption. |
| 38 | Stop persisting API keys in plaintext Hive box alongside secure storage | bug | `SettingsRepository.saveApiKey` writes key in plaintext Hive box; `main.dart` falls back to it; secure-storage path exists but legacy copy never deleted. |
| 39 | Localize hardcoded English strings in dashboard insights and canvas widgets | enhancement | `learning_insights_card.dart` and `canvas_drawing_widget.dart` use hardcoded English `Text(...)` literals absent from `.arb`. |
| 40 | Dashboard providers instantiate repositories directly instead of using injected providers | bug | `dashboard_data_providers.dart` builds `Repository()`+`.init()` inside provider bodies, reopening Hive boxes and bypassing shared injected singletons (distinct from #36). |
| 41 | Eliminate N+1 sequential Hive reads in dashboard due-reviews and session queries | enhancement | Per-item `await` loop reads in `dashboardDueReviewsProvider` and `session_query_service.getTopicsWithLessons` cause O(n) Hive reads on the UI thread. |

## Duplicate/skipped
- Hive migration → not covered by #32/#36 (repo wiring) or #12 (catch); opened as #37.
- API-key plaintext → distinct from #5 (share_plus)/#20 (model routing); opened as #38.
- i18n hardcoded strings → no open i18n-gap issue besides #17 (onboarding layout); opened as #39.
- Dashboard direct repo instantiation → distinct location/mechanism from #36 (SubjectListScreen); opened as #40.
- N+1 Hive reads → no existing performance issue; opened as #41.
- Heavy main-thread JSON/PDF parsing candidate (#14 is about PDF *regex* correctness, not main-thread cost)
  was considered but deferred to avoid exceeding the 5-issue cap this run.

## Notes
- Limited to 5 new issues to avoid spam given 41 issues now open from today's passes.
- Only this notes file is committed; no application code modified.
