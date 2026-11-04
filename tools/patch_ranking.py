#!/usr/bin/env python3
"""Tăng chữ người chơi x2 ở màn Ranking. Dùng: python3 patch_ranking.py SRC_DIR OUT_DIR (SRC_DIR = gốc dự án)"""
import re,sys,os
SRC,OUT=sys.argv[1:3]
def rd(p): return open(os.path.join(SRC,p),encoding='utf-8').read()
def wr(p,s):
    q=os.path.join(OUT,p); os.makedirs(os.path.dirname(q),exist_ok=True); open(q,'w',encoding='utf-8').write(s)
def setp(s,header_re,props):
    m=re.search(header_re,s); assert m,header_re
    e=s.find('\n[',m.end()); e=len(s) if e<0 else e+1
    blk=s[m.start():e]; lines=blk.split('\n'); hdr=lines[0]; body=lines[1:]
    for k,v in props.items():
        for i,l in enumerate(body):
            if l.startswith(k+' = '): body[i]=f'{k} = {v}'; break
        else: body.insert(0,f'{k} = {v}')
    return s[:m.start()]+hdr+'\n'+'\n'.join(body)+s[e:]
FS='theme_override_font_sizes/font_size'
def layout(path,land):
    s=rd(path)
    P='Sheet/Body/'+('LeftCol/' if land else '')
    def node(n,par): return r'\[node name="%s" type="[A-Za-z]+" parent="%s"[^\]]*\]'%(n,re.escape(par))
    G=P+'Podium/Gold'; 
    s=setp(s,node('Gold',P+'Podium'),{'custom_minimum_size':'Vector2(0, 156)'})
    s=setp(s,node('Trophy',G),{'offset_top':'44','offset_bottom':'120'})
    s=setp(s,node('Name',G),{'offset_top':'8','offset_bottom':'56','offset_left':'104','offset_right':'-12',FS:'40'})
    s=setp(s,node('Record',G),{'offset_top':'58','offset_bottom':'90','offset_left':'104','offset_right':'-12',FS:'24'})
    s=setp(s,node('Points',G),{'anchor_left':'0','offset_left':'104','offset_right':'-12','offset_top':'94','offset_bottom':'146',FS:'36'})
    for who in ('Silver','Bronze'):
        D=P+'Podium/Duo/'+who
        s=setp(s,node(who,P+'Podium/Duo'),{'custom_minimum_size':'Vector2(0, 170)'})
        s=setp(s,node('Name',D),{'offset_top':'58','offset_bottom':'94',FS:'26'})
        s=setp(s,node('Record',D),{'offset_top':'96','offset_bottom':'126',FS:'22'})
        s=setp(s,node('Points',D),{'offset_top':'128','offset_bottom':'160',FS:'22'})
    M=P+'MyRank'
    s=setp(s,node('MyRank',P[:-1]),{'custom_minimum_size':'Vector2(0, 156)'})
    s=setp(s,node('Rank',M),{'offset_left':'6','offset_right':'104','offset_top':'0','offset_bottom':'150',FS:'44'})
    s=setp(s,node('Flag',M),{'offset_left':'108','offset_top':'18','offset_right':'138','offset_bottom':'38'})
    s=setp(s,node('Name',M),{'offset_left':'146','offset_top':'6','offset_right':'-12','offset_bottom':'44',FS:'28'})
    s=setp(s,node('Sub',M),{'offset_left':'108','offset_top':'46','offset_right':'-12','offset_bottom':'76',FS:'22'})
    s=setp(s,node('Record',M),{'anchor_left':'0','offset_left':'108','offset_top':'80','offset_right':'-12','offset_bottom':'112','horizontal_alignment':'0',FS:'26'})
    s=setp(s,node('Points',M),{'anchor_left':'0','offset_left':'108','offset_top':'114','offset_right':'-12','offset_bottom':'146','horizontal_alignment':'0',FS:'26'})
    wr(path,s)
layout('scenes/layout/portrait/ranking.tscn',False); layout('scenes/layout/landscape/ranking.tscn',True)
# --- hàng danh sách: 2 dòng (tên / tầng + điểm)
r=rd('nodes/ranking/rank_row.tscn')
r=r.replace('custom_minimum_size = Vector2(0, 50)','custom_minimum_size = Vector2(0, 88)').replace('offset_bottom = 50.0','offset_bottom = 88.0',1)
r=r.replace('name_label = NodePath("Body/Name")','name_label = NodePath("Body/Info/Name")').replace('record_label = NodePath("Body/Stats/Record")','record_label = NodePath("Body/Info/Line/Record")').replace('points_label = NodePath("Body/Stats/Points")','points_label = NodePath("Body/Info/Line/Points")')
i=r.index('[node name="Rank"'); 
head=r[:i]
body='''[node name="Rank" type="Label" parent="Body"]
custom_minimum_size = Vector2(64, 0)
layout_mode = 2
theme_type_variation = &"RankRowIndex"
theme_override_colors/font_color = Color(0.4784, 0.549, 0.6275, 1)
theme_override_font_sizes/font_size = 26
text = "4"
horizontal_alignment = 1
vertical_alignment = 1
mouse_filter = 2

[node name="Flag" type="TextureRect" parent="Body"]
custom_minimum_size = Vector2(30, 20)
layout_mode = 2
size_flags_vertical = 4
mouse_filter = 2
expand_mode = 1
stretch_mode = 5

[node name="Info" type="VBoxContainer" parent="Body"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 4
mouse_filter = 2
theme_override_constants/separation = 0

[node name="Name" type="Label" parent="Body/Info"]
layout_mode = 2
theme_type_variation = &"RankRowName"
theme_override_colors/font_color = Color(0.1686, 0.2392, 0.3137, 1)
theme_override_font_sizes/font_size = 26
text = "Alex_Maze"
vertical_alignment = 1
text_overrun_behavior = 3
mouse_filter = 2

[node name="Line" type="HBoxContainer" parent="Body/Info"]
layout_mode = 2
mouse_filter = 2

[node name="Record" type="Label" parent="Body/Info/Line"]
layout_mode = 2
size_flags_horizontal = 3
theme_type_variation = &"RankRowRecord"
theme_override_colors/font_color = Color(0.1686, 0.2392, 0.3137, 1)
theme_override_font_sizes/font_size = 22
text = "TẦNG 25"
vertical_alignment = 1
text_overrun_behavior = 3
mouse_filter = 2

[node name="Points" type="Label" parent="Body/Info/Line"]
layout_mode = 2
theme_type_variation = &"RankRowPoints"
theme_override_colors/font_color = Color(0.3569, 0.4314, 0.5098, 1)
theme_override_font_sizes/font_size = 22
text = "16,005 ĐIỂM"
horizontal_alignment = 2
vertical_alignment = 1
mouse_filter = 2
'''
wr('nodes/ranking/rank_row.tscn',head+body)
print('ok')
