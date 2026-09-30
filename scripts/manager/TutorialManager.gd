extends Node
## ============================================================================
## Manager: TutorialManager — điều phối LUỒNG HỌC LẦN ĐẦU (onboarding) và
## TUTORIAL LẦN ĐẦU THEO CHẾ ĐỘ.
##
## LUỒNG ONBOARDING (chạy khi người chơi mới bấm Bắt đầu ở Title):
##   first_time → how_to_play_move → MÀN 1 → how_to_play_checking_wall
##   → MÀN 2 → how_to_use_tool → MÀN 3 → MÀN 4 → xong.
##   Vị trí bước lưu trong GameManager (`tutorial_flow_step` · `tutorial_flow_done`)
##   nên thoát giữa chừng vẫn chạy tiếp đúng chỗ ở lần mở sau.
##
## TUTORIAL THEO CHẾ ĐỘ: chế độ Special (minesweeper · blind_memory · …) tự mở bài
## học của nó LẦN ĐẦU người chơi vào chế độ — dù vào từ Daily hay từ màn có `mode_id`
## (xem `GameManager.start_level` / `start_daily`).
## ============================================================================

## Các bước của luồng onboarding: bài học xen kẽ MÀN THỰC HÀNH
const FLOW: Array[Dictionary] = [
	{"kind": "tutorial", "id": "first_time"},
	{"kind": "tutorial", "id": "how_to_play_move"},
	{"kind": "level", "id": 1},
	{"kind": "tutorial", "id": "how_to_play_checking_wall"},
	{"kind": "level", "id": 2},
	{"kind": "tutorial", "id": "how_to_use_tool"},
	{"kind": "level", "id": 3},
	{"kind": "level", "id": 4},
	{"kind": "tutorial", "id": "congrats_first_time"},
]

## MÀN THỰC HÀNH → bài học của nó: đang trong luồng thì nút "?" của màn chỉ mở ĐÚNG
## bài của màn đó (không mở cả 3 bài cơ bản như bình thường).
const PRACTICE_TUTORIALS: Dictionary = {
	1: "how_to_play_move",
	2: "how_to_play_checking_wall",
	3: "how_to_use_tool",
}

## Chế độ Special → bài học mở LẦN ĐẦU khi người chơi vào chế độ đó
const MODE_TUTORIALS: Dictionary = {
	"minesweeper": "how_to_play_minesweeper",
	"one_stroke": "how_to_play_one_stroke",
	"sum_path": "how_to_play_sum_path",
	"countdown_cost": "how_to_play_countdown_cost",
	"blind_memory": "how_to_play_blind_memory",
	"fog_of_war": "how_to_play_fog_of_war",
	"fading_ink": "how_to_play_fading_ink",
	"wall_builder": "how_to_play_wall_builder",
}

## Luồng onboarding đang chạy (đang chờ người chơi học bài / chơi màn của luồng)
var flow_active := false
var _flow_index := 0
## Màn sẽ mở ngay sau khi luồng kết thúc (bài CHÚC MỪNG chọn "bàn tiếp theo"; 0 = về Main)
var _next_level_after_flow := 0

const NAV := preload("res://scripts/utils/nav.gd")


# ---------------------------------------------------------------------------
# LUỒNG ONBOARDING
# ---------------------------------------------------------------------------
## Người chơi mới (chưa học xong luồng lần đầu) — Title hỏi trước khi vào Main
func needs_onboarding() -> bool:
	var gm := _game_manager()
	return gm != null and not bool(gm.get("tutorial_flow_done"))


## Bắt đầu/tiếp tục luồng (gọi từ Title). Trả true nếu ĐÃ điều hướng (không vào Main).
func start_onboarding() -> bool:
	if not needs_onboarding():
		return false
	flow_active = true
	_next_level_after_flow = 0
	_flow_index = _saved_step()
	return _open_step(_take_step())


