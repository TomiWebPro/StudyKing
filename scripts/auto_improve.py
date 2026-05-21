#!/usr/bin/env python3
"""
StudyKing Auto Improvement Bot
Runs opencode agents in a loop to continuously improve the project.
"""

import datetime
import os
import random
import re
import fcntl
import shutil
import signal
import subprocess
import sys
import threading
import time

PROJECT_DIR = "/home/tomi/StudyKing"
OPencode_BIN = "opencode"
FLUTTER_BIN = "flutter"
REPORT_DIR = os.path.join(PROJECT_DIR, ".auto_improve_reports")
ISSUES_DIR = os.path.join(PROJECT_DIR, "issues")
ISSUES_OPEN_DIR = os.path.join(ISSUES_DIR, "open")
ISSUES_COMPLETED_DIR = os.path.join(ISSUES_DIR, "completed")
CONSECUTIVE_FAILS = 0
MAX_FAILS = 3

CYCLE_COUNT = 0
MASTER_LOOP_DELAY_SECONDS = 20
MAIN_LOOP_DELAY_SECONDS = 5
MASTER_TIMEOUT_SECONDS = 600
SCENARIO_TIMEOUT_SECONDS = 900
IDLE_TIMEOUT_SECONDS = 300
CONNECTION_RETRY_DELAYS = [5, 15, 45]

