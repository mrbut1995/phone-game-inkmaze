extends Node
## ============================================================================
## Manager: LocalizationManager - Quản lý ngôn ngữ hiển thị (vi/en).
## - Dùng TranslationServer của Godot; lựa chọn lưu qua SettingManager (key "locale").
## ============================================================================

signal locale_changed(locale: String)

const SUPPORTED_LOCALES := ["vi", "en"]
const DEFAULT_LOCALE := "vi"

var current_locale := DEFAULT_LOCALE


func _ready() -> void:
	var sm: Variant = get_node_or_null("/root/SettingManager")
	var saved := DEFAULT_LOCALE
	if sm != null:
		saved = str(sm.call("get_setting", "locale", DEFAULT_LOCALE))
	set_locale(saved, false)


func set_locale(code: String, save := true) -> void:
	if not SUPPORTED_LOCALES.has(code):
		code = DEFAULT_LOCALE
	current_locale = code
	TranslationServer.set_locale(code)
	locale_changed.emit(code)
	if save:
		var sm: Variant = get_node_or_null("/root/SettingManager")
		if sm != null:
			sm.call("set_setting", "locale", code)


## Chuyển sang ngôn ngữ kế tiếp trong danh sách hỗ trợ
func cycle_locale() -> void:
	var index := SUPPORTED_LOCALES.find(current_locale)
	var next_index := posmod(index + 1, SUPPORTED_LOCALES.size())
	set_locale(SUPPORTED_LOCALES[next_index])


func is_supported(code: String) -> bool:
	return SUPPORTED_LOCALES.has(code)


## Wrapper cho tr() để code gọi ngắn gọn: LocalizationManager.t("KEY")
func t(key: String) -> String:
	return tr(key)
