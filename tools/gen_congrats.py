#!/usr/bin/env python3
"""Màn CHÚC MỪNG (tutorial) kiểu sổ tay: tem huy hiệu + băng dính + thẻ thống kê + nút vàng.
SVG -> assets/images/tutorial ; PNG xuất từ SVG scale 1 -> assets/images-png/tutorial ; sinh nodes/tutorials/congrats_first_time.tscn
(phần Animation lấy nguyên từ file congrats_first_time.tscn cũ: --orig, mặc định /tmp/congrats_orig.tscn)"""
import os,re,sys,math,random
from playwright.sync_api import sync_playwright
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIG=sys.argv[1] if len(sys.argv)>1 else '/tmp/congrats_orig.tscn'
INK='#3E4249'; NAVY='#1D4F73'; GOLD='#F5B83A'; GOLD_D='#C98A15'; RED='#D9453F'; BLUE='#2F78A8'
def svg(w,h,body,defs=''): return f'<?xml version="1.0" encoding="utf-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{defs}\n{body}\n</svg>\n'
SH='<defs><filter id="s" x="-10%" y="-10%" width="125%" height="135%"><feDropShadow dx="0" dy="4" stdDeviation="3" flood-color="#2D2115" flood-opacity=".25"/></filter></defs>'
def star(cx,cy,r,fill,stroke,sw=2.5):
    pts=[]
    for i in range(10):
        a=-math.pi/2+i*math.pi/5; rr=r if i%2==0 else r*0.46
        pts.append(f'{cx+rr*math.cos(a):.1f},{cy+rr*math.sin(a):.1f}')
    return f'<polygon points="{" ".join(pts)}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round"/>'
A={}
# ---- tem huy hiệu 300x270 ----
cx,cy,R=150,148,92
sc=''
n=22
for i in range(n):
    a=i*2*math.pi/n; sc+=f'<circle cx="{cx+R*math.cos(a):.1f}" cy="{cy+R*math.sin(a):.1f}" r="13" fill="{GOLD}"/>'
ribbons=(f'<g transform="rotate(14 118 225)"><path d="M96 190H140V262L118 248L96 262Z" fill="{RED}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/></g>'
         f'<g transform="rotate(-14 182 225)"><path d="M160 190H204V262L182 248L160 262Z" fill="#E8665F" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/></g>')
seal=(f'<g filter="url(#s)">{sc}<circle cx="{cx}" cy="{cy}" r="{R}" fill="{GOLD}"/></g>'
      f'<circle cx="{cx}" cy="{cy}" r="{R-6}" fill="none" stroke="{GOLD_D}" stroke-width="3" stroke-dasharray="3 7" stroke-linecap="round"/>'
      f'<circle cx="{cx}" cy="{cy}" r="70" fill="#FFFDF5" stroke="{NAVY}" stroke-width="6"/>'
      f'<circle cx="{cx}" cy="{cy}" r="60" fill="none" stroke="{NAVY}" stroke-width="2" stroke-dasharray="7 6"/>'
      f'<path d="M112 {cy+2}L138 {cy+28}L190 {cy-26}" fill="none" stroke="#fff" stroke-width="26" stroke-linecap="round" stroke-linejoin="round"/>'
      f'<path d="M112 {cy+2}L138 {cy+28}L190 {cy-26}" fill="none" stroke="#2E9E6B" stroke-width="16" stroke-linecap="round" stroke-linejoin="round"/>'
      +star(150,22,17,GOLD,GOLD_D)+star(92,34,12,GOLD,GOLD_D)+star(208,34,12,GOLD,GOLD_D))