CONNECTION_ERROR_PATTERNS = [
    "connection refused",
    "connection reset",
    "connection aborted",
    "connection timed out",
    "network is unreachable",
    "econnrefused",
    "econnreset",
    "econnaborted",
    "etimedout",
    "rate limit exceeded",
    "too many requests",
    "bad gateway",
    "service unavailable",
    "gateway timeout",
    "internal server error",
    "api key authentication failed",
    "invalid api key",
    "unauthorized",
]
MASTERS = [
    {
        "id": "internationalisation_master",
        "title": "Internationalisation Master",
        "focus": (
            "Identify internationalisation issues across the entire codebase. Explore freely without "
            "limiting yourself to a predetermined set of files. Look for:\n"
            "- Hardcoded user-facing strings that should be localised via AppLocalizations\n"
            "- Translation errors or missing translations in .arb files\n"
            "- Locale-unaware number/date formatting (toStringAsFixed, manual date strings) "
            "that should use number_format_utils.dart\n"
            "- RTL layout issues (no Directionality support, hardcoded left/right alignments)\n"
            "- Pluralisation gaps in .arb files\n"
            "- Missing locale-specific formatting for currencies, percentages, compact numbers\n"
            "- UI layouts that break with longer translated strings (e.g. German compound words)\n"
            "- LLM prompts that are hardcoded in English without locale support\n"
            "Focus on Spanish as the target locale so other languages can follow the same pattern."
        ),
    },
    {
        "id": "code_refactor_master",
        "title": "Code Refactor Master & Quality",
        "focus": (
            "Explore the codebase freely without being constrained to a predetermined set of files. "
            "Identify:\n"
            "- Dead or unreachable code (unused imports, parameters, classes, functions)\n"
            "- Circular dependencies between modules or features\n"
            "- Overly long or complex functions that violate single-responsibility principle\n"
            "- Inconsistent error handling (some places use Result type, others throw raw exceptions)\n"
            "- Redundant abstractions or unnecessary wrappers\n"
            "- File placement violations (e.g. a core concept buried inside a feature folder)\n"
            "- Outdated or misleading comments, wrong log levels (debug vs info vs error)\n"
            "- Hardcoded configuration values that should be environment-driven\n"
            "- Repeated code patterns that could be extracted into shared utilities"
        ),
    },
    {
        "id": "test_master",
        "title": "Test Master",
        "focus": (
            "Explore the codebase freely and cross-reference against the test conventions in AGENTS.md. "
            "Identify:\n"
            "- Source files in lib/features/*/ with no corresponding test file (see AGENTS.md for exact mapping)\n"
            "- Test files that only contain construction checks (isNotNull, isA) without behavioral assertions\n"
            "- Missing error-state tests (what happens when a service throws?)\n"
            "- Provider tests that don't verify dependency wiring via overrides\n"
            "- Unit tests mixed with widget tests in the same file\n"
            "- Integration gaps: features that have no test coverage at all\n"
            "- Tests that use mockito/mocktail instead of hand-written fakes\n"
            "- Widget tests that don't verify navigation behaviour with NavigatorObserver\n"
            "- Tests that depend on Hive I/O instead of using fixedStudentId or fake repos"
        ),
    },
    {
        "id": "future_functionality_planner",
        "title": "Future Functionality Planner",
        "focus": (
            "First read agent_must_read.md to understand the full product vision. Then explore the codebase "
            "freely without being constrained to a predetermined set of files. Compare the vision against "
            "what is actually implemented. Identify:\n"
            "- Major vision features that have zero implementation (e.g. voice interaction, handwriting recognition, "
            "video/audio ingestion, proactive engagement/notifications)\n"
            "- Features that exist but in a stub/incomplete state\n"
            "- Redundant or confusing components that don't serve the vision\n"
            "- Architectural gaps that block implementing vision features (e.g. no notification service, "
            "no token usage tracker, no task manager for LLM inference)\n"
            "- High-value roadmap items ordered by impact on the student experience\n"
            "Propose specific, actionable plans for the next development phase."
            "If available, the human coder himself would put md files in issues/further_issues/open, these are issues raised by real user beta testing and suggestions, if its present, write the md file so that the coder would prioritise on fixing those issues. When done fixing those issues, md file must be removed and acknowledged in issues/further_issues/completed"
        ),
    },
    {
        "id": "ui_ux_master",
        "title": "UI/UX Master",
        "focus": (
            "Explore the codebase freely without being constrained to a predetermined set of files. "
            "Open screens and trace navigation flows. Identify:\n"
            "- Confusing or dead-end navigation paths (user clicks something and nothing happens)\n"
            "- Missing UI states: no loading indicator, no empty state, no error state on screens\n"
            "- Inconsistent design language: different button styles, colour mismatches, font inconsistencies\n"
            "- Responsive/layout issues: widgets that overflow, don't adapt to screen size\n"
            "- Accessibility problems: low contrast, missing semantics, no TalkBack/voiceover labels, "
            "small touch targets\n"
            "- Animation issues: jarring transitions, excessive or missing motion\n"
            "- Screens that show raw technical data instead of user-friendly information\n"
            "- Missing onboarding or first-launch guidance for new users\n"
            "- Any components can use refractored and reused\n"
            "- Anything else. "
        ),
    },
    {
        "id": "dry_run_usability_validator",
        "title": "Dry-Run Usability Validator",
        "focus": "",
        "timeout": 900,
        "scenario_prompt": (
            "You are the Dry-Run Usability Validator for the StudyKing project. "
            "Your job is NOT to edit source code. Your ONLY output is: "
            "1. A new dry-run test scenario markdown file in `dry-run-test/` describing a real user journey. "
            "2. An issue markdown file in `issues/open/dry_run_usability_validator.md` listing problems found. First read agent_must_read.md to understand the full product vision."
            "\n\n"
            "=== PHASE 1: CREATE A SCENARIO ===\n"
            "Generate ONE concrete user scenario that has NOT yet been described in `dry-run-test/` "
            "(read existing files first to avoid duplicates). Write it to: "
            "`dry-run-test/scenario_<topic>.md`\n"
            "The scenario must be written from the perspective of a real user, for example:\n"
            "\"I'm a new user opening StudyKing for the first time. I want to learn IB Chemistry. "
            "I don't know what this program is about or what it can do.\"\n"
            "\n"
            "\"I'm a longterm user, I want to speed up my pace to learn in Physics. "
            "\n"
            "I was learning about physics but now I want to learn about another subject. \"\n"
            "I want to change API provider now. \"\n"
            "I want to reschedule a class to another time. \"\n"
            "\n"
            "Describe the user's goal step by step in plain language — what they expect to happen at each stage. "
            "Include expectations like:\n"
            "- On first launch, does the app explain itself or just show a blank screen?\n"
            "- Does it nudge me to upload content (PDFs, notes, question banks), or do I have to hunt for the feature?\n"
            "- Can I just tell the planner 'I want to learn IB Chemistry in 90 days' and have everything generated automatically?\n"
            "- Are lesson plans, lesson content, and practice questions auto-generated from the syllabus, "
            "or do I need to manually create everything?\n"
            "- Does the system detect missing materials (no textbook uploaded, no syllabus, no questions) "
            "and guide me to fix that, or does it silently break?\n"
            "- Can I easily find where to configure my API key, and if it's missing, does the app show a clear error message?\n"
            "- Does navigation make it obvious where to find my lessons, my practice, my progress?\n"
            "- Are settings applied immediately and saved across restart?\n"
            "- Does the app require me to give it things that are totally not central to the program itself and add no value?\n"
            "(and any expectations beyond what were listed)\n"
            "=== PHASE 2: DRY-RUN VALIDATE ===\n"
            "Now trace through the actual source code to validate the scenario. Explore the codebase freely "
            "without being constrained to a predetermined set of files. Look at startup flow, navigation routes, "
            "screens, state management, data dependencies, and any other relevant parts you discover. "
            "The goal is to independently trace each user expectation against the actual implementation.\n"
            "\n"
            "For each step in the scenario, determine:\n"
            " - Does the code support this user expectation? (PASS / FAIL / PARTIAL)\n"
            " - If FAIL or PARTIAL, what exactly is missing or broken in the navigation?\n"
            " - What specific screens, files and lines are responsible?\n"
            "\n"
            "=== PHASE 3: WRITE ISSUE ===\n"
            "Write all findings into `issues/open/dry_run_usability_validator.md`. "
            "The issue must include:\n"
            "- The scenario summary\n"
            "- For every FAIL/PARTIAL finding: affected files, rationale, and concrete acceptance criteria for what 'fixed' looks like\n"
            "- Group findings by severity (BLOCKER = app crashes or user cannot proceed, MAJOR = feature is broken or misleading, MINOR = UX friction)\n"
            "\n"
            "IMPORTANT:\n"
            "- Do NOT edit any source code files.\n"
            "- If the issue file already exists, read it first and add NEW findings or refine existing ones — don't overwrite.\n"
            "- If all scenarios in `dry-run-test/` already have matching issues resolved, pick a new scenario.\n"
            "- This is a non-delete zone: never delete previous dry-run test files."
        ),
    },
    {
        "id": "dry_run_result_validator",
        "title": "Dry-Run Result Validator",
        "focus": "",
        "timeout": 900,
        "recurring": True,
        "scenario_prompt": (
            "You are the Dry-Run Result Validator for the StudyKing project. "
            "Your job is NOT to edit source code. "
            "First read agent_must_read.md to understand the full product vision. "
            "Then read the scenario file `dry-run-test/{chosen_file}` and "
            "trace through the actual source code to check each step. "
            "For each step, determine if it is now completed in the current code "
            "(COMPLETED / NOT_COMPLETED / PARTIAL) and what is still missing. "
            "Update `{chosen_file}` with the validation results: append a section "
            "at the bottom showing each step's completion status and code references. "
            "If ALL steps are COMPLETED or the scenario is largely done (>80%), "
            "delete the scenario file `{chosen_file}` — it is no longer needed. "
            "If any NOT_COMPLETED or PARTIAL steps remain, write an issue file at "
            "`issues/open/{issue_file}` documenting what still needs to be fixed."
        ),
    },
]
os.makedirs(REPORT_DIR, exist_ok=True)
os.makedirs(ISSUES_OPEN_DIR, exist_ok=True)
os.makedirs(ISSUES_COMPLETED_DIR, exist_ok=True)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LOG_FILE = os.path.join(SCRIPT_DIR, "auto_improve.log")

