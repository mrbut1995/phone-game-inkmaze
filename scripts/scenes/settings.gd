class_name SettingsScene
extends BaseScene
## ============================================================================
## View Controller: Màn hình Cài đặt (Settings)
## Bám theo mockup mockup/settings_screen.svg:
##   1. Âm thanh        : slider Nhạc nền (BGM) + Hiệu ứng (SFX)
##   2. Bàn cờ          : 3 tuỳ chọn bật/tắt (Haptic, auto-mark, glow path)
##   3. Ngôn ngữ & lưu trữ: dropdown chọn ngôn ngữ (mở popup), chip cloud, player ID
##   4. Hỗ trợ          : xem hướng dẫn, khôi phục cài đặt mặc định
##   5. Chân trang      : câu quote + con dấu phiên bản
## Cài đặt lưu qua SettingManager (/root) nên không tham chiếu autoload trực tiếp.
## ============================================================================

signal guide_requested

const PLAYER_ID_PLACEHOLDER := "#NM-8924-VN"
const UIAnim := preload("res://scripts/utils/ui_anim.gd")

## Node UI gắn lại mỗi lần ĐỔI HƯỚNG (2 layout dùng CÙNG tên node — bản ngang gom Âm thanh/Bàn cờ
## vào cột trái, Hệ thống/Thao tác vào cột phải nên ĐƯỜNG DẪN khác nhau ⇒ tra theo TÊN)
var btn_back: TextureButton = null
var bgm_slider: HSlider = null
var bgm_value: Label = null
var sfx_slider: HSlider = null
var sfx_value: Label = null
var chk_haptic: TextureButton = null
var chk_auto_mark: TextureButton = null
var chk_glow: TextureButton = null
var btn_language: TextureButton = null
var lbl_language: Label = null
var lbl_player_id: Label = null
var btn_guide: TextureButton = null
var btn_credits: TextureButton = null
var btn_reset: TextureButton = null
var lbl_version: Label = null

## Chặn ghi ngược khi đang đồng bộ UI từ SettingManager
var _syncing := false
## Số lần bấm vào con dấu phiên bản để mở màn debug
const DEBUG_TAP_COUNT := 5
var _stamp_taps := 0


func _ready() -> void:
	_bind_refs()
	_wire_buttons()
	orientation_changed.connect(_on_orientation_changed)

	var content_node := ui("Content") as Control
	if content_node != null:
		UIAnim.play_slide_in(content_node, Vector2(0, 25), 0.05, 0.25)

	_setup_debug_stamp_taps()
	_sync_from_settings()


## Gắn node của layout đang hiển thị
func _bind_refs() -> void:
	btn_back = ui_path("TopBar/Back") as TextureButton
	bgm_slider = ui_child("BgmRow", "Slider") as HSlider
	bgm_value = ui_child("BgmRow", "Value") as Label
	sfx_slider = ui_child("SfxRow", "Slider") as HSlider
	sfx_value = ui_child("SfxRow", "Value") as Label
	chk_haptic = ui_child("HapticRow", "Check") as TextureButton
	chk_auto_mark = ui_child("AutoMarkRow", "Check") as TextureButton
	chk_glow = ui_child("GlowRow", "Check") as TextureButton
	btn_language = ui_child("LangRow", "LangButton") as TextureButton
	lbl_language = ui_child("LangButton", "LangValue") as Label
	lbl_player_id = ui_child("PlayerRow", "PlayerIdValue") as Label
	btn_guide = ui("Guide") as TextureButton
	btn_credits = ui("Credits") as TextureButton
	btn_reset = ui("Reset") as TextureButton
	lbl_version = ui_child("Stamp", "Label") as Label


## Nối signal + hiệu ứng (mỗi NODE chỉ nối 1 lần — xoay màn hình không nhân đôi)
func _wire_once(node: Node) -> bool:
	if node == null or node.has_meta("wired"):
		return false
	node.set_meta("wired", true)
	return true


func _wire_buttons() -> void:
	if _wire_once(btn_back):
		btn_back.pressed.connect(_on_back_pressed)
		UIAnim.attach_press_bounce(btn_back)

	if _wire_once(bgm_slider):
		bgm_slider.value_changed.connect(_on_volume_changed.bind("music", bgm_value))
	if _wire_once(sfx_slider):
		sfx_slider.value_changed.connect(_on_volume_changed.bind("sfx", sfx_value))

	# TextureButton toggle: toggled(toggled_on) + bind khoá cài đặt tương ứng
	for pair in [
		[chk_haptic, "vibration"],
		[chk_auto_mark, "auto_mark_safe"],
		[chk_glow, "glow_path"],
	]:
		var check: TextureButton = pair[0]
		if _wire_once(check):
			check.toggled.connect(_on_toggle_changed.bind(str(pair[1])))
			UIAnim.attach_press_bounce(check)

	if _wire_once(btn_language):
		btn_language.pressed.connect(_on_language_pressed)
		UIAnim.attach_press_bounce(btn_language)
	if _wire_once(btn_guide):
		btn_guide.pressed.connect(_on_guide_pressed)
		UIAnim.attach_press_bounce(btn_guide)
	if _wire_once(btn_credits):
		btn_credits.pressed.connect(_on_credits_pressed)
		UIAnim.attach_press_bounce(btn_credits)
	if _wire_once(btn_reset):
		btn_reset.pressed.connect(_on_reset_pressed)
		UIAnim.attach_press_bounce(btn_reset)