## TutorialScene gọi khi 1 BÀI của luồng vừa học xong: chạy tiếp bước kế.
## Trả {"next": id} = màn Tutorial tự chạy tiếp bài này (không đổi scene) ·
## {"level": N} = đã sang màn chơi · {} = luồng đã kết thúc.
func continue_flow_inplace() -> Dictionary:
	if not flow_active:
		return {}
	_flow_index += 1
	var step := _take_step()
	if step.is_empty():
		# Hết luồng: bài CHÚC MỪNG đã chọn "CHƠI BÀN TIẾP THEO" thì vào luôn màn đó
		if _next_level_after_flow > 0:
			var queued_level := _next_level_after_flow
			_next_level_after_flow = 0
			_start_level(queued_level)
			return {"level": queued_level}
		return {}
	if str(step.get("kind", "")) == "tutorial":
		return {"next": str(step.get("id", ""))}
	var level_id := int(step.get("id", 1))
	_start_level(level_id)
	return {"level": level_id}


## TutorialScene gọi khi vừa học xong 1 BÀI THỰC HÀNH mở từ nút "?" của màn chơi:
## nếu BƯỚC HIỆN TẠI của luồng đang là 1 BÀI HỌC chưa học thì trả id bài đó để màn Tutorial
## chạy tiếp NGAY TRONG MÀN — thay vì nhảy về màn chơi (màn chơi bị khởi động lại + nháy
## màn hình) rồi mới mở bài.
## Trả "" khi: luồng không chạy · luồng đã xong · bước hiện tại là MÀN CHƠI (phải chơi tiếp).
func resume_flow_lesson() -> String:
	if not flow_active:
		return ""
	var step := _take_step()
	if step.is_empty() or str(step.get("kind", "")) != "tutorial":
		return ""
	return str(step.get("id", ""))


## GameController gọi khi 1 MÀN vừa hoàn thành. Trả true nếu luồng đã điều hướng tiếp
## (mở bài học / màn kế của luồng), false nếu cứ đi tiếp như bình thường.
func on_level_finished(level_id: int) -> bool:
	if not flow_active:
		return false
	var index := _index_of_level(level_id)
	if index < 0:
		return false
	_flow_index = maxi(_flow_index, index + 1)
	return _open_step(_take_step())


## "Bỏ qua tất cả" (nút ở first_time): kết thúc luồng, không mở thêm bài nào
func abort_flow() -> void:
	_next_level_after_flow = 0
	_finish_flow()


## Bài CHÚC MỪNG (bước cuối luồng) gọi khi người chơi chọn "CHƠI BÀN TIẾP THEO":
## nhớ màn sẽ mở ngay sau khi học xong (màn kế tiếp trong chương hiện tại).
func request_continue_after_flow() -> void:
	var gm := _game_manager()
	if gm == null or not gm.has_method("next_level_in_chapter"):
		return
	_next_level_after_flow = maxi(int(gm.call("next_level_in_chapter", int(gm.get("current_level")))), 0)


## Bước hiện tại của luồng (Debug Console hiển thị) — luồng chưa chạy thì đọc bước đã lưu
func flow_step() -> int:
	return _flow_index if flow_active else _saved_step()


## Bài này có phải BƯỚC HIỆN TẠI của luồng không — TutorialScene dùng để biết học xong
## thì đi tiếp luồng thay vì về Main. Ván TEST (debug_run) không tính là luồng.
func is_flow_tutorial(tutorial_id: String) -> bool:
	if not flow_active or tutorial_id.is_empty() or _flow_index >= FLOW.size():
		return false
	var gm := _game_manager()
	if gm != null and bool(gm.get("debug_run")):
		return false
	var step: Dictionary = FLOW[_flow_index]
	return str(step.get("kind", "")) == "tutorial" and str(step.get("id", "")) == tutorial_id