LOCK_FILE = "/tmp/studyking-auto-improve.lock"
CHILD_PIDS = []
SHUTDOWN_REQUESTED = False


def log(msg, level="INFO"):
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] [{level}] {msg}"
    print(line, flush=True)
    with open(LOG_FILE, "a") as f:
        f.write(line + "\n")


def get_all_subdirs(base):
    abs_base = os.path.join(PROJECT_DIR, base)
    dirs = []
    for root, subdirs, files in os.walk(abs_base):
        for sd in subdirs:
            full = os.path.join(root, sd)
            try:
                if os.listdir(full):
                    rel = os.path.relpath(full, PROJECT_DIR)
                    dirs.append(rel)
            except PermissionError:
                log(f"Skipping inaccessible directory: {full}", "WARN")
    return dirs


def pick_random_subdir(base="lib"):
    dirs = get_all_subdirs(base)
    if not dirs:
        log(f"No subdirectories found under {base}", "WARN")
        return base
    chosen = random.choice(dirs)
    log(f"Picked random subdirectory: {chosen}")
    return chosen


def _run_process_simple(cmd, cwd, timeout_seconds, input_data=None):
    """Run a command with a simple timeout. Kills hard if exceeded."""
    proc = subprocess.Popen(
        cmd,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        stdin=subprocess.PIPE if input_data is not None else None,
        preexec_fn=os.setsid,
    )
    CHILD_PIDS.append(proc.pid)
    try:
        stdout, stderr = proc.communicate(input=input_data, timeout=timeout_seconds)
        output = ((stdout or b"").decode() + "\n" + (stderr or b"").decode()).strip()
        try:
            CHILD_PIDS.remove(proc.pid)
        except ValueError:
            pass
        return proc.returncode, output
    except subprocess.TimeoutExpired:
        proc.kill()
        proc.wait()
        try:
            CHILD_PIDS.remove(proc.pid)
        except ValueError:
            pass
        return -1, "TIMEOUT"


