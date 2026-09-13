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
@onready var btn_rules: TextureButton = $Panel/Other/Rule
@onready var btn_settings: TextureButton = $Panel/Other/Settings
@onready var stamp_panel: Control = $Panel/Stamp
@onready var stamp_label: Label = $Panel/Stamp/Label


func _ready() -> void:
	_refresh_stamp()
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

	if btn_settings != null:
		btn_settings.pressed.connect(_on_settings_pressed)
		UIAnim.attach_press_bounce(btn_settings)
	if btn_leaderboard != null:
		UIAnim.attach_press_bounce(btn_leaderboard)
	if btn_rules != null:
		UIAnim.attach_press_bounce(btn_rules)


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
	if btn_rules != null: others.append(btn_rules)
	if btn_settings != null: others.append(btn_settings)

	for i in others.size():
		UIAnim.play_fade_in(others[i], 0.14 + 0.05 * i, 0.22)

	# 4. Con dấu phiên bản nảy nhẹ
	if stamp_panel != null:
		UIAnim.play_pop_in(stamp_panel, 0.2, 0.85, 0.25)


func _on_play_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
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


## Con dau phien ban: "VER x.y.z" (lay tu AppManager, dung String key)
func _refresh_stamp() -> void:
	if stamp_label == null:
		return
	var app := get_node_or_null("/root/AppManager")
	var version := "1.0.0"
	if app != null:
		version = str(app.call("get_version"))
	stamp_label.text = tr("STR_SETTINGS_VERSION").format([version])
