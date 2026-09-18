class_name HintGuide
extends Control
## ============================================================================
## Panel "HƯỚNG DẪN LUẬT CHƠI TÓM TẮT" nằm dưới bàn cờ (mockup/matchup_*.svg — mục 6).
##
## Hiện ĐÚNG 1 dòng nhắc luật của chế độ đang chơi; GameScene gọi `show_mode()` mỗi
## lần đổi chế độ. Khoá dịch: `STR_HINT_<MODE_ID>` (resources/localization/string_extra.csv);
## chế độ nào chưa có khoá thì dùng `BaseGameMode.mode_description`.
## ============================================================================

const HINT_KEYS := {
	"play": "STR_HINT_PLAY",
	"dungeon": "STR_HINT_DUNGEON",
	"minesweeper": "STR_HINT_MINESWEEPER",
	"blind_memory": "STR_HINT_BLIND_MEMORY",
	"fog_of_war": "STR_HINT_FOG_OF_WAR",
	"sum_path": "STR_HINT_SUM_PATH",
	"countdown_cost": "STR_HINT_COUNTDOWN_COST",
	"fading_ink": "STR_HINT_FADING_INK",
	"one_stroke": "STR_HINT_ONE_STROKE",
	"wall_builder": "STR_HINT_WALL_BUILDER",
}


## Đổi nội dung gợi ý theo chế độ đang chơi
func show_mode(mode: BaseGameMode) -> void:
	if mode == null:
		return
	var key: String = str(HINT_KEYS.get(mode.mode_id, ""))
	if key.is_empty():
		show_text(mode.mode_description)
	else:
		show_text(tr(key))


func show_text(text: String) -> void:
	if text.is_empty():
		return
	var label := get_node_or_null("Text") as Label
	if label != null and label.text != text:
		label.text = text


## Nội dung đang hiển thị (test)
func current_text() -> String:
	var label := get_node_or_null("Text") as Label
	return label.text if label != null else ""
