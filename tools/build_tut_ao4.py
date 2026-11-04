#!/usr/bin/env python3
"""Vá nodes/tutorials/base_tutorial.tscn gốc -> kiểu AO4. Chạy: python3 build_tut_ao4.py SRC_base_tutorial.tscn OUT.tscn"""
import re,sys
s=open(sys.argv[1],encoding='utf-8').read()
T='res://assets/images-png/tutorial/'
def ext(i,f): return f'[ext_resource type="Texture2D" path="{T}{f}.png" id="{i}"]\n'
add=''.join(ext(i,f) for i,f in [('t_badge','tut_step_badge'),('t_skip','tut_skip_tag'),('t_skip_p','tut_skip_tag_pressed'),('t_strip','tut_msg_strip'),('t_next','tut_next_normal'),('t_next_p','tut_next_pressed'),('t_star_on','tut_star_on'),('t_star_off','tut_star_off'),('t_scis','tut_scissors'),('t_grid','tut_page_grid'),('t_margin','tut_page_margin'),('t_holes','tut_page_holes')])
last=[m for m in re.finditer(r'\[ext_resource[^\n]*\n',s)][-1]
s=s[:last.end()]+add+s[last.end():]
# --- style hộp: thay StyleBoxFlat nút -> StyleBoxTexture
def tex(i,t,m,cm=''):
    return f'[sub_resource type="StyleBoxTexture" id="{i}"]\n{cm}texture = ExtResource("{t}")\ntexture_margin_left = {m[0]}.0\ntexture_margin_top = {m[1]}.0\ntexture_margin_right = {m[0]}.0\ntexture_margin_bottom = {m[1]}.0\n\n'
new_styles=(tex('btn_primary','t_next',(46,40))+tex('btn_primary_hover','t_next_p',(46,40))
 +tex('sb_skip','t_skip',(24,24),'content_margin_left = 16.0\ncontent_margin_top = 6.0\ncontent_margin_right = 20.0\ncontent_margin_bottom = 8.0\n')
 +tex('sb_skip_p','t_skip_p',(24,24),'content_margin_left = 16.0\ncontent_margin_top = 6.0\ncontent_margin_right = 20.0\ncontent_margin_bottom = 8.0\n')
 +'[sub_resource type="StyleBoxEmpty" id="sb_empty"]\n\n')
i=s.index('[sub_resource type="StyleBoxFlat" id="btn_primary"]'); j=s.index('[sub_resource type="Animation" id="Animation_reset"]')
s=s[:i]+new_styles+s[j:]
# --- animation: hình học mới của thẻ thoại
def rep(a,b,cnt=1):
    global s
    assert a in s,a
    s=s.replace(a,b)
