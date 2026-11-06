# Instruction: AI Helper (prepare work for an external AI website)

**Version 1.0.** The user works partly with external AI websites (Claude website, Google AI Studio...). When the user asks you to follow this file, you **prepare**: you collect the right files, build a self-contained prompt and package everything in `ai_helper/session_N/`. You do **not** implement the change yourself and you do **not** edit game code in this mode.

Typical trigger: *"I want to update the main screen using claude/ai studio, follow this instruction."*
Related: `instruction/instruction_tools.md` (tools), `instruction/instruction_writing_project.md` (the rules that the digest in the prompt summarises).

---

## 0. Principles (MUST)

1. **Minimal sufficient context:** only what the external AI needs to do the job correctly. Outline everything that is not edited.
2. **Self-contained prompt:** the website AI has no repo. The prompt carries project facts, the rules digest, the tree, the file table, the task and the exact output format. The tools insert all boilerplate; **you write only `task.md` and choose the files**.
3. **Tools, not reading:** find files with `scene_summary`, `script_index`, `find_refs`, `project_tree`. Do not open files to decide relevance.
4. **Never include:** `.godot/`, `*.uid`, `*.import`, `.git`, `ai_helper/`, `export/`, `tools/`, lint baseline/logs, unrelated screens, large binaries (unless the task is about them), secrets (`.env`, keys, tokens).
5. **Stop after packaging.** The human talks to the website, then comes back.

## 1. Procedure

### Step 1 - Understand the request
Restate it in 1-3 lines. Pick the target: `claude` (default), `aistudio` if the user says AI Studio/Google/Gemini, otherwise `generic`. Ask **at most one** question, and only if blocked; otherwise record assumptions in `task.md`.

### Step 2 - Create the session
```bash
python tools/ai_helper.py new "Update main menu" --target claude [--plan S05]
```
Creates `ai_helper/session_N/` (N = next number) with `task.md` (template) and `session.json`.

### Step 3 - Locate the relevant files (with tools)
```bash
python tools/scene_summary.py --all                       # which scenes exist (kind, root, script)
python tools/scene_summary.py scenes/screens/main_menu.tscn
python tools/script_index.py --find menu                  # scripts related to a word
python tools/find_refs.py MainMenuScene --count           # who uses it
python tools/project_tree.py scenes --depth 3
```

### Step 4 - Select files by tier
| Tier | What | Mode |
|---|---|---|
| A | **Files to change:** the scene(s) and script(s) the task edits | `full` |
| B | **Direct contracts:** inherited/base scene, instanced scenes, base classes, classes it calls | `outline` (`--deps` adds them automatically); `full` only if the AI must edit them |
| C | **Shared vocabulary:** `scripts/constants/*`, `Enums`, EventBus signals, relevant `data/*.tres` definitions | `outline` (small `.tres`: `full`) |
| D | **Existing tests** covering the area (so the AI updates them) | `full` |
| E | **Visuals:** placeholders/art used by the screen (`.svg` is text, `.png` is an asset) | `full` / `asset` |
| F | **Spec excerpt:** the relevant gameplay section(s) and plan session | paste into `task.md` (use `python tools/plan.py spec 8`) |

Budget: aim for <= 60k tokens of context and <= 25 files unless the target allows more (`ai_helper/config.json`). Anything over `full_file_max_tokens` is auto-outlined.

```bash
python tools/ai_helper.py add 1 scenes/screens/main_menu.tscn scripts/screens/MainMenuScene.gd --mode full --deps --why "screen to change"
python tools/ai_helper.py add 1 scripts/constants --mode outline --why "shared constants"
python tools/ai_helper.py add 1 tests/integration/test_scenes_smoke.gd --why "existing smoke test"
python tools/ai_helper.py add 1 assets/images-placeholder/ui/logo.svg --why "current logo"
```
(`--why` is shown to the website AI in the file table.)

### Step 5 - Write `ai_helper/session_N/task.md`
Replace **every** `<TODO>`; `build` refuses otherwise. Rules:
- **Goal:** one short paragraph; if the user wrote in another language keep their words on a line `Original request: "..."`.
- **Requirements:** concrete, checkable. **Constraints:** what must not change (node names, public API, signals). **Acceptance criteria:** how the user will verify, test names, criteria ids. **Out of scope.**
- Mention the engine versions when they differ (project saved by Godot 4.8 but checks run on 4.4): `run_checks.py` prints an `[WARN] engine` line.
- Paste only the needed spec excerpt (a few lines), never whole documents.
- English by default (the digest and output format are English).

