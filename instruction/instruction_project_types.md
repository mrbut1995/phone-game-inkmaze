# Instruction: Project Types and Capability Coverage

**Version 1.1.** How one template serves **different kinds of projects** without new rules and without wasting tokens.
Any game/app named below is only a *sample* to test coverage, never a target. Read after `brief.md`, when the gameplay file does not fit a project you have seen before.

---

## 0. Method (any project)

0. **Archetype intake (MUST, 5 minutes, before the plan).** Answer the 7 axes below from the gameplay file and write the answers in its section 1 ("Archetype"). The answers, not the game's name, pick the foundation, blocks and tests. A project that matches no sample is normal: only the axes matter.
1. **Pick the foundation** (section 1).
2. **Map each capability the gameplay file needs to a block** (section 2). Provided block -> use it. Pattern -> follow the card (section 3). Missing -> create the block (section 4).
3. **Pure logic first** (`models/`, `systems/`, `utils/`) with tests; **then** scenes/views; wiring in the `.tscn`; animation; placeholders.
4. Plan with `gameplay_to_plan.py`; verify with `run_checks.py`.

### 0.1 The 7 axes

| Axis | Values | Decides |
|---|---|---|
| A1 Space | 2D world / 2D board-grid / UI-only (Control) / 3D / mixed | foundation (section 1) |
| A2 Time | real-time physics / real-time tick (`SimClock`) / turn-based / event-driven (UI) | P3, P4, P14; `_physics_process` vs `advance()` |
| A3 Control | keyboard-gamepad / pointer click-drag / touch-swipe / none (idle) | `InputActions`, P16, UI nodes |
| A4 State size | few values / entity list / grid / large simulation | model shape (P1, P5, P4) |
| A5 Content | hand-placed / tables (CSV -> Definitions) / procedural (seeded) | `data_import`, seeded RNG, P3/P8/P13 |
| A6 Presentation | static art / frame animation / effect animation / particles-shaders | F1 (spritesheet), R4 (AnimationPlayer), R2b |
| A7 Persistence | none / high score / progress / full save | P7, `SaveManager` |

Example answers (not targets): *driving-dodge* = 2D world, real-time physics, keyboard/touch, few values, procedural (seeded), frame+effect, high score. *Zelda-like* = 2D world (rooms), real-time physics, keyboard, entity list, hand-placed, frame+effect, progress. *2048* = UI-only, event-driven, swipe/keys, grid, procedural (seeded), effect (Tween P6), high score. *Restaurant management* = UI-only, tick, pointer, large simulation, tables, frame+effect, full save. Any other game is answered the same way.

## 1. Foundation

| The project needs | Foundation | How |
|---|---|---|
| 2D world: sprites, physics, camera, rooms | `scenes/base/base_scene.tscn` (`BaseScene`: Node2D + CanvasLayer UI) | screens inherit it |
| Only UI widgets (boards, lists, forms, menus) | `scenes/base/base_ui_scene.tscn` (`BaseUIScene`: Control root) | screens inherit it; no Node2D anywhere |
| 3D world | not provided | `python tools/new_scene.py base base_scene_3d --root Node3D` mirroring `BaseScene`; keep UI/Popup/controllers the same; add the block to `docs/blocks.md` |
| Mixed (UI-heavy with a small 2D stage) | `BaseUIScene` + a 2D object scene embedded through `SubViewportContainer` or a plain instanced `Node2D` object | keep the 2D part an *object* scene |

### 1.1 Control-only projects (BaseUIScene): what changes

