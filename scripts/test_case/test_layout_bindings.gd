extends SceneTree
## ============================================================================
## Test Case: BINDING NODE CỦA MÀN ⇄ SCENE LAYOUT (Portrait / Landscape)
##
## Mỗi màn tách 2 bố cục `scenes/layout/{portrait,landscape}/<màn>.tscn`; script layout
## (`scripts/scenes/layout/<màn>_layout.gd`) khai `@export` node và .tscn BIND SẴN bằng
## `NodePath` — script màn chỉ đọc `layout.<tên>`.
##
## Test này mở từng màn, soi CẢ 2 bố cục và đòi:
##   1. Node layout gắn ĐÚNG script layout của màn (class_name khớp).
##   2. Mọi `@export` (kiểu Object) đều trỏ tới node THẬT — trừ node nằm trong OPTIONAL
##      (bố cục ngang của splash/title chưa có node đó — thiếu có sẵn từ trước).
## ============================================================================

## Màn ⇄ class_name script layout + scene gốc
const SCREENS := {
	"settings": "SettingsLayout",
	"main": "MainLayout",
	"ranking": "RankingLayout",
	"chapters": "ChaptersLayout",
	"daily": "DailyLayout",
	"shop": "ShopLayout",
	"archivement": "ArchivementLayout",
	"credit": "CreditLayout",
	"debug": "DebugLayout",
	"splash": "SplashLayout",
	"title": "TitleLayout",
	"levels": "LevelsLayout",
	## Màn chơi: mỗi hướng 1 script riêng, đều kế thừa `GameSceneLayout`
	"game": "GameSceneLayout|GameLayout",
}
## Node được phép THIẾU ở 1 hướng (bố cục ngang chưa dựng node đó) — khoá "<màn>|<hướng>"
## `hud_slot` của màn chơi: HUD bị THAY bằng code ngay khi vào màn (đổi theo chế độ chơi) nên
## node Information ban đầu bị free — binding cũ trỏ vào node đã free là chuyện bình thường.
## `instruction_btn` bản NGANG: nút "?" trên thanh trạng thái đã BỎ — hướng dẫn nằm trong
## khung `InstructionSection` của HUD ngang (nhúng sẵn, hoặc nút mở popup khi khung quá nhỏ).
## `pad_slot` của shop: CHỈ bố cục NGANG có khung riêng cho Bàn nháp (cột trái như mockup);
## bản DỌC vẫn để bàn nháp trong danh sách nên không khai node này.
const OPTIONAL := {
	"splash|landscape": ["fade_overlay"],
	"title|landscape": ["touch_button", "fade_overlay"],
	"game|portrait": ["hud_slot"],
	"game|landscape": ["hud_slot", "instruction_btn"],
	"shop|portrait": ["pad_slot"],
}

var _failed := 0
var _checks := 0


func _init() -> void:
	print("\n========================================================")
	print("  TEST: BINDING LAYOUT (export ⇄ node trong .tscn)")
	print("========================================================\n")
	root.size = Vector2i(1080, 1920)
	await process_frame

	for screen: String in SCREENS:
		await _check_screen(screen, SCREENS[screen])

	print("\n--------------------------------------------------------")
	if _failed == 0:
		print("  KET QUA: %d/%d CHECK PASS" % [_checks, _checks])
	else:
		print("  KET QUA: FAIL %d/%d CHECK" % [_failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)


func _check_screen(screen: String, layout_class: String) -> void:
	var path := "res://scenes/%s.tscn" % screen
	var packed := load(path) as PackedScene
	if packed == null:
		_entry(false, "%s: nạp được %s" % [screen, path])
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	for holder_name in ["Portrait", "Landscape"]:
		var holder: Node = scene.get_node_or_null(holder_name)
		if holder == null:
			continue
		var script: Script = holder.get_script()
		if script == null:
			_entry(false, "%s/%s: gắn script layout" % [screen, holder_name])
			continue
		var cls: String = script.get_global_name()
		var allowed: PackedStringArray = layout_class.split("|")
		if cls == "":
			_entry(true, "%s/%s: script riêng theo hướng (kế thừa %s)" % [screen, holder_name, allowed[0]])
		else:
			_entry(allowed.has(cls), "%s/%s: script = %s (muốn %s)"
				% [screen, holder_name, cls, " · ".join(allowed)])
		_check_exports(scene, holder, screen, holder_name, script)
	scene.queue_free()
	await process_frame


func _check_exports(scene: Node, holder: Node, screen: String, holder_name: String, script: Script) -> void:
	var opt: Array = OPTIONAL.get(("%s|%s" % [screen, holder_name]).to_lower(), [])
	var total := 0
	var missing: Array[String] = []
	for prop: Dictionary in script.get_script_property_list():
		if not (int(prop.get("usage", 0)) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		if int(prop.get("type", 0)) != TYPE_OBJECT:
			continue
		total += 1
		var value: Variant = holder.get(str(prop.get("name")))
		if value == null and not opt.has(str(prop.get("name"))):
			missing.append(str(prop.get("name")))
	_entry(total > 0, "%s/%s: có %d export node trên script layout" % [screen, holder_name, total])
	_entry(missing.is_empty(), "%s/%s: mọi export trỏ tới node thật%s"
		% [screen, holder_name, "" if missing.is_empty() else " — thiếu: " + ", ".join(missing)])

	# script màn phải lấy được layout (2 bố cục dùng CÙNG class nên `active_layout()` trả về được)
	if holder_name == "Portrait" and scene.get("layout") == null:
		_entry(false, "%s: scene.layout chưa được gán sau _ready()" % screen)


func _entry(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
	print("  %s %s" % ["[OK]" if ok else "[FAIL]", label])
