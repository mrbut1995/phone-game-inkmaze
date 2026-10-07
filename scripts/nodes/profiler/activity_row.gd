class_name ProfilerActivityRow
extends Control
## ============================================================================
## Hàng "hoạt động gần đây" của màn HỒ SƠ (nodes/profiler/activity_row.tscn)
##
## Mockup profiler.svg — mỗi hàng: vòng icon · tiêu đề · dòng phụ · nhãn kết quả.
## Node tĩnh khai trong .tscn; ở đây chỉ đổ DỮ LIỆU + MÀU theo từng ván.
##
## Câu chữ dựng từ khoá dịch (STR_PROFILE_ACT_*) — xem `set_row`.
## ============================================================================

## Màu nhãn kết quả theo loại (giống mockup: vàng sao · đỏ điểm · xanh hoàn thành)
const COLOR_GOLD := Color(0.7098, 0.3529, 0.0353)     # #B45309
const COLOR_RED := Color(0.8627, 0.1490, 0.1490)      # #DC2626
const COLOR_GREEN := Color(0.0863, 0.6392, 0.2902)    # #16A34A
const COLOR_MUTED := Color(0.4431, 0.5451, 0.6196)    # #718B9E

## Nền NHẠT theo loại dòng (mockup: vòng icon + chip kết quả đều có nền pastel)
const BG_GOLD := Color(0.9961, 0.9529, 0.7804)      # #FEF3C7
const BG_RED := Color(0.9961, 0.8863, 0.8863)       # #FEE2E2
const BG_GREEN := Color(0.8627, 0.9882, 0.9020)     # #DCFCE7
const BG_MUTED := Color(0.9451, 0.9608, 0.9725)     # #F1F5F9
const DISC_PLAY := Color(0.9373, 0.9647, 1.0)       # #EFF6FF
const DISC_DUNGEON := Color(0.9961, 0.9490, 0.9490) # #FEF2F2
const DISC_DAILY := Color(0.9412, 0.9922, 0.9569)   # #F0FDF4

@onready var _disc: TextureRect = $Disc
@onready var _icon: TextureRect = $Disc/Icon
@onready var _title: Label = $Title
@onready var _sub: Label = $Sub
@onready var _tag: Label = $Tag


## Nạp 1 dòng lịch sử (dict thô từ PlayerProfileManager.record_run)
func set_row(row: Dictionary) -> void:
	var won := bool(row.get("won", false))
	var endless := bool(row.get("endless", false))
	var daily := bool(row.get("daily", false))
	var mode_id := str(row.get("mode_id", ""))
	var floor_id := int(row.get("floor", 1))
	var width := int(row.get("width", 0))
	var height := int(row.get("height", 0))

	_title.text = _title_text(endless, daily, mode_id, floor_id, width, height)
	_sub.text = _sub_text(row, endless, daily)
	_set_tag(_tag_text(row, won, endless, daily), _tag_color(won, endless, daily), _tag_bg(won, endless, daily))

	# Icon + màu vòng theo chế độ (dùng lại art có sẵn của màn chính / profiler)
	var icon_path := "res://assets/images-png/icons/icon_target.png"
	var tint := Color(0.1451, 0.4235, 0.5882)          # #256C96
	var disc_color := DISC_PLAY
	if endless:
		icon_path = "res://assets/images-png/icons/icon_castle.png"
		tint = Color(0.8471, 0.2667, 0.2667)           # #D84444
		disc_color = DISC_DUNGEON
	elif daily:
		icon_path = "res://assets/images-png/icons/icon_calendar.png"
		tint = Color(0.8510, 0.4667, 0.0235)           # #D97706
		disc_color = DISC_DAILY
	if _icon != null:
		_icon.texture = load(icon_path) as Texture2D
		_icon.self_modulate = tint
	if _disc != null:
		_disc.self_modulate = disc_color


