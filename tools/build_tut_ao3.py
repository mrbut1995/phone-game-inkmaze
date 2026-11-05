#!/usr/bin/env python3
"""Tutorial kiểu AO3 (bút chì kể chuyện + ruy-băng): sinh art (SVG + PNG scale 1) và vá nodes/tutorials/base_tutorial.tscn + congrats_first_time.tscn.
Chạy 1 lần trên base_tutorial.tscn của v71 (đã có kiểu AO4)."""
import os,re
from playwright.sync_api import sync_playwright
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NAVY='#2B3F52'; RED='#D9453F'; BLUE='#2F78A8'
def svg(w,h,body,defs='',vb=None): return f'<?xml version="1.0" encoding="utf-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb or f"0 0 {w} {h}"}" width="{w}" height="{h}">{defs}\n{body}\n</svg>\n'
A={}
# ruy-băng "Bỏ qua" 9-patch 120x72 (margin L36 T24 R14 B24): bầu bên trái, sát mép phải màn, có nếp gấp
def ribbon(face,edge,dy):
    p=lambda y:f'M120 {y}H30Q4 {y} 4 {y+27}Q4 {y+54} 30 {y+54}H120Z'
    return svg(120,72,f'<path d="{p(4+5)}" fill="{edge}"/><path d="{p(4+dy)}" fill="{face}"/><path d="M104 {63}H120V72Z" fill="#8A2823"/>')
A['tut_ribbon']=ribbon(RED,'#A9332E',0); A['tut_ribbon_pressed']=ribbon('#C93C37','#A9332E',3)
A['tut_chevron']=svg(28,28,'<path d="M9 5L20 14L9 23" fill="none" stroke="#fff" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>')
A['tut_play']=svg(28,28,'<path d="M8 4L24 14L8 24Z" fill="#fff" stroke="#fff" stroke-width="3" stroke-linejoin="round"/>')
# bóng thoại 9-patch 120x150 (margin L30 T40 R30 B40) — đuôi nhọn bên trái ở y=92
A['tut_bubble']=svg(120,150,f'<rect x="32" y="9" width="84" height="132" rx="22" fill="{NAVY}" opacity=".2" transform="translate(0 5)"/><path d="M32 78L6 92L32 106" fill="#fff" stroke="{NAVY}" stroke-width="3.5" stroke-linejoin="round"/><rect x="31" y="6" width="84" height="132" rx="22" fill="#fff" stroke="{NAVY}" stroke-width="3.5"/><rect x="28" y="80" width="8" height="24" fill="#fff"/>')
# mascot bút chì 112x198 (viewBox 96x170)
mascot=f'''<g stroke="{NAVY}" stroke-width="3.5" stroke-linejoin="round" stroke-linecap="round">
<ellipse cx="48" cy="160" rx="30" ry="6" fill="#000" opacity=".12" stroke="none"/>
<path d="M24 62L48 8L72 62Z" fill="#F2D2A3"/><path d="M38 30L48 8L58 30Z" fill="#3A3F4A"/>
<rect x="24" y="62" width="48" height="76" fill="#F7D54A"/><rect x="24" y="62" width="14" height="76" fill="#F1BF2B" stroke="none"/>
<rect x="24" y="138" width="48" height="14" fill="#C9D3DC"/><rect x="24" y="148" width="48" height="14" rx="6" fill="#F08A8A"/></g>
<circle cx="38" cy="96" r="5" fill="{NAVY}"/><circle cx="60" cy="96" r="5" fill="{NAVY}"/><circle cx="39.5" cy="94.5" r="1.8" fill="#fff"/><circle cx="61.5" cy="94.5" r="1.8" fill="#fff"/>
<path d="M38 111Q49 121 60 111" fill="none" stroke="{NAVY}" stroke-width="3.5" stroke-linecap="round"/><circle cx="29" cy="108" r="5" fill="#F4A3A3" opacity=".7"/><circle cx="68" cy="108" r="5" fill="#F4A3A3" opacity=".7"/>'''
A['tut_mascot']=svg(112,198,mascot,vb='0 0 96 170')
# thanh tiến độ nét mực gợn sóng 540x30
wave='M16 15C70 1 120 29 176 15S280 1 340 16S450 28 524 14'
A['tut_wave_bg']=svg(540,30,f'<path d="{wave}" fill="none" stroke="#E1D9BE" stroke-width="7" stroke-linecap="round"/>')
A['tut_wave_fill']=svg(540,30,f'<path d="{wave}" fill="none" stroke="{BLUE}" stroke-width="7" stroke-linecap="round"/>')
# nút Tiếp tục xanh 9-patch 128x96
def nxt(fill,edge,dy):
    return svg(128,96,f'<rect x="4" y="{10+dy}" width="120" height="82" rx="41" fill="{edge}"/><rect x="4" y="4" width="120" height="82" rx="41" fill="{fill}" transform="translate(0 {dy})"/><rect x="8" y="{8+dy}" width="112" height="74" rx="37" fill="none" stroke="#fff" stroke-width="4"/>')
