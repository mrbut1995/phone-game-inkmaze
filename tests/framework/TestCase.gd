extends RefCounted
class_name TestCase
## Base class for all tests (zero-dependency framework).
## File: test_<name>.gd  |  methods: test_<behaviour>_<condition>()  |  may use `await`.
## A fresh instance is created for every test method.

## Set by the runner.
var tree: SceneTree

var _failures: Array[String] = []
var _assert_count: int = 0
var _tracked: Array[Object] = []

## Override. Runs before every test method (may await).
func before_each() -> void:
	pass

## Override. Runs after every test method (may await).
func after_each() -> void:
	pass

func get_failures() -> Array[String]:
	return _failures

func get_assert_count() -> int:
	return _assert_count

# ---------- helpers ----------

## Frees the object automatically after the test (Nodes/Objects; RefCounted is ignored).
func autofree(obj: Object) -> Object:
	_tracked.append(obj)
	return obj

## Adds the node under the root of the SceneTree and frees it after the test.
func add_to_tree(node: Node) -> Node:
	tree.root.add_child(node)
	_tracked.append(node)
	return node

func instantiate_scene(path: String) -> Node:
	var packed := load(path) as PackedScene
	assert_not_null(packed, "cannot load " + path)
	if packed == null:
		return null
	return packed.instantiate()

func await_frames(count: int = 1) -> void:
	for i in count:
		await tree.process_frame

## Called by the runner after every test.
func cleanup() -> void:
	if tree != null:
		tree.paused = false
	for obj in _tracked:
		if is_instance_valid(obj) and not (obj is RefCounted):
			obj.free()
	_tracked.clear()

# ---------- assertions ----------

func fail(message: String) -> void:
	_assert_count += 1
	_record("explicit failure", message)

func assert_true(condition: bool, message: String = "") -> void:
	_assert_count += 1
	if not condition:
		_record("expected true", message)

func assert_false(condition: bool, message: String = "") -> void:
	_assert_count += 1
	if condition:
		_record("expected false", message)

func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	_assert_count += 1
	if actual != expected:
		_record("expected <%s> but got <%s>" % [str(expected), str(actual)], message)

func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	_assert_count += 1
	if actual == unexpected:
		_record("expected value different from <%s>" % str(unexpected), message)

func assert_almost_eq(actual: float, expected: float, tolerance: float = 0.001, message: String = "") -> void:
	_assert_count += 1
	if absf(actual - expected) > tolerance:
		_record("expected <%s> +/- %s but got <%s>" % [str(expected), str(tolerance), str(actual)], message)

func assert_null(value: Variant, message: String = "") -> void:
	_assert_count += 1
	if value != null:
		_record("expected null but got <%s>" % str(value), message)

func assert_not_null(value: Variant, message: String = "") -> void:
	_assert_count += 1
	if value == null:
		_record("expected a non-null value", message)

func assert_has(collection: Variant, item: Variant, message: String = "") -> void:
	_assert_count += 1
	if not (item in collection):
		_record("expected <%s> to contain <%s>" % [str(collection), str(item)], message)

# ---------- internals ----------

func _record(detail: String, message: String) -> void:
	var text: String = "%s: %s" % [_caller_location(), detail]
	if message != "":
		text += " | " + message
	_failures.append(text)

func _caller_location() -> String:
	for frame in get_stack():
		var function_name: String = str(frame.get("function", ""))
		if function_name.begins_with("test_") or function_name == "before_each" or function_name == "after_each":
			return "%s:%d" % [str(frame.get("source", "?")).get_file(), int(frame.get("line", 0))]
	return "?"