def _run_process_monitored(cmd, cwd, timeout_seconds, input_data=None, idle_timeout=IDLE_TIMEOUT_SECONDS):
    """Run a command with real-time output monitoring.

    - Reads stdout/stderr incrementally via background threads.
    - Kills the process (SIGINT → 5s grace → SIGKILL) if:
      a) idle_timeout seconds pass with zero output (suggests dead connection)
      b) a connection-error pattern is spotted in the output
      c) the wall-clock timeout_seconds is exceeded
    - Returns (-2, output) for connection/idle failures so the caller can retry.
    """
    proc = subprocess.Popen(
        cmd,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        stdin=subprocess.PIPE if input_data is not None else None,
        preexec_fn=os.setsid,
    )
    CHILD_PIDS.append(proc.pid)

    output_lines = []
    lock = threading.Lock()
    last_output_time = [time.time()]
    flag_connection_error = [False]

    def reader(stream):
        for raw in iter(stream.readline, b''):
            line = raw.decode(errors='replace')
            with lock:
                output_lines.append(line)
                last_output_time[0] = time.time()
                lower = line.lower()
                for pat in CONNECTION_ERROR_PATTERNS:
                    if re.search(pat, lower):
                        flag_connection_error[0] = True
                        break
        stream.close()

    tout = threading.Thread(target=reader, args=(proc.stdout,), daemon=True)
    terr = threading.Thread(target=reader, args=(proc.stderr,), daemon=True)
    tout.start()
    terr.start()

    if input_data is not None:
        proc.stdin.write(input_data)
        proc.stdin.close()

    def _terminate():
        """SIGINT → 5s grace → SIGKILL, then reap."""
        proc.send_signal(signal.SIGINT)
        time.sleep(5)
        if proc.poll() is None:
            proc.kill()
        proc.wait()
        tout.join(timeout=5)
        terr.join(timeout=5)

    start_time = time.time()

    while True:
        ret = proc.poll()
        if ret is not None:
            tout.join(timeout=10)
            terr.join(timeout=10)
            with lock:
                output = "".join(output_lines).strip()
                ce = flag_connection_error[0]
            try:
                CHILD_PIDS.remove(proc.pid)
            except ValueError:
                pass
            return (-2 if ce else ret, output)

        elapsed = time.time() - start_time

        with lock:
            idle = time.time() - last_output_time[0]
            ce = flag_connection_error[0]

        if ce:
            _terminate()
            try:
                CHILD_PIDS.remove(proc.pid)
            except ValueError:
                pass
            with lock:
                output = "".join(output_lines).strip()
            return -2, output

        if idle > idle_timeout:
            _terminate()
            try:
                CHILD_PIDS.remove(proc.pid)
            except ValueError:
                pass
            with lock:
                output = "".join(output_lines).strip()
            return -2, output + "\nIDLE_TIMEOUT"

        if elapsed > timeout_seconds:
            _terminate()
            try:
                CHILD_PIDS.remove(proc.pid)
            except ValueError:
                pass
            with lock:
                output = "".join(output_lines).strip()
            return -1, output + "\nTIMEOUT"

        time.sleep(0.5)


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
    md_files.sort(key=lambda p: os.path.getmtime(p))
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

    last_output = ""
    for attempt, delay in enumerate([0] + CONNECTION_RETRY_DELAYS):
        if attempt > 0:
            log(f"Connection retry {attempt}/{len(CONNECTION_RETRY_DELAYS)} after {delay}s...")
            time.sleep(delay)

        start = time.time()
        rc, output = _run_process_monitored(cmd, cwd, timeout_seconds)
        elapsed = time.time() - start
        last_output = output

        if rc == -2:
            log(f"opencode CONNECTION LOST after {elapsed:.1f}s (idle/error pattern)", "WARN")
            continue

        if rc == -1 and "TIMEOUT" in output:
            log(f"opencode TIMEOUT after {timeout_seconds}s", "WARN")
        elif rc != 0:
            log(f"opencode FAILED (exit {rc}) in {elapsed:.1f}s", "WARN")
        else:
            log(f"opencode SUCCESS in {elapsed:.1f}s")

        log(f"opencode exited code={rc} in {elapsed:.1f}s")
        return rc, output

    log(f"All {len(CONNECTION_RETRY_DELAYS)} connection retries exhausted", "ERROR")
    return -2, last_output


