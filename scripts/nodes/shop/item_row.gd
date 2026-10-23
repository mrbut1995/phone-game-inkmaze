class_name ShopItemRow
extends Control
## ============================================================================
## Thẻ HÀNG dạng NGANG (980×180) — dùng cho tab DỤNG CỤ và NẠP XU.
## setup(item) nhận 1 mục trong ShopManager.ITEMS; nút bên phải đổi theo trạng thái:
##   MUA / MUA THÊM (dụng cụ) · giá VNĐ (gói nạp) · SỬ DỤNG · ĐANG DÙNG ✓
## ============================================================================

signal action_pressed(item_id: String)

const ICON_BOX := preload("res://assets/images-png/icons/icon_box.png")
## Ô THÔNG TIN giá/trạng thái (PHẲNG, không bấm riêng) + art thẻ
const INFO_BLUE := preload("res://assets/images-png/shop/info_blue.png")
const INFO_DONE := preload("res://assets/images-png/shop/btn_equipped.png")
const INFO_AMBER := preload("res://assets/images-png/shop/btn_coin.png")
const CARD_NORMAL := preload("res://assets/images-png/shop/card_row.png")
const CARD_ARMED := preload("res://assets/images-png/shop/card_row_selected.png")
const ICONS := {
	"pen": preload("res://assets/images-png/icons/icon_pen.png"),
	"ink": preload("res://assets/images-png/icons/icon_ink.png"),
	"paper": preload("res://assets/images-png/icons/icon_paper.png"),
	"coin": preload("res://assets/images-png/icons/icon_coin.png"),
	"tool_undo": preload("res://assets/images-png/icons/icon_tool_undo.png"),
	"tool_hint": preload("res://assets/images-png/icons/icon_tool_hint.png"),
	"tool_reveal": preload("res://assets/images-png/icons/icon_tool_reveal.png"),
	"tool_time": preload("res://assets/images-png/icons/icon_tool_time.png"),
	"tool_revive": preload("res://assets/images-png/icons/icon_tool_revive.png"),
	"tool_shield": preload("res://assets/images-png/icons/icon_tool_shield.png"),
	"life": preload("res://assets/images-png/icons/icon_life.png"),
}

var item_id: String = ""
var item_data: Dictionary = {}
var _tap := ShopCardTap.new()
var _tappable := true
var _affordable := true
var _needs_confirm := false


func setup(data: Dictionary) -> void:
	item_data = data
	item_id = str(data.get("id", ""))
	_refresh()


func _refresh() -> void:
	var color := Color(str(item_data.get("color", "#3D83AE")))
	_set_icon(color)
	_set_texts()
	_set_button(color)


func _set_icon(color: Color) -> void:
	var box := get_node_or_null("Panel/IconBox") as TextureRect
	if box != null:
		box.texture = ICON_BOX
		box.self_modulate = Color(color.r, color.g, color.b, 1.0).lerp(Color.WHITE, 0.78)
	var icon := get_node_or_null("Panel/IconBox/Icon") as TextureRect
	if icon != null:
		icon.texture = ICONS.get(str(item_data.get("icon", "pen")), ICONS["pen"])
		icon.self_modulate = color


func _set_texts() -> void:
	_set_label("Panel/Description/Name", TranslationServer.translate(str(item_data.get("name_key", ""))))
	_set_label("Panel/Description/Desc", TranslationServer.translate(str(item_data.get("desc_key", ""))))
	_set_label("Panel/Description/Stock", str(_stock_text()))
	var badge_key := str(item_data.get("badge_key", ""))
	var badge := get_node_or_null("Panel/Badge") as NinePatchRect
	var badge_label := get_node_or_null("Panel/Badge/BadgeLabel") as Label
	if badge != null:
		badge.visible = not badge_key.is_empty()
	if badge_label != null:
		badge_label.visible = not badge_key.is_empty()
		if not badge_key.is_empty():
			badge_label.text = TranslationServer.translate(badge_key)


## Dòng phụ: kho hàng còn lại (dụng cụ) hoặc ưu đãi (gói nạp)
func _stock_text() -> String:
	# Gói LƯỢT CHƠI: hiện số lượt đang có / tối đa (lượt dùng chung toàn game)
	if Shop.is_life_pack(item_id):
		return TranslationServer.translate("STR_SHOP_LIFE_STOCK_FORMAT").format([
			Life.count(), Life.max_count()])
	if Shop.is_consumable(item_id):
		return TranslationServer.translate("STR_SHOP_STOCK_FORMAT").format([
			Shop.tool_count(item_id),
			TranslationServer.translate("STR_SHOP_UNIT_TURN")])
	var bonus := int(item_data.get("bonus", 0))
	if bonus > 0:
		return "%s  (+%s %s)" % [
			TranslationServer.translate("STR_SHOP_BONUS_TAG"),
			Shop.thousands(bonus),
			TranslationServer.translate("STR_SHOP_UNIT_COIN")]
	return ""


