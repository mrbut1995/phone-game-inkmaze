extends Node
## ============================================================================
## Manager: SaveManager - Lưu/đọc dữ liệu người chơi qua backend thay thế được.
##
## - Hiện tại: LocalSaveBackend (local, user://...). Khi phát hành lên Google Play
##   chỉ cần `Save.use_play_games()` -> xem PlayGamesSaveBackend + TODO.txt.
## - Các manager tham gia lưu trữ chỉ cần cài 2 hàm:
##       export_progress() -> Dictionary
##       import_progress(data: Dictionary) -> void
##   Khoá trong blob là TÊN NODE của provider ("GameManager", "DailyManager"...).
## - Tự lưu có debounce (0.6s) + flush khi app bị ẩn/thoát.
## ============================================================================

signal data_loaded(source: String)
signal data_saved(source: String, ok: bool)
signal backend_changed(source: String)
signal cloud_state_changed(state: String)

const LOCAL := "local"
const PLAY_GAMES := "play_games"
const SAVE_VERSION := 1
const AUTOSAVE_DELAY := 0.6

var backend: SaveBackend = null
var last_save_ok := true

var _providers: Array[Node] = []
var _timer: Timer = null
var _booted := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = AUTOSAVE_DELAY
	_timer.timeout.connect(flush)
	add_child(_timer)

	backend = LocalSaveBackend.new()
	# Các autoload khác đã _ready() xong trước SaveManager (xem project.godot)
	_ensure_ready()


## Đăng ký provider + nạp dữ liệu (chạy 1 lần, gọi lazy để không bao giờ lưu khi chưa sẵn sàng)
func _ensure_ready() -> void:
	if _booted:
		return
	var tree := get_tree()
	if tree == null or tree.root == null:
		return
	_booted = true

	register_provider(tree.root.get_node_or_null("GameManager"), "level_completed")
	register_provider(tree.root.get_node_or_null("DailyManager"), "daily_changed")
	register_provider(tree.root.get_node_or_null("ArchivementManager"), "progress_changed")

	var app: Node = tree.root.get_node_or_null("AppManager")
	if app != null and app.has_signal("app_paused") and not app.is_connected("app_paused", _on_app_paused):
		app.connect("app_paused", _on_app_paused)

	load_all()


# --- Provider ---------------------------------------------------------------

## Đăng ký một manager có tham gia lưu trữ (cần export_progress/import_progress)
func register_provider(provider: Node, autosave_signal := "") -> bool:
	if provider == null or _providers.has(provider):
		return false
	if not (provider.has_method("export_progress") and provider.has_method("import_progress")):
		push_warning("[SaveManager] '%s' thieu export_progress/import_progress" % provider.name)
		return false
	_providers.append(provider)
	if not autosave_signal.is_empty() and provider.has_signal(autosave_signal):
		if not provider.is_connected(autosave_signal, _on_provider_changed):
			provider.connect(autosave_signal, _on_provider_changed)
	return true


func providers() -> Array[Node]:
	return _providers.duplicate()


# --- Đọc / ghi --------------------------------------------------------------

## Gom dữ liệu hiện tại của mọi provider thành 1 blob để lưu
func collect() -> Dictionary:
	_ensure_ready()
	var blob := {
		"version": SAVE_VERSION,
		"saved_at": Time.get_unix_time_from_system(),
	}
	for provider in _providers:
		blob[provider.name] = provider.call("export_progress")
	return blob


## Đẩy blob vào lại các provider (dùng cho cả load local lẫn cloud)
func apply(blob: Dictionary) -> void:
	if blob.is_empty():
		return
	for provider in _providers:
		var section: Variant = blob.get(provider.name, null)
		if section is Dictionary and not (section as Dictionary).is_empty():
			provider.call("import_progress", section)


## Nạp dữ liệu từ backend hiện tại và áp vào các provider
func load_all() -> Dictionary:
	_ensure_ready()
	var blob := backend.load_data()
	apply(blob)
	data_loaded.emit(backend.id())
	return blob


## Lưu ngay (không chờ debounce)
func save_now() -> bool:
	var ok := backend.save_data(collect())
	last_save_ok = ok
	data_saved.emit(backend.id(), ok)
	return ok


## Hẹn lưu sau một nhịp (gộp nhiều thay đổi liên tiếp)
func queue_save() -> void:
	if _timer != null:
		_timer.start()


## Lưu ngay nếu đang có thay đổi chờ
func flush() -> void:
	if _timer != null:
		_timer.stop()
	save_now()


# --- Backend ----------------------------------------------------------------

## Đổi nơi lưu ("local" hoặc "play_games"). Trả về true nếu đổi thành công.
func set_backend(kind: String) -> bool:
	var next: SaveBackend = PlayGamesSaveBackend.new() if kind == PLAY_GAMES else LocalSaveBackend.new()
	if next == null or not next.is_available():
		push_warning("[SaveManager] Backend '%s' chua san sang, van dung '%s'" % [kind, backend.id()])
		cloud_state_changed.emit("unavailable")
		return false

	backend = next
	backend_changed.emit(backend.id())
	# TODO(google-play): khi có cloud, cần MERGE dữ liệu local + cloud theo
	# `saved_at` và tiến trình (không ghi đè thẳng như dưới đây).
	if backend.supports_cloud():
		load_all()
	return true


func is_cloud() -> bool:
	return backend != null and backend.supports_cloud()


func cloud_available() -> bool:
	return PlayGamesSaveBackend.new().is_available()


## Xoá dữ liệu đã lưu (dùng cho nút "xoá tiến trình")
func reset_all() -> void:
	backend.clear_data()
	for provider in _providers:
		if provider.has_method("reset_progress"):
			provider.call("reset_progress")
	save_now()


# --- Nội bộ -----------------------------------------------------------------

func _on_provider_changed(_a: Variant = null, _b: Variant = null, _c: Variant = null) -> void:
	queue_save()


func _on_app_paused() -> void:
	flush()


func _notification(what: int) -> void:
	# Lưu trước khi app bị hệ điều hành thu hồi / người chơi thoát game
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST, NOTIFICATION_APPLICATION_PAUSED:
			if backend != null:
				flush()
