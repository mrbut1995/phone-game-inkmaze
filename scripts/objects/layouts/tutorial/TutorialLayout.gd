class_name TutorialLayout
extends BaseLayout

## ============================================================================
## TutorialLayout: bố cục màn CHI TIẾT bài hướng dẫn (`scenes/tutorial.tscn`).
##
## Chỉ còn nền giấy + TopBar (Back + tiêu đề) và `TutorialContainer` — nơi
## `TutorialController` MOUNT đúng bài người chơi đã chọn (`BaseTutorial`).
##
## Danh sách bài học nằm ở màn RIÊNG `scenes/tutorial_list.tscn`
## (`TutorialListLayout`) — bấm 1 bài ở đó mới mở màn này.
##
## `TutorialContainer.z_index = 30` (> `TopBar.z_index = 10` của `base_layout`) nên bài học
## luôn VẼ ĐÈ thanh trên: mỗi `BaseTutorial` đã có header + nút Bỏ qua riêng, nhờ vậy không
## còn 2 tiêu đề chồng nhau như khi danh sách và bài học dùng chung 1 màn.
## ============================================================================

@export var btn_back: BaseButton = null
@export var lbl_title: Label = null
@export var tutorial_container: Control = null
