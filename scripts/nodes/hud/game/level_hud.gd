class_name LevelHUD
extends BaseHUD
## HUD cho Play Mode và mọi chế độ không có HUD riêng (các luật Daily còn lại):
## THỜI GIAN (trái) + THỬ THÁCH (phải, do ChallengeController vẽ).
## Thẻ THỜI GIAN do BaseHUD.set_time() lo, ở đây chỉ trả về thẻ THỬ THÁCH.


func challenge_card() -> Control:
	return get_node_or_null("Content/ModeInformation/Challenge") as Control
