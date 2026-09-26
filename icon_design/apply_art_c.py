# -*- coding: utf-8 -*-
"""应用 C 变体「一笔连枝」到 res/（底色维持品牌墨绿 #2D5A4E）"""
import os
from PIL import Image, ImageDraw

SRC = os.path.dirname(os.path.abspath(__file__))
RES = os.path.join(os.path.dirname(SRC), "android", "app", "src", "main", "res")
S = 4
CANVAS = 432
A = (216, 112); A_R = 48; A_RING = 20
B = (136, 270); C = (296, 270); MID_R = 32
D = (136, 346); E = (296, 346); LEAF_R = 20
STROKE = 20
BG = (45, 90, 78, 255)      # #2D5A4E
CREAM = (245, 240, 230, 255)

def glyph(color, size=CANVAS):
    im = Image.new("RGBA", (size*S, size*S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    k = size*S/CANVAS
    w = round(STROKE*k)
    def pt(p): return (p[0]*k, p[1]*k)
    def dot(center, radius):
        x, y = pt(center); r = radius*k
        d.ellipse([x-r, y-r, x+r, y+r], fill=color)
    def ring(center, radius, width):
        x, y = pt(center); r = radius*k
        d.ellipse([x-r, y-r, x+r, y+r], outline=color, width=round(width*k))
    a_bottom = pt((A[0], A[1] + A_R - A_RING//2))
    path = [pt((D[0], D[1])), pt((D[0], B[1])), a_bottom, pt((C[0], B[1])), pt((C[0], C[1]))]
    d.line(path, fill=color, width=w, joint="curve")
    r = w // 2
    for p in (path[0], path[-1]):
        d.ellipse([p[0]-r, p[1]-r, p[0]+r, p[1]+r], fill=color)
    dot(D, LEAF_R); dot(B, MID_R); dot(C, MID_R)
    ring(A, A_R, A_RING)
    return im.resize((size, size), Image.LANCZOS)

fg_master = glyph(CREAM)                      # 米白一笔连枝
mono_master = glyph((255, 255, 255, 255))     # monochrome 白形

DENSITIES = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}

def composite_flat(size):
    inner = round(size*72/108)
    f = fg_master.resize((inner, inner), Image.LANCZOS)
    icon = Image.new("RGBA", (size, size), BG)
    icon.alpha_composite(f, ((size-inner)//2, (size-inner)//2))
    return icon.convert("RGB")

for dpi, size in DENSITIES.items():
    fg_master.resize((size, size), Image.LANCZOS).save(
        os.path.join(RES, f"drawable-{dpi}", "ic_launcher_foreground.png"))
    mono_master.resize((size, size), Image.LANCZOS).save(
        os.path.join(RES, f"drawable-{dpi}", "ic_launcher_monochrome.png"))
    composite_flat(LEGACY[dpi]).save(os.path.join(RES, f"mipmap-{dpi}", "ic_launcher.png"))

for dpi, size in DENSITIES.items():
    fg = Image.open(os.path.join(RES, f"drawable-{dpi}", "ic_launcher_foreground.png"))
    leg = Image.open(os.path.join(RES, f"mipmap-{dpi}", "ic_launcher.png"))
    assert fg.mode == "RGBA" and fg.getpixel((0, 0))[3] == 0, f"fg {dpi} not transparent"
    assert leg.getpixel((0, 0)) == (45, 90, 78) and leg.size == (LEGACY[dpi],)*2, f"legacy {dpi} bad"
print("ALL OK: one-stroke foreground applied")
