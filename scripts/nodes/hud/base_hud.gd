class_name BaseHUD
extends Control
## ============================================================================
## Base: HUD của màn chơi — API CHUNG của MỌI HUD (nodes/hud/base.tscn gắn script này).
##
## Ai đang giữ HUD (GameScene · UIController · test) chỉ cần biết lớp này:
##   · Đồng hồ ván             : `update_hud(ctx)` · `set_time()`
##   · Thanh nút hành động     : `action_bar()` · `restart_btn()` · `submit_btn()` · `skip_btn()`
##                               · `undo_btn()` · `hint_btn()`
##   · Thẻ THỬ THÁCH           : `challenge_card()` (HUD không xài thì trả null)
##   · Khung Hướng dẫn         : `hint_guide()`
##   · Nhường input cho bàn cờ : `allow_board_input()`
##
## HUD con KHÔNG cần lộ node con ra ngoài: muốn thêm nút/thẻ mới thì thêm 1 method ở đây
## (hoặc ở `GameHUD`) rồi để HUD tự lấy node con của mình — bên ngoài chỉ gọi method.
## ============================================================================

## ---------------------------------------------------------------------------
## NODE CON — SCENE TỰ BIND qua `@export` (script KHÔNG dò đường dẫn "A/B/C")
## ---------------------------------------------------------------------------
## Label đồng hồ ván (`Content/ModeInformation/Time/Value`)
@export var time_value_node : Label
## Khối nội dung HUD (`Content`) — cần để NHƯỜNG input cho bàn cờ
@export var content_root : Control
## Thanh nút hành động (`Content/ActionBar`) — mỗi HUD instance 1 thanh riêng
@export var action_bar_node : ActionBar


## Gọi mỗi khi HUD cần vẽ lại (GameController._update_hud). ctx gồm:
##   title:String · subtitle:String · steps_remaining:int · elapsed_time:float
##   floor_number:int · extra:String · mode:BaseGameMode
##   undo_left/undo_max · hint_left/hint_max :int — giới hạn lượt Hoàn tác/Gợi ý của màn
func update_hud(ctx: Dictionary) -> void:
	set_time(float(ctx.get("elapsed_time", 0.0)))
	_sync_limits(ctx)
	_sync_instruction(ctx.get("mode"))
	_on_update(ctx)


## HUD con override để vẽ các thẻ riêng của chế độ mình
func _on_update(_ctx: Dictionary) -> void:
	pass


## HUD con CÓ khung hướng dẫn nhúng (bản NGANG) thì override — xem `GameHUD._sync_instruction`
func _sync_instruction(_mode: Variant) -> void:
	pass


## Thẻ THỬ THÁCH nếu HUD có (chỉ HUD của các chế độ dùng hệ thống Thử thách) —
## `ChallengeController` gọi hàm này rồi chỉ đưa TRẠNG THÁI vào `ChallengeCard.refresh()`.
func challenge_card() -> ChallengeCard:
	return null


## ---------------------------------------------------------------------------
## Đồng hồ ván
## ---------------------------------------------------------------------------
## Giây -> "m:ss"
func set_time(seconds: float) -> void:
	set_label_text(time_value_node, format_time(seconds))


## Gán text cho Label (bỏ qua nếu trùng -> không redraw mỗi frame)
func set_label_text(node: Node, text: String) -> void:
	var label := node as Label
	if label != null and label.text != text:
		label.text = text


static func format_time(seconds: float) -> String:
	var total := maxi(int(seconds), 0)
	return "%d:%02d" % [total / 60, total % 60]


## ---------------------------------------------------------------------------
## THANH NÚT HÀNH ĐỘNG (phương án A): mỗi HUD đều instance `nodes/hud/action_bar.tscn`
## ngay trong scene của mình ⇒ nút CHƠI LẠI/GỬI BÀI/UNDO/HINT/REPLAY nằm TRONG HUD,
## màn chơi chỉ việc lấy ra để nối tín hiệu (không còn nút nào trong game.tscn).
## ---------------------------------------------------------------------------
func action_bar() -> ActionBar:
	return action_bar_node


## Giới hạn lượt Gợi ý/Hoàn tác (GameController tính) → badge `PanelLimit` + khoá nút khi hết lượt
func _sync_limits(ctx: Dictionary) -> void:
	var bar := action_bar()
	if bar != null:
		bar.update_limits(
			int(ctx.get("undo_left", 0)), int(ctx.get("undo_max", 0)),
			int(ctx.get("hint_left", 0)), int(ctx.get("hint_max", 0)))


## Bật bố cục NGANG cho thanh nút (dọc/ngang mỗi hướng 1 scene action_bar riêng)
func set_landscape(on: bool) -> void:
	var bar := action_bar()
	if bar != null:
		bar.set_landscape(on)


func restart_btn() -> BaseButton:
	var bar := action_bar()
	return bar.restart_btn() if bar != null else null


## Nút GỬI BÀI của Wall Builder (các chế độ khác ẩn)
func submit_btn() -> BaseButton:
	var bar := action_bar()
	return bar.submit_btn() if bar != null else null


## Nút SKIP LEVEL (chỉ hiện khi chơi MÀN trong màn Chọn màn)
func skip_btn() -> BaseButton:
	var bar := action_bar()
	return bar.skip_btn() if bar != null else null


func undo_btn() -> BaseButton:
	var bar := action_bar()
	return bar.undo_btn() if bar != null else null


func hint_btn() -> BaseButton:
	var bar := action_bar()
	return bar.hint_btn() if bar != null else null


## ---------------------------------------------------------------------------
## Nhường input + khung Hướng dẫn (bên ngoài KHÔNG tự lấy node con của HUD)
## ---------------------------------------------------------------------------
## HUD phủ toàn khung (để dễ căn vị trí) nên nằm TRÊN bàn cờ ⇒ phải NHƯỜNG chạm/kéo cho bàn cờ.
## Chỉ khung HUD + khối `Content` là IGNORE — các NÚT BÊN TRONG (ActionBar, Status…) vẫn ăn input.
func allow_board_input() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if content_root != null:
		content_root.mouse_filter = Control.MOUSE_FILTER_IGNORE


## Khung Hướng dẫn (HintGuide) — mỗi hướng khai một chỗ khác nhau (bản NGANG: `Content/HintGuide`;
## bản DỌC: `Content/ActionBar/HintGuide`) nên tra theo TÊN trong chính HUD này.
## Bên ngoài (GameScene) luôn hỏi hàm này — HUD đổi theo chế độ nên không cache node.
func hint_guide() -> HintGuide:
	return find_child("HintGuide", true, false) as HintGuide
