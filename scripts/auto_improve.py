#!/usr/bin/env python3
"""
StudyKing Auto Improvement Bot
Runs opencode agents in a loop to continuously improve the project.
"""

import datetime
import os
import random
import shutil
import subprocess
import sys
import threading
import time

PROJECT_DIR = "/home/tomi/StudyKing"
OPencode_BIN = "/home/tomi/.opencode/bin/opencode"
FLUTTER_BIN = "/home/tomi/flutter_sdk/bin/flutter"
REPORT_DIR = os.path.join(PROJECT_DIR, ".auto_improve_reports")
ISSUES_DIR = os.path.join(PROJECT_DIR, "issues")
ISSUES_OPEN_DIR = os.path.join(ISSUES_DIR, "open")
ISSUES_COMPLETED_DIR = os.path.join(ISSUES_DIR, "completed")
CONSECUTIVE_FAILS = 0
MAX_FAILS = 3
RETRY_DELAY_HOURS = 1
CYCLE_COUNT = 0
MASTER_LOOP_DELAY_SECONDS = 20
MAIN_LOOP_DELAY_SECONDS = 5
MASTER_TIMEOUT_SECONDS = 600
MASTERS = [
    {
        "id": "internationalisation_master",
        "title": "Internationalisation Master",
        "focus": (
            "Identify where internationalisation can be improved. Find translation mistakes, "
            "inappropriate localization, missing language support, and better translation opportunities. Currently, focus on localisation of Spanish as an exampel so later more languages can be added easily. "
        ),
    },
    {
        "id": "code_refactor_master",
        "title": "Code Refactor Master & Quality",
        "focus": (
            "Identify readability, maintainability, file placement structure issues, hardcoded components, "
            "dead code, outdated components, inappropriate comment/log levels."
        ),
    },
    {
        "id": "test_master",
        "title": "Test Master",
        "focus": (
            "Identify test coverage gaps, missing test scenarios, and outdated or overly basic tests. Identify improvement oppotunities in the structure of test file placements. "
        ),
    },
    {
        "id": "future_functionality_planner",
        "title": "Future Functionality Planner",
        "focus": (
            "Propose future functionality plans and feature suggestions. You must read agent_must_read.md ; Identify currently redundant or confusing components, "
            "lack of functionality, and high-level roadmap opportunities."
        ),
    },
    {
        "id": "ui_ux_master",
        "title": "UI/UX Master",
        "focus": (
            "Identify accessibility, widget sizing/placement, responsive layout issues, design language inconsistency, "
            "confusing navigation, and problematic animation choices."
        ),
    },
]
os.makedirs(REPORT_DIR, exist_ok=True)
os.makedirs(ISSUES_OPEN_DIR, exist_ok=True)
os.makedirs(ISSUES_COMPLETED_DIR, exist_ok=True)


def log(msg, level="INFO"):
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{ts}] [{level}] {msg}", flush=True)


def get_all_subdirs(base):
    abs_base = os.path.join(PROJECT_DIR, base)
    dirs = []
    for root, subdirs, files in os.walk(abs_base):
        for sd in subdirs:
            full = os.path.join(root, sd)
            if os.listdir(full):
                rel = os.path.relpath(full, PROJECT_DIR)
                dirs.append(rel)
    return dirs


def pick_random_subdir(base="lib"):
    dirs = get_all_subdirs(base)
    if not dirs:
        log(f"No subdirectories found under {base}", "WARN")
        return base
    chosen = random.choice(dirs)
    log(f"Picked random subdirectory: {chosen}")
    return chosen


