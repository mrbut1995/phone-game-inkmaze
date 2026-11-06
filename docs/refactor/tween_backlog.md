# Tween backlog (D8)

Tween dựng bằng code — giữ nguyên nhịp animation ở lượt refactor này (không đổi timing).
Chuyển sang AnimationPlayer khi có thời gian + review thị giác. Mỗi dòng: file:line — biểu thức.

scripts/autoload/LoadingManager.gd:170: await tree.create_timer(VISUAL_GRACE_SEC).timeout
scripts/autoload/SceneTransition.gd:148: var tw_in := create_tween()
scripts/autoload/SceneTransition.gd:149: tw_in.tween_property(paper_page, "position:x", 0.0, duration_page_in).set_trans(Tween.TRANS_CUBIC).set_ease(Tw
scripts/autoload/SceneTransition.gd:159: var tw_out := create_tween()
scripts/autoload/SceneTransition.gd:160: tw_out.tween_property(paper_page, "position:x", end_x, duration_page_out).set_trans(Tween.TRANS_CUBIC).set_eas
scripts/autoload/SceneTransition.gd:175: var tw_in := create_tween()
scripts/autoload/SceneTransition.gd:176: tw_in.tween_method(_set_ink_radius, 0.0, _ink_max_radius, duration_ink).set_trans(Tween.TRANS_QUAD).set_ease(T
scripts/autoload/SceneTransition.gd:186: var tw_out := create_tween()
scripts/autoload/SceneTransition.gd:188: tw_out.tween_property(ink_circle_drawer, "modulate:a", 0.0, duration_page_out).set_trans(Tween.TRANS_QUAD).set
scripts/autoload/SceneTransition.gd:189: tw_out.tween_method(_set_ink_radius, _ink_max_radius, _ink_max_radius * 1.3, duration_page_out).set_trans(Twee
scripts/autoload/SceneTransition.gd:200: var tw_in := create_tween()
scripts/autoload/SceneTransition.gd:201: tw_in.tween_property(fade_rect, "modulate:a", 1.0, duration_fade).set_trans(Tween.TRANS_QUAD).set_ease(Tween.E
scripts/autoload/SceneTransition.gd:209: var tw_out := create_tween()
scripts/autoload/SceneTransition.gd:210: tw_out.tween_property(fade_rect, "modulate:a", 0.0, duration_fade).set_trans(Tween.TRANS_QUAD).set_ease(Tween.
scripts/base/BasePopup.gd:145: var tw := create_tween()
scripts/base/BasePopup.gd:152: tw.tween_property(panel, "scale", Vector2.ONE, dur_in).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/base/BasePopup.gd:172: var tw := create_tween()
scripts/base/BasePopup.gd:36: var _tween: Tween = null
scripts/base/BaseTutorial.gd:168: wave.create_tween().tween_property(wave, "value", float(current_step_index + 1), 0.3).set_trans(Tween.TRANS_CU
scripts/base/BaseTutorial.gd:187: backdrop.create_tween().tween_property(backdrop, "modulate:a", 1.0, 0.24)
scripts/base/BaseTutorial.gd:201: var settle := get_tree().create_timer(ENTRANCE_SETTLE_SECONDS)
scripts/base/BaseTutorial.gd:272: target.create_tween().tween_property(target, "modulate", old, 0.4)
scripts/base/BaseTutorial.gd:290: get_tree().create_timer(TEXT_OUT_SECONDS).timeout.connect(_apply_step_text_and_slide.bind(new_msg, new_title))
scripts/base/BaseTutorial.gd:294: _fx_message = lbl_message.create_tween()
scripts/base/BaseTutorial.gd:457: _auto_timer = get_tree().create_timer(delay)
scripts/base/BaseTutorial.gd:513: backdrop.create_tween().tween_property(backdrop, "color", Color(0.969, 0.957, 0.937, 1.0), 0.45)
scripts/base/BaseTutorial.gd:546: get_tree().create_timer(TOAST_IN_SECONDS + hold).timeout.connect(_fade_toast_after.bind(seq))
scripts/base/BaseTutorial.gd:549: _fx_toast = toast_label.create_tween()
scripts/base/BaseTutorial.gd:551: _fx_toast.parallel().tween_property(toast_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_e
scripts/base/BaseTutorial.gd:561: var tw := toast_label.create_tween()
scripts/base/BaseTutorial.gd:576: var tween := create_tween()
scripts/base/BaseTutorial.gd:647: var tw := spotlight.create_tween()
scripts/base/BaseTutorial.gd:649: tw.tween_property(spotlight, "position", target.position, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EA
scripts/base/BaseTutorial.gd:650: tw.tween_property(spotlight, "size", target.size, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/base/BaseTutorial.gd:662: get_tree().create_timer(SPOTLIGHT_IN_SECONDS).timeout.connect(_start_spotlight_pulse)
scripts/base/BaseTutorial.gd:665: spotlight.create_tween().tween_property(spotlight, "modulate:a", 1.0, 0.22)
scripts/base/BaseTutorial.gd:678: get_tree().create_timer(SPOTLIGHT_OUT_SECONDS).timeout.connect(_hide_spotlight_if_unused)
scripts/base/BaseTutorial.gd:681: var tw := spotlight.create_tween()
scripts/base/BaseTutorial.gd:701: _fx_spotlight = spotlight.create_tween().set_loops()
scripts/base/BaseTutorial.gd:702: _fx_spotlight.tween_property(spotlight, "scale", Vector2(1.06, 1.06), 0.85).set_trans(Tween.TRANS_SINE).set_ea
scripts/base/BaseTutorial.gd:703: _fx_spotlight.tween_property(spotlight, "scale", Vector2.ONE, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween
scripts/base/BaseTutorial.gd:70: var _fx_spotlight: Tween = null
scripts/base/BaseTutorial.gd:71: var _fx_toast: Tween = null
scripts/base/BaseTutorial.gd:72: var _fx_message: Tween = null
scripts/base/EventCardBase.gd:223: var tw := label.create_tween().set_parallel(true)
scripts/components/game/MazeAnchor.gd:103: var tw := create_tween().set_parallel(true)
scripts/components/game/MazeAnchor.gd:105: tw.tween_property(self, "scale", Vector2(1.35, 1.35), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT
scripts/components/game/MazeAnchor.gd:109: tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
scripts/components/game/MazeAnchor.gd:127: var tw := create_tween()
scripts/components/game/MazeAnchor.gd:128: tw.tween_property(self, "scale", Vector2(1.4, 1.4), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/components/game/MazeAnchor.gd:129: tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
scripts/components/game/MazeAnchor.gd:67: get_tree().create_timer(delay).timeout.connect(_play_entrance_now)
scripts/components/game/MazeAnchor.gd:72: var tw := create_tween()
scripts/components/game/MazeAnchor.gd:75: tw.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/components/game/MazeCell.gd:130: get_tree().create_timer(delay).timeout.connect(_play_entrance_now)
scripts/components/game/MazeCell.gd:135: var tw := create_tween().set_parallel(true)
scripts/components/game/MazeCell.gd:138: tw.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/components/game/MazeCell.gd:139: tw.tween_property(self, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
scripts/components/game/MazeCell.gd:316: var tw := create_tween()
scripts/components/game/MazeCell.gd:317: tw.tween_property(self, "scale", Vector2(1.12, 1.12), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OU
scripts/components/game/MazeCell.gd:318: tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
scripts/components/game/MazeCell.gd:343: var tw := create_tween()
scripts/components/game/MazeCell.gd:344: tw.tween_property(label, "scale", Vector2(1.32, 1.32), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_O
scripts/components/game/MazeCell.gd:345: tw.tween_property(label, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
scripts/components/game/MazeCell.gd:358: get_tree().create_timer(delay).timeout.connect(_play_win_now)
scripts/components/game/MazeCell.gd:362: var tw := create_tween()
scripts/components/game/MazeCell.gd:365: tw.tween_property(self, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OU
scripts/components/game/MazeCell.gd:366: tw.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
scripts/components/game/MazeCell.gd:380: var flash := create_tween()
scripts/components/game/MazeCell.gd:397: var fade := create_tween()
scripts/components/game/PlayerCursor.gd:157: _demo_tween = create_tween().set_loops()
scripts/components/game/PlayerCursor.gd:164: _demo_tween.tween_property(self, "position", to_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE
scripts/components/game/PlayerCursor.gd:206: _demo_tween = create_tween().set_loops()
scripts/components/game/PlayerCursor.gd:226: _demo_tween.tween_property(self, "position", to_p, dur_per_step).set_trans(Tween.TRANS_SINE).set_ease(Tween.EA
scripts/components/game/PlayerCursor.gd:232: _demo_tween.tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OU
scripts/components/game/PlayerCursor.gd:257: _demo_tween = create_tween()
scripts/components/game/PlayerCursor.gd:261: _demo_tween.tween_property(self, "position", midway_pos, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE
scripts/components/game/PlayerCursor.gd:267: _demo_tween.tween_property(self, "position", from_pos, 0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EAS
scripts/components/game/PlayerCursor.gd:268: _demo_tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(T
scripts/components/game/PlayerCursor.gd:294: _demo_tween = create_tween()
scripts/components/game/PlayerCursor.gd:295: _demo_tween.tween_property(self, "position", to_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE
scripts/components/game/PlayerCursor.gd:299: _demo_tween.tween_property(self, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_O
scripts/components/game/PlayerCursor.gd:349: _move_tween = create_tween()
scripts/components/game/PlayerCursor.gd:351: .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
scripts/components/game/PlayerCursor.gd:370: _move_tween = create_tween().set_parallel(true)
scripts/components/game/PlayerCursor.gd:372: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/components/game/PlayerCursor.gd:408: _move_tween = create_tween().set_parallel(false)
scripts/components/game/PlayerCursor.gd:409: _move_tween.tween_property(self, "position", half_way, t1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT
scripts/components/game/PlayerCursor.gd:410: _move_tween.tween_property(self, "position", target_pos, duration * 0.44).set_trans(Tween.TRANS_QUAD).set_ease
scripts/components/game/PlayerCursor.gd:45: var _move_tween: Tween = null
scripts/components/game/PlayerCursor.gd:469: _move_tween = create_tween()
scripts/components/game/PlayerCursor.gd:46: var _demo_tween: Tween = null
scripts/components/game/PlayerCursor.gd:470: _move_tween.tween_property(self, "position", base_pos + push_back, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(
scripts/components/game/PlayerCursor.gd:471: _move_tween.tween_property(self, "position", base_pos, 0.14).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EAS
scripts/components/game/WallSegment.gd:128: var tw_fade := create_tween()
scripts/components/game/WallSegment.gd:138: var tw := create_tween()
scripts/components/game/WallSegment.gd:142: , 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
scripts/components/game/WallSegment.gd:169: _preview_pulse = create_tween().set_loops()
scripts/components/game/WallSegment.gd:184: var tw := create_tween()
scripts/components/game/WallSegment.gd:186: tw.tween_property(self, "width", target_width, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/components/game/WallSegment.gd:187: tw.tween_property(self, "width", _base_width, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
scripts/components/game/WallSegment.gd:20: var _preview_pulse: Tween = null
scripts/components/shared/GameController.gd:952: get_tree().create_timer(delay).timeout.connect(_play_sfx_now.bind(sfx_name))
scripts/components/shared/UIController.gd:46: var _teleport_highlight_tween: Tween = null
scripts/components/tutorials/AnchorCallout.gd:15: var _fx: Tween = null
scripts/components/tutorials/AnchorCallout.gd:16: var _pulse: Tween = null
scripts/components/tutorials/AnchorCallout.gd:37: _fx = create_tween()
scripts/components/tutorials/AnchorCallout.gd:39: _fx.parallel().tween_property(self, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EAS
scripts/components/tutorials/AnchorCallout.gd:80: _pulse = create_tween().set_loops()
scripts/components/tutorials/AnchorCallout.gd:81: _pulse.tween_property(self, "scale", Vector2(1.12, 1.12), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE
scripts/components/tutorials/AnchorCallout.gd:82: _pulse.tween_property(self, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/components/tutorials/TutorialCell.gd:116: var tw := create_tween()
scripts/components/tutorials/TutorialCell.gd:117: tw.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/components/tutorials/TutorialCell.gd:132: get_tree().create_timer(delay).timeout.connect(_play_entrance_now)
scripts/components/tutorials/TutorialCell.gd:151: var flash := create_tween()
scripts/components/tutorials/TutorialCell.gd:160: create_tween().tween_property(self, "modulate", Color.WHITE, 0.45)
scripts/components/tutorials/TutorialCell.gd:162: var tw := create_tween()
scripts/components/tutorials/TutorialCell.gd:181: get_tree().create_timer(delay).timeout.connect(_play_win_now)
scripts/components/tutorials/TutorialCell.gd:186: var tw := create_tween()
scripts/components/tutorials/TutorialCell.gd:190: tw.tween_property(self, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/achievements/AchTabButton.gd:256: var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
scripts/objects/achievements/AchievementCardBig.gd:103: var pop := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/achievements/AchievementCardBig.gd:108: create_tween().tween_property(bg, "modulate", Color.WHITE, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EA
scripts/objects/achievements/AchievementCardBig.gd:86: var slam := create_tween().set_parallel(true)
scripts/objects/achievements/AchievementCardBig.gd:88: slam.tween_property(stamp, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
scripts/objects/achievements/AchievementCardBig.gd:89: slam.tween_property(stamp, "rotation", rest_rot, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
scripts/objects/achievements/AchievementCardBig.gd:95: var shake := create_tween()
scripts/objects/daily/CtaContentFollow.gd:14: var _tween: Tween = null
scripts/objects/daily/CtaContentFollow.gd:38: _tween = create_tween().set_parallel(true)
scripts/objects/game/BoardView.gd:1133: _shake_tween = create_tween()
scripts/objects/game/BoardView.gd:127: var _shake_tween: Tween = null
scripts/objects/game/BoardView.gd:1892: var tw := node.create_tween()
scripts/objects/game/BoardView.gd:1894: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/game/BoardView.gd:1899: var tw := (node as Node).create_tween()
scripts/objects/game/BoardView.gd:923: var tw := create_tween()
scripts/objects/game/BoardView.gd:924: tw.tween_property(_cursor, "position", target_pos, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_O
scripts/objects/level_selection/LevelMap.gd:156: var _scroll_tween: Tween = null
scripts/objects/level_selection/LevelMap.gd:236: _scroll_tween = create_tween()
scripts/objects/level_selection/LevelMap.gd:237: _scroll_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
scripts/objects/level_selection/LevelMap.gd:712: await get_tree().create_timer(anim_start_delay).timeout
scripts/objects/level_selection/LevelMap.gd:716: await get_tree().create_timer(0.2).timeout
scripts/objects/level_selection/LevelMap.gd:737: await get_tree().create_timer((scroll_to_duration + 0.1) / speed).timeout
scripts/objects/level_selection/LevelMap.gd:838: var _reveal_tweens: Array[Tween] = []
scripts/objects/level_selection/LevelMap.gd:888: await get_tree().create_timer(reveal_start_delay).timeout
scripts/objects/level_selection/LevelMap.gd:904: _scroll_tween = create_tween()
scripts/objects/level_selection/LevelMap.gd:905: _scroll_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/level_selection/LevelMap.gd:923: await get_tree().create_timer(draw_time).timeout
scripts/objects/level_selection/LevelMap.gd:928: var pop := create_tween()
scripts/objects/level_selection/LevelMap.gd:932: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/level_selection/LevelMap.gd:935: await get_tree().create_timer(maxf(step - draw_time, 0.01)).timeout
scripts/objects/level_selection/LevelMap.gd:938: await get_tree().create_timer(reveal_pop_sec * 0.8).timeout
scripts/objects/level_selection/LevelMapNode.gd:148: await get_tree().create_timer(0.2 / speed).timeout
scripts/objects/level_selection/LevelMapNode.gd:158: var tween := create_tween().set_parallel(true)
scripts/objects/level_selection/LevelMapNode.gd:159: tween.tween_property(star, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/level_selection/LevelMapNode.gd:160: tween.tween_property(star, "rotation", 0.0, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/level_selection/LevelMapNode.gd:163: await get_tree().create_timer(star_stamp_interval / speed).timeout
scripts/objects/level_selection/LevelMapNode.gd:164: await get_tree().create_timer(0.25 / speed).timeout
scripts/objects/level_selection/LevelMapNode.gd:184: var tween := create_tween().set_parallel(true)
scripts/objects/level_selection/LevelMapNode.gd:185: tween.tween_property(spark, "position", target, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
scripts/objects/level_selection/LevelMapNode.gd:219: var shake := create_tween()
scripts/objects/level_selection/LevelMapNode.gd:223: var out := create_tween().set_parallel(true)
scripts/objects/level_selection/LevelMapNode.gd:360: var _content_tween: Tween = null
scripts/objects/level_selection/LevelMapNode.gd:389: _content_tween = create_tween().set_parallel(true)
scripts/objects/level_selection/LevelMapNode.gd:390: _content_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
scripts/objects/level_selection/LevelMapPath.gd:166: func play_reveal_range(from_point: int, to_point: int, duration: float = 0.7) -> Tween:
scripts/objects/level_selection/LevelMapPath.gd:172: var tween := create_tween()
scripts/objects/level_selection/LevelMapPath.gd:173: tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/main/ChapterGateNode.gd:245: var shake := create_tween()
scripts/objects/main/ChapterGateNode.gd:248: var flash := create_tween()
scripts/objects/main/ChapterGateNode.gd:291: _content_tween = create_tween()
scripts/objects/main/ChapterGateNode.gd:292: _content_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
scripts/objects/main/ChapterGateNode.gd:96: var _content_tween: Tween = null
scripts/objects/main/EventCarousel.gd:258: _snap_tween = create_tween()
scripts/objects/main/EventCarousel.gd:259: _snap_tween.set_ease(Tween.EASE_OUT)
scripts/objects/main/EventCarousel.gd:260: _snap_tween.set_trans(Tween.TRANS_CUBIC)
scripts/objects/main/EventCarousel.gd:47: var _snap_tween: Tween
scripts/objects/ranking/RankTabButton.gd:42: var _width_tween: Tween = null
scripts/objects/ranking/RankTabButton.gd:81: _width_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
scripts/objects/shop/ShopTabButton.gd:135: var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
scripts/objects/tutorials/BoardTutorial.gd:431: get_tree().create_timer(0.15).timeout.connect(func() -> void:
scripts/objects/tutorials/BoardTutorial.gd:436: var line_tw := create_tween()
scripts/objects/tutorials/BoardTutorial.gd:439: , 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/tutorials/BoardTutorial.gd:443: get_tree().create_timer(0.15 + duration + 0.06).timeout.connect(func() -> void:
scripts/objects/tutorials/CongratsFirstTimeTutorial.gd:122: confetti.create_tween().tween_property(confetti, "modulate:a", 1.0, 0.4)
scripts/objects/tutorials/CongratsFirstTimeTutorial.gd:88: var tw := stamp.create_tween()
scripts/objects/tutorials/CongratsFirstTimeTutorial.gd:91: tw.tween_property(stamp, "scale", Vector2(0.88, 0.88), 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_
scripts/objects/tutorials/CongratsFirstTimeTutorial.gd:93: tw.tween_property(stamp, "rotation", 0.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
scripts/objects/tutorials/CongratsFirstTimeTutorial.gd:97: tw.tween_property(stamp, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/tutorials/FirstTimeTutorial.gd:47: var tw := create_tween()
scripts/objects/tutorials/FirstTimeTutorial.gd:77: get_tree().create_timer(i * 0.1).timeout.connect(preview_cells[i].play_step)
scripts/objects/tutorials/HowToPlayBlindMemoryTutorial.gd:129: _demo_tween = create_tween()
scripts/objects/tutorials/HowToPlayBlindMemoryTutorial.gd:18: var _demo_tween: Tween = null
scripts/objects/tutorials/HowToPlayBlindMemoryTutorial.gd:193: get_tree().create_timer(1.2).timeout.connect(func() -> void:
scripts/objects/tutorials/HowToPlayWallBuilderTutorial.gd:128: _demo_tween = create_tween()
scripts/objects/tutorials/HowToPlayWallBuilderTutorial.gd:203: _demo_tween = create_tween()
scripts/objects/tutorials/HowToPlayWallBuilderTutorial.gd:24: var _demo_tween: Tween = null
scripts/objects/tutorials/HowToUseToolTutorial.gd:137: get_tree().create_timer(0.18).timeout.connect(func() -> void:
scripts/objects/tutorials/HowToUseToolTutorial.gd:189: _demo_tween = create_tween()
scripts/objects/tutorials/HowToUseToolTutorial.gd:240: _demo_tween = create_tween()
scripts/objects/tutorials/HowToUseToolTutorial.gd:30: var _demo_tween: Tween = null
scripts/objects/ui/popups/EditProfilePopup.gd:389: var tw := preview_disc.create_tween()
scripts/objects/ui/popups/EditProfilePopup.gd:390: tw.tween_property(preview_disc, "scale", Vector2(1.07, 1.07), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween
scripts/objects/ui/popups/EditProfilePopup.gd:391: tw.tween_property(preview_disc, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OU
scripts/objects/ui/popups/EditProfilePopup.gd:410: await get_tree().create_timer(1.6).timeout
scripts/objects/ui/popups/GameOverLevelPopup.gd:244: var tl := _track(create_tween())
scripts/objects/ui/popups/GameOverLevelPopup.gd:264: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/GameOverLevelPopup.gd:268: var tc := _track(create_tween())
scripts/objects/ui/popups/GameOverLevelPopup.gd:271: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/GameOverLevelPopup.gd:286: var ts := _track(create_tween())
scripts/objects/ui/popups/GameOverLevelPopup.gd:294: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/GameOverLevelPopup.gd:312: var tp := _track(create_tween())
scripts/objects/ui/popups/GameOverLevelPopup.gd:315: var loop := _track(create_tween().set_loops())
scripts/objects/ui/popups/GameOverLevelPopup.gd:317: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/GameOverLevelPopup.gd:319: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT))
scripts/objects/ui/popups/GameOverLevelPopup.gd:339: var tw := _track(create_tween())
scripts/objects/ui/popups/GameOverLevelPopup.gd:361: var tw := _track(create_tween().set_parallel(true))
scripts/objects/ui/popups/GameOverLevelPopup.gd:364: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/GameOverLevelPopup.gd:367: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/GameOverLevelPopup.gd:368: var rot := _track(create_tween().set_loops())
scripts/objects/ui/popups/GameOverLevelPopup.gd:370: var beat := _track(create_tween().set_loops())
scripts/objects/ui/popups/GameOverLevelPopup.gd:373: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/GameOverLevelPopup.gd:375: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/GameOverLevelPopup.gd:389: var tw := _track(create_tween().set_parallel(true))
scripts/objects/ui/popups/GameOverLevelPopup.gd:391: .set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/GameOverLevelPopup.gd:394: .set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/GameOverLevelPopup.gd:403: var tw := _track(create_tween())
scripts/objects/ui/popups/GameOverLevelPopup.gd:407: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/GameOverLevelPopup.gd:410: func _track(tw: Tween) -> Tween:
scripts/objects/ui/popups/GameOverLevelPopup.gd:72: var _tweens: Array[Tween] = []
scripts/objects/ui/popups/GameOverPopup.gd:141: var tl := _track(create_tween())
scripts/objects/ui/popups/GameOverPopup.gd:155: var th := _track(create_tween())
scripts/objects/ui/popups/GameOverPopup.gd:159: .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
scripts/objects/ui/popups/GameOverPopup.gd:167: var tr_ := _track(create_tween())
scripts/objects/ui/popups/GameOverPopup.gd:170: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/GameOverPopup.gd:186: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/GameOverPopup.gd:188: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/GameOverPopup.gd:190: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/GameOverPopup.gd:203: var tp := _track(create_tween())
scripts/objects/ui/popups/GameOverPopup.gd:206: var loop := _track(create_tween().set_loops())
scripts/objects/ui/popups/GameOverPopup.gd:208: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/GameOverPopup.gd:210: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT))
scripts/objects/ui/popups/GameOverPopup.gd:238: var tw := _track(create_tween())
scripts/objects/ui/popups/GameOverPopup.gd:260: var tw := _track(create_tween().set_parallel(true))
scripts/objects/ui/popups/GameOverPopup.gd:263: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/GameOverPopup.gd:266: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/GameOverPopup.gd:267: var rot := _track(create_tween().set_loops())
scripts/objects/ui/popups/GameOverPopup.gd:269: var beat := _track(create_tween().set_loops())
scripts/objects/ui/popups/GameOverPopup.gd:272: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/GameOverPopup.gd:274: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/GameOverPopup.gd:288: var tw := _track(create_tween().set_parallel(true))
scripts/objects/ui/popups/GameOverPopup.gd:290: .set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/GameOverPopup.gd:293: .set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/GameOverPopup.gd:302: var tw := _track(create_tween())
scripts/objects/ui/popups/GameOverPopup.gd:306: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/GameOverPopup.gd:309: func _track(tw: Tween) -> Tween:
scripts/objects/ui/popups/GameOverPopup.gd:63: var _tweens: Array[Tween] = []
scripts/objects/ui/popups/MemoryCountdownPopup.gd:30: var _tw: Tween = null
scripts/objects/ui/popups/MemoryCountdownPopup.gd:52: _tw = create_tween()
scripts/objects/ui/popups/MemoryCountdownPopup.gd:71: var tw := create_tween()
scripts/objects/ui/popups/MemoryCountdownPopup.gd:72: tw.tween_property(number_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OU
scripts/objects/ui/popups/NextFloorPopup.gd:171: var th := _track(create_tween())
scripts/objects/ui/popups/NextFloorPopup.gd:180: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/NextFloorPopup.gd:186: var tr_ := _track(create_tween())
scripts/objects/ui/popups/NextFloorPopup.gd:189: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/NextFloorPopup.gd:202: var fade := _track(create_tween().set_parallel(true))
scripts/objects/ui/popups/NextFloorPopup.gd:211: var tc := _track(create_tween())
scripts/objects/ui/popups/NextFloorPopup.gd:214: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/NextFloorPopup.gd:219: var tt := _track(create_tween())
scripts/objects/ui/popups/NextFloorPopup.gd:222: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/NextFloorPopup.gd:227: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/NextFloorPopup.gd:236: var tb := _track(create_tween())
scripts/objects/ui/popups/NextFloorPopup.gd:249: var tp := _track(create_tween())
scripts/objects/ui/popups/NextFloorPopup.gd:252: var loop := _track(create_tween().set_loops())
scripts/objects/ui/popups/NextFloorPopup.gd:254: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/NextFloorPopup.gd:256: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT))
scripts/objects/ui/popups/NextFloorPopup.gd:326: var tin := _track(create_tween().set_parallel(true))
scripts/objects/ui/popups/NextFloorPopup.gd:329: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/NextFloorPopup.gd:331: var rot := _track(create_tween().set_loops())
scripts/objects/ui/popups/NextFloorPopup.gd:334: var flick := _track(create_tween().set_loops())
scripts/objects/ui/popups/NextFloorPopup.gd:337: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/NextFloorPopup.gd:339: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/NextFloorPopup.gd:343: var ts := _track(create_tween().set_parallel(true))
scripts/objects/ui/popups/NextFloorPopup.gd:346: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/NextFloorPopup.gd:347: var breathe := _track(create_tween().set_loops())
scripts/objects/ui/popups/NextFloorPopup.gd:350: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/NextFloorPopup.gd:352: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/NextFloorPopup.gd:363: var tw := _track(create_tween().set_parallel(true))
scripts/objects/ui/popups/NextFloorPopup.gd:399: var tw := _track(create_tween().set_parallel(true))
scripts/objects/ui/popups/NextFloorPopup.gd:401: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/NextFloorPopup.gd:414: var tw := _track(create_tween())
scripts/objects/ui/popups/NextFloorPopup.gd:416: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/NextFloorPopup.gd:418: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/NextFloorPopup.gd:448: var tw := _track(create_tween().set_parallel(true))
scripts/objects/ui/popups/NextFloorPopup.gd:450: .set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/NextFloorPopup.gd:453: .set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/NextFloorPopup.gd:462: var tw := _track(create_tween())
scripts/objects/ui/popups/NextFloorPopup.gd:466: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/NextFloorPopup.gd:469: func _track(tw: Tween) -> Tween:
scripts/objects/ui/popups/NextFloorPopup.gd:84: var _tweens: Array[Tween] = []
scripts/objects/ui/popups/RetryPencils.gd:59: var tw := create_tween()
scripts/objects/ui/popups/RetryPencils.gd:72: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:106: var _tweens: Array[Tween] = []
scripts/objects/ui/popups/WinningDailyPopup.gd:211: var tw := _track(create_tween())
scripts/objects/ui/popups/WinningDailyPopup.gd:215: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:219: var tw := _track(create_tween())
scripts/objects/ui/popups/WinningDailyPopup.gd:231: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:233: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:307: var tp := _track(create_tween())
scripts/objects/ui/popups/WinningDailyPopup.gd:310: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:319: var tb := _track(create_tween())
scripts/objects/ui/popups/WinningDailyPopup.gd:322: .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:326: var tc0 := _track(create_tween())
scripts/objects/ui/popups/WinningDailyPopup.gd:339: var ts := _track(create_tween())
scripts/objects/ui/popups/WinningDailyPopup.gd:342: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:352: var tc := _track(create_tween())
scripts/objects/ui/popups/WinningDailyPopup.gd:355: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:357: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:359: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:372: var tw := _track(create_tween())
scripts/objects/ui/popups/WinningDailyPopup.gd:374: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:378: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:383: var t2 := _track(create_tween())
scripts/objects/ui/popups/WinningDailyPopup.gd:419: var tw := _track(create_tween().set_parallel(true))
scripts/objects/ui/popups/WinningDailyPopup.gd:421: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:469: var tin := _track(create_tween().set_parallel(true))
scripts/objects/ui/popups/WinningDailyPopup.gd:472: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:474: var rot := _track(create_tween().set_loops())
scripts/objects/ui/popups/WinningDailyPopup.gd:477: var flick := _track(create_tween().set_loops())
scripts/objects/ui/popups/WinningDailyPopup.gd:480: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:482: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:486: var ts := _track(create_tween().set_parallel(true))
scripts/objects/ui/popups/WinningDailyPopup.gd:489: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:490: var breathe := _track(create_tween().set_loops())
scripts/objects/ui/popups/WinningDailyPopup.gd:493: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:495: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:506: var tw := _track(create_tween().set_parallel(true))
scripts/objects/ui/popups/WinningDailyPopup.gd:542: var tw := _track(create_tween().set_parallel(true))
scripts/objects/ui/popups/WinningDailyPopup.gd:544: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:557: var tw := _track(create_tween())
scripts/objects/ui/popups/WinningDailyPopup.gd:559: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:561: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:584: var tw := _track(create_tween().set_loops())
scripts/objects/ui/popups/WinningDailyPopup.gd:587: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:589: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:616: var tw := _track(create_tween().set_parallel(true))
scripts/objects/ui/popups/WinningDailyPopup.gd:618: .set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:621: .set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:630: var tw := _track(create_tween())
scripts/objects/ui/popups/WinningDailyPopup.gd:634: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningDailyPopup.gd:637: func _track(tw: Tween) -> Tween:
scripts/objects/ui/popups/WinningPopup.gd:171: var tw := _track(create_tween())
scripts/objects/ui/popups/WinningPopup.gd:175: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningPopup.gd:179: var tw := _track(create_tween())
scripts/objects/ui/popups/WinningPopup.gd:191: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningPopup.gd:193: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningPopup.gd:222: var tw := _track(create_tween().set_parallel(true))
scripts/objects/ui/popups/WinningPopup.gd:224: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningPopup.gd:272: var tin := _track(create_tween().set_parallel(true))
scripts/objects/ui/popups/WinningPopup.gd:275: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningPopup.gd:277: var rot := _track(create_tween().set_loops())
scripts/objects/ui/popups/WinningPopup.gd:280: var flick := _track(create_tween().set_loops())
scripts/objects/ui/popups/WinningPopup.gd:283: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/WinningPopup.gd:285: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/WinningPopup.gd:289: var ts := _track(create_tween().set_parallel(true))
scripts/objects/ui/popups/WinningPopup.gd:292: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningPopup.gd:293: var breathe := _track(create_tween().set_loops())
scripts/objects/ui/popups/WinningPopup.gd:296: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/WinningPopup.gd:298: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/WinningPopup.gd:309: var tw := _track(create_tween().set_parallel(true))
scripts/objects/ui/popups/WinningPopup.gd:345: var tw := _track(create_tween().set_parallel(true))
scripts/objects/ui/popups/WinningPopup.gd:347: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningPopup.gd:360: var tw := _track(create_tween())
scripts/objects/ui/popups/WinningPopup.gd:362: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningPopup.gd:364: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/WinningPopup.gd:387: var tw := _track(create_tween().set_loops())
scripts/objects/ui/popups/WinningPopup.gd:390: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/WinningPopup.gd:392: .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
scripts/objects/ui/popups/WinningPopup.gd:406: var tl := _track(create_tween())
scripts/objects/ui/popups/WinningPopup.gd:410: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningPopup.gd:424: var tw := _track(create_tween())
scripts/objects/ui/popups/WinningPopup.gd:428: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningPopup.gd:435: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningPopup.gd:445: var tc := _track(create_tween())
scripts/objects/ui/popups/WinningPopup.gd:448: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningPopup.gd:450: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningPopup.gd:452: .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningPopup.gd:482: var tw := _track(create_tween().set_parallel(true))
scripts/objects/ui/popups/WinningPopup.gd:484: .set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningPopup.gd:487: .set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningPopup.gd:496: var tw := _track(create_tween())
scripts/objects/ui/popups/WinningPopup.gd:500: .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/objects/ui/popups/WinningPopup.gd:503: func _track(tw: Tween) -> Tween:
scripts/objects/ui/popups/WinningPopup.gd:96: var _tweens: Array[Tween] = []
scripts/screens/AchievementScene.gd:395: var tw := create_tween()
scripts/screens/AchievementScene.gd:398: tw.parallel().tween_property(coin, "global_position", burst, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.E
scripts/screens/AchievementScene.gd:399: tw.tween_property(coin, "global_position", to - half, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN
scripts/screens/AchievementScene.gd:411: var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/screens/AchievementScene.gd:581: _scroll_tween = create_tween()
scripts/screens/AchievementScene.gd:582: _scroll_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/screens/AchievementScene.gd:58: var _scroll_tween: Tween = null
scripts/screens/DailyScene.gd:105: await get_tree().create_timer(0.55).timeout
scripts/screens/RankingScene.gd:160: _transition = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC)
scripts/screens/RankingScene.gd:161: _transition.tween_property(content, "modulate:a", 0.0, OUT_TIME).set_ease(Tween.EASE_IN)
scripts/screens/RankingScene.gd:162: _transition.tween_property(content, "position:x", _content_rest.x - dir * SLIDE_DISTANCE, OUT_TIME).set_ease(T
scripts/screens/RankingScene.gd:164: _transition.chain().tween_property(content, "modulate:a", 1.0, IN_TIME).set_ease(Tween.EASE_OUT)
scripts/screens/RankingScene.gd:165: _transition.parallel().tween_property(content, "position:x", _content_rest.x, IN_TIME).set_ease(Tween.EASE_OUT
scripts/screens/RankingScene.gd:178: _rows_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
scripts/screens/RankingScene.gd:202: func _kill_tween(tw: Tween) -> void:
scripts/screens/RankingScene.gd:55: var _transition: Tween = null
scripts/screens/RankingScene.gd:56: var _rows_tween: Tween = null
scripts/screens/ShopScene.gd:888: var tw := layout.wallet_count.create_tween()
scripts/screens/ShopScene.gd:889: tw.tween_property(layout.wallet_count, "scale", Vector2(1.28, 1.28), 0.08).set_trans(Tween.TRANS_BACK).set_eas
scripts/screens/ShopScene.gd:890: tw.tween_property(layout.wallet_count, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.
scripts/screens/SplashScene.gd:108: var tw := create_tween()
scripts/screens/SplashScene.gd:109: tw.tween_property(n, "modulate:a", 1.0, 0.4).set_delay(float(delays[i])).set_trans(Tween.TRANS_QUAD).set_ease(
scripts/screens/SplashScene.gd:110: _note_tween = create_tween().set_loops()
scripts/screens/SplashScene.gd:133: var tw := create_tween()
scripts/screens/SplashScene.gd:211: await get_tree().create_timer(remaining).timeout
scripts/screens/SplashScene.gd:251: _pencil_tween = create_tween().set_loops()
scripts/screens/SplashScene.gd:252: _pencil_tween.tween_property(layout.pencil, "rotation_degrees", 16.0, 0.38).set_trans(Tween.TRANS_SINE).set_ea
scripts/screens/SplashScene.gd:253: _pencil_tween.tween_property(layout.pencil, "rotation_degrees", -12.0, 0.38).set_trans(Tween.TRANS_SINE).set_e
scripts/screens/SplashScene.gd:273: var tw_studio := create_tween()
scripts/screens/SplashScene.gd:274: tw_studio.tween_property(layout.studio_label, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tw
scripts/screens/SplashScene.gd:278: var tw_logo := create_tween().set_parallel(true)
scripts/screens/SplashScene.gd:279: tw_logo.tween_property(layout.logo_container, "scale", Vector2.ONE, 0.55).set_delay(0.15).set_trans(Tween.TRAN
scripts/screens/SplashScene.gd:280: tw_logo.tween_property(layout.logo_container, "modulate:a", 1.0, 0.4).set_delay(0.15).set_trans(Tween.TRANS_QU
scripts/screens/SplashScene.gd:287: _pencil_tween = create_tween().set_loops()
scripts/screens/SplashScene.gd:288: _pencil_tween.tween_property(layout.pencil, "rotation_degrees", 16.0, 0.38).set_trans(Tween.TRANS_SINE).set_ea
scripts/screens/SplashScene.gd:289: _pencil_tween.tween_property(layout.pencil, "rotation_degrees", -12.0, 0.38).set_trans(Tween.TRANS_SINE).set_e
scripts/screens/SplashScene.gd:31: var _pencil_tween: Tween = null
scripts/screens/SplashScene.gd:343: var tw_out := create_tween()
scripts/screens/SplashScene.gd:344: tw_out.tween_property(layout.fade_overlay, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween
scripts/screens/SplashScene.gd:58: var _note_tween: Tween = null
scripts/screens/TitleScene.gd:109: _pencil_tween = create_tween().set_loops()
scripts/screens/TitleScene.gd:110: _pencil_tween.tween_property(layout.pencil, "rotation_degrees", 14.0, 0.42).set_trans(Tween.TRANS_SINE).set_ea
scripts/screens/TitleScene.gd:111: _pencil_tween.tween_property(layout.pencil, "rotation_degrees", -10.0, 0.42).set_trans(Tween.TRANS_SINE).set_e
scripts/screens/TitleScene.gd:152: var tw_tap := create_tween()
scripts/screens/TitleScene.gd:153: tw_tap.tween_property(layout.tap_container, "scale", Vector2(1.18, 0.88), 0.08).set_trans(Tween.TRANS_QUAD).se
scripts/screens/TitleScene.gd:154: tw_tap.tween_property(layout.tap_container, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(T
scripts/screens/TitleScene.gd:168: var tw_out := create_tween()
scripts/screens/TitleScene.gd:169: tw_out.tween_property(layout.fade_overlay, "modulate:a", 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween
scripts/screens/TitleScene.gd:24: var _pencil_tween: Tween = null
scripts/screens/TitleScene.gd:25: var _pulse_tween: Tween = null
scripts/screens/TitleScene.gd:80: _pencil_tween = create_tween().set_loops()
scripts/screens/TitleScene.gd:81: _pencil_tween.tween_property(layout.pencil, "rotation_degrees", 14.0, 0.42).set_trans(Tween.TRANS_SINE).set_ea
scripts/screens/TitleScene.gd:82: _pencil_tween.tween_property(layout.pencil, "rotation_degrees", -10.0, 0.42).set_trans(Tween.TRANS_SINE).set_e
scripts/screens/TitleScene.gd:94: var tw_in := create_tween()
scripts/screens/TitleScene.gd:95: tw_in.tween_property(layout.fade_overlay, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.
scripts/systems/ShopCardTap.gd:64: if old is Tween and (old as Tween).is_valid():
scripts/systems/ShopCardTap.gd:65: (old as Tween).kill()
scripts/systems/ShopCardTap.gd:67: var tw := node.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
scripts/systems/ShopCardTap.gd:77: var tw := node.create_tween()
scripts/systems/ShopCardTap.gd:91: (node as Node).get_tree().create_timer(ARM_SECONDS).timeout.connect(func() -> void:
scripts/utils/DockStyleJ.gd:91: var tween := button.create_tween().set_parallel(true)
scripts/utils/DockStyleJ.gd:92: tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/utils/UIAnim.gd:110: (state["tween"] as Tween).kill()
scripts/utils/UIAnim.gd:112: var tw := btn.create_tween()
scripts/utils/UIAnim.gd:114: var press_prop := tw.tween_property(btn, "position:y", state["origin_y"] + press_offset, duration)
scripts/utils/UIAnim.gd:115: press_prop.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
scripts/utils/UIAnim.gd:121: (state["tween"] as Tween).kill()
scripts/utils/UIAnim.gd:123: var tw := btn.create_tween()
scripts/utils/UIAnim.gd:127: var release_prop := tw.tween_property(btn, "position:y", state["origin_y"], duration * RELEASE_TIME_SCALE)
scripts/utils/UIAnim.gd:128: release_prop.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/utils/UIAnim.gd:146: static func play_fade_in(node: Control, delay := 0.0, duration := 0.25) -> Tween:
scripts/utils/UIAnim.gd:150: var tw := node.create_tween()
scripts/utils/UIAnim.gd:153: tw.tween_property(node, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
scripts/utils/UIAnim.gd:158: static func play_pop_in(node: Control, delay := 0.0, from_scale := 0.85, duration := 0.24) -> Tween:
scripts/utils/UIAnim.gd:164: var tw := node.create_tween()
scripts/utils/UIAnim.gd:168: tw.tween_property(node, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
scripts/utils/UIAnim.gd:169: tw.tween_property(node, "modulate:a", 1.0, duration * 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT
scripts/utils/UIAnim.gd:178: static func play_slide_in(node: Control, offset := Vector2(0, 35), delay := 0.0, duration := 0.28) -> Tween:
scripts/utils/UIAnim.gd:194: var tw := node.create_tween()
scripts/utils/UIAnim.gd:199: tw.tween_property(node, "offset_left", base_left, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_O
scripts/utils/UIAnim.gd:200: tw.tween_property(node, "offset_right", base_right, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE
scripts/utils/UIAnim.gd:201: tw.tween_property(node, "offset_top", base_top, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT
scripts/utils/UIAnim.gd:202: tw.tween_property(node, "offset_bottom", base_bottom, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EA
scripts/utils/UIAnim.gd:203: tw.tween_property(node, "modulate:a", 1.0, duration * 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OU
scripts/utils/UIAnim.gd:208: static func play_pulse(node: Control, max_scale := 1.035, cycle_duration := 1.6) -> Tween:
scripts/utils/UIAnim.gd:212: var tw := node.create_tween().set_loops()
scripts/utils/UIAnim.gd:214: tw.tween_property(node, "scale", Vector2.ONE * max_scale, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween
scripts/utils/UIAnim.gd:215: tw.tween_property(node, "scale", Vector2.ONE, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT
scripts/utils/UIAnim.gd:220: static func play_float_idle(node: Control, distance_y := 6.0, cycle_duration := 2.4) -> Tween:
scripts/utils/UIAnim.gd:224: var tw := node.create_tween().set_loops()
scripts/utils/UIAnim.gd:226: tw.tween_property(node, "position:y", initial_y - distance_y, quarter * 2).set_trans(Tween.TRANS_SINE).set_eas
scripts/utils/UIAnim.gd:227: tw.tween_property(node, "position:y", initial_y, quarter * 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_
scripts/utils/UIAnim.gd:254: var tw := label.create_tween().set_parallel(true)
scripts/utils/UIAnim.gd:255: tw.tween_property(label, "position:y", world_pos.y - 55.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Twee
scripts/utils/UIAnim.gd:256: tw.tween_property(label, "scale", Vector2(1.15, 1.15), duration * 0.25).set_trans(Tween.TRANS_BACK).set_ease(T
scripts/utils/UIAnim.gd:258: tw.tween_property(label, "modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6).set_trans(Tween.TRANS_QU
scripts/utils/UIAnim.gd:264: static func animate_counter(label: Label, from_val: int, to_val: int, duration := 0.45, prefix := "", suffix :
scripts/utils/UIAnim.gd:267: var tw := label.create_tween()
scripts/utils/UIAnim.gd:275: ).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
scripts/utils/UIAnim.gd:58: (press_state["tween"] as Tween).kill()
scripts/utils/UIAnim.gd:60: var tw := btn.create_tween()
scripts/utils/UIAnim.gd:62: tw.tween_property(btn, "scale", Vector2.ONE * scale_down, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween
scripts/utils/UIAnim.gd:67: (press_state["tween"] as Tween).kill()
scripts/utils/UIAnim.gd:69: var tw := btn.create_tween()
scripts/utils/UIAnim.gd:71: tw.tween_property(btn, "scale", Vector2.ONE * 1.035, duration * 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Twee
scripts/utils/UIAnim.gd:72: tw.tween_property(btn, "scale", Vector2.ONE, duration * 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_O
scripts/utils/UIAnim.gd:79: (press_state["tween"] as Tween).kill()
scripts/utils/UIAnim.gd:80: var tw := btn.create_tween()
scripts/utils/UIAnim.gd:82: tw.tween_property(btn, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
