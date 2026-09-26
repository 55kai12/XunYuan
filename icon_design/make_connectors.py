# -*- coding: utf-8 -*-
"""连接线艺术化三方案：弧线渐细 / 渐隐 / 呼吸断线。只出预览，不动 res。"""
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


def bez(t, p0, p1, ctrl):
    x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * ctrl[0] + t ** 2 * p1[0]
    y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * ctrl[1] + t ** 2 * p1[1]
    return (x, y)


def ctrl_point(bow):
    """AB 中点沿法线偏移 bow 像素的控制点。"""
    mx, my = (A[0] + B[0]) / 2, (A[1] + B[1]) / 2
    dx, dy = B[0] - A[0], B[1] - A[1]
    L = math.hypot(dx, dy)
    nx, ny = -dy / L, dx / L
    return (mx + nx * bow, my + ny * bow)


def draw_connector(im, variant, color):
    d = ImageDraw.Draw(im)
    c = color
    ctrl = ctrl_point(-46)  # 向左上弯，弧度克制
    n = 72
    for i in range(n + 1):
        t = i / n
        p = bez(t, A, B, ctrl)
        if variant == "v3" and 0.44 < t < 0.56:
            continue  # 气口
        if variant == "v1":
            r = 13 - 7 * t          # 13 → 6 渐细
            a = 255 - 35 * t        # 基本实
        elif variant == "v2":
            r = 13 - 6 * t          # 13 → 7 渐细
            a = 255 - 135 * t       # 255 → 120 渐隐
        else:  # v3
            r = 12 - 5 * t
            a = 255 - 25 * t
        d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=c + (int(a),))
    if variant == "v3":
        mp = bez(0.5, A, B, ctrl)
        d.ellipse([mp[0] - 8, mp[1] - 8, mp[0] + 8, mp[1] + 8], fill=c + (255,))
    return im


def glyph(variant, color, ripple_alphas=(36, 28, 20)):
    im = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = color + (255,)
    # 涟漪
    for p in (A, B):
        for r, a in zip(RINGS, ripple_alphas):
            d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r],
                      outline=color + (a,), width=5)
    # 连接线（艺术化）
    draw_connector(im, variant, color)
    # B 实心
    d.ellipse([B[0] - LEAF_R, B[1] - LEAF_R, B[0] + LEAF_R, B[1] + LEAF_R], fill=c)
    # A 空心环
    d.ellipse([A[0] - DOT_R, A[1] - DOT_R, A[0] + DOT_R, A[1] + DOT_R], fill=c)
    hole = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    dh = ImageDraw.Draw(hole)
    dh.ellipse([A[0] - DOT_R + RING_W, A[1] - DOT_R + RING_W,
                A[0] + DOT_R - RING_W, A[1] + DOT_R - RING_W], fill=(0, 0, 0, 255))
    im.putalpha(Image.composite(Image.new("L", (CANVAS, CANVAS), 0),
                                im.getchannel("A"), hole.getchannel("A")))
    return im


def circle_mask(icon, size):
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).ellipse([0, 0, size, size], fill=255)
    out = icon.resize((size, size), Image.LANCZOS).convert("RGBA")
    out.putalpha(m)
    return out


def main():
    tiles = []
    for v in ("v1", "v2", "v3"):
        icon = Image.new("RGBA", (CANVAS, CANVAS), GREEN + (255,))
        icon.alpha_composite(glyph(v, CREAM))
        tiles.append(circle_mask(icon, 230))
        tiles.append(circle_mask(icon, 96))  # 每方案配一张小图
    GAP = 28
    W = sum(t.width for t in tiles) + GAP * (len(tiles) + 1)
    H = 230 + 2 * GAP
    sheet = Image.new("RGBA", (W, H), (250, 250, 250, 255))
    x = GAP
    for t in tiles:
        sheet.alpha_composite(t, (x, GAP + (230 - t.height) // 2))
        x += t.width + GAP
    sheet.convert("RGB").save(os.path.join(OUT, "preview_connectors.png"))
    print("OK")


if __name__ == "__main__":
    main()
