# Issue Discovery Log — 2026-08-24 (issue-finder pass 8)

Run by the ISSUE-FINDER agent. No application code was modified; only this notes file.

## Toolchain
- `/opt/flutter/.installed` present → TOOLCHAIN_READY.
- `flutter analyze`: **No issues found!** (consistent with prior passes).
- `grep` for `TODO`/`FIXME`/`HACK` in `lib/`: none (only an ARB string "TODOS LOS INTENTOS" matches).

## Scan method
- Re-verified lint cleanliness and absence of empty `catch (_) {}` blocks, `print(`, and user-facing `toStringAsFixed` (all CSV/debug/LLM-facing only — permitted).
- Confirmed missing-test sweep via `for f in $(find lib ...)` loop: 0 newly-added feature/core files lack a test (issue #7 resolved).
- Commissioned a focused subagent sweep of unguarded parsing, persisted-load crashes, and LLM-task correctness; manually confirmed each candidate with file:line citations before filing.

## New issues opened (5)

| # | Title | Label | Summary |
|---|-------|-------|---------|
| 57 | LlmTaskManager._loadFromBox crashes on a single corrupt persisted task record | bug | `_loadFromBox` (llm_task_manager.dart:107-113) calls `LlmTask.fromJson` (with unguarded `DateTime.parse(json['startTime'] as String)` at :56) directly in a loop; one corrupt record throws out of `init()` and loses ALL tasks. Distinct from #51 (LlmUsageMeter). |
| 58 | llm_model_service model-listing endpoints parse HTTP body with unguarded json.decode | bug | `_fetchOpenRouterModels`/`_fetchOllamaModels`/`_fetchOpenAIModels` (llm_model_service.dart:156/171/189) do `json.decode(response.body)` with no try/catch; non-JSON 200 (proxy/HTML) throws to the model-dropdown UI. Distinct from #52 (chat parsing only). |
| 59 | get_adherence_trends_tool silently ignores string-typed 'days' arg from LLM | bug | `get_adherence_trends_tool.dart:39` uses `(args['days'] as num?)?.toInt() ?? 14`; LLM emits `"30"` as a String → `as num?` yields null → always defaults to 14-day window. |
| 60 | LLM tasks left running/queued after app restart are never reset (orphaned tasks) | bug | `init()`/`_loadFromBox` (llm_task_manager.dart:102-121) reloads tasks with no recovery; a `running`/`queued` task killed mid-flight stays active forever. |
| 61 | LlmTaskService token/cost totals sum over failed and orphaned tasks (usage inflation) | bug | `totalTokenUsage`/`totalEstimatedCost` (llm_task_service.dart:32-36, 38-52) fold over every task regardless of status; failed/orphaned/retried tasks inflate usage accounting. |

## De-duplication
Cross-checked `gh issue list --repo TomiWebPro/StudyKing --state open` (#1–#56). Skipped as already covered:
- Lints / tests bootstrap / Result<T> conversion / Logger / silent catches / build-context-async / share_plus / unawaited futures / stale fakes / switch exhaustiveness (#1–#13, #42).
- LLM chat HTTP jsonDecode (#52), Settings/LLM-timestamp DateTime.parse (#53, #54), empty question pool (#55), mentor locale force-unwrap (#56), LlmUsageMeter malformed record (#51), defaultSystemPromptForLocale crash (#50), fuzzy match (#49), late-night (#48), wellbeing cap (#47), practice_screen catchError (#46), duplicate reminders (#45), NotificationService remindAt (#44), firstWhere empty (#43), N+1 (#41), dashboard repos-in-UI (#40), i18n dashboard (#39), plaintext keys (#38), Hive migration (#37), SubjectListScreen (#36), inline Logger (#35), responsive (#34), multi-syllabus (#33/#26), MultiSyllabusInput (#32), streaming token/cost (#31), handwriting/vision (#30), lesson recap (#29), swallowed Result (#28), WeakAreasSheet (#27), lessons-remaining (#25), transcribe URLs (#24), recall prob (#23), PDF (#14), web scraper (#15), rich-question stub (#16), onboarding (#17), VoiceService (#18), avatar (#19), model routing (#20), feedback (#21), variant pipeline (#22).
- None of #57–#61 overlap the above; each targets a distinct file/mechanism (LlmTaskManager load path, model-listing network decode, mentor tool arg parsing, task recovery, usage totals).

## Notes
- Capped at 5 new issues to avoid spam. Only this notes file is committed; no application code modified.
