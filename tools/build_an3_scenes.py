#!/usr/bin/env python3
"""Vá scene Splash/Title gốc (đọc từ thư mục gốc của user) thành bản AN3. Chạy: python3 build_an3_scenes.py SRC OUT"""
import re,sys,os
SRC,OUT=sys.argv[1],sys.argv[2]
def rd(p): return open(os.path.join(SRC,p),encoding='utf-8').read()
def wr(p,s):
    q=os.path.join(OUT,p); os.makedirs(os.path.dirname(q),exist_ok=True); open(q,'w',encoding='utf-8').write(s)
def cut(s,a,b):  # đoạn từ a đến trước b
    i=s.index(a); j=s.index(b); return s[:i],s[i:j],s[j:]

def ext(id_,path,uid=None,typ='Texture2D'):
    u=f' uid="{uid}"' if uid else ''
    return f'[ext_resource type="{typ}"{u} path="{path}" id="{id_}"]\n'
def sbtex(id_,tex,ml):
    return (f'[sub_resource type="StyleBoxTexture" id="{id_}"]\ntexture = ExtResource("{tex}")\n'
            f'texture_margin_left = {ml}.0\ntexture_margin_right = {ml}.0\naxis_stretch_horizontal = 1\n\n')

# ---------------------------------------------------------------- SPLASH
def note(name,tex,rot,anc_x,off_l,anc_y,off_t,tapecol,head_id,body_id):
    return f'''[node name="{name}" type="TextureRect" parent="Panel" index="{{I}}"]
modulate = Color(1, 1, 1, 0)
layout_mode = 1
anchors_preset = -1
anchor_left = {anc_x}
anchor_top = {anc_y}
anchor_right = {anc_x}
anchor_bottom = {anc_y}
offset_left = {off_l}
offset_top = {off_t}
offset_right = {off_l+160}
offset_bottom = {off_t+150}
mouse_filter = 2
pivot_offset = Vector2(80, 75)
rotation = {rot}
texture = ExtResource("{tex}")

[node name="Tape" type="TextureRect" parent="Panel/{name}" index="0"]
modulate = {tapecol}
layout_mode = 0
offset_left = 48.0
offset_top = -12.0
offset_right = 112.0
offset_bottom = 12.0
mouse_filter = 2
texture = ExtResource("tape_wt")
expand_mode = 1
stretch_mode = 5

[node name="Head" type="Label" parent="Panel/{name}" index="1"]
modulate = Color(0.30, 0.22, 0.14, 1)
layout_mode = 0
offset_left = 14.0
offset_top = 16.0
offset_right = 146.0
offset_bottom = 38.0
theme_override_font_sizes/font_size = 15
text = "Mẹo nhỏ"
vertical_alignment = 1
clip_text = true

[node name="Body" type="Label" parent="Panel/{name}" index="2"]
modulate = Color(0.28, 0.25, 0.22, 1)
layout_mode = 0
offset_left = 14.0
offset_top = 40.0
offset_right = 146.0
offset_bottom = 138.0
theme_override_font_sizes/font_size = 13
text = "..."
autowrap_mode = 3
clip_text = true

'''
def splash_nodes(land):
    LOGOID='4_piijc' if land else '4_t1n67'
    if land:
        pol_ax,pol_ay=0.5,0.36; pol_l,pol_t=-100,-130
        na=('0.5',-400,'0.36',-75); nb=('0.5',240,'0.43',-60)
        panel='''[node name="Panel" type="TextureRect" parent="." index="0" unique_id=125026115]
layout_mode = 1
anchors_preset = -1
anchor_right = 1.0
anchor_bottom = 1.0
expand_mode = 1
metadata/_edit_use_anchors_ = true

'''
        lbox=(0.25,0.74,0.75,0.9)
    else:
        pol_ax,pol_ay=0.5,0.27; pol_l,pol_t=-100,-130
        na=('0.5',-245,'0.43',-10); nb=('0.5',85,'0.5',-10)
        panel='''[node name="Panel" type="TextureRect" parent="." index="0" unique_id=125026115]
layout_mode = 1
anchors_preset = -1
anchor_left = 0.025925925
anchor_top = 0.0734375
anchor_right = 0.98
anchor_bottom = 0.964
metadata/_edit_use_anchors_ = true

'''
        lbox=(0.18,0.76,0.82,0.85)
    s=panel
    s+=f'''[node name="Polaroid" type="TextureRect" parent="Panel" index="0"]
layout_mode = 1
anchors_preset = -1
anchor_left = {pol_ax}
anchor_top = {pol_ay}
anchor_right = {pol_ax}
anchor_bottom = {pol_ay}
offset_left = {pol_l}.0
offset_top = {pol_t}.0
offset_right = {pol_l+200}.0
offset_bottom = {pol_t+240}.0
mouse_filter = 2
texture = ExtResource("pol")

[node name="LogoContainer" type="Control" parent="Panel" index="1" unique_id=1146882852]
modulate = Color(1, 1, 1, 0)
layout_mode = 1
anchor_left = {pol_ax}
anchor_top = {pol_ay}
anchor_right = {pol_ax}
anchor_bottom = {pol_ay}
offset_left = -82.0
offset_top = {pol_t+16}.0
offset_right = 82.0
offset_bottom = {pol_t+180}.0
scale = Vector2(0.3, 0.3)

[node name="Logo" type="TextureRect" parent="Panel/LogoContainer" index="0" unique_id=1473174428]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
texture = ExtResource("{LOGOID}")
expand_mode = 1
stretch_mode = 5
metadata/_edit_use_anchors_ = true

[node name="Title" type="Label" parent="Panel" index="2" unique_id=853179373]
modulate = Color(0.23921569, 0.5137255, 0.68235296, 0)
layout_mode = 1
anchors_preset = -1
anchor_left = {pol_ax}
anchor_top = {pol_ay}
anchor_right = {pol_ax}
anchor_bottom = {pol_ay}
offset_left = -96.0
offset_top = {pol_t+186}.0
offset_right = 96.0
offset_bottom = {pol_t+232}.0
scale = Vector2(0.88, 0.88)
pivot_offset = Vector2(96, 23)
theme_type_variation = &"MainTitle"
theme_override_font_sizes/font_size = 22
text = "Invisible Gear"
horizontal_alignment = 1
vertical_alignment = 1

'''
    s+=note('NoteA','note_y',-0.1047,*na,'Color(0.55, 0.78, 0.8, 1)',0,0).replace('{I}','3')
    s+=note('NoteB','note_b',0.0873,*nb,'Color(0.95, 0.62, 0.7, 1)',0,0).replace('{I}','4')
    s+=f'''[node name="LoadingBox" type="VBoxContainer" parent="Panel" index="5" unique_id=1712045566]
layout_mode = 1
anchors_preset = -1
anchor_left = {lbox[0]}
anchor_top = {lbox[1]}
anchor_right = {lbox[2]}
anchor_bottom = {lbox[3]}
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
alignment = 1
metadata/_edit_use_anchors_ = true

[node name="LoadingBar" type="ProgressBar" parent="Panel/LoadingBox" index="0" unique_id=1300572119]
custom_minimum_size = Vector2(0, 34)
layout_mode = 2
size_flags_vertical = 4
mouse_filter = 2
max_value = 1.0
step = 0.001
show_percentage = false
theme_override_styles/background = SubResource("sb_load_track")
theme_override_styles/fill = SubResource("sb_load_fill")

[node name="LoadingLabel" type="Label" parent="Panel/LoadingBox" index="1" unique_id=1055413042]
layout_mode = 2
theme_type_variation = &"SplashLoadingLabel"
text = "0%"
horizontal_alignment = 1

'''
    return s

