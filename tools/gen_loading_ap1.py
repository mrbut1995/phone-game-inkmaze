#!/usr/bin/env python3
"""Loading kiểu AP1 (bút chì vẽ đường đi trong mê cung).
Sinh SVG (assets/images/loading) + PNG xuất từ SVG scale 1 (assets/images-png/loading) + scenes/loading.tscn.
Cần: playwright. Nguồn scene gốc: scenes/loading.tscn của v66 (đọc từ --base, mặc định cùng thư mục)."""
import os,sys,random,math
from collections import deque
from playwright.sync_api import sync_playwright
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
C,R,S,SEED=5,6,60,11          # mê cung 5x6, ô 60px -> 300x360
WW,PW=4,12                     # độ dày tường / nét mực
PAD=6; INK='#3E4249'; BLUE='#2575A7'; WALL='#C9C2AA'
def maze_gen(C,R,seed):
    rnd=random.Random(seed);vis={(0,R-1)};st=[(0,R-1)];open_=set()
    while st:
        c,r=st[-1];nb=[(c+dc,r+dr) for dc,dr in((1,0),(-1,0),(0,1),(0,-1)) if 0<=c+dc<C and 0<=r+dr<R and (c+dc,r+dr) not in vis]
        if not nb: st.pop();continue
        n=rnd.choice(nb);vis.add(n);open_.add(frozenset([(c,r),n]));st.append(n)
    s=(0,R-1);e=(C-1,0);prev={s:None};q=deque([s])
    while q:
        u=q.popleft()
        for dc,dr in((1,0),(-1,0),(0,1),(0,-1)):
            v=(u[0]+dc,u[1]+dr)
            if v not in prev and frozenset([u,v]) in open_: prev[v]=u;q.append(v)
    path=[];u=e
    while u: path.append(u);u=prev[u]
    return open_,path[::-1]
open_,path=maze_gen(C,R,SEED)
def svg(w,h,body): return f'<?xml version="1.0" encoding="utf-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{body}</svg>\n'
ln=''
for r in range(R+1):
    for c in range(C):
        if r==0 or r==R or frozenset([(c,r),(c,r-1)]) not in open_: ln+=f'<line x1="{PAD+c*S}" y1="{PAD+r*S}" x2="{PAD+(c+1)*S}" y2="{PAD+r*S}"/>'
for c in range(C+1):
    for r in range(R):
        if c==0 or c==C or frozenset([(c,r),(c-1,r)]) not in open_: ln+=f'<line x1="{PAD+c*S}" y1="{PAD+r*S}" x2="{PAD+c*S}" y2="{PAD+(r+1)*S}"/>'
W,H=C*S+2*PAD,R*S+2*PAD
A={}
A['loading_maze_walls']=svg(W,H,f'<g stroke="{WALL}" stroke-width="{WW}" stroke-linecap="square">{ln}</g>')
A['loading_ink_seg']=svg(PW,PW,f'<circle cx="{PW/2}" cy="{PW/2}" r="{PW/2}" fill="{BLUE}"/>')
A['loading_dot']=svg(16,16,'<circle cx="8" cy="8" r="7" fill="#2F78A8"/>')
PW_,PH_,TX,TY=60,74,10,70   # bút chì: đầu chì tại (10,70)
A['loading_pencil']=svg(PW_,PH_,f'<g transform="translate({TX} {TY}) rotate(35)"><path d="M0 0L-6 -17L6 -17Z" fill="#E8B84A" stroke="{INK}" stroke-width="2.2" stroke-linejoin="round"/><path d="M-2.2 -6.5L0 0L2.2 -6.5Z" fill="{INK}"/><rect x="-6.5" y="-52" width="13" height="35" fill="#F7D54A" stroke="{INK}" stroke-width="2.2"/><rect x="-6.5" y="-52" width="13" height="8" fill="#F1BF2B"/><rect x="-6.5" y="-62" width="13" height="10" rx="4" fill="#E05A5A" stroke="{INK}" stroke-width="2.2"/></g>')
for sub in ('images','images-png'): os.makedirs(f'{ROOT}/assets/{sub}/loading',exist_ok=True)
with sync_playwright() as p:
    b=p.chromium.launch();pg=b.new_page(device_scale_factor=1)
    for n,s in A.items():
        open(f'{ROOT}/assets/images/loading/{n}.svg','w',encoding='utf-8').write(s)
        import re
        w,h=map(int,re.search(r'width="(\d+)" height="(\d+)"',s).groups())
        pg.set_viewport_size({'width':w,'height':h});pg.set_content(f'<body style="margin:0;background:transparent">{s.split("?>",1)[1]}</body>')
        pg.screenshot(path=f'{ROOT}/assets/images-png/loading/{n}.png',omit_background=True,clip={'x':0,'y':0,'width':w,'height':h})
    b.close()