func _set_button(_color: Color) -> void:
	var btn := get_node_or_null("Panel/Action") as TextureButton
	var label := get_node_or_null("Panel/Action/ActionLabel") as Label
	if btn == null or label == null:
		return
	btn.disabled = false
	btn.material = null
	btn.mouse_filter = Control.MOUSE_FILTER_IGNORE   # ô giá chỉ là thông tin: chạm cả thẻ mới có tác dụng
	_tappable = true
	_affordable = true
	_needs_confirm = false
	var category: String = str(Shop.category_of(item_id))
	var price := int(Shop.item(item_id).get("price", 0))
	if category == "coin":
		# Gói nạp tiền thật: ô hổ phách ghi giá VNĐ (gói xoá quảng cáo chỉ mua 1 lần)
		if bool(item_data.get("no_ads", false)) and Shop.is_owned(item_id):
			_use_done_style(btn, label, TranslationServer.translate("STR_SHOP_EQUIPPED"))
			return
		_set_info(btn, label, INFO_AMBER, Color(0.4196, 0.2667, 0.0), &"ShopBtnTextAmber")
		label.text = Shop.vnd_text(int(item_data.get("vnd", 0)))
		return
	if Shop.is_equipped(item_id):
		_use_done_style(btn, label, TranslationServer.translate("STR_SHOP_EQUIPPED"))
		return
	# Gói LƯỢT CHƠI đã đầy lượt ⇒ không mua thêm được
	if Shop.is_life_pack(item_id) and Life.is_full():
		_use_done_style(btn, label, TranslationServer.translate("STR_SHOP_LIFE_FULL"))
		return
	var owned := Shop.is_owned(item_id)
	_set_info(btn, label, INFO_BLUE, Color(0.1176, 0.3333, 0.4706), &"ShopBtnText")
	_affordable = owned or Shop.can_afford(item_id)
	_needs_confirm = not owned
	btn.modulate = Color(1, 1, 1, 1) if _affordable else Color(1, 1, 1, 0.55)
	if owned:
		label.text = TranslationServer.translate("STR_SHOP_USE")
	elif Shop.is_consumable(item_id):
		label.text = "%s  %s" % [TranslationServer.translate("STR_SHOP_BUY_MORE"), Shop.thousands(price)]
	else:
		label.text = TranslationServer.translate("STR_SHOP_PRICE_FORMAT").format([Shop.thousands(price)])


func _set_info(btn: TextureButton, label: Label, art: Texture2D, color: Color, variation: StringName) -> void:
	btn.texture_normal = art
	btn.texture_pressed = art
	btn.texture_hover = art
	btn.texture_disabled = art
	btn.modulate = Color(1, 1, 1, 1)
	label.theme_type_variation = variation
	label.add_theme_color_override("font_color", color)


## Trạng thái "xong" (ĐANG DÙNG / ĐÃ ĐẦY LƯỢT / ĐÃ SỞ HỮU): nền xanh nhạt + chữ xanh lục ĐẬM, dễ đọc
func _use_done_style(btn: TextureButton, label: Label, text: String) -> void:
	_set_info(btn, label, INFO_DONE, Color(0.0863, 0.3961, 0.2039), &"ShopBtnTextDone")
	_tappable = false
	label.text = text


func _set_label(path: String, text: String) -> void:
	var label := get_node_or_null(path) as Label
	if label != null:
		label.text = text


func _gui_input(event: InputEvent) -> void:
	match _tap.feed(event):
		ShopCardTap.Result.DOWN:
			ShopCardTap.press_fx(self, true)
		ShopCardTap.Result.TAP:
			ShopCardTap.press_fx(self, false)
			_on_card_tapped()
		ShopCardTap.Result.CANCEL:
			ShopCardTap.press_fx(self, false)


## CHẠM CẢ THẺ. Món TỐN XU: chạm lần 1 chọn (thẻ viền xanh), chạm lần 2 mới mua
func _on_card_tapped() -> void:
	if not _tappable:
		return
	if not _affordable:
		ShopCardTap.shake(self, get_node_or_null("Panel/Action") as Control)
		return
	if _needs_confirm and not ShopCardTap.is_armed(self):
		ShopCardTap.arm(self)
		_set_armed(true)
		return
	ShopCardTap.disarm()
	action_pressed.emit(item_id)


func _set_armed(on: bool) -> void:
	var panel := get_node_or_null("Panel") as NinePatchRect
	if panel != null:
		panel.texture = CARD_ARMED if on else CARD_NORMAL


func _on_disarmed() -> void:
	_set_armed(false)


## Giữ tương thích với kết nối cũ trong scene (nút giá không còn bấm riêng)
func _on_action_pressed() -> void:
	_on_card_tapped()
