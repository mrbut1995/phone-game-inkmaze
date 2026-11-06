# Instruction: Writing a Godot Project

**Version 1.7.** Target: Godot 4.8 (GDScript; the rules only use features present since 4.4). Reusable across projects.
**This file = HOW to build.** The game-specific file `instruction/<game_name>_gameplay.md` = WHAT to build.
Keywords: **MUST / MUST NOT** = hard rule. **SHOULD** = default, deviate only with a written reason. **MAY** = optional.

---

## 0. Read order and precedence

0. **Token economy:** read `instruction/brief.md` first (~1.6k tokens), then only what the task needs: `python tools/instruction.py show R<n>` / `search <word>`. Read a whole document only when those are not enough. Start every run with `python tools/start.py`.
1. Read this file completely when you must (otherwise follow item 0), then the game's `*_gameplay.md`, then `README.md` and `docs/`.
2. Precedence: **this file (engineering rules) > gameplay file (content)**. The gameplay file decides *what* exists (entities, numbers, flow); it cannot relax an engineering rule unless it has an entry in its section "Approved deviations".
3. If a request is ambiguous: choose the most conservative reading, write the assumption in the final report **and** append it under "Assumptions made" in the gameplay file (section 16); never edit its rules. Ask only if you are blocked.
4. Do not add features, files or abstractions that the gameplay file does not require. No dead code, no unresolved TODO.
5. **Whole game / milestone requests:** if asked to build a game, a milestone or "everything in the gameplay file" and `plan/` does not exist, do NOT start coding: run `python tools/gameplay_to_plan.py`, refine, `python tools/plan.py check`, report and **STOP** for human review (`instruction_planning.md`). Different kinds of projects (2D world, Control-only, 3D, simulation...): `instruction/instruction_project_types.md` (foundation + capability matrix + pattern cards; named games there are samples only).
6. **Related instructions:** tools and token economy -> `instruction/instruction_tools.md` (read it, use the tools); executing or writing plans -> `instruction/instruction_planning.md`; preparing prompts for an external AI website -> `ai_helper/instruction_ai_helper.md` (when asked to follow it, that file governs the whole task).

## 1. Workflow (every task)

0. **Orient with tools** (`instruction_tools.md`): `script_index`, `scene_summary`, `project_tree`, `find_refs`. Do not open files to find out what they contain. If a plan exists, `python tools/plan.py next`.
1. **Plan:** list the scenes, scripts, resources, exports, signals, animations and **tests** the task touches. Check each against section 3.
2. **Build:** scene first (nodes, export values, connections, animations, placeholder art), then the script that only holds logic. Use the generators for boilerplate: `new_scene.py` (scene + mirror script + contract), `gen_animation.py` (animations), `new_svg.py` (placeholders), `data_import.py` (CSV -> Definitions), `new_test.py` (test skeleton).
3. **Test:** write/update tests (section 7), then run the **whole** suite.
4. **Verify:** `python tools/run_checks.py` (section 8).
5. **Report:** use the format in section 9.

**Definition of Done.** A task is done only when ALL are true: (a) rules R1-R7 satisfied, (b) tests for the new/changed behaviour exist, (c) `python tools/run_checks.py` exits **0** after the last code change (full gate: lint, scenes, plan, Godot import/load, tests), (d) the report is written. Exit code **2** (a step skipped, e.g. no Godot binary) means you MUST report **NOT VERIFIED**, never done. Do not change `tools/lint_baseline.json`, `tools/lint_config.json`, tests or limits to make the gate pass (`instruction_tools.md` T9).

Do not refactor unrelated code. Move/rename files with `python tools/move_file.py old new --apply` (it rewrites every `res://` reference); then re-run the gate.

---

## 2. Project structure and naming

```
res://
├── assets/{fonts,images,images-placeholder,audio,audio-placeholder,shaders}/
├── scenes/                 # ONLY .tscn
│   ├── screens/            # S  whole screens / game modes
│   ├── objects/<domain>/   # O  things that live inside a screen
│   ├── components/<domain>/# C  reusable parts of an object
│   ├── variants/<family>/  # V  same node tree as a base, different script/exports/assets
│   ├── base/               #    abstract bases, never instanced directly
│   └── autoload/           #    autoloads that need nodes
├── scripts/                # ONLY .gd   (scene-attached scripts mirror scenes/)
│   ├── screens/ objects/ components/ variants/ base/
│   ├── autoload/  models/ commands/ ai/ systems/ interfaces/   # logic with no scene
│   ├── constants/          # const-only files, one per domain
│   ├── utils/              # stateless static helpers
│   └── editor/             # custom node/resource TYPES (@tool + class_name)
├── data/       # .tres / .json (definitions, config)
├── tests/      # framework/ unit/ integration/  (+ run_tests.gd)
├── plan/       # session plans (instruction_planning.md)       contains .gdignore
├── ai_helper/  # prompts/context for external AI websites      contains .gdignore
├── tools/      # project tools (instruction_tools.md) + generator scripts
├── debug/      # profiler, mockup (excluded from export)
└── docs/  instruction/   # both contain .gdignore. docs/reports/ = final reports; instruction/ = instructions + gameplay only
```

### 2.1 Scene kinds (where does a `.tscn` go?)

Walk the list top to bottom; the first match wins.