def check_md_created(path, wait_max=30):
    log(f"Waiting up to {wait_max}s for: {path}")
    for _ in range(wait_max // 2):
        if os.path.exists(path):
            log(f"Found ({os.path.getsize(path)} bytes): {path}")
            time.sleep(2)
            return True
        time.sleep(2)
    log(f"Not found after {wait_max}s", "WARN")
    return False


def master_issue_file(master_id):
    return os.path.join(ISSUES_OPEN_DIR, f"{master_id}.md")


def get_oldest_open_issue_file():
    md_files = []
    for name in os.listdir(ISSUES_OPEN_DIR):
        if name.endswith(".md"):
            md_files.append(os.path.join(ISSUES_OPEN_DIR, name))
    if not md_files:
        return None
    md_files.sort(key=lambda p: os.path.getctime(p))
    return md_files[0]


def completed_issue_path_for(open_issue_path):
    base = os.path.basename(open_issue_path)
    return os.path.join(ISSUES_COMPLETED_DIR, base)


def run_opencode(prompt, cwd=PROJECT_DIR, timeout_seconds=600):
    log(f"RUNNING opencode (timeout={timeout_seconds}s)")
    cmd = [
        OPencode_BIN, "run",
        "--dir", cwd,
        "--dangerously-skip-permissions",
        prompt,
    ]
    try:
        start = time.time()
        result = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=timeout_seconds,
        )
        elapsed = time.time() - start
        output = (result.stdout or "") + "\n" + (result.stderr or "")
        output = output.strip()
        log(f"opencode exited code={result.returncode} in {elapsed:.1f}s")
        if output:
            lines = output.split("\n")
            log(f"opencode output: {len(lines)} lines")
        return result.returncode, output
    except subprocess.TimeoutExpired:
        log(f"opencode TIMEOUT after {timeout_seconds}s", "WARN")
        return -1, "TIMEOUT"
    except Exception as e:
        log(f"opencode EXCEPTION: {e}", "ERROR")
        return -1, str(e)


def run_flutter_analyze(cwd=PROJECT_DIR):
    log("   → flutter analyze")
    cmd = [FLUTTER_BIN, "analyze"]
    try:
        start = time.time()
        result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=120)
        elapsed = time.time() - start
        output = (result.stdout or "") + "\n" + (result.stderr or "")
        output = output.strip()
        issue_count = 0
        for line in output.split("\n"):
            if "error" in line or "warning" in line or "info" in line:
                issue_count += 1
        log(f"   ← flutter analyze exit={result.returncode} in {elapsed:.1f}s, ~{issue_count} issues")
        return result.returncode, output
    except subprocess.TimeoutExpired:
        log(f"   ← flutter analyze TIMEOUT after 120s", "WARN")
        return -1, "TIMEOUT"
    except Exception as e:
        log(f"   ← flutter analyze EXCEPTION: {e}", "ERROR")
        return -1, str(e)


def step2_act_on_oldest_open_master_issue():
    issue_file = get_oldest_open_issue_file()
    if not issue_file:
        log("Step 2: No open master issues found")
        return 0, "NO_OPEN_MASTER_ISSUES"

    random_hint = pick_random_subdir("lib")
    log(f"Step 2: Working on oldest issue: {issue_file}")
    prompt = (
        f"Read the issue markdown file `{issue_file}`. "
        f"Implement the issue in the StudyKing codebase thoroughly. "
        f"Hint: start with folder `{random_hint}` (or another folder if no further improvement is possible there). "
        f"Do not move or edit issue files."
	f"You are advised to read agent_must_read.md before you start coding and update changelog outlined by changelogs/RULES.md once you have completed your task. "
    )
    rc, output = run_opencode(prompt, timeout_seconds=900)
    if rc != 0:
        log(f"Step 2 FAILED (exit code {rc})", "ERROR")
    else:
        if os.path.exists(issue_file):
            completed_path = completed_issue_path_for(issue_file)
            shutil.move(issue_file, completed_path)
            log(f"Step 2: Moved issue to completed: {completed_path}")
        else:
            log("Step 2: Open issue file missing after completion", "WARN")
        log("Step 2 completed successfully")
    return rc, output


def step3_fix_flutter_analyze():
    log("=" * 60)
    log("Step 3: Fix ALL flutter analyze issues (loop until clean)")
    MAX_ATTEMPTS = 5

    for attempt in range(1, MAX_ATTEMPTS + 1):
        log(f"  ── Attempt {attempt}/{MAX_ATTEMPTS} ──")

        # Check current state
        rc, output = run_flutter_analyze()
        if rc == 0:
            log("  ✓ flutter analyze: CLEAN (no issues)")
            return True

        # Save snapshot
        ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        snapshot = os.path.join(REPORT_DIR, f"analyze_errors_{ts}_attempt{attempt}.txt")
        with open(snapshot, "w") as f:
            f.write(output or "No output")

        # Count issues
        errors = len([l for l in output.split("\n") if "error" in l])
        warnings = len([l for l in output.split("\n") if "warning" in l and "error" not in l])
        log(f"  → {errors} errors, {warnings} warnings remaining")
        log(f"  → Snapshot: {snapshot}")

        # Launch opencode to fix all in one session
        log(f"  → Launching opencode to fix all remaining flutter analyze issues")
        prompt = (
            f"Run `flutter analyze` in the StudyKing project directory to see all current issues. "
            f"Then fix EVERY single error, warning, and info issue in the source code. "
            f"After fixing, run `flutter analyze` again. "
            f"If any issues remain, fix them too. "
            f"Keep fixing until `flutter analyze` exits with code 0 (no issues). Do not remove any existing functionalities when doing so. "
            f"Do NOT stop until flutter analyze is completely clean."
        )
        rc2, output2 = run_opencode(prompt, timeout_seconds=900)

        if rc2 == -9:
            log(f"  ✗ opencode KILLED (SIGKILL/-9) — likely OOM", "ERROR")
            log(f"  → Skipping verify to avoid repeat OOM. Will retry next cycle.", "WARN")
            return False

        if rc2 != 0:
            log(f"  ✗ opencode exited code={rc2} (attempt {attempt})", "WARN")

        # Python verifies after opencode exits
        log(f"  → Verifying result...")
        # (loop continues to top where run_flutter_analyze() runs again)

    log(f"  ✗ Step 3: All {MAX_ATTEMPTS} attempts exhausted", "ERROR")
    return False


