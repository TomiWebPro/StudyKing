# Issue Discovery Log — 2026-08-24 (issue-finder pass 3)

Run by the ISSUE-FINDER agent. No application code was modified; only this notes file.

## Toolchain
- `/opt/flutter/.installed` present → TOOLCHAIN_READY.
- `flutter analyze`: **No issues found!** (matches prior passes; lints in #1–#13 already tracked/closed).
- Conventions re-checked: no production `print(`, no empty `catch (_) {}`, `toStringAsFixed` only in CSV/LLM/debug (allowed), `.normalized` used correctly, no undisposed `TextEditingController`, provider behavioral bar (only #13 open).

## Re-check of existing open issues (#1–#34)
Reviewed `gh issue list --repo TomiWebPro/StudyKing --state open` (#1–#34). Skipped as already covered:
- Logger module-level declarations → #11 (but inline in-method constructions are distinct → new #35).
- Silent `catch (_)` blocks → #12 (asr_engine/flashcard_generator/slide_deck_generator only; `subject_list_screen` silent `catchError` is a distinct location → new #36).
- Direct repository construction in presentation → #32 (MultiSyllabusInput only; SubjectListScreen is a distinct instance → #36).
- OCR engine integration → approved as covered/deferred by prior pass; not reopened.
- BuildContext async → #6; missing tests → #7 (closed); Result<T> → #9; etc.

## New issues opened (2)
| # | Title | Label | Summary |
|---|-------|-------|---------|
| 35 | Replace inline Logger(...) construction in methods with static final loggers | enhancement | `result.dart:34,45` and `chunked_content_processor.dart:373` construct `Logger(...)` inline inside methods, violating AGENTS.md "static final at class level" + inline-Logger ban. Distinct from #11 (module-level). |
| 36 | SubjectListScreen builds SessionRepository() per rebuild and silently swallows errors with catchError((_) => 0) | bug | `subject_list_screen.dart:168-172` recreates `SessionRepository()` inside a per-item FutureBuilder (reopening Hive box, bypassing Riverpod) and discards all failures via silent `catchError((_) => 0)` with no log. Distinct from #12/#32. |

## Duplicate/skipped
- Inline Logger → not in #11 scope (module-level only); opened as #35.
- SubjectListScreen repo/catchError → not in #12 (different files) or #32 (MultiSyllabusInput only); opened as #36.
- OCR engine integration, multi-syllabus model, responsive wrapper, token-cost accuracy, etc. — already tracked by #14/#30/#33/#34; not reopened.

## Notes
- Limited to 2 high-confidence, clearly-distinct issues to avoid spam given 34 issues already open from earlier today.
- Only this notes file is committed; no application code modified.
