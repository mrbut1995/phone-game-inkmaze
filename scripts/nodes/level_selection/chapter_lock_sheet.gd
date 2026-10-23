class_name ChapterLockSheet
extends Control
## ============================================================================
## Overlay: KHUNG "CHƯƠNG ĐANG KHOÁ" của màn Chọn màn
## (nodes/level_selection/chapter_lock_sheet.tscn)
##
## Mở khi người chơi bấm TAB chương KHOÁ / ĐỦ SAO nhưng chưa mở. Nội dung: icon · số +
## tên + mô tả chương · chip kích thước bàn · "CẦN {star_cost} SAO" · thanh Sao
## `total_stars()/star_cost` · dòng trạng thái · nút MỞ KHOÁ (hoặc xám khi thiếu Sao).
##
## ⚠️ `star_cost` KHÔNG bị trừ khi mở khoá — chỉ cần `total_stars() >= star_cost`
## (xem AI_GUIDE §3.2), nên nhãn luôn ghi "CẦN {n} SAO", không ghi "−{n}★".
##
## Mở/đóng bằng AnimationPlayer NGAY TRONG SCENE (`open` / `close` / `RESET`), như
## `MonthSheet` của màn Daily; script chỉ gọi animation và đổ dữ liệu. Animation `open`/`close`
## có track `.:visible` nên sheet TỰ ẨN khi đóng xong (nền mờ không còn chặn chuột).
## ============================================================================

## Người chơi bấm MỞ KHÓA (màn Chọn màn gọi `GameManager.unlock_chapter`)
signal unlock_requested(chapter_id: int)
## Sheet đã đóng (kể cả bấm nền mờ / nút ✕)
signal closed

@export_group("Node binding")
@export var dim: BaseButton = null
@export var icon: TextureRect = null
@export var lbl_index: Label = null
@export var lbl_title: Label = null
@export var lbl_subtitle: Label = null
@export var lbl_size: Label = null
@export var lbl_require: Label = null
@export var lbl_progress: Label = null
@export var star_bar: TextureProgressBar = null
@export var lbl_status: Label = null
@export var btn_unlock: BaseButton = null
@export var lbl_unlock: Label = null
@export var btn_close: BaseButton = null
@export var sheet_anim: AnimationPlayer = null

@export_group("Art")
@export var art_icon_locked: Texture2D = null
@export var art_icon_ready: Texture2D = null

@export_group("Màu theo trạng thái")
## Thanh Sao: art vàng khi chưa đủ, art xanh khi đủ (đổi texture, không nhuộm màu)
@export var art_bar_locked: Texture2D = null
@export var art_bar_ready: Texture2D = null
@export var color_status_locked := Color(0.5412, 0.3529, 0.0706, 1)
@export var color_status_ready := Color(0.2431, 0.5608, 0.1137, 1)
@export var color_unlock_ready := Color(1, 1, 1, 1)
@export var color_unlock_locked := Color(0.6039, 0.6824, 0.7412, 1)

@export_group("Nền mờ")
## Nền mờ tràn ra NGOÀI khung (px) — bản ngang đặt lớn để phủ cả dải bên cạnh khung thiết kế
@export var dim_overscan := 0.0

var chapter_id: int = 0
var _closing := false


func _ready() -> void:
	visible = false
	if dim != null and dim_overscan > 0.0:
		dim.offset_left = -dim_overscan
		dim.offset_top = -dim_overscan
		dim.offset_right = dim_overscan
		dim.offset_bottom = dim_overscan
	_connect_locale_signal()


## Đổi ngôn ngữ ⇒ viết lại nội dung sheet (nếu đang mở)
func _connect_locale_signal() -> void:
	var loc: Node = get_node_or_null("/root/LocalizationManager")
	if loc != null and loc.has_signal("locale_changed") \
			and not loc.is_connected("locale_changed", _on_locale_changed):
		loc.connect("locale_changed", _on_locale_changed)


func _on_locale_changed(_locale: String) -> void:
	if visible:
		_refresh()


## Mở khung cho chương `id` (đọc số liệu thật từ GameManager/LevelManager)
func open_chapter(id: int) -> void:
	chapter_id = id
	_closing = false
	visible = true
	_refresh()
	if sheet_anim != null and sheet_anim.has_animation(&"open"):
		sheet_anim.stop()
		sheet_anim.play(&"open")