A['congrats_seal']=svg(300,270,ribbons+seal,SH)
# ---- thẻ thống kê 200x86 (giấy + băng dính) ----
A['congrats_stat_card']=svg(200,86,f'<g filter="url(#s)"><rect x="6" y="12" width="188" height="68" rx="9" fill="#FFFDF5" stroke="#E0CE9E" stroke-width="2.5"/></g><rect x="62" y="3" width="76" height="20" fill="rgba(127,200,205,.82)" transform="rotate(-2 100 13)"/>',SH)
# ---- nút phụ: nhãn viền xanh navy nét đứt, 9-patch 96x64 margin 24 ----
def tag(fill,dy=0): return svg(96,64,f'<g filter="url(#s)"><rect x="5" y="{4+dy}" width="86" height="50" rx="11" fill="{fill}"/></g><rect x="5" y="{4+dy}" width="86" height="50" rx="11" fill="none" stroke="{NAVY}" stroke-width="3" stroke-dasharray="9 6"/>',SH)
A['congrats_tag_main']=tag('#fff'); A['congrats_tag_main_pressed']=tag('#E4EEF6',2)
# ---- confetti 540x340 ----
rnd=random.Random(7); cf=''
cols=[GOLD,RED,BLUE,'#7FC8CD','#E8665F','#9AD6A8']
def spots():
    for _ in range(46):
        x=rnd.uniform(8,532); y=rnd.uniform(6,200)
        if 90<x<450 and 34<y<112: continue   # chừa chỗ băng dính tiêu đề
        yield x,y
for x,y in spots():
    c=rnd.choice(cols); k=rnd.random(); rot=rnd.uniform(0,180)
    if k<.45: cf+=f'<rect x="{x-6:.0f}" y="{y-3:.0f}" width="12" height="6" rx="1.5" fill="{c}" transform="rotate({rot:.0f} {x:.0f} {y:.0f})"/>'
    elif k<.75: cf+=f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{rnd.uniform(3,5):.1f}" fill="{c}"/>'
    else: cf+=star(x,y,rnd.uniform(7,10),c,INK,1.8)
A['congrats_confetti']=svg(540,340,cf)
with sync_playwright() as pw:
    b=pw.chromium.launch(); pg=b.new_page(device_scale_factor=1)
    for n,s in A.items():
        open(f'{ROOT}/assets/images/tutorial/{n}.svg','w',encoding='utf-8').write(s)
        w,h=map(int,re.search(r'width="(\d+)" height="(\d+)"',s).groups())
        pg.set_viewport_size({'width':w,'height':h})
        pg.set_content(f'<html><body style="margin:0;background:transparent">{s}</body></html>')
        pg.screenshot(path=f'{ROOT}/assets/images-png/tutorial/{n}.png',omit_background=True,clip={'x':0,'y':0,'width':w,'height':h})
    b.close()
