# Godot 4 cheat sheet (for agents that know Godot 3 better)

Lint rule `GODOT3` rejects the left column. Typed GDScript everywhere.

## Syntax: Godot 3 -> Godot 4
| Godot 3 | Godot 4 |
|---|---|
| `onready var x = $N` / `export var v = 1` | `@onready var x: Node = %N` / `@export var v: int = 1` |
| `tool` | `@tool` |
| `yield(get_tree(), "idle_frame")` | `await get_tree().process_frame` |
| `btn.connect("pressed", self, "_f")` | `btn.pressed.connect(_f)` (prefer `[connection]` in the `.tscn`, R3) |
| `emit_signal("x", a)` | `x.emit(a)` |
| `scene.instance()` | `scene.instantiate()` |
| `KinematicBody2D`, `Spatial` | `CharacterBody2D`, `Node3D` |
| `move_and_slide(vel)` | `velocity = vel; move_and_slide()` |
| `rand_range(a, b)` / `randi() % n` | `randf_range(a, b)` / `randi_range(0, n - 1)` |
| `OS.get_ticks_msec()` | `Time.get_ticks_msec()` |
| `get_tree().change_scene("res://x.tscn")` | `get_tree().change_scene_to_file("res://x.tscn")` / `change_scene_to_packed(p)` |
| `PoolStringArray`, `PoolVector2Array` | `PackedStringArray`, `PackedVector2Array` |
| `setget` | `var v: int: set(value): ...` |
| `Tween.new()` | `create_tween()` (only as a tagged exception, R4) |
| `.tscn` `format=2` | `format=3` |

## Frequently used, correct forms
- Signals: `signal hit(amount: int)`; `hit.emit(3)`; `other.hit.connect(_on_hit)`; `is_connected(callable)`.
- Types: `var a: Array[int] = []`, `var d: Dictionary = {}`, `StringName` literal `&"id"`, enum export `@export var faction: Enums.Faction`.
- Await: `await get_tree().create_timer(t).timeout`, `await some_signal`, `await animation_player.animation_finished`.
- Nodes: `%Unique` (needs `unique_name_in_owner`), `get_node_or_null`, `queue_free()`, `is_instance_valid(x)`, `add_to_group(&"g")`.
- Input: `Input.get_vector(neg_x, pos_x, neg_y, pos_y)`, `event.is_action_pressed(&"action")` (action names from `InputActions`).
- Physics: set `collision_layer`/`collision_mask` in the scene; raycasts only in `_physics_process`: `PhysicsRayQueryParameters2D.create(a, b, mask)`.
- Resources: `@export var scene: PackedScene` then `scene.instantiate() as MyClass`; `ResourceLoader.load_threaded_request(path)`.
- Math: `floori`, `roundi`, `clampf`, `lerpf`, `Vector2i`, `Rect2.has_point`, `TAU`.
- Scene change: through `SceneManager.change_scene(SceneIds.X)`; popups through `PopupManager.open(PopupIds.X)`.
- Strings: `"HP %d/%d" % [a, b]`; `str(x)`; `String.num(x, 2)`.

## Frequent mistakes to avoid
- Indenting with spaces in `.gd` (project uses TAB) or mixing both.
- A function with a return type that does not return on every path.
- Reading `@onready` vars before `_ready` (e.g. from `_init`).
- Freed objects in typed arrays: check `is_instance_valid` before use.
- `Control` children of `Node2D` need `layout_mode = 3` + offsets in the `.tscn`; inside `Container`s use `layout_mode = 2`.
- Writing a signal connection in code that the `.tscn` can express (R3).