## Xoay màn hình: gắn lại node của layout mới rồi nạp lại giá trị cài đặt lên widget mới
func _on_orientation_changed(_is_landscape_now: bool) -> void:
	_rebind_after_orientation.call_deferred()


func _rebind_after_orientation() -> void:
	_bind_refs()
	_wire_buttons()
	_setup_debug_stamp_taps()
	_sync_from_settings()


## Bấm liên tiếp vào con dấu phiên bản để mở màn debug (chỉ trong bản debug)
func _setup_debug_stamp_taps() -> void:
	if lbl_version == null:
		return
	var stamp := lbl_version.get_parent() as Control
	if stamp == null:
		return
	stamp.mouse_filter = Control.MOUSE_FILTER_STOP
	for child in stamp.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not stamp.gui_input.is_connected(_on_stamp_gui_input):
		stamp.gui_input.connect(_on_stamp_gui_input)


func _on_stamp_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse := event as InputEventMouseButton
	if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	_stamp_taps += 1
	if _stamp_taps < DEBUG_TAP_COUNT:
		return
	_stamp_taps = 0
	var dbg: Node = get_node_or_null("/root/DebugManager")
	if dbg != null:
		dbg.call("toggle_console")


# ---------------------------------------------------------------------------
# Đồng bộ UI <-> SettingManager
# ---------------------------------------------------------------------------
func _sm() -> Node:
	return get_node_or_null("/root/SettingManager")


func _sync_from_settings() -> void:
	_syncing = true
	var sm := _sm()
	if sm != null:
		if bgm_slider != null:
			bgm_slider.value = float(sm.get("music_volume"))
		if sfx_slider != null:
			sfx_slider.value = float(sm.get("sfx_volume"))
		if chk_haptic != null:
			chk_haptic.button_pressed = bool(sm.get("vibration"))
		if chk_auto_mark != null:
			chk_auto_mark.button_pressed = bool(sm.get("auto_mark_safe"))
		if chk_glow != null:
			chk_glow.button_pressed = bool(sm.get("glow_path"))
	_update_volume_labels()
	_refresh_language()
	_refresh_version()
	_syncing = false


func _update_volume_labels() -> void:
	if bgm_value != null and bgm_slider != null:
		bgm_value.text = _to_percent(bgm_slider.value)
	if sfx_value != null and sfx_slider != null:
		sfx_value.text = _to_percent(sfx_slider.value)


func _to_percent(value: float) -> String:
	return "%d%%" % roundi(value * 100.0)


func _refresh_language() -> void:
	if lbl_language != null:
		lbl_language.text = Loc.display_name(Loc.current())


func _refresh_version() -> void:
	if lbl_version != null:
		var app := get_node_or_null("/root/AppManager")
		var version := "1.0.0"
		if app != null:
			version = str(app.call("get_version"))
		lbl_version.text = tr("STR_SETTINGS_VERSION").format([version])
	if lbl_player_id != null:
		lbl_player_id.text = PLAYER_ID_PLACEHOLDER


# ---------------------------------------------------------------------------
# Âm thanh
# ---------------------------------------------------------------------------
func _on_volume_changed(value: float, kind: String, label: Label) -> void:
	_update_volume_labels()
	if _syncing:
		return
	var sm := _sm()
	if sm != null:
		sm.call("set_volume", kind, value)
	if label != null:
		label.text = _to_percent(value)
	# SFX: tiếng thước kẻ trượt khi kéo thanh âm lượng
	Sfx.play(Sfx.SLIDER_TICK)


# ---------------------------------------------------------------------------
# Tuỳ chọn bật/tắt
# ---------------------------------------------------------------------------
func _on_toggle_changed(toggled_on: bool, key: String) -> void:
	if _syncing:
		return
	var sm := _sm()
	if sm != null:
		sm.call("set_setting", key, toggled_on)
	# SFX: tiếng bút bi vẽ dấu tích
	Sfx.play(Sfx.CHECKBOX)


# ---------------------------------------------------------------------------
# Ngôn ngữ
# ---------------------------------------------------------------------------
func _on_language_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	# Popup được PopupManager tạo khi mở và xoá khi đóng
	var popup := Popups.open(Popups.LANGUAGE)
	if popup == null:
		return
	if not popup.is_connected("locale_applied", _on_locale_applied):
		popup.connect("locale_applied", _on_locale_applied)


func _on_locale_applied(_code: String) -> void:
	_refresh_language()


# ---------------------------------------------------------------------------
# Hỗ trợ & khôi phục mặc định
# ---------------------------------------------------------------------------
func _on_guide_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	# TODO: mở màn "Hướng dẫn & 9 bộ luật chơi" khi có scene tương ứng
	push_warning("[Settings] Chưa có scene hướng dẫn - cần bổ sung sau.")
	guide_requested.emit()


func _on_credits_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	Nav.goto_credit()


func _on_reset_pressed() -> void:
	var sm := _sm()
	if sm != null:
		sm.call("reset_to_defaults")
	# SFX: tiếng "cộp" con dấu khi khôi phục mặc định
	Sfx.play(Sfx.STAMP_IMPACT)
	_sync_from_settings()


# ---------------------------------------------------------------------------
# Điều hướng
# ---------------------------------------------------------------------------
func _on_back_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("go_to_main_menu"):
		gm.call("go_to_main_menu")
	else:
		Nav.goto_main()
