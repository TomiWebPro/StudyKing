# Issue Discovery Log — 2026-08-24 (issue-finder pass 10)

Run by the ISSUE-FINDER agent. No application code was modified; only this notes file is committed.

## Toolchain
- `/opt/flutter/.installed` present → TOOLCHAIN_READY.
- `flutter analyze lib`: **No issues found!** (lib is clean).
- `flutter analyze` (lib + test): **19 issues**, all `invalid_override` compile errors in test fakes of `LlmService.chat`.
- `grep` for `TODO`/`FIXME`/`HACK` in `lib/`: none (only the ARB string "TODOS LOS INTENTOS", false positive).

## Root cause discovered (uncommitted working-tree change)
`git status` shows two uncommitted changes:
- `M lib/core/services/llm/llm_chat_service.dart` — `LlmService.chat` signature changed: `modelId` became nullable (`String? modelId`) and a new `ModelTask task = ModelTask.general` parameter was added (also added `ModelRouter? _router` + `_resolveModelId`).
- `?? lib/core/services/llm/model_router.dart` — new, untracked `ModelRouter`/`ModelTask` source file.

The 19 compile errors are all a direct consequence of the `chat` signature drift: hand-written test fakes override `chat` with the old `required String modelId` (non-nullable) and without `ModelTask task`, so they are no longer valid overrides.

## Scan method
- De-duplicated against `gh issue list --repo TomiWebPro/StudyKing --state open` (issues #1–#71).
- Re-verified prior-sweep claims: unguarded `jsonDecode`/`DateTime.parse` sites (#51–#71) are already filed; `fromOpenRouter`/`fromJson` guards are present; `mastery_graph_service` `result.data!` is guarded by `isFailure`; `shareComprehensiveCSV` throw is inside `Result.capture` (not a violation); `nudges.first` guarded by `isNotEmpty`; `messages.last` always non-empty; `llm_embeddings_service[0]` caught by try/catch.
- Coverage sweep (mirror `lib/features/**` and `lib/core/{services,providers,utils,data}/**` to `test/...`): only `lib/core/services/llm/model_router.dart` lacks a test — the single uncovered production file.

## New issues opened (2)

| # | Title | Label | Summary |
|---|-------|-------|---------|
| 72 | LlmService.chat signature change breaks 19 test fakes (invalid_override compile errors) | bug | The `chat` signature change (nullable `modelId` + new `ModelTask task`) was not propagated to 18 test files (19 `invalid_override` errors). `flutter test` does not compile. Fix = update all fakes + prefer a shared fake. |
| 73 | Add unit test for model_router.dart (ModelRouter routing logic) | enhancement | `model_router.dart` is new/untracked and the only production source file without a unit test (violates AGENTS.md coverage bar). Add `test/core/services/llm/model_router_test.dart`. |

## De-duplication
Cross-checked #1–#71. Skipped (already covered):
- Compile-error issues: #3 (StudyProgressTracker/ContentPipeline fakes), #8 (analyze lints in test files), #10 (roadmap_adapter_test) — distinct from this `chat` override breakage.
- Parsing/Result/Logger/empty-catch/l10n/Hive/provider-barrel coverage issues (#9, #11, #12, #28, #35, #37, #38, #42, #64, etc.) — unaffected by this change.
- model_router coverage is genuinely new (the file did not exist in prior passes).

## Notes
- Capped at 5; only 2 genuinely new, verified, non-duplicate findings existed this pass. No spam.
- Only this notes file is committed; no application code modified.
