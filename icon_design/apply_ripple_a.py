# -*- coding: utf-8 -*-
"""应用 A 变体「双源涟漪」到 res/（底色维持品牌墨绿 #2D5A4E）
两个涟漪源（左上/右下）各自荡开三层波纹，世系图 0.66 居中
monochrome：波纹 alpha 强化，保证主题染色下可见
"""
import os
from PIL import Image, ImageDraw

SRC = os.path.dirname(os.path.abspath(__file__))
RES = os.path.join(os.path.dirname(SRC), "android", "app", "src", "main", "res")
S = 4
CANVAS = 432
BG = (45, 90, 78, 255)      # #2D5A4E
CREAM = (245, 240, 230, 255)
WHITE = (255, 255, 255, 255)

# 世系图几何（432 空间）
A = (216, 112); B = (136, 270); C = (296, 270)
Dp = (136, 346); E = (296, 346)
A_R, A_RING, MID_R, LEAF_R = 48, 20, 32, 20

def glyph(color, size, scale):
    full = size*S
    im = Image.new("RGBA", (full, full), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    k = full/CANVAS
    w = round(20*k)
    def pt(p): return (p[0]*k, p[1]*k)
    def line_round(a, b):
        d.line([pt(a), pt(b)], fill=color, width=w)
        r = w//2
        for p in (a, b):
            x, y = pt(p)
            d.ellipse([x-r, y-r, x+r, y+r], fill=color)
    def dot(center, radius):
        x, y = pt(center); r = radius*k
        d.ellipse([x-r, y-r, x+r, y+r], fill=color)
    def ring(center, radius, width):
        x, y = pt(center); r = radius*k
        d.ellipse([x-r, y-r, x+r, y+r], outline=color, width=round(width*k))
    a_bottom = (A[0], A[1] + A_R - A_RING//2)
    line_round(a_bottom, (B[0], B[1] - MID_R))
    line_round(a_bottom, (C[0], C[1] - MID_R))
    line_round((B[0], B[1] + MID_R), (Dp[0], Dp[1] - LEAF_R))
    line_round((C[0], C[1] + MID_R), (E[0], E[1] - LEAF_R))
    dot(B, MID_R); dot(C, MID_R); dot(Dp, LEAF_R); dot(E, LEAF_R)
    ring(A, A_R, A_RING)
    g = im.resize((size, size), Image.LANCZOS)
    ns = round(size*scale)
    g2 = Image.new("RGBA", (ns, ns), (0, 0, 0, 0))
    g2.paste(g.resize((ns, ns), Image.LANCZOS), (0, 0))
    return g2

def fg_layer(ring_color, ring_alphas, glyph_color):
    im = Image.new("RGBA", (CANVAS*S, CANVAS*S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    k = CANVAS*S/CANVAS
    for (cxi, cyi) in ((150, 150), (282, 282)):
        for r, a in zip((72, 108, 144), ring_alphas):
            x, y = cxi*k, cyi*k; rr = r*k
            d.ellipse([x-rr, y-rr, x+rr, y+rr], outline=ring_color + (a,), width=round(3.4*k))
    layer = im.resize((CANVAS, CANVAS), Image.LANCZOS)
    g = glyph(glyph_color, CANVAS, 0.66)
    layer.alpha_composite(g, ((CANVAS - g.width)//2, (CANVAS - g.height)//2))
    return layer

fg_master = fg_layer(CREAM[:3], (120, 84, 52), CREAM)
mono_master = fg_layer(WHITE[:3], (215, 175, 140), WHITE)

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
print("ALL OK: dual-source ripple foreground applied")
