# -*- coding: utf-8 -*-
"""「纽带」正稿：两条等宽缎带互相拧转，交点处一上一下（穿插缺口）。
只出预览。"""
import math
import os
from PIL import Image, ImageDraw

OUT = os.path.dirname(os.path.abspath(__file__))

CREAM = (245, 240, 230)
GREEN = (45, 90, 78)
CANVAS = 432
A = (150, 138)
B = (292, 300)
RINGS = (95, 140, 185)
SW = 12  # 缎带宽


def quad_pts(p0, p1, ctrl, n=48):
    pts = []
    for i in range(n + 1):
        t = i / n
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * ctrl[0] + t ** 2 * p1[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * ctrl[1] + t ** 2 * p1[1]
        pts.append((x, y))
    return pts


def stroke(d, pts, color, w=SW):
    r = w / 2
    for (x, y) in pts:
        d.ellipse([x - r, y - r, x + r, y + r], fill=color + (255,))


def bond(color, ripple_alphas=(36, 28, 20)):
    im = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # 涟漪
    for p in (A, B):
        for r, a in zip(RINGS, ripple_alphas):
            d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r],
                      outline=color + (a,), width=5)

    mx, my = (A[0] + B[0]) / 2, (A[1] + B[1]) / 2
    dx, dy = B[0] - A[0], B[1] - A[1]
    L = math.hypot(dx, dy)
    nx, ny = -dy / L, dx / L
    AMP = 40  # 拧转幅度

    # 缎带路径：A → 中点 → B，前半段弯向一侧、后半段弯向另一侧（S 形）
    c1a = (A[0] + dx * 0.25 + nx * AMP, A[1] + dy * 0.25 + ny * AMP)
    c1b = (A[0] + dx * 0.75 + nx * AMP, A[1] + dy * 0.75 + ny * AMP)
    c2a = (A[0] + dx * 0.25 - nx * AMP, A[1] + dy * 0.25 - ny * AMP)
    c2b = (A[0] + dx * 0.75 - nx * AMP, A[1] + dy * 0.75 - ny * AMP)

    under = quad_pts(A, (mx, my), c2a) + quad_pts((mx, my), B, c2b)[1:]
    # 1) 先画下层缎带
    stroke(d, under, color)
    # 2) 在交点处挖缺口（下层缎带断开 → 上层穿过的视觉）
    hole = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    ImageDraw.Draw(hole).ellipse([mx - 17, my - 17, mx + 17, my + 17], fill=(0, 0, 0, 255))
    im.putalpha(Image.composite(Image.new("L", (CANVAS, CANVAS), 0),
                                im.getchannel("A"), hole.getchannel("A")))
    # 3) 上层缎带（完整，压在缺口上）
    d = ImageDraw.Draw(im)
    over = quad_pts(A, (mx, my), c1a) + quad_pts((mx, my), B, c1b)[1:]
    stroke(d, over, color)

    # 节点：A 空心环 / B 实心
    d.ellipse([B[0] - 30, B[1] - 30, B[0] + 30, B[1] + 30], fill=color + (255,))
    d.ellipse([A[0] - 38, A[1] - 38, A[0] + 38, A[1] + 38], fill=color + (255,))
    hole2 = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    ImageDraw.Draw(hole2).ellipse([A[0] - 22, A[1] - 22, A[0] + 22, A[1] + 22], fill=(0, 0, 0, 255))
    im.putalpha(Image.composite(Image.new("L", (CANVAS, CANVAS), 0),
                                im.getchannel("A"), hole2.getchannel("A")))
    return im


def circle_mask(icon, size):
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).ellipse([0, 0, size, size], fill=255)
    out = icon.resize((size, size), Image.LANCZOS).convert("RGBA")
    out.putalpha(m)
    return out


def main():
    icon = bond(CREAM)
    tiles = []
    for s in (250, 96, 64):
        big = Image.new("RGBA", (CANVAS, CANVAS), GREEN + (255,))
        big.alpha_composite(icon)
        tiles.append(circle_mask(big, s))
        tiles.append(circle_mask(big, s)) if False else None
    # 大图一张 + 小图两张
    tiles = [circle_mask(Image.alpha_composite(
        Image.new("RGBA", (CANVAS, CANVAS), GREEN + (255,)), icon), 250),
        circle_mask(Image.alpha_composite(
            Image.new("RGBA", (CANVAS, CANVAS), GREEN + (255,)), icon), 96),
        circle_mask(Image.alpha_composite(
            Image.new("RGBA", (CANVAS, CANVAS), GREEN + (255,)), icon), 64)]
    GAP = 30
    W = sum(t.width for t in tiles) + GAP * 4
    H = 250 + 2 * GAP
    sheet = Image.new("RGBA", (W, H), (250, 250, 250, 255))
    x = GAP
    for t in tiles:
        sheet.alpha_composite(t, (x, GAP + (250 - t.height) // 2))
        x += t.width + GAP
    sheet.convert("RGB").save(os.path.join(OUT, "preview_bond.png"))
    print("OK")


if __name__ == "__main__":
    main()
