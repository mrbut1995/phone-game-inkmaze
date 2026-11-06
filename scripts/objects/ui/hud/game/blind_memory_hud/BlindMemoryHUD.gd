class_name BlindMemoryHUD
extends BaseHUD
## ============================================================================
## HUD Blind Memory.
##
## 2026-09-27 — theo yêu cầu "chỉ hiện thứ cần thiết": HUD này CHỈ hiện **THỜI GIAN**.
## HUD không có thẻ nhắc GHI NHỚ; pha ghi nhớ (hiện toàn bộ tường + đếm ngược 3-2-1-GO!) do
## popup `scripts/ui/popups/memory_countdown.gd` lo — xem `GameController._start_memorize_phase()`.
## ============================================================================

## Scene contract
## Exports:  (none)
## Emits:    (none)
## Handlers wired in scene: (none)
## Subscribes in code (EventBus/Model): (none)