def run_flutter_analyze(cwd=PROJECT_DIR):
    log("   → flutter analyze")
    cmd = [FLUTTER_BIN, "analyze"]
    start = time.time()
    rc, output = _run_process_simple(cmd, cwd, 120)
    elapsed = time.time() - start
    issue_count = 0
    for line in output.split("\n"):
        if "error" in line or "warning" in line or "info" in line:
            issue_count += 1
    log(f"   ← flutter analyze exit={rc} in {elapsed:.1f}s, ~{issue_count} issues")
    return rc, output


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
        f"Do not move or edit issue files. "
        f"You are advised to read agent_must_read.md before you start coding and update changelog outlined by changelogs/RULES.md once you have completed your task. "
    )
    rc, output = run_opencode(prompt, timeout_seconds=1800)
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
        rc2, output2 = run_opencode(prompt, timeout_seconds=1800)

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
    rc, output = run_opencode(prompt, timeout_seconds=1800)
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
            return 0, "No changes"

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
        f"First run `git status` and `git diff --staged` to understand the changes. Then read changelogs to deepen understanding. "
        f"Then stage all changes with `git add -A` (but NOT .git-credentials or .env files). "
        f"Create a meaningful commit message summarizing the improvements made. "
        f"Then push to the remote 'origin' on the current branch. Confirm it. "
        f"The remote is already configured with credentials. "
        f"After pushing to main, remove all md files in changelogs folder except RULES.md "
    )
    rc, output = run_opencode(prompt, timeout_seconds=300)
    if rc != 0:
        log(f"Step 5 FAILED (exit code {rc})", "ERROR")
    else:
        log("Step 5 completed successfully")
    return rc, output


RECIPIENT_EMAIL = "370348116@qq.com"


