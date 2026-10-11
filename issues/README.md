# StudyKing local issue tracker

Issues live ONLY here — never in git (`issues/open/` and `issues/closed/` are
untracked; the nightly push explicitly excludes them). `claim.py` and this file
ARE versioned so every agent runs the same protocol.

## States: open → claimed → done

| State | Where | Meaning |
|---|---|---|
| open | `open/<slug>.md` with `Status: open` (or no `Status:` line yet) | needs a fix, nobody working on it |
| claimed | `open/<slug>.md` with `Status: claimed by <owner> at <time>` | one agent owns it |
| done | `closed/<slug>.md` | fixed, verified |

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
   over; the takeover is recorded on the `Status:` line.
4. Finders: every new issue file must carry a `Status: open` line right after
   the title; skip slugs present in `open/` (claimed or not) or `closed/`;
   never edit another issue's `Status:` line; never touch `closed/`.
5. Never `git add`, `git mv`, or commit anything under `open/` or `closed/`.
