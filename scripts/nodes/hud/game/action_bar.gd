class_name ActionBar
extends Control
## ============================================================================
## Thanh nút hành động của màn chơi (CHƠI LẠI · GỬI BÀI · HOÀN TÁC · GỢI Ý · CHƠI LẠI-ván)
## — nằm TRONG HUD của mỗi chế độ. MỖI HƯỚNG MÀN HÌNH CÓ 1 SCENE RIÊNG (không di chuyển node lúc chạy):
##   · `nodes/hud/portrait/game/action_bar.tscn`  — 1 hàng ngang: `Row`
##   · `nodes/hud/landscape/game/action_bar.tscn` — 1 hàng: `SubRow`
##
## Nút VẼ ĐƯỜNG / GHI NHỚ (Tool · Wall) đã BỎ (2026-09-26): bàn cờ tự nhận cả 2 thao tác (kéo nhân
## vật đi đường · kéo nối 2 Anchor để đánh dấu tường) nên thanh nút chỉ còn thao tác thật:
##   · `Restart` — CHƠI LẠI màn/tầng (DỜI từ thanh trạng thái xuống đây — có ở MỌI chế độ)
##   · `Submit`  — GỬI BÀI (chỉ Wall Builder; GameScene tự bật/tắt theo chế độ)
##   · `Undo` / `Hint` — kèm `PanelLimit` (badge nhỏ đè góc nút) hiện SỐ LƯỢT CÒN LẠI
##   · `Replay` — nút phụ ẩn sẵn, UIController hiện khi ván không còn thắng được (Sum Path)
##
## HUD bản dọc = `nodes/hud/<mode>.tscn` (kế thừa `portrait/portrait.tscn`)
## HUD bản ngang = `nodes/hud/landscape/game/<mode>.tscn` (kế thừa `landscape/landscape.tscn`)
## GameScene chỉ lấy nút ra từ HUD đang chơi (xem GameScene._bind_hud_nodes) — nhờ vậy mỗi
## chế độ tự bày nút theo bố cục của hướng màn hình tương ứng.
## ============================================================================

var _landscape := false


## Bố cục do SCENE quy định (mỗi hướng 1 scene riêng) ⇒ chỉ ghi nhớ hướng để code khác hỏi.
func set_landscape(on: bool) -> void:
	_landscape = on


func is_landscape() -> bool:
	return _landscape

## Nút theo tên — tìm SÂU trong thanh (nút nằm trong Row/SubRow của từng hướng)
func button(btn_name: String) -> BaseButton:
	return find_child(btn_name, true, false) as BaseButton

## Nút CHƠI LẠI (reset) — dời từ thanh trạng thái xuống thanh hành động (2026-09-26)
func restart_btn() -> BaseButton:
	return button("Restart")

## Nút GỬI BÀI của Wall Builder (các chế độ khác ẩn — GameScene bật/tắt theo chế độ)
func submit_btn() -> BaseButton:
	return button("Submit")

func undo_btn() -> BaseButton:
	return button("Undo")

func hint_btn() -> BaseButton:
	return button("Hint")

#func replay_btn() -> BaseButton:
	#return button("Restart")


## Cập nhật badge `PanelLimit` + trạng thái KHOÁ của 2 nút theo GIỚI HẠN lượt dùng của màn
## (`max_uses <= 0` = không giới hạn → ẩn badge, không khoá). Badge là CON của nút và
## `NinePatchStateTexture` tự đổi texture theo trạng thái nút cha ⇒ chỉ cần set chữ.
func update_limits(undo_left: int, undo_max: int, hint_left: int, hint_max: int) -> void:
	_apply_limit(undo_btn(), undo_left, undo_max)
	_apply_limit(hint_btn(), hint_left, hint_max)


func _apply_limit(btn: BaseButton, left: int, max_uses: int) -> void:
	if btn == null:
		return
	var limited := max_uses > 0
	btn.disabled = limited and left <= 0
	var panel := btn.find_child("PanelLimit", true, false) as Control
	if panel == null:
		return
	panel.visible = limited
	var label := panel.get_node_or_null("Label") as Label
	if label != null:
		label.text = str(maxi(left, 0))
