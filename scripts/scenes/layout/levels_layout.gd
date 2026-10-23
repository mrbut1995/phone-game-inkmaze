class_name LevelsLayout
extends BaseLayout

@export var btn_back: BaseButton = null
## Tên chương trên thẻ chương ("NHẬP MÔN")
@export var lbl_chapter: Label = null
## Thẻ chương (nền giấy) — chỉ để xem, không bấm
@export var banner: Control = null
## Tham chiếu đến LevelMap — dùng chung 1 instance từ scenes/levels.tscn
## (portrait & landscape đều trỏ vào cùng node)
@export var level_map: LevelMap = null
## Thanh tiến độ Sao + 3 rương mốc thưởng — bản NGANG (`nodes/chapters/chapter_progress_h.tscn`)
@export var progress: ChapterProgress = null
## Bản DỌC: thanh thưởng DỌC ở lề trái (`nodes/chapters/chapter_rail.tscn`)
@export var rail: ChapterProgress = null
## Hàng TAB chương (`nodes/level_selection/chapter_tabs.tscn`)
@export var tabs: ChapterTabs = null
## Thẻ chân màn "MÀN TIẾP THEO" (`nodes/level_selection/next_level_card*.tscn`)
@export var next_card: NextLevelCard = null
## Khung "CHƯƠNG ĐANG KHOÁ" (overlay trong scene màn Level)
@export var lock_sheet: ChapterLockSheet = null
## Bản NGANG: ô chứa bản đồ (nằm trong `FitStage`). `MapArea` của scene chính được kéo về khớp ô này.
## Bản DỌC để trống (MapArea giữ neo 31%–82% chiều cao).
@export var map_slot: Control = null

@export_group("Thẻ chương")
## 3 nhãn phụ của thẻ chương: mô tả · "x / y SAO" · "(x/y màn) · cỡ bàn"
@export var card_subtitle: Label = null
@export var card_stars: Label = null
@export var card_levels: Label = null


## Widget thanh thưởng đang dùng (dọc ưu tiên `rail`, ngang dùng `progress`) — null nếu chưa có
func reward_bar() -> ChapterProgress:
	return rail if rail != null else progress
