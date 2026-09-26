# -*- coding: utf-8 -*-
"""寻渊图标 · 艺术变体批次（人与人的连接）
六种艺术化处理，几何母题沿用「世代相承」世系图
"""
import os, math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUT = os.path.dirname(os.path.abspath(__file__))
S = 4
CANVAS = 432
FONT_PATH = os.path.join(os.path.dirname(OUT), "assets", "fonts", "LXGWWenKai.ttf")

# ---- 母题几何（432 空间）----
A = (216, 112); A_R = 48; A_RING = 20
B = (136, 270); C = (296, 270); MID_R = 32
D = (136, 346); E = (296, 346); LEAF_R = 20
STROKE = 20

CREAM = (245, 240, 230)
GREEN = (45, 90, 78)        # 品牌墨绿
GREEN_DEEP = (28, 58, 50)   # 深墨绿
NIGHT = (22, 36, 31)        # 夜绿
GOLD = (217, 185, 120)      # 鎏金

def painter(d, color, k, w_scale=1.0, alpha=None):
    """返回一组以指定颜色/线宽作画的闭包"""
    fill = color + ((alpha,) if alpha is not None else ())
    w = round(STROKE * w_scale * k)

    def line_round(a, b):
        pa = (a[0]*k, a[1]*k); pb = (b[0]*k, b[1]*k)
        d.line([pa, pb], fill=fill, width=w)
        r = w // 2
        for p in (pa, pb):
            d.ellipse([p[0]-r, p[1]-r, p[0]+r, p[1]+r], fill=fill)

    def dot(center, radius):
        x, y = center[0]*k, center[1]*k; r = radius*k
        d.ellipse([x-r, y-r, x+r, y+r], fill=fill)

    def ring(center, radius, width):
        x, y = center[0]*k, center[1]*k; r = radius*k
        d.ellipse([x-r, y-r, x+r, y+r], outline=fill, width=round(width*k))

    def poly(pts, width):
        """圆角折线（一笔连枝用）"""
        scaled = [(p[0]*k, p[1]*k) for p in pts]
        d.line(scaled, fill=fill, width=width, joint="curve")
        r = width // 2
        for p in (scaled[0], scaled[-1]):
            d.ellipse([p[0]-r, p[1]-r, p[0]+r, p[1]+r], fill=fill)

    def circle_outline(center, radius, width, a=None):
        f = color + ((a,) if a is not None else ())
        x, y = center[0]*k, center[1]*k; r = radius*k
        d.ellipse([x-r, y-r, x+r, y+r], outline=f, width=round(width*k))

    return line_round, dot, ring, poly, circle_outline