def step6_review_changes():
    """Step 6: After successful push, review completed + open issues, then email."""
    log("Step 6: Reviewing completed and open issues")

    completed_files = sorted(
        [os.path.join(ISSUES_COMPLETED_DIR, f) for f in os.listdir(ISSUES_COMPLETED_DIR) if f.endswith(".md")],
        key=os.path.getmtime, reverse=True
    )
    open_files = sorted(
        [os.path.join(ISSUES_OPEN_DIR, f) for f in os.listdir(ISSUES_OPEN_DIR) if f.endswith(".md")],
        key=os.path.getmtime
    )

    if not completed_files:
        log("Step 6: No completed issues to review", "WARN")
        return

    completed_bodies = []
    for f in completed_files:
        with open(f) as fh:
            completed_bodies.append((os.path.basename(f), fh.read()))
        log(f"  Completed: {f}")

    open_bodies = []
    for f in open_files:
        with open(f) as fh:
            open_bodies.append((os.path.basename(f), fh.read()))
        log(f"  Open:      {f}")

    prompt = (
        "## 任务说明\n\n"
        "请阅读以下所有问题文档的内容，然后写一封邮件给投资人。\n"
        "注意：所有更新已推送至开源仓库，无需再执行版本控制操作。\n\n"
        "---\n\n"
        "### 一、已完成的问题\n\n"
    )
    for name, body in completed_bodies:
        prompt += f"#### {name}\n\n```\n{body}\n```\n\n"
    if open_bodies:
        prompt += "---\n\n### 二、待处理的问题\n\n"
        for name, body in open_bodies:
            prompt += f"#### {name}\n\n```\n{body}\n```\n\n"
    prompt += (
        "---\n\n"
        "请直接输出邮件正文 不要保存文件 不要加任何额外说明\n"
        "邮件必须严格遵守以下要求：\n"
        "一 邮件开头必须严格如下 一字不可差 一行不可差：\n"
        "尊敬的投资人刘女士：\n"
        "我是杨子轩的小龙虾，... \n"
        "二 正文必须全部使用中文 不得出现任何英文单词 英文文件名 代码片段 或技术术语\n"
        "三 正文不得使用任何标记符号和LLM格式标记 任何用于加粗斜体标题列表代码块引用的格式字符一律禁止\n"
        "四 正文必须使用纯段落形式 \n"
        "五 语气正式 礼貌 简洁 面向非技术背景的投资人 不使用任何技术行话或项目文件名\n"
        "六 正文必须包含三个段落 顺序如下：\n"
        "第一段 说明本次完成了哪些修复和改进 突出重点 让投资人清楚了解进展\n"
        "第二段 指出当前仍然存在的不足和弱点 表述直接但不夸张\n"
        "第三段 说明下一步的改进计划 给出清晰方向\n"
        "七 邮件末尾必须严格如下 一字不可差 一行不可差：\n"
        "祝安，\n"
        "deepseek-v4-flash\n"
    )
    rc, output = run_opencode(prompt, timeout_seconds=300)
    if rc != 0:
        log(f"Step 6 FAILED (exit code {rc})", "ERROR")
        return

    subject = f"StudyKing 批次更新报告 - {datetime.datetime.now().strftime('%Y-%m-%d %H:%M')}"
    body = output or "（opencode 未返回内容）"
    log("Step 6: Sending review via email...")
    subprocess.run(
        ["mail", "-s", subject, RECIPIENT_EMAIL],
        input=body.encode(),
        timeout=30,
    )
    log("Step 6 completed — email sent")


def should_retry(rc):
    """Check if a return code indicates failure."""
    return rc != 0


def pick_oldest_unvalidated_scenario():
    dry_run_dir = os.path.join(PROJECT_DIR, "dry-run-test")
    if not os.path.isdir(dry_run_dir):
        return None
    files = sorted(
        [f for f in os.listdir(dry_run_dir) if f.endswith(".md")],
        key=lambda f: os.path.getmtime(os.path.join(dry_run_dir, f))
    )
    for f in files:
        path = os.path.join(dry_run_dir, f)
        with open(path) as fh:
            content = fh.read()
        if "# Validation Results" not in content:
            return f
    return None


def pick_oldest_failing_scenario():
    dry_run_dir = os.path.join(PROJECT_DIR, "dry-run-test")
    if not os.path.isdir(dry_run_dir):
        return None
    files = sorted(
        [f for f in os.listdir(dry_run_dir) if f.endswith(".md")],
        key=lambda f: os.path.getmtime(os.path.join(dry_run_dir, f))
    )
    for f in files:
        path = os.path.join(dry_run_dir, f)
        with open(path) as fh:
            content = fh.read()
        if "# Validation Results" in content and ("NOT_COMPLETED" in content or "PARTIAL" in content):
            return f
    return None


