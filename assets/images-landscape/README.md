# assets/images-landscape/

Thư mục art **RIÊNG CHO LAYOUT NGANG** (landscape) — quy tắc do user chốt (vòng 27).

## Khi nào đặt art ở đây?

Chỉ khi art gốc trong `assets/images/` **KHÔNG THỂ dùng lại bằng 9-slice** cho layout ngang:

- Nút / thẻ mà **nội dung đã bake sẵn trong SVG theo tỉ lệ dọc** (tag góc, badge, mũi tên, con dấu, hình vẽ minh hoạ…)
  → kéo giãn ngang sẽ méo chữ/hình ⇒ vẽ SVG mới theo tỉ lệ ngang.
- Bục xếp hạng, thẻ màn chơi, thẻ cửa hàng… (2–3 cột thay vì 1 cột) nếu bố cục khác hẳn bản dọc.
- Ảnh minh hoạ / banner có bố cục riêng cho màn ngang.

## Khi nào KHÔNG cần (dùng 9-slice)?

Nếu art chỉ là **tờ giấy / khung / thân nút trơn** (không có hoạ tiết phụ thuộc tỉ lệ) thì dùng lại art cũ:

```
python tools/ui/menu_buttons_9slice.py      # sinh StyleBoxTexture trong resources/settings/styles/menu/
```

- Thẻ chế độ (main): patch 277/60/227/60 · nút công cụ: 40 · nút CTA: 48/48/48/48.
- `TextureButton` KHÔNG hỗ trợ 9-slice ⇒ node phải đổi sang `Button` + `theme_override_styles/*`.

## Quy ước

- **Giữ nguyên cấu trúc thư mục con** như bên `assets/images/`
  (vd: `assets/images/main/card_mode_classic_normal.svg` → `assets/images-landscape/main/card_mode_classic_normal.svg`).
- Art ngang thiết kế theo canvas ngang cao **1920** ⇒ kích thước/ cỡ chữ = số px trong spec **× 1.778**
  (16:9 → canvas 3413×1920 · 4:3 → 2560×1920 · 19.5:9 → 4160×1920; đo lại bằng `scripts/test_case/dev_size_probe.gd`).
- Nhớ chạy `--editor --quit` sau khi thêm SVG mới để Godot import.
