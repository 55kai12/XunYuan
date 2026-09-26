# -*- coding: utf-8 -*-
"""寻渊图标生成：人与人的连接（世代相承图）
三代纵向世系：空心圆环(祖) → 两条干线 → 实心圆(第二代) → 各一支 → 小实心圆(第三代)
4x 超采样抗锯齿，输出 432 主画布 + 真机合成预览（圆/方圆角双蒙版 + 小尺寸）
"""
import os
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.dirname(os.path.abspath(__file__))
S = 4                      # 超采样倍数
CANVAS = 432               # 主画布（与现有 xxhdpi/xxxhdpi 前景一致，待确认后按需缩放）
CX = 864                   # 4x 画布中心

# ---- 几何（432 空间坐标，全部落在圆角蒙版安全圆 r≈198 内）----
A = (216, 112); A_R = 48; A_RING = 20         # 祖：空心环
B = (136, 270); C = (296, 270); MID_R = 32
D = (136, 346); E = (296, 346); LEAF_R = 20
STROKE = 20                                   # 线宽 = 环宽

def draw_glyph(color, size=CANVAS):
    """按指定颜色绘制世代相承图，返回 RGBA 图（size x size，真透明底）"""
    im = Image.new("RGBA", (size * S, size * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    k = size * S / CANVAS  # 坐标缩放系数（432*S 布局坐标 / 432）

    def pt(p): return (p[0] * k, p[1] * k)
    def r_of(v): return v * k
    w = round(STROKE * k)

    def line_round(a, b):
        d.line([pt(a), pt(b)], fill=color, width=w)
        r = w // 2
        for p in (a, b):
            d.ellipse([pt(p)[0]-r, pt(p)[1]-r, pt(p)[0]+r, pt(p)[1]+r], fill=color)

    def dot(center, radius):
        x, y = pt(center); r = r_of(radius)
        d.ellipse([x-r, y-r, x+r, y+r], fill=color)

    def ring(center, radius, width):
        x, y = pt(center); r = r_of(radius); rw = round(width * k)
        d.ellipse([x-r, y-r, x+r, y+r], outline=color, width=rw)

    # 线（先画，节点压在上面）
    a_bottom = (A[0], A[1] + A_R - A_RING // 2)          # 环下缘
    line_round(a_bottom, (B[0], B[1] - MID_R))           # 祖 → 左支
    line_round(a_bottom, (C[0], C[1] - MID_R))           # 祖 → 右支
    line_round((B[0], B[1] + MID_R), (D[0], D[1] - LEAF_R))  # 左支延代
    line_round((C[0], C[1] + MID_R), (E[0], E[1] - LEAF_R))  # 右支延代
    # 节点
    dot(B, MID_R); dot(C, MID_R); dot(D, LEAF_R); dot(E, LEAF_R)
    ring(A, A_R, A_RING)

    return im.resize((size, size), Image.LANCZOS)

# ---- 变体（底色, 图形色, 说明）----
CREAM = (245, 240, 230, 255)
GREEN_DEEP = (47, 93, 82, 255)      # 墨绿（品牌深）
TEAL = (123, 168, 160, 255)         # 现用青瓷 #7BA8A0
INK = (28, 43, 39, 255)             # 近黑墨

VARIANTS = [
    ("A", GREEN_DEEP, CREAM, "墨绿底·米白图形（推荐）"),
    ("B", CREAM, GREEN_DEEP, "米白底·墨绿图形"),
    ("C", TEAL, CREAM, "青瓷底·米白图形（延续现背景）"),
    ("D", INK, CREAM, "近黑墨底·米白图形"),
]

def composite(bg, fg):
    """真机合成：背景铺满，前景缩到中心 72/108"""
    inner = round(CANVAS * 72 / 108)
    fg2 = fg.resize((inner, inner), Image.LANCZOS)
    icon = Image.new("RGBA", (CANVAS, CANVAS), bg)
    icon.alpha_composite(fg2, ((CANVAS - inner) // 2, (CANVAS - inner) // 2))
    return icon

def circle_mask(icon, size):
    im = icon.resize((size, size), Image.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, size - 1, size - 1], fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out

def squircle_mask(icon, size, radius_ratio=0.28):
    im = icon.resize((size, size), Image.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, size - 1, size - 1], radius=round(size * radius_ratio), fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out

# ---- 预览拼版 ----
BIG, SMALL, GAP, LABEL_H = 220, 96, 28, 44
COLS = 4  # 圆大 / 方圆大 / 圆小 / 方圆小
W = COLS * BIG + (COLS + 1) * GAP
H = len(VARIANTS) * (BIG + LABEL_H + GAP) + GAP
sheet = Image.new("RGBA", (W, H), (250, 250, 250, 255))
try:
    font = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 22)
except Exception:
    font = ImageFont.load_default()
dd = ImageDraw.Draw(sheet)

for row, (tag, bg, ink, label) in enumerate(VARIANTS):
    fg = draw_glyph(ink)
    icon = composite(bg, fg)
    y0 = GAP + row * (BIG + LABEL_H + GAP)
    tiles = [
        circle_mask(icon, BIG),
        squircle_mask(icon, BIG),
        circle_mask(icon, SMALL),
        squircle_mask(icon, SMALL),
    ]
    for col, tile in enumerate(tiles):
        x0 = GAP + col * (BIG + GAP) + (BIG - tile.width) // 2
        sheet.alpha_composite(tile, (x0, y0 + (BIG - tile.height) // 2))
    dd.text((GAP + 4, y0 + BIG + 8),
            f"{tag} · {label}  bg#{bg[0]:02X}{bg[1]:02X}{bg[2]:02X}",
            fill=(60, 60, 60, 255), font=font)
    # 保存各变体合成图备用
    icon.convert("RGB").save(os.path.join(OUT, f"icon_{tag}.png"))

# 前景层（推荐变体）与 monochrome 一并输出待用
draw_glyph(CREAM).save(os.path.join(OUT, "fg_green_bg.png"))
draw_glyph(GREEN_DEEP).save(os.path.join(OUT, "fg_cream_bg.png"))
draw_glyph((255, 255, 255, 255)).save(os.path.join(OUT, "mono.png"))

sheet.convert("RGB").save(os.path.join(OUT, "preview.png"))
print("OK preview ->", os.path.join(OUT, "preview.png"))
