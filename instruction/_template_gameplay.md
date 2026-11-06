# <Game Name> - Gameplay Instruction

> Copy this file to `instruction/<game_name>_gameplay.md` and fill every section.
> This file says **WHAT** to build. **HOW** to build is in `instruction/instruction_writing_project.md` (it wins on any conflict, see its section 0).
> Delete the guidance in `<!-- -->` once filled. Write `TBD` for anything undecided and list it in section 16. Do not leave a section empty.

---

## 1. Meta

| Field | Value |
|---|---|
| Game name / id (snake_case) | |
| Version / milestone | |
| Engine | Godot 4.8 |
| Genre | <!-- e.g. top-down action, idle, turn-based --> |
| Dimension / camera | <!-- 2D top-down / side-scroller / 3D ... --> |
| Platforms | <!-- PC, Android, iOS, Web --> |
| Resolution / stretch / orientation | <!-- 1280x720, canvas_items, landscape --> |
| Input devices | <!-- keyboard, gamepad, touch --> |
| Pixel art / filtering | <!-- nearest or linear --> |
| Foundation | <!-- Node2D world (BaseScene) or Control-only (BaseUIScene) --> |
| Game type playbook | <!-- arcade / room-action / ui-puzzle / ui-management (instruction_project_types.md; samples only) --> |
| A1 Space | <!-- 2D world / 2D board-grid / UI-only (Control) / 3D / mixed --> |
| A2 Time | <!-- real-time physics / real-time tick / turn-based / event-driven --> |
| A3 Control | <!-- keyboard-gamepad / pointer / touch-swipe / none --> |
| A4 State size | <!-- few values / entity list / grid / large simulation --> |
| A5 Content | <!-- hand-placed / tables (CSV) / procedural (seeded) --> |
| A6 Presentation | <!-- static art / frame animation / effect animation / particles-shaders --> |
| A7 Persistence | <!-- none / high score / progress / full save --> |

## 2. Vision and pillars

- **One-sentence pitch:**
- **Pillars (max 3):** <!-- what the game must feel like -->
- **Non-goals (out of scope):** <!-- AI must not build these -->

## 3. Core loop

<!-- Numbered loop: what the player does, what happens, what they get, why they repeat. -->

## 4. Entities

### 4.1 Actors (PC and NPC share `actor.tscn`; they differ by Brain)

| id | Display name | Faction | Brain (player/ai) | Max HP | Move speed | Sight range | Attack range | Damage | Cooldown (s) | Placeholder visual |
|---|---|---|---|---|---|---|---|---|---|---|
| | | | | | | | | | | |

AI behaviours per NPC id (ordered by priority): <!-- Flee > Attack > Chase > Wander, or custom -->

### 4.2 Items

| id | Kind (static/dynamic) | Interaction | Effect | Stack | Placeholder visual |
|---|---|---|---|---|---|
| | | | | | |

### 4.3 Other world objects (doors, switches, hazards, spawners)

| id | Behaviour | Interaction | Placeholder visual |
|---|---|---|---|

### 4.4 Families that need variants

<!-- Only when behaviour (script) differs but the node tree is the same. Otherwise use Definitions (4.1/4.2). -->

| Base scene | Variant | What differs (script hook / sub-resource) |
|---|---|---|
| `bird.tscn` | `seagull.tscn` | |

## 5. Mechanics and rules

> **Spec clarity (MUST).** Any rule about direction, position, order or time needs a *worked example per case*, never only words like "matching", "same", "opposite", "adjacent".
> Example: "Hero leaves through the RIGHT doorway -> appears 16 px inside the LEFT edge of the room to the right, same row." Give one example for each of the 4 directions and for the blocked/edge case.
> Check units against the viewport (room size x tile size vs resolution) before handing the doc to an agent.

<!-- One subsection per mechanic: movement, combat, interaction, progression, economy... -->
<!-- Give formulas using variable names; each variable must appear in the tuning table (section 6). -->

### 5.1 <Mechanic>
- Trigger:
- Rule / formula:
- Edge cases:
- Feedback (animation/sound/UI):

## 6. Tuning table (feeds `@export` / definitions)

<!-- Every number from sections 4-5. "Stored in" decides R1: Definition (.tres) | Scene export | Config (.tres). -->

| Parameter | Default | Range | Unit | Stored in (Definition / scene export / config) | Owner (file / node) |
|---|---|---|---|---|---|
| | | | | | |

## 7. Controls

| Action name (in project.godot) | Keyboard | Gamepad | Touch | Effect |
|---|---|---|---|---|
| move_left / move_right / move_up / move_down | A D W S | Left stick | Virtual stick | Move |
| interact | E | A | Button | Interact / pick up |
| attack | Space | X | Button | Attack nearest hostile |

## 8. Screens, scenes and flow

<!-- Kind per instruction section 2.1: screen | object | component | variant | base | autoload. Folder follows the kind. -->

