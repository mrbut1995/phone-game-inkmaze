class_name MainScene
extends BaseScene
## ============================================================================
## View Controller: Màn hình chính (Main Screen)
## Quản lý 3 cổng chơi chính:
##   1. Play (Chọn Màn) -> Chuyển sang scenes/levels.tscn
##   2. Dungeon Mode    -> Bắt đầu ngay chế độ vô tận trong scenes/game.tscn
##   3. Daily Challenge -> Chuyển sang scenes/daily.tscn
## ============================================================================

@onready var btn_play: TextureButton = $Panel/GameMode/Play
@onready var btn_dungeon: TextureButton = $Panel/GameMode/Dungeon
@onready var btn_daily: TextureButton = $Panel/GameMode/DailyChallenge

@onready var btn_leaderboard: TextureButton = $Panel/Other/Leaderboard
@onready var btn_rules: TextureButton = $Panel/Other/Rule
@onready var btn_settings: TextureButton = $Panel/Other/Settings
@onready var stamp_label: Label = $Panel/Stamp/Label


func _ready() -> void:
	_refresh_stamp()
	if btn_play != null:
		btn_play.pressed.connect(_on_play_pressed)
	if btn_dungeon != null:
		btn_dungeon.pressed.connect(_on_dungeon_pressed)
	if btn_daily != null:
		btn_daily.pressed.connect(_on_daily_pressed)

	if btn_settings != null:
		btn_settings.pressed.connect(_on_settings_pressed)


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
