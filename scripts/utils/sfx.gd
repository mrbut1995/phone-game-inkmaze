class_name Sfx
extends RefCounted
## ============================================================================
## Helper tĩnh: gọi SFX qua autoload SfxManager.
##
## Vì sao không gọi thẳng `SfxManager.play(...)` trong các script khác?
##   Test runner của dự án chạy bằng `godot --script ...`. Ở chế độ này,
##   identifier của autoload KHÔNG resolve được lúc parse => script nào tham
##   chiếu thẳng tên autoload sẽ lỗi parse. Vì vậy mọi nơi chỉ tham chiếu
##   class `Sfx` này; node autoload được lấy động qua /root/SfxManager
##   (đúng pattern `get_node_or_null` mà các manager khác đang dùng).
##
## Danh mục SFX + tình huống kích hoạt: xem `sfx_suggestion.txt` ở thư mục gốc.
## ============================================================================

# --- Tên SFX -----------------------------------------------------------------
const PATH_DRAW := "path_draw"          # Ngòi chì miết trên giấy (kéo vẽ đường)
const CELL_STEP := "cell_step"          # Chấm bút chì khi vào tâm 1 ô mới
const ANCHOR_SNAP := "anchor_snap"      # "Tách" cơ học khi rê trúng điểm neo
const WALL_MARK := "wall_mark"          # Nét chì dứt khoát khi vẽ tường nghi ngờ
const WALL_HIT := "wall_hit"            # Gãy ngòi chì khi đâm tường vô hình
const UNDO := "undo"                    # Gôm tẩy quẹt trên giấy
const HINT := "hint"                    # Chuông gió khi bấm Gợi ý
const STAIRS_ENTER := "stairs_enter"    # Bước chân / lật giấy khi vào ô S - F
const BTN_CLICK := "btn_click"          # Bấm bút bi (nút chính)
const BTN_WOOD_TAP := "btn_wood_tap"    # Gõ thẻ giấy (nút phụ)
const PAGE_TURN := "page_turn"          # Lật trang khi chuyển màn hình
const DAY_SWITCH := "day_switch"        # Miết mép giấy khi chuyển ngày Daily
const SLIDER_TICK := "slider_tick"      # Thước kẻ trượt (slider âm lượng)
const CHECKBOX := "checkbox"            # Bút bi vẽ dấu tích
const STAMP_IMPACT := "stamp_impact"    # "Cộp" con dấu đóng lên giấy
const STAR_POP := "star_pop"            # Chuông gỗ reo (3 ngôi sao)
const LEVEL_WIN := "level_win"          # Jingle thắng màn
const GAME_OVER := "game_over"          # Vo giấy nháp (thua cuộc)
const FLOOR_BONUS := "floor_bonus"      # Thưởng +Bước ở Dungeon Mode
const ACHIEVEMENT := "achievement"      # Thành tích (ví dụ: floor hoàn hảo)

## sfx_name -> tên file trong res://assets/sfx/
const LIBRARY := {
	"path_draw": "sfx_path_draw.wav",
	"cell_step": "sfx_cell_step.wav",
	"anchor_snap": "sfx_anchor_snap.wav",
	"wall_mark": "sfx_wall_mark.wav",
	"wall_hit": "sfx_wall_hit.wav",
	"undo": "sfx_undo.mp3",
	"hint": "sfx_hint.wav",
	"stairs_enter": "sfx_stairs_enter.wav",
	"btn_click": "sfx_btn_click.wav",
	"btn_wood_tap": "sfx_btn_wood_tap.wav",
	"page_turn": "sfx_page_turn.wav",
	"day_switch": "sfx_day_switch.wav",
	"slider_tick": "sfx_slider_tick.wav",
	"checkbox": "sfx_checkbox.wav",
	"stamp_impact": "sfx_stamp_impact.wav",
	"star_pop": "sfx_star_pop.wav",
	"level_win": "sfx_level_win.wav",
	"game_over": "sfx_game_over.wav",
	"floor_bonus": "sfx_floor_bonus.wav",
	"achievement": "sfx_achivement.wav",
}

const SOUND_DIR := "res://assets/sfx/"
const DEFAULT_PITCH_JITTER := 0.08


# ---------------------------------------------------------------------------
# API tĩnh cho mọi script gọi: Sfx.play(Sfx.BTN_CLICK)
# ---------------------------------------------------------------------------
static func play(sfx_name: String, jitter := DEFAULT_PITCH_JITTER, volume_db := 0.0, pitch := 1.0) -> void:
	var manager := _manager()
	if manager != null:
		manager.call("play", sfx_name, jitter, volume_db, pitch)


## Nút bấm UI: nút chính = bút bi (click), nút phụ = gõ thẻ giấy (thud)
static func ui_click(secondary := false) -> void:
	play(BTN_WOOD_TAP if secondary else BTN_CLICK, 0.04)


## Ngôi sao thứ `index` (0..2) reo theo quãng Đồ - Mi - Son
static func star_pop(index: int) -> void:
	var manager := _manager()
	if manager != null:
		manager.call("star_pop", index)


## Phát âm lặp liên tục (tiếng miết bút khi đang kéo vẽ đường đi)
static func play_loop(sfx_name: String, volume_db := -5.0) -> void:
	var manager := _manager()
	if manager != null:
		manager.call("play_loop", sfx_name, volume_db)


static func stop_loop(sfx_name: String) -> void:
	var manager := _manager()
	if manager != null:
		manager.call("stop_loop", sfx_name)


static func _manager() -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		var tree := main_loop as SceneTree
		if tree.root != null:
			return tree.root.get_node_or_null("SfxManager")
	return null