def base_glyph(size, color, w_scale=1.0):
    """标准世代相承图（RGBA 真透明）"""
    im = Image.new("RGBA", (size*S, size*S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    k = size*S/CANVAS
    lr, dot, ring, _, _ = painter(d, color, k, w_scale)
    a_bottom = (A[0], A[1] + A_R - A_RING//2)
    lr(a_bottom, (B[0], B[1] - MID_R)); lr(a_bottom, (C[0], C[1] - MID_R))
    lr((B[0], B[1] + MID_R), (D[0], D[1] - LEAF_R))
    lr((C[0], C[1] + MID_R), (E[0], E[1] - LEAF_R))
    dot(B, MID_R); dot(C, MID_R); dot(D, LEAF_R); dot(E, LEAF_R)
    ring(A, A_R, A_RING)
    return im.resize((size, size), Image.LANCZOS)

def build(bg, fg_layer, size=CANVAS):
    im = Image.new("RGBA", (size, size), bg)
    im.alpha_composite(fg_layer)
    return im

def composite_flat(bg, fg, size=CANVAS):
    inner = round(size*72/108)
    f = fg.resize((inner, inner), Image.LANCZOS)
    icon = Image.new("RGBA", (size, size), bg)
    icon.alpha_composite(f, ((size-inner)//2, (size-inner)//2))
    return icon

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

# ===== V1 「寻」水印 · 世系 =====
def v1():
    size = CANVAS
    im = Image.new("RGBA", (size*S, size*S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    font = ImageFont.truetype(FONT_PATH, round(size*S*0.80))
    bbox = d.textbbox((0, 0), "寻", font=font)
    tw, th = bbox[2]-bbox[0], bbox[3]-bbox[1]
    d.text(((size*S-tw)/2 - bbox[0], (size*S-th)/2 - bbox[1]), "寻",
           font=font, fill=CREAM + (36,))
    wm = im.resize((size, size), Image.LANCZOS)
    wm.alpha_composite(base_glyph(size, cream, 0.94))
    return build(GREEN + (255,), wm)

# ===== V2 涟漪 · 代代相传 =====
def v2():
    size = CANVAS
    im = Image.new("RGBA", (size*S, size*S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    k = size*S/CANVAS
    _, _, _, _, co = painter(d, CREAM, k)
    for r, a in ((188, 40), (146, 52), (104, 66)):
        co((216, 216), r, 3.2, a=a)
    ripples = im.resize((size, size), Image.LANCZOS)
    ripples.alpha_composite(base_glyph(size, cream, 0.92))
    return build(GREEN + (255,), ripples)

# ===== V3 一笔连枝 · 一脉相承 =====
def v3():
    size = CANVAS
    im = Image.new("RGBA", (size*S, size*S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    k = size*S/CANVAS
    _, dot, ring, poly, _ = painter(d, CREAM, k)
    a_bottom = (A[0], A[1] + A_R - A_RING//2)
    poly([(D[0], D[1]), (D[0], B[1]), a_bottom, (C[0], B[1]), (C[0], C[1])], round(20*k))
    dot(D, LEAF_R); dot(C, MID_R)
    ring(A, A_R, A_RING)
    # B 处被折线圆角覆盖，补节点感
    dot(B, MID_R)
    glyph = im.resize((size, size), Image.LANCZOS)
    return build(GREEN + (255,), glyph)

# ===== V4 鎏金祖环 =====
def v4():
    fg = base_glyph(CANVAS, cream)
    im = Image.new("RGBA", (CANVAS*S, CANVAS*S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    k = CANVAS*S/CANVAS
    x, y = A[0]*k, A[1]*k; r = A_R*k
    d.ellipse([x-r, y-r, x+r, y+r], outline=GOLD + (255,), width=round(A_RING*k))
    gold_ring = im.resize((CANVAS, CANVAS), Image.LANCZOS)
    fg.alpha_composite(gold_ring)
    return build(GREEN_DEEP + (255,), fg)

# ===== V5 夜绿发光 =====
def v5():
    fg = base_glyph(CANVAS, cream)
    def boost(im, factor):
        r, g, b, a = im.split()
        a = a.point(lambda v: min(255, int(v * factor)))
        return Image.merge("RGBA", (r, g, b, a))
    glow = boost(fg.filter(ImageFilter.GaussianBlur(16)), 2.2)
    glow2 = boost(fg.filter(ImageFilter.GaussianBlur(38)), 1.6)
    out = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    out.alpha_composite(glow2)
    out.alpha_composite(glow)
    out.alpha_composite(fg)
    return build(NIGHT + (255,), out)

# ===== V6 墨分五色 =====
def v6():
    size = CANVAS
    ink = GREEN + (255,)
    im = Image.new("RGBA", (size*S, size*S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    k = size*S/CANVAS
    # 干线 + 一代（浓）
    lr, dot, ring, _, _ = painter(d, GREEN, k)
    a_bottom = (A[0], A[1] + A_R - A_RING//2)
    lr(a_bottom, (B[0], B[1] - MID_R)); lr(a_bottom, (C[0], C[1] - MID_R))
    dot(B, MID_R); dot(C, MID_R); ring(A, A_R, A_RING)
    # 二代支线 + 叶（淡）
    lr2, dot2, _, _, _ = painter(d, GREEN, k, alpha=150)
    lr2((B[0], B[1] + MID_R), (D[0], D[1] - LEAF_R))
    lr2((C[0], C[1] + MID_R), (E[0], E[1] - LEAF_R))
    dot2(D, LEAF_R); dot2(E, LEAF_R)
    glyph = im.resize((size, size), Image.LANCZOS)
    return build(CREAM + (255,), glyph)

VARIANTS = [
    ("A", v1(), "「寻」水印 · 世系图叠于大字之上"),
    ("B", v2(), "涟漪 · 同心环层层传代"),
    ("C", v3(), "一笔连枝 · 一脉相承单线贯通"),
    ("D", v4(), "鎏金祖环 · 深绿底金环点睛"),
    ("E", v5(), "夜绿发光 · 柔光晕染"),
    ("F", v6(), "墨分五色 · 米白底浓淡墨阶"),
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
    icon.convert("RGB").save(os.path.join(OUT, f"art_{tag}.png"))
    y0 = GAP + row*(BIG + LABEL_H + GAP)
    tiles = [mask_circle(icon, BIG), mask_squircle(icon, BIG),
             mask_circle(icon, SMALL), mask_squircle(icon, SMALL)]
    for col, tile in enumerate(tiles):
        x0 = GAP + col*(BIG + GAP) + (BIG - tile.width)//2
        sheet.alpha_composite(tile, (x0, y0 + (BIG - tile.height)//2))
    dd.text((GAP + 4, y0 + BIG + 8), f"{tag} · {label}", fill=(60, 60, 60, 255), font=font)

sheet.convert("RGB").save(os.path.join(OUT, "preview_art.png"))
print("OK ->", os.path.join(OUT, "preview_art.png"))
