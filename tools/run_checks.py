#!/usr/bin/env python3
"""One command = the whole quality gate. Prints a COMPACT summary (full logs go to tools/.logs/).

  python tools/run_checks.py                 # lint + scenes + plan + godot import/load/tests
  python tools/run_checks.py --fast          # python-only steps (no Godot needed)
  python tools/run_checks.py --only tests    # lint,scenes,plan,import,load,tests (comma list)
  python tools/run_checks.py --only tests --filter splash --repeat 3     # one test file/method, N times (never call godot by hand)
  python tools/run_checks.py --godot "C:/Godot/Godot_v4.4_console.exe"

Godot binary lookup: --godot, env GODOT_BIN, tools/godot_path.txt, then `godot`/`godot4` on PATH.
Exit codes: 0 = all passed | 1 = a step failed | 2 = INCOMPLETE (a step was skipped => task is NOT VERIFIED).
"""
from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys

from _common import ROOT, load_json, read_text, setup_stdout

LOGS = ROOT / "tools" / ".logs"
PY = sys.executable
ERROR_RE = re.compile(r"^(SCRIPT )?ERROR:|Parse Error|^ERROR:", re.M)
ENV_PATTERNS = load_json(ROOT / "tools" / "known_env_errors.json", {}).get("patterns", [])


def only_env_errors(output: str) -> bool:
    """True if there are ERROR lines and every one of them is a known environment problem."""
    lines = [l for l in output.splitlines() if ERROR_RE.search(l)]
    return bool(lines) and all(any(pat in l for pat in ENV_PATTERNS) for l in lines)


def engine_version(godot: str) -> str:
    rc, out = run([godot, "--version"], 30)
    m = re.match(r"^(\d+\.\d+(?:\.\d+)?)", out.strip())
    return m.group(1) if m else ""


def project_version() -> str:
    m = re.search(r'config/features=PackedStringArray\("(\d+\.\d+)"', read_text(ROOT / "project.godot"))
    return m.group(1) if m else ""


def find_godot(cli: str) -> str:
    candidates = [cli, os.environ.get("GODOT_BIN", "")]
    cfg = ROOT / "tools" / "godot_path.txt"
    if cfg.exists():
        candidates.append(cfg.read_text(encoding="utf-8").strip())
    for c in candidates:
        if c and (os.path.isfile(c) or shutil.which(c)):
            return c
    for name in ("godot", "godot4", "Godot"):
        found = shutil.which(name)
        if found:
            return found
    return ""


