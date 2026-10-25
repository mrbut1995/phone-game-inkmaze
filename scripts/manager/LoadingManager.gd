extends Node
## ============================================================================
## Autoload: LoadingManager — quản lý việc NẠP / KHỞI ĐỘNG của game.
##
## VÌ SAO CẦN: `_ready()` của autoload chạy TRƯỚC frame vẽ đầu tiên, nên mọi việc nạp nặng
## đặt ở đó đều trở thành "màn hình trống" ngay sau icon app (thấy rõ trên Android).
## Manager này gom HAI loại việc nạp và chạy chúng RẢI RA nhiều frame SAU frame Splash đầu tiên:
##   1. `add_step()` — autoload nặng (Dịch · Hồ sơ · Danh hiệu · Event…) đăng ký `initialize()`.
##   2. `PRELOAD_SCENES` — nạp sẵn scene dùng ngay sau Splash (Title · Main · Chọn Màn).
##
## Màn Splash đọc `progress()` để vẽ thanh tiến trình và chờ `loading_finished` rồi mới sang màn kế tiếp.
## Chạy headless (`godot --headless --script`, test/CI) thì nạp + preload NGAY trong `_ready()`
## ⇒ test giữ nguyên hành vi và không phải chờ thêm frame.
## ============================================================================

signal loading_finished
signal progress_changed(progress: float, label: String)

## Scene nạp sẵn để màn kế tiếp mở tức thì (thêm/bớt chỉ cần sửa danh sách này)
const PRELOAD_SCENES := [
	"res://scenes/title.tscn",
	"res://scenes/main.tscn",
	"res://scenes/levels.tscn",
]

## Số frame nhường trước khi chạy bước đầu (để engine vẽ xong frame Splash đầu tiên)
const FIRST_FRAME_DELAY := 1

## Thời gian nhường TRƯỚC bước nặng đầu tiên. Mỗi `initialize()` chặn main thread 65–230 ms,
## nếu chạy ngay thì animation logo/title ở màn Splash bị nhảy cóc từng cục. Hoạt ảnh
## `play_entrance` của layout chạy tới 0,8 s ⇒ nhường 0,82 s để nó chạy trọn ở 60 fps.
const VISUAL_GRACE_SEC := 0.82

## Bước nạp: { "label": String, "step": Callable } — chạy theo đúng thứ tự đăng ký
var _steps: Array[Dictionary] = []
## Scene đã nạp sẵn — GIỮ THAM CHIẾU để tài nguyên không bị thu hồi khỏi cache
var _preloaded: Array[Resource] = []
var _started := false
var _done := false
var _finished := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() == "headless":
		# Không có màn Splash để chờ ⇒ nạp + preload ngay (test/harness giữ hành vi cũ)
		_done = true
		_run_all_now()
		return
	# Vào hàng đợi nạp nền NGAY: 3 scene dùng ngay sau Splash được giải nén song song trong
	# lúc chờ hoạt ảnh logo ⇒ không tốn thêm thời gian khởi động.
	_request_preloads()
	# Lưới an toàn: nếu màn đầu tiên KHÔNG phải Splash thì vẫn phải nạp (đổi main scene, dev…)
	call_deferred("_auto_start")


# ---------------------------------------------------------------------------
# API
# ---------------------------------------------------------------------------

## Xong hết chưa (màn Splash dùng để biết khi nào được sang màn kế tiếp)
func is_loading_done() -> bool:
	return _done


## Tiến độ 0..1
func progress() -> float:
	var total := _steps.size()
	if _done or total == 0:
		return 1.0
	return clampf(float(_finished) / float(total), 0.0, 1.0)


## Số bước còn lại (dev/debug)
func pending_steps() -> int:
	return maxi(_steps.size() - _finished, 0)


## Tên bước đang chạy (dev/debug) — KHÔNG hiện cho người chơi
func current_label() -> String:
	if _done or _finished >= _steps.size():
		return ""
	return str(_steps[_finished].get("label", ""))


## Autoload nặng gọi trong `_ready()`: hoãn `initialize()` tới khi màn Splash đã hiện.
## Đã nạp xong (hoặc chạy headless) thì gọi NGAY để không ai phải chờ.
func add_step(step: Callable, label := "") -> void:
	if not step.is_valid():
		return
	if _done:
		step.call()
		return
	var step_label := label if not label.is_empty() else str(step.get_method())
	_steps.append({"label": step_label, "step": step})


## Bắt đầu nạp (màn Splash gọi khi sẵn sàng; gọi nhiều lần vô hại)
func start() -> void:
	if _started or _done:
		return
	_started = true
	_append_preload_steps()
	_run()


func _auto_start() -> void:
	await get_tree().process_frame
	start()


# ---------------------------------------------------------------------------
# Nội bộ
# ---------------------------------------------------------------------------

## Xếp scene cần nạp sẵn vào CUỐI danh sách bước (sau các `initialize()` của autoload)
func _append_preload_steps() -> void:
	for path in PRELOAD_SCENES:
		if not ResourceLoader.exists(path):
			push_warning("[LoadingManager] Không thấy scene để nạp sẵn: %s" % path)
			continue
		_steps.append({
			"label": path.get_file(),
			"step": Callable(self, "_load_scene").bind(path),
			"path": path,
		})


## Đưa các scene cần nạp sẵn vào hàng đợi của ResourceLoader (chạy ở luồng nền)
func _request_preloads() -> void:
	for path in PRELOAD_SCENES:
		if ResourceLoader.exists(path):
			ResourceLoader.load_threaded_request(path, "PackedScene", true)


func _load_scene(path: String) -> void:
	var packed := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_REUSE)
	if packed == null:
		push_warning("[LoadingManager] Nạp sẵn thất bại: %s" % path)
		return
	_preloaded.append(packed)


## Nạp scene ở luồng nền: chỉ chờ frame, KHÔNG chặn main thread ⇒ Splash giữ 60 fps
func _load_scene_threaded(path: String) -> void:
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		ResourceLoader.load_threaded_request(path, "PackedScene", true)
		status = ResourceLoader.load_threaded_get_status(path)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status(path)
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		push_warning("[LoadingManager] Nạp nền thất bại, nạp đồng bộ: %s" % path)
		_load_scene(path)
		return
	var packed := ResourceLoader.load_threaded_get(path)
	if packed == null:
		push_warning("[LoadingManager] Nạp sẵn thất bại: %s" % path)
		return
	_preloaded.append(packed)


func _run() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for i in FIRST_FRAME_DELAY:
		await tree.process_frame
	# Nhường thời gian cho hoạt ảnh mở màn (logo/title) chạy mượt trước khi chặn main thread
	await tree.create_timer(VISUAL_GRACE_SEC).timeout
	for entry in _steps:
		if entry.has("path"):
			await _load_scene_threaded(str(entry["path"]))
		else:
			var step: Callable = entry.get("step")
			if step.is_valid():
				step.call()
		_finished += 1
		progress_changed.emit(progress(), str(entry.get("label", "")))
		# Nhường 1 frame mỗi bước: hoạt ảnh Splash tiếp tục chạy trong lúc nạp nền
		await tree.process_frame
	_done = true
	progress_changed.emit(1.0, "")
	loading_finished.emit()


## Chế độ headless: nạp + preload NGAY, không chờ frame nào
func _run_all_now() -> void:
	_append_preload_steps()
	for entry in _steps:
		var step: Callable = entry.get("step")
		if step.is_valid():
			step.call()
	_finished = _steps.size()
