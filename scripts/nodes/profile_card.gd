class_name ProfileCard
extends Control
## ============================================================================
## Node: ProfileCard — khối hồ sơ trên thanh trên của Main Screen.
## avatar tròn + viền khung + chip cấp độ + tên + thanh XP mini + "x / y XP".
## Bấm → mở POPUP Hồ sơ (do MainScene nối `pressed`).
## ============================================================================

@onready var avatar: TextureRect = $Bg/Content/Profile/Frame/Avatar
@onready var frame: TextureRect = $Bg/Content/Profile/Frame
@onready var level_label: Label = $Bg/Content/Profile/Level/LevelText
@onready var name_label: Label = $Bg/Content/ProfileInformation/NameRow/Name
@onready var xp_bar: NinePatchProgressBar = $Bg/Content/ProfileInformation/Bar
@onready var xp_text: Label = $Bg/Content/ProfileInformation/Exp/ExpValue
@onready var profile_button : TextureButton = $Bg/Content/Profile
signal pressed()

func _ready() -> void:
	UIAnim.attach_press_bounce(profile_button)
	_refresh()


## Áp lại toàn bộ dữ liệu hồ sơ (gọi khi mở màn / hồ sơ đổi)
func refresh() -> void:
	_refresh()


func _refresh() -> void:
	if avatar != null:
		avatar.texture = load(Profile.avatar_icon(Profile.avatar_id())) as Texture2D
	if frame != null:
		frame.texture = load(Profile.frame_icon(Profile.frame_id())) as Texture2D
	if level_label != null:
		level_label.text = tr("STR_PROFILE_LEVEL_FORMAT").format([Profile.level()])
	if name_label != null:
		name_label.text = Profile.display_name()
	var step := maxi(Profile.exp_step(), 1)
	var cur := clampi(Profile.exp_in_level(), 0, step)
	if xp_bar != null:
		xp_bar.max_value = float(step)
		xp_bar.value = float(cur)
	if xp_text != null:
		xp_text.text = tr("STR_PROFILE_EXP_FORMAT").format([Shop.thousands(cur), Shop.thousands(step)])


func _on_profile_pressed() -> void:
	emit_signal("pressed")
