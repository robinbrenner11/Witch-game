"""Innenraum-Vorschau Unterschlupf: Raum + Möbel + Hexe, links ohne, rechts mit Nachtlicht.

Aufruf (aus dem Projektordner, nach shelter.py):
    python docs/art/nature_generator/shelter_preview.py docs/art/vorschau/vorschau_unterschlupf_innen_2x.png docs/art/vorschau/vorschau_unterschlupf_nacht_2x.gif
Die Positionen entsprechen denen in ASSETS.md (Abschnitt Unterschlupf).
"""
import math, sys
from pathlib import Path
from PIL import Image
R=str(Path(__file__).resolve().parents[3])+'/'
S=R+'assets/environment/shelter/'
def L(n): return Image.open(n).convert('RGBA')
room=L(S+'shelter_room.png')
def fr(name,w,i=0):
    im=L(S+name+'.png'); n=im.width//w; i%=n; return im.crop((i*w,0,i*w+w,im.height))
lect=L(R+'assets/environment/props/lectern.png')
witch=L(R+'assets/characters/witch_idle.png').crop((0,0,32,64))
# (name, frame_w, foot_x, foot_y, frame_index_fn)
def objects(t):
    return [
      ('rug',96,212,196,0,'floor'),
      ('shelter_doormat',40,160,232,0,'floor'),
      ('shelter_broom',16,300,150,0,None),
      ('shelter_firewood',28,222,106,0,None),
      ('shelter_shelf',64,74,104,0,None),
      ('shelter_stove',32,252,100,int(t*8),None),
      ('shelter_armchair',40,226,186,0,None),
      ('shelter_books',16,252,190,0,None),
      ('shelter_chest',32,58,170,0,None),
      ('shelter_candles',16,122,104,int(t*6),None),
      ('lectern',0,160,128,0,None),
      ('witch',0,128,216,0,None),
    ]
def render(t, night):
    c=Image.new('RGBA',room.size,(14,10,20,255)); c.alpha_composite(room)
    glows=[]
    objs=objects(t)
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import shadows as SH
    for n,w,fx,fy,i,layer in objs:
        if layer!='floor': SH.draw_shadow(c, n, fx, fy)
    for n,w,fx,fy,i,layer in sorted(objs,key=lambda o:(o[5]!='floor',o[3])):
        if n=='rug': im=L(S+'shelter_rug.png')
        elif n=='shelter_doormat': im=L(S+'shelter_doormat.png')
        elif n=='lectern': im=lect
        elif n=='witch': im=witch
        else: im=fr(n,w,i)
        c.alpha_composite(im,(fx-im.width//2,fy-im.height+1))
        gp=S+n+'_glow.png'
        import os
        if os.path.exists(gp):
            g=L(gp); n2=g.width//w; g=g.crop(((i%n2)*w,0,(i%n2)*w+w,g.height)); glows.append((g,fx-w//2,fy-g.height+1))
    # hängende Gläser (Fußpunkt = Aufhängung oben)
    jars=[(128,29),(168,28)]
    for k,(jx,jy) in enumerate(jars):
        im=fr('shelter_jar',16,int(t*4)+k); c.alpha_composite(im,(jx-8,jy))
        g=fr('shelter_jar_glow',16,int(t*4)+k); glows.append((g,jx-8,jy))
    if not night: return c
    N=(0x66/255,0x5C/255,0x8F/255)
    W,H=c.size
    lum=[[list(N) for _ in range(W)] for _ in range(H)]
    rnd=L(R+'assets/effects/lights/light_round_128.png')
    beam=L(R+'assets/effects/lights/light_moonbeam.png')
    def add(tex,ox,oy,col,en):
        p=tex.load()
        for y in range(tex.height):
            for x in range(tex.width):
                X,Y=ox+x,oy+y
                if 0<=X<W and 0<=Y<H:
                    a=p[x,y][3]/255*en
                    if a>0.01:
                        for q in range(3): lum[Y][X][q]+=col[q]*a
    flick=1+0.1*math.sin(t*13)
    add(beam,104-20,30,(0.6,0.7,1.0),0.9)
    add(rnd.resize((140,140)),252-70,84-70,(1,.62,.32),1.1*flick)
    add(rnd.resize((90,90)),122-45,92-45,(1,.71,.4),0.8*flick)
    for jx,jy in jars: add(rnd.resize((80,80)),jx-40,jy+22-40,(1,.78,.45),0.75)
    px=c.load()
    for y in range(H):
        for x in range(W):
            r,g,b,a=px[x,y]; Lm=lum[y][x]; px[x,y]=(min(255,int(r*Lm[0])),min(255,int(g*Lm[1])),min(255,int(b*Lm[2])),a)
    for g,gx,gy in glows: c.alpha_composite(g,(gx,gy))
    return c
if __name__=='__main__':
    a=render(0,False); b=render(0,True)
    out=Image.new('RGBA',(a.width*2+8,a.height),(14,10,20,255)); out.alpha_composite(a,(0,0)); out.alpha_composite(b,(a.width+8,0))
    out.resize((out.width*2,out.height*2),Image.NEAREST).save(sys.argv[1])
    if len(sys.argv)>2:
        fr_=[render(k/8,True).resize((a.width*2,a.height*2),Image.NEAREST).convert('RGB') for k in range(16)]
        fr_[0].save(sys.argv[2],save_all=True,append_images=fr_[1:],duration=125,loop=0)
