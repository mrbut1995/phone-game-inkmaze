# Ranking v4 — tab gáy sổ + top 3 nhà vô địch + dòng kẻ

Chép cả thư mục này đè lên gốc project (giữ nguyên cấu trúc đường dẫn).

## 1. Assets SVG → PNG
Xuất PNG bằng tool của bạn, GIỮ TÊN FILE, đặt vào `assets/images-png/...` (cùng thư mục con với svg):
- Ghi đè file cũ (giữ uid): `ranking/rank_sheet`, `ranking/rank_row`, `ranking/rank_row_you`, `ranking/my_rank_bar`, `ranking/tab_normal`, `ranking/tab_active`, `btn_header_back_normal`, `btn_header_back_pressed`
- File MỚI: `ranking/hero_card`, `ranking/duo_card_silver`, `ranking/duo_card_bronze`, `ranking/medal_circle`, `ranking/banner_title`, `ranking/hole`
- Không còn dùng (xoá được): `podium_gold/silver/bronze`, `chip_scope`, `medal_gold`, `divider_dashed` (phần ranking), `washi_tape` (ranking)
Mỗi SVG ghi sẵn kích thước ở comment đầu file; viewBox gấp đôi nên xuất 1x hoặc 2x đều khớp.

## 2. Scene / script
scenes/ranking.tscn (đã dọn ext_resource thừa) · scenes/layout/portrait|landscape/ranking.tscn ·
nodes/ranking/tab_button.tscn + rank_row.tscn · scripts/scenes/ranking.gd + layout/ranking_layout.gd · scripts/nodes/ranking/tab_button.gd

## 3. Lưu ý
- Cần Godot 4.5+ (`pivot_offset_ratio`).
- Bỏ Chip "STR_RANK_SCOPE", Footer và FooterNote (mockup không có). Muốn giữ thì báo mình thêm lại.
- Màu chữ các nhãn mới đặt trực tiếp trong scene (theme_override), nên không phải sửa theme_default.tres.
