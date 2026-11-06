# Instruction: Tools for AI Agents

**Version 1.3.** Goal: spend tokens on thinking and writing, not on exploring, searching, boilerplate or log reading.
Companion of `instruction_writing_project.md` (rules), `instruction_planning.md` (sessions) and `ai_helper/instruction_ai_helper.md` (external AI).
All project tools are in `tools/`, are plain Python 3.8+ (stdlib only), work on Windows/Linux/macOS and print compact output. Every tool has `--help`.

---

## 1. Tool-first rules (MUST)

| # | Rule |
|---|---|
| T0 | **Reading budget.** Level 0: `instruction/brief.md` (~1.6k tokens) + `python tools/start.py`. Level 1: `python tools/instruction.py show R<n>` / `search <word>`. Level 2: the full document, only when level 1 is not enough. |
| T1 | **Orient with index tools before opening any file.** Never open a file just to learn what it contains: use `script_index`, `scene_summary`, `project_tree`. |
| T2 | **Read narrowly.** Outline first, then a line range (<= 200 lines). Never `cat` a large file. Never re-read a file that is already in your context. |
| T3 | **Search with tools** (`find_refs`, `rg`), never by browsing folders. |
| T4 | **Do not hand-write what a generator emits** (placeholder SVGs, plan/session files, ai_helper sessions). |
| T5 | **Never print long logs.** `run_checks.py` prints a compact summary; full logs are in `tools/.logs/<step>.log`: read them with `grep`/`tail` only when needed. |
| T6 | **Mutate through the tool when one exists:** move/rename -> `move_file.py`; plan state -> `plan.py`; external-AI sessions -> `ai_helper.py`. |
| T7 | **Cheapest check first.** While iterating run `run_checks.py --fast` or `--only <step>`; run the full gate once at the end. |
| T8 | **Missing tool?** If a manual job will cost more than ~2k tokens and recurs, say so in the report ("tool wanted: ...") instead of silently repeating it. Section 4 lists tools worth building. |
| T10 | **Frames, sounds, levels and tables come from generators:** sprite sheets -> `spritesheet.py`; animations -> `gen_animation.py`; audio placeholders -> `placeholder_audio.py`; CSV -> Definitions -> `data_import.py`. If the game needs a new generator (level builder, art generator), write it in `tools/` as a documented tool (section 5) and list it in section 2. |
| T11 | **Prompts:** use `instruction/prompts.md` (one stage per run, `#file:instruction/brief.md`, no folder attachments). |
| T9 | **Never game the gate.** Do not run `lint_rules.py --update-baseline`, edit `tools/lint_baseline.json`, `tools/lint_config.json`, skip tests or lower a limit to make a check pass. Only a human (or an explicit task) may change the baseline. |

---

## 2. Catalog: tools provided in `tools/`

