class_name ChaptersScene
extends BaseScene
## ============================================================================
## Màn CHỌN CHƯƠNG — mockup/chapter_selection.svg
##
## - Danh sách chương lấy từ `LevelManager.get_chapters()` (resources/chapters/chapter_*.tres)
## - Mỗi chương 1 thẻ 970×285 (nodes/chapters/chapter_card.tscn), cuộn dọc khi nhiều chương
## - Trạng thái thẻ: ĐANG CHƠI (chương của màn hiện tại) · ĐÃ ĐỦ ĐIỀU KIỆN (đủ Sao -> MỞ KHÓA)
##   · ĐANG KHÓA (thiếu Sao) · SẮP RA MẮT (đã mở nhưng chưa có màn nào)
## - Bấm VÀO CHƠI -> ghi `GameManager.current_chapter` rồi sang màn Chọn màn
## ============================================================================

const CARD_SCENE := preload("res://nodes/chapters/chapter_card.tscn")
const UIAnim := preload("res://scripts/utils/ui_anim.gd")

@onready var btn_back: TextureButton = $TopBar/Back
@onready var cards_box: VBoxContainer = $List/Cards
@onready var lbl_wallet: Label = $Wallet/Count
@onready var btn_continue: TextureButton = $ContinueButton
@onready var lbl_continue: Label = $ContinueButton/Label

var _cards: Array[ChapterCard] = []


func _ready() -> void:
	if btn_back != null:
		btn_back.pressed.connect(_on_back_pressed)
		UIAnim.attach_press_bounce(btn_back)
	if btn_continue != null:
		btn_continue.pressed.connect(_on_continue_pressed)
		UIAnim.attach_press_bounce(btn_continue)
		UIAnim.play_pulse(btn_continue, 1.035, 1.6)

	var top_bar := get_node_or_null("TopBar") as Control
	if top_bar != null:
		UIAnim.play_slide_in(top_bar, Vector2(0, -22), 0.0, 0.25)
	var wallet_bar := get_node_or_null("Wallet") as Control
	if wallet_bar != null:
		UIAnim.play_slide_in(wallet_bar, Vector2(0, -22), 0.04, 0.25)
	var banner := get_node_or_null("Banner") as Control
	if banner != null:
		UIAnim.play_slide_in(banner, Vector2(0, -15), 0.08, 0.25)
	if btn_continue != null:
		UIAnim.play_slide_in(btn_continue, Vector2(0, 25), 0.15, 0.28)

	# Chương đã mở hết thì tự ẩn nút "TIẾP TỤC CHƯƠNG n" dưới chân trang
	if lbl_continue != null:
		lbl_continue.theme_type_variation = &"LevelsContinue"
	_build_cards()
	_refresh_header()
	var gm := _game_manager()
	if gm != null and gm.has_signal("chapter_unlocked"):
		gm.connect("chapter_unlocked", _on_chapter_unlocked)


# ---------------------------------------------------------------------------
# API cho test
# ---------------------------------------------------------------------------
func card_count() -> int:
	return _cards.size()


func card_at(index: int) -> ChapterCard:
	return _cards[index] if index >= 0 and index < _cards.size() else null


func card_for(chapter_id: int) -> ChapterCard:
	for card in _cards:
		if card.chapter_id == chapter_id:
			return card
	return null


## Chương đang "đang chơi" = chương chứa màn chơi hiện tại
func playing_chapter_id() -> int:
	var lm := _level_manager()
	if lm != null and lm.has_method("current_chapter_id"):
		return int(lm.call("current_chapter_id"))
	return 1


# ---------------------------------------------------------------------------
# Dựng danh sách chương
# ---------------------------------------------------------------------------
func _build_cards() -> void:
	if cards_box == null:
		return
	for child in cards_box.get_children():
		cards_box.remove_child(child)
		child.queue_free()
	_cards.clear()

	var lm := _level_manager()
	if lm == null or not lm.has_method("get_chapters"):
		return
	var chapters: Array = lm.call("get_chapters")
	var playing := playing_chapter_id()
	var index := 0
	for chapter in chapters:
		var card: ChapterCard = CARD_SCENE.instantiate()
		cards_box.add_child(card)
		card.setup(chapter, _card_info(chapter, playing))
		card.selected.connect(_on_card_selected)
		card.unlock_requested.connect(_on_unlock_requested)
		_cards.append(card)
		UIAnim.play_pop_in(card, 0.03 * index, 0.9, 0.22)
		index += 1


