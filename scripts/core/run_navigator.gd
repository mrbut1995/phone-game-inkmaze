class_name RunNavigator
extends RefCounted
## ============================================================================
## RỜI VÁN CHƠI — nút Home · "VỀ DAILY" · "TRỞ VỀ" trên popup + phím back hệ thống.
##
## Tách khỏi `GameController` để phần điều hướng rời ván nằm một chỗ, dễ đọc:
## mọi nhánh đều kết thúc bằng `GameManager.return_to_*` (nếu có) hoặc `Nav.*`.
##
## Ai gọi: `GameController._on_home_requested()` · `_on_daily_requested()` · `_on_back_requested()`.
## ============================================================================


## Về MENU CHÍNH (nút Home trên HUD)
static func home() -> void:
	var gm := Svc.game()
	if gm != null:
		gm.call("go_to_main_menu")
		return
	Nav.goto_main()


## Về màn DAILY (popup thắng ván Daily bấm "VỀ DAILY")
static func daily() -> void:
	var gm := Svc.game()
	if gm != null:
		gm.call("return_to_daily")
		return
	Nav.back_to(Nav.SCENE_DAILY)


## Quay lại ĐÚNG màn trước đó (popup thắng thử thách bấm "TRỞ VỀ"):
## ván Daily → màn Daily; còn lại → lùi LỊCH SỬ điều hướng (Chọn màn / Debug / màn đã vào ván).
static func back() -> void:
	var gm := Svc.game()
	if gm != null and not str(gm.get("daily_variant")).is_empty():
		gm.call("return_to_daily")
		return
	var screen := Svc.screen()
	if screen != null and screen.has_method("go_back") and bool(screen.call("go_back")):
		return
	# Không còn lịch sử để lùi: ván màn → Chọn màn, còn lại → Menu chính
	if gm != null and bool(gm.get("level_run")):
		gm.call("return_to_levels")
	elif gm != null:
		gm.call("go_to_main_menu")
	else:
		Nav.goto_main()