A['tut_next_blue']=nxt(BLUE,'#1D4F73',0); A['tut_next_blue_pressed']=nxt('#276A98','#1D4F73',4)
with sync_playwright() as pw:
    b=pw.chromium.launch(); pg=b.new_page(device_scale_factor=1)
    for n,s in A.items():
        open(f'{ROOT}/assets/images/tutorial/{n}.svg','w',encoding='utf-8').write(s)
        w,h=map(int,re.search(r'width="(\d+)" height="(\d+)"',s).groups())
        pg.set_viewport_size({'width':w,'height':h}); pg.set_content(f'<html><body style="margin:0;background:transparent">{s}</body></html>')
        pg.screenshot(path=f'{ROOT}/assets/images-png/tutorial/{n}.png',omit_background=True,clip={'x':0,'y':0,'width':w,'height':h})
    b.close()

# ================= vá base_tutorial.tscn =================
P=f'{ROOT}/nodes/tutorials/base_tutorial.tscn'; s=open(P,encoding='utf-8').read()
def block(name,parent):
    m=re.search(r'\[node name="%s" [^\n]*parent="%s"[^\n]*\]\n.*?(?=\n\n\[|\Z)'%(re.escape(name),re.escape(parent)),s,re.S)
    assert m,(name,parent); return m
def setblk(name,parent,new):
    global s; m=block(name,parent); s=s[:m.start()]+new.strip('\n')+s[m.end():]
# ext_resources
ext=''.join(f'[ext_resource type="Texture2D" path="res://assets/images-png/tutorial/{f}.png" id="{i}"]\n' for i,f in [('a_rib','tut_ribbon'),('a_rib_p','tut_ribbon_pressed'),('a_chev','tut_chevron'),('a_play','tut_play'),('a_bub','tut_bubble'),('a_mas','tut_mascot'),('a_wbg','tut_wave_bg'),('a_wfi','tut_wave_fill'),('a_nxb','tut_next_blue'),('a_nxbp','tut_next_blue_pressed')])
s=s.replace('\n[sub_resource type="StyleBoxTexture" id="btn_primary"]',ext+'\n[sub_resource type="StyleBoxTexture" id="btn_primary"]',1)
# nút Tiếp tục xanh
s=re.sub(r'(\[sub_resource type="StyleBoxTexture" id="btn_primary"\]\ntexture = )ExtResource\("t_next"\)',r'\1ExtResource("a_nxb")',s)
s=re.sub(r'(\[sub_resource type="StyleBoxTexture" id="btn_primary_hover"\]\ntexture = )ExtResource\("t_next_p"\)',r'\1ExtResource("a_nxbp")',s)
# ruy-băng
for sid,tex in (('sb_skip','a_rib'),('sb_skip_p','a_rib_p')):
    m=re.search(r'\[sub_resource type="StyleBoxTexture" id="%s"\]\n.*?(?=\n\n)'%sid,s,re.S)
    s=s[:m.start()]+f'[sub_resource type="StyleBoxTexture" id="{sid}"]\ncontent_margin_left = 34.0\ncontent_margin_top = 4.0\ncontent_margin_right = 22.0\ncontent_margin_bottom = 12.0\ntexture = ExtResource("{tex}")\ntexture_margin_left = 36.0\ntexture_margin_top = 24.0\ntexture_margin_right = 14.0\ntexture_margin_bottom = 24.0'+s[m.end():]
