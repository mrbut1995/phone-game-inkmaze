# InkMaze — thay đổi
Mọi file trong thư mục này nằm ĐÚNG đường dẫn project (res://). Chép đè vào project, rồi XOÁ các file trong `DELETED_FILES.txt`.
Sau khi chép: mở Godot để nó reimport (`string*.csv` -> `.translation`, ảnh PNG mới).

## Tổng kết
- Sửa: 52 · Mới: 4 · Xoá: 58

## File mới
- `assets/images-png/game/cell_teleport_glow.png`
- `assets/images-png/game/icon_key.png`
- `assets/images-png/game/icon_lock_cell.png`
- `resources/achievements/sp_no_teleport_10.tres`

## File xoá
Xem `DELETED_FILES.txt`.

## Diff từng file sửa

### `nodes/game/cell.tscn`
```diff
--- a/nodes/game/cell.tscn
+++ b/nodes/game/cell.tscn
@@ -17,4 +17,7 @@
 [ext_resource type="Texture2D" uid="uid://cowu67bwhbm4n" path="res://assets/images-png/game/cell_start.png" id="14_start"]
 [ext_resource type="Texture2D" uid="uid://dqyi8ijauyy0j" path="res://assets/images-png/game/cell_finish.png" id="15_finish"]
+[ext_resource type="Texture2D" path="res://assets/images-png/game/icon_key.png" id="16_key"]
+[ext_resource type="Texture2D" path="res://assets/images-png/game/icon_lock_cell.png" id="17_lock"]
+[ext_resource type="Texture2D" path="res://assets/images-png/game/cell_teleport_glow.png" id="18_tpglow"]
 
 [sub_resource type="Animation" id="Animation_cell_reset"]
@@ -217,4 +220,21 @@
 }
 
+[sub_resource type="Animation" id="Animation_cell_teleport_glow"]
+resource_name = "teleport_glow"
+length = 0.9
+loop_mode = 1
+tracks/0/type = "value"
+tracks/0/imported = false
+tracks/0/enabled = true
+tracks/0/path = NodePath("Sprite/TeleportGlow:modulate")
+tracks/0/interp = 1
+tracks/0/loop_wrap = true
+tracks/0/keys = {
+"times": PackedFloat32Array(0, 0.45, 0.9),
+"transitions": PackedFloat32Array(1, 1, 1),
+"update": 0,
+"values": [Color(1, 1, 1, 0.55), Color(1, 1, 1, 1), Color(1, 1, 1, 0.55)]
+}
+
 [sub_resource type="AnimationLibrary" id="AnimationLibrary_cell"]
 _data = {
@@ -226,8 +246,9 @@
 &"shudder": SubResource("Animation_cell_shudder"),
 &"step": SubResource("Animation_cell_step"),
+&"teleport_glow": SubResource("Animation_cell_teleport_glow"),
 &"win": SubResource("Animation_cell_win")
 }
 
-[node name="Cell" type="Control" unique_id=1607724359 node_paths=PackedStringArray("button", "label", "bomb", "warn", "warn_label", "faded", "faded_badge", "faded_label", "visited", "visited_label", "satisfied", "anim", "entrance_timer", "win_timer")]
+[node name="Cell" type="Control" unique_id=1607724359 node_paths=PackedStringArray("button", "label", "bomb", "warn", "warn_label", "faded", "faded_badge", "faded_label", "visited", "visited_label", "satisfied", "lock", "key_icon", "teleport_glow", "anim", "entrance_timer", "win_timer")]
 layout_mode = 3
 anchors_preset = 0
@@ -247,4 +268,7 @@
 visited_label = NodePath("Sprite/VisitedLabel")
 satisfied = NodePath("Sprite/Satisfied")
+lock = NodePath("Sprite/Lock")
+key_icon = NodePath("Sprite/Key")
+teleport_glow = NodePath("Sprite/TeleportGlow")
 anim = NodePath("AnimationPlayer")
 entrance_timer = NodePath("EntranceTimer")
@@ -406,4 +430,46 @@
 vertical_alignment = 1
 
+[node name="Lock" type="TextureRect" parent="Sprite" index="10"]
+visible = false
+layout_mode = 1
+anchors_preset = -1
+anchor_left = 0.18
+anchor_top = 0.18
+anchor_right = 0.82
+anchor_bottom = 0.82
+grow_horizontal = 2
+grow_vertical = 2
+mouse_filter = 2
+texture = ExtResource("17_lock")
+expand_mode = 1
+stretch_mode = 5
+
+[node name="Key" type="TextureRect" parent="Sprite" index="11"]
+visible = false
+layout_mode = 1
+anchors_preset = -1
+anchor_left = 0.56
+anchor_top = 0.04
+anchor_right = 0.96
+anchor_bottom = 0.44
+grow_horizontal = 2
+grow_vertical = 2
+mouse_filter = 2
+texture = ExtResource("16_key")
+expand_mode = 1
+stretch_mode = 5
+
+[node name="TeleportGlow" type="TextureRect" parent="Sprite" index="12"]
+visible = false
+layout_mode = 1
+anchors_preset = 15
+anchor_right = 1.0
+anchor_bottom = 1.0
+grow_horizontal = 2
+grow_vertical = 2
+mouse_filter = 2
+texture = ExtResource("18_tpglow")
+expand_mode = 1
+
 [node name="AnimationPlayer" type="AnimationPlayer" parent="."]
 libraries = {
```

### `nodes/hud/landscape/game/action_bar.tscn`
```diff
--- a/nodes/hud/landscape/game/action_bar.tscn
+++ b/nodes/hud/landscape/game/action_bar.tscn
@@ -70,6 +70,6 @@
 texture_margin_bottom = 20.0
 
-[sub_resource type="Animation" id="Animation_undo_pulse_l"]
-resource_name = "pulse_undo"
+[sub_resource type="Animation" id="Animation_teleport_pulse_l"]
+resource_name = "pulse_teleport"
 length = 0.7
 loop_mode = 1
@@ -77,5 +77,5 @@
 tracks/0/imported = false
 tracks/0/enabled = true
-tracks/0/path = NodePath("SubRow/Undo:scale")
+tracks/0/path = NodePath("SubRow/Teleport:scale")
 tracks/0/interp = 1
 tracks/0/loop_wrap = true
@@ -87,7 +87,7 @@
 }
 
-[sub_resource type="AnimationLibrary" id="AnimationLibrary_undo_pulse_l"]
+[sub_resource type="AnimationLibrary" id="AnimationLibrary_teleport_pulse_l"]
 _data = {
-&"pulse_undo": SubResource("Animation_undo_pulse_l")
+&"pulse_teleport": SubResource("Animation_teleport_pulse_l")
 }
 
@@ -196,9 +196,9 @@
 metadata/_edit_use_anchors_ = true
 
-[node name="Undo" type="TextureButton" parent="SubRow" unique_id=293478108 node_paths=PackedStringArray("panel_limit", "limit_label")]
+[node name="Teleport" type="TextureButton" parent="SubRow" unique_id=293478108 node_paths=PackedStringArray("panel_limit", "limit_label")]
 layout_mode = 2
 size_flags_horizontal = 4
 size_flags_vertical = 4
-tooltip_text = "STR_TOOL_UNDO"
+tooltip_text = "STR_TOOL_TELEPORT"
 texture_normal = ExtResource("10_nytdo")
 texture_pressed = ExtResource("11_t30dy")
@@ -211,5 +211,5 @@
 limit_label = NodePath("PanelLimit/Label")
 
-[node name="PanelLimit" type="Control" parent="SubRow/Undo" unique_id=1634305007]
+[node name="PanelLimit" type="Control" parent="SubRow/Teleport" unique_id=1634305007]
 layout_mode = 1
 anchor_left = 0.59300005
@@ -233,5 +233,5 @@
 metadata/_custom_type_script = "uid://blpdwtvxerh8h"
 
-[node name="Label" type="Label" parent="SubRow/Undo/PanelLimit" unique_id=307457561]
+[node name="Label" type="Label" parent="SubRow/Teleport/PanelLimit" unique_id=307457561]
 layout_mode = 1
 anchors_preset = -1
@@ -304,4 +304,4 @@
 [node name="PulseAnim" type="AnimationPlayer" parent="."]
 libraries = {
-"": SubResource("AnimationLibrary_undo_pulse_l")
+"": SubResource("AnimationLibrary_teleport_pulse_l")
 }
```

### `nodes/hud/portrait/game/action_bar.tscn`
```diff
--- a/nodes/hud/portrait/game/action_bar.tscn
+++ b/nodes/hud/portrait/game/action_bar.tscn
@@ -73,6 +73,6 @@
 texture_margin_bottom = 20.0
 
-[sub_resource type="Animation" id="Animation_undo_pulse_p"]
-resource_name = "pulse_undo"
+[sub_resource type="Animation" id="Animation_teleport_pulse_p"]
+resource_name = "pulse_teleport"
 length = 0.7
 loop_mode = 1
@@ -80,5 +80,5 @@
 tracks/0/imported = false
 tracks/0/enabled = true
-tracks/0/path = NodePath("Row/Undo:scale")
+tracks/0/path = NodePath("Row/Teleport:scale")
 tracks/0/interp = 1
 tracks/0/loop_wrap = true
@@ -90,7 +90,7 @@
 }
 
-[sub_resource type="AnimationLibrary" id="AnimationLibrary_undo_pulse_p"]
+[sub_resource type="AnimationLibrary" id="AnimationLibrary_teleport_pulse_p"]
 _data = {
-&"pulse_undo": SubResource("Animation_undo_pulse_p")
+&"pulse_teleport": SubResource("Animation_teleport_pulse_p")
 }
 
@@ -253,10 +253,10 @@
 size_flags_stretch_ratio = 0.8
 
-[node name="Undo" type="TextureButton" parent="Row" unique_id=1686832729 node_paths=PackedStringArray("panel_limit", "limit_label")]
+[node name="Teleport" type="TextureButton" parent="Row" unique_id=1686832729 node_paths=PackedStringArray("panel_limit", "limit_label")]
 layout_mode = 2
 size_flags_horizontal = 10
 size_flags_vertical = 4
 size_flags_stretch_ratio = 0.2
-tooltip_text = "STR_TOOL_UNDO"
+tooltip_text = "STR_TOOL_TELEPORT"
 texture_normal = ExtResource("bar_undo_n")
 texture_pressed = ExtResource("bar_undo_p")
@@ -266,5 +266,5 @@
 limit_label = NodePath("PanelLimit/Label")
 
-[node name="PanelLimit" type="Control" parent="Row/Undo" unique_id=1117707689]
+[node name="PanelLimit" type="Control" parent="Row/Teleport" unique_id=1117707689]
 layout_mode = 1
 anchor_left = 0.58201104
@@ -289,5 +289,5 @@
 metadata/_edit_use_anchors_ = true
 
-[node name="Label" type="Label" parent="Row/Undo/PanelLimit" unique_id=1581698055]
+[node name="Label" type="Label" parent="Row/Teleport/PanelLimit" unique_id=1581698055]
 layout_mode = 1
 anchors_preset = -1
@@ -359,4 +359,4 @@
 [node name="PulseAnim" type="AnimationPlayer" parent="." unique_id=1415538603]
 libraries = {
-"": SubResource("AnimationLibrary_undo_pulse_p")
+"": SubResource("AnimationLibrary_teleport_pulse_p")
 }
```

### `nodes/tutorials/how_to_use_tool.tscn`
```diff
--- a/nodes/tutorials/how_to_use_tool.tscn
+++ b/nodes/tutorials/how_to_use_tool.tscn
@@ -22,5 +22,5 @@
 message_key = "STR_TUT_TOOL_02"
 fallback_text = "Ví dụ: đi 1 bước rồi nhấn QUAY LẠI — con trỏ tự lùi về ô cũ."
-spotlight_node = NodePath("BoardHost/ToolRow/BtnUndo")
+spotlight_node = NodePath("BoardHost/ToolRow/BtnTeleport")
 
 [sub_resource type="Resource" id="Resource_03"]
@@ -72,10 +72,10 @@
 corner_radius_bottom_left = 9
 
-[node name="HowToUseTool" unique_id=1481527487 node_paths=PackedStringArray("lbl_hud_tools", "btn_undo", "btn_hint", "lbl_undo_count", "lbl_hint_count", "board_tutorial") instance=ExtResource("1_base")]
+[node name="HowToUseTool" unique_id=1481527487 node_paths=PackedStringArray("lbl_hud_tools", "btn_teleport", "btn_hint", "lbl_teleport_count", "lbl_hint_count", "board_tutorial") instance=ExtResource("1_base")]
 script = ExtResource("2_script")
 lbl_hud_tools = NodePath("BoardHost/HudPanel/ToolsLabel")
-btn_undo = NodePath("BoardHost/ToolRow/BtnUndo")
+btn_teleport = NodePath("BoardHost/ToolRow/BtnTeleport")
 btn_hint = NodePath("BoardHost/ToolRow/BtnHint")
-lbl_undo_count = NodePath("BoardHost/ToolRow/BtnUndo/Count")
+lbl_teleport_count = NodePath("BoardHost/ToolRow/BtnTeleport/Count")
 lbl_hint_count = NodePath("BoardHost/ToolRow/BtnHint/Count")
 START_POS = Vector2i(0, 0)
@@ -132,5 +132,5 @@
 mouse_filter = 2
 
-[node name="BtnUndo" type="TextureButton" parent="BoardHost/ToolRow" index="0" unique_id=394739118]
+[node name="BtnTeleport" type="TextureButton" parent="BoardHost/ToolRow" index="0" unique_id=394739118]
 layout_mode = 1
 anchors_preset = -1
@@ -139,5 +139,5 @@
 offset_right = 92.0
 offset_bottom = 64.0
-tooltip_text = "STR_TOOL_UNDO"
+tooltip_text = "STR_TOOL_TELEPORT"
 mouse_default_cursor_shape = 2
 texture_normal = ExtResource("5_undo_n")
@@ -147,5 +147,5 @@
 stretch_mode = 5
 
-[node name="Count" type="Label" parent="BoardHost/ToolRow/BtnUndo" index="0" unique_id=1493195486]
+[node name="Count" type="Label" parent="BoardHost/ToolRow/BtnTeleport" index="0" unique_id=1493195486]
 layout_mode = 1
 anchors_preset = 1
@@ -197,4 +197,4 @@
 
 [connection signal="cell_step_attempted" from="BoardHost/BoardTutorial" to="." method="_on_cell_step_attempted"]
-[connection signal="pressed" from="BoardHost/ToolRow/BtnUndo" to="." method="_on_undo_pressed"]
+[connection signal="pressed" from="BoardHost/ToolRow/BtnTeleport" to="." method="_on_teleport_pressed"]
 [connection signal="pressed" from="BoardHost/ToolRow/BtnHint" to="." method="_on_hint_pressed"]
```

### `resources/localization/string.csv`
```diff
--- a/resources/localization/string.csv
+++ b/resources/localization/string.csv
@@ -33,5 +33,5 @@
 STR_TOOL_MARK_WALL,"MARK WALL","GHI NHỚ","標記牆壁","标记墙壁","MARCAR MURO","تحديد جدار","WAND MARKIEREN","MARQUER MUR","दीवार चिह्नित करें","TANDAI TEMBOK","SEGNALIBRO","壁メモ","벽 표시","TANDA DINDING","MARCAR PAREDE","MARCAR PAREDE","СТЕНА","มาร์กกำแพง","DUVAR İŞARETLE"
 STR_TOOL_MARK_WALL_DESC,"Connect 2 Anchors","Nối 2 Anchor","連接 2 個錨點","连接 2 个锚点","Une 2 anclas","صل بين نقطتين","2 Anker verbinden","Relier 2 points","2 एंकर जोड़ें","Hubungkan 2 titik","Collega 2 punti","アンカー同士を結ぶ","앵커 2개 잇기","Sambung 2 pin","Ligar 2 âncoras","Conecte 2 âncoras","Соединить 2 точки","ลากเชื่อม 2 จุดยึด","2 Çapayı Birleştir"
-STR_TOOL_UNDO,"UNDO","HOÀN TÁC","復原","撤销","DESHACER","تراجع","ZURÜCK","ANNULER","पूर्ववत","BATAL","ANNULLA","元に戻す","실행 취소","BUAT SEMULA","DESFAZER","DESFAZER","ОТМЕНА","เลิกทำ","GERİ AL"
+STR_TOOL_TELEPORT,"TELEPORT","DỊCH CHUYỂN","傳送","传送","TELEPORTE","انتقال","TELEPORT","TÉLÉPORT","टेलीपोर्ट","TELEPORT","TELETRASPORTO","テレポート","순간이동","TELEPORT","TELEPORTE","TELEPORTE","ТЕЛЕПОРТ","วาร์ป","IŞINLAN"
 STR_TOOL_HINT,"HINT","GỢI Ý","提示","提示","PISTA","تلميح","HINWEIS","INDICE","संकेत","PETUNJUK","SUGGERIMENTO","ヒント","힌트","PETUNJUK","PISTA","DICA","ПОДСКАЗКА","คำใบ้","İPUCU"
 STR_GAME_OVER_TITLE,"PATH BROKEN!","ĐỨT ĐOẠN ĐƯỜNG ĐI!","路線中斷！","路线中断！","¡RUTA CORTADA!","المسار مقطوع!","WEG BLOCKIERT!","CHEMIN ROMPU !","रास्ता टूट गया!","JALUR TERPUTUS!","PERCORSO INTERROTTO!","ルート寸断！","경로가 끊어졌습니다!","LALUAN TERPUTUS!","CAMINHO INTERROMPIDO!","CAMINHO INTERROMPIDO!","ПУТЬ ПРЕРВАН!","เส้นทางขาดตอน!","YOL KESİLDİ!"
```

### `resources/localization/string_extra.csv`
```diff
--- a/resources/localization/string_extra.csv
+++ b/resources/localization/string_extra.csv
@@ -208,5 +208,5 @@
 STR_MISSION_SUM_GE,Path sum at least {0},Tổng số đã đi >= {0}
 STR_MISSION_NO_HINT,Do not use hints,Không dùng gợi ý
-STR_MISSION_NO_UNDO,Do not use undo,Không dùng hoàn tác
+STR_MISSION_NO_TELEPORT,Do not use teleport,Không dùng dịch chuyển
 STR_MISSION_ST_OK,OK,ổn
 STR_MISSION_ST_VIOLATED,VIOLATED,VI PHẠM
@@ -217,5 +217,5 @@
 STR_MISSION_ST_REVISITED,{0} revisits,đi đè {0}
 STR_MISSION_ST_HINT_USED,hints {0},gợi ý {0}
-STR_MISSION_ST_UNDO_USED,undos {0},hoàn tác {0}
+STR_MISSION_ST_TELEPORT_USED,teleports {0},dịch chuyển {0}
 STR_MISSION_STEPS_PROGRESS,{0}/{1} steps,{0}/{1} bước
 STR_MISSION_TIME_LEFT,{0}s left,còn {0}s
@@ -378,6 +378,6 @@
 STR_SHOP_THEME_EXAM_NAME,Exam Paper,Tờ Giấy Thi Học Trò
 STR_SHOP_THEME_EXAM_DESC,Thrilling exam-room mood,Không khí phòng thi kịch tính
-STR_SHOP_TOOL_UNDO_NAME,Eraser 4B (x10 Turns),Gôm Tẩy 4B (x10 Lượt)
-STR_SHOP_TOOL_UNDO_DESC,Undo a wrong step without any penalty,Hoàn tác bước đi sai lầm mà không bị tính lỗi hay trừ cước phí
+STR_SHOP_TOOL_TELEPORT_NAME,Warp Pencil (x10 Turns),Bút Dịch Chuyển (x10 Lượt)
+STR_SHOP_TOOL_TELEPORT_DESC,Jump the cursor to any cell within 2 steps — even through walls,Nhảy con trỏ tới ô bất kỳ trong phạm vi 2 ô — kể cả xuyên tường
 STR_SHOP_TOOL_HINT_NAME,Path Magnifier (x5),Kính Lúp Soi Lối (x5)
 STR_SHOP_TOOL_HINT_DESC,Reveal one safe segment of the path,Vạch trần 1 đoạn đường an toàn tránh đâm vào tường vô hình
@@ -452,44 +452,4 @@
 STR_GI_BLINDMEMORY_P3_TAB3,PLACE DRAFT WALLS,DỰNG TƯỜNG NHÁP
 STR_GI_BLINDMEMORY_P3_TITLE,Draft Walls & Hints,Dựng Tường Nháp & Gợi Ý
-STR_GI_COUNTDOWNCOST_CHIP,COUNTDOWN COST,COUNTDOWN COST
-STR_GI_COUNTDOWNCOST_P1_CTA,NEXT: WALL HITS CHARGE THE TOLL (2/3) ›,TIẾP THEO: ĐÂM TƯỜNG TRỪ CƯỚC (2/3) ›
-STR_GI_COUNTDOWNCOST_P1_LINK,Skip guide & start counting the cost now,Bỏ qua hướng dẫn & Vào tính cước ngay
-STR_GI_COUNTDOWNCOST_P1_R1D,Every cell you enter charges its price straight from your budget (1 to 4 steps).,"Mỗi khi bạn bước vào ô nào, ngân sách sẽ trừ thẳng bấy nhiêu bước (từ 1 đến 4 bước)."
-STR_GI_COUNTDOWNCOST_P1_R1T,The Number Is The Cell's Step Cost:,Con Số Là Chi Phí Bước Của Ô:
-STR_GI_COUNTDOWNCOST_P1_R2D,If the step budget runs dry before you reach the Finish hole • Game Over!,Nếu chưa kịp chạm tới hố thang Finish mà đã cạn kiệt ngân sách bước • Game Over!
-STR_GI_COUNTDOWNCOST_P1_R2T,Budget Drops To 0 And You Lose:,Ngân Sách Tụt Về 0 Là Thua Ngay:
-STR_GI_COUNTDOWNCOST_P1_R3D,Numbers here never mark walls — they only show the step cost of walking through.,Con số ở chế độ này hoàn toàn không báo vị trí tường — chỉ biểu thị chi phí bước đi.
-STR_GI_COUNTDOWNCOST_P1_R3T,Nothing To Do With Wall Counts:,Không Liên Quan Tới Số Tường:
-STR_GI_COUNTDOWNCOST_P1_SECTION,STEP COST RULES,QUY TẮC CHI PHÍ BƯỚC
-STR_GI_COUNTDOWNCOST_P1_TAB1,BUDGET & TOLLS,NGÂN SÁCH & CƯỚC
-STR_GI_COUNTDOWNCOST_P1_TAB2,WALL HITS COST STEPS,ĐÂM TƯỜNG TRỪ BƯỚC
-STR_GI_COUNTDOWNCOST_P1_TAB3,OPTIMIZE COST,TỐI ƯU CHI PHÍ
-STR_GI_COUNTDOWNCOST_P1_TITLE,Budget & Cell Tolls,Ngân Sách & Giá Cước Ô
-STR_GI_COUNTDOWNCOST_P2_CTA,NEXT: OPTIMIZE COST & UNDO (3/3) ›,TIẾP THEO: TỐI ƯU CHI PHÍ & UNDO (3/3) ›
-STR_GI_COUNTDOWNCOST_P2_LINK,Skip guide & start counting the cost now,Bỏ qua hướng dẫn & Vào tính cước ngay
-STR_GI_COUNTDOWNCOST_P2_R1D,Hitting an invisible wall bounces you back to S and charges the cost of the cell you tried to enter.,Đâm vào tường vô hình sẽ văng về S và trừ thẳng chi phí của ô bạn vừa toan bước vào.
-STR_GI_COUNTDOWNCOST_P2_R1T,Wall Hits Still Charge The Toll:,Đâm Tường Vẫn Bị Phạt Cước Bước:
-STR_GI_COUNTDOWNCOST_P2_R2D,Just 2-3 big cells can wipe your entire budget. Prefer routes through cells 1 and 2.,Chỉ 2-3 ô số to là đủ vét sạch ngân sách của bạn. Hãy ưu tiên các tuyến đường qua ô 1 và 2.
-STR_GI_COUNTDOWNCOST_P2_R2T,Avoid Cells 3 & 4:,Hạn Chế Bước Vào Ô Số 3 & Số 4:
-STR_GI_COUNTDOWNCOST_P2_R3D,The wall you hit stays visible on the board. Don't hit it twice and burn more budget!,Bức tường bị đâm sẽ hiện rõ trên bàn cờ. Đừng đâm lại lần thứ hai làm tiêu hao ngân sách!
-STR_GI_COUNTDOWNCOST_P2_R3T,Walls Reveal Themselves As Lessons:,Tường Lộ Ra Để Rút Kinh Nghiệm:
-STR_GI_COUNTDOWNCOST_P2_SECTION,WALL HIT & TOLL RULES,QUY TẮC ĐÂM TƯỜNG & CƯỚC PHÍ
-STR_GI_COUNTDOWNCOST_P2_TAB1,BUDGET & TOLLS,NGÂN SÁCH & CƯỚC
-STR_GI_COUNTDOWNCOST_P2_TAB2,WALL HITS COST STEPS,ĐÂM TƯỜNG TRỪ BƯỚC
-STR_GI_COUNTDOWNCOST_P2_TAB3,OPTIMIZE COST,TỐI ƯU CHI PHÍ
-STR_GI_COUNTDOWNCOST_P2_TITLE,Wall Hits & Pricey-Cell Traps,Đâm Tường & Bẫy Ô Đắt
-STR_GI_COUNTDOWNCOST_P3_CTA,UNDERSTOOD • OPTIMIZE THE BUDGET,ĐÃ HIỂU • TỐI ƯU NGÂN SÁCH
-STR_GI_COUNTDOWNCOST_P3_LINK,Review from the start (Page 1),Xem lại từ đầu (Trang 1)
-STR_GI_COUNTDOWNCOST_P3_R1D,Add up the cell values along each route; pick the branch with the smallest total to reach F.,Nhẩm tính tổng số điểm của các ô trên đường đi; chọn nhánh có tổng số nhỏ nhất để tới F.
-STR_GI_COUNTDOWNCOST_P3_R1T,Scout The Cheapest Route First:,Tìm Tuyến Đường Rẻ Nhất Trước Khi Vẽ:
-STR_GI_COUNTDOWNCOST_P3_R2D,"If a branch turns out too costly, Undo back and recover every step already spent.","Nếu nhận thấy nhánh đang đi quá tốn bước, hãy Undo lùi lại để nhận lại toàn bộ số bước đã trừ."
-STR_GI_COUNTDOWNCOST_P3_R2T,Use Undo To Reclaim Budget:,Tận Dụng Undo Để Thu Hồi Ngân Sách:
-STR_GI_COUNTDOWNCOST_P3_R3D,"The fewer steps you burn on the way to the exit, the higher you rank!",Người chơi về đích với tổng chi phí bước tiêu tốn càng ít sẽ giành thứ hạng càng cao!
-STR_GI_COUNTDOWNCOST_P3_R3T,Ranking Rewards Minimum Cost:,Xếp Hạng Dựa Trên Chi Phí Tối Thiểu:
-STR_GI_COUNTDOWNCOST_P3_SECTION,MASTER TIPS,BÍ QUYẾT PHÁ ĐẢO
-STR_GI_COUNTDOWNCOST_P3_TAB1,BUDGET & TOLLS,NGÂN SÁCH & CƯỚC
-STR_GI_COUNTDOWNCOST_P3_TAB2,WALL HITS COST STEPS,ĐÂM TƯỜNG TRỪ BƯỚC
-STR_GI_COUNTDOWNCOST_P3_TAB3,OPTIMIZE COST,TỐI ƯU CHI PHÍ
-STR_GI_COUNTDOWNCOST_P3_TITLE,Optimize Cost & Undo Refunds,Tối Ưu Chi Phí & Hoàn Cước
 STR_GI_DUNGEON_CHIP,ENDLESS MODE,CHẾ ĐỘ VÔ TẬN
 STR_GI_DUNGEON_P1_CTA,NEXT: WALL HIT MECHANICS (2/3) ›,TIẾP THEO: CƠ CHẾ ĐÂM TƯỜNG (2/3) ›
@@ -532,124 +492,4 @@
 STR_GI_DUNGEON_P3_TAB3,ENDLESS TRAPS,BẪY VÔ TẬN
 STR_GI_DUNGEON_P3_TITLE,Endless Traps & Survival Tips,Bẫy Vô Tận & Mẹo Sinh Tồn
-STR_GI_FADINGINK_CHIP,FADING INK,FADING INK • MỰC PHAI
-STR_GI_FADINGINK_P1_CTA,NEXT: DRY CELLS BLOCK THE WAY (2/3) ›,TIẾP THEO: Ô CẠN KHÓA ĐƯỜNG (2/3) ›
-STR_GI_FADINGINK_P1_LINK,Skip guide & start playing now,Bỏ qua hướng dẫn & Vào chơi ngay
-STR_GI_FADINGINK_P1_R1D,Every cell has its own ink. You may only step into cells that STILL have ink (> 0).,Mỗi ô có điểm mực riêng. Chỉ được phép bước vào các ô vẫn CÒN mực (> 0).
-STR_GI_FADINGINK_P1_R1T,The Number Shows Remaining Ink:,Số Trên Ô Thể Hiện Lượng Mực Còn Lại:
-STR_GI_FADINGINK_P1_R2D,Every step you take drains 1 ink from EVERY cell — whether you enter it or not!,"Mỗi bước bạn di chuyển, TẤT CẢ các ô đều bị trừ 1 mực, bất kể bạn có đi vào ô đó hay không!"
-STR_GI_FADINGINK_P1_R2T,The Whole Board Fades One Tick:,Cả Bàn Cờ Cùng Phai Đi Một Nhịp:
-STR_GI_FADINGINK_P1_R3D,The board is wide open; the only obstacles are cells whose ink has run dry.,Bàn cờ thông suốt; chướng ngại vật cản đường bạn duy nhất chính là các ô bị cạn sạch mực.
-STR_GI_FADINGINK_P1_R3T,There Are No Walls At All:,Hoàn Toàn Không Có Bức Tường Nào:
-STR_GI_FADINGINK_P1_SECTION,BASIC INK FADING RULES,QUY TẮC MỰC PHAI CƠ BẢN
-STR_GI_FADINGINK_P1_TAB1,EACH MOVE: -1 INK,MỖI BƯỚC -1 MỰC
-STR_GI_FADINGINK_P1_TAB2,DRY CELLS BLOCK PATHS,Ô CẠN KHÓA ĐƯỜNG
-STR_GI_FADINGINK_P1_TAB3,OPTIMAL PATH & UNDO,ĐƯỜNG TỐI ƯU & UNDO
-STR_GI_FADINGINK_P1_TITLE,Whole-Board Ink Fading,Cơ Chế Phai Mực Toàn Bàn
-STR_GI_FADINGINK_P2_CTA,NEXT: SHORTEST PATH & UNDO (3/3) ›,TIẾP THEO: ĐƯỜNG NGẮN NHẤT & UNDO (3/3) ›
-STR_GI_FADINGINK_P2_LINK,Skip guide & start playing now,Bỏ qua hướng dẫn & Vào chơi ngay
-STR_GI_FADINGINK_P2_R1D,This cell survives exactly one more move. Step in now or it runs completely dry.,"Ô này chỉ tồn tại thêm đúng 1 lượt đi nữa. Nếu bạn không bước vào ngay, nó sẽ cạn sạch."
-STR_GI_FADINGINK_P2_R1T,Orange-Rimmed Cells (1 Ink Left):,Cảnh Báo Ô Viền Cam (Còn 1 Mực):
-STR_GI_FADINGINK_P2_R2D,The number vanishes and the cell greys out. You are blocked from entering a dry cell.,Mất hoàn toàn con số và mờ đi. Người chơi bị chặn không thể bước chân vào ô cạn mực.
-STR_GI_FADINGINK_P2_R2T,0-Ink Cells Become Locked Gaps:,Ô Về 0 Biến Thành Khoảng Trống Bị Khóa:
-STR_GI_FADINGINK_P2_R3D,If every surrounding cell is dry and no route to the F shaft remains • DEAD END!,Nếu các ô xung quanh đều cạn mực và không còn lối nào tới hố thang F • HẾT ĐƯỜNG ĐI!
-STR_GI_FADINGINK_P2_R3T,You Lose When Every Route Is Sealed:,Thua Cuộc Khi Bị Bít Lối Đi:
-STR_GI_FADINGINK_P2_SECTION,DRY INK & BLOCKED PATH RULES,QUY TẮC CẠN MỰC & KHÓA ĐƯỜNG
-STR_GI_FADINGINK_P2_TAB1,EACH MOVE: -1 INK,MỖI BƯỚC -1 MỰC
-STR_GI_FADINGINK_P2_TAB2,DRY CELLS BLOCK PATHS,Ô CẠN KHÓA ĐƯỜNG
-STR_GI_FADINGINK_P2_TAB3,OPTIMAL PATH & UNDO,ĐƯỜNG TỐI ƯU & UNDO
-STR_GI_FADINGINK_P2_TITLE,Dry Cells Block Paths & Warnings,Ô Cạn Khóa Lối & Cảnh Báo
-STR_GI_FADINGINK_P3_CTA,UNDERSTOOD • START DRAWING,ĐÃ HIỂU • BẮT ĐẦU VẼ ĐƯỜNG
-STR_GI_FADINGINK_P3_LINK,Review from the start (Page 1),Xem lại từ đầu (Trang 1)
-STR_GI_FADINGINK_P3_R1D,"Scan the board, count the steps to F and pick the route with the fewest turns.","Nhìn bao quát bàn cờ, đếm số bước tới F và chọn tuyến đường ít ô chuyển hướng nhất."
-STR_GI_FADINGINK_P3_R1T,Plan The Shortest Path First:,Tìm Đường Ngắn Nhất Trước Khi Vẽ:
-STR_GI_FADINGINK_P3_R2D,Wandered into a dead end and lost the cells ahead? Undo to give that ink back.,Lỡ đi vào ngõ cụt làm ô phía trước biến mất? Undo ngay để cứu lại mực cho các ô đó.
-STR_GI_FADINGINK_P3_R2T,Use Undo To Restore The Path:,Tận Dụng Undo Để Hồi Phục Đường Đi:
-STR_GI_FADINGINK_P3_R3D,"This mode has no step limit, but the faster you finish, the higher you rank!","Chế độ này không giới hạn số bước, nhưng hoàn thành càng nhanh thì điểm xếp hạng càng cao!"
-STR_GI_FADINGINK_P3_R3T,The Clock Still Counts:,Đồng Hồ Thời Gian Vẫn Tính Điểm:
-STR_GI_FADINGINK_P3_SECTION,WINNING SECRETS,BÍ QUYẾT CHIẾN THẮNG
-STR_GI_FADINGINK_P3_TAB1,EACH MOVE: -1 INK,MỖI BƯỚC -1 MỰC
-STR_GI_FADINGINK_P3_TAB2,DRY CELLS BLOCK PATHS,Ô CẠN KHÓA ĐƯỜNG
-STR_GI_FADINGINK_P3_TAB3,OPTIMAL PATH & UNDO,ĐƯỜNG TỐI ƯU & UNDO
-STR_GI_FADINGINK_P3_TITLE,Shortest Path & Ink Recovery,Đường Ngắn & Hồi Mực
-STR_GI_FOG_OF_WAR_CHIP,FOG OF WAR,FOG OF WAR • SƯƠNG MÙ
-STR_GI_FOG_OF_WAR_P1_CTA,NEXT: SCOUTING STEP BY STEP (2/3) ›,TIẾP THEO: DÒ ĐƯỜNG TỪNG BƯỚC (2/3) ›
-STR_GI_FOG_OF_WAR_P1_LINK,Skip guide & start scouting now,Bỏ qua hướng dẫn & Vào dò đường ngay
-STR_GI_FOG_OF_WAR_P1_R1D,"You can only read clue numbers from cells directly beside you (horizontal, vertical, diagonal).","Bạn chỉ có thể đọc được manh mối số của các ô nằm ngay sát cạnh (ngang, dọc, chéo)."
-STR_GI_FOG_OF_WAR_P1_R1T,Only Numbers Within 1 Cell Show:,Chỉ Thấy Số Trong Bán Kính 1 Ô:
-STR_GI_FOG_OF_WAR_P1_R2D,The fog hides every number on far cells until you walk close enough.,Màn sương mù ẩn giấu toàn bộ con số của những ô phía xa cho đến khi bạn bước lại gần.
-STR_GI_FOG_OF_WAR_P1_R2T,Distant Cells Stay Fully Fogged:,Các Ô Ở Xa Bị Phủ Mờ Hoàn Toàn:
-STR_GI_FOG_OF_WAR_P1_R3D,Invisible walls still sit between cells — step blindly into the fog and you hit one!,Vẫn có các bức tường vô hình giữa các ô — bước bừa vào sương mù là đâm tường ngay!
-STR_GI_FOG_OF_WAR_P1_R3T,Invisible Walls Still Lurk:,Tường Vô Hình Vẫn Nằm Ẩn Mình:
-STR_GI_FOG_OF_WAR_P1_SECTION,FOG RULES,QUY TẮC MÀN SƯƠNG
-STR_GI_FOG_OF_WAR_P1_TAB1,RADIUS-1 VISION,TẦM NHÌN BÁN KÍNH 1
-STR_GI_FOG_OF_WAR_P1_TAB2,SCOUT STEP BY STEP,DÒ ĐƯỜNG TỪNG BƯỚC
-STR_GI_FOG_OF_WAR_P1_TAB3,MEMORY & TIPS,GHI NHỚ & BÍ QUYẾT
-STR_GI_FOG_OF_WAR_P1_TITLE,The Fog & 1-Cell Vision,Màn Sương & Tầm Nhìn 1 Ô
-STR_GI_FOG_OF_WAR_P2_CTA,NEXT: ANCHOR MEMORY & TIPS (3/3) ›,TIẾP THEO: GHI NHỚ ANCHOR & BÍ QUYẾT (3/3) ›
-STR_GI_FOG_OF_WAR_P2_LINK,Skip guide & start scouting now,Bỏ qua hướng dẫn & Vào dò đường ngay
-STR_GI_FOG_OF_WAR_P2_R1D,Stepping onto a new cell instantly reveals the numbers of the cells touching your front.,Đặt chân tới ô mới sẽ lập tức hé lộ con số của những ô tiếp giáp phía trước mặt bạn.
-STR_GI_FOG_OF_WAR_P2_R1T,Vision Moves With Every Step:,Tầm Nhìn Di Chuyển Theo Từng Bước:
-STR_GI_FOG_OF_WAR_P2_R2D,"Cells beyond your vision are swallowed by fog again, so old numbers are hard to recheck.","Các ô ở xa tầm nhìn sẽ bị sương mù bao phủ trở lại, khiến bạn khó nhìn lại số cũ."
-STR_GI_FOG_OF_WAR_P2_R2T,Cells Behind You Get Re-Fogged:,Ô Cũ Phía Sau Sẽ Bị Che Lại:
-STR_GI_FOG_OF_WAR_P2_R3D,Dare to step into an unlit cell and you may ram a hidden wall and get bounced back to S!,"Nếu bước liều sang ô chưa sáng, bạn có thể đâm trúng tường ẩn và bị phạt văng về điểm S!"
-STR_GI_FOG_OF_WAR_P2_R3T,Risk Of Hitting Invisible Walls:,Nguy Cơ Va Phải Tường Vô Hình:
-STR_GI_FOG_OF_WAR_P2_SECTION,MOVING THROUGH THE FOG,QUY TẮC DI CHUYỂN TRONG SƯƠNG
-STR_GI_FOG_OF_WAR_P2_TAB1,RADIUS-1 VISION,TẦM NHÌN BÁN KÍNH 1
-STR_GI_FOG_OF_WAR_P2_TAB2,SCOUT STEP BY STEP,DÒ ĐƯỜNG TỪNG BƯỚC
-STR_GI_FOG_OF_WAR_P2_TAB3,MEMORY & TIPS,GHI NHỚ & BÍ QUYẾT
-STR_GI_FOG_OF_WAR_P2_TITLE,Scouting With Every Step,Dò Đường Theo Bước Chân
-STR_GI_FOG_OF_WAR_P3_CTA,UNDERSTOOD • BEAT THE FOG,ĐÃ HIỂU • VƯỢT MÀN SƯƠNG
-STR_GI_FOG_OF_WAR_P3_LINK,Review from the start (Page 1),Xem lại từ đầu (Trang 1)
-STR_GI_FOG_OF_WAR_P3_R1D,Don't let fog hide the clues. Connect 2 Anchors to mark orange walls and protect yourself.,Đừng để sương mù che khuất manh mối. Nối 2 Anchor để đánh dấu tường cam bảo vệ bản thân.
-STR_GI_FOG_OF_WAR_P3_R1T,Place Draft Walls While The Glow Shows:,Dựng Tường Nháp Ngay Khi Quầng Sáng Soi Thấy:
-STR_GI_FOG_OF_WAR_P3_R2D,Stuck in a dead end? Tap Hint to reveal 1 correct cell.,"Khi rơi vào ngõ cụt và không đoán được bước tiếp theo, hãy dùng Gợi Ý để soi ra 1 ô đúng."
-STR_GI_FOG_OF_WAR_P3_R2T,Light The Path With Hint:,Bật Đèn Bằng Nút Gợi Ý:
-STR_GI_FOG_OF_WAR_P3_R3D,No step limit here. Reason calmly cell by cell and bring the route home to the F shaft!,Chế độ này không giới hạn số bước. Cứ bình tĩnh suy luận từng ô để đưa lối thoát về hố thang F!
-STR_GI_FOG_OF_WAR_P3_R3T,Advance One Certain Cell At A Time:,Tiến Lên Từng Ô Một Cách Chắc Chắn:
-STR_GI_FOG_OF_WAR_P3_SECTION,WINNING SECRETS,BÍ QUYẾT CHIẾN THẮNG
-STR_GI_FOG_OF_WAR_P3_TAB1,RADIUS-1 VISION,TẦM NHÌN BÁN KÍNH 1
-STR_GI_FOG_OF_WAR_P3_TAB2,SCOUT STEP BY STEP,DÒ ĐƯỜNG TỪNG BƯỚC
-STR_GI_FOG_OF_WAR_P3_TAB3,MEMORY & TIPS,GHI NHỚ & BÍ QUYẾT
-STR_GI_FOG_OF_WAR_P3_TITLE,Anchor Memory & Secrets,Ghi Nhớ Anchor & Bí Quyết
-STR_GI_MINESWEEPER_CHIP,MINESWEEPER MAZE,MINESWEEPER MAZE
-STR_GI_MINESWEEPER_P1_CTA,NEXT: BOMBS & ZERO ZONES (2/3) ›,TIẾP THEO: ĐẠP BOM & VÙNG SỐ 0 (2/3) ›
-STR_GI_MINESWEEPER_P1_LINK,Skip guide & start sweeping now,Bỏ qua hướng dẫn & Vào dò mìn ngay
-STR_GI_MINESWEEPER_P1_R1D,"That includes the 4 orthogonal cells (up, down, left, right) and the 4 diagonal corners.","Bao gồm 4 ô vuông góc (trên, dưới, trái, phải) và 4 ô góc chéo xung quanh."
-STR_GI_MINESWEEPER_P1_R1T,The Number = Bombs In The 8 Neighbor Cells:,Số Trên Ô = Số Bom Trong 8 Ô Lân Cận:
-STR_GI_MINESWEEPER_P1_R2D,The start cell and the finish shaft are 100% bomb-free. A bomb-free route to the exit always exists!,Ô xuất phát và hố thang đích 100% không có bom. Luôn có đường BFS không bom tới đích!
-STR_GI_MINESWEEPER_P1_R2T,Start Stair (S) & Finish (F) Are Always Safe:,Cầu Thang Start (S) & Finish (F) Luôn An Toàn:
-STR_GI_MINESWEEPER_P1_R3D,"Daily boards have no walls — move freely, but only into bomb-free cells. On a designer LEVEL the maze may have walls: they block steps while bombs stay hidden.","Bàn Daily không có tường — đi tự do nhưng chỉ được bước vào ô sạch bom. Ở MÀN do nhà thiết kế vẽ, mê cung CÓ THỂ có tường: tường chặn bước còn bom vẫn ẩn như cũ."
-STR_GI_MINESWEEPER_P1_R3T,Walls: None In Daily · Possible In Levels:,Tường: Daily Không Có · Màn Thiết Kế Có Thể Có:
-STR_GI_MINESWEEPER_P1_SECTION,BASIC MINESWEEPER RULES,QUY TẮC DÒ MÌN CƠ BẢN
-STR_GI_MINESWEEPER_P1_TAB1,8-NEIGHBOR BOMB RULE,LUẬT 8 Ô BOM
-STR_GI_MINESWEEPER_P1_TAB2,BOMBS & ZERO ZONES,ĐẠP BOM & VÙNG 0
-STR_GI_MINESWEEPER_P1_TAB3,BOMB-SWEEPING TOOLS,CÔNG CỤ DÒ BOM
-STR_GI_MINESWEEPER_P1_TITLE,8-Neighbor Mine Rules,Luật Dò Mìn 8 Ô
-STR_GI_MINESWEEPER_P2_CTA,NEXT: TOOLS & FLAGGING (3/3) ›,TIẾP THEO: CÔNG CỤ DÒ BOM & CẮM CỜ (3/3) ›
-STR_GI_MINESWEEPER_P2_LINK,Skip guide & start sweeping now,Bỏ qua hướng dẫn & Vào dò mìn ngay
-STR_GI_MINESWEEPER_P2_R1D,The run stops immediately. You stand on the blast cell and can revive one step back.,Ván đấu dừng ngay tức khắc. Bạn đứng tại ô nổ và có thể hồi sinh lùi lại 1 bước.
-STR_GI_MINESWEEPER_P2_R1T,Stepping On A Bomb:,Hậu Quả Khi Đạp Trúng Bom:
-STR_GI_MINESWEEPER_P2_R2D,"If a cell shows 0, all 8 cells around it are 100% bomb-free — route through that zone!","Nếu ô có số 0, toàn bộ 8 ô kề cạnh nó 100% không có bom — hãy đi qua vùng này!"
-STR_GI_MINESWEEPER_P2_R2T,Exploit Zero Cells To The Fullest:,Tận Dụng Triệt Để Các Ô Số 0:
-STR_GI_MINESWEEPER_P2_R3D,Don't swipe fast; only draw into cells you are certain are safe.,Không vội vàng kéo lướt nhanh; chỉ vẽ vào các ô bạn đã chắc chắn an toàn.
-STR_GI_MINESWEEPER_P2_R3T,Draw Your Line Slowly:,Kéo Nét Vẽ Chậm Rãi:
-STR_GI_MINESWEEPER_P2_SECTION,PATH-SCOUTING TACTICS,CHIẾN THUẬT DÒ ĐƯỜNG
-STR_GI_MINESWEEPER_P2_TAB1,8-NEIGHBOR BOMB RULE,LUẬT 8 Ô BOM
-STR_GI_MINESWEEPER_P2_TAB2,BOMBS & ZERO ZONES,ĐẠP BOM & VÙNG 0
-STR_GI_MINESWEEPER_P2_TAB3,BOMB-SWEEPING TOOLS,CÔNG CỤ DÒ BOM
-STR_GI_MINESWEEPER_P2_TITLE,Bomb Detonation & Zero Zones,Đạp Bom Nổ & Vùng Số 0
-STR_GI_MINESWEEPER_P3_CTA,UNDERSTOOD • START SWEEPING,ĐÃ HIỂU • BẮT ĐẦU DÒ MÌN
-STR_GI_MINESWEEPER_P3_LINK,Review from the start (Page 1),Xem lại từ đầu (Trang 1)
-STR_GI_MINESWEEPER_P3_R1D,"When a cell is certain to hold a bomb, flag it right away so a swipe can't touch it.","Khi phát hiện ô chắc chắn có bom, hãy cắm cờ khóa ô lại ngay để tránh tay quẹt trúng."
-STR_GI_MINESWEEPER_P3_R1T,Flag Before You Draw:,Cắm Cờ Trước Khi Vẽ Đường:
-STR_GI_MINESWEEPER_P3_R2D,Cross-check your flags against the HUD's remaining bombs so none slip past.,Đối chiếu số cờ đã cắm với số bom còn lại trên HUD để đảm bảo không bỏ sót quả nào.
-STR_GI_MINESWEEPER_P3_R2T,Check The Bomb Total On The HUD:,Kiểm Tra Tổng Số Bom Trên HUD:
-STR_GI_MINESWEEPER_P3_R3D,"If you step on a bomb, revive to return to the previous cell and try another direction.","Nếu lỡ đạp trúng bom, bạn có thể hồi sinh để quay lại ô ngay trước đó và thử hướng khác."
-STR_GI_MINESWEEPER_P3_R3T,Revive To Take Back The Bad Step:,Hồi Sinh Rút Lại Bước Lỗi:
-STR_GI_MINESWEEPER_P3_SECTION,MASTER TIPS,BÍ QUYẾT PHÁ ĐẢO
-STR_GI_MINESWEEPER_P3_TAB1,8-NEIGHBOR BOMB RULE,LUẬT 8 Ô BOM
-STR_GI_MINESWEEPER_P3_TAB2,BOMBS & ZERO ZONES,ĐẠP BOM & VÙNG 0
-STR_GI_MINESWEEPER_P3_TAB3,BOMB-SWEEPING TOOLS,CÔNG CỤ DÒ BOM
-STR_GI_MINESWEEPER_P3_TITLE,Tools & The Bomb-Count HUD,Công Cụ & HUD Đếm Bom
 STR_GI_NORMAL_MAZE_CHIP,HOW TO PLAY,HƯỚNG DẪN CHƠI
 STR_GI_NORMAL_MAZE_P1_CTA,NEXT: NUMBER CLUES (2/3) ›,TIẾP THEO: MANH MỐI SỐ (2/3) ›
@@ -692,85 +532,5 @@
 STR_GI_NORMAL_MAZE_P3_TAB3,TOOLS,CÔNG CỤ
 STR_GI_NORMAL_MAZE_P3_TITLE,Helper Tools,Công Cụ Trợ Giúp
-STR_GI_ONE_STROKE_CHIP,ONE STROKE • ONE LINE,ONE STROKE • MỘT NÉT
-STR_GI_ONE_STROKE_P1_CTA,NEXT: NO RE-ENTERING OLD CELLS (2/3) ›,TIẾP THEO: CẤM ĐI LẠI Ô CŨ (2/3) ›
-STR_GI_ONE_STROKE_P1_LINK,Skip the guide & start drawing now,Bỏ qua hướng dẫn & Vào vẽ một nét ngay
-STR_GI_ONE_STROKE_P1_R1D,Every wall shows up front — the whole mission is the order of your steps to cover the board.,Mọi vách ngăn đều hiện sẵn. Toàn bộ nhiệm vụ là tìm thứ tự đi bao phủ trọn vẹn bàn cờ.
-STR_GI_ONE_STROKE_P1_R1T,"Walls Are Visible, No Numbers At All:","Tường Nhìn Thấy Rõ, Hoàn Toàn Không Có Số:"
-STR_GI_ONE_STROKE_P1_R2D,The stroke must fill 100% of the board — no cell may be left empty before you finish.,"Nét vẽ phải lấp đầy 100% diện tích, không được bỏ trống bất kỳ một ô nào trước khi về đích."
-STR_GI_ONE_STROKE_P1_R2T,You Must Visit Every Cell On The Board:,Phải Đi Hết Tất Cả Các Ô Thuộc Bàn Cờ:
-STR_GI_ONE_STROKE_P1_R3D,Touching F while empty cells remain is blocked — F must be the very last cell of your stroke!,Chạm vào F khi vẫn còn ô trống chưa đi sẽ bị chặn lại — F phải là ô cuối cùng của nét vẽ!
-STR_GI_ONE_STROKE_P1_R3T,The Finish Hole (F) Is The Last Stop:,Hố Thang Finish (F) Là Điểm Dừng Chân Cuối:
-STR_GI_ONE_STROKE_P1_SECTION,ONE-STROKE RULES,QUY TẮC MỘT NÉT KÍN TRANG
-STR_GI_ONE_STROKE_P1_TAB1,COVER EVERY CELL,PHỦ KÍN MỌI Ô
-STR_GI_ONE_STROKE_P1_TAB2,NO RE-ENTERING OLD CELLS,CẤM ĐI LẠI Ô CŨ
-STR_GI_ONE_STROKE_P1_TAB3,REACH F & UNDO,CHẠM ĐÍCH F & UNDO
-STR_GI_ONE_STROKE_P1_TITLE,Draw One Stroke Covering Every Cell,Vẽ 1 Nét Phủ Kín Mọi Ô
-STR_GI_ONE_STROKE_P2_CTA,NEXT: REACHING F & UNDO (3/3) ›,TIẾP THEO: CHẠM ĐÍCH F & UNDO (3/3) ›
-STR_GI_ONE_STROKE_P2_LINK,Skip the guide & start drawing now,Bỏ qua hướng dẫn & Vào vẽ một nét ngay
-STR_GI_ONE_STROKE_P2_R1D,A visited cell locks forever. Drawing back over your own trail • Game Over instantly!,Ô đã đi qua sẽ bị khóa vĩnh viễn. Cố tình kéo nét vẽ đè vào đường cũ • Game Over ngay!
-STR_GI_ONE_STROKE_P2_R1T,Stepping On An Old Cell = Instant Loss:,Đi Vào Ô Cũ = Thua Ngay Lập Tức:
-STR_GI_ONE_STROKE_P2_R2D,Don't slice the board in half across empty cells — you can never come back for the ones left behind.,"Đừng đi vắt ngang bàn cờ chia đôi ô trống, vì bạn sẽ không thể quay lại đón các ô bị bỏ lại."
-STR_GI_ONE_STROKE_P2_R2T,Avoid Cut-Off Traps That Isolate Cells:,Tránh Bẫy Cắt Ngang Làm Cô Lập Ô:
-STR_GI_ONE_STROKE_P2_R3D,"If the way ahead is a dead end, don't force it — use Undo instead (see Page 3).","Nếu nhận ra phía trước là đường cùng, đừng cố đi liều — hãy dùng Undo (xem Trang 3)."
-STR_GI_ONE_STROKE_P2_R3T,Stop When The Path Runs Dead:,Dừng Lại Khi Bị Cụt Đường:
-STR_GI_ONE_STROKE_P2_SECTION,SURVIVAL RULES,QUY TẮC SỐNG CÒN
-STR_GI_ONE_STROKE_P2_TAB1,COVER EVERY CELL,PHỦ KÍN MỌI Ô
-STR_GI_ONE_STROKE_P2_TAB2,NO RE-ENTERING OLD CELLS,CẤM ĐI LẠI Ô CŨ
-STR_GI_ONE_STROKE_P2_TAB3,REACH F & UNDO,CHẠM ĐÍCH F & UNDO
-STR_GI_ONE_STROKE_P2_TITLE,Never Re-Enter A Cell,Cấm Đi Lại Đường Đã Qua
-STR_GI_ONE_STROKE_P3_CTA,GOT IT • START THE ONE STROKE,ĐÃ HIỂU • BẮT ĐẦU VẼ MỘT NÉT
-STR_GI_ONE_STROKE_P3_LINK,Review from the start (Page 1),Xem lại từ đầu (Trang 1)
-STR_GI_ONE_STROKE_P3_R1D,Watch the HUD progress bar: only at 100% coverage may you lead the stroke into the finish hole F.,Kiểm tra thanh tiến độ trên HUD: Phải đạt 100% số ô rồi mới được dẫn nét vẽ vào hố thang F.
-STR_GI_ONE_STROKE_P3_R1T,Step Into F Only On Your Final Move:,Chỉ Bước Vào F Ở Nước Đi Cuối Cùng:
-STR_GI_ONE_STROKE_P3_R2D,Took a wrong branch? Tap Undo to step back and reopen the cells you just crossed — with no risk of a Game Over.,Lỡ đi sai nhánh? Bấm Undo để lùi bước và mở lại các ô vừa đi mà không lo bị Game Over.
-STR_GI_ONE_STROKE_P3_R2T,Use Undo In Time To Reopen Cells:,Dùng Undo Kịp Thời Để Mở Lại Ô:
-STR_GI_ONE_STROKE_P3_R3D,"The Hint button points out the next correct cell, or warns you when the branch you are on is completely dead.","Nút Gợi Ý sẽ chỉ ra 1 ô đúng kế tiếp, hoặc cảnh báo nếu nhánh bạn đang đi đã hoàn toàn bế tắc."
-STR_GI_ONE_STROKE_P3_R3T,Use Hint When You Lose Your Way:,Dùng Gợi Ý (Hint) Khi Mất Hướng:
-STR_GI_ONE_STROKE_P3_SECTION,MASTER TIPS,BÍ QUYẾT PHÁ ĐẢO
-STR_GI_ONE_STROKE_P3_TAB1,COVER EVERY CELL,PHỦ KÍN MỌI Ô
-STR_GI_ONE_STROKE_P3_TAB2,NO RE-ENTERING OLD CELLS,CẤM ĐI LẠI Ô CŨ
-STR_GI_ONE_STROKE_P3_TAB3,REACH F & UNDO,CHẠM ĐÍCH F & UNDO
-STR_GI_ONE_STROKE_P3_TITLE,Reach F & Use Undo,Chạm Đích F & Dùng Undo
 STR_GI_PAGE_INDEX,PAGE {0} / {1},TRANG {0} / {1}
-STR_GI_SUMPATH_CHIP,SUM PATH,SUM PATH • TOÁN ĐỐ
-STR_GI_SUMPATH_P1_CTA,NEXT: OPERATORS & ONE-TIME CELLS (2/3) ›,TIẾP THEO: TOÁN TỬ & Ô 1 LẦN (2/3) ›
-STR_GI_SUMPATH_P1_LINK,Skip guide & start scoring now,Bỏ qua hướng dẫn & Vào cộng điểm ngay
-STR_GI_SUMPATH_P1_R1D,"No walls, no hidden bombs. Every cell on the board is simply a score value.","Không có tường chắn, không có bom ẩn. Mỗi ô trên bàn cờ đóng vai trò là một điểm số."
-STR_GI_SUMPATH_P1_R1T,The Number Is The Cell's Score (1 to 9):,Con Số Là Điểm Số Của Ô (1 đến 9):
-STR_GI_SUMPATH_P1_R2D,"Each time your line enters a new cell, its value is added straight to the Current Total card.","Mỗi khi nét vẽ kéo sang ô mới, điểm ô đó sẽ lập tức được cộng dồn vào thẻ Tổng Hiện Tại."
-STR_GI_SUMPATH_P1_R2T,Values Add Up Continuously:,Cộng Dồn Liên Tục Vào Tổng Điểm:
-STR_GI_SUMPATH_P1_R3D,You only win by touching the Finish hole F with a Total that satisfies the required math.,Chỉ chiến thắng khi bạn chạm Hố Thang Đích F với Tổng Điểm thỏa mãn đúng phép tính yêu cầu.
-STR_GI_SUMPATH_P1_R3T,Reach The Exit With The Exact Target:,Chạm Đích Khớp Đúng Mục Tiêu:
-STR_GI_SUMPATH_P1_SECTION,BASIC SUMMING RULES,QUY TẮC CỘNG TỔNG CƠ BẢN
-STR_GI_SUMPATH_P1_TAB1,SUMS & TARGETS,CỘNG TỔNG & MỤC TIÊU
-STR_GI_SUMPATH_P1_TAB2,OPERATORS & ONE-TIME CELLS,TOÁN TỬ & Ô 1 LẦN
-STR_GI_SUMPATH_P1_TAB3,MATH TIPS & UNDO,BÍ QUYẾT TÍNH & UNDO
-STR_GI_SUMPATH_P1_TITLE,The Sum-Adding Puzzle,Bài Toán Cộng Tổng Điểm
-STR_GI_SUMPATH_P2_CTA,NEXT: TACTICS & UNDO (3/3) ›,TIẾP THEO: CHIẾN THUẬT & UNDO (3/3) ›
-STR_GI_SUMPATH_P2_LINK,Skip guide & start scoring now,Bỏ qua hướng dẫn & Vào cộng điểm ngay
-STR_GI_SUMPATH_P2_R1D,"With =, the total must match exactly. With < or >, the total just needs to land in the valid range.","Với dấu =, tổng phải khớp tuyệt đối. Với dấu < hoặc >, chỉ cần tổng nằm trong khoảng hợp lệ."
-STR_GI_SUMPATH_P2_R1T,"Watch The Operator (=, <, >):","Để Ý Ký Hiệu Toán Tử (=, <, >):"
-STR_GI_SUMPATH_P2_R2D,"You may cross an old cell to change direction, but it adds no extra points.","Bạn có thể vẽ đường giao cắt ô cũ để chuyển hướng, nhưng điểm ô đó sẽ không được cộng thêm."
-STR_GI_SUMPATH_P2_R2T,Each Cell Scores Only Once:,Mỗi Ô Chỉ Tính Điểm Một Lần:
-STR_GI_SUMPATH_P2_R3D,"Touching the F shaft is not enough — if the total fails the math, the level is not over!",Dù bạn chạm được hố thang F nhưng tổng điểm không thỏa mãn phép tính thì màn chơi chưa kết thúc!
-STR_GI_SUMPATH_P2_R3T,Wrong Total At The Exit = Failure:,Về Đích Sai Mục Tiêu = Thất Bại:
-STR_GI_SUMPATH_P2_SECTION,TARGET & CELL-SCORE RULES,QUY TẮC MỤC TIÊU & ĐIỂM Ô
-STR_GI_SUMPATH_P2_TAB1,SUMS & TARGETS,CỘNG TỔNG & MỤC TIÊU
-STR_GI_SUMPATH_P2_TAB2,OPERATORS & ONE-TIME CELLS,TOÁN TỬ & Ô 1 LẦN
-STR_GI_SUMPATH_P2_TAB3,MATH TIPS & UNDO,BÍ QUYẾT TÍNH & UNDO
-STR_GI_SUMPATH_P2_TITLE,Operators & One-Time Cells,Toán Tử & Ô Điểm 1 Lần
-STR_GI_SUMPATH_P3_CTA,UNDERSTOOD • START SCORING,ĐÃ HIỂU • BẮT ĐẦU CỘNG ĐIỂM
-STR_GI_SUMPATH_P3_LINK,Review from the start (Page 1),Xem lại từ đầu (Trang 1)
-STR_GI_SUMPATH_P3_R1D,Each level guarantees at least one perfect route that satisfies the target operator.,Mỗi màn đều đảm bảo có ít nhất một đường đi hoàn hảo thỏa mãn đúng toán tử mục tiêu.
-STR_GI_SUMPATH_P3_R1T,Every Board Has At Least 1 Correct Solution:,Bản Cờ Luôn Có Ít Nhất 1 Nghiệm Đúng:
-STR_GI_SUMPATH_P3_R2D,"If a big cell pushes the total past the target, just Undo back and the points come off.","Nếu lỡ bước vào ô số to khiến tổng vượt quá mục tiêu, chỉ cần Undo lùi lại để trừ điểm ra."
-STR_GI_SUMPATH_P3_R2T,Use Undo To Recover Overshoot:,Dùng Undo Để Thu Hồi Điểm Lố:
-STR_GI_SUMPATH_P3_R3D,No step limit — the quickest mental math and earliest finish earns the top rank!,Game không giới hạn số bước — người nhẩm tính nhanh và về đích sớm nhất sẽ đạt hạng cao!
-STR_GI_SUMPATH_P3_R3T,Race To Solve Fastest:,Đua Tốc Độ Phá Giải:
-STR_GI_SUMPATH_P3_SECTION,MATH SECRETS,BÍ QUYẾT TÍNH TOÁN
-STR_GI_SUMPATH_P3_TAB1,SUMS & TARGETS,CỘNG TỔNG & MỤC TIÊU
-STR_GI_SUMPATH_P3_TAB2,OPERATORS & ONE-TIME CELLS,TOÁN TỬ & Ô 1 LẦN
-STR_GI_SUMPATH_P3_TAB3,MATH TIPS & UNDO,BÍ QUYẾT TÍNH & UNDO
-STR_GI_SUMPATH_P3_TITLE,Tactics & Undo Fixes,Chiến Thuật & Undo Sửa Sai
 STR_GI_WALL_BUILDER_CHIP,WALL BUILDER • BUILD THE MAZE,WALL BUILDER • XÂY TƯỜNG
 STR_GI_WALL_BUILDER_P1_CTA,NEXT: SUBMIT & 3 TRIES (2/3) ›,TIẾP THEO: NÚT GỬI & 3 LƯỢT (2/3) ›
@@ -1225,11 +985,11 @@
 STR_TUT_BM_FAIL_01,Wall hit! Try to recall where the walls are.,Đâm tường! Nhớ lại xem tường nằm đâu.
 STR_TUT_BM_HUD,Walls hidden: {0},Tường ẩn: {0} vị trí
-STR_TUT_TOOL_01,The toolbar has 2 tools: UNDO and HINT — each can be used 3 times per level. Let's see how they work!,Thanh công cụ có 2 nút: QUAY LẠI và GỢI Ý — mỗi nút dùng được 3 lượt mỗi màn. Cùng xem cách dùng nhé!
-STR_TUT_TOOL_02,"Example: take a step, then press UNDO — the cursor moves back to the previous cell.",Ví dụ: đi 1 bước rồi nhấn QUAY LẠI — con trỏ tự lùi về ô cũ.
+STR_TUT_TOOL_01,The toolbar has 2 tools: TELEPORT and HINT — each can be used 3 times per level. Let's see how they work!,Thanh công cụ có 2 nút: DỊCH CHUYỂN và GỢI Ý — mỗi nút dùng được 3 lượt mỗi màn. Cùng xem cách dùng nhé!
+STR_TUT_TOOL_02,"Example: press TELEPORT — cells within 2 steps light up. Tap one to jump straight there, even through walls.",Ví dụ: nhấn DỊCH CHUYỂN — các ô trong tầm 2 ô sáng lên. Chạm 1 ô để nhảy thẳng tới đó, kể cả có tường chắn.
 STR_TUT_TOOL_03,Example: press HINT — the next cell lights up.,Ví dụ: nhấn GỢI Ý — ô nên đi tiếp sẽ sáng lên.
-STR_TUT_TOOL_04,"Now try it yourself — reach F, using UNDO and HINT when needed!","Giờ tự thử — đi tới F, dùng QUAY LẠI và GỢI Ý khi cần nhé!"
+STR_TUT_TOOL_04,"Now try it yourself — reach F, using TELEPORT and HINT when needed!",Giờ tự thử — đi tới F, dùng DỊCH CHUYỂN và GỢI Ý khi cần nhé!
 STR_TUT_TOOL_05,Great! You have mastered both tools.,Tuyệt! Bạn đã nắm được 2 công cụ rồi.
-STR_TUT_TOOL_FAIL_UNDO,No steps to undo yet!,Chưa có bước nào để quay lại!
-STR_TUT_TOOL_HUD,Undo: {0} · Hint: {1},Quay lại: {0} lượt · Gợi ý: {1} lượt
+STR_TUT_TOOL_FAIL_TELEPORT,No cell to teleport to!,Không có ô nào để dịch chuyển tới!
+STR_TUT_TOOL_HUD,Teleport: {0} · Hint: {1},Dịch chuyển: {0} lượt · Gợi ý: {1} lượt
 STR_TUT_CONGRATS_TITLE,CONGRATULATIONS!,CHÚC MỪNG!
 STR_TUT_CONGRATS_BODY,"You finished the first 3 lessons and 4 practice boards — now you are ready for the real journey!","Bạn đã hoàn thành 3 bài học đầu tiên và 4 bàn thử sức — sẵn sàng cho hành trình tiếp theo!"
@@ -1284,6 +1044,6 @@
 STR_ACH_SP_NO_HINT_5_TITLE,Self-Reliant,Tự Lực Cánh Sinh
 STR_ACH_SP_NO_HINT_5_DESC,Win 5 levels/floors without using hints,Thắng 5 màn/tầng mà KHÔNG dùng gợi ý
-STR_ACH_SP_NO_UNDO_10_TITLE,No Turning Back,Đi Không Quay Lại
-STR_ACH_SP_NO_UNDO_10_DESC,Win 10 levels/floors without undo,Thắng 10 màn/tầng mà KHÔNG dùng hoàn tác
+STR_ACH_SP_NO_TELEPORT_10_TITLE,No Shortcuts,Không Đi Tắt
+STR_ACH_SP_NO_TELEPORT_10_DESC,Win 10 levels/floors without teleport,Thắng 10 màn/tầng mà KHÔNG dùng dịch chuyển
 STR_ACH_SP_SECRET_DUNGEON_50_TITLE,Secret • Oath of the Dungeon,Thành Tựu Ẩn • Lời Thề Ngục Tối
 STR_ACH_SP_SECRET_DUNGEON_50_DESC,Clear 50 floors total in Dungeon Mode,Vượt qua tổng cộng 50 Tầng ở Dungeon Mode
@@ -1447,5 +1207,5 @@
 STR_CHALLENGE_SUB_BUDGET,STEPS,BƯỚC
 STR_CHALLENGE_SUB_STEP_TIMER,SEC,GIÂY
-STR_CHALLENGE_SUB_BAN_TOOL,HINT/UNDO = LOSE,GỢI Ý/HOÀN TÁC = THUA
+STR_CHALLENGE_SUB_BAN_TOOL,HINT/TELEPORT = LOSE,GỢI Ý/DỊCH CHUYỂN = THUA
 STR_CHALLENGE_SUB_BAN_OVERLAP,OVERLAP = LOSE,ĐI LẠI = THUA
 STR_CHALLENGE_SUB_WALK_NUMBER,BLANK = LOSE,Ô TRỐNG = THUA
@@ -1466,4 +1226,8 @@
 STR_CHALLENGE_HEAD_WALK_EMPTY,BLANK ONLY,CHỈ Ô TRỐNG
 STR_CHALLENGE_SUB_WALK_EMPTY,NUMBER = LOSE,Ô SỐ = THUA
+STR_CHALLENGE_NAME_FOG,FOG OF WAR,SƯƠNG MÙ
+STR_CHALLENGE_HEAD_FOG,FOG,SƯƠNG MÙ
+STR_CHALLENGE_SUB_FOG,EXPLORE,KHÁM PHÁ
+STR_KEY_PICKED,Key!,Chìa khoá!
 STR_CHALLENGE_FAIL_WALK_EMPTY,You stepped on a numbered cell!,Bạn đã bước vào ô có số!
 STR_DAILY_GAME_TITLE,GAME {0} · {1},TRÒ CHƠI {0} · {1}
@@ -1489,5 +1253,5 @@
 STR_PROFILE_STAT_WALL_DRAW,WALL DRAW,VẼ TƯỜNG
 STR_PROFILE_STAT_REVERT_USED,REVERT USED,GỠ TƯỜNG
-STR_PROFILE_STAT_UNDO_USED,UNDO USED,LƯỢT HOÀN TÁC
+STR_PROFILE_STAT_TELEPORT_USED,TELEPORTS USED,LƯỢT DỊCH CHUYỂN
 STR_PROFILE_STAT_SKIP_USED,SKIP USED,LƯỢT BỎ QUA
 STR_PROFILE_TIME_SEC,{0}s,{0}s
@@ -1664,5 +1428,5 @@
 STR_DAILY_MILESTONE_NEED,"{0}★ TO GO","Cần thêm {0}★"
 STR_DAILY_TOOL_HINT,"Hint ×{0}","Gợi ý ×{0}"
-STR_DAILY_TOOL_UNDO,"Undo ×{0}","Hoàn tác ×{0}"
+STR_DAILY_TOOL_TELEPORT,"Teleport ×{0}","Dịch chuyển ×{0}"
 STR_DAILY_TOOL_SKIP,"Skip ×{0}","Bỏ qua ×{0}"
 STR_DAILY_CARD_PLAY,"PLAY","CHƠI"
```

### `scenes/layout/landscape/tutorial_list.tscn`
```diff
--- a/scenes/layout/landscape/tutorial_list.tscn
+++ b/scenes/layout/landscape/tutorial_list.tscn
@@ -169,5 +169,5 @@
 corner_radius_bottom_left = 8
 
-[node name="Landscape" node_paths=PackedStringArray("btn_back", "lbl_title", "mode_list", "btn_first_time", "btn_move", "btn_checking_wall", "btn_minesweeper", "btn_one_stroke", "btn_sum_path", "btn_wall_builder", "btn_countdown_cost", "btn_fading_ink", "btn_fog_of_war", "btn_blind_memory", "btn_use_tool", "header_anchor") instance=ExtResource("1_dymst")]
+[node name="Landscape" node_paths=PackedStringArray("btn_back", "lbl_title", "mode_list", "btn_first_time", "btn_move", "btn_checking_wall", "btn_wall_builder", "btn_blind_memory", "btn_use_tool", "header_anchor") instance=ExtResource("1_dymst")]
 script = ExtResource("2_layout")
 header_anchor = NodePath("Paper/Body/LeftCol/TopBarAnchor")
@@ -178,11 +178,5 @@
 btn_move = NodePath("Paper/Body/RightCol/ModeScroll/ModeList/BtnMove")
 btn_checking_wall = NodePath("Paper/Body/RightCol/ModeScroll/ModeList/BtnCheckingWall")
-btn_minesweeper = NodePath("Paper/Body/RightCol/ModeScroll/ModeList/BtnMinesweeper")
-btn_one_stroke = NodePath("Paper/Body/RightCol/ModeScroll/ModeList/BtnOneStroke")
-btn_sum_path = NodePath("Paper/Body/RightCol/ModeScroll/ModeList/BtnSumPath")
 btn_wall_builder = NodePath("Paper/Body/RightCol/ModeScroll/ModeList/BtnWallBuilder")
-btn_countdown_cost = NodePath("Paper/Body/RightCol/ModeScroll/ModeList/BtnCountdownCost")
-btn_fading_ink = NodePath("Paper/Body/RightCol/ModeScroll/ModeList/BtnFadingInk")
-btn_fog_of_war = NodePath("Paper/Body/RightCol/ModeScroll/ModeList/BtnFogOfWar")
 btn_blind_memory = NodePath("Paper/Body/RightCol/ModeScroll/ModeList/BtnBlindMemory")
 btn_use_tool = NodePath("Paper/Body/RightCol/ModeScroll/ModeList/BtnUseTool")
@@ -671,5 +665,5 @@
 stretch_mode = 0
 
-[node name="BtnMinesweeper" type="Button" parent="Paper/Body/RightCol/ModeScroll/ModeList" index="3"]
+[node name="BtnWallBuilder" type="Button" parent="Paper/Body/RightCol/ModeScroll/ModeList" index="3"]
 custom_minimum_size = Vector2(0, 72)
 layout_mode = 2
@@ -682,5 +676,5 @@
 theme_override_styles/focus = SubResource("sb_empty")
 
-[node name="Content" type="HBoxContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnMinesweeper"]
+[node name="Content" type="HBoxContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnWallBuilder"]
 layout_mode = 1
 anchors_preset = 15
@@ -697,5 +691,5 @@
 alignment = 1
 
-[node name="Node" type="PanelContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnMinesweeper/Content" index="0"]
+[node name="Node" type="PanelContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnWallBuilder/Content" index="0"]
 custom_minimum_size = Vector2(44, 44)
 layout_mode = 2
@@ -704,5 +698,5 @@
 theme_override_styles/panel = SubResource("sb_node3")
 
-[node name="Num" type="Label" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnMinesweeper/Content/Node"]
+[node name="Num" type="Label" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnWallBuilder/Content/Node"]
 layout_mode = 2
 theme_override_colors/font_color = Color(1, 1, 1, 1)
@@ -712,5 +706,5 @@
 vertical_alignment = 1
 
-[node name="IconBadge" type="PanelContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnMinesweeper/Content" index="1"]
+[node name="IconBadge" type="PanelContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnWallBuilder/Content" index="1"]
 custom_minimum_size = Vector2(44, 44)
 layout_mode = 2
@@ -719,5 +713,5 @@
 theme_override_styles/panel = SubResource("sb_icon")
 
-[node name="Icon" type="TextureRect" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnMinesweeper/Content/IconBadge" index="0"]
+[node name="Icon" type="TextureRect" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnWallBuilder/Content/IconBadge" index="0"]
 custom_minimum_size = Vector2(28, 28)
 layout_mode = 2
@@ -725,9 +719,9 @@
 size_flags_vertical = 4
 mouse_filter = 2
-texture = ExtResource("13_ic_bomb")
-expand_mode = 1
-stretch_mode = 5
-
-[node name="Texts" type="VBoxContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnMinesweeper/Content" index="2"]
+texture = ExtResource("16_ic_castle")
+expand_mode = 1
+stretch_mode = 5
+
+[node name="Texts" type="VBoxContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnWallBuilder/Content" index="2"]
 layout_mode = 2
 size_flags_horizontal = 3
@@ -736,21 +730,21 @@
 theme_override_constants/separation = 2
 
-[node name="Title" type="Label" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnMinesweeper/Content/Texts" index="0"]
+[node name="Title" type="Label" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnWallBuilder/Content/Texts" index="0"]
 layout_mode = 2
 theme_override_colors/font_color = Color(0.1686, 0.2392, 0.3137, 1)
 theme_override_font_sizes/font_size = 15
-text = "Né mìn theo số"
+text = "Tự xây dựng tường"
 vertical_alignment = 1
 text_overrun_behavior = 3
 
-[node name="Desc" type="Label" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnMinesweeper/Content/Texts" index="1"]
+[node name="Desc" type="Label" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnWallBuilder/Content/Texts" index="1"]
 layout_mode = 2
 theme_override_colors/font_color = Color(0.3569, 0.4314, 0.5098, 1)
 theme_override_font_sizes/font_size = 12
-text = "Dò tìm ô an toàn và tránh xa bẫy mìn"
+text = "Vẽ các đoạn tường ngăn theo chỉ số rồi Gửi bài"
 vertical_alignment = 1
 autowrap_mode = 3
 
-[node name="Chevron" type="TextureRect" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnMinesweeper/Content" index="3"]
+[node name="Chevron" type="TextureRect" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnWallBuilder/Content" index="3"]
 self_modulate = Color(0.1843, 0.4667, 0.6471, 1)
 custom_minimum_size = Vector2(10, 14)
@@ -762,5 +756,5 @@
 stretch_mode = 5
 
-[node name="Link" type="TextureRect" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnMinesweeper" index="1"]
+[node name="Link" type="TextureRect" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnWallBuilder" index="1"]
 layout_mode = 1
 anchors_preset = -1
@@ -776,5 +770,5 @@
 stretch_mode = 0
 
-[node name="BtnOneStroke" type="Button" parent="Paper/Body/RightCol/ModeScroll/ModeList" index="4"]
+[node name="BtnBlindMemory" type="Button" parent="Paper/Body/RightCol/ModeScroll/ModeList" index="4"]
 custom_minimum_size = Vector2(0, 72)
 layout_mode = 2
@@ -787,5 +781,5 @@
 theme_override_styles/focus = SubResource("sb_empty")
 
-[node name="Content" type="HBoxContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnOneStroke"]
+[node name="Content" type="HBoxContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnBlindMemory"]
 layout_mode = 1
 anchors_preset = 15
@@ -802,12 +796,12 @@
 alignment = 1
 
-[node name="Node" type="PanelContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnOneStroke/Content" index="0"]
-custom_minimum_size = Vector2(44, 44)
-layout_mode = 2
-size_flags_vertical = 4
-mouse_filter = 2
-theme_override_styles/panel = SubResource("sb_node0")
-
-[node name="Num" type="Label" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnOneStroke/Content/Node"]
+[node name="Node" type="PanelContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnBlindMemory/Content" index="0"]
+custom_minimum_size = Vector2(44, 44)
+layout_mode = 2
+size_flags_vertical = 4
+mouse_filter = 2
+theme_override_styles/panel = SubResource("sb_node2")
+
+[node name="Num" type="Label" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnBlindMemory/Content/Node"]
 layout_mode = 2
 theme_override_colors/font_color = Color(1, 1, 1, 1)
@@ -817,5 +811,5 @@
 vertical_alignment = 1
 
-[node name="IconBadge" type="PanelContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnOneStroke/Content" index="1"]
+[node name="IconBadge" type="PanelContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnBlindMemory/Content" index="1"]
 custom_minimum_size = Vector2(44, 44)
 layout_mode = 2
@@ -824,5 +818,5 @@
 theme_override_styles/panel = SubResource("sb_icon")
 
-[node name="Icon" type="TextureRect" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnOneStroke/Content/IconBadge" index="0"]
+[node name="Icon" type="TextureRect" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnBlindMemory/Content/IconBadge" index="0"]
 custom_minimum_size = Vector2(28, 28)
 layout_mode = 2
@@ -830,9 +824,9 @@
 size_flags_vertical = 4
 mouse_filter = 2
-texture = ExtResource("14_ic_pencil")
-expand_mode = 1
-stretch_mode = 5
-
-[node name="Texts" type="VBoxContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnOneStroke/Content" index="2"]
+texture = ExtResource("20_ic_target")
+expand_mode = 1
+stretch_mode = 5
+
+[node name="Texts" type="VBoxContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnBlindMemory/Content" index="2"]
 layout_mode = 2
 size_flags_horizontal = 3
@@ -841,21 +835,21 @@
 theme_override_constants/separation = 2
 
-[node name="Title" type="Label" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnOneStroke/Content/Texts" index="0"]
+[node name="Title" type="Label" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnBlindMemory/Content/Texts" index="0"]
 layout_mode = 2
 theme_override_colors/font_color = Color(0.1686, 0.2392, 0.3137, 1)
 theme_override_font_sizes/font_size = 15
-text = "Vẽ đường một nét"
+text = "Ghi nhớ đường mù"
 vertical_alignment = 1
 text_overrun_behavior = 3
 
-[node name="Desc" type="Label" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnOneStroke/Content/Texts" index="1"]
+[node name="Desc" type="Label" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnBlindMemory/Content/Texts" index="1"]
 layout_mode = 2
 theme_override_colors/font_color = Color(0.3569, 0.4314, 0.5098, 1)
 theme_override_font_sizes/font_size = 12
-text = "Đi qua toàn bộ mọi ô trong bàn đúng 1 lần"
+text = "Nhìn bản đồ vài giây rồi tự vẽ trong bóng tối"
 vertical_alignment = 1
 autowrap_mode = 3
 
-[node name="Chevron" type="TextureRect" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnOneStroke/Content" index="3"]
+[node name="Chevron" type="TextureRect" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnBlindMemory/Content" index="3"]
 self_modulate = Color(0.1843, 0.4667, 0.6471, 1)
 custom_minimum_size = Vector2(10, 14)
@@ -867,5 +861,5 @@
 stretch_mode = 5
 
-[node name="Link" type="TextureRect" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnOneStroke" index="1"]
+[node name="Link" type="TextureRect" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnBlindMemory" index="1"]
 layout_mode = 1
 anchors_preset = -1
@@ -881,5 +875,5 @@
 stretch_mode = 0
 
-[node name="BtnSumPath" type="Button" parent="Paper/Body/RightCol/ModeScroll/ModeList" index="5"]
+[node name="BtnUseTool" type="Button" parent="Paper/Body/RightCol/ModeScroll/ModeList" index="5"]
 custom_minimum_size = Vector2(0, 72)
 layout_mode = 2
@@ -892,5 +886,5 @@
 theme_override_styles/focus = SubResource("sb_empty")
 
-[node name="Content" type="HBoxContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnSumPath"]
+[node name="Content" type="HBoxContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnUseTool"]
 layout_mode = 1
 anchors_preset = 15
@@ -907,646 +901,16 @@
 alignment = 1
 
-[node name="Node" type="PanelContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnSumPath/Content" index="0"]
-custom_minimum_size = Vector2(44, 44)
-layout_mode = 2
-size_flags_vertical = 4
-mouse_filter = 2
-theme_override_styles/panel = SubResource("sb_node1")
-
-[node name="Num" type="Label" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnSumPath/Content/Node"]
+[node name="Node" type="PanelContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnUseTool/Content" index="0"]
+custom_minimum_size = Vector2(44, 44)
+layout_mode = 2
+size_flags_vertical = 4
+mouse_filter = 2
+theme_override_styles/panel = SubResource("sb_node3")
+
+[node name="Num" type="Label" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnUseTool/Content/Node"]
 layout_mode = 2
 theme_override_colors/font_color = Color(1, 1, 1, 1)
 theme_override_font_sizes/font_size = 17
 text = "6"
-horizontal_alignment = 1
-vertical_alignment = 1
-
-[node name="IconBadge" type="PanelContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnSumPath/Content" index="1"]
-custom_minimum_size = Vector2(44, 44)
-layout_mode = 2
-size_flags_vertical = 4
-mouse_filter = 2
-theme_override_styles/panel = SubResource("sb_icon")
-
-[node name="Icon" type="TextureRect" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnSumPath/Content/IconBadge" index="0"]
-custom_minimum_size = Vector2(28, 28)
-layout_mode = 2
-size_flags_horizontal = 4
-size_flags_vertical = 4
-mouse_filter = 2
-texture = ExtResource("15_ic_circle")
-expand_mode = 1
-stretch_mode = 5
-
-[node name="Texts" type="VBoxContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnSumPath/Content" index="2"]
-layout_mode = 2
-size_flags_horizontal = 3
-size_flags_vertical = 4
-mouse_filter = 2
-theme_override_constants/separation = 2
-
-[node name="Title" type="Label" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnSumPath/Content/Texts" index="0"]
-layout_mode = 2
-theme_override_colors/font_color = Color(0.1686, 0.2392, 0.3137, 1)
-theme_override_font_sizes/font_size = 15
-text = "Khớp tổng điểm"
-vertical_alignment = 1
-text_overrun_behavior = 3
-
-[node name="Desc" type="Label" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnSumPath/Content/Texts" index="1"]
-layout_mode = 2
-theme_override_colors/font_color = Color(0.3569, 0.4314, 0.5098, 1)
-theme_override_font_sizes/font_size = 12
-text = "Đi qua các ô sao cho tổng khớp mục tiêu"
-vertical_alignment = 1
-autowrap_mode = 3
-
-[node name="Chevron" type="TextureRect" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnSumPath/Content" index="3"]
-self_modulate = Color(0.1843, 0.4667, 0.6471, 1)
-custom_minimum_size = Vector2(10, 14)
-layout_mode = 2
-size_flags_vertical = 4
-mouse_filter = 2
-texture = ExtResource("chev")
-expand_mode = 1
-stretch_mode = 5
-
-[node name="Link" type="TextureRect" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnSumPath" index="1"]
-layout_mode = 1
-anchors_preset = -1
-anchor_top = 1.0
-anchor_bottom = 1.0
-offset_left = 31.0
-offset_top = -6.0
-offset_right = 37.0
-offset_bottom = 36.0
-mouse_filter = 2
-texture = ExtResource("tut_link_v")
-expand_mode = 1
-stretch_mode = 0
-
-[node name="BtnWallBuilder" type="Button" parent="Paper/Body/RightCol/ModeScroll/ModeList" index="6"]
-custom_minimum_size = Vector2(0, 72)
-layout_mode = 2
-focus_mode = 0
-mouse_default_cursor_shape = 2
-theme_override_styles/normal = SubResource("sb_n")
-theme_override_styles/pressed = SubResource("sb_p")
-theme_override_styles/hover = SubResource("sb_n")
-theme_override_styles/disabled = SubResource("sb_d")
-theme_override_styles/focus = SubResource("sb_empty")
-
-[node name="Content" type="HBoxContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnWallBuilder"]
-layout_mode = 1
-anchors_preset = 15
-anchor_right = 1.0
-anchor_bottom = 1.0
-offset_left = 12.0
-offset_top = 6.0
-offset_right = -12.0
-offset_bottom = -11.0
-grow_horizontal = 2
-grow_vertical = 2
-mouse_filter = 2
-theme_override_constants/separation = 10
-alignment = 1
-
-[node name="Node" type="PanelContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnWallBuilder/Content" index="0"]
-custom_minimum_size = Vector2(44, 44)
-layout_mode = 2
-size_flags_vertical = 4
-mouse_filter = 2
-theme_override_styles/panel = SubResource("sb_node2")
-
-[node name="Num" type="Label" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnWallBuilder/Content/Node"]
-layout_mode = 2
-theme_override_colors/font_color = Color(1, 1, 1, 1)
-theme_override_font_sizes/font_size = 17
-text = "7"
-horizontal_alignment = 1
-vertical_alignment = 1
-
-[node name="IconBadge" type="PanelContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnWallBuilder/Content" index="1"]
-custom_minimum_size = Vector2(44, 44)
-layout_mode = 2
-size_flags_vertical = 4
-mouse_filter = 2
-theme_override_styles/panel = SubResource("sb_icon")
-
-[node name="Icon" type="TextureRect" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnWallBuilder/Content/IconBadge" index="0"]
-custom_minimum_size = Vector2(28, 28)
-layout_mode = 2
-size_flags_horizontal = 4
-size_flags_vertical = 4
-mouse_filter = 2
-texture = ExtResource("16_ic_castle")
-expand_mode = 1
-stretch_mode = 5
-
-[node name="Texts" type="VBoxContainer" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnWallBuilder/Content" index="2"]
-layout_mode = 2
-size_flags_horizontal = 3
-size_flags_vertical = 4
-mouse_filter = 2
-theme_override_constants/separation = 2
-
-[node name="Title" type="Label" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnWallBuilder/Content/Texts" index="0"]
-layout_mode = 2
-theme_override_colors/font_color = Color(0.1686, 0.2392, 0.3137, 1)
-theme_override_font_sizes/font_size = 15
-text = "Tự xây dựng tường"
-vertical_alignment = 1
-text_overrun_behavior = 3
-
-[node name="Desc" type="Label" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnWallBuilder/Content/Texts" index="1"]
-layout_mode = 2
-theme_override_colors/font_color = Color(0.3569, 0.4314, 0.5098, 1)
-theme_override_font_sizes/font_size = 12
-text = "Vẽ các đoạn tường ngăn theo chỉ số rồi Gửi bài"
-vertical_alignment = 1
-autowrap_mode = 3
-
-[node name="Chevron" type="TextureRect" parent="Paper/Body/RightCol/ModeScroll/ModeList/BtnWallBuilder/Content" index="3"]
-self_modulate = Color(0.1843, 0.4667, 0.6471, 1)
-custom_minimum_size = Vector2(10, 14)
-layout_mode = 2
-size_flags_vertical = 4
... (cắt bớt — xem file đầy đủ trong package)
```

### `scenes/layout/portrait/tutorial_list.tscn`
```diff
--- a/scenes/layout/portrait/tutorial_list.tscn
+++ b/scenes/layout/portrait/tutorial_list.tscn
@@ -158,5 +158,5 @@
 fill_to = Vector2(0, 1)
 
-[node name="Portrait" node_paths=PackedStringArray("btn_back", "lbl_title", "mode_list", "btn_first_time", "btn_move", "btn_checking_wall", "btn_minesweeper", "btn_one_stroke", "btn_sum_path", "btn_wall_builder", "btn_countdown_cost", "btn_fading_ink", "btn_fog_of_war", "btn_blind_memory", "btn_use_tool", "header_anchor") instance=ExtResource("1_parent")]
+[node name="Portrait" node_paths=PackedStringArray("btn_back", "lbl_title", "mode_list", "btn_first_time", "btn_move", "btn_checking_wall", "btn_wall_builder", "btn_blind_memory", "btn_use_tool", "header_anchor") instance=ExtResource("1_parent")]
 script = ExtResource("2_layout")
 header_anchor = NodePath("Paper/TopBarAnchor")
@@ -167,11 +167,5 @@
 btn_move = NodePath("Paper/ModeScroll/ModeList/BtnMove")
 btn_checking_wall = NodePath("Paper/ModeScroll/ModeList/BtnCheckingWall")
-btn_minesweeper = NodePath("Paper/ModeScroll/ModeList/BtnMinesweeper")
-btn_one_stroke = NodePath("Paper/ModeScroll/ModeList/BtnOneStroke")
-btn_sum_path = NodePath("Paper/ModeScroll/ModeList/BtnSumPath")
 btn_wall_builder = NodePath("Paper/ModeScroll/ModeList/BtnWallBuilder")
-btn_countdown_cost = NodePath("Paper/ModeScroll/ModeList/BtnCountdownCost")
-btn_fading_ink = NodePath("Paper/ModeScroll/ModeList/BtnFadingInk")
-btn_fog_of_war = NodePath("Paper/ModeScroll/ModeList/BtnFogOfWar")
 btn_blind_memory = NodePath("Paper/ModeScroll/ModeList/BtnBlindMemory")
 btn_use_tool = NodePath("Paper/ModeScroll/ModeList/BtnUseTool")
@@ -609,5 +603,5 @@
 stretch_mode = 0
 
-[node name="BtnMinesweeper" type="Button" parent="Paper/ModeScroll/ModeList" index="3"]
+[node name="BtnWallBuilder" type="Button" parent="Paper/ModeScroll/ModeList" index="3"]
 custom_minimum_size = Vector2(320, 72)
 layout_mode = 2
@@ -621,5 +615,5 @@
 size_flags_horizontal = 0
 
-[node name="Content" type="HBoxContainer" parent="Paper/ModeScroll/ModeList/BtnMinesweeper"]
+[node name="Content" type="HBoxContainer" parent="Paper/ModeScroll/ModeList/BtnWallBuilder"]
 layout_mode = 1
 anchors_preset = 15
@@ -636,5 +630,5 @@
 alignment = 1
 
-[node name="IconBadge" type="PanelContainer" parent="Paper/ModeScroll/ModeList/BtnMinesweeper/Content" index="0"]
+[node name="IconBadge" type="PanelContainer" parent="Paper/ModeScroll/ModeList/BtnWallBuilder/Content" index="0"]
 custom_minimum_size = Vector2(44, 44)
 layout_mode = 2
@@ -643,5 +637,5 @@
 theme_override_styles/panel = SubResource("sb_icon")
 
-[node name="Icon" type="TextureRect" parent="Paper/ModeScroll/ModeList/BtnMinesweeper/Content/IconBadge" index="0"]
+[node name="Icon" type="TextureRect" parent="Paper/ModeScroll/ModeList/BtnWallBuilder/Content/IconBadge" index="0"]
 custom_minimum_size = Vector2(28, 28)
 layout_mode = 2
@@ -649,9 +643,9 @@
 size_flags_vertical = 4
 mouse_filter = 2
-texture = ExtResource("12_ic_bomb")
-expand_mode = 1
-stretch_mode = 5
-
-[node name="Texts" type="VBoxContainer" parent="Paper/ModeScroll/ModeList/BtnMinesweeper/Content" index="1"]
+texture = ExtResource("15_ic_castle")
+expand_mode = 1
+stretch_mode = 5
+
+[node name="Texts" type="VBoxContainer" parent="Paper/ModeScroll/ModeList/BtnWallBuilder/Content" index="1"]
 layout_mode = 2
 size_flags_horizontal = 3
@@ -660,21 +654,21 @@
 theme_override_constants/separation = 2
 
-[node name="Title" type="Label" parent="Paper/ModeScroll/ModeList/BtnMinesweeper/Content/Texts" index="0"]
+[node name="Title" type="Label" parent="Paper/ModeScroll/ModeList/BtnWallBuilder/Content/Texts" index="0"]
 layout_mode = 2
 theme_override_colors/font_color = Color(0.1686, 0.2392, 0.3137, 1)
 theme_override_font_sizes/font_size = 15
-text = "Né mìn theo số"
+text = "Tự xây dựng tường"
 vertical_alignment = 1
 text_overrun_behavior = 3
 
-[node name="Desc" type="Label" parent="Paper/ModeScroll/ModeList/BtnMinesweeper/Content/Texts" index="1"]
+[node name="Desc" type="Label" parent="Paper/ModeScroll/ModeList/BtnWallBuilder/Content/Texts" index="1"]
 layout_mode = 2
 theme_override_colors/font_color = Color(0.3569, 0.4314, 0.5098, 1)
 theme_override_font_sizes/font_size = 12
-text = "Dò tìm ô an toàn và tránh xa bẫy mìn"
+text = "Vẽ các đoạn tường ngăn theo chỉ số rồi Gửi bài"
 vertical_alignment = 1
 autowrap_mode = 3
 
-[node name="Chevron" type="TextureRect" parent="Paper/ModeScroll/ModeList/BtnMinesweeper/Content" index="2"]
+[node name="Chevron" type="TextureRect" parent="Paper/ModeScroll/ModeList/BtnWallBuilder/Content" index="2"]
 self_modulate = Color(0.1843, 0.4667, 0.6471, 1)
 custom_minimum_size = Vector2(10, 14)
@@ -686,5 +680,5 @@
 stretch_mode = 5
 
-[node name="Node" type="PanelContainer" parent="Paper/ModeScroll/ModeList/BtnMinesweeper" index="1"]
+[node name="Node" type="PanelContainer" parent="Paper/ModeScroll/ModeList/BtnWallBuilder" index="1"]
 layout_mode = 1
 anchors_preset = -1
@@ -700,5 +694,5 @@
 theme_override_styles/panel = SubResource("sb_node3")
 
-[node name="Num" type="Label" parent="Paper/ModeScroll/ModeList/BtnMinesweeper/Node"]
+[node name="Num" type="Label" parent="Paper/ModeScroll/ModeList/BtnWallBuilder/Node"]
 layout_mode = 2
 theme_override_colors/font_color = Color(1, 1, 1, 1)
@@ -708,5 +702,5 @@
 vertical_alignment = 1
 
-[node name="Link" type="TextureRect" parent="Paper/ModeScroll/ModeList/BtnMinesweeper" index="2"]
+[node name="Link" type="TextureRect" parent="Paper/ModeScroll/ModeList/BtnWallBuilder" index="2"]
 layout_mode = 1
 anchors_preset = -1
@@ -720,5 +714,5 @@
 stretch_mode = 0
 
-[node name="BtnOneStroke" type="Button" parent="Paper/ModeScroll/ModeList" index="4"]
+[node name="BtnBlindMemory" type="Button" parent="Paper/ModeScroll/ModeList" index="4"]
 custom_minimum_size = Vector2(320, 72)
 layout_mode = 2
@@ -732,5 +726,5 @@
 size_flags_horizontal = 8
 
-[node name="Content" type="HBoxContainer" parent="Paper/ModeScroll/ModeList/BtnOneStroke"]
+[node name="Content" type="HBoxContainer" parent="Paper/ModeScroll/ModeList/BtnBlindMemory"]
 layout_mode = 1
 anchors_preset = 15
@@ -747,5 +741,5 @@
 alignment = 1
 
-[node name="IconBadge" type="PanelContainer" parent="Paper/ModeScroll/ModeList/BtnOneStroke/Content" index="0"]
+[node name="IconBadge" type="PanelContainer" parent="Paper/ModeScroll/ModeList/BtnBlindMemory/Content" index="0"]
 custom_minimum_size = Vector2(44, 44)
 layout_mode = 2
@@ -754,5 +748,5 @@
 theme_override_styles/panel = SubResource("sb_icon")
 
-[node name="Icon" type="TextureRect" parent="Paper/ModeScroll/ModeList/BtnOneStroke/Content/IconBadge" index="0"]
+[node name="Icon" type="TextureRect" parent="Paper/ModeScroll/ModeList/BtnBlindMemory/Content/IconBadge" index="0"]
 custom_minimum_size = Vector2(28, 28)
 layout_mode = 2
@@ -760,9 +754,9 @@
 size_flags_vertical = 4
 mouse_filter = 2
-texture = ExtResource("13_ic_pencil")
-expand_mode = 1
-stretch_mode = 5
-
-[node name="Texts" type="VBoxContainer" parent="Paper/ModeScroll/ModeList/BtnOneStroke/Content" index="1"]
+texture = ExtResource("19_ic_target")
+expand_mode = 1
+stretch_mode = 5
+
+[node name="Texts" type="VBoxContainer" parent="Paper/ModeScroll/ModeList/BtnBlindMemory/Content" index="1"]
 layout_mode = 2
 size_flags_horizontal = 3
@@ -771,21 +765,21 @@
 theme_override_constants/separation = 2
 
-[node name="Title" type="Label" parent="Paper/ModeScroll/ModeList/BtnOneStroke/Content/Texts" index="0"]
+[node name="Title" type="Label" parent="Paper/ModeScroll/ModeList/BtnBlindMemory/Content/Texts" index="0"]
 layout_mode = 2
 theme_override_colors/font_color = Color(0.1686, 0.2392, 0.3137, 1)
 theme_override_font_sizes/font_size = 15
-text = "Vẽ đường một nét"
+text = "Ghi nhớ đường mù"
 vertical_alignment = 1
 text_overrun_behavior = 3
 
-[node name="Desc" type="Label" parent="Paper/ModeScroll/ModeList/BtnOneStroke/Content/Texts" index="1"]
+[node name="Desc" type="Label" parent="Paper/ModeScroll/ModeList/BtnBlindMemory/Content/Texts" index="1"]
 layout_mode = 2
 theme_override_colors/font_color = Color(0.3569, 0.4314, 0.5098, 1)
 theme_override_font_sizes/font_size = 12
-text = "Đi qua toàn bộ mọi ô trong bàn đúng 1 lần"
+text = "Nhìn bản đồ vài giây rồi tự vẽ trong bóng tối"
 vertical_alignment = 1
 autowrap_mode = 3
 
-[node name="Chevron" type="TextureRect" parent="Paper/ModeScroll/ModeList/BtnOneStroke/Content" index="2"]
+[node name="Chevron" type="TextureRect" parent="Paper/ModeScroll/ModeList/BtnBlindMemory/Content" index="2"]
 self_modulate = Color(0.1843, 0.4667, 0.6471, 1)
 custom_minimum_size = Vector2(10, 14)
@@ -797,5 +791,5 @@
 stretch_mode = 5
 
-[node name="Node" type="PanelContainer" parent="Paper/ModeScroll/ModeList/BtnOneStroke" index="1"]
+[node name="Node" type="PanelContainer" parent="Paper/ModeScroll/ModeList/BtnBlindMemory" index="1"]
 layout_mode = 1
 anchors_preset = -1
@@ -809,7 +803,7 @@
 offset_bottom = 28
 mouse_filter = 2
-theme_override_styles/panel = SubResource("sb_node0")
-
-[node name="Num" type="Label" parent="Paper/ModeScroll/ModeList/BtnOneStroke/Node"]
+theme_override_styles/panel = SubResource("sb_node2")
+
+[node name="Num" type="Label" parent="Paper/ModeScroll/ModeList/BtnBlindMemory/Node"]
 layout_mode = 2
 theme_override_colors/font_color = Color(1, 1, 1, 1)
@@ -819,5 +813,5 @@
 vertical_alignment = 1
 
-[node name="Link" type="TextureRect" parent="Paper/ModeScroll/ModeList/BtnOneStroke" index="2"]
+[node name="Link" type="TextureRect" parent="Paper/ModeScroll/ModeList/BtnBlindMemory" index="2"]
 layout_mode = 1
 anchors_preset = -1
@@ -831,5 +825,5 @@
 stretch_mode = 0
 
-[node name="BtnSumPath" type="Button" parent="Paper/ModeScroll/ModeList" index="5"]
+[node name="BtnUseTool" type="Button" parent="Paper/ModeScroll/ModeList" index="5"]
 custom_minimum_size = Vector2(320, 72)
 layout_mode = 2
@@ -843,5 +837,5 @@
 size_flags_horizontal = 0
 
-[node name="Content" type="HBoxContainer" parent="Paper/ModeScroll/ModeList/BtnSumPath"]
+[node name="Content" type="HBoxContainer" parent="Paper/ModeScroll/ModeList/BtnUseTool"]
 layout_mode = 1
 anchors_preset = 15
@@ -858,5 +852,5 @@
 alignment = 1
 
-[node name="IconBadge" type="PanelContainer" parent="Paper/ModeScroll/ModeList/BtnSumPath/Content" index="0"]
+[node name="IconBadge" type="PanelContainer" parent="Paper/ModeScroll/ModeList/BtnUseTool/Content" index="0"]
 custom_minimum_size = Vector2(44, 44)
 layout_mode = 2
@@ -865,5 +859,5 @@
 theme_override_styles/panel = SubResource("sb_icon")
 
-[node name="Icon" type="TextureRect" parent="Paper/ModeScroll/ModeList/BtnSumPath/Content/IconBadge" index="0"]
+[node name="Icon" type="TextureRect" parent="Paper/ModeScroll/ModeList/BtnUseTool/Content/IconBadge" index="0"]
 custom_minimum_size = Vector2(28, 28)
 layout_mode = 2
@@ -871,9 +865,9 @@
 size_flags_vertical = 4
 mouse_filter = 2
-texture = ExtResource("14_ic_circle")
-expand_mode = 1
-stretch_mode = 5
-
-[node name="Texts" type="VBoxContainer" parent="Paper/ModeScroll/ModeList/BtnSumPath/Content" index="1"]
+texture = ExtResource("20_ic_bulb")
+expand_mode = 1
+stretch_mode = 5
+
+[node name="Texts" type="VBoxContainer" parent="Paper/ModeScroll/ModeList/BtnUseTool/Content" index="1"]
 layout_mode = 2
 size_flags_horizontal = 3
@@ -882,21 +876,21 @@
 theme_override_constants/separation = 2
 
-[node name="Title" type="Label" parent="Paper/ModeScroll/ModeList/BtnSumPath/Content/Texts" index="0"]
+[node name="Title" type="Label" parent="Paper/ModeScroll/ModeList/BtnUseTool/Content/Texts" index="0"]
 layout_mode = 2
 theme_override_colors/font_color = Color(0.1686, 0.2392, 0.3137, 1)
 theme_override_font_sizes/font_size = 15
-text = "Khớp tổng điểm"
+text = "Dùng công cụ"
 vertical_alignment = 1
 text_overrun_behavior = 3
 
-[node name="Desc" type="Label" parent="Paper/ModeScroll/ModeList/BtnSumPath/Content/Texts" index="1"]
+[node name="Desc" type="Label" parent="Paper/ModeScroll/ModeList/BtnUseTool/Content/Texts" index="1"]
 layout_mode = 2
 theme_override_colors/font_color = Color(0.3569, 0.4314, 0.5098, 1)
 theme_override_font_sizes/font_size = 12
-text = "Đi qua các ô sao cho tổng khớp mục tiêu"
+text = "Quay lại & Gợi ý — mỗi nút dùng 3 lượt mỗi màn"
 vertical_alignment = 1
 autowrap_mode = 3
 
-[node name="Chevron" type="TextureRect" parent="Paper/ModeScroll/ModeList/BtnSumPath/Content" index="2"]
+[node name="Chevron" type="TextureRect" parent="Paper/ModeScroll/ModeList/BtnUseTool/Content" index="2"]
 self_modulate = Color(0.1843, 0.4667, 0.6471, 1)
 custom_minimum_size = Vector2(10, 14)
@@ -908,5 +902,5 @@
 stretch_mode = 5
 
-[node name="Node" type="PanelContainer" parent="Paper/ModeScroll/ModeList/BtnSumPath" index="1"]
+[node name="Node" type="PanelContainer" parent="Paper/ModeScroll/ModeList/BtnUseTool" index="1"]
 layout_mode = 1
 anchors_preset = -1
@@ -920,677 +914,11 @@
 offset_bottom = 28
 mouse_filter = 2
-theme_override_styles/panel = SubResource("sb_node1")
-
-[node name="Num" type="Label" parent="Paper/ModeScroll/ModeList/BtnSumPath/Node"]
+theme_override_styles/panel = SubResource("sb_node3")
+
+[node name="Num" type="Label" parent="Paper/ModeScroll/ModeList/BtnUseTool/Node"]
 layout_mode = 2
 theme_override_colors/font_color = Color(1, 1, 1, 1)
 theme_override_font_sizes/font_size = 20
 text = "6"
-horizontal_alignment = 1
-vertical_alignment = 1
-
-[node name="Link" type="TextureRect" parent="Paper/ModeScroll/ModeList/BtnSumPath" index="2"]
-layout_mode = 1
-anchors_preset = -1
-offset_left = 28
-offset_top = 64.0
-offset_right = 360
-offset_bottom = 114.0
-mouse_filter = 2
-texture = ExtResource("tut_link_rl")
-expand_mode = 1
-stretch_mode = 0
-
-[node name="BtnWallBuilder" type="Button" parent="Paper/ModeScroll/ModeList" index="6"]
-custom_minimum_size = Vector2(320, 72)
-layout_mode = 2
-focus_mode = 0
-mouse_default_cursor_shape = 2
-theme_override_styles/normal = SubResource("sb_n")
-theme_override_styles/pressed = SubResource("sb_p")
-theme_override_styles/hover = SubResource("sb_n")
-theme_override_styles/disabled = SubResource("sb_d")
-theme_override_styles/focus = SubResource("sb_empty")
-size_flags_horizontal = 8
-
-[node name="Content" type="HBoxContainer" parent="Paper/ModeScroll/ModeList/BtnWallBuilder"]
-layout_mode = 1
-anchors_preset = 15
-anchor_right = 1.0
-anchor_bottom = 1.0
-offset_left = 12.0
-offset_top = 6.0
-offset_right = -12.0
-offset_bottom = -11.0
-grow_horizontal = 2
-grow_vertical = 2
-mouse_filter = 2
-theme_override_constants/separation = 10
-alignment = 1
-
-[node name="IconBadge" type="PanelContainer" parent="Paper/ModeScroll/ModeList/BtnWallBuilder/Content" index="0"]
-custom_minimum_size = Vector2(44, 44)
-layout_mode = 2
-size_flags_vertical = 4
-mouse_filter = 2
-theme_override_styles/panel = SubResource("sb_icon")
-
-[node name="Icon" type="TextureRect" parent="Paper/ModeScroll/ModeList/BtnWallBuilder/Content/IconBadge" index="0"]
-custom_minimum_size = Vector2(28, 28)
-layout_mode = 2
-size_flags_horizontal = 4
-size_flags_vertical = 4
-mouse_filter = 2
-texture = ExtResource("15_ic_castle")
-expand_mode = 1
-stretch_mode = 5
-
-[node name="Texts" type="VBoxContainer" parent="Paper/ModeScroll/ModeList/BtnWallBuilder/Content" index="1"]
-layout_mode = 2
-size_flags_horizontal = 3
-size_flags_vertical = 4
-mouse_filter = 2
-theme_override_constants/separation = 2
-
-[node name="Title" type="Label" parent="Paper/ModeScroll/ModeList/BtnWallBuilder/Content/Texts" index="0"]
-layout_mode = 2
-theme_override_colors/font_color = Color(0.1686, 0.2392, 0.3137, 1)
-theme_override_font_sizes/font_size = 15
-text = "Tự xây dựng tường"
-vertical_alignment = 1
-text_overrun_behavior = 3
-
-[node name="Desc" type="Label" parent="Paper/ModeScroll/ModeList/BtnWallBuilder/Content/Texts" index="1"]
-layout_mode = 2
-theme_override_colors/font_color = Color(0.3569, 0.4314, 0.5098, 1)
-theme_override_font_sizes/font_size = 12
-text = "Vẽ các đoạn tường ngăn theo chỉ số rồi Gửi bài"
-vertical_alignment = 1
-autowrap_mode = 3
-
-[node name="Chevron" type="TextureRect" parent="Paper/ModeScroll/ModeList/BtnWallBuilder/Content" index="2"]
-self_modulate = Color(0.1843, 0.4667, 0.6471, 1)
-custom_minimum_size = Vector2(10, 14)
-layout_mode = 2
-size_flags_vertical = 4
-mouse_filter = 2
-texture = ExtResource("chev")
-expand_mode = 1
-stretch_mode = 5
-
-[node name="Node" type="PanelContainer" parent="Paper/ModeScroll/ModeList/BtnWallBuilder" index="1"]
-layout_mode = 1
-anchors_preset = -1
-anchor_left = 0
-anchor_top = 0.5
-anchor_right = 0
-anchor_bottom = 0.5
-offset_left = -68
-offset_top = -28
-offset_right = -12
-offset_bottom = 28
... (cắt bớt — xem file đầy đủ trong package)
```

### `scenes/tutorial_list.tscn`
```diff
--- a/scenes/tutorial_list.tscn
+++ b/scenes/tutorial_list.tscn
@@ -21,11 +21,5 @@
 [connection signal="pressed" from="Portrait/Paper/ModeScroll/ModeList/BtnMove" to="." method="_on_select_tutorial" binds= ["how_to_play_move"]]
 [connection signal="pressed" from="Portrait/Paper/ModeScroll/ModeList/BtnCheckingWall" to="." method="_on_select_tutorial" binds= ["how_to_play_checking_wall"]]
-[connection signal="pressed" from="Portrait/Paper/ModeScroll/ModeList/BtnMinesweeper" to="." method="_on_select_tutorial" binds= ["how_to_play_minesweeper"]]
-[connection signal="pressed" from="Portrait/Paper/ModeScroll/ModeList/BtnOneStroke" to="." method="_on_select_tutorial" binds= ["how_to_play_one_stroke"]]
-[connection signal="pressed" from="Portrait/Paper/ModeScroll/ModeList/BtnSumPath" to="." method="_on_select_tutorial" binds= ["how_to_play_sum_path"]]
 [connection signal="pressed" from="Portrait/Paper/ModeScroll/ModeList/BtnWallBuilder" to="." method="_on_select_tutorial" binds= ["how_to_play_wall_builder"]]
-[connection signal="pressed" from="Portrait/Paper/ModeScroll/ModeList/BtnCountdownCost" to="." method="_on_select_tutorial" binds= ["how_to_play_countdown_cost"]]
-[connection signal="pressed" from="Portrait/Paper/ModeScroll/ModeList/BtnFadingInk" to="." method="_on_select_tutorial" binds= ["how_to_play_fading_ink"]]
-[connection signal="pressed" from="Portrait/Paper/ModeScroll/ModeList/BtnFogOfWar" to="." method="_on_select_tutorial" binds= ["how_to_play_fog_of_war"]]
 [connection signal="pressed" from="Portrait/Paper/ModeScroll/ModeList/BtnBlindMemory" to="." method="_on_select_tutorial" binds= ["how_to_play_blind_memory"]]
 [connection signal="pressed" from="Portrait/Paper/ModeScroll/ModeList/BtnUseTool" to="." method="_on_select_tutorial" binds= ["how_to_use_tool"]]
@@ -34,11 +28,5 @@
 [connection signal="pressed" from="Landscape/Paper/Body/RightCol/ModeScroll/ModeList/BtnMove" to="." method="_on_select_tutorial" binds= ["how_to_play_move"]]
 [connection signal="pressed" from="Landscape/Paper/Body/RightCol/ModeScroll/ModeList/BtnCheckingWall" to="." method="_on_select_tutorial" binds= ["how_to_play_checking_wall"]]
-[connection signal="pressed" from="Landscape/Paper/Body/RightCol/ModeScroll/ModeList/BtnMinesweeper" to="." method="_on_select_tutorial" binds= ["how_to_play_minesweeper"]]
-[connection signal="pressed" from="Landscape/Paper/Body/RightCol/ModeScroll/ModeList/BtnOneStroke" to="." method="_on_select_tutorial" binds= ["how_to_play_one_stroke"]]
-[connection signal="pressed" from="Landscape/Paper/Body/RightCol/ModeScroll/ModeList/BtnSumPath" to="." method="_on_select_tutorial" binds= ["how_to_play_sum_path"]]
 [connection signal="pressed" from="Landscape/Paper/Body/RightCol/ModeScroll/ModeList/BtnWallBuilder" to="." method="_on_select_tutorial" binds= ["how_to_play_wall_builder"]]
-[connection signal="pressed" from="Landscape/Paper/Body/RightCol/ModeScroll/ModeList/BtnCountdownCost" to="." method="_on_select_tutorial" binds= ["how_to_play_countdown_cost"]]
-[connection signal="pressed" from="Landscape/Paper/Body/RightCol/ModeScroll/ModeList/BtnFadingInk" to="." method="_on_select_tutorial" binds= ["how_to_play_fading_ink"]]
-[connection signal="pressed" from="Landscape/Paper/Body/RightCol/ModeScroll/ModeList/BtnFogOfWar" to="." method="_on_select_tutorial" binds= ["how_to_play_fog_of_war"]]
 [connection signal="pressed" from="Landscape/Paper/Body/RightCol/ModeScroll/ModeList/BtnBlindMemory" to="." method="_on_select_tutorial" binds= ["how_to_play_blind_memory"]]
 [connection signal="pressed" from="Landscape/Paper/Body/RightCol/ModeScroll/ModeList/BtnUseTool" to="." method="_on_select_tutorial" binds= ["how_to_use_tool"]]
```

### `scripts/autoload/achievement_manager.gd`
```diff
--- a/scripts/autoload/achievement_manager.gd
+++ b/scripts/autoload/achievement_manager.gd
@@ -33,7 +33,7 @@
 	"wins_total": 0,
 	"wins_no_hint": 0,
-	"wins_no_undo": 0,
+	"wins_no_teleport": 0,
 	"hints_total": 0,
-	"undos_total": 0,
+	"teleports_total": 0,
 	"hardcore_wins": 0,
 	"play_seconds": 0,
@@ -250,5 +250,5 @@
 # Game báo kết quả 1 màn/tầng -> cập nhật số liệu tích luỹ
 # ---------------------------------------------------------------------------
-## `results` = { mode_id, won, endless, floor, score, elapsed, wall_hits, hints_used, undos_used, hardcore }
+## `results` = { mode_id, won, endless, floor, score, elapsed, wall_hits, hints_used, teleports_used, hardcore }
 func notify_run_result(results: Dictionary) -> void:
 	var won := bool(results.get("won", false))
@@ -256,8 +256,8 @@
 	var floor := maxi(int(results.get("floor", 1)), 1)
 	var hints := maxi(int(results.get("hints_used", 0)), 0)
-	var undos := maxi(int(results.get("undos_used", 0)), 0)
+	var teleports := maxi(int(results.get("teleports_used", 0)), 0)
 
 	_bump("hints_total", hints)
-	_bump("undos_total", undos)
+	_bump("teleports_total", teleports)
 	_bump("play_seconds", int(round(float(results.get("elapsed", 0.0)))))
 
@@ -275,6 +275,6 @@
 		if hints == 0:
 			_bump("wins_no_hint", 1)
-		if undos == 0:
-			_bump("wins_no_undo", 1)
+		if teleports == 0:
+			_bump("wins_no_teleport", 1)
 		if bool(results.get("hardcore", false)):
 			_bump("hardcore_wins", 1)
```

### `scripts/autoload/daily_manager.gd`
```diff
--- a/scripts/autoload/daily_manager.gd
+++ b/scripts/autoload/daily_manager.gd
@@ -37,10 +37,10 @@
 
 ## Mốc thưởng THÁNG — đúng như mockup `daily_challenge.svg` (15★ · 30★ · 45★ · 60★).
-## `coins`/`hint`/`undo`/`skip` = số lượng thưởng (0 = không thưởng loại đó).
+## `coins`/`hint`/`teleport`/`skip` = số lượng thưởng (0 = không thưởng loại đó).
 const MILESTONES: Array[Dictionary] = [
-	{"stars": 15, "coins": 100, "hint": 0, "undo": 0, "skip": 0},
-	{"stars": 30, "coins": 0, "hint": 2, "undo": 0, "skip": 0},
-	{"stars": 45, "coins": 250, "hint": 0, "undo": 2, "skip": 0},
-	{"stars": 60, "coins": 500, "hint": 3, "undo": 0, "skip": 0},
+	{"stars": 15, "coins": 100, "hint": 0, "teleport": 0, "skip": 0},
+	{"stars": 30, "coins": 0, "hint": 2, "teleport": 0, "skip": 0},
+	{"stars": 45, "coins": 250, "hint": 0, "teleport": 2, "skip": 0},
+	{"stars": 60, "coins": 500, "hint": 3, "teleport": 0, "skip": 0},
 ]
 
@@ -246,5 +246,5 @@
 	if coins > 0:
 		parts.append(tr("STR_DAILY_REWARD_COINS").format([coins]))
-	for tool_id in ["hint", "undo", "skip"]:
+	for tool_id in ["hint", "teleport", "skip"]:
 		var amount := int(def.get(tool_id, 0))
 		if amount > 0:
@@ -262,5 +262,5 @@
 	if gm == null or not gm.has_method("grant_tool_uses"):
 		return
-	for tool_id in ["hint", "undo", "skip"]:
+	for tool_id in ["hint", "teleport", "skip"]:
 		var amount := int(def.get(tool_id, 0))
 		if amount > 0:
```

### `scripts/autoload/game_manager.gd`
```diff
--- a/scripts/autoload/game_manager.gd
+++ b/scripts/autoload/game_manager.gd
@@ -18,7 +18,7 @@
 
 const TOOL_SKIP := "skip"
-const TOOL_UNDO := "undo"
+const TOOL_TELEPORT := "teleport"
 const TOOL_HINT := "hint"
-const TOOL_IDS: Array[String] = [TOOL_SKIP, TOOL_UNDO, TOOL_HINT]
+const TOOL_IDS: Array[String] = [TOOL_SKIP, TOOL_TELEPORT, TOOL_HINT]
 const INITIAL_TOOL_USES := 3
 ## Scene của ván chơi (mọi chế độ đều vào đây)
@@ -282,5 +282,5 @@
 
 ## Khởi động 1 MÀN trong màn Chọn màn.
-## Màn có thể ghi CHẾ ĐỘ riêng trong LevelData (`mode_id`) — vd màn 13 = "minesweeper" —
+## Màn có thể ghi CHẾ ĐỘ riêng trong LevelData (`mode_id`) — vd màn 13 = "wall_builder" —
 ## khi đó ván chơi chạy bằng chế độ Special TRÊN BÀN DO NHÀ THIẾT KẾ VẼ (xem BaseGameMode.designed_maze).
 ## Màn không khai gì (hoặc khai id lạ) = chế độ Play như trước.
@@ -546,5 +546,5 @@
 
 ## 3 định nghĩa rương của một chương có `stars_total` Sao tối đa.
-## Mỗi phần tử: `{ index, stars, coins, hint, undo, skip, life }` (`stars` = ngưỡng Sao cần).
+## Mỗi phần tử: `{ index, stars, coins, hint, teleport, skip, life }` (`stars` = ngưỡng Sao cần).
 func chapter_chest_defs(stars_total: int) -> Array[Dictionary]:
 	return _chests.defs(stars_total)
```

### `scripts/autoload/player_profile_manager.gd`
```diff
--- a/scripts/autoload/player_profile_manager.gd
+++ b/scripts/autoload/player_profile_manager.gd
@@ -78,5 +78,5 @@
 var time_total := 0.0           # tổng thời gian (giây, mọi ván)
 var level_time_total := 0.0     # tổng thời gian các ván MÀN (giây)
-var undos_total := 0            # tổng lượt Hoàn tác
+var teleports_total := 0       # tổng lượt Dịch chuyển
 var wall_draws_total := 0       # tổng lượt VẼ tường nghi ngờ
 var wall_erases_total := 0      # tổng lượt GỠ tường đã vẽ (Revert)
@@ -351,5 +351,5 @@
 		"wall_draws": wall_draws_total,
 		"wall_erases": wall_erases_total,
-		"undos_total": undos_total,
+		"teleports_total": teleports_total,
 		"skips_total": skips_total,
 	}
@@ -382,5 +382,5 @@
 	if bool(info.get("endless", false)):
 		dungeon_wall_hits += maxi(int(info.get("wall_hits", 0)), 0)
-	undos_total += maxi(int(info.get("undos", 0)), 0)
+	teleports_total += maxi(int(info.get("teleports", 0)), 0)
 	wall_draws_total += maxi(int(info.get("wall_draws", 0)), 0)
 	wall_erases_total += maxi(int(info.get("wall_erases", 0)), 0)
@@ -454,5 +454,5 @@
 		"time_total": time_total,
 		"level_time_total": level_time_total,
-		"undos_total": undos_total,
+		"teleports_total": teleports_total,
 		"wall_draws_total": wall_draws_total,
 		"wall_erases_total": wall_erases_total,
@@ -483,5 +483,5 @@
 	time_total = float(data.get("time_total", 0.0))
 	level_time_total = float(data.get("level_time_total", 0.0))
-	undos_total = int(data.get("undos_total", 0))
+	teleports_total = int(data.get("teleports_total", data.get("undos_total", 0)))
 	wall_draws_total = int(data.get("wall_draws_total", 0))
 	wall_erases_total = int(data.get("wall_erases_total", 0))
@@ -515,5 +515,5 @@
 	time_total = 0.0
 	level_time_total = 0.0
-	undos_total = 0
+	teleports_total = 0
 	wall_draws_total = 0
 	wall_erases_total = 0
```

### `scripts/autoload/shop_manager.gd`
```diff
--- a/scripts/autoload/shop_manager.gd
+++ b/scripts/autoload/shop_manager.gd
@@ -7,5 +7,5 @@
 ##   pen   · BÚT & MỰC  — skin ngòi bút (ĐỔI ĐƯỢC, xem ThemeManager.apply_pen)
 ##   theme · GIẤY VỞ    — chủ đề giấy/bàn cờ (ĐỔI ĐƯỢC, xem ThemeManager.apply_theme)
-##   tool  · DỤNG CỤ    — vật phẩm tiêu hao mua bằng Xu (undo · gợi ý · ...)
+##   tool  · DỤNG CỤ    — vật phẩm tiêu hao mua bằng Xu (dịch chuyển · gợi ý · ...)
 ##   coin  · NẠP XU     — gói nạp tiền thật (IAP) + gói xoá quảng cáo
 ##
@@ -97,6 +97,6 @@
 		"icon": "life", "life": true, "name_key": "STR_SHOP_LIFE_NAME",
 		"desc_key": "STR_SHOP_LIFE_DESC", "badge_key": "STR_SHOP_BADGE_PACK"},
-	{"id": "tool_undo_x10", "category": "tool", "price": 150, "amount": 10, "color": "#3D83AE",
-		"icon": "tool_undo", "name_key": "STR_SHOP_TOOL_UNDO_NAME", "desc_key": "STR_SHOP_TOOL_UNDO_DESC",
+	{"id": "tool_teleport_x10", "category": "tool", "price": 150, "amount": 10, "color": "#3D83AE",
+		"icon": "tool_teleport", "name_key": "STR_SHOP_TOOL_TELEPORT_NAME", "desc_key": "STR_SHOP_TOOL_TELEPORT_DESC",
 		"badge_key": "STR_SHOP_BADGE_PACK"},
 	{"id": "tool_hint_x5", "category": "tool", "price": 200, "amount": 5, "color": "#F59E0B",
```

### `scripts/autoload/tutorial_manager.gd`
```diff
--- a/scripts/autoload/tutorial_manager.gd
+++ b/scripts/autoload/tutorial_manager.gd
@@ -11,5 +11,5 @@
 ##   nên thoát giữa chừng vẫn chạy tiếp đúng chỗ ở lần mở sau.
 ##
-## TUTORIAL THEO CHẾ ĐỘ: chế độ Special (minesweeper · blind_memory · …) tự mở bài
+## TUTORIAL THEO CHẾ ĐỘ: chế độ Special (blind_memory · wall_builder) tự mở bài
 ## học của nó LẦN ĐẦU người chơi vào chế độ — dù vào từ Daily hay từ màn có `mode_id`
 ## (xem `GameManager.start_level` / `start_daily`).
@@ -39,11 +39,5 @@
 ## Chế độ Special → bài học mở LẦN ĐẦU khi người chơi vào chế độ đó
 const MODE_TUTORIALS: Dictionary = {
-	"minesweeper": "how_to_play_minesweeper",
-	"one_stroke": "how_to_play_one_stroke",
-	"sum_path": "how_to_play_sum_path",
-	"countdown_cost": "how_to_play_countdown_cost",
 	"blind_memory": "how_to_play_blind_memory",
-	"fog_of_war": "how_to_play_fog_of_war",
-	"fading_ink": "how_to_play_fading_ink",
 	"wall_builder": "how_to_play_wall_builder",
 }
```

### `scripts/core/challenge_rules.gd`
```diff
--- a/scripts/core/challenge_rules.gd
+++ b/scripts/core/challenge_rules.gd
@@ -4,5 +4,5 @@
 ## LUẬT CỦA CHẾ ĐỘ THỬ THÁCH (Challenge Mode) — tách khỏi `GameController`.
 ##
-## 8 luật nằm trong `ChallengeGameMode`; file này chỉ SOI vi phạm và trả về id luật
+## 9 luật nằm trong `ChallengeGameMode`; file này chỉ SOI vi phạm và trả về id luật
 ## (chuỗi rỗng = không vi phạm). `GameController` quyết định khi nào soi + mở popup thua.
 ##
@@ -44,8 +44,12 @@
 
 
-## Soi 3 luật theo NƯỚC ĐI (gọi ngay sau khi bước thành công — `path` đã có vị trí mới).
-func after_step(ch: ChallengeGameMode, path: Array[Vector2i], moves: int) -> String:
+## Soi các luật theo NƯỚC ĐI (gọi ngay sau khi bước thành công — `path` đã có vị trí mới).
+func after_step(ch: ChallengeGameMode, path: Array[Vector2i], moves: int, maze: MazeData = null) -> String:
 	if ch == null:
 		return ""
+	# Dịch chuyển tới ô SAI LOẠI (luật walk_*) cũng là vi phạm — bước thường đã bị chặn từ evaluate_move
+	if ch.is_walk_rule() and maze != null and not path.is_empty() \
+			and not ch.cell_allowed_by_rule(path[path.size() - 1], maze):
+		return ch.challenge_id
 	match ch.challenge_id:
 		ChallengeGameMode.MOVE_LIMIT:
```

### `scripts/core/chapter_chests_store.gd`
```diff
--- a/scripts/core/chapter_chests_store.gd
+++ b/scripts/core/chapter_chests_store.gd
@@ -16,5 +16,5 @@
 const REWARDS: Array[Dictionary] = [
 	{"coins": 50},
-	{"hint": 2, "undo": 1},
+	{"hint": 2, "teleport": 1},
 	{"coins": 150, "life": 1},
 ]
@@ -25,5 +25,5 @@
 
 ## 3 định nghĩa rương của một chương có `stars_total` Sao tối đa.
-## Mỗi phần tử: `{ index, stars, coins, hint, undo, skip, life }` (`stars` = ngưỡng Sao cần).
+## Mỗi phần tử: `{ index, stars, coins, hint, teleport, skip, life }` (`stars` = ngưỡng Sao cần).
 func defs(stars_total: int) -> Array[Dictionary]:
 	var out: Array[Dictionary] = []
```

### `scripts/core/controllers/game_controller.gd`
```diff
--- a/scripts/core/controllers/game_controller.gd
+++ b/scripts/core/controllers/game_controller.gd
@@ -27,10 +27,10 @@
 ## Số dư công cụ toàn tài khoản, chép sang HUD khi vẽ lại.
 var skip_left := 0
-var undo_left := 0
+var teleport_left := 0
 var hint_left := 0
-## Chi phí từng bước đã đi (Countdown Cost thu 1..4 bước mỗi ô) — Undo hoàn lại ĐÚNG chi phí
+## Chi phí từng bước đã đi — hồi sinh hoàn lại ĐÚNG chi phí bước vừa lùi
 var _move_costs: Array[int] = []
-## Đang khoá tương tác vì Countdown Cost hết ngân sách (chỉ mở lại khi VỪA lùi bước để có thêm bước)
-var _countdown_locked := false
+## Đang ở bước CHỌN Ô để dịch chuyển (đã bấm nút Teleport, các ô đang được tô sáng)
+var _teleport_selecting := false
 ## Trạng thái + luật của Challenge Mode (xem `scripts/core/challenge_rules.gd`)
 var _challenge_rules := ChallengeRules.new()
@@ -106,4 +106,5 @@
 	_floor_finished = false
 	_move_costs.clear()
+	_cancel_teleport()
 	# Challenge: cấp lại đồng hồ con "mỗi bước" + lượt quay đầu cho màn mới
 	_challenge_rules.reset()
@@ -126,5 +127,4 @@
 	if grid_view != null:
 		grid_view.set_interaction_enabled(true)
-	_countdown_locked = false
 	_overlay_showing = false
 	if grid_view != null:
@@ -201,5 +201,5 @@
 	var mode: BaseGameMode = game_mode_controller.game_mode if game_mode_controller != null else null
 	skip_left = _tool_uses_left(GameManagerClass.TOOL_SKIP)
-	undo_left = _tool_uses_left(GameManagerClass.TOOL_UNDO)
+	teleport_left = _tool_uses_left(GameManagerClass.TOOL_TELEPORT)
 	hint_left = _tool_uses_left(GameManagerClass.TOOL_HINT)
 	var extra_info := game_mode_controller.game_mode.get_hud_extra_info() if game_mode_controller.game_mode != null else ""
@@ -207,16 +207,5 @@
 	var subtitle := game_mode_controller.game_mode.get_hud_subtitle(game_state.floor_number) if game_mode_controller.game_mode != null else ""
 	var running := _run_active and not _floor_finished
-	# Countdown Cost: hết ngân sách -> KHOÁ di chuyển (người chơi phải lùi bước mới đi tiếp được).
-	# LƯU Ý: chỉ MỞ LẠI khi vừa hết khoá do ngân sách — KHÔNG bật tuỳ tiện, kẻo ghi đè khoá
-	# của hệ thống khác (VD pha GHI NHỚ của Blind Memory đang khoá tương tác).
-	var countdown_blocked := running and mode != null and mode.mode_id == "countdown_cost" \
-			and game_state.is_out_of_moves()
-	if grid_view != null:
-		if countdown_blocked:
-			grid_view.set_interaction_enabled(false)
-		elif running and _countdown_locked:
-			grid_view.set_interaction_enabled(true)
-	_countdown_locked = countdown_blocked
-	# Sum Path / Countdown Cost / Fading Ink: kiểm overlay "Hết nước đi" trên bàn
+	# Kiểm overlay "Hết nước đi" trên bàn (mode nào override `is_stuck` — hiện chưa chế độ nào dùng)
 	var was_overlay := _overlay_showing
 	var cur_pos := grid_controller.current_pos if grid_controller != null else Vector2i.ZERO
@@ -245,8 +234,8 @@
 			"steps_max": game_state.max_steps,
 			"mode_name": mode.mode_id if mode != null else "dungeon",
-			"undo_highlight": countdown_blocked,
+			"teleport_active": _teleport_selecting,
 			"replay_visible": replay_visible,
 			"skip_left": skip_left,
-			"undo_left": undo_left,
+			"teleport_left": teleport_left,
 			"hint_left": hint_left,
 			"guided": _guided_run(),
@@ -281,5 +270,5 @@
 		return
 	game_state.consume_step(cost)
-	# Nhớ chi phí bước ĐI ĐƯỢC để Undo hoàn lại đúng (Countdown Cost: mỗi ô 1..4 bước)
+	# Nhớ chi phí bước ĐI ĐƯỢC để hồi sinh hoàn lại đúng
 	if not hit_hazard:
 		_move_costs.append(cost)
@@ -298,6 +287,6 @@
 			return
 		game_state.record_wall_hit()
-		# Chế độ thua-ngay (Play / Daily Classic / Minesweeper...) -> mở popup thua.
-		# Chế độ có LƯỢT THỬ LẠI (Fog of War): trừ 1 lượt, hết lượt mới thua.
+		# Chế độ thua-ngay (Play / Daily Classic...) -> mở popup thua.
+		# Chế độ có LƯỢT THỬ LẠI (nếu có): trừ 1 lượt, hết lượt mới thua.
 		if game_mode_controller.game_mode != null and game_mode_controller.game_mode.register_hazard():
 			_game_over.call_deferred(_hazard_game_over_reason())
@@ -353,5 +342,5 @@
 
 
-## Luật "không công cụ": chặn CẢ gợi ý lẫn hoàn tác
+## Luật "không công cụ": chặn CẢ gợi ý lẫn dịch chuyển
 func _challenge_blocks_tool() -> bool:
 	var ch := _challenge()
@@ -381,5 +370,6 @@
 		return
 	var path: Array[Vector2i] = grid_controller.path if grid_controller != null else []
-	var fail := _challenge_rules.after_step(ch, path, game_state.floor_moves)
+	var maze: MazeData = grid_controller.maze if grid_controller != null else null
+	var fail := _challenge_rules.after_step(ch, path, game_state.floor_moves, maze)
 	if fail != "":
 		_challenge_fail(fail)
@@ -403,4 +393,5 @@
 
 func _complete_floor() -> void:
+	_cancel_teleport()
 	if timer_controller != null:
 		timer_controller.pause()
@@ -511,4 +502,5 @@
 		return
 	_run_active = false
+	_cancel_teleport()
 	if timer_controller != null:
 		timer_controller.stop()
@@ -797,35 +789,61 @@
 
 
-func undo() -> void:
-	# Challenge "không công cụ": bấm Hoàn tác = vi phạm -> thua ngay (popup thua thử thách)
+## Nút DỊCH CHUYỂN (Teleport) trên thanh công cụ:
+##   · Bấm lần 1 — tô sáng các ô trong tầm (`GridController.teleport_range`) quanh nhân vật.
+##   · Chạm 1 ô đã sáng — con trỏ NHẢY thẳng tới đó (kể cả có tường chắn), trừ 1 lượt Teleport.
+##   · Bấm lại nút / chạm ô khác — huỷ, KHÔNG mất lượt.
+func teleport() -> void:
+	# Challenge "không công cụ": bấm Dịch chuyển = vi phạm -> thua ngay (popup thua thử thách)
 	if _challenge_blocks_tool():
 		_challenge_fail(ChallengeGameMode.NO_TOOL)
 		return
-	# Hết lượt hoàn tác toàn tài khoản (nút đã bị khoá ở HUD) → không làm gì
-	if _tool_uses_left(GameManagerClass.TOOL_UNDO) <= 0:
-		return
-	# Wall Builder: Undo xoá ĐOẠN TƯỜNG vừa nối (chế độ không có nước đi để lùi)
-	if grid_controller != null and game_mode_controller != null \
-			and game_mode_controller.game_mode != null \
-			and game_mode_controller.game_mode.undo_drawn_wall(grid_controller.anchor_controller):
-		Sfx.play(Sfx.UNDO)
-		if game_state != null:
-			game_state.undos_used += 1     # nhiệm vụ "không dùng hoàn tác"
-		_consume_tool_use(GameManagerClass.TOOL_UNDO)
+	if not _run_active or _floor_finished or _memorize_active or _overlay_showing:
+		return
+	if _teleport_selecting:
+		_cancel_teleport()
 		_update_hud()
 		return
-	if grid_controller != null and grid_controller.undo_last_move():
-		# SFX: tiếng gôm tẩy quẹt trên giấy
-		Sfx.play(Sfx.UNDO)
-		if game_state != null:
-			# Hoàn lại ĐÚNG chi phí bước vừa đi (Countdown Cost thu 1..4 bước mỗi ô,
-			# các chế độ khác luôn là 1 -> giống hành vi cũ)
-			var refund := 1
-			if not _move_costs.is_empty():
-				refund = _move_costs.pop_back()
-			game_state.refund_step(refund)
-			game_state.undos_used += 1     # nhiệm vụ "không dùng hoàn tác"
-		_consume_tool_use(GameManagerClass.TOOL_UNDO)
+	# Hết lượt toàn tài khoản (nút đã bị khoá ở HUD) → không làm gì
+	if _tool_uses_left(GameManagerClass.TOOL_TELEPORT) <= 0:
+		return
+	if grid_controller == null or grid_view == null:
+		return
+	var targets := grid_controller.teleport_targets()
+	if targets.is_empty():
+		return
+	Sfx.play(Sfx.BTN_WOOD_TAP)
+	_teleport_selecting = true
+	grid_view.show_teleport_targets(targets)
+	_update_hud()
+
+
+## Người chơi chạm 1 ô đang sáng (Board phát `teleport_chosen`)
+func _on_teleport_chosen(pos: Vector2i) -> void:
+	if not _teleport_selecting:
+		return
+	_cancel_teleport()
+	if grid_controller == null or not grid_controller.teleport_to(pos):
 		_update_hud()
+		return
+	Sfx.play(Sfx.TELEPORT)
+	if game_state != null:
+		game_state.teleports_used += 1     # nhiệm vụ "không dùng dịch chuyển"
+	_consume_tool_use(GameManagerClass.TOOL_TELEPORT)
+	_update_hud()
+
+
+## Chạm ra ngoài các ô sáng → huỷ chọn (không mất lượt)
+func _on_teleport_cancelled() -> void:
+	if _teleport_selecting:
+		_cancel_teleport()
+		_update_hud()
+
+
+func _cancel_teleport() -> void:
+	if not _teleport_selecting:
+		return
+	_teleport_selecting = false
+	if grid_view != null:
+		grid_view.clear_teleport_targets()
 
 
```

### `scripts/core/controllers/game_mode_controller.gd`
```diff
--- a/scripts/core/controllers/game_mode_controller.gd
+++ b/scripts/core/controllers/game_mode_controller.gd
@@ -3,5 +3,5 @@
 ## ============================================================================
 ## Controller: Quản lý và chuyển đổi chiến lược chế độ chơi (GameMode Strategy).
-## Cung cấp khả năng chuyển đổi linh hoạt giữa 9 Game Modes của game.
+## Các chế độ còn lại: Play · Challenge · Daily · Dungeon · Blind Memory · Wall Builder.
 ## ============================================================================
 
@@ -36,18 +36,6 @@
 		"dungeon":
 			new_mode = DungeonGameMode.new()
-		"minesweeper":
-			new_mode = MinesweeperPathGameMode.new()
-		"sum_path":
-			new_mode = SumPathGameMode.new(difficulty)
-		"countdown_cost":
-			new_mode = CountdownCostGameMode.new(difficulty)
 		"blind_memory":
 			new_mode = BlindMemoryGameMode.new(difficulty)
-		"fog_of_war":
-			new_mode = FogOfWarGameMode.new(difficulty)
-		"fading_ink":
-			new_mode = FadingInkGameMode.new(difficulty)
-		"one_stroke":
-			new_mode = OneStrokeGameMode.new(difficulty)
 		"wall_builder":
 			new_mode = WallBuilderGameMode.new(difficulty)
```

### `scripts/core/controllers/grid_controller.gd`
```diff
--- a/scripts/core/controllers/grid_controller.gd
+++ b/scripts/core/controllers/grid_controller.gd
@@ -6,5 +6,6 @@
 ## - Thẩm định tính hợp lệ của nước đi và chướng ngại vật qua GameMode Strategy.
 ## - Quản lý AnchorController cho logic Tường Nghi Ngờ.
-## - Quản lý UndoController và HintController.
+## - Quản lý UndoController (lịch sử bước đi — chỉ dùng cho HỒI SINH) và HintController.
+## - DỊCH CHUYỂN (công cụ Teleport) + nhặt CHÌA mở ô KHOÁ.
 ## - Emit signal cho GameController: step_consumed / wall_hit / reached_end.
 ## ============================================================================
@@ -27,4 +28,6 @@
 @export var hint_controller: HintController = null
 @export var game_mode_controller: GameModeController = null
+## Tầm DỊCH CHUYỂN: các ô cách nhân vật tối đa N ô (khoảng cách Manhattan), bỏ qua tường chắn
+@export var teleport_range := 2
 
 var current_pos: Vector2i = Vector2i.ZERO
@@ -159,4 +162,5 @@
 
 		game_mode_controller.game_mode.on_player_moved(board_view, pos, maze)
+		_collect_key_at(pos)
 		step_consumed.emit(step_cost, false)
 
@@ -168,10 +172,75 @@
 		# Nước đi hợp lệ về hình học nhưng bị LUẬT của mode chặn (VD One Stroke còn ô trống
 		# nên chưa được chạm F) -> mode tự phản hồi (hiện chữ nổi cảnh báo...)
-		game_mode_controller.game_mode.on_move_blocked(
-			board_view, current_pos, pos, str(eval_result.get("reason", "")))
-
-
-# ---------------------------------------------------------------------------
-# Undo & Hint Support
+		var reason := str(eval_result.get("reason", ""))
+		if reason == "locked":
+			# Ô KHOÁ: rung + hiện ổ khoá, KHÔNG trừ bước/lượt
+			Sfx.play(Sfx.LOCK_BUMP)
+			board_view.show_lock_bump(pos)
+		game_mode_controller.game_mode.on_move_blocked(board_view, current_pos, pos, reason)
+
+
+# ---------------------------------------------------------------------------
+# CHÌA KHOÁ
+# ---------------------------------------------------------------------------
+## Nhân vật vừa tới `pos`: có chìa thì nhặt, mở mọi ô khoá cùng id + cập nhật bàn cờ
+func _collect_key_at(pos: Vector2i) -> void:
+	if maze == null:
+		return
+	var got := maze.collect_key(pos)
+	if got.is_empty():
+		return
+	Sfx.play(Sfx.KEY_PICKUP)
+	if board_view != null:
+		board_view.on_key_collected(pos, got.get("unlocked", []))
+
+
+# ---------------------------------------------------------------------------
+# DỊCH CHUYỂN (Teleport)
+# ---------------------------------------------------------------------------
+## Các ô có thể dịch chuyển tới: trong tầm `teleport_range`, thuộc board, KHÔNG bị khoá,
+## chế độ cho phép. Tường chắn giữa đường KHÔNG ảnh hưởng.
+func teleport_targets() -> Array[Vector2i]:
+	var out: Array[Vector2i] = []
+	var mode: BaseGameMode = game_mode_controller.game_mode if game_mode_controller != null else null
+	if maze == null or mode == null or not mode.allows_teleport():
+		return out
+	for dy in range(-teleport_range, teleport_range + 1):
+		for dx in range(-teleport_range, teleport_range + 1):
+			var dist := absi(dx) + absi(dy)
+			if dist == 0 or dist > teleport_range:
+				continue
+			var p := current_pos + Vector2i(dx, dy)
+			if not maze.is_in_bounds(p) or not maze.is_cell_active(p) or maze.is_locked(p):
+				continue
+			if not mode.can_teleport_to(p, maze):
+				continue
+			out.append(p)
+	return out
+
+
+## Nhảy thẳng tới `pos` (bỏ qua tường). Tính như 1 nước đi: ghi vào đường đi + lịch sử hồi sinh,
+## nhặt chìa nếu có, báo `step_consumed` / `reached_end`. Trả false nếu ô không hợp lệ.
+func teleport_to(pos: Vector2i) -> bool:
+	if board_view == null or not teleport_targets().has(pos):
+		return false
+	var mode := game_mode_controller.game_mode
+	var prev_pos := current_pos
+	var step_cost := 1
+	current_pos = pos
+	path.append(pos)
+	if undo_controller != null:
+		undo_controller.record_move(prev_pos, pos, step_cost)
+	board_view.teleport_cursor_to(pos)
+	board_view.set_moving_path(path)
+	mode.on_player_moved(board_view, pos, maze)
+	_collect_key_at(pos)
+	step_consumed.emit(step_cost, false)
+	if mode.check_completion(current_pos, maze, anchor_controller):
+		reached_end.emit()
+	return true
+
+
+# ---------------------------------------------------------------------------
+# Lùi bước (chỉ dùng khi HỒI SINH) & Hint Support
 # ---------------------------------------------------------------------------
 func undo_last_move() -> bool:
```

### `scripts/core/controllers/hint_controller.gd`
```diff
--- a/scripts/core/controllers/hint_controller.gd
+++ b/scripts/core/controllers/hint_controller.gd
@@ -13,5 +13,5 @@
 	if maze == null:
 		return current_pos
-	var path := maze.get_shortest_path(current_pos, maze.get_end())
+	var path := maze.get_play_path(current_pos, maze.get_end())   # có tính ô khoá + chìa
 	if path.size() >= 2:
 		var next_step: Vector2i = path[1]
```

### `scripts/core/controllers/mission_controller.gd`
```diff
--- a/scripts/core/controllers/mission_controller.gd
+++ b/scripts/core/controllers/mission_controller.gd
@@ -91,5 +91,5 @@
 		int(metrics["submit_misses"]),
 		ctx.state.hints_used,
-		ctx.state.undos_used,
+		ctx.state.teleports_used,
 		str(int(ctx.elapsed)),
 		str(ctx.final),
@@ -378,8 +378,8 @@
 			return _verdict(ok, _pass_fail(ok) if ok else tr("STR_MISSION_ST_HINT_USED").format([used]))
 
-		MissionTypes.NO_UNDO:
-			var used := state.undos_used
+		MissionTypes.NO_TELEPORT:
+			var used := state.teleports_used
 			var ok := used == 0
-			return _verdict(ok, _pass_fail(ok) if ok else tr("STR_MISSION_ST_UNDO_USED").format([used]))
+			return _verdict(ok, _pass_fail(ok) if ok else tr("STR_MISSION_ST_TELEPORT_USED").format([used]))
 
 		MissionTypes.NO_WRONG_SUBMIT:
```

### `scripts/core/controllers/mission_types.gd`
```diff
--- a/scripts/core/controllers/mission_types.gd
+++ b/scripts/core/controllers/mission_types.gd
@@ -17,5 +17,5 @@
 ##        sum_lt · sum_le · sum_gt · sum_ge
 ##   E. Cách chơi (công cụ):
-##        no_hint · no_undo
+##        no_hint · no_teleport
 ##   F. Riêng Wall Builder:
 ##        no_wrong_submit (gửi đúng ngay lần GỬI đầu tiên)
@@ -41,5 +41,5 @@
 const SUM_GE := "sum_ge"
 const NO_HINT := "no_hint"
-const NO_UNDO := "no_undo"
+const NO_TELEPORT := "no_teleport"
 const NO_WRONG_SUBMIT := "no_wrong_submit"
 
@@ -71,5 +71,5 @@
 	SUM_GE,
 	NO_HINT,
-	NO_UNDO,
+	NO_TELEPORT,
 	NO_WRONG_SUBMIT,
 ]
@@ -92,5 +92,5 @@
 	SUM_GE: {"key": "STR_MISSION_SUM_GE", "param": PARAM_SUM, "unit": ""},
 	NO_HINT: {"key": "STR_MISSION_NO_HINT", "param": PARAM_NONE, "unit": ""},
-	NO_UNDO: {"key": "STR_MISSION_NO_UNDO", "param": PARAM_NONE, "unit": ""},
+	NO_TELEPORT: {"key": "STR_MISSION_NO_TELEPORT", "param": PARAM_NONE, "unit": ""},
 	NO_WRONG_SUBMIT: {"key": "STR_MISSION_NO_WRONG_SUBMIT", "param": PARAM_NONE, "unit": ""},
 }
@@ -105,5 +105,5 @@
 	VISIT_ALL_NUMBERED,
 	NO_HINT,
-	NO_UNDO,
+	NO_TELEPORT,
 	NO_WRONG_SUBMIT,
 ]
@@ -171,6 +171,6 @@
 		NO_HINT:
 			return "Không dùng gợi ý"
-		NO_UNDO:
-			return "Không dùng hoàn tác"
+		NO_TELEPORT:
+			return "Không dùng dịch chuyển"
 		_:
 			return type_id
```

### `scripts/core/controllers/tutorial_controller.gd`
```diff
--- a/scripts/core/controllers/tutorial_controller.gd
+++ b/scripts/core/controllers/tutorial_controller.gd
@@ -16,11 +16,5 @@
 	"how_to_play_move": "res://scenes/objects/tutorials/how_to_play_move.tscn",
 	"how_to_play_checking_wall": "res://scenes/objects/tutorials/how_to_play_checking_wall.tscn",
-	"how_to_play_minesweeper": "res://nodes/tutorials/how_to_play_minesweeper.tscn",
-	"how_to_play_one_stroke": "res://nodes/tutorials/how_to_play_one_stroke.tscn",
-	"how_to_play_sum_path": "res://nodes/tutorials/how_to_play_sum_path.tscn",
 	"how_to_play_wall_builder": "res://scenes/objects/tutorials/how_to_play_wall_builder.tscn",
-	"how_to_play_countdown_cost": "res://nodes/tutorials/how_to_play_countdown_cost.tscn",
-	"how_to_play_fading_ink": "res://nodes/tutorials/how_to_play_fading_ink.tscn",
-	"how_to_play_fog_of_war": "res://nodes/tutorials/how_to_play_fog_of_war.tscn",
 	"how_to_play_blind_memory": "res://scenes/objects/tutorials/how_to_play_blind_memory.tscn",
 	"how_to_use_tool": "res://scenes/objects/tutorials/how_to_use_tool.tscn",
```

### `scripts/core/controllers/ui_controller.gd`
```diff
--- a/scripts/core/controllers/ui_controller.gd
+++ b/scripts/core/controllers/ui_controller.gd
@@ -31,6 +31,6 @@
 ## Dòng phụ nhỏ dưới tiêu đề (VD "PLAY MODE · CHƯƠNG 1"). Rỗng = ẩn.
 @export var subtitle_label: Label = null
-## Nút UNDO của thanh nút dưới — được NHẤN MẠNH khi Countdown Cost hết ngân sách (phải lùi bước)
-@export var undo_button: TextureButton = null
+## Nút TELEPORT của thanh nút dưới — được NHẤN MẠNH khi đang chọn ô đích dịch chuyển
+@export var teleport_button: TextureButton = null
 ## Nút CHƠI LẠI (ẩn sẵn dưới thanh nút) — hiện khi Sum Path không còn thắng được nữa
 @export var replay_button: TextureButton = null
@@ -42,7 +42,7 @@
 var run_info: Dictionary = {}
 
-var _undo_highlight_on := false
+var _teleport_highlight_on := false
 var _replay_shown := false
-var _undo_highlight_tween: Tween = null
+var _teleport_highlight_tween: Tween = null
 
 
@@ -50,36 +50,36 @@
 	run_info = info
 	# Cờ trạng thái đặc biệt của ván (GameController tính trong _update_hud):
-	#  - undo_highlight: Countdown Cost hết ngân sách -> khoá di chuyển, NHẤN MẠNH nút Undo
+	#  - teleport_active: đang chọn ô đích -> NHẤN MẠNH nút Teleport
 	#  - replay_visible: Sum Path không thể thắng nữa -> hiện nút CHƠI LẠI dưới thanh nút
-	set_undo_highlight(bool(info.get("undo_highlight", false)))
+	set_teleport_highlight(bool(info.get("teleport_active", false)))
 	set_replay_visible(bool(info.get("replay_visible", false)))
 
 
 # ---------------------------------------------------------------------------
-# Cờ trạng thái nút (Countdown Cost hết ngân sách · Sum Path hết đường thắng)
-# ---------------------------------------------------------------------------
-## Nhấn mạnh nút UNDO: ám vàng + nhịp phồng nhẹ để người chơi biết cần lùi bước để tiếp tục
-func set_undo_highlight(on: bool) -> void:
-	_undo_highlight_on = on
-	if undo_button == null:
-		return
-	if _undo_highlight_tween != null and _undo_highlight_tween.is_valid():
-		_undo_highlight_tween.kill()
-	_undo_highlight_tween = null
+# Cờ trạng thái nút (đang chọn Teleport · hết đường thắng)
+# ---------------------------------------------------------------------------
+## Nhấn mạnh nút TELEPORT: ám tím + nhịp phồng nhẹ khi đang chọn ô đích
+func set_teleport_highlight(on: bool) -> void:
+	_teleport_highlight_on = on
+	if teleport_button == null:
+		return
+	if _teleport_highlight_tween != null and _teleport_highlight_tween.is_valid():
+		_teleport_highlight_tween.kill()
+	_teleport_highlight_tween = null
 	# Nhịp "thở" khai trong `action_bar.tscn` (player `PulseAnim`); thiếu thì fallback tween
-	var bar := _undo_pulse_bar()
+	var bar := _teleport_pulse_bar()
 	if on:
-		undo_button.modulate = Color(1.25, 1.15, 0.55)  # keep-code: hoạt cảnh/trạng thái runtime (tween)
-		if bar == null or not UIAnim.play_layout_anim(bar, "PulseAnim", &"pulse_undo", undo_button):
-			_undo_highlight_tween = UIAnim.play_pulse(undo_button, 1.12, 0.7)
+		teleport_button.modulate = Color(0.85, 0.7, 1.25)  # keep-code: hoạt cảnh/trạng thái runtime (tween)
+		if bar == null or not UIAnim.play_layout_anim(bar, "PulseAnim", &"pulse_teleport", teleport_button):
+			_teleport_highlight_tween = UIAnim.play_pulse(teleport_button, 1.12, 0.7)
 	else:
-		undo_button.modulate = Color.WHITE  # keep-code: hoạt cảnh/trạng thái runtime (tween)
+		teleport_button.modulate = Color.WHITE  # keep-code: hoạt cảnh/trạng thái runtime (tween)
 		if bar != null:
 			UIAnim.stop_layout_anim(bar, "PulseAnim")
-		undo_button.scale = Vector2.ONE  # keep-code: hoạt cảnh/trạng thái runtime (tween)
-
-
-## Thanh công cụ của HUD đang dùng (chứa player `PulseAnim` cho nhịp nút Undo)
-func _undo_pulse_bar() -> Node:
+		teleport_button.scale = Vector2.ONE  # keep-code: hoạt cảnh/trạng thái runtime (tween)
+
+
+## Thanh công cụ của HUD đang dùng (chứa player `PulseAnim` cho nhịp nút Teleport)
+func _teleport_pulse_bar() -> Node:
 	if hud == null:
 		return null
@@ -87,6 +87,6 @@
 
 
-func undo_highlighted() -> bool:
-	return _undo_highlight_on
+func teleport_highlighted() -> bool:
+	return _teleport_highlight_on
 
 
@@ -146,5 +146,5 @@
 			# → HUD hiện trên badge PanelLimit + khoá nút khi hết lượt
 			"skip_left": int(run_info.get("skip_left", 0)),
-			"undo_left": int(run_info.get("undo_left", 0)),
+			"teleport_left": int(run_info.get("teleport_left", 0)),
 			"hint_left": int(run_info.get("hint_left", 0)),
 		})
```

### `scripts/core/game_state.gd`
```diff
--- a/scripts/core/game_state.gd
+++ b/scripts/core/game_state.gd
@@ -17,5 +17,5 @@
 var perfect_floor: bool = true  # chưa đâm tường lần nào trong floor
 var hints_used: int = 0         # số lần bấm Gợi ý trong floor hiện tại (cho nhiệm vụ)
-var undos_used: int = 0         # số lần bấm Hoàn tác trong floor hiện tại (cho nhiệm vụ)
+var teleports_used: int = 0     # số lần DỊCH CHUYỂN trong floor hiện tại (cho nhiệm vụ)
 ## --- Số liệu Profiler (bản Hồ sơ mới) ---
 var wall_draws: int = 0         # số lần VẼ tường nghi ngờ (kéo nối 2 giao điểm)
@@ -53,5 +53,5 @@
 	perfect_floor = true
 	hints_used = 0
-	undos_used = 0
+	teleports_used = 0
 	wall_draws = 0
 	wall_erases = 0
```

### `scripts/core/level_catalog.gd`
```diff
--- a/scripts/core/level_catalog.gd
+++ b/scripts/core/level_catalog.gd
@@ -12,13 +12,8 @@
 ## ============================================================================
 
-## 8 chế độ Special xoay vòng cho Daily (thứ tự cũng là thứ tự xoay theo ngày)
+## Chế độ Special còn lại (xoay vòng cho Daily). Minesweeper · Sum Path · Countdown Cost ·
+## Fading Ink · One Stroke đã XOÁ; Fog of War đã GỘP vào Challenge (id `fog_of_war` của ChallengeGameMode).
 const SPECIAL_MODES: Array[String] = [
-	"minesweeper",
-	"sum_path",
-	"countdown_cost",
 	"blind_memory",
-	"fog_of_war",
-	"fading_ink",
-	"one_stroke",
 	"wall_builder",
 ]
@@ -46,5 +41,5 @@
 
 
-## id chế độ có tồn tại không (Play · Dungeon · Daily Classic · 8 chế độ Special)
+## id chế độ có tồn tại không (Play · Dungeon · Daily Classic · các chế độ Special)
 static func is_known_mode(mode_id: String) -> bool:
 	if mode_id in BASE_MODES:
```

### `scripts/core/maze_data.gd`
```diff
--- a/scripts/core/maze_data.gd
+++ b/scripts/core/maze_data.gd
@@ -32,4 +32,11 @@
 var _wall_count: Array = []      # _wall_count[y][x]
 var _tree_edges: Dictionary = {} # key cạnh thuộc cây khung (bắt buộc mở)
+
+## Ô KHOÁ: pos -> id khoá (>= 1). Ô khoá KHÔNG đi vào được cho tới khi nhặt CHÌA cùng id.
+var _locks: Dictionary = {}
+## Ô CHÌA: pos -> id chìa (>= 1). Chìa được nhặt khi nhân vật bước vào ô (kể cả khi dịch chuyển tới).
+var _keys: Dictionary = {}
+## id chìa đã nhặt trong ván này (id -> true) — mở mọi ô khoá cùng id
+var _opened: Dictionary = {}
 
 
@@ -383,4 +390,118 @@
 
 
+# ---------------------------------------------------------------------------
+# Ô KHOÁ + CHÌA KHOÁ
+# ---------------------------------------------------------------------------
+## Đặt 1 ô khoá (id >= 1). Ô S/F và ô ngoài board không được khoá.
+func add_lock(pos: Vector2i, lock_id := 1) -> void:
+	if not is_cell_active(pos) or pos == start or pos == end:
+		return
+	_locks[pos] = maxi(lock_id, 1)
+
+
+## Đặt 1 chìa khoá (id >= 1) lên ô. Ô S không đặt chìa (nhặt ngay từ đầu thì vô nghĩa).
+func add_key(pos: Vector2i, key_id := 1) -> void:
+	if not is_cell_active(pos) or pos == start or _locks.has(pos):
+		return
+	_keys[pos] = maxi(key_id, 1)
+
+
+func has_locks() -> bool:
+	return not _locks.is_empty()
+
+
+## id khoá của ô (0 = ô không phải ô khoá). KHÔNG xét đã mở hay chưa — xem `is_locked()`.
+func lock_id_at(pos: Vector2i) -> int:
+	return int(_locks.get(pos, 0))
+
+
+## id chìa còn nằm trên ô (0 = không có chìa — chưa từng có hoặc đã nhặt)
+func key_id_at(pos: Vector2i) -> int:
+	return int(_keys.get(pos, 0))
+
+
+## Ô đang BỊ KHOÁ (có khoá và chưa nhặt chìa cùng id) — không đi / dịch chuyển vào được
+func is_locked(pos: Vector2i) -> bool:
+	return _locks.has(pos) and not _opened.has(int(_locks[pos]))
+
+
+## Toạ độ mọi ô khoá còn đóng (để Board vẽ)
+func locked_cells() -> Array[Vector2i]:
+	var out: Array[Vector2i] = []
+	for pos: Vector2i in _locks:
+		if is_locked(pos):
+			out.append(pos)
+	return out
+
+
+func key_cells() -> Array[Vector2i]:
+	var out: Array[Vector2i] = []
+	for pos: Vector2i in _keys:
+		out.append(pos)
+	return out
+
+
+## Nhân vật vừa bước vào `pos`: có chìa thì NHẶT + mở mọi ô khoá cùng id.
+## Trả về `{ "key_id": int, "unlocked": Array[Vector2i] }`, rỗng nếu ô không có chìa.
+func collect_key(pos: Vector2i) -> Dictionary:
+	if not _keys.has(pos):
+		return {}
+	var key_id := int(_keys[pos])
+	_keys.erase(pos)
+	var unlocked: Array[Vector2i] = []
+	if not _opened.has(key_id):
+		_opened[key_id] = true
+		for lock_pos: Vector2i in _locks:
+			if int(_locks[lock_pos]) == key_id:
+				unlocked.append(lock_pos)
+	return {"key_id": key_id, "unlocked": unlocked}
+
+
+## Đường đi ngắn nhất `from_pos -> to_pos` CÓ TÍNH ô khoá/chìa (BFS theo cặp ô + tập chìa đã nhặt):
+## đường có thể đi vòng qua ô chìa trước rồi mới vào ô khoá. Dùng cho Gợi ý; mê cung không có
+## khoá thì kết quả giống `get_shortest_path()`. Rỗng = hiện không có đường (VD thiết kế thiếu chìa).
+func get_play_path(from_pos: Vector2i, to_pos: Vector2i) -> Array[Vector2i]:
+	if _locks.is_empty():
+		return get_shortest_path(from_pos, to_pos)
+	if not is_cell_active(from_pos) or not is_cell_active(to_pos):
+		return []
+	var opened_mask := 0
+	for kid: int in _opened:
+		opened_mask |= 1 << clampi(kid, 0, 30)
+	var cells := width * height
+	var start_state := from_pos.y * width + from_pos.x + cells * opened_mask
+	var parent: Dictionary = {start_state: -1}
+	var queue: Array[int] = [start_state]
+	while not queue.is_empty():
+		var state: int = queue.pop_front()
+		var mask := floori(float(state) / float(cells))
+		var cell_index := state % cells
+		var cur := Vector2i(cell_index % width, floori(float(cell_index) / float(width)))
+		if cur == to_pos:
+			var rev: Array[Vector2i] = []
+			var walk := state
+			while walk != -1:
+				var wi := walk % cells
+				rev.append(Vector2i(wi % width, floori(float(wi) / float(width))))
+				walk = int(parent[walk])
+			rev.reverse()
+			return rev
+		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
+			var nxt := cur + d
+			if not is_in_bounds(nxt) or not is_cell_active(nxt) or has_wall(cur, nxt):
+				continue
+			if _locks.has(nxt) and not _opened.has(int(_locks[nxt])) \
+					and (mask & (1 << clampi(int(_locks[nxt]), 0, 30))) == 0:
+				continue
+			var nmask := mask
+			if _keys.has(nxt):
+				nmask |= 1 << clampi(int(_keys[nxt]), 0, 30)
+			var nstate := nxt.y * width + nxt.x + cells * nmask
+			if not parent.has(nstate):
+				parent[nstate] = state
+				queue.append(nstate)
+	return []
+
+
 # --- Key helpers ---
 func _h_key(ix: int, iy: int) -> String:
```

### `scripts/core/run_reporter.gd`
```diff
--- a/scripts/core/run_reporter.gd
+++ b/scripts/core/run_reporter.gd
@@ -30,5 +30,5 @@
 		"wall_hits": state.floor_wall_hits,
 		"hints_used": state.hints_used,
-		"undos_used": state.undos_used,
+		"teleports_used": state.teleports_used,
 		"hardcore": str(mode.difficulty).to_lower() == "hardcore",
 	})
@@ -50,5 +50,5 @@
 		"level_run": gm != null and bool(gm.get("level_run")),
 		"level_id": int(gm.get("current_level")) if gm != null else 0,
-		"undos": state.undos_used,
+		"teleports": state.teleports_used,
 		"hints": state.hints_used,
 		"wall_draws": state.wall_draws,
```

### `scripts/core/tool_inventory.gd`
```diff
--- a/scripts/core/tool_inventory.gd
+++ b/scripts/core/tool_inventory.gd
@@ -2,5 +2,5 @@
 extends RefCounted
 ## ============================================================================
-## KHO DỤNG CỤ (skip · undo · hint) — tách khỏi `GameManager` (autoload).
+## KHO DỤNG CỤ (skip · teleport · hint) — tách khỏi `GameManager` (autoload).
 ##
 ## Số lượt dùng là TÀI NGUYÊN TOÀN CỤC: không cấp lại theo màn/tầng, chỉ tăng khi
@@ -15,7 +15,7 @@
 
 const SKIP := "skip"
-const UNDO := "undo"
+const TELEPORT := "teleport"
 const HINT := "hint"
-const IDS: Array[String] = [SKIP, UNDO, HINT]
+const IDS: Array[String] = [SKIP, TELEPORT, HINT]
 const INITIAL_USES := 3
 ## Nguồn hợp lệ khi cấp lượt dùng: mua ở Shop · thưởng nhiệm vụ · thưởng mốc Sao Daily · rương chương
@@ -24,5 +24,5 @@
 var uses: Dictionary = {
 	SKIP: INITIAL_USES,
-	UNDO: INITIAL_USES,
+	TELEPORT: INITIAL_USES,
 	HINT: INITIAL_USES,
 }
@@ -70,4 +70,7 @@
 		return
 	var saved: Dictionary = value
+	# Save cũ: công cụ "undo" đã đổi thành "teleport" -> giữ nguyên số dư
+	if saved.has("undo") and not saved.has(TELEPORT):
+		uses[TELEPORT] = maxi(int(saved["undo"]), 0)
 	for tool_id in IDS:
 		if saved.has(tool_id):
```

### `scripts/core/tutorial_launcher.gd`
```diff
--- a/scripts/core/tutorial_launcher.gd
+++ b/scripts/core/tutorial_launcher.gd
@@ -22,11 +22,5 @@
 	"daily_classic": ["how_to_play_move", "how_to_play_checking_wall", "how_to_use_tool"],
 	"daily_challenge": ["how_to_play_move", "how_to_play_checking_wall", "how_to_use_tool"],
-	"minesweeper": ["how_to_play_minesweeper"],
-	"sum_path": ["how_to_play_sum_path"],
-	"countdown_cost": ["how_to_play_countdown_cost"],
 	"blind_memory": ["how_to_play_blind_memory"],
-	"fog_of_war": ["how_to_play_fog_of_war"],
-	"fading_ink": ["how_to_play_fading_ink"],
-	"one_stroke": ["how_to_play_one_stroke"],
 	"wall_builder": ["how_to_play_wall_builder"],
 }
```

### `scripts/core/tutorial_store.gd`
```diff
--- a/scripts/core/tutorial_store.gd
+++ b/scripts/core/tutorial_store.gd
@@ -18,7 +18,4 @@
 	"how_to_play_writting_hint": false,
 	"core_completed": false,
-	"how_to_play_minesweeper": false,
-	"how_to_play_one_stroke": false,
-	"how_to_play_sum_path": false,
 	"how_to_play_wall_builder": false,
 }
```

### `scripts/data/level_data.gd`
```diff
--- a/scripts/data/level_data.gd
+++ b/scripts/data/level_data.gd
@@ -14,5 +14,5 @@
 ## CHALLENGE MODE: màn này gắn THỬ THÁCH nào ("" = không gắn). Id hợp lệ:
 ## scripts/modes/challenge_game_mode.gd — countdown · move_limit · step_timer · no_tool ·
-## no_move_overlapped · walk_number_only · walk_empty_only · backtrack_limit.
+## no_move_overlapped · walk_number_only · walk_empty_only · backtrack_limit · fog_of_war.
 ## `challenge_param` = số giây / số bước / số lượt tuỳ luật (0 = game tự tính mặc định).
 @export var challenge: String = ""
@@ -41,5 +41,13 @@
 @export var cell_mask: PackedByteArray = PackedByteArray()
 
-## Dữ liệu mở rộng cho các mode khác (Minesweeper, Sum Path, ...)
+## Ô KHOÁ: các BỘ BA (x, y, id) nối tiếp nhau [x0, y0, id0, x1, y1, id1, ...] — id >= 1.
+## Ô khoá hiện hình ổ khoá, KHÔNG đi / dịch chuyển vào được cho tới khi người chơi nhặt CHÌA cùng id.
+## Không đặt khoá lên ô S / F / ô ngoài board (bị bỏ qua).
+@export var lock_cells: PackedInt32Array = PackedInt32Array()
+## CHÌA KHOÁ: các bộ ba (x, y, id) như `lock_cells`. Bước (hoặc dịch chuyển) vào ô chìa = nhặt chìa,
+## mở mọi ô khoá cùng id. Mỗi id khoá nên có ÍT NHẤT 1 chìa tới được mà không cần đi qua chính ô khoá đó.
+@export var key_cells: PackedInt32Array = PackedInt32Array()
+
+## Dữ liệu mở rộng cho các mode khác (hiện chưa chế độ nào dùng)
 @export var custom_cell_values: Dictionary = {}
 
@@ -111,4 +119,10 @@
 	# Hàm này tự ép tường bao quanh các ô ngoài board + tính lại số trên ô
 	maze.set_cell_mask(cell_mask)
+
+	# Ô khoá + chìa khoá (đặt SAU mask để biết ô nào thuộc board; khoá trước, chìa sau)
+	for i in range(0, lock_cells.size() - 2, 3):
+		maze.add_lock(Vector2i(lock_cells[i], lock_cells[i + 1]), lock_cells[i + 2])
+	for i in range(0, key_cells.size() - 2, 3):
+		maze.add_key(Vector2i(key_cells[i], key_cells[i + 1]), key_cells[i + 2])
 	return maze
 
```

### `scripts/modes/base_game_mode.gd`
```diff
--- a/scripts/modes/base_game_mode.gd
+++ b/scripts/modes/base_game_mode.gd
@@ -158,5 +158,9 @@
 	if d.x + d.y != 1:
 		return { "allowed": false, "is_hazard": false, "hazard_type": "none" }
-	
+
+	# Ô KHOÁ chưa mở chìa: không đi vào được (không phải đâm tường — không trừ lượt/không thua)
+	if maze.is_locked(to_pos):
+		return { "allowed": false, "is_hazard": false, "hazard_type": "none", "reason": "locked", "to": to_pos }
+
 	return { "allowed": true, "is_hazard": false, "hazard_type": "none" }
 
@@ -179,5 +183,5 @@
 
 
-## Người chơi vừa LÙI 1 bước (Undo). Mode nào có trạng thái riêng thì lùi theo
+## Người chơi vừa LÙI 1 bước (hồi sinh). Mode nào có trạng thái riêng thì lùi theo
 ## (VD Fading Ink hồi lại mực đã phai). `from_pos` = ô vừa rời, `to_pos` = ô quay về.
 func on_move_undone(_grid_view: Control, _from_pos: Vector2i, _to_pos: Vector2i, _maze: MazeData) -> void:
@@ -247,9 +251,4 @@
 
 
-## Lùi 1 đoạn tường đã nối (Undo riêng của Wall Builder). `true` = đã xoá 1 đoạn.
-func undo_drawn_wall(_anchor_controller: AnchorController) -> bool:
-	return false
-
-
 ## Gợi ý kiểu "mở 1 đoạn tường" (Wall Builder). `true` = đã mở/khoá 1 đoạn.
 func hint_wall(_anchor_controller: AnchorController, _maze: MazeData) -> bool:
@@ -259,4 +258,17 @@
 ## Bàn chơi có hiện nhân vật không (Wall Builder: KHÔNG có nhân vật, không di chuyển)
 func shows_player() -> bool:
+	return true
+
+
+# ---------------------------------------------------------------------------
+# DỊCH CHUYỂN (công cụ Teleport)
+# ---------------------------------------------------------------------------
+## Chế độ có cho dùng công cụ Dịch chuyển không (mặc định: có nhân vật thì có — Wall Builder không)
+func allows_teleport() -> bool:
+	return shows_player()
+
+
+## Ô `pos` có được chọn làm điểm đến dịch chuyển không (luật riêng của chế độ; ô khoá do GridController loại)
+func can_teleport_to(_pos: Vector2i, _maze: MazeData) -> bool:
 	return true
 
```

### `scripts/modes/challenge_game_mode.gd`
```diff
--- a/scripts/modes/challenge_game_mode.gd
+++ b/scripts/modes/challenge_game_mode.gd
@@ -9,13 +9,15 @@
 ## là THUA NGAY, mở popup `gameover_challenge.tscn`. Thắng màn mở `winning_challenge.tscn`.
 ##
-## 8 thử thách (id trong CHALLENGE_IDS):
+## 9 thử thách (id trong CHALLENGE_IDS):
 ##   countdown           — hoàn thành TRƯỚC khi hết đếm ngược (giây)
 ##   move_limit          — hoàn thành trong TỐI ĐA N bước (vượt N = thua)
 ##   step_timer          — MỖI BƯỚC phải đi trong X giây (đồng hồ con, reset sau mỗi bước)
-##   no_tool             — KHÔNG dùng CÔNG CỤ: bấm GỢI Ý hoặc HOÀN TÁC = thua (gộp no_hint + no_undo)
+##   no_tool             — KHÔNG dùng CÔNG CỤ: bấm GỢI Ý hoặc DỊCH CHUYỂN = thua
 ##   no_move_overlapped  — KHÔNG đi lại trên đường đã đi (thay luật cũ no_revisit, tên rõ hơn)
 ##   walk_number_only    — CHỈ đi trên ô CÓ SỐ (bước vào ô không số = thua)
 ##   walk_empty_only     — CHỈ đi trên ô KHÔNG SỐ (bước vào ô có số = thua)
 ##   backtrack_limit     — quay đầu (lùi về ô vừa rời) tối đa N lần (vượt N = thua)
+##   fog_of_war          — SƯƠNG MÙ: chỉ thấy số ở các ô quanh nhân vật (bán kính 1), tường ẩn hết
+##                         (gộp từ chế độ Special "Fog of War" cũ — đâm tường vẫn = thua như Play)
 ##
 ## HUD (ChallengeHUD): Head = tên luật · Value = số chính · Sub = chú thích nhỏ.
@@ -31,8 +33,9 @@
 const WALK_EMPTY_ONLY := "walk_empty_only"
 const BACKTRACK_LIMIT := "backtrack_limit"
+const FOG_OF_WAR := "fog_of_war"
 
 const CHALLENGE_IDS: PackedStringArray = [
 	COUNTDOWN, MOVE_LIMIT, STEP_TIMER, NO_TOOL,
-	NO_MOVE_OVERLAPPED, WALK_NUMBER_ONLY, WALK_EMPTY_ONLY, BACKTRACK_LIMIT,
+	NO_MOVE_OVERLAPPED, WALK_NUMBER_ONLY, WALK_EMPTY_ONLY, BACKTRACK_LIMIT, FOG_OF_WAR,
 ]
 
@@ -47,4 +50,5 @@
 	WALK_EMPTY_ONLY: "STR_CHALLENGE_HEAD_WALK_EMPTY",
 	BACKTRACK_LIMIT: "STR_CHALLENGE_HEAD_BACKTRACK",
+	FOG_OF_WAR: "STR_CHALLENGE_HEAD_FOG",
 }
 const NAME_KEYS := {
@@ -57,4 +61,5 @@
 	WALK_EMPTY_ONLY: "STR_CHALLENGE_NAME_WALK_EMPTY",
 	BACKTRACK_LIMIT: "STR_CHALLENGE_NAME_BACKTRACK",
+	FOG_OF_WAR: "STR_CHALLENGE_NAME_FOG",
 }
 ## Khoá dịch CHÚ THÍCH NHỎ dưới Value (Sub)
@@ -68,4 +73,5 @@
 	WALK_EMPTY_ONLY: "STR_CHALLENGE_SUB_WALK_EMPTY",
 	BACKTRACK_LIMIT: "STR_CHALLENGE_SUB_BACKTRACK",
+	FOG_OF_WAR: "STR_CHALLENGE_SUB_FOG",
 }
 ## Khoá dịch LÝ DO THUA (popup GameOver thử thách) — theo `reason` GameController gửi
@@ -88,4 +94,6 @@
 const COUNTDOWN_PER_CELL := 4
 const COUNTDOWN_MIN := 75
+## Fog of War: bán kính nhìn thấy số quanh nhân vật (1 = 3×3 ô)
+const FOG_RADIUS := 1
 
 ## Thử thách đang gắn (rỗng = ván này chơi như Play Mode thường)
@@ -93,4 +101,8 @@
 ## Tham số thử thách: số giây / số bước / số lượt tuỳ luật (0 = lấy mặc định)
 var challenge_param := 0
+
+## Fog of War: vị trí nhân vật + các ô đã được "soi sáng" (để Board làm mờ ô chưa khám phá)
+var _fog_pos: Vector2i = Vector2i.ZERO
+var _fog_explored: Dictionary = {}
 
 
@@ -131,4 +143,8 @@
 
 ## 2 luật "đi trên ô ...": kiểm ô ĐÍCH trước khi bước (xem `evaluate_move`)
+func is_fog_rule() -> bool:
+	return challenge_id == FOG_OF_WAR
+
+
 func is_walk_rule() -> bool:
 	return challenge_id == WALK_NUMBER_ONLY or challenge_id == WALK_EMPTY_ONLY
@@ -177,5 +193,17 @@
 	if is_active() and challenge_param <= 0:
 		challenge_param = _default_param(maze)
+	prepare_rule(maze)
 	return maze
+
+
+## Chuẩn bị riêng của từng luật SAU khi có bàn (Fog of War: ẩn mọi tường + mở sương quanh S).
+## `DailyChallengeGameMode` (tự sinh bàn) cũng gọi hàm này.
+func prepare_rule(maze: MazeData) -> void:
+	if not is_fog_rule() or maze == null:
+		return
+	maze.set_all_walls_visible(false)
+	_fog_explored.clear()
+	_fog_pos = maze.get_start()
+	_fog_reveal(_fog_pos, maze)
 
 
@@ -222,4 +250,50 @@
 	var has_number := not get_cell_text(pos, maze).is_empty()
 	return has_number if challenge_id == WALK_NUMBER_ONLY else not has_number
+
+
+## Fog of War: số chỉ hiện ở ô trong tầm nhìn quanh nhân vật (S/F luôn hiện)
+func get_cell_text(pos: Vector2i, maze: MazeData) -> String:
+	if maze == null or not is_fog_rule():
+		return super.get_cell_text(pos, maze)
+	if pos == maze.get_start():
+		return "S"
+	if pos == maze.get_end():
+		return "F"
+	var d := (pos - _fog_pos).abs()
+	if d.x <= FOG_RADIUS and d.y <= FOG_RADIUS:
+		var count := maze.get_wall_count(pos)
+		return "" if count == 0 else str(count)
+	return ""
+
+
+func on_grid_setup(grid_view: Control, maze: MazeData) -> void:
+	if is_fog_rule() and maze != null:
+		prepare_rule(maze)
+		_fog_apply(grid_view)
+
+
+func on_player_moved(grid_view: Control, new_pos: Vector2i, maze: MazeData) -> void:
+	if is_fog_rule() and maze != null:
+		_fog_pos = new_pos
+		_fog_reveal(new_pos, maze)
+		_fog_apply(grid_view)
+
+
+## Hồi sinh / về lại ô: mở sương quanh vị trí mới
+func on_respawned(grid_view: Control, pos: Vector2i, maze: MazeData) -> void:
+	on_player_moved(grid_view, pos, maze)
+
+
+func _fog_reveal(center: Vector2i, maze: MazeData) -> void:
+	for dy in range(-FOG_RADIUS, FOG_RADIUS + 1):
+		for dx in range(-FOG_RADIUS, FOG_RADIUS + 1):
+			var p := center + Vector2i(dx, dy)
+			if maze.is_in_bounds(p):
+				_fog_explored[p] = true
+
+
+func _fog_apply(grid_view: Control) -> void:
+	if grid_view != null and grid_view.has_method("apply_fog_of_war"):
+		grid_view.apply_fog_of_war(_fog_pos, FOG_RADIUS, _fog_explored)
 
 
@@ -251,4 +325,6 @@
 			value = str(backtracks_left)
 			low = backtracks_left <= 1
+		FOG_OF_WAR:
+			value = str(FOG_RADIUS)
 	var sub := tr(sub_key())
 	# 2 luật "đếm số" hiện kèm hạn mức: "12  /20 BƯỚC" · "2  /3 LƯỢT"
```

### `scripts/modes/daily_challenge_game_mode.gd`
```diff
--- a/scripts/modes/daily_challenge_game_mode.gd
+++ b/scripts/modes/daily_challenge_game_mode.gd
@@ -42,4 +42,5 @@
 	if challenge_id == MOVE_LIMIT:
 		challenge_param = maxi(challenge_param, _shortest_moves(maze) + 3)
+	prepare_rule(maze)      # Fog of War: ẩn tường + mở sương quanh S
 	return maze
 
```

### `scripts/modes/wall_builder_game_mode.gd`
```diff
--- a/scripts/modes/wall_builder_game_mode.gd
+++ b/scripts/modes/wall_builder_game_mode.gd
@@ -16,5 +16,5 @@
 ## - Hồi sinh (xem quảng cáo): **+1 LƯỢT GỬI** (dùng chung cơ chế LƯỢT THỬ §13.16).
 ## - GỢI Ý: mở + **KHOÁ** 1 đoạn tường THẬT (luôn là một nghiệm hợp lệ, không xoá được).
-## - UNDO: xoá đoạn tường vừa nối (bỏ qua các đoạn đã bị khoá).
+## - Muốn gỡ đoạn đã nối: kéo nối lại đúng khe đó (đoạn do GỢI Ý khoá thì không gỡ được).
 ## ============================================================================
 
@@ -428,24 +428,6 @@
 
 # ---------------------------------------------------------------------------
-# Undo / Hint riêng của chế độ
-# ---------------------------------------------------------------------------
-## Xoá đoạn tường vừa nối (bỏ qua đoạn đã bị Gợi ý khoá)
-func undo_drawn_wall(anchor_controller: AnchorController) -> bool:
-	if anchor_controller == null:
-		return false
-	var index := -1
-	for i in range(_draw_order.size() - 1, -1, -1):
-		if not locked.has(_draw_order[i]):
-			index = i
-			break
-	if index < 0:
-		return false
-	var key: String = _draw_order[index]
-	_draw_order.remove_at(index)
-	built.erase(key)
-	_apply_to_anchor(anchor_controller, key, false)
-	return true
-
-
+# Hint riêng của chế độ
+# ---------------------------------------------------------------------------
 ## Gợi ý: mở + KHOÁ 1 đoạn tường THẬT chưa dựng (đoạn này không xoá được nữa)
 func hint_wall(anchor_controller: AnchorController, maze: MazeData) -> bool:
```

### `scripts/ui/game/board.gd`
```diff
--- a/scripts/ui/game/board.gd
+++ b/scripts/ui/game/board.gd
@@ -14,4 +14,8 @@
 ## Người chơi bấm nút retry trên overlay "Hết nước đi" (game_controller lắng nghe để restart)
 signal no_moves_retry_pressed
+## Người chơi chạm 1 ô đang được tô sáng khi chọn Teleport (GameController lắng nghe)
+signal teleport_chosen(pos: Vector2i)
+## Người chơi chạm ra ngoài các ô sáng khi đang chọn Teleport -> huỷ chọn
+signal teleport_cancelled
 
 const CRASH_SFX_SCENE := preload("res://scenes/objects/vfx/crash.tscn")
@@ -96,4 +100,6 @@
 var _dragging_player := false
 var _player_current_cell := Vector2i.ZERO
+## Các ô đang sáng làm đích Teleport (rỗng = không ở bước chọn)
+var _teleport_targets: Array[Vector2i] = []
 var _drag_draw_sfx_on := false    # Đã phát tiếng miết bút trong lượt kéo này chưa
 
@@ -278,4 +284,5 @@
 	_height = maze.height
 	_interaction_enabled = true
+	_teleport_targets.clear()
 	_dragging_player = false
 	_pressed_cell = Vector2i(-1, -1)
@@ -636,5 +643,14 @@
 			c.set_text(text)
 			_sync_bomb_marker(c, pos)
+			_sync_lock_key(c, pos)
 			c.set_focused(false)
+
+## Đồng bộ biểu tượng KHOÁ / CHÌA KHOÁ của ô theo trạng thái trong MazeData.
+func _sync_lock_key(cell_node: MazeCell, pos: Vector2i) -> void:
+	if cell_node == null or maze == null:
+		return
+	cell_node.set_locked(maze.is_locked(pos))
+	cell_node.set_key(maze.key_id_at(pos) > 0)
+
 
 ## Đồng bộ biểu tượng Bomb cho ô (mode nào có mìn đã nổ — xem MinesweeperPathGameMode).
@@ -980,4 +996,68 @@
 	_play_grid_shake()
 
+## Đi vào ô KHOÁ bị chặn: ô rung + con trỏ giật lùi nhẹ + tiếng gõ khoá.
+func show_lock_bump(pos: Vector2i) -> void:
+	var node := _cell_node(pos)
+	if node != null:
+		node.play_fail()
+	_snap_pen_for_impact()
+	if _cursor != null:
+		var recoil := (Vector2(_player_current_cell) - Vector2(pos)).normalized()
+		_cursor.play_bonk_recoil(recoil)
+	Sfx.play(Sfx.LOCK_BUMP)
+
+
+## Nhặt được chìa: biểu tượng chìa biến mất, các ô vừa mở khoá bung ra.
+func on_key_collected(pos: Vector2i, unlocked: Array) -> void:
+	var key_node := _cell_node(pos)
+	if key_node != null:
+		key_node.set_key(false)
+		key_node.pulse()
+	for u in unlocked:
+		var n := _cell_node(u as Vector2i)
+		if n != null:
+			n.play_unlock()
+	Sfx.play(Sfx.KEY_PICKUP)
+	spawn_floating_popup(tr("STR_KEY_PICKED"), pos, Color(0.78, 0.52, 0.04, 1.0))
+
+
+# ----------------------------------------------------------------------------
+# TELEPORT
+# ----------------------------------------------------------------------------
+## Tô sáng các ô đích; từ giờ lần chạm kế tiếp chọn đích (hoặc huỷ), KHÔNG vẽ nét.
+func show_teleport_targets(cells: Array[Vector2i]) -> void:
+	clear_teleport_targets()
+	_teleport_targets = cells.duplicate()
+	for p in _teleport_targets:
+		var n := _cell_node(p)
+		if n != null:
+			n.set_teleport_target(true)
+
+
+func clear_teleport_targets() -> void:
+	for p in _teleport_targets:
+		var n := _cell_node(p)
+		if n != null:
+			n.set_teleport_target(false)
+	_teleport_targets.clear()
+
+
+func is_selecting_teleport() -> bool:
+	return not _teleport_targets.is_empty()
+
+
+## Con trỏ NHẢY thẳng tới ô `pos` (bỏ qua tường): đặt lại đầu bút, hiệu ứng rơi xuống.
+func teleport_cursor_to(pos: Vector2i) -> void:
+	if _cursor == null or maze == null:
+		return
+	_player_current_cell = pos
+	var target_pos := cursor_pos_at(_cell_center(pos))
+	_cursor.position = target_pos
+	_snap_tip_to_center()
+	if DisplayServer.get_name() != "headless":
+		_cursor.play_spawn_drop(target_pos)
+	pulse_cell(pos)
+
+
 func pulse_cell(pos: Vector2i) -> void:
 	var node := _cell_node(pos)
@@ -1020,4 +1100,13 @@
 	BoardCellsView.refresh_texts(_width, _height, _cell_node, maze, game_mode,
 			dim_unwalkable, _sync_bomb_marker)
+	_resync_lock_keys()
+
+func _resync_lock_keys() -> void:
+	if maze == null:
+		return
+	for y in _height:
+		for x in _width:
+			_sync_lock_key(_cell_node(Vector2i(x, y)), Vector2i(x, y))
+
 
 func apply_fog_of_war(_center: Vector2i, _radius: int, explored: Dictionary) -> void:
@@ -1258,4 +1347,13 @@
 	_pressed_cell = Vector2i(-1, -1)
 	_drag_draw_sfx_on = false
+
+	# Đang chọn đích Teleport: lần chạm này chỉ để CHỌN ô sáng hoặc huỷ — không bắt đầu kéo nét
+	if not _teleport_targets.is_empty():
+		var tc := _hit_cell(local_pos)
+		if tc != Vector2i(-1, -1) and _teleport_targets.has(tc):
+			teleport_chosen.emit(tc)
+		else:
+			teleport_cancelled.emit()
+		return
 
 	var anchor_info := _hit_anchor_info(local_pos)
```

### `scripts/ui/game/cell.gd`
```diff
--- a/scripts/ui/game/cell.gd
+++ b/scripts/ui/game/cell.gd
@@ -43,4 +43,10 @@
 @export var visited_label: Label = null
 @export var satisfied: TextureRect = null
+## Ô KHOÁ: biểu tượng ổ khoá phủ giữa ô (cần nhặt chìa khoá ở ô khác trên mê cung để mở)
+@export var lock: TextureRect = null
+## Ô CHỨA CHÌA KHOÁ: biểu tượng chìa nhỏ ở góc ô
+@export var key_icon: TextureRect = null
+## Ô đang là ĐÍCH DỊCH CHUYỂN hợp lệ (Teleport): viền/nền tím nhấp nháy
+@export var teleport_glow: TextureRect = null
 ## AnimationPlayer của chính `cell.tscn` — mọi hiệu ứng nảy/rung/nháy (entrance · pulse · step ·
 ## win · shudder · fail · pop_text) khai trong scene; code chỉ set pose ban đầu + gọi play.
@@ -59,5 +65,15 @@
 
 
+var _locked := false
+
+
 func set_text(text: String) -> void:
+	_set_text_raw(text)
+	# Ô khoá luôn ẩn số (nhãn chỉ hiện lại khi mở khoá)
+	if _locked and label != null:
+		label.visible = false
+
+
+func _set_text_raw(text: String) -> void:
 	if text == "S":
 		if button != null:
@@ -217,4 +233,50 @@
 
 ## Hiện/ẩn biểu tượng Bomb đã nổ (Minesweeper) — icon to giữa ô, số trên ô vẽ ĐÈ LÊN icon.
+## Bật/tắt trạng thái KHOÁ: hiện ổ khoá, ẩn số, làm tối nền ô.
+func set_locked(on: bool) -> void:
+	_locked = on
+	if lock != null:
+		lock.visible = on
+	if label != null:
+		label.visible = (not on) and not label.text.is_empty()
+	if button != null:
+		button.self_modulate = Color(0.62, 0.64, 0.72, 1.0) if on else Color.WHITE
+
+
+func is_locked_visual() -> bool:
+	return _locked
+
+
+## Hiện/ẩn biểu tượng CHÌA KHOÁ trên ô.
+func set_key(on: bool) -> void:
+	if key_icon != null:
+		key_icon.visible = on
+
+
+func has_key_icon() -> bool:
+	return key_icon != null and key_icon.visible
+
+
+## Tô sáng ô như một ĐÍCH DỊCH CHUYỂN (nhấp nháy tím) — tắt khi huỷ/đã chọn xong.
+func set_teleport_target(on: bool) -> void:
+	if teleport_glow == null:
+		return
+	teleport_glow.visible = on
+	if anim != null and anim.has_animation(&"teleport_glow"):
+		if on:
+			anim.play(&"teleport_glow")
+		elif anim.current_animation == &"teleport_glow":
+			anim.play(&"RESET")
+	else:
+		teleport_glow.modulate = Color.WHITE
+
+
+## Ô KHOÁ vừa bị mở: ổ khoá bung ra + nảy số.
+func play_unlock() -> void:
+	set_locked(false)
+	pulse()
+	play_pop_text()
+
+
 func set_bomb(active: bool) -> void:
 	if bomb != null:
```

### `scripts/ui/game/hint_guide.gd`
```diff
--- a/scripts/ui/game/hint_guide.gd
+++ b/scripts/ui/game/hint_guide.gd
@@ -12,11 +12,5 @@
 	"play": "STR_HINT_PLAY",
 	"dungeon": "STR_HINT_DUNGEON",
-	"minesweeper": "STR_HINT_MINESWEEPER",
 	"blind_memory": "STR_HINT_BLIND_MEMORY",
-	"fog_of_war": "STR_HINT_FOG_OF_WAR",
-	"sum_path": "STR_HINT_SUM_PATH",
-	"countdown_cost": "STR_HINT_COUNTDOWN_COST",
-	"fading_ink": "STR_HINT_FADING_INK",
-	"one_stroke": "STR_HINT_ONE_STROKE",
 	"wall_builder": "STR_HINT_WALL_BUILDER",
 	"challenge": "STR_HINT_CHALLENGE",
```

### `scripts/ui/hud/base_hud.gd`
```diff
--- a/scripts/ui/hud/base_hud.gd
+++ b/scripts/ui/hud/base_hud.gd
@@ -7,5 +7,5 @@
 ##   · Đồng hồ ván             : `update_hud(ctx)` · `set_time()`
 ##   · Thanh nút hành động     : `action_bar()` · `restart_btn()` · `submit_btn()` · `skip_btn()`
-##                               · `undo_btn()` · `hint_btn()`
+##                               · `teleport_btn()` · `hint_btn()`
 ##   · Thẻ NHIỆM VỤ           : `mission_card()` (HUD không xài thì trả null)
 ##   · Khung Hướng dẫn         : `hint_guide()`
@@ -32,5 +32,5 @@
 ##   title:String · subtitle:String · steps_remaining:int · elapsed_time:float
 ##   floor_number:int · extra:String · mode:BaseGameMode
-##   skip_left · undo_left · hint_left :int — số dư công cụ toàn tài khoản
+##   skip_left · teleport_left · hint_left :int — số dư công cụ toàn tài khoản
 func update_hud(ctx: Dictionary) -> void:
 	set_time(float(ctx.get("elapsed_time", 0.0)))
@@ -72,5 +72,5 @@
 ## ---------------------------------------------------------------------------
 ## THANH NÚT HÀNH ĐỘNG (phương án A): mỗi HUD đều instance `nodes/hud/action_bar.tscn`
-## ngay trong scene của mình ⇒ nút CHƠI LẠI/GỬI BÀI/UNDO/HINT/REPLAY nằm TRONG HUD,
+## ngay trong scene của mình ⇒ nút CHƠI LẠI/GỬI BÀI/TELEPORT/HINT/REPLAY nằm TRONG HUD,
 ## màn chơi chỉ việc lấy ra để nối tín hiệu (không còn nút nào trong game.tscn).
 ## ---------------------------------------------------------------------------
@@ -85,5 +85,5 @@
 		bar.update_tool_counts(
 			int(ctx.get("skip_left", 0)),
-			int(ctx.get("undo_left", 0)),
+			int(ctx.get("teleport_left", 0)),
 			int(ctx.get("hint_left", 0)))
 
@@ -113,7 +113,7 @@
 
 
-func undo_btn() -> BaseButton:
+func teleport_btn() -> BaseButton:
 	var bar := action_bar()
-	return bar.undo_btn() if bar != null else null
+	return bar.teleport_btn() if bar != null else null
 
 
```

### `scripts/ui/hud/game/action_bar.gd`
```diff
--- a/scripts/ui/hud/game/action_bar.gd
+++ b/scripts/ui/hud/game/action_bar.gd
@@ -11,5 +11,5 @@
 ##   · `Restart` — CHƠI LẠI màn/tầng (DỜI từ thanh trạng thái xuống đây — có ở MỌI chế độ)
 ##   · `Submit`  — GỬI BÀI (chỉ Wall Builder; GameScene tự bật/tắt theo chế độ)
-##   · `Skip` / `Undo` / `Hint` — kèm `PanelLimit` hiện SỐ LƯỢT CÒN LẠI
+##   · `Skip` / `Teleport` / `Hint` — kèm `PanelLimit` hiện SỐ LƯỢT CÒN LẠI
 ##   · `Replay` — nút phụ ẩn sẵn, UIController hiện khi ván không còn thắng được (Sum Path)
 ##
@@ -48,6 +48,6 @@
 	return button("Skip") as LimitedButton
 
-func undo_btn() -> LimitedButton:
-	return button("Undo") as LimitedButton
+func teleport_btn() -> LimitedButton:
+	return button("Teleport") as LimitedButton
 
 
@@ -60,11 +60,11 @@
 
 ## Cập nhật số dư toàn tài khoản + trạng thái khoá của các nút có giới hạn.
-func update_tool_counts(skip_left: int, undo_left: int, hint_left: int) -> void:
+func update_tool_counts(skip_left: int, teleport_left: int, hint_left: int) -> void:
 	var skip := skip_btn()
 	if skip != null:
 		skip.set_remaining(skip_left)
-	var undo := undo_btn()
-	if undo != null:
-		undo.set_remaining(undo_left)
+	var teleport := teleport_btn()
+	if teleport != null:
+		teleport.set_remaining(teleport_left)
 	var hint := hint_btn()
 	if hint != null:
```

### `scripts/ui/hud/game/limited_button.gd`
```diff
--- a/scripts/ui/hud/game/limited_button.gd
+++ b/scripts/ui/hud/game/limited_button.gd
@@ -9,5 +9,5 @@
 ## ============================================================================
 
-## Node binding: khai `node_paths` + NodePath cho TỪNG nút (Skip/Undo/Hint) trong
+## Node binding: khai `node_paths` + NodePath cho TỪNG nút (Skip/Teleport/Hint) trong
 ## `nodes/hud/portrait/game/action_bar.tscn` + `nodes/hud/landscape/game/action_bar.tscn`
 @export var panel_limit: Control = null
```

### `scripts/ui/layouts/tutorial_list_layout.gd`
```diff
--- a/scripts/ui/layouts/tutorial_list_layout.gd
+++ b/scripts/ui/layouts/tutorial_list_layout.gd
@@ -6,5 +6,5 @@
 ## (`scenes/tutorial_list.tscn` — Portrait & Landscape).
 ##
-## Chỉ chứa TopBar (Back + tiêu đề) + danh sách 12 nút bài học. Bài học thật KHÔNG
+## Chỉ chứa TopBar (Back + tiêu đề) + danh sách 6 nút bài học. Bài học thật KHÔNG
 ## mount ở đây: bấm 1 nút ⇒ mở màn CHI TIẾT `scenes/tutorial.tscn` với yêu cầu
 ## `GameManager.request_tutorial(id, true)`.
@@ -20,11 +20,5 @@
 @export var btn_move: BaseButton = null
 @export var btn_checking_wall: BaseButton = null
-@export var btn_minesweeper: BaseButton = null
-@export var btn_one_stroke: BaseButton = null
-@export var btn_sum_path: BaseButton = null
 @export var btn_wall_builder: BaseButton = null
-@export var btn_countdown_cost: BaseButton = null
-@export var btn_fading_ink: BaseButton = null
-@export var btn_fog_of_war: BaseButton = null
 @export var btn_blind_memory: BaseButton = null
 @export var btn_use_tool: BaseButton = null
```

### `scripts/ui/popups/daily_milestone.gd`
```diff
--- a/scripts/ui/popups/daily_milestone.gd
+++ b/scripts/ui/popups/daily_milestone.gd
@@ -7,5 +7,5 @@
 ## Mở bằng `Popups.open(Popups.DAILY_MILESTONE, { "stars": <ngưỡng>, "reward": <def> })`
 ## trong đó `reward` là Dictionary của `DailyManager.MILESTONES`
-## (`{stars, coins, hint, undo, skip}`) — script chỉ HIỂN THỊ, không tự cộng gì.
+## (`{stars, coins, hint, teleport, skip}`) — script chỉ HIỂN THỊ, không tự cộng gì.
 ##
 ## RƯƠNG QUÀ: dùng `AnimatedSprite2D` + `SpriteFrames` sinh từ
```

### `scripts/ui/screens/debug.gd`
```diff
--- a/scripts/ui/screens/debug.gd
+++ b/scripts/ui/screens/debug.gd
@@ -138,5 +138,5 @@
 	for tool_data in [
 		[GameManagerClass.TOOL_SKIP, "Skip"],
-		[GameManagerClass.TOOL_UNDO, "Eraser / Undo"],
+		[GameManagerClass.TOOL_TELEPORT, "Teleport"],
 		[GameManagerClass.TOOL_HINT, "Hint"],
 	]:
@@ -370,9 +370,9 @@
 
 # ---------------------------------------------------------------------------
-# SPECIAL MODES: vào thẳng 7 chế độ chỉ chơi được qua Daily để test
+# SPECIAL MODES: vào thẳng các chế độ Special còn lại (Blind Memory · Wall Builder) để test
 # ---------------------------------------------------------------------------
 func _build_special_modes() -> void:
 	_add_section("SPECIAL MODES (TEST)")
-	_add_label("7 luật chỉ mở qua Daily — ở đây vào thẳng để thử, kèm chọn độ khó / tầng bắt đầu:",
+	_add_label("Các chế độ Special còn lại — ở đây vào thẳng để thử, kèm chọn độ khó / tầng bắt đầu:",
 		&"PopupSubtitle")
 
@@ -386,5 +386,5 @@
 			"Cho các mode có tham số độ khó", _set_difficulty.bind(diff))
 
-	_add_label("Tầng bắt đầu (tầng càng cao bàn càng to ở minesweeper / fading ink...):", &"PopupSubtitle")
+	_add_label("Tầng bắt đầu:", &"PopupSubtitle")
 	for floor_number in TEST_FLOORS:
 		_add_action(_choice_text("Tầng", str(floor_number), floor_number == _floor),
@@ -405,6 +405,6 @@
 	controller.free()
 
-	_add_action("Chế độ kế tiếp", "Xoay vòng qua 7 chế độ Special", _start_next_special_mode)
-	_add_action("Chế độ ngẫu nhiên", "Random 1 trong 7 chế độ Special", _start_random_special_mode)
+	_add_action("Chế độ kế tiếp", "Xoay vòng qua các chế độ Special", _start_next_special_mode)
+	_add_action("Chế độ ngẫu nhiên", "Random 1 trong các chế độ Special", _start_random_special_mode)
 
 # ---------------------------------------------------------------------------
@@ -416,7 +416,4 @@
 	"how_to_play_move": "Bàn 1×3 — giữ & kéo đường S → F",
 	"how_to_play_checking_wall": "Bàn 2×2 — đoán tường vô hình từ con số",
-	"how_to_play_minesweeper": "Bàn 3×3 — né mìn theo số quanh ô",
-	"how_to_play_one_stroke": "Bàn 3×3 — đi hết mọi ô đúng 1 lần",
-	"how_to_play_sum_path": "Bàn 3×3 — tổng điểm khớp mục tiêu",
 	"how_to_play_wall_builder": "Bàn 2×2 — tự vẽ tường rồi GỬI BÀI",
 	"congrats_first_time": "Chúc mừng xong chuỗi mở đầu (về Main hoặc bàn kế)",
@@ -671,8 +668,4 @@
 	if gm != null and gm.has_method("special_mode_ids"):
 		ids.assign(gm.call("special_mode_ids"))
-	# One Stroke MỚI (2026-09-19): chưa gắn vào vòng xoay DAILY_MODES (chờ quyết định §6) nhưng
-	# vẫn cho vào thẳng từ Debug Console để chơi thử / kiểm thử trên máy thật.
-	if not ids.has("one_stroke"):
-		ids.append("one_stroke")
 	if not ids.has("wall_builder"):
 		ids.append("wall_builder")
```

### `scripts/ui/screens/game.gd`
```diff
--- a/scripts/ui/screens/game.gd
+++ b/scripts/ui/screens/game.gd
@@ -23,5 +23,5 @@
 ## Nút SKIP LEVEL — chỉ hiện khi ván này là ván chơi MÀN trong màn Chọn màn (`_apply_mode_buttons`)
 var skip_btn: BaseButton = null
-var undo_btn: BaseButton = null
+var teleport_btn: BaseButton = null
 var hint_btn: BaseButton = null
 ### Nút CHƠI LẠI ẩn sẵn DƯỚI thanh nút — UIController hiện khi ván không còn thắng được nữa (Sum Path)
@@ -48,13 +48,5 @@
 const HUD_LEVEL := preload("res://scenes/objects/ui/hud/game/level_mode/portrait.tscn")
 const HUD_DUNGEON := preload("res://scenes/objects/ui/hud/game/dungeon_mode/portrait.tscn")
-const HUD_MINESWEEP := preload("res://nodes/hud/portrait/game/minesweep_hud.tscn")
-const HUD_SUM_PATH := preload("res://nodes/hud/portrait/game/sum_path_hud.tscn")
 const HUD_BLIND_MEMORY := preload("res://scenes/objects/ui/hud/game/blind_memory_hud/portrait.tscn")
-const HUD_COUNTDOWN := preload("res://nodes/hud/portrait/game/countdown_hud.tscn")
-const HUD_FADING_INK := preload("res://nodes/hud/portrait/game/fading_ink_hud.tscn")
-## Fog of War: THỜI GIAN + BẢNG SƯƠNG MÙ (lượt thử lại · tầm nhìn · cảnh báo) — không có thẻ Nhiệm vụ
-const HUD_FOG_OF_WAR := preload("res://nodes/hud/portrait/game/fog_of_war_hud.tscn")
-## One Stroke: THỜI GIAN + BẢNG TIẾN ĐỘ PHỦ KÍN (số ô đã đi · thanh tiến độ) — không có thẻ Nhiệm vụ
-const HUD_ONE_STROKE := preload("res://nodes/hud/portrait/game/one_stroke_hud.tscn")
 ## Wall Builder: THỜI GIAN + BẢNG TƯỜNG ĐÃ VẼ (đoạn đã dựng · lượt gửi) — không có thẻ Nhiệm vụ
 const HUD_WALL_BUILDER := preload("res://scenes/objects/ui/hud/game/wall_builder_hud/portrait.tscn")
@@ -64,11 +56,5 @@
 const HUD_LAND_LEVEL := preload("res://scenes/objects/ui/hud/game/level_mode/landscape.tscn")
 const HUD_LAND_DUNGEON := preload("res://scenes/objects/ui/hud/game/dungeon_mode/landscape.tscn")
-const HUD_LAND_MINESWEEP := preload("res://nodes/hud/landscape/game/minesweep_hud.tscn")
-const HUD_LAND_SUM_PATH := preload("res://nodes/hud/landscape/game/sum_path_hud.tscn")
 const HUD_LAND_BLIND_MEMORY := preload("res://scenes/objects/ui/hud/game/blind_memory_hud/landscape.tscn")
-const HUD_LAND_COUNTDOWN := preload("res://nodes/hud/landscape/game/countdown_hud.tscn")
-const HUD_LAND_FADING_INK := preload("res://nodes/hud/landscape/game/fading_ink_hud.tscn")
-const HUD_LAND_FOG_OF_WAR := preload("res://nodes/hud/landscape/game/fog_of_war_hud.tscn")
-const HUD_LAND_ONE_STROKE := preload("res://nodes/hud/landscape/game/one_stroke_hud.tscn")
 const HUD_LAND_WALL_BUILDER := preload("res://scenes/objects/ui/hud/game/wall_builder_hud/landscape.tscn")
 const HUD_LAND_CHALLENGE := preload("res://scenes/objects/ui/hud/game/challenge_hud/landscape.tscn")
@@ -143,4 +129,6 @@
 	# Bàn cờ → GameController (overlay retry)
 	_connect_once(board_view, "no_moves_retry_pressed", game_controller, "_on_no_moves_retry_pressed")
+	_connect_once(board_view, "teleport_chosen", game_controller, "_on_teleport_chosen")
+	_connect_once(board_view, "teleport_cancelled", game_controller, "_on_teleport_cancelled")
 	# GridController → GameController (đếm bước · đâm tường · tới đích · hết đường)
 	_connect_once(grid_controller, "step_consumed", game_controller, "_on_step_consumed")
@@ -182,5 +170,5 @@
 		layout.pause_btn if layout != null else null,
 		layout.instruction_btn if layout != null else null,
-		restart_btn, submit_btn, skip_btn, undo_btn, hint_btn,
+		restart_btn, submit_btn, skip_btn, teleport_btn, hint_btn,
 	]
 
@@ -269,5 +257,5 @@
 	if layout != null and layout.hud_slot != null:
 		UIAnim.play_slide_in(layout.hud_slot, Vector2(0, -15), 0.04, 0.25)
-	var button_bar := undo_btn.get_parent() as Control if undo_btn != null else null
+	var button_bar := teleport_btn.get_parent() as Control if teleport_btn != null else null
 	if button_bar != null:
 		UIAnim.play_slide_in(button_bar, Vector2(0, 30), 0.08, 0.25)
@@ -325,9 +313,4 @@
 
 
-func _on_undo_pressed() -> void:
-	if game_controller != null:
-		game_controller.undo()
-
-
 func _on_hint_pressed() -> void:
 	if game_controller != null:
@@ -347,4 +330,8 @@
 	if skip_btn != null:
 		skip_btn.visible = _is_level_run()
+	# Wall Builder dựng tường chứ không đi con trỏ -> không có Teleport
+	if teleport_btn != null:
+		teleport_btn.visible = mode_name.to_lower() != "wall_builder"
+
 	# Dungeon: ẩn nút "?" (không có tutorial cho dungeon).
 	# LUỒNG HỌC LẦN ĐẦU: các màn M1..M4 tự mở đúng bài học theo trình tự — ẩn nút "?"
@@ -433,18 +420,6 @@
 		"daily_challenge":
 			return _hud_variant(HUD_CHALLENGE, HUD_LAND_CHALLENGE)
-		"minesweeper":
-			return _hud_variant(HUD_MINESWEEP, HUD_LAND_MINESWEEP)
-		"sum_path":
-			return _hud_variant(HUD_SUM_PATH, HUD_LAND_SUM_PATH)
 		"blind_memory":
 			return _hud_variant(HUD_BLIND_MEMORY, HUD_LAND_BLIND_MEMORY)
-		"countdown_cost":
-			return _hud_variant(HUD_COUNTDOWN, HUD_LAND_COUNTDOWN)
-		"fading_ink":
-			return _hud_variant(HUD_FADING_INK, HUD_LAND_FADING_INK)
-		"fog_of_war":
-			return _hud_variant(HUD_FOG_OF_WAR, HUD_LAND_FOG_OF_WAR)
-		"one_stroke":
-			return _hud_variant(HUD_ONE_STROKE, HUD_LAND_ONE_STROKE)
 		"wall_builder":
 			return _hud_variant(HUD_WALL_BUILDER, HUD_LAND_WALL_BUILDER)
@@ -463,18 +438,6 @@
 		"daily_challenge":
 			return ChallengeHUD
-		"minesweeper":
-			return MinesweepHUD
-		"sum_path":
-			return SumPathHUD
 		"blind_memory":
 			return BlindMemoryHUD
-		"countdown_cost":
-			return CountdownHUD
-		"fading_ink":
-			return FadingInkHUD
-		"fog_of_war":
-			return FogOfWarHUD
-		"one_stroke":
-			return OneStrokeHUD
 		"wall_builder":
 			return WallBuilderHUD
@@ -525,5 +488,5 @@
 	# ⚠️ KHÔNG xoá khung gốc (`layout.hud_slot`): mỗi lần xoay màn hình `_bind_refs()` cần nó làm
 	# mốc để đặt HUD mới. Xoá nó ⇒ `layout.hud_slot` thành node đã free ⇒ xoay/resize
-	# tiếp theo là lỗi "Trying to cast a freed object" (tái hiện: xoay dọc→ngang ở mode Minesweeper).
+	# tiếp theo là lỗi "Trying to cast a freed object" (tái hiện: xoay dọc→ngang ở mode Blind Memory).
 	if hud_host != null and is_instance_valid(hud_host) and hud_host != slot:
 		hud_host.queue_free()
@@ -585,5 +548,5 @@
 	submit_btn = hud.submit_btn()
 	skip_btn = hud.skip_btn()
-	undo_btn = hud.undo_btn()
+	teleport_btn = hud.teleport_btn()
 	hint_btn = hud.hint_btn()
 	#replay_btn = hud.replay_btn()
@@ -616,6 +579,6 @@
 		if submit_btn != null and not submit_btn.pressed.is_connected(game_controller.submit_build):
 			submit_btn.pressed.connect(game_controller.submit_build)
-		if undo_btn != null and not undo_btn.pressed.is_connected(game_controller.undo):
-			undo_btn.pressed.connect(game_controller.undo)
+		if teleport_btn != null and not teleport_btn.pressed.is_connected(game_controller.teleport):
+			teleport_btn.pressed.connect(game_controller.teleport)
 		if hint_btn != null and not hint_btn.pressed.is_connected(game_controller.hint):
 			hint_btn.pressed.connect(game_controller.hint)
@@ -623,4 +586,4 @@
 			#replay_btn.pressed.connect(game_controller.restart_run)
 	if ui_controller != null:
-		ui_controller.undo_button = undo_btn
+		ui_controller.teleport_button = teleport_btn
 		#ui_controller.replay_button = replay_btn
```

### `scripts/ui/screens/profiler.gd`
```diff
--- a/scripts/ui/screens/profiler.gd
+++ b/scripts/ui/screens/profiler.gd
@@ -47,5 +47,5 @@
 	"pencil": preload("res://assets/images-png/profiler/ic_pencil.png"),
 	"revert": preload("res://assets/images-png/profiler/ic_revert.png"),
-	"undo": preload("res://assets/images-png/profiler/ic_undo.png"),
+	"teleport": preload("res://assets/images-png/profiler/ic_undo.png"),   # TODO art: thay ic_undo bằng icon dịch chuyển
 	"skip": preload("res://assets/images-png/profiler/ic_skip.png"),
 }
@@ -245,5 +245,5 @@
 		_card("pencil", "STR_PROFILE_STAT_WALL_DRAW", str(int(data.get("wall_draws", 0)))),
 		_card("revert", "STR_PROFILE_STAT_REVERT_USED", str(int(data.get("wall_erases", 0)))),
-		_card("undo", "STR_PROFILE_STAT_UNDO_USED", str(int(data.get("undos_total", 0)))),
+		_card("teleport", "STR_PROFILE_STAT_TELEPORT_USED", str(int(data.get("teleports_total", 0)))),
 		_card("skip", "STR_PROFILE_STAT_SKIP_USED", str(int(data.get("skips_total", 0)))),
 	])
```

### `scripts/ui/screens/tutorial_list.gd`
```diff
--- a/scripts/ui/screens/tutorial_list.gd
+++ b/scripts/ui/screens/tutorial_list.gd
@@ -72,11 +72,5 @@
 		"how_to_play_move": layout.btn_move,
 		"how_to_play_checking_wall": layout.btn_checking_wall,
-		"how_to_play_minesweeper": layout.btn_minesweeper,
-		"how_to_play_one_stroke": layout.btn_one_stroke,
-		"how_to_play_sum_path": layout.btn_sum_path,
 		"how_to_play_wall_builder": layout.btn_wall_builder,
-		"how_to_play_countdown_cost": layout.btn_countdown_cost,
-		"how_to_play_fading_ink": layout.btn_fading_ink,
-		"how_to_play_fog_of_war": layout.btn_fog_of_war,
 		"how_to_play_blind_memory": layout.btn_blind_memory,
 		"how_to_use_tool": layout.btn_use_tool,
```

### `scripts/ui/tutorial/how_to_use_tool.gd`
```diff
--- a/scripts/ui/tutorial/how_to_use_tool.gd
+++ b/scripts/ui/tutorial/how_to_use_tool.gd
@@ -4,6 +4,6 @@
 ## ============================================================================
 ## HowToUseToolTutorial: Dạy dùng 2 nút CÔNG CỤ (thanh hành động) —
-## QUAY LẠI (undo) và GỢI Ý (hint) — mỗi nút 3 lượt mỗi màn.
-## Bàn 3×3 không tường. Bước 1 giới thiệu · bước 2 demo undo · bước 3 demo hint
+## DỊCH CHUYỂN (teleport) và GỢI Ý (hint) — mỗi nút 3 lượt mỗi màn.
+## Bàn 3×3 không tường. Bước 1 giới thiệu · bước 2 demo teleport · bước 3 demo hint
 ## · bước 4 luyện tập (tự đi + tự bấm 2 nút) · bước 5 chúc mừng.
 ## Kế thừa BaseInteractivePathTutorial (SOLID - OCP/SRP).
@@ -11,7 +11,7 @@
 
 @export var lbl_hud_tools: Label = null
-@export var btn_undo: BaseButton = null
+@export var btn_teleport: BaseButton = null
 @export var btn_hint: BaseButton = null
-@export var lbl_undo_count: Label = null
+@export var lbl_teleport_count: Label = null
 @export var lbl_hint_count: Label = null
 
@@ -20,5 +20,5 @@
 @export var TOOL_USES := 3
 
-var _undo_left: int = TOOL_USES
+var _teleport_left: int = TOOL_USES
 var _hint_left: int = TOOL_USES
 var _demo_tween: Tween = null
@@ -52,10 +52,10 @@
 		{
 			"message_key": "STR_TUT_TOOL_01",
-			"fallback_text": "Thanh công cụ có 2 nút: QUAY LẠI và GỢI Ý — mỗi nút dùng được 3 lượt mỗi màn. Cùng xem cách dùng nhé!",
+			"fallback_text": "Thanh công cụ có 2 nút: DỊCH CHUYỂN và GỢI Ý — mỗi nút dùng được 3 lượt mỗi màn. Cùng xem cách dùng nhé!",
 			"advance_mode": "MANUAL",
 		},
 		{
 			"message_key": "STR_TUT_TOOL_02",
-			"fallback_text": "Ví dụ: đi 1 bước rồi nhấn QUAY LẠI — con trỏ tự lùi về ô cũ.",
+			"fallback_text": "Ví dụ: nhấn DỊCH CHUYỂN — các ô trong tầm 2 ô sáng lên, chạm 1 ô để nhảy thẳng tới đó, kể cả có tường chắn.",
 			"advance_mode": "MANUAL",
 		},
@@ -67,5 +67,5 @@
 		{
 			"message_key": "STR_TUT_TOOL_04",
-			"fallback_text": "Giờ tự thử — đi tới F, dùng QUAY LẠI và GỢI Ý khi cần nhé!",
+			"fallback_text": "Giờ tự thử — đi tới F, dùng DỊCH CHUYỂN và GỢI Ý khi cần nhé!",
 			"advance_mode": "AUTO",
 			"required_action": "DRAG_PATH",
@@ -83,5 +83,5 @@
 	match index:
 		1:
-			_start_undo_demo()
+			_start_teleport_demo()
 		2:
 			_start_hint_demo()
@@ -99,10 +99,10 @@
 
 func _update_tools(animated: bool = true) -> void:
-	if lbl_undo_count != null:
-		lbl_undo_count.text = str(_undo_left)
+	if lbl_teleport_count != null:
+		lbl_teleport_count.text = str(_teleport_left)
 	if lbl_hint_count != null:
 		lbl_hint_count.text = str(_hint_left)
-	if btn_undo != null:
-		btn_undo.disabled = _undo_left <= 0
+	if btn_teleport != null:
+		btn_teleport.disabled = _teleport_left <= 0
 	if btn_hint != null:
 		btn_hint.disabled = _hint_left <= 0
@@ -111,6 +111,6 @@
 	var fmt := str(tr("STR_TUT_TOOL_HUD"))
 	if fmt == "STR_TUT_TOOL_HUD":
-		fmt = "Quay lại: {0} lượt · Gợi ý: {1} lượt"
-	lbl_hud_tools.text = fmt.format([_undo_left, _hint_left])
+		fmt = "Dịch chuyển: {0} lượt · Gợi ý: {1} lượt"
+	lbl_hud_tools.text = fmt.format([_teleport_left, _hint_left])
 	if not animated:
 		return
@@ -140,26 +140,59 @@
 
 
-## Bước 2: demo QUAY LẠI — đi 1 bước rồi lùi về, huy hiệu 3 → 2 bằng Tween
-func _start_undo_demo() -> void:
+## Bước 2: demo DỊCH CHUYỂN — nhấn nút, các ô trong tầm 2 sáng lên, con trỏ nhảy tới 1 ô
+func _start_teleport_demo() -> void:
 	if board_tutorial == null:
 		return
-	_run_undo_demo_cycle()
-
-
-func _run_undo_demo_cycle() -> void:
+	_run_teleport_demo_cycle()
+
+
+func _teleport_range_cells(from: Vector2i) -> Array[Vector2i]:
+	var out: Array[Vector2i] = []
+	for dy in range(-2, 3):
+		for dx in range(-2, 3):
+			var d := absi(dx) + absi(dy)
+			if d == 0 or d > 2:
+				continue
+			var p := from + Vector2i(dx, dy)
+			if p.x < 0 or p.y < 0 or p.x > 2 or p.y > 2:
+				continue
+			out.append(p)
+	return out
+
+
+func _set_teleport_glow(cells: Array[Vector2i], on: bool) -> void:
+	if board_tutorial == null:
+		return
+	for p in cells:
+		var c := board_tutorial.get_cell(p)
+		if c != null and c.has_method("set_teleport_target"):
+			c.set_teleport_target(on)
+
+
+func _run_teleport_demo_cycle() -> void:
 	if current_step_index != 1 or not is_inside_tree() or board_tutorial == null:
 		return
 	reset_path()
-	_undo_left = TOOL_USES
+	_teleport_left = TOOL_USES
 	_hint_left = TOOL_USES
 	_update_tools(false)
+	var glow := _teleport_range_cells(START_POS)
+	var target := Vector2i(1, 1)
 
 	_demo_tween = create_tween()
-	# Đi mẫu 1 bước: S → (0,1)
-	_demo_tween.tween_interval(0.45)
+	# Nhấn DỊCH CHUYỂN -> các ô trong tầm sáng lên
+	_demo_tween.tween_interval(0.5)
+	_demo_tween.tween_callback(func() -> void:
+		if current_step_index != 1: return
+		_flash_tool_button(btn_teleport)
+		_set_teleport_glow(glow, true)
+	)
+	# Chọn ô (1,1): con trỏ nhảy tới, huy hiệu 3 -> 2
+	_demo_tween.tween_interval(1.3)
 	_demo_tween.tween_callback(func() -> void:
 		if current_step_index != 1 or board_tutorial == null: return
-		_visited_cells = [START_POS, Vector2i(0, 1)]
-		_current_cell = Vector2i(0, 1)
+		_set_teleport_glow(glow, false)
+		_visited_cells = [target]
+		_current_cell = target
 		board_tutorial.set_path(_visited_cells)
 		board_tutorial.set_player_cell(_current_cell, true)
@@ -167,29 +200,18 @@
 		if c != null:
 			c.play_step()
-	)
-	# Nhấn QUAY LẠI (huy hiệu 3 → 2)
-	_demo_tween.tween_interval(1.25)
+		_teleport_left = TOOL_USES - 1
+		_update_tools(true)
+		spawn_board_text("-1", _button_center(btn_teleport) + Vector2(0, -30), Color(0.78, 0.22, 0.22))
+	)
+	# Về lại ô xuất phát cho vòng lặp sau
+	_demo_tween.tween_interval(1.6)
 	_demo_tween.tween_callback(func() -> void:
 		if current_step_index != 1: return
-		_flash_tool_button(btn_undo)
-		_undo_left = TOOL_USES - 1
+		reset_path()
+		_teleport_left = TOOL_USES
 		_update_tools(true)
-		spawn_board_text("-1", _button_center(btn_undo) + Vector2(0, -30), Color(0.78, 0.22, 0.22))
-	)
-	# Lùi lại ô cũ
+	)
 	_demo_tween.tween_interval(0.7)
-	_demo_tween.tween_callback(func() -> void:
-		if current_step_index != 1 or board_tutorial == null: return
-		reset_path()
-	)
-	# Trả huy hiệu về 3 cho vòng lặp sau
-	_demo_tween.tween_interval(1.6)
-	_demo_tween.tween_callback(func() -> void:
-		if current_step_index != 1: return
-		_undo_left = TOOL_USES
-		_update_tools(true)
-	)
-	_demo_tween.tween_interval(0.7)
-	_demo_tween.tween_callback(_run_undo_demo_cycle)
+	_demo_tween.tween_callback(_run_teleport_demo_cycle)
 
 
@@ -205,5 +227,5 @@
 		return
 	reset_path()
-	_undo_left = TOOL_USES
+	_teleport_left = TOOL_USES
 	_hint_left = TOOL_USES
 	_update_tools(false)
@@ -246,5 +268,5 @@
 func _start_practice() -> void:
 	reset_path()
-	_undo_left = TOOL_USES
+	_teleport_left = TOOL_USES
 	_hint_left = TOOL_USES
 	_update_tools(true)
@@ -263,17 +285,27 @@
 
 
-func _on_undo_pressed() -> void:
-	if current_step_index != 3 or _undo_left <= 0:
-		return
-	if _visited_cells.size() <= 1:
-		show_fail_feedback("STR_TUT_TOOL_FAIL_UNDO", "Chưa có bước nào để quay lại!")
-		return
-	_undo_left -= 1
-	_visited_cells.pop_back()
-	_current_cell = _visited_cells.back()
+## Luyện tập: nhảy tới ô trong tầm 2 gần ô F nhất (tutorial không cần bước chọn ô)
+func _on_teleport_pressed() -> void:
+	if current_step_index != 3 or _teleport_left <= 0:
+		return
+	var best := Vector2i(-1, -1)
+	var best_d := 1 << 20
+	for p in _teleport_range_cells(_current_cell):
+		var d := absi(p.x - FINISH_POS.x) + absi(p.y - FINISH_POS.y)
+		if d < best_d:
+			best_d = d
+			best = p
+	if best == Vector2i(-1, -1):
+		show_fail_feedback("STR_TUT_TOOL_FAIL_TELEPORT", "Không có ô nào để dịch chuyển tới!")
+		return
+	_teleport_left -= 1
+	_visited_cells = [best]
+	_current_cell = best
 	if board_tutorial != null:
 		board_tutorial.set_path(_visited_cells)
 		board_tutorial.set_player_cell(_current_cell, true)
 	_update_tools(true)
+	if best == FINISH_POS:
+		_on_goal_reached(best)
 
 
```

### `scripts/ui/widgets/shop/item_row.gd`
```diff
--- a/scripts/ui/widgets/shop/item_row.gd
+++ b/scripts/ui/widgets/shop/item_row.gd
@@ -21,5 +21,5 @@
 	"paper": preload("res://assets/images-png/icons/icon_paper.png"),
 	"coin": preload("res://assets/images-png/icons/icon_coin.png"),
-	"tool_undo": preload("res://assets/images-png/icons/icon_tool_undo.png"),
+	"tool_teleport": preload("res://assets/images-png/icons/icon_tool_undo.png"),   # TODO art: icon dịch chuyển
 	"tool_hint": preload("res://assets/images-png/icons/icon_tool_hint.png"),
 	"tool_reveal": preload("res://assets/images-png/icons/icon_tool_reveal.png"),
```

### `scripts/utils/sfx.gd`
```diff
--- a/scripts/utils/sfx.gd
+++ b/scripts/utils/sfx.gd
@@ -19,5 +19,7 @@
 const WALL_MARK := "wall_mark"          # Nét chì dứt khoát khi vẽ tường nghi ngờ
 const WALL_HIT := "wall_hit"            # Gãy ngòi chì khi đâm tường vô hình
-const UNDO := "undo"                    # Gôm tẩy quẹt trên giấy
+const TELEPORT := "teleport"            # Dịch chuyển con trỏ
+const KEY_PICKUP := "key_pickup"        # Nhặt chìa khoá (mở ô khoá)
+const LOCK_BUMP := "lock_bump"          # Đâm vào ô còn khoá
 const HINT := "hint"                    # Chuông gió khi bấm Gợi ý
 const STAIRS_ENTER := "stairs_enter"    # Bước chân / lật giấy khi vào ô S - F
@@ -44,5 +46,7 @@
 	"wall_mark": "sfx_wall_mark.wav",
 	"wall_hit": "sfx_wall_hit.wav",
-	"undo": "sfx_undo.mp3",
+	"teleport": "sfx_stairs_enter.wav",    # TODO âm thanh riêng
+	"key_pickup": "sfx_star_pop.wav",      # TODO âm thanh riêng
+	"lock_bump": "sfx_wall_hit.wav",       # TODO âm thanh riêng
 	"hint": "sfx_hint.wav",
 	"stairs_enter": "sfx_stairs_enter.wav",
```
