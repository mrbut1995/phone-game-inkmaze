extends Node
## ============================================================================
## Manager: SfxManager - Phát hiệu ứng âm thanh (SFX) toàn cục.
##
## Phong cách SFX: "văn phòng phẩm / sổ tay học sinh" (bút chì, gôm tẩy, lật
## giấy, con dấu, kalimba...). Danh mục đầy đủ + tình huống kích hoạt xem file
## `sfx_suggestion.txt` ở thư mục gốc dự án.
##
## Đặc điểm:
##   - Pool AudioStreamPlayer: nhiều âm phát chồng nhau KHÔNG bị cắt tiếng.
##   - Random pitch nhẹ 0.92 - 1.08 cho các âm lặp lại (bút chì, bước chân)
##     để tai không bị mỏi khi người chơi thao tác liên tục.
##   - Hỗ trợ âm LOOP (tiếng miết bút khi đang kéo vẽ đường đi).
##   - Volume lấy từ SettingManager: bus Master đã do SettingManager áp dụng,
##     ở đây chỉ nhân thêm volume riêng của kênh SFX.
## ============================================================================

signal sfx_played(sfx_name: String)

## Danh mục tên SFX + file tương ứng nằm trong class helper `Sfx`
## (res://scripts/utils/sfx.gd) để mọi script gọi an toàn: Sfx.play(Sfx.BTN_CLICK)
const POOL_SIZE := 12
## ±8% => pitch 0.92..1.08 (đúng gợi ý trong sfx_suggestion.txt)
const DEFAULT_PITCH_JITTER := 0.08
## Khoảng lặp tối thiểu (giây) để 1 SFX không bị phát dồn dập chói tai
const MIN_REPEAT_INTERVAL := 0.04
## Quãng 3 nốt Đồ - Mi - Son cho 3 ngôi sao
const STAR_PITCHES := [1.0, 1.125, 1.25]

var _players: Array[AudioStreamPlayer] = []
var _loop_players: Dictionary = {}      # sfx_name -> AudioStreamPlayer
var _stream_cache: Dictionary = {}      # sfx_name -> AudioStream
var _last_played_ms: Dictionary = {}    # sfx_name -> ticks
var _warned: Dictionary = {}
var _sfx_gain := 1.0
var _next_player := 0


func _ready() -> void:
	_build_pool()
	_refresh_gain()
	var sm: Variant = get_node_or_null("/root/SettingManager")
	if sm != null and sm.has_signal("volume_changed"):
		sm.connect("volume_changed", _on_volume_changed)


# ---------------------------------------------------------------------------
# API chính
# ---------------------------------------------------------------------------
## Phát 1 SFX một lần. Trả về player đang phát (null nếu bị chặn / thiếu file).
func play(sfx_name: String, jitter := DEFAULT_PITCH_JITTER, volume_db := 0.0, pitch := 1.0) -> AudioStreamPlayer:
	var stream := _get_stream(sfx_name)
	if stream == null:
		return null

	# Chống phát trùng 1 SFX quá nhanh (ví dụ signal bị bắn 2 lần)
	var now_ms := Time.get_ticks_msec()
	var last_ms: int = int(_last_played_ms.get(sfx_name, -100000))
	if now_ms - last_ms < int(MIN_REPEAT_INTERVAL * 1000.0):
		return null
	_last_played_ms[sfx_name] = now_ms

	var player := _take_player()
	player.stream = stream
	player.pitch_scale = clampf(pitch + randf_range(-jitter, jitter), 0.05, 4.0)
	player.volume_db = _gain_to_db() + volume_db
	player.play()
	sfx_played.emit(sfx_name)
	return player


## Nút bấm UI: nút chính = bút bi (click), nút phụ = gõ thẻ giấy (thud).
func ui_click(secondary := false) -> void:
	play(Sfx.BTN_WOOD_TAP if secondary else Sfx.BTN_CLICK, 0.04)


