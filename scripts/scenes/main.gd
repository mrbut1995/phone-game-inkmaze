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


func _ready() -> void:
	if btn_play != null:
		btn_play.pressed.connect(_on_play_pressed)
	if btn_dungeon != null:
		btn_dungeon.pressed.connect(_on_dungeon_pressed)
	if btn_daily != null:
		btn_daily.pressed.connect(_on_daily_pressed)

	if btn_settings != null:
		btn_settings.pressed.connect(_on_settings_pressed)


func _on_play_pressed() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("go_to_levels"):
		gm.go_to_levels()
	else:
		get_tree().change_scene_to_file("res://scenes/levels.tscn")


func _on_dungeon_pressed() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("start_dungeon"):
		gm.start_dungeon()
	else:
		get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_daily_pressed() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("go_to_daily"):
		gm.go_to_daily()
	else:
		get_tree().change_scene_to_file("res://scenes/daily.tscn")


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")