## Thông tin cho 1 thẻ: trạng thái + số liệu Sao / màn
func _card_info(chapter: ChapterData, playing_chapter_id_: int) -> Dictionary:
	var lm := _level_manager()
	var gm := _game_manager()
	var total_stars := int(gm.call("total_stars")) if gm != null and gm.has_method("total_stars") else 0
	var levels: Array = lm.call("levels_in_chapter", chapter.chapter_id) if lm != null else []
	var stars_total := levels.size() * 3
	var stars_own := int(lm.call("chapter_stars", chapter.chapter_id)) if lm != null else 0
	var cleared := int(lm.call("chapter_cleared_count", chapter.chapter_id)) if lm != null else 0
	var unlocked := bool(gm.call("is_chapter_unlocked", chapter.chapter_id)) if gm != null else chapter.chapter_id <= 1
	var state: ChapterCard.State = ChapterCard.State.PLAYING
	if not unlocked:
		state = ChapterCard.State.READY if total_stars >= chapter.star_cost else ChapterCard.State.LOCKED
	elif levels.is_empty():
		state = ChapterCard.State.COMING
	elif chapter.chapter_id != playing_chapter_id_:
		state = ChapterCard.State.PLAYING
	return {
		"state": state,
		"current": chapter.chapter_id == playing_chapter_id_,
		"stars_own": stars_own,
		"stars_total": stars_total,
		"levels_cleared": cleared,
		"levels_total": levels.size(),
		"star_cost": chapter.star_cost,
		"total_stars": total_stars,
		"next_level": _next_level_of(levels),
		"size_tier": _size_tier(levels),
	}


## Màn "đang chơi" của chương (màn chưa hoàn thành đầu tiên, hoặc màn cuối)
func _next_level_of(levels: Array) -> int:
	if levels.is_empty():
		return 1
	var stars: Dictionary = {}
	var gm := _game_manager()
	if gm != null:
		var value: Variant = gm.get("level_stars")
		if value is Dictionary:
			stars = value
	for level_id in levels:
		if int(stars.get(level_id, 0)) <= 0:
			return int(level_id)
	return int(levels[levels.size() - 1])


## Cỡ doodle theo bàn cờ lớn nhất trong chương: <=5 nhỏ · <=8 vừa · còn lại lớn
func _size_tier(levels: Array) -> String:
	var lm := _level_manager()
	var biggest := 0
	if lm != null:
		for level_id in levels:
			var data: LevelData = lm.call("load_level", level_id)
			if data != null:
				biggest = maxi(biggest, maxi(data.width, data.height))
	if biggest <= 5:
		return "small"
	return "medium" if biggest <= 8 else "large"


func _refresh_header() -> void:
	var gm := _game_manager()
	var stars := int(gm.call("total_stars")) if gm != null and gm.has_method("total_stars") else 0
	if lbl_wallet != null:
		lbl_wallet.text = str(stars)
	# Nút chân trang: nhảy tới chương đang chơi
	if btn_continue != null:
		var playing := playing_chapter_id()
		if lbl_continue != null:
			lbl_continue.text = TranslationServer.translate("STR_CHAPTER_CONTINUE_FORMAT").format([
				playing, _next_level_of(_levels_of(playing))])


func _levels_of(chapter_id: int) -> Array:
	var lm := _level_manager()
	return lm.call("levels_in_chapter", chapter_id) if lm != null else []


# ---------------------------------------------------------------------------
# Hành động
# ---------------------------------------------------------------------------
func _on_card_selected(chapter_id: int) -> void:
	var gm := _game_manager()
	if gm == null or not bool(gm.call("is_chapter_unlocked", chapter_id)):
		return
	Sfx.play(Sfx.BTN_CLICK)
	gm.call("set_chapter", chapter_id)
	Nav.goto_levels()


func _on_unlock_requested(chapter_id: int) -> void:
	var gm := _game_manager()
	if gm == null:
		return
	if bool(gm.call("unlock_chapter", chapter_id)):
		Sfx.play(Sfx.ACHIEVEMENT)
		_build_cards()
		_refresh_header()
		if lbl_wallet != null and DisplayServer.get_name() != "headless":
			lbl_wallet.pivot_offset = lbl_wallet.size * 0.5
			var tw := lbl_wallet.create_tween()
			tw.tween_property(lbl_wallet, "scale", Vector2(1.3, 1.3), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(lbl_wallet, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		Sfx.play(Sfx.BTN_CLICK)


func _on_continue_pressed() -> void:
	_on_card_selected(playing_chapter_id())


func _on_back_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	# Màn Chọn Chương là màn CON của Chọn màn -> Back quay về Chọn màn
	Nav.goto_levels()


func _on_chapter_unlocked(_chapter_id: int) -> void:
	call_deferred("_build_cards")


func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")


func _level_manager() -> Node:
	return get_node_or_null("/root/LevelManager")
