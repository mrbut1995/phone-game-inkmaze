class_name ChapterCard
extends Control
## ============================================================================
## Thẻ 1 CHƯƠNG trong màn CHỌN CHƯƠNG — mockup/chapter_selection.svg (970×285)
##
## 4 trạng thái:
##   PLAYING — chương đang chơi (viền xanh): thanh Sao trong chương + nút VÀO CHƠI
##   READY   — đã đủ Sao, chờ bấm MỞ KHÓA (viền hổ phách + hào quang nét đứt)
##   LOCKED  — thiếu Sao (giấy xám + ổ khóa trên doodle + nút CẦN n SAO)
##   COMING  — đã mở nhưng chương chưa có màn nào (nút SẮP RA MẮT)
##
## Icon mê cung (doodle) dùng art TRẮNG theo độ mờ + `modulate` theo trạng thái:
##   xanh #3D83AE (đang chơi) · hổ phách #C4843A (đủ điều kiện) · xám #7A8F9B (khóa)
## ============================================================================

signal selected(chapter_id: int)
signal unlock_requested(chapter_id: int)

enum State { PLAYING, READY, LOCKED, COMING }

const CARD_OPEN := preload("res://assets/images/chapters/card_open.svg")
const CARD_READY := preload("res://assets/images/chapters/card_ready.svg")
const CARD_LOCKED := preload("res://assets/images/chapters/card_locked.svg")
const CHIP_SIZE_ART := preload("res://assets/images/chapters/chip_size.svg")
const BTN_PLAY_NORMAL := preload("res://assets/images/chapters/btn_play_normal.svg")
const BTN_PLAY_PRESSED := preload("res://assets/images/chapters/btn_play_pressed.svg")
const BTN_UNLOCK_NORMAL := preload("res://assets/images/chapters/btn_unlock_normal.svg")
const BTN_UNLOCK_PRESSED := preload("res://assets/images/chapters/btn_unlock_pressed.svg")
const BTN_LOCKED_ART := preload("res://assets/images/chapters/btn_locked.svg")
const STAR_ICON := preload("res://assets/images/chapters/icon_star_white.svg")
const LOCK_ICON := preload("res://assets/images/chapters/lock_overlay.svg")
const PLAY_ICON := preload("res://assets/images/level_selector/icon_play_triangle.svg")
## Icon mê cung dùng chung theo cỡ bàn (fallback khi chương chưa có icon riêng)
const MAZE_TIERS := {
	"small": preload("res://assets/images/chapters/maze_small.svg"),
	"medium": preload("res://assets/images/chapters/maze_medium.svg"),
	"large": preload("res://assets/images/chapters/maze_large.svg"),
}
## Mỗi chương 1 icon RIÊNG (doodle khác nhau cho dễ nhận biết)
const CHAPTER_ICONS := {
	1: preload("res://assets/images/chapters/icon_intro.svg"),
	2: preload("res://assets/images/chapters/icon_logic.svg"),
	3: preload("res://assets/images/chapters/icon_trap.svg"),
	4: preload("res://assets/images/chapters/icon_master.svg"),
}
## Tên icon ghi trong `ChapterData.icon` -> texture (ưu tiên hơn số chương)
const ICON_KEYS := {
	"intro": preload("res://assets/images/chapters/icon_intro.svg"),
	"logic": preload("res://assets/images/chapters/icon_logic.svg"),
	"trap": preload("res://assets/images/chapters/icon_trap.svg"),
	"master": preload("res://assets/images/chapters/icon_master.svg"),
}

## Màu theo trạng thái (dùng cho doodle + ruy băng + chip kích thước + thanh Sao)
const COLOR_PLAYING := Color(0.23921569, 0.5137255, 0.68235296)
const COLOR_READY := Color(0.76862746, 0.5176471, 0.22745098)
const COLOR_LOCKED := Color(0.47843137, 0.56078434, 0.60784316)
## Nền chip kích thước (đặt bằng modulate trên art trắng)
const CHIP_BG_PLAYING := Color(0.92156863, 0.9529412, 0.972549)
const CHIP_BG_READY := Color(0.99607843, 0.9529412, 0.78039217)
const CHIP_BG_LOCKED := Color(0.8862745, 0.8666667, 0.8352941)

