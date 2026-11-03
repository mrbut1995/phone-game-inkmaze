# Hướng dẫn cho AI local — hoàn thiện đợt đổi InkMaze (Godot 4.8)

## Bối cảnh (đã làm xong, KHÔNG làm lại)
- Chỉ còn Special mode: Wall Builder, Blind Memory. Đã xoá Minesweeper, Sum Path, Countdown Cost, Fading Ink, One Stroke, Fog of War (mode riêng).
- Fog of War giờ là luật Challenge: id `fog_of_war` trong `scripts/modes/challenge_game_mode.gd`.
- Tool Undo -> Teleport (id `teleport`, tầm 2 ô Manhattan, xuyên tường). `UndoController` GIỮ LẠI cho hồi sinh.
- Ô KHOÁ + ô CHÌA: `MazeData` (`scripts/core/maze_data.gd`), `LevelData.lock_cells` / `key_cells` (PackedInt32Array, mỗi ô 3 số `x,y,id`; chìa có cùng id mới mở được ô khoá).
Quy tắc: sửa tối thiểu, giữ phong cách code + comment tiếng Việt, không viết lại cả file, không đổi file ngoài danh sách việc.

## Việc 1 — Level designer (Python, `tools/tools/level_designer/`)
1. `app/models/challenge_rules.py`: thêm luật `fog_of_war`; đổi `no_undo`/"undo" -> `no_teleport` (khớp `ChallengeGameMode`: `NO_TOOL`, `FOG_OF_WAR`).
2. `app/models/missions.py`: mission `no_undo` -> `no_teleport` (khớp `mission_types.gd` NO_TELEPORT).
3. `app/config.py`, `app/models/level.py`, `app/services/validator.py`, `app/views/inspector_view.py`, `main.py`, `README.md`: bỏ các mode minesweeper/sum_path/countdown_cost/fading_ink/one_stroke/fog_of_war (mode riêng), chỉ giữ wall_builder + blind_memory.
4. Thêm vào model level + xuất file: `lock_cells`, `key_cells` (bộ ba x,y,id) khớp `scripts/data/level_data.gd`. Validator: mỗi id khoá phải có ít nhất 1 chìa, chìa/khoá không nằm trên ô S/F, và vẫn tồn tại đường từ S tới F (BFS theo trạng thái (ô, tập chìa) như `MazeData.get_play_path`).
5. Cập nhật `tests/*` và `make_samples.py` cho khớp; chạy `pytest`.

## Việc 2 — Tài liệu `design.md`
Xoá các mục của 6 mode đã bỏ, ghi Fog of War là luật Challenge, đổi Undo -> Teleport (cách dùng, tầm 2 ô, xuyên tường), thêm mục "Ô khoá & chìa khoá".

## Việc 3 — Bản dịch
`resources/localization/string.csv` cột: id,en,vi,zh_TW,zh_CN,es,ar,de,fr,hi,id,it,ja,ko,ms,pt,pt_BR,ru,th,tr. Với các key mới trong `string_extra.csv` (cột chỉ en,vi) không cần làm. Chỉ kiểm tra `STR_TOOL_TELEPORT` ở `string.csv` có đủ 20 cột. Không rewrite cả CSV, sửa theo dòng.

## Việc 4 — Art / âm thanh (thay placeholder)
- `assets/images-png/game/icon_key.png` (64x64), `icon_lock_cell.png` (96x96), `cell_teleport_glow.png` (88x88): vẽ lại cho đẹp, giữ tên + kích thước.
- Nút Teleport trên action bar còn dùng `btn_undo_{normal,pressed,disabled}.png`: tạo `btn_teleport_*.png` và đổi ExtResource trong `nodes/hud/portrait/game/action_bar.tscn`, `nodes/hud/landscape/game/action_bar.tscn`, `nodes/tutorials/how_to_use_tool.tscn`.
- Icon shop/profiler: `item_row.gd`, `profiler.gd` còn dùng icon undo (có comment TODO art).
- SFX `teleport`, `key_pickup`, `lock_bump` trong `scripts/utils/sfx.gd` đang mượn file cũ (comment TODO).

## Việc 5 — Level thật có ô khoá
Thêm vài level mẫu có `lock_cells`/`key_cells` (dùng level designer sau Việc 1), kiểm tra giải được.

## Kiểm tra cuối
- Mở project bằng Godot 4.8, xem Output không có lỗi parse/missing resource.
- Chơi thử: Teleport (sáng 2 ô, nhảy xuyên tường, huỷ không mất lượt), ô khoá (rung khi đâm, mở khi nhặt chìa), Challenge Fog of War, Wall Builder không có nút Teleport.
- `grep -rni "undo"` chỉ còn được phép ở `undo_controller.gd`, hồi sinh (`undo_last_move`, `on_move_undone`), `STR_REVIVE_DESC_UNDO`, migrate save trong `tool_inventory.gd`/`player_profile_manager.gd`.
