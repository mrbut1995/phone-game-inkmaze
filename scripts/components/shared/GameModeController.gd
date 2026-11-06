class_name GameModeController
extends Node
## ============================================================================
## Controller: Quản lý và chuyển đổi chiến lược chế độ chơi (GameMode Strategy).
## Các chế độ còn lại: Play · Challenge · Daily · Dungeon · Blind Memory · Wall Builder.
## ============================================================================

signal mode_changed(new_mode: BaseGameMode)

@export var game_mode: BaseGameMode = null


func _init() -> void:
	if game_mode == null:
		game_mode = DungeonGameMode.new()


## Thiết lập GameMode trực tiếp
func set_game_mode(p_mode: BaseGameMode) -> void:
	game_mode = p_mode
	mode_changed.emit(game_mode)


## Chuyển đổi GameMode theo tên chế độ (name) và độ khó
func set_mode_by_name(mode_name: String, difficulty: String = "medium") -> BaseGameMode:
	var new_mode: BaseGameMode = null
	match mode_name.to_lower():
		"play", "classic", "standard":
			new_mode = StandardGameMode.new(difficulty)
		"challenge":
			new_mode = ChallengeGameMode.new(difficulty)
		"daily_classic":
			new_mode = DailyClassicGameMode.new(difficulty)
		"daily_challenge":
			new_mode = DailyChallengeGameMode.new(difficulty)
		"dungeon":
			new_mode = DungeonGameMode.new()
		"blind_memory":
			new_mode = BlindMemoryGameMode.new(difficulty)
		"wall_builder":
			new_mode = WallBuilderGameMode.new(difficulty)
		_:
			new_mode = DungeonGameMode.new()

	set_game_mode(new_mode)
	return new_mode
