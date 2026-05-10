#!/usr/bin/env python3
"""
StudyKing Auto Improvement Bot
Runs opencode agents in a loop to continuously improve the project.
"""

import datetime
import os
import random
import subprocess
import sys
import time

PROJECT_DIR = "/home/tomi/StudyKing"
OPencode_BIN = "/home/tomi/.opencode/bin/opencode"
FLUTTER_BIN = "/home/tomi/flutter_sdk/bin/flutter"
REPORT_DIR = os.path.join(PROJECT_DIR, ".auto_improve_reports")
CONSECUTIVE_FAILS = 0
MAX_FAILS = 3
RETRY_DELAY_HOURS = 1
CYCLE_COUNT = 0
os.makedirs(REPORT_DIR, exist_ok=True)


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


def run_opencode(prompt, cwd=PROJECT_DIR, timeout_seconds=600):
    log(f"RUNNING opencode (timeout={timeout_seconds}s, prompt first 120 chars): {prompt[:120]}...")
    log(f"CWD: {cwd}")
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
            log(f"opencode output ({len(lines)} lines, last 5):")
            for l in lines[-5:]:
                log(f"  | {l[:200]}")
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


def step1_list_improvements(random_dir):
    ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    safe_name = random_dir.replace("/", "_").replace("\\", "_")
    report_file = os.path.join(REPORT_DIR, f"improvements_{safe_name}_{ts}.md")

    log(f"Step 1: Analyzing {random_dir} for improvements -> {report_file}")
    prompt = (
        f"Analyze the code in the directory `{random_dir}` of the StudyKing project. "
        f"List ALL potential improvements in that code including bugs, "
        f"performance issues, code style problems, and enhancement suggestions. "
        f"For each issue provide the file path, line number, description, severity, and suggested fix. "
        f"Write the complete report in markdown format to the file `{report_file}`. "
        f"Be thorough and exhaustive."
    )
    rc, output = run_opencode(prompt, timeout_seconds=600)
    found = False
    if rc == 0:
        found = True

    found = found or check_md_created(report_file, wait_max=30)

    if not found:
        log("opencode succeeded; saving its output as report", "WARN")
        with open(report_file, "w") as f:
            f.write(output or "# No output from opencode")
        found = os.path.exists(report_file)

    if found:
        log(f"Report saved to {report_file}")
    else:
        log(f"Step 1 FAILED", "ERROR")
    return found, report_file, output


def step2_act_on_report(report_file):
    """Step 2: Point a new opencode agent to the report MD file to act on improvements."""
    log(f"Step 2: Acting on report: {report_file}")
    prompt = (
        f"Read the file `{report_file}` which contains a list of code improvements for the StudyKing project. "
        f"Apply ALL the fixes and improvements described in that report. "
        f"Edit the source files directly to fix bugs, improve performance, enhance code style, and apply suggestions. "
        f"Do NOT skip any item. Be thorough and make all changes."
    )
    rc, output = run_opencode(prompt, timeout_seconds=900)
    if rc != 0:
        log(f"Step 2 FAILED (exit code {rc})", "ERROR")
    else:
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
            f"Keep fixing until `flutter analyze` exits with code 0 (no issues). "
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
        f"First run `git status` and `git diff --staged` to understand the changes. "
        f"Then stage all changes with `git add -A` (but NOT .git-credentials or .env files). "
        f"Create a meaningful commit message summarizing the improvements made. "
        f"Then push to the remote 'origin' on the current branch. "
        f"The remote is already configured with credentials."
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


def main_loop():
    global CONSECUTIVE_FAILS, CYCLE_COUNT

    log("=" * 60)
    log("StudyKing Auto Improvement Bot - STARTING")
    log(f"Project: {PROJECT_DIR}")
    log(f"opencode: {OPencode_BIN}")
    log(f"Flutter: {FLUTTER_BIN}")
    log("=" * 60)

    while True:
        CYCLE_COUNT += 1
        log("")
        log("=" * 60)
        log(f"CYCLE #{CYCLE_COUNT} starting at {datetime.datetime.now()}")
        log("=" * 60)

        cycle_failed = False

        # --- Step 1: List improvements from random subfolder ---
        log("-" * 40)
        random_dir = pick_random_subdir("lib")
        log(f"Step 1: Analyzing {random_dir} for improvements")
        ok, report_file, _ = step1_list_improvements(random_dir)
        if not ok:
            CONSECUTIVE_FAILS += 1
            cycle_failed = True
            log("Step 1 FAILED", "ERROR")
        else:
            log("Step 1 SUCCESS")

            # --- Step 2: Act on the report ---
            log("-" * 40)
            log("Step 2: Acting on improvement report")
            rc2, _ = step2_act_on_report(report_file)
            if should_retry(rc2):
                CONSECUTIVE_FAILS += 1
                cycle_failed = True
                log("Step 2 FAILED", "ERROR")
            else:
                log("Step 2 SUCCESS")
                CONSECUTIVE_FAILS = 0

        # --- Step 3: Flutter analyze and fix ---
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

        # --- Step 4: Improve test coverage ---
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

        # --- Step 5: Commit to GitHub ---
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

        # --- Check failure count ---
        log("-" * 40)
        log(f"Cycle #{CYCLE_COUNT} finished. Cycle failed: {cycle_failed}")
        log(f"Consecutive failures: {CONSECUTIVE_FAILS}/{MAX_FAILS}")

        if CONSECUTIVE_FAILS >= MAX_FAILS:
            log(f"")
            log(f"!!! {MAX_FAILS} consecutive failures reached !!!")
            log(f"Waiting {RETRY_DELAY_HOURS} hour(s) before retrying...")
            log(f"Sleeping until {(datetime.datetime.now() + datetime.timedelta(hours=RETRY_DELAY_HOURS)).strftime('%Y-%m-%d %H:%M:%S')}")
            time.sleep(RETRY_DELAY_HOURS * 3600)
            CONSECUTIVE_FAILS = 0
            log("Retry delay over. Resuming cycles.")
        else:
            log("Starting next cycle immediately...")
            time.sleep(5)


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
