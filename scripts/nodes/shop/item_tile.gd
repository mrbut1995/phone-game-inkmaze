class_name ShopItemTile
extends Control
## ============================================================================
## Thẻ HÀNG dạng Ô 475×315 — dùng cho tab BÚT & MỰC và GIẤY VỞ
## (theo mockup/shopping_pencil.svg):
##   nhãn góc trên-trái · vòng icon + hình minh hoạ + NÉT MỰC vẽ thử ·
##   tên · mô tả · dòng trạng thái · nút 200×46 (SỬ DỤNG / ĐANG DÙNG / giá Xu)
##
## Màu món hàng (data.color) tô cho: lề trái · vòng icon · icon · nét mực · nút.
## ============================================================================

signal action_pressed(item_id: String)
## Chạm vào thân thẻ (ngoài nút) = chọn ngòi bút này để XEM THỬ ở Bàn nháp thử bút
signal preview_pressed(item_id: String)

const CARD_ART := preload("res://assets/images/shop/card_tile.svg")
const CIRCLE := preload("res://assets/images/shop/icon_circle.svg")
const STROKE := preload("res://assets/images/shop/ink_stroke.svg")
const BTN_NORMAL := preload("res://assets/images/shop/btn_tile_normal.svg")
const BTN_DONE := preload("res://assets/images/shop/btn_tile_done.svg")
const BTN_PRICE := preload("res://assets/images/shop/btn_tile_price.svg")
const BTN_PRICE_VIP := preload("res://assets/images/shop/btn_tile_price_vip.svg")
const ICONS := {
	"pen": preload("res://assets/images/shop/icon_pen.svg"),
	"ink": preload("res://assets/images/shop/icon_ink.svg"),
	"paper": preload("res://assets/images/shop/icon_paper.svg"),
}
const VIP_BADGE := "STR_SHOP_BADGE_VIP"

var item_id: String = ""
var item_data: Dictionary = {}
var _selected := false


func setup(data: Dictionary) -> void:
	item_data = data
	item_id = str(data.get("id", ""))
	_refresh()


func _refresh() -> void:
	var color := Color(str(item_data.get("color", "#3D83AE")))
	_refresh_preview(color)
	_set_texts()
	_set_button(color)


func _refresh_preview(color: Color) -> void:
	var margin := get_node_or_null("Bar") as ColorRect
	if margin != null:
		margin.color = color
	var circle := get_node_or_null("IconCircle") as TextureRect
	if circle != null:
		circle.texture = CIRCLE
		circle.modulate = Color(color.r, color.g, color.b, 0.30 if _selected else 0.16)
	var icon := get_node_or_null("Icon") as TextureRect
	if icon != null:
		icon.visible = true
		var cursor_tex := PenSkin.cursor_texture(item_id) if _is_pen() else null
		if cursor_tex != null:
			# BÚT & MỰC: hiện đúng icon con trỏ sẽ dùng trong game của ngòi bút này
			icon.texture = cursor_tex
			icon.modulate = Color.WHITE
		else:
			icon.texture = ICONS.get(str(item_data.get("icon", "pen")), ICONS["pen"])
			icon.modulate = color
	var stroke := get_node_or_null("Stroke") as TextureRect
	if stroke != null:
		stroke.texture = STROKE
		# Nét mực mẫu: màu mực thật của ngòi bút (trùng màu nét vẽ trong game)
		stroke.modulate = PenSkin.ink_color(item_id) if _is_pen() else color


func _is_pen() -> bool:
	return str(item_data.get("category", "")) == "pen"


## Thẻ đang được Bàn nháp thử bút xem thử -> vòng tròn icon sáng hơn
func set_selected(on: bool) -> void:
	if _selected == on:
		return
	_selected = on
	var color := Color(str(item_data.get("color", "#3D83AE")))
	var circle := get_node_or_null("IconCircle") as TextureRect
	if circle != null:
		circle.modulate = Color(color.r, color.g, color.b, 0.30 if _selected else 0.16)


## Chạm thân thẻ (vùng không bị nút hành động "ăn") = chọn xem thử
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			preview_pressed.emit(item_id)
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			preview_pressed.emit(item_id)