## Ngôi sao thứ `index` (0..2) vang theo quãng Đồ - Mi - Son.
func star_pop(index: int) -> void:
	var i := clampi(index, 0, STAR_PITCHES.size() - 1)
	play(Sfx.STAR_POP, 0.0, 0.0, float(STAR_PITCHES[i]))


## Phát âm lặp liên tục (tiếng miết bút khi đang kéo vẽ đường đi).
func play_loop(sfx_name: String, volume_db := -5.0) -> void:
	if _loop_players.has(sfx_name):
		return
	var loop_stream := _make_looped(_get_stream(sfx_name))
	if loop_stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.name = "Loop_%s" % sfx_name
	player.stream = loop_stream
	player.volume_db = _gain_to_db() + volume_db
	player.set_meta("base_volume_db", volume_db)
	add_child(player)
	player.play()
	_loop_players[sfx_name] = player


func stop_loop(sfx_name: String) -> void:
	if not _loop_players.has(sfx_name):
		return
	var player: AudioStreamPlayer = _loop_players[sfx_name]
	player.stop()
	player.queue_free()
	_loop_players.erase(sfx_name)


func stop_all() -> void:
	for player in _players:
		player.stop()
	for sfx_name in _loop_players.keys():
		stop_loop(str(sfx_name))


# ---------------------------------------------------------------------------
# Nội bộ
# ---------------------------------------------------------------------------
func _build_pool() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % i
		add_child(player)
		_players.append(player)


func _take_player() -> AudioStreamPlayer:
	for i in _players.size():
		var idx := (_next_player + i) % _players.size()
		if not _players[idx].playing:
			_next_player = (idx + 1) % _players.size()
			return _players[idx]
	# Tất cả đang phát -> lấy luân phiên (âm cũ nhất bị thay)
	var fallback := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	fallback.stop()
	return fallback


func _get_stream(sfx_name: String) -> AudioStream:
	if _stream_cache.has(sfx_name):
		return _stream_cache[sfx_name]
	if not Sfx.LIBRARY.has(sfx_name):
		_warn_once("unknown_%s" % sfx_name, "SFX '%s' không có trong Sfx.LIBRARY" % sfx_name)
		return null
	var path := Sfx.SOUND_DIR + str(Sfx.LIBRARY[sfx_name])
	if not ResourceLoader.exists(path):
		_warn_once("missing_%s" % sfx_name, "Thiếu file SFX: %s" % path)
		return null
	var stream := load(path) as AudioStream
	if stream == null:
		_warn_once("load_%s" % sfx_name, "Không load được SFX: %s" % path)
		return null
	_stream_cache[sfx_name] = stream
	return stream


## Tạo bản loop từ stream gốc (không làm thay đổi resource gốc đang cache).
func _make_looped(source: AudioStream) -> AudioStream:
	if source == null:
		return null
	var loop_stream: AudioStream = source.duplicate()
	if loop_stream is AudioStreamWAV:
		(loop_stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif loop_stream is AudioStreamMP3:
		(loop_stream as AudioStreamMP3).loop = true
	return loop_stream


func _warn_once(key: String, message: String) -> void:
	if _warned.has(key):
		return
	_warned[key] = true
	push_warning("[SfxManager] " + message)


func _gain_to_db() -> float:
	return linear_to_db(maxf(_sfx_gain, 0.0001)) if _sfx_gain > 0.0 else -80.0


func _refresh_gain() -> void:
	var sm: Variant = get_node_or_null("/root/SettingManager")
	_sfx_gain = clampf(float(sm.get("sfx_volume")) if sm != null else 1.0, 0.0, 1.0)


func _on_volume_changed(kind: String, value: float) -> void:
	if kind != "sfx":
		return
	_sfx_gain = clampf(value, 0.0, 1.0)
	for player in _players:
		if player.playing:
			player.volume_db = _gain_to_db()
	for player: AudioStreamPlayer in _loop_players.values():
		player.volume_db = _gain_to_db() + float(player.get_meta("base_volume_db", -5.0))