rep('"values": [116.0]','"values": [210.0]'); rep('"values": [206.0]','"values": [360.0]')
rep('"values": [-234.0]','"values": [-236.0]'); rep('"values": [234.0]','"values": [236.0]')
rep('"values": [158.0, 158.0, 116.0]','"values": [252.0, 252.0, 210.0]'); rep('"values": [248.0, 248.0, 206.0]','"values": [402.0, 402.0, 360.0]')
rep('[-234.0, -226.0, -242.0, -228.0, -240.0, -234.0]','[-236.0, -228.0, -244.0, -230.0, -242.0, -236.0]')
rep('[234.0, 242.0, 226.0, 240.0, 228.0, 234.0]','[236.0, 244.0, 228.0, 242.0, 230.0, 236.0]')
# nền backdrop trong animation giữ nguyên (cream đặc) -> trang vở vẽ đè bằng PageDeco
# --- node_paths + exports
rep('"btn_skip_all", ','"btn_skip_all", "lbl_step_num", "lbl_step_of", ')
rep('btn_skip_all = NodePath("NavBar/BtnSkipAll")','btn_skip_all = NodePath("Header/BtnSkipAll")\nlbl_step_num = NodePath("Header/StepBadge/Num")\nlbl_step_of = NodePath("Header/StepOf")\ntex_star_on = ExtResource("t_star_on")\ntex_star_off = ExtResource("t_star_off")')
# --- BoardHost +60 px xuống
rep('offset_top = -240.0\noffset_right = 230.0\noffset_bottom = 180.0','offset_top = -180.0\noffset_right = 230.0\noffset_bottom = 240.0')
# --- PageDeco sau Backdrop
deco='''[node name="PageDeco" type="Control" parent="." index="1"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="Grid" type="TextureRect" parent="PageDeco" index="0"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
texture = ExtResource("t_grid")
stretch_mode = 1

[node name="Margin" type="TextureRect" parent="PageDeco" index="1"]
layout_mode = 1
anchors_preset = 11
anchor_left = 0.0
anchor_right = 0.0
anchor_bottom = 1.0
offset_left = 50.0
offset_right = 54.0
grow_vertical = 2
mouse_filter = 2
texture = ExtResource("t_margin")
stretch_mode = 1

[node name="Holes" type="TextureRect" parent="PageDeco" index="2"]
layout_mode = 1
anchors_preset = 11
anchor_left = 0.0
anchor_right = 0.0
anchor_bottom = 1.0
offset_left = 4.0
offset_top = 30.0
offset_right = 32.0
grow_vertical = 2
mouse_filter = 2
texture = ExtResource("t_holes")
stretch_mode = 1

'''
k=s.index('[node name="Spotlight"')
s=s[:k]+deco+s[k:]
# index của các node con trực tiếp: đánh lại theo thứ tự mới (Backdrop 0, PageDeco 1, Spotlight... ) bằng cách bỏ index cũ của gốc (không bắt buộc)
# --- khối Header ... Dots (thay toàn bộ)
a=s.index('[node name="Header"'); b=s.index('[node name="AnimationPlayer"')
dots=''.join(f'''[node name="Dot{n}" type="TextureRect" parent="Dots" unique_id={uid}]
visible = false
custom_minimum_size = Vector2(44, 44)
layout_mode = 2
pivot_offset = Vector2(22, 22)
texture = ExtResource("t_star_off")
expand_mode = 1
stretch_mode = 5

''' for n,uid in zip(range(1,7),[1848305278,318154076,1381081468,408374677,1930197384,967110451]))
hdr=f'''[node name="Header" type="Control" parent="." unique_id=601935572]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_bottom = 200.0
grow_horizontal = 2
mouse_filter = 2

[node name="StepBadge" type="TextureRect" parent="Header"]
layout_mode = 0
offset_left = 62.0
offset_top = 36.0
offset_right = 172.0
offset_bottom = 146.0
pivot_offset = Vector2(55, 55)
rotation = -0.1047
mouse_filter = 2
texture = ExtResource("t_badge")

[node name="Num" type="Label" parent="Header/StepBadge"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_top = -2.0
grow_horizontal = 2
grow_vertical = 2
theme_override_colors/font_color = Color(0.85, 0.27, 0.25, 1)
theme_override_font_sizes/font_size = 62
text = "1"
horizontal_alignment = 1
vertical_alignment = 1

[node name="Title" type="Label" parent="Header" unique_id=1569248542]
layout_mode = 1
anchors_preset = -1
anchor_right = 1.0
offset_left = 196.0
offset_top = 40.0
offset_right = -20.0
offset_bottom = 92.0
pivot_offset = Vector2(0, 26)
theme_override_colors/font_color = Color(0.114, 0.31, 0.45, 1)
theme_override_font_sizes/font_size = 34
text = "STR_TUT_COMMON_TITLE"
vertical_alignment = 1
clip_text = true

[node name="StepOf" type="Label" parent="Header"]
layout_mode = 1
anchors_preset = -1
anchor_right = 1.0
offset_left = 196.0
offset_top = 94.0
offset_right = -20.0
offset_bottom = 130.0
theme_override_colors/font_color = Color(0.35, 0.45, 0.55, 1)
theme_override_font_sizes/font_size = 24
text = "Bước 1 trong 4"
vertical_alignment = 1

[node name="BtnSkip" type="Button" parent="Header" unique_id=1671343425]
layout_mode = 1
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -200.0
offset_top = 138.0
offset_right = -18.0
offset_bottom = 204.0
grow_horizontal = 0
pivot_offset = Vector2(90, 33)
rotation = 0.07
mouse_default_cursor_shape = 2
focus_mode = 0
theme_override_colors/font_color = Color(0.85, 0.27, 0.25, 1)
theme_override_colors/font_hover_color = Color(0.72, 0.2, 0.18, 1)
theme_override_colors/font_pressed_color = Color(0.72, 0.2, 0.18, 1)
theme_override_constants/h_separation = 8
theme_override_font_sizes/font_size = 30
theme_override_styles/normal = SubResource("sb_skip")
theme_override_styles/hover = SubResource("sb_skip")
theme_override_styles/pressed = SubResource("sb_skip_p")
theme_override_styles/focus = SubResource("sb_empty")
text = "STR_TUT_COMMON_SKIP"
icon = ExtResource("t_scis")

[node name="BtnSkipAll" type="Button" parent="Header" unique_id=220332689]
visible = false
layout_mode = 1
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -300.0
offset_top = 138.0
offset_right = -18.0
offset_bottom = 204.0
grow_horizontal = 0
pivot_offset = Vector2(140, 33)
rotation = 0.07
mouse_default_cursor_shape = 2
focus_mode = 0
theme_override_colors/font_color = Color(0.85, 0.27, 0.25, 1)
theme_override_colors/font_hover_color = Color(0.72, 0.2, 0.18, 1)
theme_override_colors/font_pressed_color = Color(0.72, 0.2, 0.18, 1)
theme_override_constants/h_separation = 8
theme_override_font_sizes/font_size = 30
theme_override_styles/normal = SubResource("sb_skip")
theme_override_styles/hover = SubResource("sb_skip")
theme_override_styles/pressed = SubResource("sb_skip_p")
theme_override_styles/focus = SubResource("sb_empty")
text = "STR_TUT_COMMON_SKIP_ALL"
icon = ExtResource("t_scis")

[node name="DialogBubble" type="Control" parent="." unique_id=2017602598]
layout_mode = 1
anchors_preset = 5
anchor_left = 0.5
anchor_right = 0.5
offset_left = -236.0
offset_top = 210.0
offset_right = 236.0
offset_bottom = 360.0
grow_horizontal = 2
mouse_filter = 2

[node name="Strip" type="NinePatchRect" parent="DialogBubble"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
texture = ExtResource("t_strip")
patch_margin_left = 24
patch_margin_top = 22
patch_margin_right = 24
patch_margin_bottom = 22

[node name="Message" type="Label" parent="DialogBubble" unique_id=211959486]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 30.0
offset_top = 20.0
offset_right = -30.0
offset_bottom = -20.0
grow_horizontal = 2
grow_vertical = 2
theme_override_colors/font_color = Color(0.114, 0.31, 0.45, 1)
theme_override_constants/line_spacing = 6
theme_override_font_sizes/font_size = 27
vertical_alignment = 1
autowrap_mode = 3

[node name="ToastLabel" type="Label" parent="." unique_id=1722041310]
modulate = Color(1, 1, 1, 0)
layout_mode = 1
anchors_preset = 5
anchor_left = 0.5
anchor_right = 0.5
offset_left = -236.0
offset_top = 372.0
offset_right = 236.0
offset_bottom = 420.0
grow_horizontal = 2
theme_override_font_sizes/font_size = 24
horizontal_alignment = 1
vertical_alignment = 1
autowrap_mode = 3

[node name="NavBar" type="Control" parent="." unique_id=564302285]
layout_mode = 1
anchors_preset = 12
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_top = -170.0
offset_bottom = -70.0
grow_horizontal = 2
grow_vertical = 0
mouse_filter = 2

[node name="BtnNext" type="Button" parent="NavBar" unique_id=966799915]
layout_mode = 1
anchors_preset = 7
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -236.0
offset_top = -104.0
offset_right = 236.0
offset_bottom = -8.0
grow_horizontal = 2
grow_vertical = 0
mouse_default_cursor_shape = 2
focus_mode = 0
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_colors/font_hover_color = Color(1, 1, 1, 1)
theme_override_colors/font_pressed_color = Color(1, 1, 1, 1)
theme_override_colors/font_outline_color = Color(0.6, 0.38, 0.05, 1)
theme_override_constants/outline_size = 7
theme_override_font_sizes/font_size = 36
theme_override_styles/normal = SubResource("btn_primary")
theme_override_styles/hover = SubResource("btn_primary")
theme_override_styles/pressed = SubResource("btn_primary_hover")
theme_override_styles/focus = SubResource("sb_empty")
text = "STR_TUT_COMMON_NEXT"

[node name="Dots" type="HBoxContainer" parent="." unique_id=1937457845]
layout_mode = 1
anchors_preset = 7
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -180.0
offset_top = -272.0
offset_right = 180.0
offset_bottom = -222.0
grow_horizontal = 2
grow_vertical = 0
mouse_filter = 2
theme_override_constants/separation = 16
alignment = 1

{dots}'''
s=s[:a]+hdr+s[b:]
s=s.replace('[connection signal="pressed" from="NavBar/BtnSkipAll" to="." method="skip_all_tutorials"]','[connection signal="pressed" from="Header/BtnSkipAll" to="." method="skip_all_tutorials"]')
open(sys.argv[2],'w',encoding='utf-8').write(s)
print('ok')
