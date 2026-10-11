#!/usr/bin/env python3
"""
StudyKing issue claim locks — open → claimed → done.

Mirrors the video-scout convention (one agent claims ONE issue per run via a
status marker) adapted to StudyKing's issues/open/ + issues/closed/ layout.

Protocol:
  1. BEFORE starting work, claim exactly one issue:
       python3 issues/claim.py claim <slug> <owner>
     Exit 0 = claimed by you. Exit 1 = already claimed (prints the owner) —
     pick another issue. Exit 2 = usage / no such issue.
  2. Fix, verify (flutter analyze + affected tests) per AGENTS.md.
  3. Close (moves to issues/closed/ AND releases the lock):
       python3 issues/claim.py close <slug> <owner>
     Never `mv` a claimed issue by hand, never `git mv`, never commit it.

Lock mechanics:
  - A claim is a sidecar file issues/open/<slug>.md.lock holding JSON
    {owner, claimed_at, pid, host}. Creation uses O_CREAT|O_EXCL, so exactly
    one claimant wins even if two agents race.
  - *.lock files never match the *.md globs the automation uses, and
    issues/open/ + issues/closed/ stay git-untracked (see issues/README.md).
  - Stale claims (older than STALE_AFTER = 2h, beyond the 90min max run
    timeout) are auto-taken-over with a warning; the previous owner is
    recorded in the new lock for audit.

$SK_ISSUES_DIR overrides the issues dir (used for tests).
"""

import json
import os
import socket
import sys
import time
from pathlib import Path

STALE_AFTER = 2 * 3600  # seconds; exceeds the 90min max agent run timeout

SCRIPT_DIR = Path(__file__).resolve().parent
ISSUES_DIR = Path(os.environ.get("SK_ISSUES_DIR", SCRIPT_DIR))
OPEN_DIR = ISSUES_DIR / "open"
CLOSED_DIR = ISSUES_DIR / "closed"


def norm_slug(slug: str) -> str:
    slug = slug.strip()
    if slug.endswith(".lock"):
        slug = slug[: -len(".lock")]
    if not slug.endswith(".md"):
        slug += ".md"
    if "/" in slug or slug in (".md",):
        fail(2, f"invalid slug: {slug!r}")
    return slug


def issue_path(slug: str) -> Path:
    return OPEN_DIR / norm_slug(slug)


def lock_path(slug: str) -> Path:
    return OPEN_DIR / (norm_slug(slug) + ".lock")


def default_owner() -> str:
    return f"{os.environ.get('USER', 'agent')}@{socket.gethostname()}:pid{os.getpid()}"


def read_lock(lp: Path):
    try:
        return json.loads(lp.read_text())
    except (OSError, ValueError):
        return None


def lock_age(lock: dict) -> float:
    try:
        return time.time() - float(lock.get("claimed_at", 0))
    except (TypeError, ValueError):
        return float("inf")


def fail(code: int, msg: str):
    print(msg, file=sys.stderr)
    sys.exit(code)


def cmd_list() -> int:
    files = sorted(p for p in OPEN_DIR.glob("*.md") if p.is_file())
    if not files:
        print("no open issues")
        return 0
    for fp in files:
        lp = Path(str(fp) + ".lock")
        if lp.exists():
            lock = read_lock(lp)
            if lock is None:
                print(f"{fp.name} claimed by <unreadable lock>")
            else:
                age = lock_age(lock)
                stale = " STALE" if age > STALE_AFTER else ""
                print(f"{fp.name} claimed by {lock.get('owner')} ({age:.0f}s ago){stale}")
        else:
            print(f"{fp.name} open")
    return 0


def cmd_claim(slug: str, owner: str) -> int:
    ip = issue_path(slug)
    if not ip.is_file():
        fail(2, f"no such open issue: {ip.name}")
    lp = lock_path(slug)
    payload = json.dumps(
        {"owner": owner, "claimed_at": time.time(), "pid": os.getpid(),
         "host": socket.gethostname()}
    )
    try:
        fd = os.open(lp, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
    except FileExistsError:
        lock = read_lock(lp)
        if lock is not None and lock_age(lock) > STALE_AFTER:
            took = lock.get("owner")
            rec = json.loads(payload)
            rec["took_over_from"] = took
            lp.write_text(json.dumps(rec))
            print(f"STALE lock taken over from {took}: {ip.name} now claimed by {owner}")
            return 0
        holder = lock.get("owner") if lock else "<unreadable>"
        print(f"already claimed by {holder}: {ip.name}")
        return 1
    with os.fdopen(fd, "w") as f:
        f.write(payload)
    print(f"claimed by {owner}: {ip.name}")
    return 0


def _owned_or_stale(lp: Path, owner: str):
    """Returns (ok, message). Only the owner (or anyone, once stale) may proceed."""
    if not lp.exists():
        return False, f"not claimed: {lp.name[:-len('.lock')]}"
    lock = read_lock(lp)
    if lock is None:
        return False, f"unreadable lock, refusing: {lp.name}"
    if lock.get("owner") == owner:
        return True, ""
    if lock_age(lock) > STALE_AFTER:
        return True, f"stale (was {lock.get('owner')})"
    return False, f"claimed by {lock.get('owner')}: {lp.name[:-len('.lock')]}"


def cmd_release(slug: str, owner: str) -> int:
    lp = lock_path(slug)
    ok, msg = _owned_or_stale(lp, owner)
    if not ok:
        fail(1, msg)
    lp.unlink()
    suffix = f" ({msg})" if msg else ""
    print(f"released{suffix}: {lp.name[:-len('.lock')]}")
    return 0


def cmd_close(slug: str, owner: str) -> int:
    ip = issue_path(slug)
    lp = lock_path(slug)
    ok, msg = _owned_or_stale(lp, owner)
    if not ok:
        fail(1, msg + " — close refused, issue stays open")
    if not ip.is_file():
        fail(2, f"no such open issue: {ip.name}")
    CLOSED_DIR.mkdir(parents=True, exist_ok=True)
    ip.rename(CLOSED_DIR / ip.name)  # plain local move, never git mv
    lp.unlink()
    suffix = f" ({msg})" if msg else ""
    print(f"closed{suffix}: {ip.name}")
    return 0


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
        fn = {"claim": cmd_claim, "release": cmd_release, "close": cmd_close}[cmd]
        return fn(argv[2], owner)
    fail(2, f"unknown command: {cmd} (list|claim|release|close)")


if __name__ == "__main__":
    sys.exit(main(sys.argv))