| Scene file | Kind | Inherits | Purpose | Contains |
|---|---|---|---|---|
| `scenes/screens/boot.tscn` | screen | - | Boot, load settings/save | |
| `scenes/screens/main_menu.tscn` | screen | `base_scene` | | |
| `scenes/screens/game.tscn` | screen | `base_scene` | | |
| `scenes/objects/world/actor.tscn` | object | - | | |
| `scenes/components/actor/actor_info_view.tscn` | component | - | | |

**Navigation:** `boot -> main_menu -> game -> (pause popup) -> main_menu`
<!-- Add win/lose/result screens and popups: id, trigger, buttons, result. -->

## 9. World / levels

- Layout, size, camera behaviour:
- Spawns (what, where, when):
- Win / lose conditions:
- Difficulty progression:

## 10. UI / UX

<!-- HUD elements (id, what it shows, which Model value it binds to), menus, popups, text/localisation approach, accessibility. -->
<!-- Reuse custom widgets from scripts/editor/ (e.g. Button2D, StateTexture) instead of rebuilding them. -->

| UI element | Scene | Bound to (Model value / EventBus signal) | Notes |
|---|---|---|---|

## 11. Art and audio direction

- Style, palette by role (overrides the default colours in R5):
- Font(s):
- Audio: music per screen, SFX list (`assets/audio/...`; use silent/beep placeholders until real files exist).

**Required visuals** (this table seeds `assets/images-placeholder/MANIFEST.md`):

| Visual id | Used by | Final size (px) | Pivot | Frames | Notes |
|---|---|---|---|---|---|

## 11b. Spritesheets (frame animation, instruction F1)

<!-- One row per sheet. Rows = animations named `<state>_<direction>` (direction: down|up|left|right|side; art for right/side faces right, left is mirrored at runtime).
     Source decides the command: none -> `spritesheet.py placeholder`, frame files -> `pack-dir`, Aseprite -> `from-aseprite`, ready sheet -> `inspect` + spec.
     Control-only project: the scene uses `FrameTextureRect`; say so in "Used by". -->

| Sheet | Source (none / folder / aseprite / sheet) | Frame size | Animations: name:frames (top to bottom) | fps | Loops | Directions shipped | Used by (scene + node) |
|---|---|---|---|---|---|---|---|
| characters/hero | none | 16x16 | idle_down:2, walk_down:6, idle_side:2, walk_side:6, attack_side:4, death_down:4 | state default (idle 4, walk 8, attack 12) | all except attack/death | down, side (left = mirrored) | actor.tscn Sprite |

## 12. Animations and effects

<!-- One row per animation. These become AnimationPlayer animations + AnimationController methods (R4). -->
<!-- Mark "Tween?" = yes only with a written reason that satisfies R4. -->

<!-- Kind: `effect` = tracks in an AnimationPlayer (flash, shake, fade; gen_animation.py); `frame` = SpriteFrames cycle from section 11b (play_state(state, direction)).
     Control-only scenes: `frame` rows use FrameTextureRect; `effect` rows animate modulate/scale/rotation, never the position of a container child (instruction F1). -->

| Scene | Animation name | Kind (effect / frame) | Trigger (event) | Duration (s) or fps | Loop | AnimationController method / widget call | Tween? (reason) |
|---|---|---|---|---|---|---|---|
| actor | idle_<dir> | frame | spawn / stop moving | 4 fps | yes | `play_state(&"idle", dir)` | no |
| actor | walk_<dir> | frame | moving | 8 fps | yes | `play_state(&"walk", dir)` / `face(velocity)` | no |
| actor | hit | effect | health decreased | | no | `play_hit()` | no |
| actor | death | effect | model died | | no | `play_death()` | no |

## 13. Data and persistence

- Definitions (`data/actors`, `data/items`, ...): list ids.
- Saved state (PlayerProfile fields), save slots, versioning:
- Settings saved:

## 14. Events (EventBus additions)

| Signal | Args | Emitted by | Consumed by |
|---|---|---|---|

## 15. Milestones and acceptance criteria

<!-- Small, testable. Give every criterion an id. Each criterion needs at least one test (instruction section 7.3).
     Write criteria as OUTCOMES (where/what/how much), e.g. "hero x == left edge + 16 px", not "transition triggers". Add the negative/blocked case as its own criterion. -->
<!-- An AI task = one milestone or part of it. A milestone is done only when its tests are green. -->

### M1 - <name>

| Id | Criterion (Given / When / Then) | Test file :: method |
|---|---|---|
| M1-1 | Given ..., when ..., then ... | `tests/unit/...::test_...` |
| M1-2 | | |

- [ ] Full test suite green and verification clean (instruction sections 7-8).

## 16. Approved deviations, assumptions, open questions

**Approved deviations from engineering rules** (default: none). Format: `Rule R<n> | scope | reason | approved by`.

**Assumptions made:**

**Open questions:**
