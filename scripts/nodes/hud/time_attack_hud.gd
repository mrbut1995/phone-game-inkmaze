class_name TimeAttackHUD
extends BaseHUD
## ============================================================================
## HUD TIME ATTACK — mockup/matchup_time_attack.svg (thiết kế lại 2026-09-19)
##
## CHỈ còn thẻ THỜI GIAN (card_time_tall.svg 250×156) đặt GIỮA khung HUD 980×249
## (offset (365, 46)) — KHÔNG hiện thẻ THỬ THÁCH (challenge_card() = null nên
## ChallengeController tự bỏ qua). Đồng hồ ĐẾM NGƯỢC (TimerController.start_countdown),
## hết giờ = thua; dòng phụ "ĐẾM NGƯỢC" (STR_HUD_TIME_COUNTDOWN).
##
## Giá trị đồng hồ do BaseHUD.set_time() (Time/Value) lo — HUD này không cần thêm gì.
## ============================================================================
