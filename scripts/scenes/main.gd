class_name MainScene
extends BaseScene
## ============================================================================
## View Controller: Màn hình chính (Main Screen)
## Quản lý 3 cổng chơi chính:
##   1. Play (Chọn Màn) -> Chuyển sang scenes/levels.tscn
##   2. Dungeon Mode    -> Bắt đầu ngay chế độ vô tận trong scenes/game.tscn
##   3. Daily Challenge -> Chuyển sang scenes/daily.tscn
## ============================================================================
const UIAnim := preload("res://scripts/utils/ui_anim.gd")

## Node UI của màn nằm trong BỐ CỤC đang hiển thị (`Portrait` / `Landscape` — 2 hướng dùng
## CÙNG tên node). Các node đã BIND SẴN bằng `@export` trong `scenes/layout/<hướng>/main.tscn`
## ⇒ code đọc qua `layout.<tên>`, KHÔNG tra đường dẫn; thêm/đổi node chỉ cần sửa scene + export.
var layout: MainLayout = null


func _ready() -> void:
	_bind_layout()
	_refresh_stamp()
	_refresh_badge()
	_refresh_mode_badges()
	_refresh_profile()
	_connect_profile_manager()
	_setup_buttons()
	_setup_animations()
	orientation_changed.connect(_on_orientation_changed)


## Gắn lại toàn bộ node UI theo layout ĐANG HIỂN THỊ (dọc ⇄ ngang)
func _bind_layout() -> void:
	layout = active_layout() as MainLayout
	if layout == null:
		push_warning("main: bố cục chưa gắn MainLayout — thiếu binding trong scenes/layout/<hướng>/main.tscn")


## Xoay màn hình: gắn lại node của layout mới rồi chạy lại hiệu ứng
func _on_orientation_changed(_is_landscape_now: bool) -> void:
	_bind_layout()
	_refresh_stamp()
	_refresh_badge()
	_refresh_mode_badges()
	_refresh_profile()
	_setup_buttons()
	_setup_animations()


## Dây NÚT khai trong `scenes/main.tscn` (cả Portrait lẫn Landscape) — guard dưới chỉ nối lại
## nếu dây bị mất (xoay màn hình gắn lại node của layout mới nên hàm này chạy lại được).
func _connect_pressed(button: BaseButton, handler: Callable) -> void:
	if button == null:
		return
	ensure_signal(button, &"pressed", handler.get_method())
	UIAnim.attach_press_bounce(button)


func _setup_buttons() -> void:
	_connect_pressed(layout.btn_play, _on_play_pressed)
	_connect_pressed(layout.btn_dungeon, _on_dungeon_pressed)
	_connect_pressed(layout.btn_daily, _on_daily_pressed)
	_connect_pressed(layout.btn_leaderboard, _on_leaderboard_pressed)
	_connect_pressed(layout.btn_shop, _on_shop_pressed)
	_connect_pressed(layout.btn_settings, _on_settings_pressed)
	_connect_pressed(layout.btn_archivement, _on_archivement_pressed)
	_connect_pressed(layout.btn_profile, _on_profile_pressed)


func _setup_animations() -> void:
	# 1. Logo bồng bềnh nhẹ
	# (GIỮ tween) Logo nằm TRONG VBoxContainer — vị trí do container dàn nên không khai
	# được track tĩnh (offset/scale không thay được vị trí do container quản lý).
	if layout.logo != null:
		UIAnim.play_float_idle(layout.logo, 5.0, 2.6)

	# 2. Khung GameMode (dọc) / Menu (ngang) trượt nhẹ từ dưới lên + các thẻ con fade-in so le
	if layout.game_mode_box != null:
		UIAnim.play_slide_in(layout.game_mode_box, Vector2(0, 25), 0.0, 0.28)

	var cards: Array[Control] = []
	if layout.btn_play != null: cards.append(layout.btn_play)
	if layout.btn_dungeon != null: cards.append(layout.btn_dungeon)
	if layout.btn_daily != null: cards.append(layout.btn_daily)

	for i in cards.size():
		UIAnim.play_fade_in(cards[i], 0.06 * i, 0.24)

	# 3. Khung nút chức năng Other (dọc) / Utils (ngang) trượt nhẹ + các nút con fade-in so le
	if layout.other_box != null:
		UIAnim.play_slide_in(layout.other_box, Vector2(0, 18), 0.12, 0.25)

	var others: Array[Control] = []
	if layout.btn_leaderboard != null: others.append(layout.btn_leaderboard)
	if layout.btn_shop != null: others.append(layout.btn_shop)
	if layout.btn_settings != null: others.append(layout.btn_settings)

	for i in others.size():
		UIAnim.play_fade_in(others[i], 0.14 + 0.05 * i, 0.22)

	# 3b. Nút Sổ tay thành tựu ở góc trên phải tờ giấy: nảy nhẹ khi mở màn
	if layout.btn_archivement != null:
		UIAnim.play_pop_in(layout.btn_archivement, 0.08, 0.9, 0.28)

	# 3c. Sticker HỒ SƠ ở góc trên trái: nảy nhẹ như sticker Danh hiệu
	if layout.btn_profile != null:
		UIAnim.play_pop_in(layout.btn_profile, 0.1, 0.9, 0.28)

	# 4. Con dấu phiên bản nảy nhẹ
	if layout.stamp_panel != null:
		UIAnim.play_pop_in(layout.stamp_panel, 0.2, 0.85, 0.25)