# ---- đoạn thẳng (gộp các ô cùng hướng) ----
pts=[(PAD+c*S+S/2-PAD, PAD+r*S+S/2-PAD) for c,r in path]   # toạ độ trong Maze (đã bù PAD: Maze Control có offset PAD)
segs=[];i=0
while i<len(pts)-1:
    a=pts[i];d=(pts[i+1][0]-a[0],pts[i+1][1]-a[1]);j=i+1
    while j<len(pts)-1 and (pts[j+1][0]-pts[j][0],pts[j+1][1]-pts[j][1])==d: j+=1
    segs.append((a,pts[j]));i=j
TOTAL=sum(abs(b[0]-a[0])+abs(b[1]-a[1]) for a,b in segs)
DRAW,LEN=3.0,3.6
t=0.0;rows=[]
for a,b in segs:
    l=abs(b[0]-a[0])+abs(b[1]-a[1]);t1=t+DRAW*l/TOTAL;rows.append((a,b,t,t1));t=t1
# ---- tscn ----
def f(x): return f'{x:.3f}'.rstrip('0').rstrip('.')
def track(i,path,prop,times,vals,interp=1):
    ks=', '.join(vals)
    return (f'tracks/{i}/type = "value"\ntracks/{i}/imported = false\ntracks/{i}/enabled = true\ntracks/{i}/path = NodePath("{path}:{prop}")\n'
            f'tracks/{i}/interp = {interp}\ntracks/{i}/loop_wrap = true\ntracks/{i}/keys = {{\n"times": PackedFloat32Array({", ".join(f(x) for x in times)}),\n"transitions": PackedFloat32Array({", ".join("1" for _ in times)}),\n"update": 0,\n"values": [{ks}]\n}}\n')
V2=lambda x,y:f'Vector2({f(x)}, {f(y)})'
base='TransitionRoot/PaperPage/Content'
tracks='';ti=0;segnodes=''
for k,(a,b,t0,t1) in enumerate(rows):
    horiz=abs(b[1]-a[1])<1e-6; L=abs(b[0]-a[0])+abs(b[1]-a[1])
    fx=min(a[0],b[0])-PW/2; fy=min(a[1],b[1])-PW/2
    size_full=V2(L+PW,PW) if horiz else V2(PW,L+PW)
    segnodes+=(f'[node name="Seg{k}" type="NinePatchRect" parent="{base}/Maze/Ink"]\nlayout_mode = 0\noffset_left = {f(fx)}\noffset_top = {f(fy)}\noffset_right = {f(fx)}\noffset_bottom = {f(fy)}\nmouse_filter = 2\ntexture = ExtResource("l_seg")\npatch_margin_left = 5\npatch_margin_top = 5\npatch_margin_right = 5\npatch_margin_bottom = 5\n\n')
    p=f'{base}/Maze/Ink/Seg{k}'
    e=0.001
    tracks+=track(ti,p,'size',[0,max(t0-e,0),t0,t1,LEN],[V2(0,0),V2(0,0),V2(PW,PW),size_full,size_full]);ti+=1
    back=(b[0]<a[0]) if horiz else (b[1]<a[1])
    if back:
        endp=V2(b[0]-PW/2,b[1]-PW/2); startp=V2(a[0]-PW/2,a[1]-PW/2)
        tracks+=track(ti,p,'position',[0,t0,t1,LEN],[startp,startp,endp,endp]);ti+=1
# bút chì
pt=[0];pv=[V2(rows[0][0][0]-TX,rows[0][0][1]-TY)]
for a,b,t0,t1 in rows: pt.append(t1);pv.append(V2(b[0]-TX,b[1]-TY))
pt.append(LEN);pv.append(pv[-1])
tracks+=track(ti,f'{base}/Maze/Ink/Pencil','position',pt,pv);ti+=1
# mờ dần cuối vòng + hiện lại
tracks+=track(ti,f'{base}/Maze','modulate:a',[0,3.2,LEN],['1.0','1.0','0.0']);ti+=1
# 3 chấm nhảy
for d in range(3):
    ts=[round(x*0.15,3) for x in range(int(LEN/0.15)+1)]
    vs=[]
    for x in ts:
        ph=(x/1.2)*2*math.pi-d*0.9; vs.append(V2(d*26,-max(0,math.sin(ph))*12))
    tracks+=track(ti,f'{base}/Dots/Dot{d}','position',ts,vs);ti+=1
