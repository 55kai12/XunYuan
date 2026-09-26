# -*- coding: utf-8 -*-
"""连接的另三种表达（不用线）：波纹相交 / 相牵弧 / 点串。只出预览。"""
import math
import os
from PIL import Image, ImageDraw

OUT = os.path.dirname(os.path.abspath(__file__))

CREAM = (245, 240, 230)
GREEN = (45, 90, 78)
CANVAS = 432
A = (150, 138)
B = (292, 300)
DOT_R = 38
RING_W = 16
LEAF_R = 30
RINGS = (95, 140, 185)


def base_glyph(color, ripple_alphas=(36, 28, 20), extra=None, skip_ripple_a=False):
    """涟漪 + 两点（A 空心 B 实心）。extra(im_draw, color) 画连接元素。"""
    im = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for p in (A, B):
        for r, a in zip(RINGS, ripple_alphas):
            d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r],
                      outline=color + (a,), width=5)
    if extra:
        extra(d, color)
    # B 实心
    d.ellipse([B[0] - LEAF_R, B[1] - LEAF_R, B[0] + LEAF_R, B[1] + LEAF_R], fill=color + (255,))
    # A 空心环
    d.ellipse([A[0] - DOT_R, A[1] - DOT_R, A[0] + DOT_R, A[1] + DOT_R], fill=color + (255,))
    hole = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    dh = ImageDraw.Draw(hole)
    dh.ellipse([A[0] - DOT_R + RING_W, A[1] - DOT_R + RING_W,
                A[0] + DOT_R - RING_W, A[1] + DOT_R - RING_W], fill=(0, 0, 0, 255))
    im.putalpha(Image.composite(Image.new("L", (CANVAS, CANVAS), 0),
                                im.getchannel("A"), hole.getchannel("A")))
    return im


def ang(p0, p1):
    return math.degrees(math.atan2(p1[1] - p0[1], p1[0] - p0[0]))


def cap(d, center, r, color):
    d.ellipse([center[0] - r, center[1] - r, center[0] + r, center[1] + r], fill=color + (255,))


# ---- B 相牵弧：两点各伸出一道弧，末端圆头，中间留一息 ----
def arms(d, color):
    aAB = ang(A, B)
    aBA = ang(B, A)
    R = 100
    SPAN = 34  # 半张角
    # PIL arc 角度顺时针（y 向下），正常数学角直接给起止即可（start<end）
    d.arc([A[0] - R, A[1] - R, A[0] + R, A[1] + R],
          start=aAB - SPAN, end=aAB + SPAN, fill=color + (255,), width=13)
    d.arc([B[0] - R, B[1] - R, B[0] + R, B[1] + R],
          start=aBA - SPAN, end=aBA + SPAN, fill=color + (255,), width=13)
    # 弧端圆头
    for (p0, a0) in ((A, aAB), (B, aBA)):
        for e in (a0 - SPAN, a0 + SPAN):
            ex = p0[0] + R * math.cos(math.radians(e))
            ey = p0[1] + R * math.sin(math.radians(e))
            cap(d, (ex, ey), 7.5, color)


# ---- C 点串：三点渐小，涟漪上的一串足迹 ----
def dotted(d, color):
    for t, r in ((0.32, 13), (0.52, 9), (0.70, 6)):
        x = A[0] + (B[0] - A[0]) * t
        y = A[1] + (B[1] - A[1]) * t
        d.ellipse([x - r, y - r, x + r, y + r], fill=color + (255,))


def circle_mask(icon, size):
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).ellipse([0, 0, size, size], fill=255)
    out = icon.resize((size, size), Image.LANCZOS).convert("RGBA")
    out.putalpha(m)
    return out


def main():
    variants = [
        ("A 波纹相交", base_glyph(CREAM)),                       # 无连接物，纯涟漪交叠
        ("B 相牵弧", base_glyph(CREAM, extra=arms)),
        ("C 点串", base_glyph(CREAM, extra=dotted)),
    ]
    tiles = []
    for _, icon in variants:
        big = Image.new("RGBA", (CANVAS, CANVAS), GREEN + (255,))
        big.alpha_composite(icon)
        tiles.append(circle_mask(big, 230))
        tiles.append(circle_mask(big, 96))
    GAP = 28
    W = sum(t.width for t in tiles) + GAP * (len(tiles) + 1)
    H = 230 + 2 * GAP
    sheet = Image.new("RGBA", (W, H), (250, 250, 250, 255))
    x = GAP
    for t in tiles:
        sheet.alpha_composite(t, (x, GAP + (230 - t.height) // 2))
        x += t.width + GAP
    sheet.convert("RGB").save(os.path.join(OUT, "preview_connect_expr.png"))
    print("OK")


if __name__ == "__main__":
    main()
