class_name DailyActionCard
extends Control
## ============================================================================
## Component: thẻ HÀNH ĐỘNG của màn Daily (nodes/daily/action_card.tscn)
##
## Bám ĐÚNG mockup/daily_challenge.svg (thẻ 448×391 trong khung 1080×1920, scene
## dùng nửa kích thước 224×195,5):
##   · Băng dính chéo góc trên (xanh cho CHƠI · hổ phách cho THỬ THÁCH)
##   · Khung icon vuông bo góc (tam giác Play xanh · tia sét hổ phách)
##   · Tiêu đề + dòng phụ (tên luật của ngày, chữ hổ phách ở thẻ THỬ THÁCH)
##   · 3 ngôi sao ở giữa (vàng = đã đạt · xám = chưa)
##   · Nút CTA lớn ở đáy (xanh `#256C96` · hổ phách `#F59E0B`)
##
## `is_challenge` quyết định art; `setup()` gán toàn bộ chữ nên scene cha chỉ
## cần đặt 2 thẻ và nối tín hiệu `pressed`.
## ============================================================================

signal pressed

## Số Sao tối đa của một thẻ (khớp `DailyManager.PLAY_STARS_MAX` / `CHALLENGE_STARS_MAX`)
const STARS_MAX := 3

const ART_DIR := "res://assets/images-png/daily/"
const ICON_TEXTURES := {false: "tri_blue.png", true: "bolt_amber.png"}
const BOX_TEXTURES := {false: "icon_box_blue.png", true: "icon_box_amber.png"}
const CTA_ICON_TEXTURES := {false: "tri_white.png", true: "tri_dark.png"}
## [normal, pressed]
const CTA_TEXTURES := {
	false: ["btn_cta_blue_normal.png", "btn_cta_blue_pressed.png"],
	true: ["btn_cta_amber_normal.png", "btn_cta_amber_pressed.png"],
}
const CTA_LABEL_COLORS := {false: Color("#FFFDF8"), true: Color("#2A1A05")}
const SUB_COLORS := {false: Color("#3D5A73"), true: Color("#C4843A")}
const PAPER_TEXTURES := {false: "card_paper.png", true: "card_paper_amber.png"}
const STAR_ON := "res://assets/images-png/common/star_highlight.png"
const STAR_OFF := "res://assets/images-png/common/star_empty.png"

@export var paper: TextureRect = null
@export var icon_box: TextureRect = null
@export var icon: TextureRect = null
@export var tape_blue: TextureRect = null
@export var tape_amber: TextureRect = null
@export var lbl_title: Label = null
@export var lbl_sub: Label = null
@export var stars_row: HBoxContainer = null
@export var btn_cta: TextureButton = null
@export var lbl_cta: Label = null
@export var icon_cta: TextureRect = null
## AnimationPlayer chứa `celebrate_1..3` (sao nảy + toả sáng + lấp lánh khi vừa hoàn thành ván) và `RESET`
@export var fx_anim: AnimationPlayer = null

## Số Sao đã đạt của thẻ hiện tại (0..3)
var _stars: int = 0
## Đang chạy hiệu ứng "vừa hoàn thành" (test/tiện ích đọc)
var _celebrating: bool = false


func _ready() -> void:
	if fx_anim != null and not fx_anim.animation_finished.is_connected(_on_fx_finished):
		fx_anim.animation_finished.connect(_on_fx_finished)


## Phát hiệu ứng "vừa hoàn thành ván": các ngôi sao ĐÃ ĐẠT nảy lần lượt + khung icon
## nhún nhẹ. Animation khai sẵn trong `action_card.tscn` (`celebrate_1..3`) — script
## chỉ CHỌN animation theo số Sao rồi play, không tween trong code.
func play_celebrate() -> bool:
	if fx_anim == null or _stars <= 0:
		return false
	var anim := "celebrate_%d" % clampi(_stars, 1, STARS_MAX)
	if not fx_anim.has_animation(anim):
		return false
	fx_anim.stop()
	fx_anim.play(anim)
	_celebrating = true
	return true


## Thẻ có đang chạy hiệu ứng "vừa hoàn thành" không
func is_celebrating() -> bool:
	return _celebrating


## Dừng hiệu ứng (đổi ngày giữa lúc đang ăn mừng / dọn dẹp) và đưa sao/khung icon về trạng thái nghỉ
func stop_celebrate() -> void:
	if fx_anim != null:
		fx_anim.stop()
		if fx_anim.has_animation(&"RESET"):
			fx_anim.play(&"RESET")
			fx_anim.seek(0.0, true)
	_celebrating = false


## Tâm (toạ độ GLOBAL) của ngôi sao thứ `index` (0..2) — điểm xuất phát của sao bay lên thanh Sao
func star_center(index: int) -> Vector2:
	if stars_row != null and index >= 0 and index < stars_row.get_child_count():
		var star := stars_row.get_child(index) as Control
		if star != null:
			return star.get_global_transform() * (star.size * 0.5)
	return get_global_transform() * (size * 0.5)


func _on_fx_finished(_anim_name: StringName) -> void:
	_celebrating = false


## `stars` = số Sao đã đạt của thẻ này (0..3)
func setup(title_key: String, sub_text: String, cta_key: String, is_challenge: bool,
		stars: int) -> void:
	if lbl_title != null:
		lbl_title.text = tr(title_key)
	if lbl_sub != null:
		lbl_sub.text = sub_text
		lbl_sub.add_theme_color_override("font_color", SUB_COLORS[is_challenge])
	if lbl_cta != null:
		lbl_cta.text = tr(cta_key)
		lbl_cta.add_theme_color_override("font_color", CTA_LABEL_COLORS[is_challenge])
	if paper != null:
		paper.texture = _tex(str(PAPER_TEXTURES[is_challenge]))
	if icon_box != null:
		icon_box.texture = _tex(str(BOX_TEXTURES[is_challenge]))
	if icon != null:
		icon.texture = _tex(str(ICON_TEXTURES[is_challenge]))
	if tape_blue != null:
		tape_blue.visible = not is_challenge
	if tape_amber != null:
		tape_amber.visible = is_challenge
	if icon_cta != null:
		icon_cta.texture = _tex(str(CTA_ICON_TEXTURES[is_challenge]))
	if btn_cta != null:
		var art: Array = CTA_TEXTURES[is_challenge]
		btn_cta.texture_normal = _tex(str(art[0]))
		btn_cta.texture_pressed = _tex(str(art[1]))
		btn_cta.texture_hover = _tex(str(art[1]))
		btn_cta.texture_focused = _tex(str(art[0]))
		btn_cta.texture_disabled = _tex(str(art[0]))
	_stars = clampi(stars, 0, STARS_MAX)
	if stars_row == null:
		return
	var children := stars_row.get_children()
	for i in children.size():
		var star := children[i] as TextureRect
		if star == null:
			continue
		star.texture = _tex(STAR_ON if i < _stars else STAR_OFF)


## Số Sao đã đạt của thẻ (0..3)
func lit_stars() -> int:
	return _stars


## Chữ trên nút CTA (test đọc để kiểm tra trạng thái "CHƠI LẠI")
func cta_text() -> String:
	return "" if lbl_cta == null else lbl_cta.text


func _tex(file: String) -> Texture2D:
	if file.begins_with("res://"):
		return load(file) as Texture2D
	return load(ART_DIR + file) as Texture2D


func _on_btn_cta_pressed() -> void:
	pressed.emit()
