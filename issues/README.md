# StudyKing local issue tracker

Issues live ONLY here — never in git (`issues/open/` and `issues/closed/` are
untracked; the nightly push explicitly excludes them). `claim.py` and this file
ARE versioned so every agent runs the same protocol.

## States: open → claimed → done

| State | Where | Meaning |
|---|---|---|
| open | `open/<slug>.md` | needs a fix, nobody working on it |
| claimed | `open/<slug>.md` + `open/<slug>.md.lock` | one agent owns it (see lock JSON for owner + time) |
| done | `closed/<slug>.md` | fixed, verified, lock released |

This mirrors the other project's `open → claimed → done` flow: **claim ONE
issue per run**, solve it, close it with evidence.

## Commands (run from the repo root)

- `python3 issues/claim.py list` — open issues with claim status
- `python3 issues/claim.py claim <slug> <owner>` — claim it (exit 1 = someone
  else holds it, pick another; exit 2 = no such issue)
- `python3 issues/claim.py release <slug> <owner>` — give up without closing
- `python3 issues/claim.py close <slug> <owner>` — move to `closed/` and
  release the lock (only the owner may close)

`<slug>` accepts `foo` or `foo.md`. `<owner>` defaults to `user@host:pid`.

## Rules for automation (binding)

1. Claim BEFORE editing any code. If the claim fails, the issue is taken —
   pick another, never work an issue you have not claimed.
2. Only the lock owner may close that issue. `close` refuses otherwise, so a
   concurrent run can neither steal nor double-close your issue.
3. Locks older than 2h are stale (max agent run is 90min) and may be taken
   over; the previous owner is recorded in the new lock.
4. Finders: skip slugs present in `open/` (claimed or not) or `closed/`;
   never create, edit, or delete `*.lock` files; never touch `closed/`.
5. Never `git add`, `git mv`, or commit anything under `open/` or `closed/`.
   Lock sidecars (`*.md.lock`) never match the `*.md` globs the automation
   and `claim.py list` use, so they are invisible to existing tooling.