def run(cmd, timeout=600):
    try:
        p = subprocess.run(cmd, cwd=str(ROOT), capture_output=True, text=True, encoding="utf-8",
                           errors="replace", timeout=timeout)
        return p.returncode, (p.stdout or "") + (p.stderr or "")
    except subprocess.TimeoutExpired as exc:
        return 124, f"timeout after {timeout}s\n{exc.stdout or ''}"
    except OSError as exc:
        return 127, str(exc)


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--fast", action="store_true")
    ap.add_argument("--only", default="")
    ap.add_argument("--godot", default="")
    ap.add_argument("--timeout", type=int, default=300)
    ap.add_argument("--filter", default="", help="run only tests whose file::method contains this text (tests step)")
    ap.add_argument("--repeat", type=int, default=1, help="run the tests step N times (detects flaky tests)")
    a = ap.parse_args()

    all_steps = ["lint", "scenes", "exports", "plan", "import", "load", "tests"]
    steps = [s.strip() for s in a.only.split(",") if s.strip()] or all_steps
    LOGS.mkdir(parents=True, exist_ok=True)
    godot = find_godot(a.godot)
    results = []  # (name, status, detail)

    def record(name, status, detail, output=""):
        (LOGS / f"{name}.log").write_text(output, encoding="utf-8")
        results.append((name, status, detail, output))

    if godot and any(x in steps for x in ("import", "load", "tests")) and not a.fast:
        have, want = engine_version(godot), project_version()
        if have and want and not have.startswith(want):
            record("engine", "WARN", f"Godot {have} runs the checks but project.godot targets {want}: results may differ from the editor you use")
    for step in steps:
        if step == "lint":
            rc, out = run([PY, "tools/lint_rules.py", "--strict"])
            record("lint", "PASS" if rc == 0 else "FAIL", out.strip().splitlines()[-1] if out.strip() else "", out)
        elif step == "scenes":
            rc, out = run([PY, "tools/validate_scenes.py"])
            record("scenes", "PASS" if rc == 0 else "FAIL", out.strip().splitlines()[-1] if out.strip() else "", out)
        elif step == "exports":
            rc, out = run([PY, "tools/export_check.py"])
            record("exports", "PASS" if rc == 0 else "FAIL", out.strip().splitlines()[-1] if out.strip() else "", out)
        elif step == "plan":
            has_gameplay = any(p for p in (ROOT / "instruction").glob("*_gameplay.md") if not p.name.startswith("_"))
            if not (ROOT / "plan").is_dir() and has_gameplay:
                record("plan", "WARN", "gameplay file exists but plan/ is missing (building a game needs `python tools/gameplay_to_plan.py` first)")
            elif (ROOT / "plan").is_dir():
                rc, out = run([PY, "tools/plan.py", "check"])
                record("plan", "PASS" if rc == 0 else "FAIL", out.strip().splitlines()[-1] if out.strip() else "", out)
            else:
                record("plan", "PASS", "no plan/ folder (nothing to check)")
        elif step in ("import", "load", "tests"):
            if a.fast:
                record(step, "SKIP", "--fast")
                continue
            if not godot:
                record(step, "SKIP", "godot binary not found (set GODOT_BIN or tools/godot_path.txt)")
                continue
            if step == "import":
                rc, out = run([godot, "--headless", "--path", str(ROOT), "--import"], a.timeout)
                bad = ERROR_RE.findall(out)
                if bad and only_env_errors(out):
                    record("import", "WARN", f"rc={rc}; only known environment errors (tools/known_env_errors.json), not a project bug", out)
                else:
                    record("import", "PASS" if rc == 0 and not bad else "FAIL", f"rc={rc}", out)
            elif step == "load":
                rc, out = run([godot, "--headless", "--path", str(ROOT), "--quit"], a.timeout)
                bad = ERROR_RE.search(out)
                record("load", "PASS" if rc == 0 and not bad else "FAIL", f"rc={rc}", out)
            else:
                if not (ROOT / "tests" / "run_tests.gd").exists():
                    record("tests", "FAIL", "tests/run_tests.gd missing")
                    continue
                cmd = [godot, "--headless", "--path", str(ROOT), "-s", "res://tests/run_tests.gd"] + (["--", f"--filter={a.filter}"] if a.filter else [])
                runs = []
                for _ in range(max(1, a.repeat)):
                    rc, out = run(cmd, a.timeout)
                    engine_errors = [l for l in out.splitlines() if ERROR_RE.search(l)]
                    runs.append((rc == 0 and not engine_errors, out, engine_errors))
                    if not runs[-1][0] and a.repeat == 1:
                        break
                failed_runs = [i + 1 for i, r in enumerate(runs) if not r[0]]
                out = next((r[1] for r in runs if not r[0]), runs[-1][1])
                engine_errors = next((r[2] for r in runs if not r[0]), [])
                summary = next((l for l in out.splitlines() if l.startswith("Tests:")), "no summary line")
                if a.filter:
                    summary += f" (filter '{a.filter}')"
                if a.repeat > 1:
                    summary += f" | {len(runs)} runs: " + ("all passed" if not failed_runs else f"FLAKY, runs {failed_runs} failed")
                ok = not failed_runs
                record("tests", "PASS" if ok else "FAIL", summary + (f" | {len(engine_errors)} engine ERROR lines" if engine_errors else ""), out)

    width = max(len(r[0]) for r in results)
    for name, status, detail, _ in results:
        print(f"[{status}] {name.ljust(width)}  {detail}")
    failed = [r for r in results if r[1] == "FAIL"]
    skipped = [r for r in results if r[1] == "SKIP"]
    for name, _, _, out in failed:
        lines = [l for l in out.splitlines() if l.strip() and (l.startswith(("ERROR", "WARN", "[FAIL]", "       ", "SCRIPT")) or "ERROR" in l)][:15]
        print(f"--- {name}: first lines (full log: tools/.logs/{name}.log)")
        print("\n".join(lines) if lines else "\n".join(out.splitlines()[-10:]))
    if failed:
        print("RESULT: FAILED")
        return 1
    if skipped and not a.fast:
        print("RESULT: INCOMPLETE - skipped steps => report the task as NOT VERIFIED")
        return 2
    print("RESULT: PASSED" + (" (python steps only; Godot steps not run)" if skipped else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
