class_name PopupHost
extends Control
## ============================================================================
## Lớp phủ CHỨA POPUP (nodes/popups/host.tscn) — dùng khi scene hiện tại KHÔNG
## có sẵn node "Popups" (xem `PopupManager.get_host()`).
##
## Trước đây lớp phủ này được tạo bằng code (`Control.new()` + set anchors) —
## nay là SCENE riêng, thuộc tính chỉnh được ngay trong scene:
##   · full-rect (bám kín màn hình) · mouse_filter = IGNORE (không chặn input).
## ============================================================================
