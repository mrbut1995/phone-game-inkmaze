# Báo cáo gen_move_map

- scene: 169 ({'screens': 14, 'base': 5, 'objects': 136, 'autoload': 1, 'components': 13})
- script: 257 (+68 test/probe)
- data/assets: 15 dòng, dir_refs: 13
- override áp dụng: 8

## Va chạm đích (0) — PHẢI = 0 trước khi áp dụng

## Cần người xem lại (3)
- script không gắn scene ở vị trí lạ: scripts/ui/game/paper_geometry.gd -> scripts/utils/PaperGeometry.gd
- script không gắn scene ở vị trí lạ: scripts/ui/screens/debug_data.gd -> scripts/utils/DebugData.gd
- script không gắn scene ở vị trí lạ: scripts/ui/widgets/shop/card_tap.gd -> scripts/systems/ShopCardTap.gd

## Scene bị hạ xuống components
- nodes/daily/week_day.tscn -> scenes/components/daily/week_day.tscn
- nodes/game/anchor.tscn -> scenes/components/game/anchor.tscn
- nodes/game/board_layers.tscn -> scenes/components/game/board_layers.tscn
- nodes/game/cell.tscn -> scenes/components/game/cell.tscn
- nodes/game/history_line.tscn -> scenes/components/game/history_line.tscn
- nodes/game/moving_line.tscn -> scenes/components/game/moving_line.tscn
- nodes/game/player_cursor.tscn -> scenes/components/game/player_cursor.tscn
- nodes/game/wall_segment.tscn -> scenes/components/game/wall_segment.tscn
- nodes/main/chest_widget.tscn -> scenes/components/main/chest_widget.tscn
- nodes/main/dungeon_pill.tscn -> scenes/components/main/dungeon_pill.tscn
- nodes/main/event_dots.tscn -> scenes/components/main/event_dots.tscn
- nodes/tutorials/anchor_callout.tscn -> scenes/components/tutorials/anchor_callout.tscn
- nodes/tutorials/tutorial_cell.tscn -> scenes/components/tutorials/tutorial_cell.tscn
