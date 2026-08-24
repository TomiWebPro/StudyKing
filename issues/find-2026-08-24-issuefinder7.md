# Issue Discovery Log — 2026-08-24 (issue-finder pass 7)

Run by the ISSUE-FINDER agent. No application code was modified; only this notes file.

## Toolchain
- `/opt/flutter/.installed` present → TOOLCHAIN_READY.
- `flutter analyze`: **No issues found!** (consistent with prior passes today).
- `grep` for `TODO`/`FIXME`/`HACK` in `lib/`: none (only an ARB string "TODOS LOS INTENTOS" matches).

## Scan method
- Re-verified lint cleanliness and absence of `print(`, empty `catch (_) {}`, and `TextEditingController` leaks (all instantiation sites have `dispose()`).
- Commissioned a focused subagent sweep of untrusted-input parsing, empty-list index/division, and force-unwrap crashes.
- Manually confirmed each candidate with file:line citations before filing.

## New issues opened (5)

| # | Title | Label | Summary |
|---|-------|-------|---------|
| 52 | Wrap non-streaming LLM chat HTTP parsing in try/catch | bug | `_callOpenRouter/_callOllama/_callOpenAI` do unguarded `jsonDecode` + nested `choices[0].message.content` access; a malformed 200 throws instead of returning `Result.failure` (violates AGENTS.md `Result<T>` rule). Streaming variants are already guarded, so this is an oversight. |
| 53 | Settings screen DateTime.parse on persisted backup timestamp crashes the screen | bug | `settings_screen.dart:711` calls `DateTime.parse(lastBackupStr)` in `build` on persisted data; a malformed/corrupted value throws `FormatException` and red-screens the whole Settings screen. |
| 54 | schedule_lesson tool crashes on non-ISO LLM timestamp | bug | `schedule_lesson_tool.dart:47` does `DateTime.parse(args['scheduledTime'])` on a raw LLM arg; non-ISO times throw, escaping to the opaque generic agent-loop catch with no log/fallback. |
| 55 | Unguarded empty question pool in exam/practice session build paths | bug | `exam_session_screen.dart:321-322` and `practice_session_screen.dart:649-650` index `_questions[_currentIndex]` and divide by `_questions.length` with no empty-pool guard → `RangeError` + `Infinity` progress when active-but-empty. |
| 56 | Remove force-unwrap ['en']! fallback in mentor keyword locale maps | bug | `mentor_service.dart:319/320/321` (and `conversation_manager.dart:370/378`) use `?? <map>['en']!`; a removed/empty `'en'` key throws in the mentor hot path despite the `??` implying a safe fallback. |

## De-duplication
Cross-checked `gh issue list --repo TomiWebPro/StudyKing --state open` (#1–#51). Skipped as already covered:
- Lints / tests bootstrap / Result<T> conversion / Logger / silent catches / build-context-async / share_plus / unawaited futures / stale fakes / switch exhaustiveness → #1–#13 (and the systemic test-Hive issue #42).
- LLM-specific: streaming token/cost accuracy (#31), locale-fallback crash in chat (#50 — distinct: JSON-shape/network, not locale), LlmUsageMeter malformed record (#51 — distinct subsystem).
- Hive migration plaintext/API-key (#37, #38), repository-in-UI (#36, #40), N+1 (#41), i18n hardcoded (#39), reminders (#44, #45), practice_screen catchError (#46), firstWhere (#43), wellbeing cap (#47), late-night (#48), fuzzy match (#49), weak areas (#27), plans/syllabus (#26, #33), recall probability (#23), transcribe URLs (#24), lessons-remaining (#25), handwriting (#30), lesson recap (#29), swallowed Result via .data?? (#28).
- None of the 5 new issues overlap the above; each has a distinct file/mechanism.

## Notes
- Capped at 5 new issues to avoid spam. Only this notes file is committed; no application code modified.