| # | Question | Kind -> folder |
|---|---|---|
| 1 | Loaded by `SceneManager` as the whole screen or game mode? | **Screen** -> `scenes/screens/` (`boot`, `main_menu`, `game`) |
| 2 | Needs nodes **and** is an autoload? | `scenes/autoload/` |
| 3 | Abstract base that is never instanced directly? | `scenes/base/` (`base_scene`, `base_popup`) |
| 4 | Inherits a scene and its **node tree is identical** (only script / exports / sub-resources / textures differ)? | **Variant** -> `scenes/variants/<family>/` |
| 5 | A thing the player perceives or interacts with, instanced into a screen (actor, item, world, level, HUD, popup)? | **Object** -> `scenes/objects/<domain>/` |
| 6 | Only meaningful as a piece of an object (brain, health bar, hitbox, vfx, info view)? | **Component** -> `scenes/components/<domain>/` |

**Dependency direction (MUST):** screens may instance objects; objects may instance components; components MUST NOT instance objects or screens; objects MUST NOT instance screens. Communicate upwards with signals or `EventBus`, never by reference.

### 2.2 Script placement

- A script attached to a scene's root (or to a node specific to that scene, e.g. its View/Controller) lives in the **mirror folder**: `scenes/objects/world/actor.tscn` -> `scripts/objects/world/Actor.gd` (+ `ActorView.gd`, `ActorController.gd` next to it).
- Reusable component scripts used by many scenes -> `scripts/components/<domain>/`.
- Base classes (`BaseScene`, `Component`, `WorldEntity`) -> `scripts/base/`.
- Logic without a scene -> role folders: `models/` (Resource/RefCounted data), `commands/`, `ai/`, `systems/` (rules/services, e.g. `FactionRules`), `interfaces/`.
- Scene and script trees stay **separate** (never put `.gd` in `scenes/` or `.tscn` in `scripts/`).

### 2.3 Variants (replaces the old `prefabs/` folder)

Use a variant when `seagull.tscn` and `crow.tscn` inherit `bird.tscn` and differ only in script/parameters/assets.

- Layout: `scenes/variants/bird/seagull.tscn` <-> `scripts/variants/bird/Seagull.gd` with `class_name Seagull` / `extends Bird` (`Bird.gd` is the root script of `bird.tscn`).
- **Node tree MUST be identical** to the base: do not add, remove, rename or reparent nodes. If the tree must differ, it is not a variant: make a new object scene inheriting the base and put it in its kind folder (this is why `pause_popup` is an *object*, not a variant of `base_popup`).
- A variant MAY change: root script (subclass), exports, sub-resources (shapes, sprite frames, materials), textures, exported `PackedScene`s.
- The variant script overrides only documented hook methods and calls `super`. It does not copy the base's exports or code.
- Inheritance depth max 2 (base -> variant). No variant of a variant.
- **Prefer a Definition `.tres` over a variant** when only numbers/textures differ and no behaviour differs (see table).

| Difference between two things | Use |
|---|---|
| Only numbers, textures, names, sprite frames | Definition `.tres` (`ActorDefinition`, `ItemDefinition`), no new scene |
| Different behaviour (script) or scene-only sub-resources (collision shape size, particle setup), same node tree | **Variant** |
| Different node tree | New object scene inheriting the base |

### 2.4 `scripts/constants/` and `scripts/utils/`

