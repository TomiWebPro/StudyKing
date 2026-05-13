#!/usr/bin/env python3
"""
StudyKing Auto Improvement Bot
Runs opencode agents in a loop to continuously improve the project.
"""

import datetime
import os
import random
import re
import shutil
import signal
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
IDLE_TIMEOUT_SECONDS = 90
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

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LOG_FILE = os.path.join(SCRIPT_DIR, "auto_improve.log")


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
    )
    try:
        stdout, stderr = proc.communicate(input=input_data, timeout=timeout_seconds)
        output = ((stdout or b"").decode() + "\n" + (stderr or b"").decode()).strip()
        return proc.returncode, output
    except subprocess.TimeoutExpired:
        proc.kill()
        proc.wait()
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
    )

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
            return (-2 if ce else ret, output)

        elapsed = time.time() - start_time

        with lock:
            idle = time.time() - last_output_time[0]
            ce = flag_connection_error[0]

        if ce:
            _terminate()
            with lock:
                output = "".join(output_lines).strip()
            return -2, output

        if idle > idle_timeout:
            _terminate()
            with lock:
                output = "".join(output_lines).strip()
            return -2, output + "\nIDLE_TIMEOUT"

        if elapsed > timeout_seconds:
            _terminate()
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
        "我是杨子轩的小龙虾，\n\n"
        "二 正文必须全部使用中文 不得出现任何英文单词 英文文件名 代码片段 或技术术语\n"
        "三 正文不得使用任何标记符号和LLM格式标记 包括但不限于星号井号减号下划线反引号中括号小括号尖括号斜线句点逗号分号冒号感叹号问号at符号百分号and符号美元符号波浪号等号加号竖线花括号at符号等 任何用于加粗斜体标题列表代码块引用的格式字符一律禁止\n"
        "四 正文必须使用纯段落形式 不得分点列举 不得使用编号 不得使用横线分隔\n"
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
            log(f"Waiting {RETRY_DELAY_HOURS}h before retrying...")
            time.sleep(RETRY_DELAY_HOURS * 3600)
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