- **No Node2D anywhere.** Sprites become `TextureRect`; frame animation = `FrameTextureRect` (F1); never `AnimatedSprite2D`/`Sprite2D` under a `Container`.
- **Containers own layout.** Do not animate `position`/`size` of a container child (the container resets it). Animate `modulate`, `scale` (set `pivot_offset` in the scene), `rotation`, `custom_minimum_size` of a wrapper, or a transform of a child *inside* a wrapper `Control`. Position-driven motion that cannot be expressed this way (a tile sliding across a board) = **P6 tagged Tween** on a non-container `Control` layer.
- **Board/list items** are instanced scenes in a container (P2); the model holds the truth, the view diffs by id.
- **Input** is `Control` signals wired in the `.tscn` (`pressed`, `gui_input`, `focus_entered`); swipes/drag via P16, never raw `_input` polling in logic.
- **Themes:** one `Theme` resource in `data/config/` assigned on the root Control; no `add_theme_*_override` in scripts (R2).
- **Scaling:** `stretch/mode = canvas_items`, anchors/containers instead of pixel positions; test one wide and one narrow aspect in the smoke test list if the target is mobile.

## 2. Capability matrix

| Capability | Provided block | Notes |
|---|---|---|
| Whole-screen flow, popups, pause, settings | `SceneManager`, `PopupManager`, `BaseScene`/`BaseUIScene`, popups | ids in `SceneIds`/`PopupIds` |
| Save/load, profile, settings | `SaveManager`, `PlayerProfile`, `SettingsManager`, `Saveable` | extend `PlayerProfile.to_dict/from_dict` |
| Content tables / balancing | Definitions (`.tres`) + `data_import.py` (CSV) | R1 |
| Time-driven simulation | `SimClock` (pure, pausable, speed, save) | never read wall-clock in logic |
| Entity state | `StateMachine` (pure transition table) | customers, enemies, UI flows |
| Grid / board / rooms math | `GridMath` (cell <-> world, neighbors, bounds) | pure |
| Actor control (2D) | Commands, Brains, `CommandHandler`, `Perception`, AI behaviours, `WorldQuery`, `FactionRules` | optional; delete if unused |
| Collision / layers | `PhysicsLayers`, `Groups`, `Area2D` signals wired in `.tscn` | |
| Effect animation (flash, shake, fade) | `BaseAnimationController`, `gen_animation.py`, Tween exception | R4 |
| Frame animation (sprite cycles, directions) | `spritesheet.py` (placeholder / pack-dir / from-aseprite / frames), `BaseFrameAnimationController`, `FrameAnimUtils`, `FrameTextureRect` (Control) | F1 |
| Art / audio placeholders | `new_svg.py`, `spritesheet.py placeholder`, `placeholder_audio.py` | R5 |
| Audio playback | `AudioManager` (scene autoload) | |
| Input | `InputActions` + `project.godot` actions | touch/swipe, rebinding: create the block |
| Randomness | seeded `RandomNumberGenerator` injected into models | tests seed it |
| Difficulty / progression | exported `Curve` resources | |
| Localization | not provided | create the block when needed |
| Networking | not provided | out of template scope |

## 3. Pattern cards (use, do not reinvent)