def build_splash(land):
    p=f'scenes/layout/{"landscape" if land else "portrait"}/splash.tscn'
    s=rd(p)
    # sub_resource StyleBox -> StyleBoxTexture
    s=re.sub(r'\[sub_resource type="StyleBoxFlat" id="sb_load_track"\].*?\n\n',sbtex('sb_load_track','trk',8),s,flags=re.S)
    s=re.sub(r'\[sub_resource type="StyleBoxFlat" id="sb_load_fill"\].*?\n\n',sbtex('sb_load_fill','fil',8),s,flags=re.S)
    # ext resources
    last=[m for m in re.finditer(r'\[ext_resource[^\n]*\n',s)][-1]
    add=(ext('note_y','res://assets/images-png/splash/splash_note_yellow.png')+ext('note_b','res://assets/images-png/splash/splash_note_blue.png')
        +ext('pol','res://assets/images-png/splash/splash_polaroid.png')+ext('trk','res://assets/images-png/splash/loading_track_tape.png')
        +ext('fil','res://assets/images-png/splash/loading_fill_tape.png')+ext('tape_wt','res://assets/images-png/popups/washi_tape.png','uid://ruoaaeu82tl0'))
    s=s[:last.end()]+add+s[last.end():]
    # node_paths + exports
    s=s.replace('"loading_bar")','"loading_bar", "note_a_head", "note_a_body", "note_b_head", "note_b_body", "note_a", "note_b")',1)
    s=s.replace('loading_bar = NodePath("Panel/LoadingBox/LoadingBar")\n','''loading_bar = NodePath("Panel/LoadingBox/LoadingBar")
note_a_head = NodePath("Panel/NoteA/Head")
note_a_body = NodePath("Panel/NoteA/Body")
note_b_head = NodePath("Panel/NoteB/Head")
note_b_body = NodePath("Panel/NoteB/Body")
note_a = NodePath("Panel/NoteA")
note_b = NodePath("Panel/NoteB")
''',1)
    a,_,c=cut(s,'[node name="Panel"','[node name="TouchButton"')
    return p,a+splash_nodes(land)+c

