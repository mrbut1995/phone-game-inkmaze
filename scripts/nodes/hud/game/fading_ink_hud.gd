class_name FadingInkHUD
extends GameHUD
## ============================================================================
## HUD Fading Ink.
##
## 2026-09-27 — theo yêu cầu "chỉ hiện thứ cần thiết": HUD này CHỈ hiện **THỜI GIAN**.
## Bảng "TRẠM ĐO ĐỘ PHAI MỰC" (bước đã đi · quang phổ 4 mức · cảnh báo cạn mực) đã gỡ:
## số mực hiện NGAY TRÊN TỪNG Ô của bàn cờ (lớp cảnh báo "SẮP PHAI/CẠN" do `MazeCell` vẽ), nên
## HUD không cần lặp lại.
## ============================================================================
