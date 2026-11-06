class_name SplashLayout
extends BaseLayout

## Scene contract
## Exports:  studio_label, logo_container, logo, pencil, title_label, tagline_label, stamp_label, touch_button, fade_overlay, anim_player, loading_box, loading_label, loading_bar, note_a, note_b, note_a_head, note_a_body, note_b_head, note_b_body
## Emits:    (none)
## Handlers wired in scene: (none)
## Subscribes in code (EventBus/Model): (none)

@export var studio_label: Label = null
@export var logo_container: Control = null
@export var logo: TextureRect = null
@export var pencil: TextureRect = null
@export var title_label: Label = null
@export var tagline_label: Label = null
@export var stamp_label: Label = null
@export var touch_button: TextureButton = null
@export var fade_overlay: ColorRect = null
@export var anim_player: AnimationPlayer = null
## Khối thanh tiến trình nạp (LoadingBox/LoadingLabel/LoadingBar) — xem scripts/autoload/LoadingManager.gd
@export var loading_box: Control = null
@export var loading_label: Label = null
@export var loading_bar: ProgressBar = null
## Hai tờ ghi chú dán chứa mẹo / hướng dẫn xoay vòng (NoteA = "Mẹo nhỏ", NoteB = "Hướng dẫn")
@export var note_a: Control = null
@export var note_b: Control = null
@export var note_a_head: Label = null
@export var note_a_body: Label = null
@export var note_b_head: Label = null
@export var note_b_body: Label = null