def run_master_once(master):
    open_file = master_issue_file(master["id"])
    is_scenario = bool(master.get("scenario_prompt"))
    is_recurring = master.get("recurring", False)
    if not is_scenario and not is_recurring and os.path.exists(open_file):
        return False

    if is_scenario:
        if master["id"] == "dry_run_result_validator":
            chosen = pick_oldest_failing_scenario()
            if chosen is None:
                chosen = pick_oldest_unvalidated_scenario()
                if chosen is None:
                    log("No dry-run scenarios need validation.")
                    return False
            topic = chosen.replace("scenario_", "").replace(".md", "")
            issue_file = f"dry_run_result_{topic}.md"
            issue_path = os.path.join(ISSUES_OPEN_DIR, issue_file)
            if os.path.exists(issue_path):
                log(f"Issue already exists for {chosen}: {issue_file}")
                return False
            log(f"Re-validating scenario: {chosen}")
        else:
            chosen = pick_oldest_unvalidated_scenario()
            if chosen is None:
                log("All dry-run scenarios already validated; nothing to do.")
                return False
            log(f"Validating scenario: {chosen}")
        fmt = {"chosen_file": chosen}
        if master["id"] == "dry_run_result_validator":
            topic = chosen.replace("scenario_", "").replace(".md", "")
            fmt["issue_file"] = f"dry_run_result_{topic}.md"
        prompt = master["scenario_prompt"].format(**fmt)
        timeout = master.get("timeout", SCENARIO_TIMEOUT_SECONDS)
    else:
        prompt = (
            f"You are `{master['title']}` for the StudyKing project. "
            f"Your ONLY allowed write actions are: create exactly one markdown issue file at `{open_file}`. "
            f"Do NOT edit any source code files. Do NOT modify other issue files. "
            f"If `{open_file}` already exists, read it first then add NEW findings or refine existing ones — don't overwrite. "
            f"Explore the codebase freely without being constrained to a predetermined set of files. "
            f"Focus: {master['focus']} "
            f"Write a single actionable issue with context, affected files, rationale, "
            f"and concrete acceptance criteria for what 'fixed' looks like. "
            f"Group findings by severity (BLOCKER = app crashes or user cannot proceed, "
            f"MAJOR = feature is broken or misleading, MINOR = code quality / UX friction)."
        )
        timeout = MASTER_TIMEOUT_SECONDS
    rc, _ = run_opencode(prompt, timeout_seconds=timeout)
    if rc == 0:
        if is_scenario:
            log(f"Master updated issue + scenario: {open_file}")
        else:
            log(f"Master created issue: {open_file}")
        return True
    log(f"Master `{master['title']}` did not create issue this round", "WARN")
    return False


def master_worker(master):
    log(f"Starting background worker: {master['title']}")
    while True:
        try:
            is_recurring = master.get("recurring", False)
            if not is_recurring and os.path.exists(master_issue_file(master["id"])):
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


def kill_orphan_opencode_children():
    current_pid = os.getpid()
    killed = 0
    try:
        for entry in os.listdir("/proc"):
            if not entry.isdigit():
                continue
            pid = int(entry)
            if pid in (current_pid, 1):
                continue
            try:
                with open(f"/proc/{entry}/cmdline", "rb") as f:
                    cmdline = f.read().replace(b'\0', b' ').decode(errors='replace').strip()
                if "opencode" not in cmdline or " run " not in cmdline:
                    continue
                with open(f"/proc/{entry}/status") as f:
                    status = f.read()
                ppid_line = [l for l in status.split("\n") if l.startswith("PPid:")]
                if not ppid_line:
                    continue
                ppid = ppid_line[0].split()[1]
                if ppid == "1":
                    os.kill(pid, signal.SIGTERM)
                    killed += 1
                    log(f"Killed orphaned opencode process {pid}")
            except (ProcessLookupError, PermissionError, OSError, IOError):
                continue
    except Exception as e:
        log(f"Error killing orphan children: {e}", "WARN")
    if killed:
        time.sleep(2)
    return killed


def signal_handler(signum, frame):
    global SHUTDOWN_REQUESTED
    log(f"Received signal {signum}, shutting down after current operation...")
    SHUTDOWN_REQUESTED = True