var chapter_id: int = 1
var state: State = State.PLAYING
var _ratio := 0.0


## info: { state, stars_own, stars_total, levels_cleared, levels_total,
##         total_stars, next_level, size_tier }
func setup(chapter: ChapterData, info: Dictionary) -> void:
	chapter_id = maxi(int(chapter.chapter_id), 1)
	state = info.get("state", State.PLAYING)

	_apply_state_art(info)
	_apply_texts(chapter, info)
	_apply_stats(chapter, info)
	_apply_action(chapter, info)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_bar_fill()


## Thanh Sao: đo lại mỗi khi thẻ đổi cỡ — thẻ nằm trong CONTAINER nên lúc `setup()`
## bề rộng thanh có thể còn 0 (bố cục chưa dàn xong).
func _apply_bar_fill() -> void:
	var bar := get_node_or_null("Panel/Content/Display/Info/Bar") as Control
	var fill := get_node_or_null("Panel/Content/Display/Info/Bar/Fill") as Control
	if bar == null or fill == null:
		return
	fill.size = Vector2(bar.size.x * _ratio, bar.size.y)


# ---------------------------------------------------------------------------
# Hình thức theo trạng thái
# ---------------------------------------------------------------------------
func _apply_state_art(info: Dictionary) -> void:
	var bg := get_node_or_null("Panel") as TextureRect
	var halo := get_node_or_null("Halo") as Control
	var ribbon := get_node_or_null("Panel/Ribbon") as TextureRect
	var ribbon_label := get_node_or_null("Panel/Ribbon/RibbonLabel") as Label
	var chip := get_node_or_null("Panel/Content/Display/Info/Chip") as TextureRect
	var chip_label := get_node_or_null("Panel/Content/Display/Info/Chip/ChipLabel") as Label
	var doodle := get_node_or_null("Panel/Content/Display/Doodle") as TextureRect
	var lock := get_node_or_null("Panel/Content/Display/Doodle/Lock") as Control

	var color := COLOR_PLAYING
	var ribbon_key := "STR_CHAPTER_RIBBON_PLAYING"
	var chip_color := CHIP_BG_PLAYING
	if state == State.PLAYING and not bool(info.get("current", true)):
		ribbon_key = "STR_CHAPTER_RIBBON_OPEN"
	match state:
		State.READY:
			color = COLOR_READY
			ribbon_key = "STR_CHAPTER_RIBBON_READY"
			chip_color = CHIP_BG_READY
		State.LOCKED:
			color = COLOR_LOCKED
			ribbon_key = "STR_CHAPTER_RIBBON_LOCKED"
			chip_color = CHIP_BG_LOCKED
		State.COMING:
			ribbon_key = "STR_CHAPTER_RIBBON_COMING"

	if bg != null:
		match state:
			State.READY:
				bg.texture = CARD_READY
			State.LOCKED:
				bg.texture = CARD_LOCKED
			_:
				bg.texture = CARD_OPEN
	if halo != null:
		halo.visible = state == State.READY
	if doodle != null:
		doodle.self_modulate = color
	if lock != null:
		lock.visible = state == State.LOCKED
	if ribbon != null:
		ribbon.self_modulate = color
	if ribbon_label != null:
		ribbon_label.text = TranslationServer.translate(ribbon_key)
	if chip != null:
		chip.self_modulate = chip_color
	if chip_label != null:
		chip_label.theme_type_variation = _chip_variation()


func _chip_variation() -> StringName:
	match state:
		State.READY:
			return &"ChapterChipSizeAmber"
		State.LOCKED:
			return &"ChapterChipSizeMuted"
		_:
			return &"ChapterChipSize"