func _on_play_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	# Luồng chơi: Main -> CHỌN MÀN (vào thẳng); muốn đổi chương thì bấm banner trong màn Chọn màn
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("go_to_levels"):
		gm.go_to_levels()
	else:
		Nav.goto_levels()


func _on_dungeon_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("start_dungeon"):
		gm.start_dungeon()
	else:
		Nav.goto_game()


func _on_daily_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("go_to_daily"):
		gm.go_to_daily()
	else:
		Nav.goto_daily()


func _on_settings_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	Nav.goto_settings()


func _on_archivement_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	Nav.goto_archivement()


## Sticker HỒ SƠ (avatar góc trên trái) mở POPUP hồ sơ cá nhân (không đổi màn hình)
func _on_profile_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	Popups.open(Popups.PROFILER)


func _on_leaderboard_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	Nav.goto_ranking()


func _on_shop_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	Nav.goto_shop()


func _refresh_stamp() -> void:
	if layout.stamp_label == null:
		return
	var app := get_node_or_null("/root/AppManager")
	var version := "1.0.0"
	if app != null:
		version = str(app.call("get_version"))
	layout.stamp_label.text = tr("STR_SETTINGS_VERSION").format([version])


## Số danh hiệu đã đạt / tổng số danh hiệu — in ngay trên huy chương
func _refresh_badge() -> void:
	if layout.badge_count_label == null:
		return
	layout.badge_count_label.text = "%d/%d" % [Archivement.unlocked_count(), Archivement.total_count()]


## 3 huy hiệu trên thẻ chế độ: Màn hiện tại · Kỷ lục tầng Dungeon · Chuỗi ngày Daily.
## Chuỗi dịch chứa "{0}" nên phải điền số lúc chạy (Label chỉ tự dịch phần chữ).
func _refresh_mode_badges() -> void:
	var gm := get_node_or_null("/root/GameManager")
	var level := 1
	if gm != null:
		level = maxi(int(gm.get("current_level")), 1)
	if layout.badge_play != null:
		layout.badge_play.text = tr("STR_CURRENT_LEVEL_BADGE").format([level])

	if layout.badge_dungeon != null:
		var floor := Archivement.stat_value("dungeon_best_floor")
		layout.badge_dungeon.text = tr("STR_RECORD_FLOOR_BADGE").format([floor])

	var dm := get_node_or_null("/root/DailyManager")
	var streak := 0
	if dm != null and dm.has_method("get_streak"):
		streak = int(dm.call("get_streak"))
	if layout.badge_daily != null:
		layout.badge_daily.text = tr("STR_STREAK_BADGE").format([streak])


## Sticker HỒ SƠ: avatar + viền khung + cấp độ (layout NGANG còn có tên người chơi)
func _refresh_profile() -> void:
	if layout.profile_avatar != null:
		layout.profile_avatar.texture = load(Profile.avatar_icon(Profile.avatar_id())) as Texture2D
	if layout.profile_frame != null:
		layout.profile_frame.texture = load(Profile.frame_icon(Profile.frame_id())) as Texture2D
	if layout.profile_level != null:
		layout.profile_level.text = tr("STR_PROFILE_LEVEL_FORMAT").format([Profile.level()])
	if layout.profile_name != null:
		layout.profile_name.text = Profile.display_name()


## Hồ sơ đổi (đổi avatar/viền/tên ở popup) -> sticker trên màn chính cập nhật theo
func _connect_profile_manager() -> void:
	var m := Profile.manager()
	if m != null and m.has_signal("profile_changed") and not m.is_connected("profile_changed", _refresh_profile):
		m.connect("profile_changed", _refresh_profile)
