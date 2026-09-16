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

@onready var logo: TextureRect = $Panel/Logo
@onready var btn_play: TextureButton = $Panel/GameMode/Play
@onready var btn_dungeon: TextureButton = $Panel/GameMode/Dungeon
@onready var btn_daily: TextureButton = $Panel/GameMode/DailyChallenge

@onready var btn_leaderboard: TextureButton = $Panel/Other/Leaderboard
@onready var btn_shop: TextureButton = $Panel/Other/Shop
@onready var btn_settings: TextureButton = $Panel/Other/Settings
@onready var btn_archivement: TextureButton = $Panel/Archivement
@onready var badge_count_label: Label = $Panel/Archivement/Count
@onready var badge_play: Label = $Panel/GameMode/Play/Badge
@onready var badge_dungeon: Label = $Panel/GameMode/Dungeon/Badge
@onready var badge_daily: Label = $Panel/GameMode/DailyChallenge/Badge
@onready var stamp_panel: Control = $Panel/Stamp
@onready var stamp_label: Label = $Panel/Stamp/Label


func _ready() -> void:
	_refresh_stamp()
	_refresh_badge()
	_refresh_mode_badges()
	_setup_buttons()
	_setup_animations()


func _setup_buttons() -> void:
	if btn_play != null:
		btn_play.pressed.connect(_on_play_pressed)
		UIAnim.attach_press_bounce(btn_play)
	if btn_dungeon != null:
		btn_dungeon.pressed.connect(_on_dungeon_pressed)
		UIAnim.attach_press_bounce(btn_dungeon)
	if btn_daily != null:
		btn_daily.pressed.connect(_on_daily_pressed)
		UIAnim.attach_press_bounce(btn_daily)

	if btn_leaderboard != null:
		btn_leaderboard.pressed.connect(_on_leaderboard_pressed)
		UIAnim.attach_press_bounce(btn_leaderboard)
	if btn_shop != null:
		btn_shop.pressed.connect(_on_shop_pressed)
		UIAnim.attach_press_bounce(btn_shop)
	if btn_settings != null:
		btn_settings.pressed.connect(_on_settings_pressed)
		UIAnim.attach_press_bounce(btn_settings)
	if btn_archivement != null:
		btn_archivement.pressed.connect(_on_archivement_pressed)
		UIAnim.attach_press_bounce(btn_archivement)


func _setup_animations() -> void:
	# 1. Logo bồng bềnh nhẹ
	if logo != null:
		UIAnim.play_float_idle(logo, 5.0, 2.6)

	# 2. Khung GameMode trượt nhẹ từ dưới lên + các thẻ con fade-in so le
	var game_mode_box := get_node_or_null("Panel/GameMode") as Control
	if game_mode_box != null:
		UIAnim.play_slide_in(game_mode_box, Vector2(0, 25), 0.0, 0.28)

	var cards: Array[Control] = []
	if btn_play != null: cards.append(btn_play)
	if btn_dungeon != null: cards.append(btn_dungeon)
	if btn_daily != null: cards.append(btn_daily)

	for i in cards.size():
		UIAnim.play_fade_in(cards[i], 0.06 * i, 0.24)

	# 3. Khung nút chức năng Other trượt nhẹ từ dưới lên + các nút con fade-in so le
	var other_box := get_node_or_null("Panel/Other") as Control
	if other_box != null:
		UIAnim.play_slide_in(other_box, Vector2(0, 18), 0.12, 0.25)

	var others: Array[Control] = []
	if btn_leaderboard != null: others.append(btn_leaderboard)
	if btn_shop != null: others.append(btn_shop)
	if btn_settings != null: others.append(btn_settings)

	for i in others.size():
		UIAnim.play_fade_in(others[i], 0.14 + 0.05 * i, 0.22)

	# 3b. Nút Sổ tay thành tựu ở góc trên phải tờ giấy: nảy nhẹ khi mở màn
	if btn_archivement != null:
		UIAnim.play_pop_in(btn_archivement, 0.08, 0.9, 0.28)

	# 4. Con dấu phiên bản nảy nhẹ
	if stamp_panel != null:
		UIAnim.play_pop_in(stamp_panel, 0.2, 0.85, 0.25)


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


func _on_leaderboard_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	Nav.goto_ranking()


func _on_shop_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	Nav.goto_shop()


func _refresh_stamp() -> void:
	if stamp_label == null:
		return
	var app := get_node_or_null("/root/AppManager")
	var version := "1.0.0"
	if app != null:
		version = str(app.call("get_version"))
	stamp_label.text = tr("STR_SETTINGS_VERSION").format([version])


## Số danh hiệu đã đạt / tổng số danh hiệu — in ngay trên huy chương
func _refresh_badge() -> void:
	if badge_count_label == null:
		return
	badge_count_label.text = "%d/%d" % [Archivement.unlocked_count(), Archivement.total_count()]


## 3 huy hiệu trên thẻ chế độ: Màn hiện tại · Kỷ lục tầng Dungeon · Chuỗi ngày Daily.
## Chuỗi dịch chứa "{0}" nên phải điền số lúc chạy (Label chỉ tự dịch phần chữ).
func _refresh_mode_badges() -> void:
	var gm := get_node_or_null("/root/GameManager")
	var level := 1
	if gm != null:
		level = maxi(int(gm.get("current_level")), 1)
	if badge_play != null:
		badge_play.text = tr("STR_CURRENT_LEVEL_BADGE").format([level])

	if badge_dungeon != null:
		var floor := Archivement.stat_value("dungeon_best_floor")
		badge_dungeon.text = tr("STR_RECORD_FLOOR_BADGE").format([floor])

	var dm := get_node_or_null("/root/DailyManager")
	var streak := 0
	if dm != null and dm.has_method("get_streak"):
		streak = int(dm.call("get_streak"))
	if badge_daily != null:
		badge_daily.text = tr("STR_STREAK_BADGE").format([streak])
