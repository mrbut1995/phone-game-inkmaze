class_name MainLayout
extends BaseLayout

@export var logo: TextureRect = null
@export var btn_play: BaseButton = null
@export var btn_dungeon: BaseButton = null
@export var btn_daily: BaseButton = null
@export var btn_leaderboard: BaseButton = null
@export var btn_shop: BaseButton = null
@export var btn_settings: BaseButton = null
@export var btn_archivement: BaseButton = null
@export var badge_count_label: Label = null
## Sticker HỒ SƠ (góc trên trái — mở màn Profiler): avatar + viền khung + chip cấp độ
@export var btn_profile: BaseButton = null
@export var profile_avatar: TextureRect = null
@export var profile_frame: TextureRect = null
@export var profile_level: Label = null
## Chỉ layout NGANG dùng: thẻ hồ sơ có thêm tên người chơi
@export var profile_name: Label = null
@export var badge_play: Label = null
@export var badge_dungeon: Label = null
@export var badge_daily: Label = null
@export var stamp_panel: Control = null
@export var stamp_label: Label = null
@export var game_mode_box: Control = null
@export var other_box: Control = null