func _apply_texts(chapter: ChapterData, info: Dictionary) -> void:
	_set_label("Panel/Content/Display/Info/Title", TranslationServer.translate("STR_CHAPTER_TITLE_FORMAT").format([
		chapter.chapter_id, chapter.title]))
	_set_label("Panel/Content/Display/Info/Subtitle", chapter.subtitle)
	var chip := get_node_or_null("Panel/Content/Display/Info/Chip") as Control
	if chip != null:
		var size_text := chapter.display_size()
		chip.visible = not size_text.is_empty()
		_set_label("Panel/Content/Display/Info/Chip/ChipLabel", TranslationServer.translate("STR_CHAPTER_SIZE_FORMAT").format([size_text]))
	# Doodle theo chương (icon riêng) — suy từ dữ liệu chương / cỡ bàn lớn nhất
	var doodle := get_node_or_null("Panel/Content/Display/Doodle") as TextureRect
	if doodle != null:
		doodle.texture = _icon_for(chapter, info)
	var locked_title := state == State.LOCKED
	var title := get_node_or_null("Panel/Content/Display/Info/Title") as Label
	if title != null:
		title.theme_type_variation = &"ChapterCardTitleLocked" if locked_title else &"ChapterCardTitle"
	var subtitle := get_node_or_null("Panel/Content/Display/Info/Subtitle") as Label
	if subtitle != null:
		subtitle.theme_type_variation = &"ChapterCardSubtitleLocked" if locked_title else &"ChapterCardSubtitle"


## Icon của chương: 1) tên ghi trong .tres chương  2) icon riêng theo số chương
## 3) fallback theo cỡ bàn lớn nhất (maze_small/medium/large)
func _icon_for(chapter: ChapterData, info: Dictionary) -> Texture2D:
	var key: String = chapter.display_icon()
	if not key.is_empty() and ICON_KEYS.has(key):
		return ICON_KEYS[key]
	if CHAPTER_ICONS.has(chapter.chapter_id):
		return CHAPTER_ICONS[chapter.chapter_id]
	return MAZE_TIERS.get(str(info.get("size_tier", "small")), MAZE_TIERS["small"])


# ---------------------------------------------------------------------------
# Số liệu: thanh Sao / chip trạng thái
# ---------------------------------------------------------------------------
func _apply_stats(_chapter: ChapterData, info: Dictionary) -> void:
	var bar := get_node_or_null("Panel/Content/Display/Info/Bar") as Control
	var fill := get_node_or_null("Panel/Content/Display/Info/Bar/Fill") as Control
	var stars := get_node_or_null("Panel/Content/Display/Info/Stats/Stars") as Label
	var stars_sub := get_node_or_null("Panel/Content/Display/Info/Stats/StarsSub") as Label
	var need := get_node_or_null("Panel/Content/Action/NeedChip") as Control
	var have := get_node_or_null("Panel/Content/Display/Info/HaveChip") as Control
	var need_label := get_node_or_null("Panel/Content/Action/NeedChip/NeedLabel") as Label
	var have_label := get_node_or_null("Panel/Content/Display/Info/HaveChip/HaveLabel") as Label

	var stars_total: int = maxi(int(info.get("stars_total", 0)), 0)
	var stars_own: int = int(info.get("stars_own", 0))
	var cost: int = maxi(int(info.get("star_cost", 0)), 0)
	var total_stars: int = int(info.get("total_stars", 0))
	# Chương ĐANG CHƠI / ĐÃ MỞ: tiến độ Sao TRONG chương; chương KHÓA: tiến độ mở khóa
	var locked := state == State.LOCKED
	var shown: int = total_stars if locked else stars_own
	var target: int = cost if locked else stars_total
	var ratio := 0.0
	if target > 0:
		ratio = clampf(float(shown) / float(target), 0.0, 1.0)

	if bar != null:
		bar.visible = not state == State.READY
	_ratio = ratio
	_apply_bar_fill()
	if fill != null:
		fill.self_modulate = COLOR_LOCKED if locked else (COLOR_READY if shown < target else COLOR_PLAYING)
	if stars != null:
		stars.visible = not state == State.READY
		stars.text = TranslationServer.translate("STR_CHAPTER_STARS_FORMAT").format([shown, target])
		stars.theme_type_variation = &"ChapterStarsMuted" if locked else &"ChapterStars"
	if stars_sub != null:
		stars_sub.visible = not locked and not state == State.READY
		stars_sub.text = TranslationServer.translate("STR_CHAPTER_LEVELS_FORMAT").format([
			int(info.get("levels_cleared", 0)), int(info.get("levels_total", 0))])
	if have != null:
		have.visible = state == State.READY
		_set_label("Panel/Content/Display/Info/HaveChip/HaveLabel", TranslationServer.translate("STR_CHAPTER_HAVE_FORMAT").format([total_stars, cost]))
	if have_label != null:
		have_label.visible = state == State.READY
	if need != null:
		need.visible = locked and cost > total_stars
		_set_label("Panel/Content/Action/NeedChip/NeedLabel", TranslationServer.translate("STR_CHAPTER_NEED_FORMAT").format([
			maxi(cost - total_stars, 0)]))
	if need_label != null:
		need_label.visible = locked and cost > total_stars