def step4_improve_test_coverage(random_dir):
    """Step 4: Point opencode to improve test coverage for a random directory."""
    log(f"Step 4: Improving test coverage for: {random_dir}")
    prompt = (
        f"Improve test code coverage for the directory `{random_dir}` in the StudyKing project. "
        f"Analyze the existing tests in `test/` and identify gaps. "
        f"Write comprehensive unit tests, widget tests, and any missing tests for the code in `{random_dir}`. "
        f"Create new test files in the `test/` directory following the existing test conventions. "
        f"Aim for at least 80% code coverage for the `{random_dir}` directory. "
        f"Run the tests after writing them to make sure they pass."
    )
    rc, output = run_opencode(prompt, timeout_seconds=900)
    if rc != 0:
        log(f"Step 4 FAILED (exit code {rc})", "ERROR")
    else:
        log("Step 4 completed successfully")
    return rc, output


def step5_commit_to_github():
    """Step 5: Commit all changes and push to GitHub."""
    log("Step 5: Committing and pushing to GitHub")

    # Determine commit message based on changes
    try:
        status_result = subprocess.run(
            ["git", "status", "--porcelain"],
            cwd=PROJECT_DIR, capture_output=True, text=True, timeout=30
        )
        changes = status_result.stdout.strip()
        if not changes:
            log("No changes to commit")
            return True

        # Count changes by type
        lines = changes.split("\n")
        modified = sum(1 for l in lines if l.startswith(" M") or l.startswith("M "))
        added = sum(1 for l in lines if l.startswith("??") or l.startswith("A "))
        deleted = sum(1 for l in lines if l.startswith(" D") or l.startswith("D "))
        log(f"Changes: {added} added, {modified} modified, {deleted} deleted")
    except Exception as e:
        log(f"Could not check git status: {e}", "WARN")
        lines = []
        modified = 0

    # Use opencode to commit
    prompt = (
        f"Commit all current changes in the StudyKing project to the git repository. "
        f"First run `git status` and `git diff --staged` to understand the changes. Then read changelogs to deepen understanding."
        f"Then stage all changes with `git add -A` (but NOT .git-credentials or .env files). "
        f"Create a meaningful commit message summarizing the improvements made. "
        f"Then push to the remote 'origin' on the current branch. Confirm it. "
        f"The remote is already configured with credentials."
	f"After pushing to main, remove all md files in changelogs folder except RULES.md "
    )
    rc, output = run_opencode(prompt, timeout_seconds=300)
    if rc != 0:
        log(f"Step 5 FAILED (exit code {rc})", "ERROR")
    else:
        log("Step 5 completed successfully")
    return rc, output


def should_retry(rc):
    """Check if a return code indicates failure."""
    return rc != 0


def run_master_once(master):
    open_file = master_issue_file(master["id"])
    if os.path.exists(open_file):
        return False

    random_hint = pick_random_subdir("lib")
    prompt = (
        f"You are `{master['title']}` for the StudyKing project. "
        f"You must NOT edit any source code or files outside the issue output file. "
        f"Your only allowed write action is to create exactly one markdown issue file at `{open_file}`. "
        f"If this issue file already exists, do nothing and exit. "
        f"Read the codebase and identify high-value issues only (not surface-level bug fixing). "
        f"Focus: {master['focus']} "
        f"Hint: start inspecting `{random_hint}` (or other folders if needed). "
        f"Write a single actionable issue with context, affected files, rationale, and acceptance criteria."
    )
    rc, _ = run_opencode(prompt, timeout_seconds=MASTER_TIMEOUT_SECONDS)
    if rc == 0 and os.path.exists(open_file):
        log(f"Master created issue: {open_file}")
        return True
    log(f"Master `{master['title']}` did not create issue this round", "WARN")
    return False