| Id | When | Shape | Tests |
|---|---|---|---|
| P1 Model + view binding | any state shown on screen | `RefCounted` model emits signals; view has `set_*()`; controller connects in `setup()` with `# code-connect: model`; view->controller in `.tscn` | model unit tests; view smoke |
| P2 Instanced list/grid | rows, tiles, cards, inventory | one scene + exported `PackedScene` + `instantiate()` into a container; update by id (diff), never rebuild every tick | add/remove/update ids |
| P3 Timed spawner | enemies, traffic, customers, drops | component with a `Timer` node (wait_time in the scene), exported scene/area/curve, `_on_timer_timeout` wired in `.tscn`, seeded RNG | handler spawns; pattern fairness pure + seeded |
| P4 Tick simulation | management, idle, turn systems | `SimClock.advance(delta)` -> systems advance per tick -> models emit | N ticks => expected state |
| P5 Board/grid rules | puzzles, tactics, tile games | pure model with `GridMath`; moves return a result record (what moved/merged/spawned) for the view to animate | every rule + edge + determinism |
| P6 Runtime-computed motion | tile slide, fly-to-target, count-up | Tween as a **tagged exception** (R4): exported duration/ease, kill the previous Tween, block input while animating | logic tested without the Tween |
| P7 Save slice | progress, high score | fields in `PlayerProfile` with `to_dict`/`from_dict`; version key | round trip + missing keys |
| P8 Difficulty curve | arcade, waves, economy | `@export var curve: Curve`; pure `difficulty_at(t)` | sample points |
| P9 Spatial/directional rule | room flip, movement, merge order | separate *travel direction* from *entry side* by name; helper is a static pure function | **one test per direction + blocked case**, assert resulting position/value |
| P10 Scrolling / parallax world | endless road, runner, shooter | world scrolls past a fixed camera: `speed` export, `ParallaxBackground`/`Parallax2D` layers authored in the scene, spawner (P3) spawns beyond the screen edge, despawn by `VisibleOnScreenNotifier2D.screen_exited` wired in the `.tscn` | scroll offset after N s; spawn/despawn bounds |
| P11 Object pool | bullets, particles, tiles reused | `Pool` system (pure list of free/used ids) + scene instances kept in the tree, `visible`/`process_mode` toggled; only when profiling shows `instantiate()` cost | acquire/release/exhausted |
| P12 Camera | follow, shake, room lock | `Camera2D` in the scene; follow target by export; shake = `AnimationPlayer` offset track (fixed) or tagged Tween (decaying) | limits respected |
| P13 Room / level data | rooms, stages, waves | level = Resource (`data/levels/*.tres`) or CSV via `data_import`; a loader instantiates exported scenes; validate the data in a pure function | every exit/neighbor; unreachable room |
| P14 Turn-based flow | tactics, card games, board games | `StateMachine` for phases + a command queue of results (what happened) that views play back one by one; input locked while playing back | phase order; illegal move rejected |
| P15 Dialogue / text content | adventures, tutorials, flavour text | `Resource` lines with ids, text through `tr()` keys, a `DialogueRunner` (pure) that returns the next line / choices | branch coverage |
| P16 Touch / swipe / drag input | mobile, puzzle | a small input component emits `swiped(direction: StringName)` / `dragged(...)` with exported thresholds; logic only sees directions | thresholds both sides |
| P17 Big numbers / idle growth | incremental, economy | model with `float`/`int` + a formatter util (`1.2K`); offline progress = `SimClock.advance(elapsed)` capped by an export | overflow cap; format table |

## 4. When a capability is missing: add a block (procedure)

1. Write the pure logic in `scripts/systems/` or `scripts/models/` (`RefCounted`/`Resource`), no Node access, injected dependencies.
2. Tests first/with it (`new_test.py <Class>`), then scenes via `new_scene.py`.
3. Numbers as exports/Definitions (R1); ids as constants (`scripts/constants/`).
4. Add one line to `docs/blocks.md` (create it): `Name | path | public API | tests`. Future sessions read that file instead of the code.
5. Reusable across projects? Mention it in the report as "block candidate for the template".

## 5. Samples (coverage checks only)

| Sample | Foundation | Blocks | Tests that matter |
|---|---|---|---|
| Top-down driving, dodge cars | `BaseScene` | P3 spawner, P8 curve, `PhysicsLayers`, `gen_animation`, `placeholder_audio` | run model, fair traffic pattern (seeded), collision handler |
| NES-Zelda-like rooms | `BaseScene` | actors/commands/AI, `GridMath`, rooms, P9 | every transition direction + blocked case, combat rules |
| 2048-style, Control only | `BaseUIScene` | P1, P2, P5, P6 | slide/merge table, deterministic spawn, game over/win |
| Restaurant management, Control only | `BaseUIScene` | `SimClock`, `StateMachine`, P2, P4, `data_import` | state transitions, throughput over ticks, economy, save |

## 6. Checklist

- [ ] Foundation chosen (section 1); capabilities mapped (section 2).
- [ ] `docs/blocks.md` updated for every new block.
- [ ] Pure logic + tests before scenes; `run_checks.py` exit 0.
- [ ] No unused template code (lint `DEAD`); no Godot 3 syntax (lint `GODOT3`).