# ---------------------------------------------------------------------------
# Nút hành động
# ---------------------------------------------------------------------------
func _apply_action(_chapter: ChapterData, info: Dictionary) -> void:
	var btn := get_node_or_null("Panel/Content/Action/Btn") as TextureButton
	var title := get_node_or_null("Panel/Content/Action/Btn/Title") as Label
	var sub := get_node_or_null("Panel/Content/Action/Btn/Sub") as Label
	var star := get_node_or_null("Panel/Content/Action/Btn/Icon") as Control
	var lock := get_node_or_null("Panel/Content/Action/Btn/LockIcon") as Control
	if btn == null:
		return
	if star != null:
		star.visible = false
	if lock != null:
		lock.visible = false
	match state:
		State.READY:
			btn.texture_normal = BTN_UNLOCK_NORMAL
			btn.texture_pressed = BTN_UNLOCK_PRESSED
			btn.disabled = false
			_set_label("Panel/Content/Action/Btn/Title", TranslationServer.translate("STR_CHAPTER_UNLOCK"))
			_set_label("Panel/Content/Action/Btn/Sub", TranslationServer.translate("STR_CHAPTER_REQUIRE_FORMAT").format([
				maxi(int(info.get("star_cost", 0)), 0)]))
			title.theme_type_variation = &"ChapterAction"
			sub.theme_type_variation = &"ChapterActionSubAmber"
			if star != null:
				star.texture = STAR_ICON
				star.visible = true
		State.LOCKED:
			btn.texture_normal = BTN_LOCKED_ART
			btn.texture_pressed = BTN_LOCKED_ART
			btn.disabled = true
			_set_label("Panel/Content/Action/Btn/Title", TranslationServer.translate("STR_CHAPTER_REQUIRE_FORMAT").format([
				maxi(int(info.get("star_cost", 0)), 0)]))
			_set_label("Panel/Content/Action/Btn/Sub", TranslationServer.translate("STR_CHAPTER_NOT_ENOUGH"))
			title.theme_type_variation = &"ChapterActionLocked"
			sub.theme_type_variation = &"ChapterActionLockedSub"
			if lock != null:
				lock.visible = true
		State.COMING:
			btn.texture_normal = BTN_LOCKED_ART
			btn.texture_pressed = BTN_LOCKED_ART
			btn.disabled = true
			_set_label("Panel/Content/Action/Btn/Title", TranslationServer.translate("STR_CHAPTER_RIBBON_COMING"))
			_set_label("Panel/Content/Action/Btn/Sub", "")
			title.theme_type_variation = &"ChapterActionLocked"
		_:
			btn.texture_normal = BTN_PLAY_NORMAL
			btn.texture_pressed = BTN_PLAY_PRESSED
			btn.disabled = false
			_set_label("Panel/Content/Action/Btn/Title", TranslationServer.translate("STR_CHAPTER_PLAY"))
			_set_label("Panel/Content/Action/Btn/Sub", TranslationServer.translate("STR_CHAPTER_PLAY_SUB").format([
				int(info.get("next_level", 1))]))
			title.theme_type_variation = &"ChapterAction"
			sub.theme_type_variation = &"ChapterActionSub"
			# Chương MỞ: chỗ trống bên trái nút -> đặt icon PLAY
			if star != null:
				star.texture = PLAY_ICON
				star.visible = true


func _set_label(path: String, text: String) -> void:
	# Đường dẫn ghi đủ `Panel/...`: mọi UI của thẻ (trừ `Halo`) nằm trong `Panel` = nền thẻ
	var label := get_node_or_null(path) as Label
	if label != null and label.text != text:
		label.text = text


func _on_btn_pressed() -> void:
	if state == State.READY:
		unlock_requested.emit(chapter_id)
	else:
		selected.emit(chapter_id)
