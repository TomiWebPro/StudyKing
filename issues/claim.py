#!/usr/bin/env python3
"""
StudyKing issue claim locks — open → claimed → done.

The issue .md file itself is the single source of truth: a `Status:` line
right after the title. There are NO sidecar files, so there is nothing
leftover to go stale.

  Status: open                              anyone may claim it
  Status: claimed by <owner> at <utc-iso>   one agent owns it

Protocol:
  1. BEFORE starting work, claim exactly one issue:
       python3 issues/claim.py claim <slug> <owner>
     Exit 0 = claimed by you. Exit 1 = already claimed (prints the owner) —
     pick another issue. Exit 2 = usage / no such issue.
  2. Fix, verify (flutter analyze + affected tests) per AGENTS.md.
  3. Close (moves to issues/closed/):
       python3 issues/claim.py close <slug> <owner>

Concurrency: every read-modify-write is done while holding an exclusive
`flock` on the issue file itself, so racing claimants serialize and exactly
one wins. The lock is held only for milliseconds and is released by the
kernel if the process dies — it can never go stale. Ownership is the Status
line, not a held lock. Claims older than STALE_AFTER (2h, beyond the 90min
max run timeout) may be taken over; the takeover is recorded on the line.

$SK_ISSUES_DIR overrides the issues dir (used for tests).
"""

import fcntl
import os
import re
import socket
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

STALE_AFTER = 2 * 3600  # seconds; exceeds the 90min max agent run timeout

SCRIPT_DIR = Path(__file__).resolve().parent
ISSUES_DIR = Path(os.environ.get("SK_ISSUES_DIR", SCRIPT_DIR))
OPEN_DIR = ISSUES_DIR / "open"
CLOSED_DIR = ISSUES_DIR / "closed"

STATUS_RE = re.compile(r"^Status:\s*(.*?)\s*$", re.M)
CLAIMED_RE = re.compile(r"^claimed by (.*) at (\S+?)( \(took over from .*\))?\s*$")


def utcnow_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def status_age(ts: str) -> float:
    try:
        dt = datetime.strptime(ts, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
        return time.time() - dt.timestamp()
    except ValueError:
        return float("inf")


def norm_slug(slug: str) -> str:
    slug = slug.strip()
    if not slug.endswith(".md"):
        slug += ".md"
    if "/" in slug or slug in (".md",):
        fail(2, f"invalid slug: {slug!r}")
    return slug


def default_owner() -> str:
    return f"{os.environ.get('USER', 'agent')}@{socket.gethostname()}:pid{os.getpid()}"


def parse_status(text: str):
    """Returns (state, owner, timestamp) with state 'open' or 'claimed'.
    A missing or unrecognised Status line means open (backward compatible)."""
    m = STATUS_RE.search(text)
    if not m:
        return ("open", None, None)
    cm = CLAIMED_RE.match(m.group(1))
    if not cm:
        return ("open", None, None)
    return ("claimed", cm.group(1), cm.group(2))


def set_status(text: str, line: str) -> str:
    if STATUS_RE.search(text):
        return STATUS_RE.sub(line, text, count=1)
    lines = text.split("\n")
    return "\n".join([lines[0], line] + lines[1:]) if lines else line + "\n"


def fail(code: int, msg: str):
    print(msg, file=sys.stderr)
    sys.exit(code)


def cmd_list() -> int:
    files = sorted(p for p in OPEN_DIR.glob("*.md") if p.is_file())
    if not files:
        print("no open issues")
        return 0
    for fp in files:
        with open(fp) as f:
            fcntl.flock(f, fcntl.LOCK_SH)
            try:
                state, owner, ts = parse_status(f.read())
            finally:
                fcntl.flock(f, fcntl.LOCK_UN)
        if state == "claimed":
            age = status_age(ts)
            stale = " STALE" if age > STALE_AFTER else ""
            print(f"{fp.name} claimed by {owner} ({age:.0f}s ago){stale}")
        else:
            print(f"{fp.name} open")
    return 0


def _transact(slug: str, owner: str, action: str) -> int:
    """action: claim | release | close. All mutations happen under LOCK_EX."""
    ip = OPEN_DIR / norm_slug(slug)
    if not ip.is_file():
        fail(2, f"no such open issue: {ip.name}")
    now = utcnow_iso()
    with open(ip, "r+") as f:
        fcntl.flock(f, fcntl.LOCK_EX)
        try:
            text = f.read()
            state, holder, ts = parse_status(text)
            fresh_claim = state == "claimed" and status_age(ts) <= STALE_AFTER

            if action == "claim":
                if fresh_claim:
                    print(f"already claimed by {holder}: {ip.name}")
                    return 1
                note = f" (took over from {holder}, stale)" if state == "claimed" else ""
                f.seek(0)
                f.write(set_status(text, f"Status: claimed by {owner} at {now}{note}"))
                f.truncate()
                print(f"claimed by {owner}{note}: {ip.name}")
                return 0

            # release | close: only the owner (or anyone, once stale) may proceed
            if state != "claimed":
                fail(1, f"not claimed: {ip.name}")
            if holder != owner and status_age(ts) <= STALE_AFTER:
                fail(1, f"claimed by {holder}: {ip.name}"
                        + (" — close refused, issue stays open" if action == "close" else ""))
            stale_note = f" (was {holder}, stale)" if holder != owner else ""
            if action == "release":
                f.seek(0)
                f.write(set_status(text, "Status: open"))
                f.truncate()
                print(f"released{stale_note}: {ip.name}")
                return 0
            # close: rename while still holding the lock, then release
            CLOSED_DIR.mkdir(parents=True, exist_ok=True)
            ip.rename(CLOSED_DIR / ip.name)  # plain local move, never git mv
            print(f"closed{stale_note}: {ip.name}")
            return 0
        finally:
            fcntl.flock(f, fcntl.LOCK_UN)


def main(argv) -> int:
    if len(argv) < 2 or argv[1] in ("-h", "--help"):
        print(__doc__.strip())
        return 0
    cmd = argv[1]
    if cmd == "list":
        return cmd_list()
    if cmd in ("claim", "release", "close"):
        if len(argv) < 3:
            fail(2, f"usage: claim.py {cmd} <slug> [owner]")
        owner = argv[3] if len(argv) > 3 else default_owner()
        return _transact(argv[2], owner, cmd)
    fail(2, f"unknown command: {cmd} (list|claim|release|close)")


if __name__ == "__main__":
    sys.exit(main(sys.argv))