## Màn thực hành này gắn với bài nào ("" = không phải màn thực hành đang trong luồng).
## Nút "?" trên màn thực hành chỉ mở đúng bài này thay vì mở cả 3.
func practice_tutorial_for_level(level_id: int) -> String:
	if not flow_active:
		return ""
	return str(PRACTICE_TUTORIALS.get(level_id, ""))


# ---------------------------------------------------------------------------
# TUTORIAL LẦN ĐẦU THEO CHẾ ĐỘ
# ---------------------------------------------------------------------------
## Lần đầu vào chế độ này: mở bài học của chế độ rồi mới vào màn chơi.
## GameManager gọi ngay trước khi đổi scene sang màn chơi. Trả true nếu đã mở bài học.
func begin_mode_tutorial(mode_id: String) -> bool:
	var gm := _game_manager()
	if gm == null or flow_active:
		return false
	var tutorial_id := str(MODE_TUTORIALS.get(mode_id, ""))
	if tutorial_id.is_empty() or _tutorial_done(tutorial_id):
		return false
	gm.set("pending_tutorial", tutorial_id)
	gm.set("pending_return_to_game", true)
	NAV.goto_tutorial()
	return true


# ---------------------------------------------------------------------------
# Nội bộ
# ---------------------------------------------------------------------------
## Lấy bước kế theo `_flow_index`, tự bỏ qua bước đã thỏa (bài đã học / màn đã qua)
func _take_step() -> Dictionary:
	while _flow_index < FLOW.size() and _step_satisfied(FLOW[_flow_index]):
		_flow_index += 1
	if _flow_index >= FLOW.size():
		_finish_flow()
		return {}
	_save_step(_flow_index)
	return FLOW[_flow_index]


## Bước này có được TỰ BỎ QUA không — chỉ bỏ qua BÀI HỌC đã học (vd người chơi học trước
## qua nút "?"). MÀN THỰC HÀNH thì KHÔNG bỏ qua theo `unlocked_levels`: save đã mở sẵn nhiều
## màn (người chơi cũ / Debug / vừa xoá tiến trình tutorial) vẫn phải chơi ĐỦ các màn thực hành.
func _step_satisfied(step: Dictionary) -> bool:
	if str(step.get("kind", "")) != "tutorial":
		return false
	return _tutorial_done(str(step.get("id", "")))


## Mở 1 bước: bài học → sang màn Tutorial; màn thực hành → vào thẳng màn chơi
func _open_step(step: Dictionary) -> bool:
	if step.is_empty():
		return false
	if str(step.get("kind", "")) == "tutorial":
		var gm := _game_manager()
		gm.set("pending_tutorial", str(step.get("id", "")))
		gm.set("pending_return_to_game", false)
		NAV.goto_tutorial()
		return true
	_start_level(int(step.get("id", 1)))
	return true


func _start_level(level_id: int) -> void:
	var gm := _game_manager()
	if gm != null and gm.has_method("start_level"):
		gm.call("start_level", level_id)


func _finish_flow() -> void:
	flow_active = false
	var gm := _game_manager()
	if gm != null and gm.has_method("set_tutorial_flow"):
		gm.call("set_tutorial_flow", FLOW.size(), true)


func _index_of_level(level_id: int) -> int:
	for i in FLOW.size():
		var step: Dictionary = FLOW[i]
		if str(step.get("kind", "")) == "level" and int(step.get("id", 0)) == level_id:
			return i
	return -1


func _save_step(index: int) -> void:
	var gm := _game_manager()
	if gm != null and gm.has_method("set_tutorial_flow"):
		gm.call("set_tutorial_flow", index, false)


func _saved_step() -> int:
	var gm := _game_manager()
	if gm == null:
		return 0
	return clampi(int(gm.get("tutorial_flow_step")), 0, FLOW.size())


func _tutorial_done(tutorial_id: String) -> bool:
	var gm := _game_manager()
	if gm == null or not gm.has_method("is_tutorial_completed"):
		return false
	return bool(gm.call("is_tutorial_completed", tutorial_id))


func _game_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("GameManager")
