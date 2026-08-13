#!/usr/bin/env python3
"""
Issue Fixer Loop — processes one open issue at a time via `opencode`.
After the agent finishes, verifies actual source code changes were made
before moving the issue to closed/.
"""

import sys
import subprocess
import time
import logging
from pathlib import Path

ISSUES_DIR = Path(__file__).parent
OPEN_DIR = ISSUES_DIR / "open"
CLOSED_DIR = ISSUES_DIR / "closed"
LOG_FILE = ISSUES_DIR / "issue_loop.log"
PROJECT_DIR = ISSUES_DIR.parent

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(sys.stdout),
    ],
)


def get_open_issues():
    return sorted(
        [f for f in OPEN_DIR.iterdir() if f.suffix == ".md"],
        key=lambda p: p.name,
    )


def get_non_issue_diff() -> str:
    result = subprocess.run(
        ["git", "diff", "--stat"],
        cwd=PROJECT_DIR,
        capture_output=True,
        text=True,
    )
    lines = result.stdout.strip().split("\n")
    non_issue = [l for l in lines if "issues/" not in l]
    return "\n".join(non_issue).strip()


def run_opencode(issue_path: Path) -> bool:
    prompt = (
        f"Fix the issue described in the file {issue_path}. "
        f"Read it, understand the problem, implement the fix, "
        f"run lint/typecheck/tests, and confirm when done."
    )
    logging.info(f"Processing issue: {issue_path.name}")

    result = subprocess.run(
        ["opencode", "run", "--auto", prompt],
        cwd=PROJECT_DIR,
        capture_output=False,
        text=True,
    )

    if result.returncode == 0:
        logging.info(f"SUCCESS: {issue_path.name} — opencode exited cleanly")
        return True
    else:
        logging.warning(
            f"FAILED: {issue_path.name} — exit code {result.returncode}"
        )
        return False


def main():
    logging.info("=== Issue Fixer Loop started ===")

    while True:
        open_issues = get_open_issues()

        if not open_issues:
            logging.info("No open issues remaining. Waiting for new issues...")
            time.sleep(60)
            continue

        for issue in open_issues:
            diff_before = get_non_issue_diff()
            success = run_opencode(issue)

            if success:
                diff_after = get_non_issue_diff()
                if diff_after and diff_after != diff_before:
                    dest = CLOSED_DIR / issue.name
                    issue.rename(dest)
                    remaining = len(get_open_issues())
                    logging.info(
                        f"REAL FIX CONFIRMED — {issue.name} moved to closed/. "
                        f"{remaining} remaining."
                    )
                else:
                    logging.warning(
                        f"NO real changes for {issue.name}. "
                        f"Agent likely skipped. Moving on."
                    )
            else:
                logging.info(
                    f"Will retry {issue.name} on next iteration "
                    f"(waiting 10s before re-checking list)."
                )
                time.sleep(10)
                break

        time.sleep(5)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        logging.info("=== Issue Fixer Loop stopped by user ===")
        sys.exit(0)
