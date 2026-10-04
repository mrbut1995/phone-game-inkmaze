extends SceneTree
## ============================================================================
## Test Case: BINDING NODE CỦA POPUP (export ⇄ node trong .tscn)
##
## Mọi popup khai `@export` node và BIND SẴN trong .tscn bằng `node_paths` + `NodePath`
## (chuẩn `chapters_layout`/`chapters.tscn`) — script KHÔNG tự dò node bằng chuỗi lúc chạy
## (không còn `piece()` / `get_node_or_null("Panel/...")`).
##
## Test này instantiate từng scene popup và đòi: MỌI `@export` kiểu Object trên script gốc
## đều trỏ tới node THẬT — trừ node nằm trong OPTIONAL (scene không khai node đó).
## Export của `BasePopup` (dim/panel/anim_player) cũng được soi: popup con kế thừa
## `base.tscn` nên phải nhận được binding của base (kiểm luôn cơ chế kế thừa scene).
## ============================================================================

## Scene popup ⇄ đường dẫn (gồm cả 2 scene con: ô mẫu hồ sơ + hàng ngôn ngữ)
const POPUPS := {
	"base": "res://nodes/popups/base.tscn",
	"winning": "res://nodes/popups/winning.tscn",
	"winning_daily": "res://nodes/popups/winning_daily.tscn",
	"gameover": "res://nodes/popups/gameover.tscn",
	"gameover_level": "res://nodes/popups/gameover_level.tscn",
	"next_floor": "res://nodes/popups/next_floor.tscn",
	"pause": "res://nodes/popups/pause.tscn",
	"memory_countdown": "res://nodes/popups/memory_countdown.tscn",
	"language": "res://nodes/popups/language.tscn",
	"edit_profile": "res://nodes/popups/edit_profile.tscn",
	"profiler_popup": "res://nodes/popups/profiler_popup.tscn",
	"edit_profile_item": "res://nodes/popups/edit_profile_item.tscn",
	"language_row": "res://nodes/popups/language_row.tscn",
}
## Export được phép = null: popup `language`/`edit_profile` là scene ĐỘC LẬP không có
## node `AnimationPlayer` của base → `anim_player` null là ĐÚNG thiết kế (base tự chạy tween).
const OPTIONAL := {
	"language": ["anim_player"],
	"edit_profile": ["anim_player"],
}

var _failed := 0
var _checks := 0


func _init() -> void:
	print("\n========================================================")
	print("  TEST: BINDING POPUP (export ⇄ node trong .tscn)")
	print("========================================================\n")
	root.size = Vector2i(1080, 1920)
	await process_frame

	for popup_name: String in POPUPS:
		await _check_popup(popup_name, POPUPS[popup_name])

	print("\n--------------------------------------------------------")
	if _failed == 0:
		print("  KET QUA: %d/%d CHECK PASS" % [_checks, _checks])
	else:
		print("  KET QUA: FAIL %d/%d CHECK" % [_failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)


func _check_popup(popup_name: String, path: String) -> void:
	var packed := load(path) as PackedScene
	if packed == null:
		_entry(false, "%s: nạp được %s" % [popup_name, path])
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var script: Script = scene.get_script()
	if script == null:
		_entry(false, "%s: gắn script" % popup_name)
		scene.queue_free()
		await process_frame
		return

	var opt: Array = OPTIONAL.get(popup_name, [])
	var total := 0
	var missing: Array[String] = []
	for prop: Dictionary in script.get_script_property_list():
		var usage := int(prop.get("usage", 0))
		# @export node: có CẢ SCRIPT_VARIABLE lẫn STORAGE
		# (biến thường như `_tween`/`_closing` chỉ có SCRIPT_VARIABLE — bỏ qua)
		if not (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) or not (usage & PROPERTY_USAGE_STORAGE):
			continue
		if int(prop.get("type", 0)) != TYPE_OBJECT:
			continue
		total += 1
		var value: Variant = scene.get(str(prop.get("name")))
		if value == null and not opt.has(str(prop.get("name"))):
			missing.append(str(prop.get("name")))
	_entry(total > 0, "%s: có %d export node trên script" % [popup_name, total])
	_entry(missing.is_empty(), "%s: mọi export trỏ tới node thật%s"
		% [popup_name, "" if missing.is_empty() else " — thiếu: " + ", ".join(missing)])

	scene.queue_free()
	await process_frame


func _entry(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
	print("  %s %s" % ["[OK]" if ok else "[FAIL]", label])
