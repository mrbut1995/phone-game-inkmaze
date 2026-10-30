class_name TutorialStore
extends RefCounted
## ============================================================================
## TIẾN TRÌNH HỌC (tutorial) + YÊU CẦU MỞ BÀI HỌC — tách khỏi `GameManager`.
##
## Gồm 2 phần:
##   · Cờ đã học từng bài (`progress`) + vị trí bước trong luồng onboarding (`flow_step`/`flow_done`).
##   · Yêu cầu "mở thẳng bài X" do màn khác đặt trước khi đổi scene (`pending_*`).
##
## Ai gọi: CHỈ `GameManager` (giữ property cùng tên để code/test cũ đọc-ghi như trước).
## ============================================================================

## tutorial_id -> đã học xong
var progress: Dictionary = {
	"first_time": false,
	"how_to_play_move": false,
	"how_to_play_checking_wall": false,
	"how_to_play_writting_hint": false,
	"core_completed": false,
	"how_to_play_minesweeper": false,
	"how_to_play_one_stroke": false,
	"how_to_play_sum_path": false,
	"how_to_play_wall_builder": false,
}
## Bước hiện tại trong luồng onboarding (0 = chưa bắt đầu)
var flow_step: int = 0
## Đã đi hết luồng onboarding chưa
var flow_done: bool = false

## Yêu cầu mở thẳng 1 bài khi vào màn Tutorial: "" = chạy chuỗi mặc định · id bài · REQUEST_CORE
var pending_tutorial: String = ""
## Mở tutorial từ màn chơi: xong thì trả về game thay vì Main
var pending_return_to_game: bool = false
## Mở tutorial từ DANH SÁCH bài học: Back/xong ⇒ về lại danh sách
var pending_return_to_list: bool = false


func is_completed(tutorial_id: String) -> bool:
	return bool(progress.get(tutorial_id, false))


## Ghi vị trí luồng onboarding (TutorialManager gọi sau mỗi bước / khi xong luồng)
func set_flow(step: int, done: bool) -> void:
	flow_step = clampi(step, 0, 64)
	flow_done = done


func set_completed(tutorial_id: String, completed := true) -> void:
	progress[tutorial_id] = completed
	if progress.get("first_time", false) and \
			progress.get("how_to_play_move", false) and \
			progress.get("how_to_play_checking_wall", false):
		progress["core_completed"] = true


func mark_core_completed() -> void:
	progress["first_time"] = true
	progress["how_to_play_move"] = true
	progress["how_to_play_checking_wall"] = true
	progress["how_to_play_writting_hint"] = true
	progress["core_completed"] = true


## `from_list = true` khi người chơi chọn bài từ màn danh sách
func request(tutorial_id: String, from_list := false) -> void:
	pending_tutorial = tutorial_id.strip_edges()
	pending_return_to_list = from_list


## Màn Tutorial đọc 1 lần rồi xoá yêu cầu (không giữ cho lần sau)
func take_request() -> String:
	var requested := pending_tutorial
	pending_tutorial = ""
	return requested


func take_return_to_game() -> bool:
	var flag := pending_return_to_game
	pending_return_to_game = false
	return flag


func take_return_to_list() -> bool:
	var flag := pending_return_to_list
	pending_return_to_list = false
	return flag


## Xoá tiến trình tutorial (Debug Console) — KHÔNG đụng tới tiến trình màn chơi
func reset() -> void:
	for key in progress:
		progress[key] = false
	flow_step = 0
	flow_done = false
