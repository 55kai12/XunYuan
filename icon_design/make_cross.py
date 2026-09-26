# -*- coding: utf-8 -*-
"""交错连接三方案：双弧交错 / 三弧编织 / 交错加结。只出预览。"""
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
    mx, my = (A[0] + B[0]) / 2, (A[1] + B[1]) / 2
    dx, dy = B[0] - A[0], B[1] - A[1]
    L = math.hypot(dx, dy)
    return (mx - dy / L * bow, my + dx / L * bow)


def strand(d, ctrl, color, r0=11, r1=7):
    """一条弧形笔画，圆头收笔。"""
    n = 60
    for i in range(n + 1):
        t = i / n
        p = bez(t, A, B, ctrl)
        r = r0 + (r1 - r0) * t
        d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=color + (255,))


def base_glyph(color, ripple_alphas=(36, 28, 20), extra=None):
    im = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for p in (A, B):
        for r, a in zip(RINGS, ripple_alphas):
            d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r],
                      outline=color + (a,), width=5)
    if extra:
        extra(d, color)
    d.ellipse([B[0] - LEAF_R, B[1] - LEAF_R, B[0] + LEAF_R, B[1] + LEAF_R], fill=color + (255,))
    d.ellipse([A[0] - DOT_R, A[1] - DOT_R, A[0] + DOT_R, A[1] + DOT_R], fill=color + (255,))
    hole = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    dh = ImageDraw.Draw(hole)
    dh.ellipse([A[0] - DOT_R + RING_W, A[1] - DOT_R + RING_W,
                A[0] + DOT_R - RING_W, A[1] + DOT_R - RING_W], fill=(0, 0, 0, 255))
    im.putalpha(Image.composite(Image.new("L", (CANVAS, CANVAS), 0),
                                im.getchannel("A"), hole.getchannel("A")))
    return im


# ---- V1 双弧交错：两笔反向弯曲，中部一交 ----
def cross2(d, color):
    strand(d, ctrl_point(-46), color)
    strand(d, ctrl_point(46), color)


# ---- V4 S 形编织：两条 S 线互相缠绕，中部真交叉 ----
def _quad_path(d, p0, p1, ctrl, color, r0, r1):
    n = 40
    for i in range(n + 1):
        t = i / n
        # quadratic bezier 逐点
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * ctrl[0] + t ** 2 * p1[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * ctrl[1] + t ** 2 * p1[1]
        r = r0 + (r1 - r0) * t
        d.ellipse([x - r, y - r, x + r, y + r], fill=color + (255,))


def s_weave(d, color):
    mx, my = (A[0] + B[0]) / 2, (A[1] + B[1]) / 2
    dx, dy = B[0] - A[0], B[1] - A[1]
    L = math.hypot(dx, dy)
    nx, ny = -dy / L, dx / L
    # 前后段的弯向控制点（法线偏移，符号相反 → S 形）
    q1a = (A[0] + dx * 0.25 + nx * 42, A[1] + dy * 0.25 + ny * 42)
    q1b = (A[0] + dx * 0.75 + nx * 42, A[1] + dy * 0.75 + ny * 42)
    s1a = (A[0] + dx * 0.25 - nx * 42, A[1] + dy * 0.25 - ny * 42)
    s1b = (A[0] + dx * 0.75 - nx * 42, A[1] + dy * 0.75 - ny * 42)
    # 线 1：先向左弯再向右弯
    _quad_path(d, A, (mx, my), q1a, color, 11, 9)
    _quad_path(d, (mx, my), B, q1b, color, 9, 7)
    # 线 2：镜像
    _quad_path(d, A, (mx, my), s1a, color, 11, 9)
    _quad_path(d, (mx, my), B, s1b, color, 9, 7)


# ---- V3 双弧交错 + 交区中心小结 ----
def cross2_knot(d, color):
    cross2(d, color)
    ca, cb = ctrl_point(-46), ctrl_point(46)
    pa = bez(0.5, A, B, ca)
    pb = bez(0.5, A, B, cb)
    cx, cy = (pa[0] + pb[0]) / 2, (pa[1] + pb[1]) / 2
    d.ellipse([cx - 12, cy - 12, cx + 12, cy + 12], fill=color + (255,))


def circle_mask(icon, size):
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).ellipse([0, 0, size, size], fill=255)
    out = icon.resize((size, size), Image.LANCZOS).convert("RGBA")
    out.putalpha(m)
    return out


def main():
    variants = [
        ("V1 双弧交错", cross2),
        ("V4 S形编织", s_weave),
        ("V3 交错加结", cross2_knot),
    ]
    tiles = []
    for _, fn in variants:
        icon = base_glyph(CREAM, extra=fn)
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
    sheet.convert("RGB").save(os.path.join(OUT, "preview_cross.png"))
    print("OK")


if __name__ == "__main__":
    main()