# ---- scene ----
o=open(ORIG,encoding='utf-8').read()
anim=o[o.index('[sub_resource type="Animation" id="Animation_congrats"]'):o.index('[node name="CongratsFirstTime"')]
def pop(name,t0,t1,k=1): pass
extra_anim='''[sub_resource type="Animation" id="Animation_stats"]
resource_name = "stats_in"
length = 0.5
'''
tscn=f'''[gd_scene format=3 uid="uid://4br5abaueaea"]

[ext_resource type="PackedScene" uid="uid://bdaud8s52opsm" path="res://nodes/tutorials/base_tutorial.tscn" id="1_base"]
[ext_resource type="Script" path="res://scripts/ui/tutorial/congrats_first_time.gd" id="2_script"]
[ext_resource type="Texture2D" path="res://assets/images-png/tutorial/congrats_seal.png" id="3_seal"]
[ext_resource type="Texture2D" path="res://assets/images-png/tutorial/congrats_confetti.png" id="4_conf"]
[ext_resource type="Texture2D" path="res://assets/images-png/tutorial/congrats_stat_card.png" id="5_card"]
[ext_resource type="Texture2D" path="res://assets/images-png/tutorial/congrats_tag_main.png" id="6_tag"]
[ext_resource type="Texture2D" path="res://assets/images-png/tutorial/congrats_tag_main_pressed.png" id="7_tag_p"]
[ext_resource type="Texture2D" path="res://assets/images-png/tutorial/tut_next_normal.png" id="8_next"]
[ext_resource type="Texture2D" path="res://assets/images-png/tutorial/tut_next_pressed.png" id="9_next_p"]
[ext_resource type="Texture2D" path="res://assets/images-png/popups/washi_tape.png" id="10_tape"]

[sub_resource type="StyleBoxTexture" id="btn_primary"]
content_margin_left = 24.0
content_margin_top = 8.0
content_margin_right = 24.0
content_margin_bottom = 14.0
texture = ExtResource("8_next")
texture_margin_left = 46.0
texture_margin_top = 40.0
texture_margin_right = 46.0
texture_margin_bottom = 40.0

[sub_resource type="StyleBoxTexture" id="btn_primary_hover"]
content_margin_left = 24.0
content_margin_top = 8.0
content_margin_right = 24.0
content_margin_bottom = 14.0
texture = ExtResource("9_next_p")
texture_margin_left = 46.0
texture_margin_top = 40.0
texture_margin_right = 46.0
texture_margin_bottom = 40.0

[sub_resource type="StyleBoxTexture" id="btn_ghost"]
content_margin_left = 20.0
content_margin_top = 6.0
content_margin_right = 20.0
content_margin_bottom = 8.0
texture = ExtResource("6_tag")
texture_margin_left = 24.0
texture_margin_top = 24.0
texture_margin_right = 24.0
texture_margin_bottom = 24.0

[sub_resource type="StyleBoxTexture" id="btn_ghost_p"]
content_margin_left = 20.0
content_margin_top = 6.0
content_margin_right = 20.0
content_margin_bottom = 8.0
texture = ExtResource("7_tag_p")
texture_margin_left = 24.0
texture_margin_top = 24.0
texture_margin_right = 24.0
texture_margin_bottom = 24.0

[sub_resource type="StyleBoxEmpty" id="sb_empty"]

{anim}[node name="CongratsFirstTime" instance=ExtResource("1_base") node_paths=PackedStringArray("stamp", "btn_continue", "btn_main", "fx_anim", "confetti", "stat_cards", "lbl_stat_a", "lbl_stat_b")]
script = ExtResource("2_script")
stamp = NodePath("Stamp")
btn_continue = NodePath("ChoiceRow/BtnContinue")
btn_main = NodePath("ChoiceRow/BtnMain")
fx_anim = NodePath("CongratsAnim")
confetti = NodePath("Confetti")
stat_cards = [NodePath("Stats/CardA"), NodePath("Stats/CardB")]
lbl_stat_a = NodePath("Stats/CardA/Text")
lbl_stat_b = NodePath("Stats/CardB/Text")

[node name="Confetti" type="TextureRect" parent="." index="2"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_bottom = 340.0
grow_horizontal = 2
mouse_filter = 2
texture = ExtResource("4_conf")
stretch_mode = 5

[node name="Title" parent="Header" index="1"]
z_index = 1
offset_left = 70.0
offset_top = 34.0
offset_right = -70.0
offset_bottom = 104.0
pivot_offset = Vector2(200, 35)
theme_override_font_sizes/font_size = 54
horizontal_alignment = 1

[node name="TitleTape" type="NinePatchRect" parent="Header" index="5"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_left = 44.0
offset_top = 26.0
offset_right = -44.0
offset_bottom = 112.0
grow_horizontal = 2
mouse_filter = 2
texture = ExtResource("10_tape")
patch_margin_left = 14
patch_margin_top = 14
patch_margin_right = 14
patch_margin_bottom = 14

[node name="DialogBubble" parent="."]
offset_top = 132.0
offset_bottom = 282.0

[node name="Stamp" type="TextureRect" parent="." index="8"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -150.0
offset_top = -150.0
offset_right = 150.0
offset_bottom = 120.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
texture = ExtResource("3_seal")
expand_mode = 1
stretch_mode = 5

[node name="Stats" type="Control" parent="." index="9"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -215.0
offset_top = 130.0
offset_right = 215.0
offset_bottom = 216.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

'''
def card(name,x,rot,num,txt,col):
    return f'''[node name="{name}" type="TextureRect" parent="Stats"]
layout_mode = 0
offset_left = {x}
offset_right = {x+200}
offset_bottom = 86.0
pivot_offset = Vector2(100, 43)
rotation = {rot}
mouse_filter = 2
texture = ExtResource("5_card")

[node name="Num" type="Label" parent="Stats/{name}"]
layout_mode = 0
offset_left = 12.0
offset_top = 14.0
offset_right = 72.0
offset_bottom = 80.0
theme_override_colors/font_color = Color({col})
theme_override_font_sizes/font_size = 46
text = "{num}"
horizontal_alignment = 1
vertical_alignment = 1

[node name="Text" type="Label" parent="Stats/{name}"]
layout_mode = 0
offset_left = 70.0
offset_top = 16.0
offset_right = 192.0
offset_bottom = 78.0
theme_override_colors/font_color = Color(0.114, 0.31, 0.451, 1)
theme_override_font_sizes/font_size = 22
text = "{txt}"
vertical_alignment = 1
autowrap_mode = 3

'''
tscn+=card('CardA',0.0,-0.04,'3','bài học','0.85, 0.27, 0.25, 1')+card('CardB',230.0,0.035,'4','màn thử sức','0.18, 0.46, 0.66, 1')
tscn+='''[node name="ChoiceRow" type="VBoxContainer" parent="." index="10"]
layout_mode = 1
anchors_preset = 7
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -225.0
offset_top = -184.0
offset_right = 225.0
offset_bottom = -20.0
grow_horizontal = 2
grow_vertical = 0
theme_override_constants/separation = 8
alignment = 1

[node name="BtnContinue" type="Button" parent="ChoiceRow" index="0"]
custom_minimum_size = Vector2(450, 92)
layout_mode = 2
size_flags_horizontal = 4
mouse_default_cursor_shape = 2
focus_mode = 0
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_colors/font_hover_color = Color(1, 1, 1, 1)
theme_override_colors/font_pressed_color = Color(1, 1, 1, 1)
theme_override_colors/font_outline_color = Color(0.6, 0.38, 0.05, 1)
theme_override_constants/outline_size = 7
theme_override_font_sizes/font_size = 30
theme_override_styles/normal = SubResource("btn_primary")
theme_override_styles/hover = SubResource("btn_primary")
theme_override_styles/pressed = SubResource("btn_primary_hover")
theme_override_styles/focus = SubResource("sb_empty")
text = "STR_TUT_CONGRATS_CONTINUE"

[node name="BtnMain" type="Button" parent="ChoiceRow" index="1"]
custom_minimum_size = Vector2(340, 64)
layout_mode = 2
size_flags_horizontal = 4
mouse_default_cursor_shape = 2
focus_mode = 0
theme_override_colors/font_color = Color(0.114, 0.31, 0.451, 1)
theme_override_colors/font_hover_color = Color(0.114, 0.31, 0.451, 1)
theme_override_colors/font_pressed_color = Color(0.114, 0.31, 0.451, 1)
theme_override_font_sizes/font_size = 26
theme_override_styles/normal = SubResource("btn_ghost")
theme_override_styles/hover = SubResource("btn_ghost")
theme_override_styles/pressed = SubResource("btn_ghost_p")
theme_override_styles/focus = SubResource("sb_empty")
text = "STR_TUT_CONGRATS_MAIN"

[node name="CongratsAnim" type="AnimationPlayer" parent="."]
libraries = {
"": SubResource("AnimationLibrary_congrats")
}

[connection signal="pressed" from="ChoiceRow/BtnContinue" to="." method="_on_continue_pressed"]
[connection signal="pressed" from="ChoiceRow/BtnMain" to="." method="_on_main_pressed"]
'''
open(f'{ROOT}/nodes/tutorials/congrats_first_time.tscn','w',encoding='utf-8').write(tscn)
print('ok')