- **constants/**: `class_name <Domain>` + `extends RefCounted`, only `const` and `enum`. **One domain per file** (`Groups`, `PhysicsLayers`, `Enums`, `InputActions`, `SceneIds`, `PopupIds`...). Never write a raw action/scene/popup/group name in logic: use the constant. No catch-all `Constants.gd`. Only *true constants* (R1): a tuning value never goes here.
- **utils/**: `class_name <Domain>Utils` (`MathUtils`, `ColorUtils`), **all `static func`**, no state, no Node/SceneTree/autoload access. Every public function MUST have a unit test. Anything with state, node access or domain meaning belongs in `systems/` or a component.

### 2.5 `scripts/editor/` (custom types)

Scripts here add new **types** to the editor via `@tool` + `class_name` (e.g. `StateTexture`, `Button2D`). They are shipped game code, **not editor-only**: never exclude this folder from export. Rules in R7.

### 2.6 Naming

| Thing | Convention | Example |
|---|---|---|
| Script with `class_name` (usable globally, shown in *Create New Node*) | PascalCase file, `class_name` = file name | `ActorView.gd` -> `class_name ActorView` |
| Autoload (no `class_name`; global name set in Project Settings) | PascalCase | `SaveManager.gd` |
| Script without `class_name` (one-off, attached by hand; test files) | snake_case | `intro_cutscene.gd`, `test_actor_model.gd` |
| Scene, folder, `.tres` | snake_case | `pause_popup.tscn` |
| Signal | past tense, typed args | `signal health_changed(old_value: int, new_value: int)` |
| Signal handler | `_on_<emitter>_<signal>` | `_on_resume_button_pressed` |
| Private member | leading underscore | `_timer` |

### 2.7 Architecture (MUST)

- **MVC.** Model = `Resource`/`RefCounted`, no Node access, emits signals. View = scene + script, displays only, emits input signals. Controller = node in the scene, connects Model and View.
- **SOLID in practice:** one responsibility per script; extend behaviour with new Components/Commands/Behaviors instead of editing existing ones; depend on signals/EventBus and injected data, not on `get_node("../..")`.
- **Autoload** only for truly global services; services talk through `EventBus`.
- **Composition over inheritance:** behaviour = Component node attached in the scene.

---

## 3. Core rules

### R1. Tunable values are `@export`, not literals

**Rule.** Every value a designer might want to change without touching code MUST be an `@export` (or a field in a Resource). **No magic numbers/strings** in logic.

| Kind | Examples | Where |
|---|---|---|
| **Tuning** (gameplay or presentation feel) | speed, damage, cooldown, radius, count of items to spawn, durations, colours, font sizes, volumes | `@export` |
| **Runtime state** | current health, countdown timers, cached refs | plain `var`, private (`_name`) |
| **True constant** (never tuned) | enum values, `StringName` ids (action/animation/group names), physics layer numbers, math constants | `const` (in `scripts/constants/`) |

**Decision test:** "Would a designer plausibly change this number to rebalance or re-feel the game?" Yes -> `@export`. Unsure -> `@export`.

**One source of truth per value:**

| Scope | Location |
|---|---|
| Differs per placed instance / per scene | `@export` on that scene's script, value set in the `.tscn` |
| Shared by all instances of a *type* | Resource definition in `data/` |
| Global config not owned by a scene | one config Resource in `data/config/` |

**Details (MUST):**
- Typed exports, grouped with `@export_group`, bounded with `@export_range(min, max, step, "suffix:s")` where a sane range exists. A `##` comment states unit and effect.
- Script default = sane fallback; override in the scene only when it differs.
- References to scenes/resources/textures/audio are exports (`@export var bullet_scene: PackedScene`), **not** `preload("res://...")`/`load()` paths. For lazy loading (scene transitions) use `@export_file("*.tscn") var path: String`.
- A required reference export MUST be validated at the top of `_ready()`: `assert(sprite != null, "<Scene>: 'sprite' export is not assigned")`.
- Exported `Resource` instances are shared between scene instances: do not mutate them at runtime; duplicate or use `resource_local_to_scene`.
- **Shaders** (`assets/shaders/*.gdshader`): every tunable (colours, speeds, radii, thresholds) is a `uniform` with a hint (`source_color`, `hint_range`); only true constants are `const`. The `ShaderMaterial` and its uniform values are authored in the scene/`.tres` (R2); code sets only runtime-dependent uniforms with `set_shader_parameter(PARAM_NAME, value)` where `PARAM_NAME` is a `StringName` const. Never `ShaderMaterial.new()`/`Shader.new()` in a script (lint R2).
- Exempt from "no `load()`": data-driven registries that scan `data/` (`DataManager`) and the id -> path registries of `SceneManager` / `PopupManager` (ids live in `scripts/constants/SceneIds.gd` / `PopupIds.gd`; scenes are loaded lazily by path).

```gdscript
# BAD
func _physics_process(delta): position += dir * 150.0 * delta
const WANDER_RADIUS = 150.0           # tuning disguised as a constant

# GOOD
@export_group("Movement")
## Pixels per second.
@export_range(0.0, 600.0, 1.0, "suffix:px/s") var move_speed: float = 150.0
@export var wander_radius: float = 150.0
```

### R2. Build scene content in the scene, not in script

**Rule.** Nodes, their static properties, shapes, materials, themes, sprite frames, timers, audio players, collision shapes and layout MUST be authored in the `.tscn`. A script MUST NOT build them at runtime.

**MUST NOT (unless an exception applies):**
- `Node.new()`, `Label.new()`, `Timer.new()`, `AudioStreamPlayer.new()`, `CollisionShape2D.new()`, `add_child(<node>.new())`
- setting static properties in `_ready()` (`label.text = "Settings"`, `button.size = ...`, `modulate = ...`)
- `add_theme_*_override(...)` (use a `Theme` resource / overrides in the scene)
- creating config `Resource`s in code (`SpriteFrames.new()`, `StyleBoxFlat.new()`); author `.tres`/sub-resources

**Allowed (no tag needed):**
- `PackedScene.instantiate()` of an editor-authored scene, then `add_child` (spawning, popups, list items, effects). *Instantiating a scene is not constructing nodes.*
- Setting **runtime-dependent** values on existing nodes (`bar.value = health`).
- Runtime state objects that are not scene content: Models, Commands, Snapshots, `RefCounted` data.
- Everything inside `scripts/editor/` (see R7).

**Exceptions (tag `# EXCEPTION(R2): <reason>`):** structure only known at runtime and not expressible as a scene (procedural tile grid, generated mesh); tooling under `tools/` and `@tool` plugins; debug overlays under `debug/`.

**Autoloads that need nodes MUST be scenes:** `scenes/autoload/audio_manager.tscn` (with its `AudioStreamPlayer` children and exports set) + script `scripts/autoload/AudioManager.gd`, registered in Project Settings under the same global name. Pure-logic autoloads may stay `.gd`.

**Node references (MUST):**
- Same-scene child: `@onready var x: Type = %UniqueName` (node has `unique_name_in_owner = true`) **or** `@export var x: Type`. No deep paths (`$A/B/C`).
- Outside your own scene: exported reference, signal, `EventBus`, or group. Never `get_node("..")`, `$"../.."`, `get_parent().x`, `owner.x` to reach other scenes.
- Do not reach into the internals of an instanced child scene; use public methods/signals on its root.
- Allowed documented helper: a `Component` base class may resolve its owning entity.

**Static vs dynamic wiring:** static references inside one scene = exports/`%Name`. Runtime data = injected through `setup(...)`.

```gdscript
# BAD: builds UI in code
func _ready():
    var btn := Button.new(); btn.text = "Play"; add_child(btn)
    btn.pressed.connect(_on_play)

# GOOD: Button, its text and the connection are in the .tscn; the script has only the handler
func _on_play_button_pressed() -> void: SceneManager.change_scene(&"game")
```

### R3. Signals are connected in the scene

**Rule.** If emitter and receiver both exist in the same scene (including the root of an instanced child scene), the connection MUST be a `[connection]` in the `.tscn`, not `connect()` in a script.

| Emitter -> receiver | Location |
|---|---|
| Node -> node in the same scene (Button, Area2D, Timer, AnimationPlayer, View -> Controller) | **`.tscn` `[connection]`** |
| Instanced child scene's **root** signal -> parent scene script | **`.tscn`** of the parent (a child exposes public signals at its root; re-emit internal ones) |
| Autoload / `EventBus` (subscribe or emit) | code |
| `Resource` / `RefCounted` signals (Models) | code (the editor cannot connect these) |
| Node instantiated at runtime | code, by the instantiating owner, right after `instantiate()` |
| `SceneTree` / `Viewport` / `Window` signals | code |
| Inside `scripts/editor/` custom types | code (R7) |

Anything not in this table is an exception: `# EXCEPTION(R3): <reason>`.

**Code connections (when allowed) MUST:**
- carry the marker `# code-connect: model|runtime|tree` on the same or previous line (`EventBus.` connections need none). The lint checks it; the marker states *why* it is not in the `.tscn`;
- live in one place (`_ready()` or `setup()`), use **named methods** `_on_<emitter>_<signal>`; no lambdas (they cannot be disconnected and leak captured nodes). *Test files may use lambdas.*
- guard with `is_connected` and **disconnect in `_exit_tree()`** when the emitter outlives the receiver (autoload, EventBus, Models);
- use `CONNECT_ONE_SHOT` for one-time reactions.

**Canonical MVC wiring:** View -> Controller in the `.tscn`; Model -> Controller in code inside `setup(model, ...)`.

**Do not connect a node's own signal to itself in code.** Use a virtual hook instead (`BasePopup` calls `_on_popup_ready()` / `_on_close()`; `BaseScene` calls `_on_scene_ready()`); a subclass overrides the hook.

**Scene contract (MUST).** Top of every scene script:

```gdscript
## Scene contract
## Exports:  move_speed, attack_cooldown
## Emits:    clicked, closed
## Handlers wired in scene: _on_close_button_pressed, _on_timer_timeout
## Subscribes in code (EventBus/Model): actor_died
```

### R4. Animation and effects: AnimationPlayer + an AnimationController

**Rule.** Animations and visual effects are authored as `Animation` resources in an `AnimationPlayer` (or `AnimationTree` for blending/state machines) inside the scene. A script MUST NOT build animations or tweens by default.

**`AnimationController` (MUST for every animated scene):**
- A `Node` child of the View scene named `AnimationController` (unique name); script `<Name>AnimationController.gd` (`class_name`) that **extends `BaseAnimationController`** (player tracks) or, for scenes animated only by frames, `BaseFrameAnimationController` (F1; no AnimationPlayer needed). A Control scene whose only animation is a `FrameTextureRect` needs no AnimationController: its View calls the widget (F1); (`scripts/base/`). The base class finds the sibling `%AnimationPlayer`, applies `speed_scale`, asserts the animations returned by `_required_animations()`, exposes `animation_finished`, and its handler is wired in the `.tscn`. The subclass adds the semantic methods and references `AnimatedSprite2D`/`AnimationTree` through `%UniqueName`.
- Exposes **semantic methods** (`play_hit()`, `play_death()`, `set_moving(is_moving: bool)`) and a signal `animation_finished(animation_name: StringName)`.
- **No game logic**, no Model access. Called by the Controller or View. The **only** script that touches the AnimationPlayer/AnimatedSprite2D.
- Animation names are `const` `StringName`s inside it and must exist in the player (assert in `_ready()`).
- Durations/easing live in the `Animation` resources; playback speed = exported `speed_scale`. Every `AnimationPlayer` has a `RESET` animation.
- **Frame animation (sprite sheets):** never hand-write `SpriteFrames`/`AtlasTexture`; use the toolchain and the runtime blocks in **F1** (placeholder with moving frames, pack a folder, import Aseprite, `<state>_<direction>` names, mirroring, Control-only).
- **Generate the animations, do not hand-write tracks:** write a JSON spec in `data/animations/specs/<name>.json` and run `python tools/gen_animation.py <spec>` -> `data/animations/<name>.tres` (an `AnimationLibrary` referenced from the `AnimationPlayer`). Set `root_node` on the player so track paths are relative to the animated node.
- (View-side helper; not the MVC "Controller".)

| Need | Use |
|---|---|
| Frame-by-frame sprite cycle | `AnimatedSprite2D` + `SpriteFrames` (driven by the AnimationController) |
| modulate/scale/position/visibility, fixed shake, sounds, particle `emitting`, method calls | `AnimationPlayer` |
| Blending / state machine | `AnimationTree` |
| One-shot effect (hit spark) | own scene: autoplay animation + a **method-call track calling `queue_free`** on the last frame |
| Particles | `GPUParticles2D`/`CPUParticles2D` configured in the scene; triggered by animation track or `restart()` |

**Tween is an exception.** Allowed only if **both**: (1) it cannot be a fixed `Animation` resource, **and** (2) at least one of: start/end values computed at runtime (fly to a moving target, count a number up to a runtime value), per-instance procedural motion (decaying shake, spring), unbounded number of unique instances.
- Tag: `# EXCEPTION(R4-tween): <which criterion>`.
- Duration/ease/transition are `@export`s; keep the Tween in a var, `kill()` the previous one, `bind_node(self)`.
- Never tween a property an `AnimationPlayer` in the same scene also animates.

**Timing:** do not sequence animation with `await get_tree().create_timer(x)`; wait for `animation_finished`. Repeating/cancellable timers are `Timer` nodes in the scene; a one-shot logic delay may use `create_timer(<exported duration>)`.

### F1. Frame animation toolchain (sprite cycles)

**Rule.** A frame animation is a `SpriteFrames` `.tres` generated from a spec by `tools/spritesheet.py`, played by a block (never by ad-hoc `sprite.play("walk")` calls scattered in scripts). No art yet -> the placeholder tool draws **moving** SVG frames, so every state is visible in the game from day one.

| You have | Run | Result |
|---|---|---|
| No art | `spritesheet.py placeholder <cat/name> --frame 16x16 --cols 6 --role player --rows idle_down:2,walk_down:6,attack_down:4,death_down:4` | SVG sheet (frames bob / lunge / flash / fade by state) + spec + manifest row |
| A folder of frames `<anim>_<NN>.png\|svg` | `spritesheet.py pack-dir <cat/name> <folder> [--fps walk=10] [--once attack,hit]` | one sheet + spec (same-size frames; PNG needs Pillow) |
| An Aseprite export (JSON array/hash, **Trim off**, tags = animations) | `spritesheet.py from-aseprite <json> --texture <png> --name <cat/name>` | spec with `regions` and per-frame durations |
| A ready sheet | `spritesheet.py inspect <png> --frame WxH` (or `--grid CxR`) -> write the spec by hand | grid check + **blank cells** list |

Then always: `spritesheet.py frames <spec>` -> `data/animations/<name>_frames.tres` (refuses blank cells, bad indexes, bad names) -> `names <spec>` (StringName consts) -> optionally `preview <spec>` (PNG contact sheet). Assign the `.tres` to `Sprite.sprite_frames` in the `.tscn` or to a Definition export. **Replacing placeholder with real art:** change `texture` in the spec, run `frames` again; nothing else changes.

**Naming (MUST).** `<state>` or `<state>_<direction>`, direction in `down|up|left|right|side`, `[a-z0-9_]+`. Art convention: `right` and `side` face **right**, `left` faces **left**. Ship only one horizontal side: the runtime mirrors with `flip_h`. One-shot states (`attack`, `hit`, `death`, ...) have `loop: false`.

**Runtime blocks (choose by scene kind):**

| Scene | Use | API |
|---|---|---|
| 2D, frames only | `AnimatedSprite2D %Sprite` + `AnimationController` extending `BaseFrameAnimationController` (`new_scene.py ... --frames`) | `play_state(&"walk", AnimDirections.LEFT)`, `face(velocity)`, `animation_finished` (wired in the `.tscn`) |
| 2D, frames **and** effects (hit flash, shake) | `AnimationController` extending `BaseAnimationController` (player tracks) that also drives `%Sprite` with `FrameAnimUtils.resolve(...)` | keep the one-controller rule: only this node touches the sprite and the player |
| **Control-only** (board tiles, cards, list rows, icons) | `FrameTextureRect` (`scripts/editor/`), `new_scene.py ... --root Control --frames` | `play_state()`, `play()`, `stop()`, `animation_finished`; layout via `expand_mode`/`stretch_mode` |
| Frame index as a property (`Sprite2D.hframes`) | `gen_animation.py` `frames` track | R4 |

Never put an `AnimatedSprite2D` under a `Container` (it is not a `Control`, so layout ignores it): use `FrameTextureRect`. Never hand-write positions of container children in an Animation (the container resets them): animate `modulate`, `scale`/`pivot_offset`, `custom_minimum_size` of a wrapper, or use a tagged Tween (P6).

### R5. Visual placeholders are SVG files, never drawn in the scene

**Rule.** Every visible game object, icon, character, background needs a texture from day one. If the real asset is missing in `assets/images/`, create an **SVG placeholder** in `assets/images-placeholder/` and reference it exactly where the real texture will be referenced.

**MUST NOT use as placeholder art:** `ColorRect`, `Polygon2D`, `Line2D`, `_draw()`, `PlaceholderTexture2D`, `GradientTexture`, `ImageTexture` built in code.
**Still allowed (UI structure, not art):** `Panel`/`PanelContainer` with `StyleBoxFlat`, dim overlays, separators, `ProgressBar` styling, debug overlays in `debug/`, and the drawing code of `scripts/editor/` custom types.

**SVG spec (MUST):**
- Path `assets/images-placeholder/<category>/<snake_case_name>.svg` (category mirrors `assets/images/`). Frames: `<name>_00.svg`, `<name>_01.svg`.
- `width`, `height`, `viewBox` = intended final pixel size from the gameplay file (default 64x64 characters, 32x32 items, 128x128 icons).
- Flat simple shapes, no raster images, no external fonts, < 2 KB (spritesheets from `spritesheet.py placeholder` are exempt: < 2 KB per frame), pivot at the centre unless stated otherwise, small text label with the asset name.
- Colour by role (unless the gameplay file defines a palette): player `#4C99FF`, enemy `#E64D4D`, neutral `#B3B3B3`, collectible `#FFD933`, obstacle `#8C6640`.
- Do not hand-write `.import` files; run the import step so Godot generates them.

**Manifest (MUST):** keep `assets/images-placeholder/MANIFEST.md` current:

| File | Used by (scene/resource + property) | Size | Pivot | Frames | Status | Final path |
|---|---|---|---|---|---|---|

**Spritesheet placeholders** use `spritesheet.py placeholder` (one SVG sheet + a starter frames spec). **Audio placeholders**: `python tools/placeholder_audio.py <category>/<name> --kind beep|noise|sweep|loop|silence` -> `assets/audio-placeholder/` (+ its `MANIFEST.md`); the export preset also excludes `assets/audio-placeholder/*`.

**Replacing with real art:** add the file to `assets/images/...`, change the single reference, set Status = replaced, delete the placeholder. The export preset MUST exclude `assets/images-placeholder/*`, `tests/*`, `debug/*`.

### R6. Every exception is tagged

Format: `# EXCEPTION(R<n>-<short-name>): <reason>` on the line above the code. Untagged violations are bugs. Tags make exceptions greppable.

### R7. Custom types in `scripts/editor/`

Scripts that add a reusable node/resource **type** (`@tool` + `class_name`, e.g. `StateTexture`, `Button2D`).

- **Scope:** presentation and input of a widget only. No game logic, no Model access, no autoload/`EventBus` calls (autoloads are not available in the editor).
- **Carve-out (declare once in the file header: `# EXCEPTION(R2,R3,R5): custom type implementation`):** inside these files you MAY draw in code (`_draw`, `StyleBoxFlat.new()`), connect signals in code (own signals, parent's signals), and create resources. This is the *only* place those are allowed without a per-line tag.
- **Still binding:** R1 (font size, margins, colours are exports, not literals), static typing, tests (R8), naming (file = `class_name`, PascalCase).
- Every exported property that affects drawing/size calls `queue_redraw()` / `update_minimum_size()` in its setter.
- Runtime-only logic is guarded with `Engine.is_editor_hint()`.
- Disconnect parent/child signals in `_exit_tree()` / on `NOTIFICATION_UNPARENTED`.
- **Use them:** scenes MUST use these types instead of rebuilding the same widget in script or with ad-hoc nodes.

---

## 4. Hand-authoring `.tscn` and `.tres`

You usually cannot open the editor. Write the text formats carefully and **validate by loading** (section 8).

- Order: `[gd_scene]`, `[ext_resource]`, `[sub_resource]`, `[node]`, then `[connection]` entries last.
- Reference by `path`; do not invent `uid`s.
- Unique `id` per `ext_resource`/`sub_resource`. Node `parent` is relative to the root (`"."` for direct children, `"Panel/Content"` deeper).
- Inherited scene: `[node name="X" instance=ExtResource("base")]`; added nodes use `parent=` and `index=`.
- **Variant** (same tree, new script + exports):
  ```
  [ext_resource type="PackedScene" path="res://scenes/objects/world/bird.tscn" id="1_bird"]
  [ext_resource type="Script" path="res://scripts/variants/bird/Seagull.gd" id="2_script"]
  [node name="Seagull" instance=ExtResource("1_bird")]
  script = ExtResource("2_script")
  fly_speed = 220.0
  ```
- `unique_name_in_owner = true` for `%Name` nodes.
- Signal connection: `[connection signal="pressed" from="Panel/Content/ResumeButton" to="." method="_on_resume_button_pressed"]` (child-scene root signal: `from="Child"`; extra args: `binds=[...]`).
- Exports are plain properties on the node that has the script.
- **Animations and SpriteFrames are never hand-written** (they appear in `.tscn` only as `ExtResource` of a generated `.tres`): tracks -> `gen_animation.py` (R4), frames -> `spritesheet.py` (F1). Reference them as `[ext_resource type="AnimationLibrary" ...]` / `type="SpriteFrames"`.
- Never edit `.godot/`. When moving files, update every reference in `.tscn`/`.tres`/`project.godot`/scripts/tests.

---

## 5. GDScript style (MUST)

- **Static typing everywhere:** variables, parameters, return types (`var p: Node = get_parent()`, not `var p = get_parent()`).
- Member order: `class_name`/`extends`, `##` doc, signals, enums, consts, exports, public vars, private vars, `@onready`, lifecycle, public methods, private methods, signal handlers.
- **Godot 4 syntax only** (`instruction/godot4_cheatsheet.md`); the lint rule `GODOT3` fails the gate on `yield`, `onready var`, string `connect`, `.instance()`, `KinematicBody2D`, `move_and_slide(arg)`, `format=2`...
- Input: only action names defined in `project.godot` (put them in `scripts/constants/InputActions.gd`).
- No `print()` leftovers; use `DebugManager.log_msg()`.
- Physics/raycast queries only inside `_physics_process`.
- Recommended `project.godot` warnings: `untyped_declaration`, `unsafe_method_access`, `unused_variable`, `unused_parameter` as warnings or errors.

---

## 6. Quick reference: where does it go?

| I need to... | Do this |
|---|---|
| Create a new scene | `python tools/new_scene.py <kind> <domain>/<name> [--animated]` |
| Create effect animations (flash, shake, fade) | spec JSON + `python tools/gen_animation.py <spec>` |
| Create frame animations (walk cycle, spritesheet) | F1: `spritesheet.py placeholder / pack-dir / from-aseprite` -> `frames <spec>`; scene via `new_scene.py ... --frames` |
| Animate a sprite inside a Control layout | `FrameTextureRect` (F1) |
| Create many Definitions | CSV + `python tools/data_import.py <DefinitionScript> <csv> --out data/...` |
| React to a popup/scene lifecycle event | Override the hook (`_on_popup_ready`, `_on_close`, `_on_scene_ready`) |
| Add a sprite/label/shape/timer/audio player/collider | Node in the `.tscn` |
| Change a number | `@export` / Resource field |
| Decide a scene's folder | Section 2.1 table |
| Make a "seagull" from "bird" | Variant if same tree + different script; Definition `.tres` if only numbers/textures |
| Share a constant between scripts | `scripts/constants/<Domain>.gd` (true constants only) |
| Share a pure helper function | `scripts/utils/<Domain>Utils.gd`, `static func`, unit-tested |
| Add a new widget type to the editor | `scripts/editor/<Type>.gd` (`@tool` + `class_name`), R7 |
| React to Button/Area2D/Timer/AnimationPlayer in the same scene | `[connection]` in the `.tscn` |
| Subscribe to `EventBus` or a Model | Code in `_ready()`/`setup()`, named handler, disconnect in `_exit_tree()` |
| Spawn something | Exported `PackedScene` -> `instantiate()` |
| Play hit flash / death / idle | `AnimationController.play_*()` |
| Fly an effect to a moving target | Tween (tagged exception) |
| Show a thing with no art yet | SVG in `assets/images-placeholder/` + manifest line |
| Autoload needs nodes | Make it a `.tscn` in `scenes/autoload/` |
| Find out what a class/scene contains, who uses it | `script_index`, `scene_summary`, `find_refs` (never open blindly) |
| Move or rename a file | `python tools/move_file.py old new --apply` |
| Finish a task | Tests written + `python tools/run_checks.py` exit 0 |

---

## 7. Testing (MUST)

**Every build ends with a full test run.** No task is done, and no "done" may be reported, until the whole suite has been run after the last code change and is green (Definition of Done, section 1).

### 7.1 Framework and commands

Default framework: the in-repo, zero-dependency runner `tests/run_tests.gd` with base class `tests/framework/TestCase.gd`. A project MAY migrate to GdUnit4 or GUT, but the **contract stays**: one command runs everything and exits non-zero on any failure.

```bash
godot --headless --path . --import                                 # first time / after adding class_name files
godot --headless --path . -s res://tests/run_tests.gd 2>&1 | tee test.log
grep -nE "^(SCRIPT )?ERROR|Parse Error" test.log                   # MUST print nothing
godot --headless --path . -s res://tests/run_tests.gd -- --filter=command_handler   # while iterating
```
Exit code != 0 = failed. Engine `ERROR:` lines in the log are failures too (the runner cannot intercept them). Zero tests found = failure.

### 7.2 Layout and naming

```
tests/
├── run_tests.gd            # runner
├── framework/TestCase.gd   # base class (asserts, autofree, add_to_tree, await_frames)
├── unit/<mirrors scripts/ subfolder>/test_<snake_case_class>.gd
└── integration/test_*.gd   # scenes, flows
```
- Test file: `test_<snake_case_class>.gd`, `extends TestCase`, no `class_name`.
- Test method: `test_<behaviour>_<condition>()`; may use `await`.
- One behaviour per test; arrange / act / assert.

### 7.3 What MUST be tested

| Code | Test |
|---|---|
| Models, Commands, AI Behaviors, Snapshots, rules (`systems/`), `utils/` functions | **Unit tests** for every public behaviour, including edge cases (zero, negative, dead, empty) |
| Every scene under `scenes/` | **Smoke test** (instantiate, enter tree, 2 frames, no errors). `tests/integration/test_scenes_smoke.gd` covers all scenes automatically; keep its skip list minimal |
| Scene contracts | Required exports assigned; animation names used by the AnimationController exist in the player; `[connection]`s resolve |
| Custom types in `scripts/editor/` | Instantiate, set each exported property, check size/state; simulate state changes (e.g. `StateTexture.State`) |
| A bug fix | **Regression test first**: reproduce (fails), fix, passes |
| Directional / spatial / ordered rules (room entry side, movement, merge order) | **One test per direction/case, plus the blocked/edge case**, asserting the resulting *position/value* |
| Each acceptance criterion in the gameplay file | At least one test; name or comment contains the criterion id (e.g. `M1-2`) |

### 7.4 Test quality rules

- **Deterministic:** seed RNG (`seed(1)` or a `RandomNumberGenerator` with fixed `seed`), pass `delta` explicitly (call `_physics_process(0.1)`), never depend on wall-clock time. No sleeps; `await_frames(n)` only.
- **Isolated:** fresh instance per test; reset autoload state in `before_each` (e.g. `SaveManager.profile = PlayerProfile.new()`); free what you create (`autofree`, `add_to_tree`); no file I/O except `user://tests/`, cleaned up.
- **Fast:** each test < 2 s, whole suite < 60 s.
- A test that only proves a mechanism fired (the camera panned, a signal was emitted) does **not** verify an outcome criterion: assert the outcome (where the hero stands, which value results).
- Test behaviour through public API/signals. Do not assert on private fields unless there is no other seam. Do not test Godot itself.
- **Never** delete, skip, comment out or weaken a failing test to make the suite pass. Either the code is wrong (fix it) or the expectation is wrong (change it **and** explain why in the report).
- New logic without tests is an incomplete task.

### 7.5 Test-driven order of work

Plan tests with the plan (section 1, step 1) -> write the failing test -> implement -> run the full suite -> fix -> run again until green.

---

## 8. Verification (before reporting)

**One command:** `python tools/run_checks.py` (compact summary; logs in `tools/.logs/`). Steps: `lint`, `scenes`, `exports`, `plan`, `import`, `load`, `tests`. `[WARN]` never fails the run but must be read: missing plan, engine version differs from `project.godot`, or an import error listed in `tools/known_env_errors.json` (environment, not a project bug; say so in the report). `--fast` = Python steps only (use while iterating). Exit 0 = pass, 1 = failed, 2 = incomplete = **NOT VERIFIED**. `lint_rules.py` shows only **new** findings (legacy ones are in `tools/lint_baseline.json`); the gate runs it with `--strict`, so a new WARN fails too. Fix it, or add the justified marker (`# EXCEPTION(R<n>-name): reason`, `# code-connect: model|runtime|tree`). Never leave warnings unexplained. Raw equivalents:

```bash
godot --headless --path . --import                       # class cache + assets (SVG)
godot --headless --path . --quit                         # loads project + autoloads: parse/load errors
godot --headless --path . --check-only --script res://<changed_script>.gd
godot --headless --path . -s res://tests/run_tests.gd 2>&1 | tee test.log     # section 7
godot --headless --path . --quit-after 120               # smoke run of the main scene (~2 s)
```

Rule lint (each hit must be an allowed case or carry an `EXCEPTION` tag; `scripts/editor/` and `tests/` are exempt where R7/7.4 say so):

```bash
grep -rnE "(Node|Node2D|Control|Label|Button|Timer|Sprite2D|AnimatedSprite2D|CollisionShape2D|Area2D|CanvasLayer|AudioStreamPlayer|AnimationPlayer)\.new\(" scripts --exclude-dir=editor
grep -rnE "\.connect\(" scripts --exclude-dir=editor | grep -v "EXCEPTION"
grep -rnE "create_tween|Tween" scripts --exclude-dir=editor
grep -rnE 'get_node\(|\$"?\.\.|get_parent\(\)|owner\.' scripts
grep -rnE "preload\(|[^_]load\(" scripts
grep -rnE "ColorRect|Polygon2D|Line2D|_draw\(" scenes scripts --exclude-dir=editor
grep -rnE "add_theme_.*_override" scripts --exclude-dir=editor
grep -rnE "[^A-Za-z_\"]-?[0-9]+\.[0-9]+" scripts --exclude-dir=editor      # magic floats in logic
find scripts -name "*.gd" -path "*/utils/*" | xargs grep -L "static func"   # utils must be static
```

Checklist:
- [ ] Every tuning value is an export or Resource field; constants are true constants in `scripts/constants/`.
- [ ] No nodes/resources built in code (or tagged / inside `scripts/editor/`).
- [ ] Same-scene signals are `[connection]`s; code connections are in the allowed table.
- [ ] Animated scenes have an `AnimationController`; every Tween is tagged and justified.
- [ ] Every visual has a texture; placeholders are SVG; manifest updated.
- [ ] Scene files are in the right kind folder (2.1); scripts in the mirror folder (2.2); variants keep the same tree.
- [ ] Scene contract header present; required exports asserted.
- [ ] Tests written for new/changed behaviour; **full suite green after the last change**; no `ERROR` in the log.
- [ ] No dangling references (headless load passes); no untyped code.

---

## 9. Final report format

Pre-fill it: `python tools/diff_summary.py --save docs/reports/<date>_<task>.md` (needs a git baseline commit). Then complete the TODOs. The report lists **every** section below, not only a summary.

1. **Summary** (what was built, 3-5 lines).
2. **Files** created/changed/moved.
3. **Exports added** (scene, name, default, unit).
4. **Signals:** `.tscn` connections added; code connections added (with category).
5. **Animations:** names, AnimationController API; Tweens (with justification).
6. **Placeholders** added (manifest lines).
7. **Tests:** files added/changed; command run; result line (`Tests: N passed, M failed`); criteria covered. If not run: **NOT VERIFIED** and why.
8. **Exceptions** (all `EXCEPTION` tags, with reason).
9. **Assumptions / deviations / open questions.**
10. **Verification:** commands run and results; checks that could not be run.
