class_name EventLayout
extends BaseLayout
## ============================================================================
## Layout: EventLayout — Node layout cho màn chi tiết Sự kiện.
## Dùng chung cho cả Portrait lẫn Landscape (cùng tên node).
## ============================================================================

## Scene contract
## Exports:  btn_back, event_title, event_subtitle, event_timer, progress_label, progress_unit, cta_button, cta_label, reward_container
## Emits:    (none)
## Handlers wired in scene: (none)
## Subscribes in code (EventBus/Model): (none)

@export var btn_back: BaseButton = null
@export var event_title: Label = null
@export var event_subtitle: Label = null
@export var event_timer: Label = null
@export var progress_label: Label = null
@export var progress_unit: Label = null
@export var cta_button: BaseButton = null
@export var cta_label: Label = null
@export var reward_container: Control = null
