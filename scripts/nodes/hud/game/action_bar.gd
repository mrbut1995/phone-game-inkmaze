class_name ActionBar
extends Control
## ============================================================================
## Thanh nút hành động của màn chơi (CHƠI LẠI · GỬI BÀI · HOÀN TÁC · GỢI Ý · CHƠI LẠI-ván)
## — nằm TRONG HUD của mỗi chế độ. MỖI HƯỚNG MÀN HÌNH CÓ 1 SCENE RIÊNG (không di chuyển node lúc chạy):
##   · `nodes/hud/portrait/game/action_bar.tscn`  — 1 hàng ngang: `Row`
##
## Nút VẼ ĐƯỜNG / GHI NHỚ (Tool · Wall) đã BỎ (2026-09-26): bàn cờ tự nhận cả 2 thao tác (kéo nhân
## vật đi đường · kéo nối 2 Anchor để đánh dấu tường) nên thanh nút chỉ còn thao tác thật:
##   · `Restart` — CHƠI LẠI màn/tầng (DỜI từ thanh trạng thái xuống đây — có ở MỌI chế độ)
##   · `Submit`  — GỬI BÀI (chỉ Wall Builder; GameScene tự bật/tắt theo chế độ)
##   · `Undo` / `Hint` — kèm `PanelLimit` (badge nhỏ đè góc nút) hiện SỐ LƯỢT CÒN LẠI
##   · `Replay` — nút phụ ẩn sẵn, UIController hiện khi ván không còn thắng được (Sum Path)
##
## HUD bản dọc = `nodes/hud/<mode>.tscn` (kế thừa `portrait/portrait.tscn`)
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


## Nút SKIP LEVEL — CHỈ hiện khi đang chơi MÀN trong màn Chọn màn (GameScene tự bật/tắt)
func skip_btn() -> BaseButton:
	return button("Skip")

func undo_btn() -> LimitedButton:
	return button("Undo") as LimitedButton


func hint_btn() -> LimitedButton:
	return button("Hint") as LimitedButton

#func replay_btn() -> BaseButton:
	#return button("Restart")


## Cập nhật badge giới hạn + trạng thái KHOÁ của 2 nút — mỗi nút tự lo badge của mình
## (`LimitedButton.set_limit`), thanh nút không với tay vào node con của nút.
func update_limits(undo_left: int, undo_max: int, hint_left: int, hint_max: int) -> void:
	var undo := undo_btn()
	if undo != null:
		undo.set_limit(undo_left, undo_max)
	var hint := hint_btn()
	if hint != null:
		hint.set_limit(hint_left, hint_max)
