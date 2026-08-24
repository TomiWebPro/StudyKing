# Issue Discovery Log — 2026-08-24 (issue-finder pass 2)

Run by the ISSUE-FINDER agent. No application code was modified; only this notes file.

## Toolchain
- `/opt/flutter/.installed` present → TOOLCHAIN_READY.
- `flutter analyze`: **No issues found!** — prior lint issues (#1–#13) are resolved.
- Convention re-checks: no `print(` in lib/, no empty `catch (_) {}`, `.normalized` used correctly,
  no barrel files under lib/, CSV/LLM-facing `toStringAsFixed` usages are all permitted by AGENTS.md.

## Existing open issues reviewed (did NOT duplicate #1–#30)
Covered topics confirmed still open; no re-open. Verified NOT gaps: token-usage portal
(`LlmTaskManagerScreen`) exists (gap is data accuracy); voice conversation in lessons exists
(`VoiceBar` + `ConversationManager`); no uncovered source files remain (test coverage matched);
no `.data!` unguarded crashes in ~40 sampled services/screens.

## New issues opened (4)

| # | Title | Label | Summary |
|---|-------|-------|---------|
| 31 | Streaming LLM path reports estimated token counts and never records cost | bug | Streaming completions use `chars/4` token estimate and never pass `estimatedCost` → inaccurate tokens + permanent $0.00 cost in the task-manager portal. |
| 32 | MultiSyllabusInput swallows errors and creates a TopicRepository per build | bug | `catch (e) { return 0; }` violates AGENTS.md logging rule; a new `TopicRepository()`+`init()` is built inside a `FutureBuilder` per row with no disposal. |
| 33 | Introduce a first-class multi-syllabus domain model with per-syllabus tracking | enhancement | Only a free-text `syllabus` string on `SubjectModel`; no `Syllabus` entity or per-syllabus progress. Distinct from open #26 (study plans). |
| 34 | Add an app-wide responsive layout wrapper for wide/desktop screens | enhancement | Most top-level screens lack width constraints; vision requires responsive polish across all screen sizes. |

## De-duplication
Cross-checked `gh issue list --repo TomiWebPro/StudyKing --state open` (#1–#30). Skipped as already covered:
- Silent catch / empty catch → #12 (but #32 is a distinct concrete instance with a resource leak, not a duplicate).
- Multiple study plans → #26 (distinct from #33 multi-syllabus model).
- LLM token tracking portal presence → exists; #31 covers accuracy, not presence.

## Notes
- Limited to 4 new issues to avoid spam; several weaker candidates (broad responsive polish, minor
  logging cleanups) deliberately deferred.
- `git push` of this notes file is the only commit; no application code modified.