def master_worker(master):
    log(f"Starting background worker: {master['title']}")
    while True:
        try:
            if os.path.exists(master_issue_file(master["id"])):
                time.sleep(MASTER_LOOP_DELAY_SECONDS)
                continue
            run_master_once(master)
        except Exception as e:
            log(f"Master worker error ({master['title']}): {e}", "ERROR")
        time.sleep(MASTER_LOOP_DELAY_SECONDS)


def start_master_workers():
    threads = []
    for master in MASTERS:
        t = threading.Thread(target=master_worker, args=(master,), daemon=True)
        t.start()
        threads.append(t)
    return threads


def main_loop():
    global CONSECUTIVE_FAILS, CYCLE_COUNT

    log("=" * 60)

    start_master_workers()
    log("Started all master workers in parallel")
    log("StudyKing Auto Improvement Bot - STARTING")
    log(f"Project: {PROJECT_DIR}")
    log(f"opencode: {OPencode_BIN}")
    log(f"Flutter: {FLUTTER_BIN}")
    log("=" * 60)

    while True:
        CYCLE_COUNT += 1
        log("=" * 60)
        log(f"CYCLE #{CYCLE_COUNT} starting at {datetime.datetime.now()}")
        log("=" * 60)

        cycle_failed = False

        log("-" * 40)
        log("Step 1/2: Working on oldest open master issue")
        rc2, _ = step2_act_on_oldest_open_master_issue()
        if should_retry(rc2):
            CONSECUTIVE_FAILS += 1
            cycle_failed = True
            log("Step 1/2 FAILED", "ERROR")
        else:
            log("Step 1/2 SUCCESS")
            CONSECUTIVE_FAILS = 0

        if not cycle_failed:
            log("-" * 40)
            try:
                ok3 = step3_fix_flutter_analyze()
                if not ok3:
                    CONSECUTIVE_FAILS += 1
                    cycle_failed = True
                    log("Step 3 FAILED", "ERROR")
                else:
                    log("Step 3 SUCCESS")
                    CONSECUTIVE_FAILS = 0
            except Exception as e:
                log(f"Step 3 exception: {e}", "ERROR")
                CONSECUTIVE_FAILS += 1
                cycle_failed = True

        if not cycle_failed:
            log("-" * 40)
            random_test_dir = pick_random_subdir("lib")
            log(f"Step 4: Improving test coverage for {random_test_dir}")
            rc4, _ = step4_improve_test_coverage(random_test_dir)
            if should_retry(rc4):
                CONSECUTIVE_FAILS += 1
                cycle_failed = True
                log("Step 4 FAILED", "ERROR")
            else:
                log("Step 4 SUCCESS")
                CONSECUTIVE_FAILS = 0

        if not cycle_failed:
            log("-" * 40)
            log("Step 5: Committing to GitHub")
            rc5, _ = step5_commit_to_github()
            if should_retry(rc5):
                CONSECUTIVE_FAILS += 1
                cycle_failed = True
                log("Step 5 FAILED", "ERROR")
            else:
                log("Step 5 SUCCESS")
                CONSECUTIVE_FAILS = 0

        log("-" * 40)
        log(f"Cycle #{CYCLE_COUNT} finished. Cycle failed: {cycle_failed}")
        log(f"Consecutive failures: {CONSECUTIVE_FAILS}/{MAX_FAILS}")

        if CONSECUTIVE_FAILS >= MAX_FAILS:
            log(f"!!! {MAX_FAILS} consecutive failures reached !!!")
            log(f"Waiting {RETRY_DELAY_HOURS} hour(s) before retrying...")
            log(f"Sleeping until {(datetime.datetime.now() + datetime.timedelta(hours=RETRY_DELAY_HOURS)).strftime('%Y-%m-%d %H:%M:%S')}")
            time.sleep(RETRY_DELAY_HOURS * 3600)
            CONSECUTIVE_FAILS = 0
            log("Retry delay over. Resuming cycles.")
        else:
            log("Starting next cycle immediately...")
            time.sleep(MAIN_LOOP_DELAY_SECONDS)


if __name__ == "__main__":
    try:
        main_loop()
    except KeyboardInterrupt:
        log("")
        log("Bot stopped by user (Ctrl+C)")
        sys.exit(0)
    except Exception as e:
        log(f"FATAL ERROR: {e}", "FATAL")
        import traceback
        traceback.print_exc()
        sys.exit(1)