func close_sheet() -> void:
	if not visible or _closing:
		return
	_closing = true
	if sheet_anim != null and sheet_anim.has_animation(&"close"):
		sheet_anim.stop()
		sheet_anim.play(&"close")   # track `.:visible` trong animation tự ẩn sheet khi xong
	else:
		visible = false
	closed.emit()


## Khung đang mở (màn Chọn màn dùng để chặn Back đóng scene khi sheet còn mở).
## Đang chạy animation đóng thì coi như ĐÃ đóng.
func is_open() -> bool:
	return visible and not _closing


## Đổ toàn bộ nội dung theo dữ liệu hiện tại của chương
func _refresh() -> void:
	var chapter := _chapter_data()
	var have_stars := _total_stars()
	var cost := chapter.star_cost if chapter != null else 0
	var enough := have_stars >= cost

	# "CHƯƠNG 2" (nhỏ, cam) → TÊN chương (to) → mô tả
	if lbl_index != null:
		lbl_index.text = TranslationServer.translate("STR_CHAPTER_FORMAT").format([chapter_id])
	if lbl_title != null:
		lbl_title.text = chapter.display_title() if chapter != null else ""
	if lbl_subtitle != null:
		lbl_subtitle.text = chapter.display_subtitle() if chapter != null else ""
		lbl_subtitle.visible = not lbl_subtitle.text.is_empty()
	if lbl_size != null:
		var size_text := chapter.display_size() if chapter != null else ""
		lbl_size.text = TranslationServer.translate("STR_CHAPTER_SIZE_FORMAT").format([size_text])
		lbl_size.visible = not size_text.is_empty()
	if lbl_require != null:
		lbl_require.text = TranslationServer.translate("STR_CHAPTER_REQUIRE_FORMAT").format([cost])
	if star_bar != null:
		star_bar.min_value = 0.0
		star_bar.max_value = maxf(float(cost), 1.0)
		star_bar.value = float(mini(have_stars, maxi(cost, 0)))
	if star_bar != null:
		var bar_art := art_bar_ready if enough else art_bar_locked
		if bar_art != null:
			star_bar.texture_progress = bar_art
	if lbl_progress != null:
		lbl_progress.text = TranslationServer.translate("STR_CHAPTER_STARS_FORMAT").format([
			mini(have_stars, cost), cost])
	if lbl_status != null:
		# "18 / 25 SAO · CÒN THIẾU 7 SAO" (chưa đủ) · "✓ ĐÃ ĐỦ: 27 / 25 SAO" (đủ)
		if enough:
			lbl_status.text = TranslationServer.translate("STR_CHAPTER_HAVE_FORMAT").format([have_stars, cost])
		else:
			lbl_status.text = "%s · %s" % [
				TranslationServer.translate("STR_CHAPTER_STARS_FORMAT").format([have_stars, cost]),
				TranslationServer.translate("STR_CHAPTER_NEED_FORMAT").format([maxi(cost - have_stars, 0)])]
		lbl_status.add_theme_color_override("font_color",
			color_status_ready if enough else color_status_locked)
	if lbl_unlock != null:
		lbl_unlock.text = TranslationServer.translate("STR_CHAPTER_UNLOCK") if enough \
			else TranslationServer.translate("STR_CHAPTER_NOT_ENOUGH")
		lbl_unlock.add_theme_color_override("font_color",
			color_unlock_ready if enough else color_unlock_locked)
	if btn_unlock != null:
		btn_unlock.disabled = not enough
	if icon != null:
		var art: Texture2D = art_icon_ready if enough else art_icon_locked
		if art != null:
			icon.texture = art


func _on_unlock_pressed() -> void:
	if btn_unlock != null and btn_unlock.disabled:
		Sfx.play(Sfx.BTN_CLICK)
		return
	unlock_requested.emit(chapter_id)


func _on_close_pressed() -> void:
	close_sheet()


func _chapter_data() -> ChapterData:
	var lm := get_node_or_null("/root/LevelManager")
	if lm == null or not lm.has_method("get_chapter"):
		return null
	return lm.call("get_chapter", chapter_id) as ChapterData


func _total_stars() -> int:
	var gm := get_node_or_null("/root/GameManager")
	if gm == null or not gm.has_method("total_stars"):
		return 0
	return int(gm.call("total_stars"))