**Bug-fix tasks (MUST):** fill the *Evidence* section of `task.md`: the root cause with file:line **and a table of every call site / branch** of the faulty code with the value each passes (error, blocked, first-run, special branches included). Never write "X is unchanged/correct" about a branch you have not read. Every acceptance criterion needs a named test asserting the **outcome** (position/value), including the negative or blocked case. A past session claimed the blocked-exit branch was correct, but that branch passed the opposite value (`-dir`) and had the same inversion.

### Step 6 - Build
```bash
python tools/ai_helper.py build N            # add --no-bundle to list files individually instead of one context.txt
```
Read only the printed summary (sizes, warnings). If over budget: switch large files to `--mode outline` (re-`add` with `--mode outline`) or drop low-value files, then `build` again. If it warns that the rules block of `instruction/brief.md` does not match the instruction version, update the brief first.

### Step 7 - Report to the user, then STOP
Keep it short:
1. Session folder.
2. **Paste** `ai_helper/session_N/prompt.txt` into the website.
3. **Attach** `ai_helper/session_N/context.txt` (and any listed binary assets).
4. Estimated tokens and the target limit.
5. "Save the website's answer to `ai_helper/session_N/response.md` and tell me: *apply session N*."

## 2. When the user returns with the answer

```bash
python tools/ai_helper.py apply N              # dry-run: NEW / MODIFIED / UNCHANGED, problems
python tools/ai_helper.py apply N --diff       # also shows the changed lines
python tools/ai_helper.py apply N --write      # write into the project
godot --headless --path . --import             # creates .uid files for new scripts
python tools/run_checks.py                     # lint + scenes + tests (full gate)
```
- `apply` refuses (writes nothing) on PROBLEMs: elided code ("...", "rest unchanged"), paths outside `scenes/ scripts/ data/ tests/ assets/images-placeholder/ plan/ docs/`, `..`/absolute paths, protected files (`project.godot` needs `--allow-protected`). Reviewed copies are in `session_N/out/`. Fix by asking the website for full files, not by `--force`.
- It converts space indentation to tabs in `.gd` files and normalises line endings.
- If the checks fail with small local issues (typo, missing handler), fix them yourself under the normal rules. If the fix is large, create a **follow-up session**: `ai_helper.py new "Fix: <topic>" --target ...`, add the changed files (`full`) and put the failing lines (<= 40, from `tools/.logs/*.log`) into `task.md`.
- Finish with the report format of `instruction_writing_project.md` section 9 (list the files applied).

## 3. Session folder

| File | Meaning |
|---|---|
| `session.json` | title, target, plan ref, file list (mode, why, tokens), status |
| `task.md` | the task you wrote (input to the prompt) |
| `request.md` | task copy for history |
| `files/` | copies of the selected files (and `*.outline.txt` for outlines) |
| `tree.txt` | filtered project tree (no `.godot`, `*.uid`, `*.import`) |
| `context.txt` | **attach this**: all text files bundled, each starting `===== FILE: path [mode] =====` |
| `prompt.txt` | **paste this** |
| `response.md` | the website AI's answer (saved by the user) |
| `out/` | the files extracted from `response.md`, post-normalisation |

`ai_helper/` contains `.gdignore` so Godot never imports the copies (they would clash on `class_name`). Do not remove it. `files/`, `context.txt` and `out/` are git-ignored.

## 4. Prompt quality checklist

- [ ] `task.md` has no `<TODO>`; requirements and acceptance criteria are checkable.
- [ ] Tier A files are `full`; everything else is `outline` unless it must be edited.
- [ ] No `.godot`, `.uid`, `.import`, secrets or unrelated files.
- [ ] Context tokens are within the target budget.
- [ ] You told the user exactly what to paste, what to attach and what to do next.

## 5. Configuration (all editable)

- `ai_helper/config.json`: per-target `max_files` / `max_tokens` (**assumptions: check the current limits of your website/plan**), `full_file_max_tokens`, `tree_max_lines`, `allowed_output_roots`, `protected_files`.
- `ai_helper/templates/`: `prompt_template.txt`, `output_format.md`, `task_template.md`. The rules digest sent to the website is the `<!-- rules:start -->` block of `instruction/brief.md` (single source; `build` warns when its version differs from `instruction_writing_project.md`).