## "Màn 24 • Bàn 7×7" / "Dungeon Mode • Tầng 48" / "Daily Mission • Wall Builder"
func _title_text(endless: bool, daily: bool, mode_id: String, floor_id: int, width: int, height: int) -> String:
	if endless:
		return tr("STR_PROFILE_ACT_DUNGEON").format([floor_id])
	if daily:
		return tr("STR_PROFILE_ACT_DAILY").format([_mode_name(mode_id)])
	if _mode_name(mode_id) != "":
		return tr("STR_PROFILE_ACT_CUSTOM").format([_mode_name(mode_id), floor_id])
	return tr("STR_PROFILE_ACT_LEVEL").format([floor_id, maxi(width, 0), maxi(height, 0)])


## Dòng phụ: thời gian phá giải · số bước · chuỗi daily (theo mockup)
func _sub_text(row: Dictionary, endless: bool, daily: bool) -> String:
	var elapsed := float(row.get("elapsed", 0.0))
	var time_text := _mmss(elapsed)
	if daily:
		return tr("STR_PROFILE_CHAIN_TAG")
	if endless:
		return tr("STR_PROFILE_RECORD_TAG") + " • " + tr("STR_PROFILE_ACT_MOVES_FORMAT").format([int(row.get("moves", 0))])
	return tr("STR_PROFILE_ACT_TIME_FORMAT").format([time_text])


## Nhãn phải: "3/3 SAO" · "+480 PTS" · "HOÀN THÀNH"
func _tag_text(row: Dictionary, won: bool, endless: bool, daily: bool) -> String:
	if daily:
		return tr("STR_PROFILE_DONE_TAG") if won else tr("STR_PROFILE_FAIL_TAG")
	if endless:
		var score := int(row.get("score", 0))
		return tr("STR_PROFILE_SCORE_FORMAT").format([score]) if won else tr("STR_PROFILE_SCORE_LOSE").format([score])
	if won:
		return tr("STR_PROFILE_STARS_VALUE").format([int(row.get("stars", 0)), 3])
	return tr("STR_PROFILE_FAIL_TAG")


func _tag_color(won: bool, endless: bool, daily: bool) -> Color:
	if daily:
		return COLOR_GREEN if won else COLOR_MUTED
	if endless:
		return COLOR_RED
	return COLOR_GOLD if won else COLOR_MUTED


## Nền chip kết quả (nhạt hơn màu chữ — mockup: vàng pastel · đỏ · xanh lá · xám)
func _tag_bg(won: bool, endless: bool, daily: bool) -> Color:
	if daily:
		return BG_GREEN if won else BG_MUTED
	if endless:
		return BG_RED
	return BG_GOLD if won else BG_MUTED


func _set_tag(text: String, color: Color, bg: Color) -> void:
	if _tag == null:
		return
	_tag.text = text
	# Màu theo dòng là dữ liệu RUNTIME ⇒ nhân bản LabelSettings rồi đổi font_color
	if _tag.label_settings != null:
		var settings := _tag.label_settings.duplicate() as LabelSettings
		settings.font_color = color
		_tag.label_settings = settings
	# Chip nền: art TĨNH khai trong .tscn (chip_grey) → nhân màu pastel theo loại dòng,
	# và co bề rộng ôm theo chữ (nhãn neo phải nên chỉ cần kéo offset_left).
	var box := _tag.get_theme_stylebox("normal")
	if box is StyleBoxTexture:
		var styled := (box as StyleBoxTexture).duplicate() as StyleBoxTexture
		styled.modulate_color = bg
		_tag.add_theme_stylebox_override("normal", styled)
	_tag.offset_left = -(maxf(_tag.get_minimum_size().x, 28.0) + 10.0)


## Tên chế độ đặc biệt (rỗng với màn thường / dungeon / daily cổ điển)
func _mode_name(mode_id: String) -> String:
	if mode_id.is_empty() or mode_id == "play" or mode_id == "dungeon" or mode_id == "daily_classic":
		return ""
	# Khoá dịch dựng theo MÃ chế độ — cùng cách các popup/màn Daily đang dùng
	var key := "STR_MODE_%s" % mode_id.to_upper()
	var text := tr(key)
	return "" if text == key else text


static func _mmss(seconds: float) -> String:
	var total := maxi(int(round(seconds)), 0)
	return "%02d:%02d" % [total / 60, total % 60]