anim_loading=f'[sub_resource type="Animation" id="Animation_loading"]\nresource_name = "loading"\nlength = {LEN}\nloop_mode = 1\n{tracks}\n'
scene=f'''[gd_scene format=3 uid="uid://gpu3hvws2a5j"]

[ext_resource type="Script" uid="uid://beu82xphg17i6" path="res://scripts/ui/widgets/common/scene_transition.gd" id="1_transition"]
[ext_resource type="Texture2D" path="res://assets/images-png/loading/loading_page_grid.png" id="l_grid"]
[ext_resource type="Texture2D" path="res://assets/images-png/loading/loading_page_margin.png" id="l_mar"]
[ext_resource type="Texture2D" path="res://assets/images-png/loading/loading_page_holes.png" id="l_hole"]
[ext_resource type="Texture2D" path="res://assets/images-png/loading/loading_maze_walls.png" id="l_walls"]
[ext_resource type="Texture2D" path="res://assets/images-png/loading/loading_ink_seg.png" id="l_seg"]
[ext_resource type="Texture2D" path="res://assets/images-png/loading/loading_pencil.png" id="l_pen"]
[ext_resource type="Texture2D" path="res://assets/images-png/loading/loading_dot.png" id="l_dot"]

[sub_resource type="Gradient" id="GradShadowLeft"]
colors = PackedColorArray(0.12, 0.1, 0.08, 0.38, 0, 0, 0, 0)

[sub_resource type="GradientTexture2D" id="TexShadowLeft"]
gradient = SubResource("GradShadowLeft")
fill_from = Vector2(0, 0.5)
fill_to = Vector2(1, 0.5)

[sub_resource type="Gradient" id="GradShadowRight"]
colors = PackedColorArray(0, 0, 0, 0, 0.12, 0.1, 0.08, 0.38)

[sub_resource type="GradientTexture2D" id="TexShadowRight"]
gradient = SubResource("GradShadowRight")
fill_from = Vector2(0, 0.5)
fill_to = Vector2(1, 0.5)

[sub_resource type="Animation" id="Animation_reset"]
length = 0.001

{anim_loading}
[sub_resource type="AnimationLibrary" id="AnimationLibrary_101rs"]
_data = {{
&"RESET": SubResource("Animation_reset"),
&"loading": SubResource("Animation_loading")
}}

[node name="Loading" type="CanvasLayer" unique_id=1836600101 node_paths=PackedStringArray("transition_root", "blocker", "paper_page", "page_bg", "page_shadow_left", "page_shadow_right", "ink_circle_drawer", "fade_rect")]
process_mode = 3
layer = 128
script = ExtResource("1_transition")
transition_root = NodePath("TransitionRoot")
blocker = NodePath("TransitionRoot/InputBlocker")
paper_page = NodePath("TransitionRoot/PaperPage")
page_bg = NodePath("TransitionRoot/PaperPage/PaperBg")
page_shadow_left = NodePath("TransitionRoot/PaperPage/ShadowLeft")
page_shadow_right = NodePath("TransitionRoot/PaperPage/ShadowRight")
ink_circle_drawer = NodePath("TransitionRoot/InkCircleDrawer")
fade_rect = NodePath("TransitionRoot/FadeRect")

[node name="TransitionRoot" type="Control" parent="." unique_id=2081642660]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="InputBlocker" type="Control" parent="TransitionRoot" unique_id=1630297414]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="PaperPage" type="Control" parent="TransitionRoot" unique_id=9938624]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="PaperBg" type="ColorRect" parent="TransitionRoot/PaperPage" unique_id=91376094]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.992, 0.969, 0.918, 1)

[node name="ShadowLeft" type="TextureRect" parent="TransitionRoot/PaperPage" unique_id=878971299]
layout_mode = 1
anchors_preset = -1
anchor_bottom = 1.0
offset_left = -35.0
grow_vertical = 2
mouse_filter = 2
texture = SubResource("TexShadowLeft")

[node name="ShadowRight" type="TextureRect" parent="TransitionRoot/PaperPage" unique_id=987592050]
layout_mode = 1
anchors_preset = -1
anchor_left = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_right = 35.0
grow_horizontal = 0
grow_vertical = 2
mouse_filter = 2
texture = SubResource("TexShadowRight")

[node name="Grid" type="TextureRect" parent="TransitionRoot/PaperPage"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
texture = ExtResource("l_grid")
stretch_mode = 1

[node name="Margin" type="TextureRect" parent="TransitionRoot/PaperPage"]
layout_mode = 1
anchors_preset = 11
anchor_bottom = 1.0
offset_left = 50.0
offset_right = 54.0
grow_vertical = 2
mouse_filter = 2
texture = ExtResource("l_mar")
stretch_mode = 1

[node name="Holes" type="TextureRect" parent="TransitionRoot/PaperPage"]
layout_mode = 1
anchors_preset = 11
anchor_bottom = 1.0
offset_left = 4.0
offset_top = 30.0
offset_right = 32.0
grow_vertical = 2
mouse_filter = 2
texture = ExtResource("l_hole")
stretch_mode = 1

[node name="Content" type="Control" parent="TransitionRoot/PaperPage"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -170.0
offset_top = -260.0
offset_right = 170.0
offset_bottom = 260.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="Maze" type="Control" parent="{base}"]
layout_mode = 1
anchors_preset = 5
anchor_left = 0.5
anchor_right = 0.5
offset_left = {-W//2}.0
offset_right = {W-W//2}.0
offset_bottom = {H}.0
grow_horizontal = 2
mouse_filter = 2

[node name="Walls" type="TextureRect" parent="{base}/Maze"]
layout_mode = 0
offset_right = {W}.0
offset_bottom = {H}.0
mouse_filter = 2
texture = ExtResource("l_walls")

[node name="Ink" type="Control" parent="{base}/Maze"]
layout_mode = 0
offset_left = {PAD}.0
offset_top = {PAD}.0
offset_right = {PAD}.0
offset_bottom = {PAD}.0
mouse_filter = 2

{segnodes}[node name="Pencil" type="TextureRect" parent="{base}/Maze/Ink"]
layout_mode = 0
offset_right = {PW_}.0
offset_bottom = {PH_}.0
mouse_filter = 2
texture = ExtResource("l_pen")

[node name="Title" type="Label" parent="{base}"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_top = {H+26}.0
offset_bottom = {H+78}.0
grow_horizontal = 2
theme_override_colors/font_color = Color(0.114, 0.31, 0.451, 1)
theme_override_font_sizes/font_size = 38
text = "Đang lật trang"
horizontal_alignment = 1
vertical_alignment = 1

[node name="Sub" type="Label" parent="{base}"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_top = {H+80}.0
offset_bottom = {H+112}.0
grow_horizontal = 2
theme_override_colors/font_color = Color(0.353, 0.451, 0.533, 1)
theme_override_font_sizes/font_size = 20
text = "mê cung đang được vẽ…"
horizontal_alignment = 1
vertical_alignment = 1

[node name="Dots" type="Control" parent="{base}"]
layout_mode = 1
anchors_preset = 5
anchor_left = 0.5
anchor_right = 0.5
offset_left = -30.0
offset_top = {H+130}.0
offset_right = 30.0
offset_bottom = {H+146}.0
grow_horizontal = 2
mouse_filter = 2

''' + ''.join(f'[node name="Dot{d}" type="TextureRect" parent="{base}/Dots"]\nlayout_mode = 0\noffset_right = 16.0\noffset_bottom = 16.0\nmodulate = Color(1, 1, 1, {0.55+d*0.2:.2f})\nmouse_filter = 2\ntexture = ExtResource("l_dot")\n\n' for d in range(3)) + '''[node name="InkCircleDrawer" type="Control" parent="TransitionRoot" unique_id=2094697202]
visible = false
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="FadeRect" type="ColorRect" parent="TransitionRoot" unique_id=364417070]
visible = false
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.965, 0.945, 0.915, 1)

[node name="AnimationPlayer" type="AnimationPlayer" parent="." unique_id=1871871165]
libraries = {
"": SubResource("AnimationLibrary_101rs")
}
autoplay = &"loading"

[connection signal="draw" from="TransitionRoot/InkCircleDrawer" to="." method="_on_ink_draw"]
'''
os.makedirs(f'{ROOT}/scenes',exist_ok=True)
open(f'{ROOT}/scenes/loading.tscn','w',encoding='utf-8').write(scene)
print('segments',len(rows),'tracks',ti,'size',W,H)