# animation: thay 2 track offset của DialogBubble bằng scale
def trk(i,path,times,vals): return f'tracks/{i}/type = "value"\ntracks/{i}/imported = false\ntracks/{i}/enabled = true\ntracks/{i}/path = NodePath("{path}")\ntracks/{i}/interp = 1\ntracks/{i}/loop_wrap = true\ntracks/{i}/keys = {{\n"times": PackedFloat32Array({times}),\n"transitions": PackedFloat32Array(1, 1, 1),\n"update": 0,\n"values": [{vals}]\n}}\n'
m=re.search(r'tracks/2/type = "value"\ntracks/2/imported = false\ntracks/2/enabled = true\ntracks/2/path = NodePath\("DialogBubble:offset_top"\).*?(?=tracks/4/type)',s,re.S)
rest=s[m.end():]
rest=rest.replace('tracks/4/','tracks/3/',).replace('tracks/5/','tracks/4/') if False else rest
s=s[:m.start()]+trk(2,'DialogBubble:scale','0, 0.06, 0.32','Vector2(0.92, 0.92), Vector2(0.92, 0.92), Vector2(1, 1)')+s[m.end():]
mm=re.search(r'\[sub_resource type="Animation" id="Animation_entrance"\].*?(?=\n\[sub_resource)',s,re.S)
bb=mm.group(0).replace('tracks/4/','tracks/3/').replace('tracks/5/','tracks/4/')
s=s[:mm.start()]+bb+s[mm.end():]
s=s.replace('[-236.0, -228.0, -244.0, -230.0, -242.0, -236.0]','[-118.0, -110.0, -126.0, -112.0, -124.0, -118.0]').replace('[236.0, 244.0, 228.0, 242.0, 230.0, 236.0]','[244.0, 252.0, 236.0, 250.0, 238.0, 244.0]')
# Header
setblk('StepBadge','Header',open_:=None) if False else None
m=block('StepBadge','Header'); s=s[:m.end()]+'' +s[m.end():]
s=s.replace('[node name="StepBadge" type="TextureRect" parent="Header"]\nlayout_mode = 0','[node name="StepBadge" type="TextureRect" parent="Header"]\nvisible = false\nlayout_mode = 0',1)
setblk('Title','Header','''[node name="Title" type="Label" parent="Header" unique_id=1569248542]
layout_mode = 1
anchors_preset = -1
anchor_right = 1.0
offset_left = 50.0
offset_top = 22.0
offset_right = -190.0
offset_bottom = 66.0
pivot_offset = Vector2(0, 22)
theme_override_colors/font_color = Color(0.114, 0.31, 0.45, 1)
theme_override_font_sizes/font_size = 32
text = "STR_TUT_COMMON_TITLE"
vertical_alignment = 1
clip_text = true''')
setblk('StepOf','Header','''[node name="StepOf" type="Label" parent="Header"]
layout_mode = 1
anchors_preset = -1
anchor_right = 1.0
offset_left = 50.0
offset_top = 64.0
offset_right = -190.0
offset_bottom = 98.0
theme_override_colors/font_color = Color(0.353, 0.451, 0.533, 1)
theme_override_font_sizes/font_size = 24
text = "Bước 1 trong 4"
vertical_alignment = 1''')
for nm,uid,left in (('BtnSkip','1671343425',210),('BtnSkipAll','220332689',300)):
    vis='visible = false\n' if nm=='BtnSkipAll' else ''
    setblk(nm,'Header',f'''[node name="{nm}" type="Button" parent="Header" unique_id={uid}]
{vis}layout_mode = 1
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -{left}.0
offset_top = 124.0
offset_right = 0.0
offset_bottom = 196.0
grow_horizontal = 0
mouse_default_cursor_shape = 2
focus_mode = 0
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_colors/font_hover_color = Color(1, 1, 1, 1)
theme_override_colors/font_pressed_color = Color(1, 1, 1, 1)
theme_override_colors/icon_normal_color = Color(1, 1, 1, 1)
theme_override_constants/h_separation = 8
theme_override_font_sizes/font_size = {30 if nm=='BtnSkip' else 26}
theme_override_styles/normal = SubResource("sb_skip")
theme_override_styles/hover = SubResource("sb_skip")
theme_override_styles/pressed = SubResource("sb_skip_p")
theme_override_styles/focus = SubResource("sb_empty")
text = "{'STR_TUT_COMMON_SKIP' if nm=='BtnSkip' else 'STR_TUT_COMMON_SKIP_ALL'}"
icon = ExtResource("a_chev")
icon_alignment = 2''')
# Wave (thanh tiến độ) ngay dưới StepOf
wave_node='''[node name="Wave" type="TextureProgressBar" parent="Header"]
layout_mode = 0
offset_left = 0.0
offset_top = 98.0
offset_right = 540.0
offset_bottom = 128.0
mouse_filter = 2
max_value = 4.0
step = 0.01
value = 1.0
texture_under = ExtResource("a_wbg")
texture_progress = ExtResource("a_wfi")
nine_patch_stretch = true
'''
m=block('BtnSkipAll','Header'); s=s[:m.end()]+'\n\n'+wave_node.rstrip('\n')+s[m.end():]
# BoardHost
s=s.replace('offset_left = -230.0\noffset_top = -150.0\noffset_right = 230.0\noffset_bottom = 270.0','offset_left = -230.0\noffset_top = -276.0\noffset_right = 230.0\noffset_bottom = 144.0',1)
# DialogBubble (neo đáy, có mascot bên trái)
setblk('DialogBubble','.','''[node name="DialogBubble" type="Control" parent="." unique_id=2017602598]
layout_mode = 1
anchors_preset = 7
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -118.0
offset_top = -322.0
offset_right = 244.0
offset_bottom = -182.0
grow_horizontal = 2
grow_vertical = 0
pivot_offset = Vector2(181, 70)
mouse_filter = 2''')
setblk('Strip','DialogBubble','''[node name="Strip" type="NinePatchRect" parent="DialogBubble"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
texture = ExtResource("a_bub")
patch_margin_left = 30
patch_margin_top = 40
patch_margin_right = 30
patch_margin_bottom = 40''')
setblk('Message','DialogBubble','''[node name="Message" type="Label" parent="DialogBubble" unique_id=211959486]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 44.0
offset_top = 14.0
offset_right = -24.0
offset_bottom = -20.0
grow_horizontal = 2
grow_vertical = 2
theme_override_colors/font_color = Color(0.114, 0.31, 0.45, 1)
theme_override_constants/line_spacing = 4
theme_override_font_sizes/font_size = 27
vertical_alignment = 1
autowrap_mode = 3''')
mascot_node='''[node name="Mascot" type="TextureRect" parent="." index="8"]
layout_mode = 1
anchors_preset = 2
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = 8.0
offset_top = -380.0
offset_right = 120.0
offset_bottom = -182.0
grow_vertical = 0
mouse_filter = 2
texture = ExtResource("a_mas")
'''
m=block('Message','DialogBubble'); s=s[:m.end()]+'\n\n'+mascot_node.rstrip('\n')+s[m.end():]
# Dots ẩn (thanh nét mực thay sao)
s=s.replace('[node name="Dots" type="HBoxContainer" parent="." unique_id=1937457845]\n','[node name="Dots" type="HBoxContainer" parent="." unique_id=1937457845]\nvisible = false\n',1)
# BtnNext xanh to + mũi tên
setblk('BtnNext','NavBar','''[node name="BtnNext" type="Button" parent="NavBar" unique_id=966799915]
layout_mode = 1
anchors_preset = 7
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -206.0
offset_top = -100.0
offset_right = 206.0
offset_bottom = -8.0
grow_horizontal = 2
grow_vertical = 0
mouse_default_cursor_shape = 2
focus_mode = 0
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_colors/font_hover_color = Color(1, 1, 1, 1)
theme_override_colors/font_pressed_color = Color(1, 1, 1, 1)
theme_override_colors/font_outline_color = Color(0.114, 0.31, 0.45, 1)
theme_override_colors/icon_normal_color = Color(1, 1, 1, 1)
theme_override_constants/h_separation = 12
theme_override_constants/outline_size = 6
theme_override_font_sizes/font_size = 36
theme_override_styles/normal = SubResource("btn_primary")
theme_override_styles/hover = SubResource("btn_primary")
theme_override_styles/pressed = SubResource("btn_primary_hover")
theme_override_styles/focus = SubResource("sb_empty")
text = "STR_TUT_COMMON_NEXT"
icon = ExtResource("a_play")
icon_alignment = 2''')
# export wave
s=s.replace('"lbl_step_of", "btn_skip"','"lbl_step_of", "wave", "btn_skip"',1)
s=s.replace('lbl_step_of = NodePath("Header/StepOf")','lbl_step_of = NodePath("Header/StepOf")\nwave = NodePath("Header/Wave")',1)
open(P,'w',encoding='utf-8').write(s)
print('base ok')
