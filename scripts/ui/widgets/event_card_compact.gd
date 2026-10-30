class_name EventCardCompact
extends EventCard
## ============================================================================
## Node: EventCardCompact — thẻ SỰ KIỆN GỌN cho Main gộp (nodes/main/event_card_compact.tscn).
## Dùng lại 100% logic `EventCard` (theme, chip, đếm ngược, tiến độ, CTA) — chỉ khác BỐ CỤC:
## thẻ ngang (tỉ lệ ~1.26) thay vì thẻ dọc 0.8, cao ~150 px thay vì 270 px.
##
## ⚠️ Art THẺ đã bị BỎ khỏi `EventTheme` khi chuyển sang bộ NÚT event
## (`buttons_v2`, §13.31) nên thẻ chỉ còn NỀN GRADIENT + chữ; cửa sổ cắt art cũng bỏ theo. Trên Main khối thẻ **bị ẩn** — event hiện
## thành CỘT NÚT icon bên phải bản đồ (`EventButtonColumn`).
## ============================================================================
