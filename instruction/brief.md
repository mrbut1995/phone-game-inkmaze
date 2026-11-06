# Agent Brief (instruction v1.7)

Read this first (~1.6k tokens). It is a digest. One rule: `python tools/instruction.py show R3`; find a word: `search <word>`; full documents only if both are not enough.

## Run protocol
0. **One session = one NEW chat.** Never continue a finished session in the same chat: the whole history is re-sent at every step (measured: S06 cost 12.8M input tokens because S01-S05 were still in the thread). The plan files carry the state.
1. `python tools/start.py` (project facts, plan state, last checks, tool list).
2. Asked to build a whole game/milestone and `plan/` is missing: `python tools/gameplay_to_plan.py`, refine, `python tools/plan.py check`, report, **STOP**.
3. `python tools/plan.py next` (prints goal, context pack, contracts, the previous session's Handoff, open tasks, commands); `python tools/plan.py start <S>`; read only the Context pack (`plan.py spec <n>` for gameplay sections).
4. Build scene-first; generators for boilerplate; rule logic as pure code in `models/` or `systems/` **with tests**.
5. `python tools/run_checks.py` -> exit 0 = done, 1 = failed (`python tools/logs.py <step>` for compact errors), 2 = **NOT VERIFIED**. One test/flaky check: `run_checks.py --only tests --filter <text> --repeat 5`.
6. `diff_summary.py --save docs/reports/<date>_<task>.md`, fill the TODOs, write the Handoff to a file, `plan.py done ...`, `plan.py finish <S> --handoff-file <file>` (runs the gate, ticks Definition of Done, writes Handoff), **STOP**. Step budget per session ~80 tool calls: past it, hand off and stop.

## Token rules
- Do not call Godot by hand (long paths + PowerShell pipes), do not hand-edit `plan/*.md` with regex scripts, do not read `tools/*.py` to learn usage: `run_checks.py`, `plan.py`, `logs.py` and `<tool> --help` cover it.
- Never open a file to learn what it contains: `script_index.py`, `scene_summary.py`, `find_refs.py`, `project_tree.py`.
- Read line ranges (<= 200 lines). Never `cat` logs (`logs.py`). Never re-read what is already in context.
- Generators instead of typing: `new_scene` (`--animated` effects, `--frames` sprite cycles), `new_svg`, `spritesheet` (placeholder / pack-dir / from-aseprite / frames / names / preview), `gen_animation`, `data_import`, `placeholder_audio`, `new_test`.
- Frame animation or spritesheet needed: `python tools/instruction.py show F1` first; never write `SpriteFrames` by hand.
- Unfamiliar project type (3D, card game, platformer, Control-only...): `python tools/instruction.py show 0 --doc types` (archetype intake); do not invent a structure.
- A recurring manual job over ~2k tokens with no tool: write "tool wanted: ..." in the report.

## Never
- Update the lint baseline, edit lint/test limits, or delete/skip a test to get green.
- Write Godot 3 syntax (lint `GODOT3`; see `instruction/godot4_cheatsheet.md`).
- Hand-write `SpriteFrames`, `AtlasTexture`, `Animation` tracks, `.import` files or `uid=` values.
- Leave unused template code (lint `DEAD`) or unexplained warnings (the gate is `--strict`).
- Use one `dir` parameter for two meanings (e.g. travel direction vs entry side): name them apart and test every direction + the blocked case.

<!-- rules:start -->
Digest of instruction/instruction_writing_project.md (instruction v1.7) - follow strictly. Godot 4.x, GDScript, static typing everywhere, TAB indentation, Godot 4 syntax only.
R1  Tunable values are @export (typed, @export_range, ## doc comment) or Resource fields. No magic numbers. `const` only for true constants (enums, StringName ids, layer numbers) in scripts/constants/<Domain>.gd.
R2  Build scene content in the .tscn. No Node.new()/Label.new()/StyleBoxFlat.new()/add_theme_*_override in scripts. PackedScene.instantiate() of an editor-authored scene is fine. Same-scene references: %UniqueName or @export Node refs; never get_node("../..") or $A/B/C.
R3  Signals between nodes of the same scene are [connection] entries in the .tscn (handlers named _on_<emitter>_<signal>). Code connect() only for EventBus / Resource models / runtime-instantiated nodes / SceneTree, marked `# code-connect: model|runtime|tree`; named methods, no lambdas. Use virtual hooks (_on_popup_ready, _on_close, _on_scene_ready) instead of self-connecting.
R4  Animations and effects: Animation resources in an AnimationPlayer plus an `AnimationController` node extending BaseAnimationController (semantic play_*() API, StringName constants, RESET animation); generate libraries from a JSON spec with tools/gen_animation.py. Frame animation (spritesheets) = F1: `spritesheet.py` makes SpriteFrames, names are `<state>_<direction>`, frames-only 2D scenes use BaseFrameAnimationController, Control-only scenes use FrameTextureRect. Tween only with `# EXCEPTION(R4-tween): reason` (runtime-computed endpoints).
R2b Shaders: tunables are `uniform`s with hints; ShaderMaterial + values live in the scene; code sets only runtime uniforms via `set_shader_parameter(PARAM, v)` with a StringName const.
R5  No art yet: SVG placeholder in assets/images-placeholder/<category>/<name>.svg (+ a row in MANIFEST.md). Never ColorRect/Polygon2D/_draw as placeholder art. Frame animation: never hand-write SpriteFrames; `spritesheet.py placeholder` draws moving SVG frames, then `frames <spec>` (F1). Audio placeholders: assets/audio-placeholder/.
R6  Every exception is tagged `# EXCEPTION(R<n>-<name>): reason`.
R7  Custom editor types live in scripts/editor/ (@tool + class_name); reuse them instead of rebuilding widgets.
Structure: scenes/ holds only .tscn: screens/ (whole screens), objects/<domain>/ (things inside a screen), components/<domain>/ (parts of an object), variants/<family>/ (same node tree as a base, different script/exports/assets), base/ (abstract bases: base_scene = Node2D world, base_ui_scene = Control-only).
scripts/ holds only .gd: scene scripts mirror scenes/ (scenes/objects/ui/hud.tscn -> scripts/objects/ui/HUD.gd); plus models/ commands/ ai/ systems/ constants/ utils/ editor/ autoload/.
Naming: script with class_name = PascalCase file named like the class; other scripts, scenes, folders, .tres = snake_case; signals past tense; private members start with _.
Architecture: MVC (Model = Resource/RefCounted, View = scene + script, Controller = node wiring both), SOLID, composition with Component nodes, EventBus for cross-system events.
Every scene script starts with a `## Scene contract` comment (Exports / Emits / Handlers wired in scene / Subscribes in code).
Tests: new logic gets tests under tests/ (extends TestCase, methods test_<behaviour>_<condition>). Directional/spatial rules need one test per direction plus the blocked case, asserting the resulting position/value (not just that a signal fired).
<!-- rules:end -->
