# -*- coding: utf-8 -*-
"""「纽带」logo 两方案（设计师正稿）：
方案一「一脉一笔」：一条不断线画出两个节点——环出、S 行、盘入，血脉即笔画。
方案二「环环相扣」：双环互扣，纽带字面义。
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
SW = 13  # 笔画宽


def unit(ang):
    return (math.cos(math.radians(ang)), math.sin(math.radians(ang)))


def draw_poly(d, pts, color, w=SW, taper_end=None):
    n = len(pts)
    for i, (x, y) in enumerate(pts):
        r = w / 2
        if taper_end is not None and i > n * 0.85:
            k = (i - n * 0.85) / (n * 0.15)
            r = w / 2 * (1 - 0.45 * k)
        d.ellipse([x - r, y - r, x + r, y + r], fill=color + (255,))


def one_stroke(color, ripple_alphas=(36, 28, 20)):
    """方案一：一条不断线 = 环A(留开口) + S 弧 + 盘入B 的螺旋。"""
    im = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # 涟漪
    for p in (A, B):
        for r, a in zip(RINGS, ripple_alphas):
            d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r],
                      outline=color + (a,), width=5)
    c = color + (255,)
    ang = math.degrees(math.atan2(B[1] - A[1], B[0] - A[0]))  # ≈49°
    # 1) 环 A：290°，开口朝 B（±35°）
    ring_pts = []
    for i in range(0, 291, 2):
        th = math.radians(ang + 35 + i)
        ring_pts.append((A[0] + DOTR * math.cos(th), A[1] + DOTR * math.sin(th)))
    draw_poly(d, ring_pts, color)
    tail_cap(ring_pts[-1], d, color)
    # 2) S 弧：从环尾切出，绕到 B 的左上方进入
    ux, uy = unit(ang)
    nx, ny = -uy, ux
    e0 = (A[0] + DOTR * unit(ang + 35)[0], A[1] + DOTR * unit(ang + 35)[1])
    e1 = (e0[0] + nx * 52 + ux * 30, e0[1] + ny * 52 + uy * 30)
    e2 = (B[0] - ux * 95 - nx * 58, B[1] - uy * 95 - ny * 58)
    e3 = (B[0] - ux * 26 + nx * 10, B[1] - uy * 26 + ny * 10)  # 螺旋入口
    pts = []
    for i in range(0, 61):
        t = i / 60
        # 两次贝塞尔近似 S
        if t < 0.5:
            tt = t / 0.5
            x = (1 - tt) ** 2 * e0[0] + 2 * (1 - tt) * tt * e1[0] + tt ** 2 * ((e0[3] if False else e2[0]) * 0 + (e0[0] + e2[0]) / 2)
            y = (1 - tt) ** 2 * e0[1] + 2 * (1 - tt) * tt * e1[1] + tt ** 2 * ((e0[1] + e2[1]) / 2)
        else:
            tt = (t - 0.5) / 0.5
            m = ((e0[0] + e2[0]) / 2, (e0[1] + e2[1]) / 2)
            x = (1 - tt) ** 2 * m[0] + 2 * (1 - tt) * tt * e2[0] + tt ** 2 * e3[0]
            y = (1 - tt) ** 2 * m[1] + 2 * (1 - tt) * tt * e2[1] + tt ** 2 * e3[1]
        pts.append((x, y))
    draw_poly(d, pts, color)
    # 3) 盘入 B：从入口角向内卷 1.5 圈
    start_ang = math.degrees(math.atan2(e3[1] - B[1], e3[0] - B[0]))
    sp = []
    for i in range(0, 181, 2):
        t = i / 180
        th = math.radians(start_ang - 360 * 1.5 * t)
        r = 26 * (1 - t) + 7
        sp.append((B[0] + r * math.cos(th), B[1] + r * math.sin(th)))
    draw_poly(d, sp, color, taper_end=True)
    # 螺旋芯
    d.ellipse([B[0] - 8, B[1] - 8, B[0] + 8, B[1] + 8], fill=c)
    # 涟漪的 A 环位不画实心环（一笔即环）
    return im


DOTR = 38


def tail_cap(p, d, color):
    d.ellipse([p[0] - SW / 2, p[1] - SW / 2, p[0] + SW / 2, p[1] + SW / 2], fill=color + (255,))


def chain(color, ripple_alphas=(36, 28, 20)):
    """方案二：双环互扣（纽带字面义）。两个斜环在 AB 中段相扣，一上一下。"""
    im = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for p in (A, B):
        for r, a in zip(RINGS, ripple_alphas):
            d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r],
                      outline=color + (a,), width=5)
    ang = math.atan2(B[1] - A[1], B[0] - A[0])
    mx, my = (A[0] + B[0]) / 2, (A[1] + B[1]) / 2
    ux, uy = math.cos(ang), math.sin(ang)
    nx, ny = -uy, ux

    def link(cx, cy, tilt):
        """斜椭圆环，参数采样。tilt: 椭圆长轴相对 AB 的偏角(度)。"""
        pts = []
        rot = math.radians(tilt)
        rx, ry = 42, 26
        for i in range(0, 360, 3):
            th = math.radians(i)
            ex, ey = rx * math.cos(th), ry * math.sin(th)
            x = cx + ex * math.cos(rot) - ey * math.sin(rot)
            y = cy + ex * math.sin(rot) + ey * math.cos(rot)
            pts.append((x, y))
        draw_poly(d, pts, color, w=12)

    c1 = (mx - ux * 26 - nx * 14, my - uy * 26 - ny * 14)
    c2 = (mx + ux * 26 + nx * 14, my + uy * 26 + ny * 14)
    # 连接臂：A 环 → 链环1，链环2 → B 点（短线）
    draw_poly(d, [(A[0] + 38 * ux, A[1] + 38 * uy), (c1[0] - 30 * ux + 10 * nx, c1[1] - 30 * uy + 10 * ny)], color, w=11)
    draw_poly(d, [(c2[0] + 30 * ux, c2[1] + 30 * uy), (B[0] - 30 * ux, B[1] - 30 * uy)], color, w=11)
    link(c1[0], c1[1], -28)
    link(c2[0], c2[1], 24)
    # 互扣：擦掉环2与环1交叠处一小段（形成上下穿插的错觉），再把环1该处重绘
    # 简化：在环2上叠一个小缺口（透明）
    gap = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    dg = ImageDraw.Draw(gap)
    dg.line([(c1[0] + 18 * ux, c1[1] + 18 * uy), (c1[0] + 34 * ux + 12 * nx, c1[1] + 34 * uy + 12 * ny)], fill=(0, 0, 0, 255), width=15)
    im.putalpha(Image.composite(Image.new("L", (CANVAS, CANVAS), 0),
                                im.getchannel("A"), gap.getchannel("A")))
    # 重新在缺口上画环1的一段（表示环1压在环2上）
    d2 = ImageDraw.Draw(im)
    seg = []
    for i in range(140, 221, 2):
        th = math.radians(i)
        ex, ey = 42 * math.cos(th), 26 * math.sin(th)
        rot = math.radians(-28)
        x = c1[0] + ex * math.cos(rot) - ey * math.sin(rot)
        y = c1[1] + ex * math.sin(rot) + ey * math.cos(rot)
        seg.append((x, y))
    draw_poly(d2, seg, color, w=12)
    # B 实心 / A 空心环
    d2.ellipse([B[0] - 30, B[1] - 30, B[0] + 30, B[1] + 30], fill=color + (255,))
    d2.ellipse([A[0] - 38, A[1] - 38, A[0] + 38, A[1] + 38], fill=color + (255,))
    hole = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    dh = ImageDraw.Draw(hole)
    dh.ellipse([A[0] - 22, A[1] - 22, A[0] + 22, A[1] + 22], fill=(0, 0, 0, 255))
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
    for icon in (one_stroke(CREAM), chain(CREAM)):
        big = Image.new("RGBA", (CANVAS, CANVAS), GREEN + (255,))
        big.alpha_composite(icon)
        tiles.append(circle_mask(big, 250))
        tiles.append(circle_mask(big, 96))
        tiles.append(circle_mask(big, 64))
    GAP = 30
    W = sum(t.width for t in tiles) + GAP * (len(tiles) + 1)
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
