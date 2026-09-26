# -*- coding: utf-8 -*-
"""寻渊图标 · 涟漪变奏（乡土中国 · 差序格局的波纹）
六个涟漪方向的再创作，世系图母题保持居中
"""
import os, math
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.dirname(os.path.abspath(__file__))
S = 4
CANVAS = 432
CX = 216

CREAM = (245, 240, 230)
GREEN = (45, 90, 78)         # 品牌墨绿
GREEN_DEEP = (28, 58, 50)
NIGHT = (22, 36, 31)
GOLD = (217, 185, 120)
GOLD_DEEP = (196, 156, 82)

def glyph(color, size=CANVAS, scale=0.92, w_scale=1.0):
    """标准世代相承图（真透明，可缩放）"""
    full = size*S
    im = Image.new("RGBA", (full, full), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    k = full/CANVAS
    w = round(20*w_scale*k)
    A = (216, 112); B = (136, 270); C = (296, 270)
    Dp = (136, 346); E = (296, 346)
    A_R, A_RING, MID_R, LEAF_R = 48, 20, 32, 20
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
    if scale != 1.0:
        ns = round(size*scale)
        g2 = Image.new("RGBA", (ns, ns), (0, 0, 0, 0))
        g2.paste(g.resize((ns, ns), Image.LANCZOS), (0, 0))
        g = g2
    return g

def paste_center(base, layer):
    base.alpha_composite(layer, ((base.width - layer.width)//2, (base.height - layer.height)//2))
    return base

def ring_layer(draw_fn, size=CANVAS):
    im = Image.new("RGBA", (size*S, size*S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    draw_fn(d, size*S/CANVAS)
    return im.resize((size, size), Image.LANCZOS)

def wobble_ring(d, k, center, radius, width, color, alpha, amp=3.5, phase=0.0, seg=180):
    """手绘感微扰圆环：半径随角度轻微波动，笔画粗细分段变化"""
    cx, cy = center[0]*k, center[1]*k
    pts = []
    for i in range(seg + 1):
        a = 2*math.pi*i/seg
        r = (radius + amp*math.sin(3*a + phase) + amp*0.5*math.cos(5*a)) * k
        pts.append((cx + r*math.cos(a), cy + r*math.sin(a)))
    d.line(pts, fill=color + (alpha,), width=max(2, round(width*k)), joint="curve")

def fade_rings(d, k, center, radii_alphas, width, color):
    for r, a in radii_alphas:
        x, y = center[0]*k, center[1]*k; rr = r*k
        d.ellipse([x-rr, y-rr, x+rr, y+rr], outline=color + (a,), width=round(width*k))

def build(bg, fg, size=CANVAS):
    im = Image.new("RGBA", (size, size), bg)
    im.alpha_composite(fg)
    return im

def mask_circle(icon, size):
    im = icon.resize((size, size), Image.LANCZOS)
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).ellipse([0, 0, size-1, size-1], fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0)); out.paste(im, (0, 0), m); return out

def mask_squircle(icon, size):
    im = icon.resize((size, size), Image.LANCZOS)
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size-1, size-1], radius=round(size*0.28), fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0)); out.paste(im, (0, 0), m); return out

cream = CREAM + (255,)

# ===== A 双源涟漪 · 波纹交汇 =====
def va():
    """两个人各自荡开的涟漪，波纹在中间相遇——连接即交叠"""
    def rings(d, k):
        # 左上源与右下源，各自的波纹圈
        for (cxi, cyi, radii) in ((150, 150, (72, 108, 144)), (282, 282, (72, 108, 144))):
            for r, a in zip(radii, (120, 84, 52)):
                x, y = cxi*k, cyi*k; rr = r*k
                d.ellipse([x-rr, y-rr, x+rr, y+rr], outline=CREAM + (a,), width=round(3.4*k))
    fg = ring_layer(rings)
    g = glyph(cream, scale=0.66)
    paste_center(fg, g)
    return build(GREEN + (255,), fg)

# ===== B 水墨涟漪 · 手绘微扰 =====
def vb():
    """笔意波纹：半径与笔画带微扰，像毛笔在宣纸上荡开"""
    def rings(d, k):
        wobble_ring(d, k, (216, 216), 188, 4.2, CREAM, 46, amp=4.5, phase=0.7)
        wobble_ring(d, k, (216, 216), 146, 5.0, CREAM, 62, amp=3.8, phase=2.1)
        wobble_ring(d, k, (216, 216), 104, 6.0, CREAM, 82, amp=3.0, phase=4.2)
    fg = ring_layer(rings)
    paste_center(fg, glyph(cream, scale=0.92))
    return build(GREEN + (255,), fg)

# ===== C 金秋稻浪 · 鎏金渐层 =====
def vc():
    """波纹由内向外由金渐白——乡土的丰饶"""
    def rings(d, k):
        spec = ((188, 50), (146, 74), (104, 120), (70, 190))
        for i, (r, a) in enumerate(spec):
            t = i / (len(spec) - 1)
            col = tuple(round(GOLD_DEEP[j] + (CREAM[j] - GOLD_DEEP[j]) * t) for j in range(3))
            x, y = 216*k, 216*k; rr = r*k
            d.ellipse([x-rr, y-rr, x+rr, y+rr], outline=col + (a,), width=round(3.6*k))
    fg = ring_layer(rings)
    paste_center(fg, glyph(cream, scale=0.9))
    return build(GREEN_DEEP + (255,), fg)

