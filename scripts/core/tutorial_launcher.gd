class_name TutorialLauncher
extends RefCounted
## ============================================================================
## MỞ BÀI HỌC ("?") TỪ TRONG VÁN CHƠI — tách khỏi `GameController`.
##
## Hai bước:
##   1. `ids_for(mode_id, floor)` — bài nào cần mở cho chế độ/tầng này (rỗng = không có nút "?").
##   2. `launch(host, ids)` — ghi yêu cầu vào `GameManager.pending_tutorial` rồi mở
##      `scenes/tutorial.tscn` dưới dạng LỚP PHỦ ngay trên màn chơi (không đổi scene).
##
## Trong LUỒNG HỌC LẦN ĐẦU, màn thực hành chỉ mở ĐÚNG bài của màn đó
## (xem `TutorialManager.practice_tutorial_for_level`).
##
## Ai gọi: `GameController.open_instruction()`.
## ============================================================================

## Bài học theo chế độ chơi
const IDS := {
	"play": ["how_to_play_move", "how_to_play_checking_wall", "how_to_use_tool"],
	"standard": ["how_to_play_move", "how_to_play_checking_wall", "how_to_use_tool"],
	"challenge": ["how_to_play_move", "how_to_play_checking_wall", "how_to_use_tool"],
	"daily_classic": ["how_to_play_move", "how_to_play_checking_wall", "how_to_use_tool"],
	"daily_challenge": ["how_to_play_move", "how_to_play_checking_wall", "how_to_use_tool"],
	"minesweeper": ["how_to_play_minesweeper"],
	"sum_path": ["how_to_play_sum_path"],
	"countdown_cost": ["how_to_play_countdown_cost"],
	"blind_memory": ["how_to_play_blind_memory"],
	"fog_of_war": ["how_to_play_fog_of_war"],
	"fading_ink": ["how_to_play_fading_ink"],
	"one_stroke": ["how_to_play_one_stroke"],
	"wall_builder": ["how_to_play_wall_builder"],
}
## Chế độ không có nút "?" (Dungeon — luật đã hiện trong popup hướng dẫn riêng)
const MODES_WITHOUT_TUTORIAL: Array[String] = ["dungeon"]


## Danh sách bài học cần mở cho chế độ/tầng hiện tại ([] = không mở gì)
static func ids_for(mode_id: String, floor_number: int) -> Array:
	if mode_id in MODES_WITHOUT_TUTORIAL:
		return []
	var ids: Array = IDS.get(mode_id, [])
	var tm := Svc.tutorial()
	if tm != null and tm.has_method("practice_tutorial_for_level"):
		var only := str(tm.call("practice_tutorial_for_level", floor_number))
		if not only.is_empty():
			ids = [only]
	return ids


## Ghi yêu cầu mở bài học + dựng lớp phủ Tutorial trên `host` (màn chơi đang chạy)
static func launch(host: Node, ids: Array) -> void:
	if host == null or ids.is_empty():
		return
	var gm := Svc.game()
	if gm == null:
		return
	gm.set("pending_return_to_game", true)
	# Lớp phủ KHÔNG đi qua danh sách ⇒ xoá cờ danh sách còn sót của lần trước
	gm.set("pending_return_to_list", false)
	# `pending_tutorial` được tutorial.gd đọc; nhiều bài nối bằng dấu phẩy → chạy theo chuỗi
	gm.set("pending_tutorial", ",".join(ids))
	_open_overlay(host)


## Mở màn Tutorial dạng LỚP PHỦ ngay TRÊN màn chơi (không đổi scene):
## ván đang chơi được GIỮ NGUYÊN; đóng lớp phủ (học xong / bỏ qua / Back) → chơi tiếp đúng ván đó.
static func _open_overlay(host: Node) -> void:
	if host.has_node("TutorialOverlay"):
		return
	var scene := load("res://scenes/tutorial.tscn") as PackedScene
	if scene == null:
		return
	var overlay := scene.instantiate()
	overlay.name = "TutorialOverlay"
	# Cờ này được TutorialScene đọc trong `_ready` ⇒ phải set TRƯỚC khi add_child
	overlay.set("overlay_mode", true)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	host.add_child(overlay)
	# Màn chơi bên dưới đứng yên hoàn toàn (cả nhận input) cho tới khi đóng lớp phủ
	host.process_mode = Node.PROCESS_MODE_DISABLED
