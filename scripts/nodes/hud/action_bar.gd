class_name ActionBar
extends Control
## ============================================================================
## Thanh nút hành động của màn chơi (Tool · Wall · Undo · Hint · Replay) — nằm TRONG HUD
## của mỗi chế độ. MỖI HƯỚNG MÀN HÌNH CÓ 1 SCENE RIÊNG (không di chuyển node lúc chạy):
##   · `nodes/hud/portrait/action_bar.tscn`  — 1 hàng ngang: Portrait/Row
##   · `nodes/hud/landscape/action_bar.tscn` — 2 hàng: MainRow (VẼ ĐƯỜNG · GHI NHỚ)
##                                             + SubRow (UNDO · HINT · CHƠI LẠI)
##
## HUD bản dọc = `nodes/hud/<mode>.tscn` (kế thừa `portrait/portrait.tscn`)
## HUD bản ngang = `nodes/hud/landscape/<mode>.tscn` (kế thừa `landscape/landscape.tscn`)
## GameScene chỉ lấy nút ra từ HUD đang chơi (xem GameScene._bind_hud_nodes) — nhờ vậy mỗi
## chế độ tự bày nút theo bố cục của hướng màn hình tương ứng.
## ============================================================================

const BUTTON_NAMES: Array[String] = ["Tool", "Wall", "Undo", "Hint", "Replay"]

var _landscape := false


## Bố cục do SCENE quy định (mỗi hướng 1 scene riêng) ⇒ chỉ ghi nhớ hướng để code khác hỏi.
func set_landscape(on: bool) -> void:
	_landscape = on


func is_landscape() -> bool:
	return _landscape


## Nút theo tên — tìm SÂU trong thanh (nút nằm trong Row/MainRow/SubRow của từng hướng)
func button(name: String) -> BaseButton:
	return find_child(name, true, false) as BaseButton


func tool_path_btn() -> BaseButton:
	return button("Tool")


func tool_wall_btn() -> BaseButton:
	return button("Wall")


func undo_btn() -> BaseButton:
	return button("Undo")


func hint_btn() -> BaseButton:
	return button("Hint")


func replay_btn() -> BaseButton:
	return button("Replay")