def cleanup():
    if not CHILD_PIDS:
        return
    log(f"Cleaning up {len(CHILD_PIDS)} child process(es)...")
    for pid in list(CHILD_PIDS):
        try:
            os.killpg(os.getpgid(pid), signal.SIGTERM)
        except (ProcessLookupError, PermissionError, OSError):
            try:
                os.kill(pid, signal.SIGTERM)
            except (ProcessLookupError, PermissionError, OSError):
                pass
    time.sleep(3)
    for pid in list(CHILD_PIDS):
        try:
            os.killpg(os.getpgid(pid), signal.SIGKILL)
        except (ProcessLookupError, PermissionError, OSError):
            try:
                os.kill(pid, signal.SIGKILL)
            except (ProcessLookupError, PermissionError, OSError):
                pass
    CHILD_PIDS.clear()
    log("Cleanup complete")


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
        if SHUTDOWN_REQUESTED:
            log("Shutdown requested, exiting main loop")
            break
        CYCLE_COUNT += 1
        log("=" * 60)
        log(f"CYCLE #{CYCLE_COUNT} starting at {datetime.datetime.now()}")
        log("=" * 60)

        for _ in range(5):
            if CONSECUTIVE_FAILS >= MAX_FAILS:
                log("Too many consecutive failures; backing off", "ERROR")
                break

            log("-" * 40)
            log("Resolving oldest open master issue")
            rc2, _ = step2_act_on_oldest_open_master_issue()
            if should_retry(rc2):
                CONSECUTIVE_FAILS += 1
                log("Step 2 FAILED", "ERROR")
                continue
            else:
                log("Step 2 SUCCESS")
                CONSECUTIVE_FAILS = 0

            log("-" * 40)
            try:
                ok3 = step3_fix_flutter_analyze()
                if not ok3:
                    CONSECUTIVE_FAILS += 1
                    log("Step 3 FAILED", "ERROR")
                    continue
                else:
                    log("Step 3 SUCCESS")
                    CONSECUTIVE_FAILS = 0
            except Exception as e:
                log(f"Step 3 exception: {e}", "ERROR")
                CONSECUTIVE_FAILS += 1
                continue

            log("-" * 40)
            random_test_dir = pick_random_subdir("lib")
            log(f"Step 4: Improving test coverage for {random_test_dir}")
            rc4, _ = step4_improve_test_coverage(random_test_dir)
            if should_retry(rc4):
                CONSECUTIVE_FAILS += 1
                log("Step 4 FAILED", "ERROR")
                continue
            else:
                log("Step 4 SUCCESS")
                CONSECUTIVE_FAILS = 0

        if CONSECUTIVE_FAILS >= MAX_FAILS:
            log(f"!!! {MAX_FAILS} consecutive failures reached !!!")
            CONSECUTIVE_FAILS = 0
            continue

        log("All 5 resolution rounds done. Committing.")
        log("-" * 40)
        log("Step 5: Committing to GitHub")
        rc5, _ = step5_commit_to_github()
        if should_retry(rc5):
            CONSECUTIVE_FAILS += 1
            log("Step 5 FAILED", "ERROR")
        else:
            CONSECUTIVE_FAILS = 0
            log("Step 5 SUCCESS")

        threading.Thread(target=step6_review_changes, daemon=True).start()

        log("-" * 40)
        log(f"Cycle #{CYCLE_COUNT} finished successfully")
        log("Starting next cycle immediately...")
        time.sleep(MAIN_LOOP_DELAY_SECONDS)


if __name__ == "__main__":
    lock_fd = open(LOCK_FILE, "w")
    try:
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except IOError:
        log("Another instance is already running (lock held). Exiting.", "FATAL")
        sys.exit(1)

    log("Singleton lock acquired")
    kill_orphan_opencode_children()
    signal.signal(signal.SIGTERM, signal_handler)

    try:
        main_loop()
    except KeyboardInterrupt:
        log("")
        log("Bot stopped by user (Ctrl+C)")
    except Exception as e:
        log(f"FATAL ERROR: {e}", "FATAL")
        import traceback
        traceback.print_exc()
    finally:
        cleanup()
        sys.exit(0)