| Tool | Command | Replaces (what costs tokens otherwise) |
|---|---|---|
| **start** | `python tools/start.py` | Exploratory `ls`/reads at the start of a run: project facts, plan next, last check results, tool list (~40 lines) |
| **instruction** | `python tools/instruction.py list / show R3 / show 7.3 / search word / brief` | Reading 10k-token instruction files to apply one rule |
| **logs** | `python tools/logs.py <step> [--context 2]` | Reading raw logs: distinct errors + the offending source lines |
| **run_checks** | `python tools/run_checks.py [--fast] [--only lint,scenes,exports,plan,import,load,tests] [--filter text] [--repeat N]` | Running 6+ commands and reading raw logs. One compact summary. Exit 0 pass / 1 fail / **2 incomplete = NOT VERIFIED** |
| **project_tree** | `python tools/project_tree.py [folder] [--depth N] [--ext gd,tscn] [--format list]` | `ls -R`/`find`; hides `.godot`, `*.uid`, `*.import`, `.git`, `ai_helper` |
| **script_index** | `python tools/script_index.py --classes` / `--class Actor` / `--find health` / `--file path` | Opening scripts to learn class, signals, exports, public functions |
| **scene_summary** | `python tools/scene_summary.py --all` / `<scene.tscn> [--flat]` | Reading raw `.tscn`: node tree, scripts, instances, connections, inheritance |
| **find_refs** | `python tools/find_refs.py <path\|ClassName\|text> [--count]` | grep + reading each hit; finds `res://` usages and class usages |
| **move_file** | `python tools/move_file.py old new [--apply]` | Manual move + fixing every `res://` reference; moves `.uid`/`.import` sidecars |
| **validate_scenes** | `python tools/validate_scenes.py [files]` | Opening Godot to find broken `.tscn`: missing resources, bad ids, unknown nodes, missing `_on_` handlers, wrong `$Path`/`%Name` |
| **lint_rules** | `python tools/lint_rules.py [--rule R2] [--all]` | Manual review of R1-R7, **Godot 3 syntax (`GODOT3`)**, dead template code (`DEAD`), file naming, folder rules, dependency direction, variant tree, tests-per-class, manifest. Baseline hides legacy debt, so you only see **new** findings |
| **new_scene** | `python tools/new_scene.py <screen\|object\|component\|variant\|base\|autoload> <domain>/<name> [--root Node2D] [--inherits base.tscn] [--animated \| --frames]` | Hand-creating scene + mirror script + contract header + AnimationController wiring in the right folder (`--frames`: AnimatedSprite2D + BaseFrameAnimationController; `--root Control --frames`: FrameTextureRect); validates the result |
| **gen_animation** | `python tools/gen_animation.py data/animations/specs/<name>.json` | Hand-writing `Animation` tracks (R4): JSON spec -> `AnimationLibrary` `.tres`; checks RESET and key times |
| **data_import** | `python tools/data_import.py scripts/models/definitions/ActorDefinition.gd data/import/actors.csv --out data/actors` | Writing `.tres` Definitions by hand; types/enums/resource paths converted from the script's `@export`s |
| **new_test** | `python tools/new_test.py <ClassName>` | Test boilerplate; every public function gets a *failing* stub so the gate stays red until implemented |
| **spritesheet** | `placeholder <cat/name> --rows idle_down:2,walk_down:6` (moving SVG frames) / `pack-dir <name> <folder>` (frames `<anim>_<NN>.png`) / `from-aseprite <json> --texture <png>` / `inspect <png> --frame WxH` (blank cells) -> `frames <spec>` -> `names <spec>` / `preview <spec>` | Hand-writing `AtlasTexture` regions and `SpriteFrames` text, static placeholder cells, slicing sheets by hand; validates grid, indexes, names, blank cells (instruction F1) |
| **placeholder_audio** | `python tools/placeholder_audio.py sfx/hit --kind beep` | Missing audio blocking exports/scenes; writes WAV + manifest |
| **signal_map** | `python tools/signal_map.py [--find x] [--orphans]` | Grepping emit/connect/`[connection]` to trace a signal |
| **export_check** | `python tools/export_check.py` | Runtime `assert(x != null)` failures: required exports no scene assigns |
| **diff_summary** | `python tools/diff_summary.py --save docs/reports/<date>_<task>.md` | Writing the report skeleton: files, new exports/signals/connections/tags/tests |
| **gameplay_to_plan** | `python tools/gameplay_to_plan.py` | Planning from scratch: S01 skeleton + one session per milestone, criteria mapped to tasks |
| **token_report** | `python tools/token_report.py --top 20` | Guessing which files are expensive to read/send |
| **new_svg** | `python tools/new_svg.py characters/goblin --role enemy --used-by "..."` | Hand-writing SVG placeholders and manifest rows (R5) |
| **plan** | `python tools/plan.py status / next / start / done / finish --handoff-file f / check / spec` | Re-reading the whole gameplay + plan to find "what next" |
| **ai_helper** | `python tools/ai_helper.py new/add/build/apply` | Collecting files, writing the prompt, pasting results back for an external AI website |
| **Godot test runner** | `godot --headless --path . -s res://tests/run_tests.gd` (via `run_checks`) | Manual testing |

