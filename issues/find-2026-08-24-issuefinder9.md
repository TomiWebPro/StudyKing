# Issue Discovery Log — 2026-08-24 (issue-finder pass 9)

Run by the ISSUE-FINDER agent. No application code was modified; only this notes file.

## Toolchain
- `/opt/flutter/.installed` present → TOOLCHAIN_READY.
- `flutter analyze lib`: **No issues found!** (consistent with prior passes).
- `grep` for `TODO`/`FIXME`/`HACK` in `lib/`: none (only the ARB string "TODOS LOS INTENTOS" matches, a false positive).

## Scan method
- Reviewed open issues #1–#66 to de-duplicate.
- Grepped `lib/` for `jsonDecode`/`json.decode`/`DateTime.parse` and then **manually verified each candidate's surrounding context** to confirm it is NOT already inside a try/catch (prior passes had flagged many, but most — `agent_loop`, `answer_validation_service`, `content_pipeline:728`, `exercise_evaluator`, `tutor_service:453`, `lesson_agent_service`, `chat_bubble`, `conversation_message_model`, `mastery_recorder`, `spaced_repetition_service`, `agent_memory`, `asr_engine`, `transcription_extractor` — are already guarded). Only genuinely unguarded sites were filed.
- Verified model `fromJson` factories contain unguarded `DateTime.parse`/`as` casts used by Hive adapters.

## New issues opened (5)

| # | Title | Label | Summary |
|---|-------|-------|---------|
| 67 | Unguarded jsonDecode in chunked_content_processor crashes question generation on non-JSON LLM response | bug | `chunked_content_processor.dart:365` raw `jsonDecode(cleaned)` not in try/catch; malformed LLM response throws and aborts ingestion. |
| 68 | slide_deck_generator throws on malformed LLM JSON (unguarded jsonDecode) and aborts deck generation | bug | `slide_deck_generator.dart:241` and `:457` raw `jsonDecode(cleaned)`; non-JSON model output crashes deck generation. |
| 69 | Backup restore crashes (unguarded jsonDecode) when backup file is corrupt or from a newer schema | bug | `data_backup_service.dart:152`/`:155` raw `jsonDecode` on restore; corrupt/truncated/incompatible backup throws and can red-screen Settings. |
| 70 | Question import crashes on malformed file (unguarded jsonDecode/DateTime.parse) violating Result<T> | bug | `question_import_utils.dart:28` (`jsonDecode`) and `:114/121/130` (`DateTime.parse`) unguarded; exceptions escape a method that otherwise returns `Result.failure`, violating AGENTS.md `Result<T>` rule. |
| 71 | Model fromJson methods throw FormatException on corrupt persisted Hive records, crashing box reads app-wide | bug | Multiple domain-model `fromJson` factories call unguarded `DateTime.parse`/`as` on persisted JSON; one corrupt record in a box throws during `box.getAll()` and takes down the feature/startup. Broadens the corrupt-record pattern already filed for LlmUsageMeter (#51), LlmTaskManager (#57), LlmResponseCache (#64). |

## De-duplication
Cross-checked `gh issue list --repo TomiWebPro/StudyKing --state open` (#1–#66). Skipped as already covered:
- Unguarded LLM chat HTTP jsonDecode (#52), model-listing json.decode (#58), Settings `DateTime.parse` (#53), schedule_lesson `DateTime.parse` (#54), LlmTaskManager load (#57), LlmUsageMeter corrupt (#51), LlmResponseCache corrupt (#64), mentor `['en']!` (#56), firstWhere empty (#43), etc.
- Confirmed the candidate files (`chunked_content_processor`, `slide_deck_generator`, `data_backup_service`, `question_import_utils`) and the broad model-`fromJson` set are NOT represented in #1–#66.
- Note: the open list itself contains internal duplicates (#60 and #62 are identical "orphaned LLM tasks after restart"); not reopened.

## Notes
- Capped at 5 new issues to avoid spam. Only this notes file is committed; no application code modified.
