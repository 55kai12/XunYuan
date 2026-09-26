# -*- coding: utf-8 -*-
"""应用 B 变体「涟漪」到 res/（底色维持品牌墨绿 #2D5A4E）
涟漪同心环 + 0.92 缩放世系图；monochrome 用强化的白形（环 alpha 提高）
"""
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
WHITE = (255, 255, 255, 255)

RIPPLES = ((188, 40), (146, 52), (104, 66))   # (半径, alpha) —— 彩色前景用
RIPPLES_MONO = ((188, 210), (146, 225), (104, 240))  # monochrome 强化

def base_glyph(color, size=CANVAS, w_scale=1.0):
    """标准世代相承图（真透明）"""
    im = Image.new("RGBA", (size*S, size*S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    k = size*S/CANVAS
    w = round(STROKE*w_scale*k)
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
    line_round((B[0], B[1] + MID_R), (D[0], D[1] - LEAF_R))
    line_round((C[0], C[1] + MID_R), (E[0], E[1] - LEAF_R))
    dot(B, MID_R); dot(C, MID_R); dot(D, LEAF_R); dot(E, LEAF_R)
    ring(A, A_R, A_RING)
    return im.resize((size, size), Image.LANCZOS)

def fg_layer(cream, white, ripple_spec, ring_color):
    """涟漪环 + 0.92 缩放世系图，返回 432 真透明前景"""
    im = Image.new("RGBA", (CANVAS*S, CANVAS*S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    k = CANVAS*S/CANVAS
    for r, a in ripple_spec:
        x, y = 216*k, 216*k; rr = r*k
        d.ellipse([x-rr, y-rr, x+rr, y+rr], outline=ring_color + (a,), width=round(3.2*k))
    layer = im.resize((CANVAS, CANVAS), Image.LANCZOS)
    g = base_glyph(cream, w_scale=0.94)
    g = g.resize((round(CANVAS*0.92), round(CANVAS*0.92)), Image.LANCZOS)
    layer.alpha_composite(g, ((CANVAS - g.width)//2, (CANVAS - g.height)//2))
    return layer

fg_master = fg_layer(CREAM, WHITE, RIPPLES, CREAM[:3])
mono_master = fg_layer(WHITE, WHITE, RIPPLES_MONO, WHITE[:3])

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
print("ALL OK: ripple foreground applied")