Configuration: Godot binary = `--godot`, env `GODOT_BIN`, `tools/godot_path.txt` or `godot` on PATH. Lint tuning in `tools/lint_config.json`.

### Cheapest command per question

| Question | Command |
|---|---|
| What is in the project? | `project_tree.py --depth 2` |
| Where is class X defined? What does it expose? | `script_index.py --class X` |
| Which scripts deal with "health"? | `script_index.py --find health` |
| Who uses X / this file? | `find_refs.py X --count`, then `find_refs.py X --max 20` |
| What is in this scene? | `scene_summary.py <scene>` (`--flat` for inherited nodes) |
| Which scenes exist and what are their roots/scripts? | `scene_summary.py --all` |
| Is anything broken? | `run_checks.py --fast` |
| Does the game run and do tests pass? | `run_checks.py` |
| What is the next task? | `plan.py next` |
| What does the gameplay say about 5.1? | `plan.py spec 5.1` |
| Rename/move a file safely | `move_file.py old new` then `--apply` |
| I need a placeholder image | `new_svg.py ...` |

---

## 3. External tools to install (recommended)

| Tool | Why | Install / use |
|---|---|---|
| **Godot 4.4+ CLI** | import, load check, tests, export | set `GODOT_BIN`; use the *console* executable on Windows |
| **ripgrep (`rg`)** | fast code search when `find_refs` is not enough: `rg -n "pattern" scripts --max-count 5` | package manager |
| **fd** | fast file find | optional |
| **git** | `git diff --stat`, `git status -s`, small commits per task | system |
| **gdtoolkit** (`gdformat`, `gdlint`) | auto-format and style-lint GDScript: **never spend tokens on formatting** | `pip install gdtoolkit`; run `gdformat scripts tests` before the gate |
| **Python 3.8+** | runs all project tools | system |
| **GdUnit4 / GUT** (optional) | richer test framework if the project outgrows `tests/framework` (keep the `run_tests` exit-code contract) | addon in `addons/` |
| **pre-commit hook / CI** (optional) | run `run_checks.py` on every commit/PR (`godot-ci` image for the Godot steps) | `.git/hooks/pre-commit` or GitHub Actions |

---

## 4. Tools worth building next (priority order)

| Priority | Tool | What it does | Saves |
|---|---|---|---|
| Medium | `capture_scene` | Runs a scene in a real (non-headless) window and saves a PNG so an agent/human can inspect layout (the Echoes agent did this ad hoc) | Visual regressions found without opening the editor |
| Medium | `level_tool` | Generalised ASCII/JSON level builder + validator (the Echoes agent wrote `tools/build_level.py` by hand) | Level data boilerplate |
| Low-Med | `localization_extract` | Collect UI strings into a translation CSV | String hunting |
| Low | `balance_report` | Print stats tables from Definitions (dps, ttk, price/cost) | Balancing by eye |

---

## 5. Writing a new tool (contract)

- Python 3.8+ stdlib only, one file in `tools/`, `--help` with 2-3 examples at the top docstring.
- Reuse `tools/_common.py` (`iter_files` ignores `.godot`, `*.uid`, `*.import`, `ai_helper`; parsers for `.gd`/`.tscn`).
- Output compact: default <= 60 lines, summary line last, details behind flags.
- Exit codes: `0` ok, `1` failed, `2` incomplete/unverifiable.
- Read-only by default; anything that writes needs an explicit flag (`--apply`, `--write`) and a dry-run.
- Normalise paths (`/`, no `res://`), never assume the cwd: use `ROOT`.
- Add the tool to section 2 of this file and to `run_checks.py` if it is a gate.
