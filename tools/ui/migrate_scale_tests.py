"""Cập nhật số đo KỲ VỌNG trong test cho khớp THIẾT KẾ 540×960 (đợt giảm nửa tỉ lệ)
và API `scene.layout.<tên>` (refactor binding). Chạy MỘT LẦN, có kiểm tra số lần khớp.

Usage: python tools/ui/migrate_scale_tests.py [--dry-run]
"""

from __future__ import annotations

import pathlib
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = pathlib.Path(__file__).resolve().parents[2]

# (file, đoạn cũ, đoạn mới) — mỗi cặp phải khớp ĐÚNG 1 lần
PAIRS: list[tuple[str, str, str]] = [
    # ── test_levels_paging: hết biến thành viên `scroll` ────────────────────────
    ("test_levels_paging.gd",
     "\tvar width := int(round(float(scene.scroll.size.x)))\n\tvar scroll_x := scene.scroll.scroll_horizontal\n",
     "\tvar width := int(round(float(scene.layout.scroll.size.x)))\n\tvar scroll_x := scene.layout.scroll.scroll_horizontal\n"),

    # ── test_controllers_and_signals: nút công cụ là NinePatchButton ───────────
    ("test_controllers_and_signals.gd",
     "\tvar tool_wall_btn: TextureButton = game_scene.tool_wall_btn as TextureButton\n",
     "\tvar tool_wall_btn: NinePatchButton = game_scene.tool_wall_btn\n"),
    ("test_controllers_and_signals.gd",
     "\tvar tool_path_btn: TextureButton = game_scene.tool_path_btn as TextureButton\n",
     "\tvar tool_path_btn: NinePatchButton = game_scene.tool_path_btn\n"),

    # ── test_full_flow: lịch Daily có lưới ở Panel/Content/Days ────────────────
    ("test_full_flow.gd",
     'daily_scene.layout.calendar.get_node_or_null("Days")',
     'daily_scene.layout.calendar.get_node_or_null("Panel/Content/Days")'),

    # ── test_main_layout: số đo giảm nửa ───────────────────────────────────────
    ("test_main_layout.gd",
     '\t\t\tassert(absf(button.size.x - 230.0) < 1.0 and absf(button.size.y - 130.0) < 1.0,\n'
     '\t\t\t\t"Nut %s phai dung kich thuoc art 230x130 (dang %s)" % [child.name, str(button.size)])',
     '\t\t\tassert(absf(button.size.x - 115.0) < 1.0 and absf(button.size.y - 65.0) < 1.0,\n'
     '\t\t\t\t"Nut %s phai dung kich thuoc art 115x65 (dang %s)" % [child.name, str(button.size)])'),
    ("test_main_layout.gd",
     'assert(main_scene.layout.btn_archivement.size.x >= 200.0 and main_scene.layout.btn_archivement.size.y >= 200.0,\n'
     '\t\t"Nút thành tựu phải là icon LỚN (>= 200x200), đang %s"',
     'assert(main_scene.layout.btn_archivement.size.x >= 100.0 and main_scene.layout.btn_archivement.size.y >= 100.0,\n'
     '\t\t"Nút thành tựu phải là icon LỚN (>= 100x100), đang %s"'),

    # ── test_ui_scenes: số đo giảm nửa + đường dẫn countdown_segment ───────────
    ("test_ui_scenes.gd",
     '\t_entry(is_equal_approx(ShopTabButton.art_height(), 98.0),\n'
     '\t\t"chieu cao tab lay tu art = 98 (dang %.0f)" % ShopTabButton.art_height())',
     '\t_entry(is_equal_approx(ShopTabButton.art_height(), 49.0),\n'
     '\t\t"chieu cao tab lay tu art = 49 (dang %.0f)" % ShopTabButton.art_height())'),
    ("test_ui_scenes.gd",
     '\ttab.apply_row_layout(200.0, 98.0, 83.0)\n'
     '\t_entry(tab.custom_minimum_size == Vector2(200, 98), "tab dang chon: 200x98")\n'
     '\ttab.set_active(false)\n'
     '\ttab.apply_row_layout(200.0, 98.0, 83.0)\n'
     '\t_entry(tab.custom_minimum_size == Vector2(200, 83), "tab chua chon: 200x83")\n'
     '\t_entry(is_equal_approx(tab.label.position.y, -15.0),',
     '\ttab.apply_row_layout(100.0, 49.0, 41.5)\n'
     '\t_entry(tab.custom_minimum_size == Vector2(100, 49), "tab dang chon: 100x49")\n'
     '\ttab.set_active(false)\n'
     '\ttab.apply_row_layout(100.0, 49.0, 41.5)\n'
     '\t_entry(tab.custom_minimum_size == Vector2(100, 41.5), "tab chua chon: 100x41.5")\n'
     '\t_entry(is_equal_approx(tab.label.position.y, -7.5),'),
    ("test_ui_scenes.gd",
     '\t\t_entry(grid.get_theme_constant("h_separation") == 30, "khe ngang 30 (tu scene)")\n'
     '\t\t_entry(grid.get_theme_constant("v_separation") == 24, "khe doc 24 (tu scene)")',
     '\t\t_entry(grid.get_theme_constant("h_separation") == 15, "khe ngang 15 (tu scene)")\n'
     '\t\t_entry(grid.get_theme_constant("v_separation") == 12, "khe doc 12 (tu scene)")'),
    ("test_ui_scenes.gd",
     '\t\t_entry(page.grid().get_theme_constant("h_separation") == 46, "khe ngang 46")\n'
     '\t\t_entry(page.grid().get_theme_constant("v_separation") == 24, "khe doc 24")',
     '\t\t_entry(page.grid().get_theme_constant("h_separation") == 23, "khe ngang 23")\n'
     '\t\t_entry(page.grid().get_theme_constant("v_separation") == 12, "khe doc 12")'),
    ("test_ui_scenes.gd",
     '\ttab.setup("play", "THU THACH", 235.0)\n'
     '\t_entry(tab.custom_minimum_size == Vector2(235, 52),\n'
     '\t\t"tab nhan be rong rieng, cao theo scene (235x52)")',
     '\ttab.setup("play", "THU THACH", 117.5)\n'
     '\t_entry(tab.custom_minimum_size == Vector2(117.5, 26),\n'
     '\t\t"tab nhan be rong rieng, cao theo scene (117.5x26)")'),
    ("test_ui_scenes.gd",
     '\t\t_entry(footstep.size == Vector2(36, 36) and footstep.position == Vector2(82, 182),\n'
     '\t\t\t"setup() đặt vệt mực đúng TÂM ô (36×36)")',
     '\t\t_entry(footstep.size == Vector2(18, 18) and footstep.position == Vector2(41, 91),\n'
     '\t\t\t"setup() đặt vệt mực đúng TÂM ô (18×18)")'),
    ("test_ui_scenes.gd",
     "res://nodes/hud/countdown_segment.tscn",
     "res://nodes/hud/portrait/countdown_segment.tscn"),

    # ── test_chapters: số đo giảm nửa + node banner lấy từ `layout` ────────────
    ("test_chapters.gd",
     '\t_entry(absf(lock.position.y + 47.0 - (doodle.position.y + doodle.size.y * 0.5)) <= 6.0,',
     '\t_entry(absf(lock.position.y + 23.5 - (doodle.position.y + doodle.size.y * 0.5)) <= 6.0,'),
    ("test_chapters.gd",
     '\t_entry(title.get_theme_font_size("font_size") >= 40,\n'
     '\t\t"Tieu de chuong >= 40px (nhan %d)" % title.get_theme_font_size("font_size"))',
     '\t_entry(title.get_theme_font_size("font_size") >= 20,\n'
     '\t\t"Tieu de chuong >= 20px (nhan %d)" % title.get_theme_font_size("font_size"))'),
    ("test_chapters.gd",
     '\t_entry((card.get_node("Subtitle") as Label).get_theme_font_size("font_size") >= 22,\n'
     '\t\t"Mo ta chuong >= 22px")',
     '\t_entry((card.get_node("Subtitle") as Label).get_theme_font_size("font_size") >= 11,\n'
     '\t\t"Mo ta chuong >= 11px")'),
    ("test_chapters.gd",
     '\t_entry((card.get_node("Action/Title") as Label).get_theme_font_size("font_size") >= 24,\n'
     '\t\t"Chu tren nut >= 24px")',
     '\t_entry((card.get_node("Action/Title") as Label).get_theme_font_size("font_size") >= 12,\n'
     '\t\t"Chu tren nut >= 12px")'),
    ("test_chapters.gd",
     '\t_entry((scene.ui_path("List/Cards") as VBoxContainer).get_theme_constant("separation") == 30,\n'
     '\t\t"Khoang cach giua cac the = 30px")',
     '\t_entry((scene.ui_path("List/Cards") as VBoxContainer).get_theme_constant("separation") == 15,\n'
     '\t\t"Khoang cach giua cac the = 15px")'),
    ("test_chapters.gd",
     '\t_entry(scene.ui_path("ChapterBanner/TitleContainer/ChangeChapter") is Label,\n'
     '\t\t"Banner co dong \'DOI CHUONG\'")',
     '\t_entry(scene.layout.lbl_change_chapter is Label,\n\t\t"Banner co dong \'DOI CHUONG\'")'),
    ("test_chapters.gd",
     '\tvar banner_node := scene.ui_path("ChapterBanner")',
     '\tvar banner_node := scene.layout.banner'),
    ("test_chapters.gd",
     '\t_entry(scene.ui_path("TopBar/Back") is TextureButton, "Man chon man co nut Back")',
     '\t_entry(scene.layout.btn_back is BaseButton, "Man chon man co nut Back")'),
    ("test_chapters.gd",
     '\t_entry((scene2.ui_path("ChapterBanner/TitleContainer/ChangeChapter") as Label).text',
     '\t_entry(scene2.layout.lbl_change_chapter.text'),
    ("test_chapters.gd",
     '\t_entry((scene2.ui_path("ChapterBanner") as Control).modulate == Color.WHITE,',
     '\t_entry(scene2.layout.banner.modulate == Color.WHITE,'),
    ("test_chapters.gd",
     '\tvar banner: Control = scene.call("ui_path", "ChapterBanner") as Control\n'
     '\tif banner == null:\n\t\treturn null',
     '\tvar layout: Node = scene.get("layout")\n'
     '\tvar banner: Control = layout.banner as Control if layout != null else null\n'
     '\tif banner == null:\n\t\treturn null'),

    # ── test_shop: số đo giảm nửa ──────────────────────────────────────────────
    ("test_shop.gd",
     '\t_entry(absf(tab_h - 98.0 * scene.screen_scale()) < 0.5,',
     '\t_entry(absf(tab_h - 49.0 * scene.screen_scale()) < 0.5,'),
    ("test_shop.gd",
     '\t_entry(scene.tile_design_size() == Vector2(475, 294),',
     '\t_entry(scene.tile_design_size() == Vector2(237.5, 147),'),
    ("test_shop.gd",
     '\tvar expect_h: float = 294.0 * 1.25 * scene.screen_scale()\n'
     '\t_entry(absf(tile_h - expect_h) < 1.0 and tile_h > 294.0,\n'
     '\t\t"The o cao = 294 × 1,25 × he so man hinh (%.0f, mong %.0f)" % [tile_h, expect_h])',
     '\tvar expect_h: float = 147.0 * 1.25 * scene.screen_scale()\n'
     '\t_entry(absf(tile_h - expect_h) < 1.0 and tile_h > 147.0,\n'
     '\t\t"The o cao = 147 × 1,25 × he so man hinh (%.0f, mong %.0f)" % [tile_h, expect_h])'),
    ("test_shop.gd",
     '\t_entry(tile != null and absf(tile.size.x - 475.0) < 1.0 and absf(tile.size.y - tile_h) < 1.0,\n'
     '\t\t"The o dung co 475x%.0f (nhan %s)" % [tile_h,',
     '\t_entry(tile != null and absf(tile.size.x - 237.5) < 1.0 and absf(tile.size.y - tile_h) < 1.0,\n'
     '\t\t"The o dung co 237.5x%.0f (nhan %s)" % [tile_h,'),
    ("test_shop.gd",
     '\t\t_entry(action != null and action.size == Vector2(200, 46),\n'
     '\t\t\t"Nut the o dung 200x46 (nhan %s)" % str(action.size if action != null else Vector2.ZERO))',
     '\t\t_entry(action != null and action.size == Vector2(100, 23),\n'
     '\t\t\t"Nut the o dung 100x23 (nhan %s)" % str(action.size if action != null else Vector2.ZERO))'),
    ("test_shop.gd",
     '\t\t\t_entry(absf((action.position.y + action.size.y) - (tile.size.y - 16.0)) < 1.0,\n'
     '\t\t\t\t"Nut the o neo day the (cach day 16, nhan %.0f)"',
     '\t\t\t_entry(absf((action.position.y + action.size.y) - (tile.size.y - 8.0)) < 1.0,\n'
     '\t\t\t\t"Nut the o neo day the (cach day 8, nhan %.0f)"'),
    ("test_shop.gd",
     '\t\t_entry(pad.size.x >= 960.0 and absf(pad.size.y - 215.0) < 2.0,\n'
     '\t\t\t"Ban nhap dung co 980x215 (nhan %s)" % str(pad.size))',
     '\t\t_entry(pad.size.x >= 480.0 and absf(pad.size.y - 107.5) < 2.0,\n'
     '\t\t\t"Ban nhap dung co 490x107.5 (nhan %s)" % str(pad.size))'),
    ("test_shop.gd",
     '\t\t_entry(noads.size == Vector2(980, 200), "Hang VIP cao 200 va rong 980 (bao trum 1 hang)")',
     '\t\t_entry(noads.size == Vector2(490, 100), "Hang VIP cao 100 va rong 490 (bao trum 1 hang)")'),
    ("test_shop.gd",
     '\t\t_entry(pack_tile.size == Vector2(475, 240), "The goi nap dung 475x240 (nhan %s)" % str(pack_tile.size))',
     '\t\t_entry(pack_tile.size == Vector2(237.5, 120), "The goi nap dung 237.5x120 (nhan %s)" % str(pack_tile.size))'),

    # ── test_shop: phân trang — màn đủ chỗ 10 món thì phải THU NHỎ khung mới có 2 trang ──
    ("test_shop.gd",
     '\tscene.goto_page(1)\n'
     '\tawait process_frame\n'
     '\tvar page2_count := mini(per_page, maxi(10 - per_page, 0))\n'
     '\t_entry(scene.item_count() == page2_count, "Trang 2 con %d mon (nhan %d)" % [page2_count, scene.item_count()])\n'
     '\t_entry(scene.item_id_at(0) != first_id, "Sang trang thi doi danh sach mon")\n'
     '\t_entry(scene.current_page() == 1, "current_page() = 1")',
     '\t# Màn đủ chỗ cả 10 món thì chỉ 1 trang ⇒ THU NHỎ khung để chắc chắn có >= 2 trang rồi kiểm tra\n'
     '\tif scene.page_count() < 2:\n'
     '\t\troot.size = Vector2i(1080, 900)\n'
     '\t\tawait process_frame\n'
     '\t\tawait process_frame\n'
     '\t_entry(scene.page_count() >= 2, "Khung thap -> chia >= 2 trang (nhan %d)" % scene.page_count())\n'
     '\tvar per_page_small := scene.items_per_page()\n'
     '\tscene.goto_page(1)\n'
     '\tawait process_frame\n'
     '\tvar page2_count := mini(per_page_small, maxi(10 - per_page_small, 0))\n'
     '\t_entry(scene.item_count() == page2_count, "Trang 2 con %d mon (nhan %d)" % [page2_count, scene.item_count()])\n'
     '\t_entry(scene.item_id_at(0) != first_id, "Sang trang thi doi danh sach mon")\n'
     '\t_entry(scene.current_page() == 1, "current_page() = 1")\n'
     '\troot.size = Vector2i(1080, 1920)\n'
     '\tawait process_frame\n'
     '\tawait process_frame'),
    ("test_shop.gd",
     '\t_entry(not scene.clicks_locked(), "Chua vuot thi chua khoa bam nut")\n'
     '\tscene.call("_begin_drag", Vector2(700, 800))',
     '\t_entry(not scene.clicks_locked(), "Chua vuot thi chua khoa bam nut")\n'
     '\t# Màn đủ chỗ cả 10 món thì chỉ 1 trang ⇒ thu nhỏ khung để CHẮC CHẮN vuốt được sang trang 2\n'
     '\tif scene.page_count() < 2:\n'
     '\t\troot.size = Vector2i(1080, 900)\n'
     '\t\tawait process_frame\n'
     '\t\tawait process_frame\n'
     '\t_entry(scene.page_count() >= 2, "Khung thap -> co >= 2 trang de kiem tra vuot (nhan %d)" % scene.page_count())\n'
     '\tscene.call("_begin_drag", Vector2(700, 800))'),
    ("test_shop.gd",
     '\t_entry(int(shop.call("coins")) == before_coins, "Dang khoa bam -> bam the KHONG mua")\n\n'
     '\t# Hết thời gian khoá -> nút mũi tên lại hoạt động',
     '\t_entry(int(shop.call("coins")) == before_coins, "Dang khoa bam -> bam the KHONG mua")\n'
     '\t# Trả khung về cỡ chuẩn cho các mục kiểm tra còn lại\n'
     '\troot.size = Vector2i(1080, 1920)\n'
     '\tawait process_frame\n'
     '\tawait process_frame\n\n'
     '\t# Hết thời gian khoá -> nút mũi tên lại hoạt động'),
]


def main() -> None:
    dry = "--dry-run" in sys.argv
    bad = 0
    for name, old, new in PAIRS:
        path = ROOT / "scripts" / "test_case" / name
        text = path.read_text(encoding="utf-8")
        count = text.count(old)
        if count == 0:
            print(f"  !! KHÔNG khớp: {name}: {old.strip().splitlines()[0][:70]}")
            bad += 1
            continue
        if count > 1:
            print(f"  !! khớp {count} lần (cần 1): {name}: {old.strip().splitlines()[0][:70]}")
            bad += 1
            continue
        if not dry:
            path.write_text(text.replace(old, new, 1), encoding="utf-8")
        print(f"  OK {name}: {old.strip().splitlines()[0][:70]}")
    print(f"\n>>> {'(dry) ' if dry else ''}{len(PAIRS) - bad}/{len(PAIRS)} mục đã xử lý")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