func _set_texts() -> void:
	_set_label("Name", TranslationServer.translate(str(item_data.get("name_key", ""))))
	_set_label("Desc", TranslationServer.translate(str(item_data.get("desc_key", ""))))
	_set_label("Note", _note_text())
	_refresh_badge()


## Nhãn góc: bề ngang co theo chữ (mockup: chip ở góc trên-trái, không tràn thẻ)
func _refresh_badge() -> void:
	var badge := get_node_or_null("Badge") as NinePatchRect
	var badge_label := get_node_or_null("BadgeLabel") as Label
	var badge_key := str(item_data.get("badge_key", ""))
	if badge == null or badge_label == null:
		return
	if badge_key.is_empty():
		badge.visible = false
		badge_label.visible = false
		return
	badge.visible = true
	badge_label.visible = true
	badge_label.text = TranslationServer.translate(badge_key)
	var width := maxf(badge_label.get_minimum_size().x + 34.0, 88.0)
	badge.position = Vector2(42, 20)
	badge.size = Vector2(width, 26)
	badge_label.position = badge.position
	badge_label.size = badge.size


func _note_text() -> String:
	if Shop.is_equipped(item_id):
		return TranslationServer.translate("STR_SHOP_EQUIPPED_NOTE")
	if Shop.is_owned(item_id):
		return TranslationServer.translate("STR_SHOP_OWNED_NOTE")
	if not Shop.can_afford(item_id):
		return TranslationServer.translate("STR_SHOP_NOT_ENOUGH")
	return ""


func _set_button(color: Color) -> void:
	var btn := get_node_or_null("Action") as TextureButton
	var label := get_node_or_null("ActionLabel") as Label
	var coin := get_node_or_null("CoinIcon") as TextureRect
	if btn == null or label == null:
		return
	btn.modulate = Color.WHITE
	btn.disabled = false
	# Đang dùng -> con dấu xanh lá (khoá bấm)
	if Shop.is_equipped(item_id):
		btn.texture_normal = BTN_DONE
		btn.texture_pressed = BTN_DONE
		btn.texture_hover = BTN_DONE
		btn.texture_disabled = BTN_DONE
		btn.disabled = true
		label.theme_type_variation = &"ShopBtnTextDone"
		label.text = TranslationServer.translate("STR_SHOP_EQUIPPED")
		_set_coin_icon(coin, false, label)
		return
	# Đã sở hữu -> nút "SỬ DỤNG" tô màu món hàng (art TRẮNG + modulate)
	if Shop.is_owned(item_id):
		btn.texture_normal = BTN_NORMAL
		btn.texture_pressed = BTN_NORMAL
		btn.texture_hover = BTN_NORMAL
		btn.texture_disabled = BTN_NORMAL
		btn.modulate = color
		label.theme_type_variation = &"ShopBtnText"
		label.text = TranslationServer.translate("STR_SHOP_USE")
		_set_coin_icon(coin, false, label)
		return
	# Chưa sở hữu -> nút giá Xu (món VIP dùng nút hổ phách đặc, chữ trắng)
	var vip := str(item_data.get("badge_key", "")) == VIP_BADGE
	btn.texture_normal = BTN_PRICE_VIP if vip else BTN_PRICE
	btn.texture_pressed = btn.texture_normal
	btn.texture_hover = btn.texture_normal
	btn.texture_disabled = btn.texture_normal
	btn.disabled = not Shop.can_afford(item_id)
	label.theme_type_variation = &"ShopBtnText" if vip else &"ShopPrice"
	label.text = TranslationServer.translate("STR_SHOP_PRICE_FORMAT").format([
		Shop.thousands(int(item_data.get("price", 0)))])
	_set_coin_icon(coin, not vip, label)


## Icon Xu trong nút giá; bật thì đẩy chữ sang phải cho khỏi đè lên icon
func _set_coin_icon(coin: TextureRect, visible_now: bool, label: Label) -> void:
	var shift := 24.0 if visible_now else 0.0
	if coin != null:
		coin.visible = visible_now
	label.offset_left = 137.0 + shift
	label.offset_right = 337.0 + shift


func _set_label(path: String, text: String) -> void:
	var label := get_node_or_null(path) as Label
	if label != null:
		label.text = text


func _on_action_pressed() -> void:
	action_pressed.emit(item_id)
