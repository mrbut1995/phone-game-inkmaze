class_name CreditScene
extends BaseScene
## ============================================================================
## View Controller: Credit Scene
## - Hiển thị thông tin soundtrack nền + attribution bản quyền.
## - Hiển thị theme giấy đang dùng để người chơi thấy nhạc đổi theo theme.
## ============================================================================

const UIAnim := preload("res://scripts/utils/ui_anim.gd")

## Node UI của màn nằm trong BỐ CỤC đang hiển thị (`Portrait` / `Landscape` — 2 hướng dùng
## CÙNG tên node). Các node đã BIND SẴN bằng `@export` trong `scenes/layout/<hướng>/credit.tscn`
## ⇒ code đọc qua `layout.<tên>`, KHÔNG tra đường dẫn; thêm/đổi node chỉ cần sửa scene + export.
var layout: CreditLayout = null


## Gắn node của layout đang hiển thị (2 layout giữ CÙNG đường dẫn node)
func _bind_refs() -> void:
	layout = active_layout() as CreditLayout
	if layout == null:
		push_warning("credit: bố cục chưa gắn CreditLayout — thiếu binding trong scenes/layout/<hướng>/credit.tscn")


func _ready() -> void:
	_bind_refs()
	if layout.btn_back != null:
		layout.btn_back.pressed.connect(_on_back_pressed)
		UIAnim.attach_press_bounce(layout.btn_back)
	if layout.content_root != null:
		UIAnim.play_slide_in(layout.content_root, Vector2(0, 24), 0.04, 0.24)
	_apply_credit_context()
	_bind_theme_signal()
	_bind_music_signal()
	_refresh_all()


func _apply_credit_context() -> void:
	var music := _music_manager()
	if music != null and music.has_method("set_context"):
		music.call("set_context", "credits", true)


func _bind_theme_signal() -> void:
	var themes: Variant = get_node_or_null("/root/ThemeManager")
	if themes == null or not themes.has_signal("skin_changed"):
		return
	var cb := Callable(self, "_on_skin_changed")
	if not themes.is_connected("skin_changed", cb):
		themes.connect("skin_changed", cb)


func _bind_music_signal() -> void:
	var music := _music_manager()
	if music == null or not music.has_signal("soundtrack_changed"):
		return
	var cb := Callable(self, "_on_soundtrack_changed")
	if not music.is_connected("soundtrack_changed", cb):
		music.connect("soundtrack_changed", cb)


func _refresh_all() -> void:
	_refresh_theme_name()
	_refresh_track_name()
	_refresh_version()


func _refresh_theme_name() -> void:
	if layout.theme_value == null:
		return
	var fallback := tr("STR_SHOP_THEME_4LY_NAME")
	var shop: Variant = get_node_or_null("/root/ShopManager")
	if shop == null or not shop.has_method("item"):
		layout.theme_value.text = fallback
		return
	var theme_id := str(shop.get("equipped_theme"))
	var data: Variant = shop.call("item", theme_id)
	if data is Dictionary and data.has("name_key"):
		layout.theme_value.text = tr(str(data.get("name_key")))
		return
	layout.theme_value.text = fallback


func _refresh_track_name() -> void:
	if layout.track_value == null:
		return
	var music := _music_manager()
	var track_name := "Wallpaper"
	if music != null and music.has_method("current_track_name"):
		var value := str(music.call("current_track_name"))
		if not value.is_empty():
			track_name = value
	layout.track_value.text = track_name


func _refresh_version() -> void:
	if layout.version_label == null:
		return
	var app := get_node_or_null("/root/AppManager")
	var version := "1.0.0"
	if app != null:
		version = str(app.call("get_version"))
	layout.version_label.text = tr("STR_SETTINGS_VERSION").format([version])


func _music_manager() -> Node:
	return get_node_or_null("/root/MusicManager")


func _on_skin_changed(_theme_id: String, _pen_id: String) -> void:
	_refresh_theme_name()


func _on_soundtrack_changed(_track_path: String, _theme_id: String, _context_name: String) -> void:
	_refresh_track_name()


func _on_back_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	var screen: Variant = get_node_or_null("/root/ScreenManager")
	if screen != null and screen.has_method("go_back") and bool(screen.call("go_back")):
		return
	Nav.goto_settings()