# ---------------------------------------------------------------- TITLE
def build_title(land):
    p=f'scenes/layout/{"landscape" if land else "portrait"}/title.tscn'
    s=rd(p)
    last=[m for m in re.finditer(r'\[ext_resource[^\n]*\n',s)][-1]
    add=((ext('stack','res://assets/images-png/main/title_paper_stack.png') if not land else '')+ext('banner','res://assets/images-png/main/title_banner_torn.png')
        +ext('pstamp','res://assets/images-png/main/title_stamp_play.png'))
    s=s[:last.end()]+add+s[last.end():]
    if not land: s=re.sub(r'\[ext_resource[^\n]*id="4_paper"\]\n','',s)
    s=s.replace('NodePath("Panel/TapContainer/PlayIcon")','NodePath("Panel/TapContainer/Content/PlayIcon")').replace('NodePath("Panel/TapContainer/TapLabel")','NodePath("Panel/TapContainer/Content/TapLabel")')
    RED='Color(0.80, 0.22, 0.22, 1)'
    if not land:
        panel='''[node name="Panel" type="TextureRect" parent="." index="0" unique_id=1052516246]
layout_mode = 1
anchors_preset = -1
anchor_left = 0.025925925
anchor_top = 0.0734375
anchor_right = 0.98
anchor_bottom = 0.964
texture = ExtResource("stack")
expand_mode = 1
stretch_mode = 5
metadata/_edit_use_anchors_ = true

'''
        logo='''[node name="LogoContainer" type="Control" parent="Panel" index="0" unique_id=198818976]
layout_mode = 1
anchor_left = 0.5
anchor_top = 0.19
anchor_right = 0.5
anchor_bottom = 0.36
offset_left = -95.0
offset_top = 12.8484
offset_right = 95.0
offset_bottom = 12.8484
'''
        pencil_vis='visible = false\n'
        banner_geo=('anchor_left = 0.5\nanchor_top = 0.385\nanchor_right = 0.5\nanchor_bottom = 0.385\noffset_left = -190.0\noffset_top = 0.0\noffset_right = 190.0\noffset_bottom = 96.0\n')
        title_geo=('anchor_left = 0.5\nanchor_top = 0.385\nanchor_right = 0.5\nanchor_bottom = 0.385\noffset_left = -190.0\noffset_top = 6.0\noffset_right = 190.0\noffset_bottom = 90.0\npivot_offset = Vector2(190, 42)\n')
        sub_geo=('anchor_left = 0.5\nanchor_top = 0.505\nanchor_right = 0.5\nanchor_bottom = 0.55\noffset_left = -140.0\noffset_top = 0.0\noffset_right = 140.0\noffset_bottom = 0.0\n')
        tap_geo=('anchor_left = 0.5\nanchor_top = 0.73\nanchor_right = 0.5\nanchor_bottom = 0.73\noffset_left = -75.0\noffset_top = 0.0\noffset_right = 75.0\noffset_bottom = 150.0\n')
        title_font=56; stamp_sz=150; icon=(34,32); tfont=12; margin=28
        studio_geo='anchor_left = 0.2\nanchor_top = 0.14\nanchor_right = 0.8\nanchor_bottom = 0.18\n'
    else:
        panel='''[node name="Panel" type="TextureRect" parent="." index="0" unique_id=1052516246]
layout_mode = 1
anchors_preset = -1
anchor_right = 1.0
anchor_bottom = 1.0
texture = ExtResource("4_paper")
expand_mode = 1
metadata/_edit_use_anchors_ = true

'''
        logo=None; pencil_vis=''
        banner_geo=('anchor_left = 0.5\nanchor_top = 0.47\nanchor_right = 0.5\nanchor_bottom = 0.47\noffset_left = -190.0\noffset_top = 0.0\noffset_right = 190.0\noffset_bottom = 96.0\n')
        title_geo=('anchor_left = 0.5\nanchor_top = 0.47\nanchor_right = 0.5\nanchor_bottom = 0.47\noffset_left = -190.0\noffset_top = 6.0\noffset_right = 190.0\noffset_bottom = 90.0\npivot_offset = Vector2(190, 42)\n')
        sub_geo=('anchor_left = 0.5\nanchor_top = 0.66\nanchor_right = 0.5\nanchor_bottom = 0.72\noffset_left = -300.0\noffset_top = 0.0\noffset_right = 300.0\noffset_bottom = 0.0\n')
        tap_geo=('anchor_left = 0.5\nanchor_top = 0.74\nanchor_right = 0.5\nanchor_bottom = 0.74\noffset_left = -60.0\noffset_top = 0.0\noffset_right = 60.0\noffset_bottom = 120.0\n')
        title_font=48; stamp_sz=120; icon=(26,24); tfont=10; margin=22
        studio_geo=None
    # giữ nguyên LogoContainer/Logo/Pencil gốc của landscape
    m=re.search(r'\[node name="LogoContainer".*?(?=\[node name="Title")',s,flags=re.S)
    orig_logo=m.group(0)
    if land:
        logo_txt=orig_logo
    else:
        logo_txt=logo+'\n'+orig_logo[orig_logo.index('[node name="Logo"'):]
        logo_txt=logo_txt.replace('[node name="Pencil" type="TextureRect" parent="Panel/LogoContainer" index="1" unique_id=1525035922]\n','[node name="Pencil" type="TextureRect" parent="Panel/LogoContainer" index="1" unique_id=1525035922]\nvisible = false\n')
    body=panel+logo_txt
    body+=f'''[node name="Banner" type="TextureRect" parent="Panel" index="1"]
layout_mode = 1
anchors_preset = -1
{banner_geo}mouse_filter = 2
texture = ExtResource("banner")
expand_mode = 1
stretch_mode = 5

[node name="Title" type="Label" parent="Panel" index="2" unique_id=352020136]
modulate = Color(0.23921569, 0.5137255, 0.68235296, 1)
layout_mode = 1
anchors_preset = -1
{title_geo}theme_type_variation = &"MainTitle"
theme_override_font_sizes/font_size = {title_font}
text = "Ink Maze"
horizontal_alignment = 1
vertical_alignment = 1

[node name="Subtitle" type="Label" parent="Panel" index="3" unique_id=512779228]
modulate = Color(0.35, 0.45, 0.55, 1)
layout_mode = 1
anchors_preset = -1
{sub_geo}theme_type_variation = &"MainTagline"
theme_override_font_sizes/font_size = 14
text = "STR_TITLE_SUBTITLE"
horizontal_alignment = 1
vertical_alignment = 1
autowrap_mode = 3

[node name="TapContainer" type="Control" parent="Panel" index="4" unique_id=551840619]
layout_mode = 1
anchors_preset = -1
{tap_geo}pivot_offset = Vector2({stamp_sz/2}, {stamp_sz/2})
mouse_filter = 2

[node name="PlayStamp" type="TextureRect" parent="Panel/TapContainer" index="0"]
modulate = Color(1, 1, 1, 0.95)
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
texture = ExtResource("pstamp")
expand_mode = 1
stretch_mode = 5

[node name="Content" type="VBoxContainer" parent="Panel/TapContainer" index="1"]
layout_mode = 1
anchors_preset = -1
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = {margin}.0
offset_top = {margin}.0
offset_right = -{margin}.0
offset_bottom = -{margin}.0
mouse_filter = 2
theme_override_constants/separation = 2
alignment = 1

[node name="PlayIcon" type="TextureRect" parent="Panel/TapContainer/Content" index="0" unique_id=275797762]
modulate = {RED}
custom_minimum_size = Vector2({icon[0]}, {icon[1]})
layout_mode = 2
size_flags_vertical = 4
mouse_filter = 2
texture = ExtResource("{'7_play_icon' if land else '6_tcygh'}")
expand_mode = 1
stretch_mode = 5

[node name="TapLabel" type="Label" parent="Panel/TapContainer/Content" index="1" unique_id=17935693]
modulate = {RED}
layout_mode = 2
theme_override_font_sizes/font_size = {tfont}
text = "STR_TITLE_TAP_TO_START"
horizontal_alignment = 1
vertical_alignment = 1
autowrap_mode = 3

'''
    # Stamp + StudioLabel gốc (đổi index)
    m2=re.search(r'\[node name="Stamp".*?(?=\[node name="TouchButton")',s,flags=re.S)
    tail=m2.group(0)
    tail=tail.replace('parent="Panel" index="4"','parent="Panel" index="5"').replace('parent="Panel" index="5" unique_id=1866432788','parent="Panel" index="6" unique_id=1866432788')
    if studio_geo:
        tail=re.sub(r'(\[node name="StudioLabel".*?\n)anchors_preset = -1\nanchor_left = 0.1\nanchor_top = 0.18\nanchor_right = 0.9\nanchor_bottom = 0.23\n',
                    lambda mm: mm.group(1)+'anchors_preset = -1\n'+studio_geo,tail,flags=re.S)
    a,_,c=cut(s,'[node name="Panel"','[node name="TouchButton"')
    return p,a+body+tail+c

for land in (False,True):
    wr(*build_splash(land)); wr(*build_title(land))
print('ok')