# ===== D 滴墨成纹 · 一脉入水 =====
def vd():
    """上方一滴墨将坠，涟漪自落点荡开——祖先一滴血，代代荡开去"""
    def drop_and_rings(d, k):
        # 悬滴：小圆 + 短收尖（轮廓式，更轻盈）
        cx, cy, r = 216*k, 92*k, 20*k
        d.ellipse([cx-r, cy-r, cx+r, cy+r], fill=CREAM + (255,))
        apex = (cx, cy - r - 16*k)
        d.polygon([(cx-r*0.62, cy-r*0.62), apex, (cx+r*0.62, cy-r*0.62)], fill=CREAM + (255,))
        # 涟漪自落点荡开（落点在下方水面）
        fade_rings(d, k, (216, 222), ((142, 52), (106, 84), (74, 124)), 3.4, CREAM)
        # 落点小点
        x, y = 216*k, 222*k; rr = 5*k
        d.ellipse([x-rr, y-rr, x+rr, y+rr], fill=CREAM + (200,))
    fg = ring_layer(drop_and_rings)
    g = glyph(cream, scale=0.56)
    paste_center(fg, g)
    return build(GREEN + (255,), fg)

# ===== E 梯田环 · 层层田畴 =====
def ve():
    """断续圆弧如俯瞰梯田，代代开垦"""
    def rings(d, k):
        cx, cy = 216*k, 216*k
        spec = ((186, 46), (144, 66), (102, 92))
        gaps = {186: (0.55, 0.75), 144: (0.30, 0.50), 102: (0.80, 1.00)}  # 缺口弧段
        for r, a in spec:
            g0, g1 = gaps[r]
            for start, end in ((g1, g0 + 2*math.pi),):
                steps = 64
                pts = [(cx + (r*math.cos(start + (end-start)*i/steps))*k,
                        cy + (r*math.sin(start + (end-start)*i/steps))*k) for i in range(steps+1)]
                d.line(pts, fill=CREAM + (a,), width=round(3.4*k), joint="curve")
        # 缺口处补一点：田埂上的「人」
        for r, a in spec:
            ang = gaps[r][0]
            x, y = cx + r*math.cos(ang)*k, cy + r*math.sin(ang)*k
            rr = 4.5*k
            d.ellipse([x-rr, y-rr, x+rr, y+rr], fill=CREAM + (min(255, a+110),))
    fg = ring_layer(rings)
    paste_center(fg, glyph(cream, scale=0.9))
    return build(GREEN + (255,), fg)

# ===== F 声呐涟漪 · 年轮渐隐 =====
def vf():
    """密环渐隐，像树上年轮又像水里长歌"""
    def rings(d, k):
        for i, r in enumerate(range(64, 200, 17)):
            a = max(24, 150 - i*17)
            x, y = 216*k, 216*k; rr = r*k
            d.ellipse([x-rr, y-rr, x+rr, y+rr], outline=CREAM + (a,), width=round(2.6*k))
    fg = ring_layer(rings)
    paste_center(fg, glyph(cream, scale=0.86, w_scale=0.95))
    return build(NIGHT + (255,), fg)

VARIANTS = [
    ("A", va(), "双源涟漪 · 两人的波纹在中间交汇"),
    ("B", vb(), "水墨涟漪 · 笔意微扰如宣纸荡墨"),
    ("C", vc(), "金秋稻浪 · 波纹由金渐白喻丰饶"),
    ("D", vd(), "滴墨成纹 · 一脉入水代代荡开"),
    ("E", ve(), "梯田环 · 俯瞰田畴代代开垦"),
    ("F", vf(), "年轮涟漪 · 密环渐隐如水中长歌"),
]

BIG, SMALL, GAP, LABEL_H = 200, 88, 26, 44
COLS = 4
W = COLS*BIG + (COLS+1)*GAP
H = len(VARIANTS)*(BIG + LABEL_H + GAP) + GAP
sheet = Image.new("RGBA", (W, H), (248, 248, 248, 255))
dd = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 21)
except Exception:
    font = ImageFont.load_default()

for row, (tag, icon, label) in enumerate(VARIANTS):
    icon.convert("RGB").save(os.path.join(OUT, f"ripple_{tag}.png"))
    y0 = GAP + row*(BIG + LABEL_H + GAP)
    tiles = [mask_circle(icon, BIG), mask_squircle(icon, BIG),
             mask_circle(icon, SMALL), mask_squircle(icon, SMALL)]
    for col, tile in enumerate(tiles):
        x0 = GAP + col*(BIG + GAP) + (BIG - tile.width)//2
        sheet.alpha_composite(tile, (x0, y0 + (BIG - tile.height)//2))
    dd.text((GAP + 4, y0 + BIG + 8), f"{tag} · {label}", fill=(60, 60, 60, 255), font=font)

sheet.convert("RGB").save(os.path.join(OUT, "preview_ripple.png"))
print("OK ->", os.path.join(OUT, "preview_ripple.png"))
