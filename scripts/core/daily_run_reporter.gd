class_name DailyRunReporter
extends RefCounted
## ============================================================================
## CHỐT KẾT QUẢ VÁN DAILY — ghi vào `DailyManager` và trả Dictionary mô tả để popup thắng dùng.
##
## Sao của 1 ván Daily:
##   · "challenge" / "special" (luật Special không có nhiệm vụ): thắng = CHALLENGE_STARS_MAX.
##   · "classic" (phần CHƠI): số Sao = số NHIỆM VỤ hoàn thành (0..PLAY_STARS_MAX).
##
## Ai gọi: `GameController._complete_daily_missions()` (ván không phải Daily ⇒ trả `{}`).
## ============================================================================


## `mission_stars` = số Sao theo nhiệm vụ của ván (chỉ dùng cho variant "classic")
static func complete(mission_stars: int, mode_id: String, mode_name: String) -> Dictionary:
	var gm := Svc.game()
	var dm := Svc.daily()
	if gm == null or dm == null:
		return {}
	var variant := str(gm.get("daily_variant"))
	if variant.is_empty():
		return {}

	var day := maxi(int(gm.get("selected_daily_day")), 1)
	var is_challenge := variant != "classic"
	var stars := int(dm.call("get_day_challenge_stars" if is_challenge else "get_day_play_stars", day))
	if is_challenge:
		# Luật Special không có nhiệm vụ ⇒ hoàn thành ván là trọn 3 Sao.
		stars = DailyManager.CHALLENGE_STARS_MAX
	else:
		stars = clampi(mission_stars, 0, DailyManager.PLAY_STARS_MAX)
	var gained := int(dm.call("record_daily_win", day, is_challenge, stars))
	# Đánh dấu "vừa thắng ván Daily" để màn Daily chạy hiệu ứng Sao trên đúng thẻ vừa chơi
	if stars > 0:
		gm.set("daily_celebrate", {
			"day": day, "challenge": is_challenge, "stars": stars, "gained": gained,
		})

	return {
		"day": day,
		"variant": variant,
		"challenge": is_challenge,
		"mode_id": mode_id,
		"mode_name": mode_name,
		"stars": stars,
		"stars_gained": gained,
		"day_stars": int(dm.call("get_day_stars", day)),
		"stars_max": DailyManager.DAY_STARS_MAX,
		"month_stars": int(dm.call("get_month_stars")),
		"month_goal": int(dm.call("month_star_goal")),
		"completed_day": bool(dm.call("is_completed", day)),
	}
