# Inconsistent & Misleading Feature Directory Structure

## Context

The 14 features under `lib/features/` have drifted into three competing structural conventions with **17 empty placeholder directories** and **two conflicting widget placement patterns**. This makes the codebase harder to navigate, confuses new contributors, and undermines the convention documented in `AGENTS.md`.

## Affected Directories

### 17 empty directories (placeholder clutter)

| Feature | Empty directories |
|---|---|
| `dashboard/` | `services/`, `widgets/`, `presentation/providers/`, `presentation/services/` |
| `lessons/` | `providers/`, `services/`, `widgets/` |
| `llm_tasks/` | `providers/`, `services/`, `widgets/` |
| `planner/` | `providers/`, `services/`, `widgets/` |
| `quickguide/` | `providers/`, `services/`, `widgets/` |

### Two competing widget placement conventions

- **Top-level `widgets/`**: `dashboard/widgets/` (empty), `lessons/widgets/` (empty), `llm_tasks/widgets/` (empty), `planner/widgets/` (empty), `quickguide/widgets/` (empty), `sessions/widgets/` (1 file)
- **`presentation/widgets/`**: `dashboard/presentation/widgets/` (9 files), `focus_mode/presentation/widgets/` (2), `practice/presentation/widgets/` (15), `quickguide/presentation/widgets/` (4), `subjects/presentation/widgets/` (4), `teaching/presentation/widgets/` (2)

### Non-standard directory naming

- `questions/` uses `ui/` and `ui/widgets/` instead of `presentation/` or `widgets/`

## Rationale

1. **Dead directory burden**: 17 empty directories create visual noise, suggest unfinished work, and waste cognitive overhead during navigation. Every developer who browses the tree must mentally filter these out.

2. **Fragmented conventions**: `AGENTS.md` defines `lib/features/*/widgets/*.dart` as the expected location, but 6 features actually place widgets under `presentation/widgets/`. New contributors cannot predict where a widget lives without checking both locations.

3. **Empty placeholder dirs invite stale scope creep**: They suggest "we planned to put something here" — without implementation, they remain as permanent clutter.

4. **`dashboard/presentation/providers/` and `dashboard/presentation/services/`** are nested dead dirs alongside top-level dead dirs, demonstrating two layers of unused scaffolding.

5. **`questions/ui/`** breaks the pattern entirely — every other feature uses `presentation/`, making this an outlier that forces special-case mental mapping.

## Acceptance Criteria

1. Remove all empty directories under `lib/features/` (the 17 listed above).
2. Make a project-wide decision on where widgets live — either:
   - **Option A**: Move ALL widget files to `lib/features/*/widgets/` (aligning with AGENTS.md), or
   - **Option B**: Move ALL widget files to `lib/features/*/presentation/widgets/` (aligning with majority usage), then update AGENTS.md accordingly.
3. Rename `questions/ui/` → `questions/presentation/` to match the project convention (with corresponding `ui/widgets/*` → `presentation/widgets/*`).
4. Update all import paths across the codebase to reflect structural changes.
5. Update `AGENTS.md` to document the chosen canon structure.
6. Verify that `dart analyze` passes with zero errors after all changes.

## Out of scope

- Adding missing test files for untested widgets (separate issue)
- Adding missing `providers/`, `models/`, `data/` directories (only remove empty ones; no need to create new ones until content exists)
