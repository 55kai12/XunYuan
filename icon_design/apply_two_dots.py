# -*- coding: utf-8 -*-
"""图标定稿：两个点连成一条线，两点各自荡开涟漪（双源）。
前景（真透明）+ monochrome（白色同形、涟漪增强）+ 旧版整图（绿底合成）。
"""
import os
from PIL import Image, ImageDraw

SRC = os.path.dirname(os.path.abspath(__file__))
RES = os.path.join(os.path.dirname(SRC), "android", "app", "src", "main", "res")
CREAM = (245, 240, 230)
GREEN = (45, 90, 78)          # 品牌墨绿 #2D5A4E
CANVAS = 432

# ---- 构图（432 坐标）----
A = (150, 138)    # 点 1（空心环，尺寸对齐 preview_sketch）
B = (292, 300)    # 点 2（实心）
DOT_R = 38        # 空心环半径（同 apply_sketch 的 A_R）
RING_W = 16       # 空心环宽
LEAF_R = 30       # 实心点半径（同 apply_sketch 的 LEAF_R）
STROKE = 16       # 连接线宽
RINGS = (95, 140, 185)  # 每个点的涟漪（三层）


def glyph(color, ripple_alphas=(36, 28, 20)):
    """一空一实两点一线 + 各自三层涟漪。ripple_alphas：monochrome 传增强值。"""
    im = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = color + (255,)

    # 涟漪（先画，垫在点和线下面）：两点各三层，由内向外渐淡
    for p in (A, B):
        for r, a in zip(RINGS, ripple_alphas):
            d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r],
                      outline=color + (a,), width=5)

    # 连接线（圆头端帽，端点被点盖住）
    d.line([A, B], fill=c, width=STROKE)
    for p in (A, B):
        d.ellipse([p[0] - STROKE // 2, p[1] - STROKE // 2,
                   p[0] + STROKE // 2, p[1] + STROKE // 2], fill=c)

    # B：实心点
    d.ellipse([B[0] - LEAF_R, B[1] - LEAF_R, B[0] + LEAF_R, B[1] + LEAF_R], fill=c)

    # A：空心环（实心圆 + 挖空中心，盖住线端）
    d.ellipse([A[0] - DOT_R, A[1] - DOT_R, A[0] + DOT_R, A[1] + DOT_R], fill=c)
    hole = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    dh = ImageDraw.Draw(hole)
    dh.ellipse([A[0] - DOT_R + RING_W, A[1] - DOT_R + RING_W,
                A[0] + DOT_R - RING_W, A[1] + DOT_R - RING_W], fill=(0, 0, 0, 255))
    im.putalpha(Image.composite(Image.new("L", (CANVAS, CANVAS), 0),
                                im.getchannel("A"), hole.getchannel("A")))
    return im


def composite_flat(size):
    """旧版整图：绿底 + 前景居中（78%）。"""
    fg = glyph(CREAM).resize((int(size * 0.78),) * 2, Image.LANCZOS)
    out = Image.new("RGBA", (size, size), GREEN + (255,))
    off = (size - fg.width) // 2
    out.alpha_composite(fg, (off, off))
    return out.convert("RGB")


def main():
    fg_master = glyph(CREAM)                                        # 彩色前景
    mono_master = glyph((255, 255, 255), ripple_alphas=(150, 118, 88))  # monochrome 增强

    # 预览：圆/方圆角蒙版 + 96px 小图
    def circle_mask(icon, size):
        m = Image.new("L", (size, size), 0)
        ImageDraw.Draw(m).ellipse([0, 0, size, size], fill=255)
        out = icon.resize((size, size), Image.LANCZOS).convert("RGBA")
        out.putalpha(m)
        return out

    def squircle_mask(icon, size):
        m = Image.new("L", (size, size), 0)
        ImageDraw.Draw(m).rounded_rectangle([0, 0, size - 1, size - 1],
                                            radius=int(size * 0.24), fill=255)
        out = icon.resize((size, size), Image.LANCZOS).convert("RGBA")
        out.putalpha(m)
        return out

    icon = Image.new("RGBA", (CANVAS, CANVAS), GREEN + (255,))
    icon.alpha_composite(fg_master)
    tiles = [circle_mask(icon, 220), squircle_mask(icon, 220),
             circle_mask(icon, 96), squircle_mask(icon, 96)]
    GAP = 24
    W = sum(t.width for t in tiles) + GAP * 5
    sheet = Image.new("RGBA", (W, 220 + 2 * GAP), (250, 250, 250, 255))
    x = GAP
    for t in tiles:
        sheet.alpha_composite(t, (x, GAP))
        x += t.width + GAP
    sheet.convert("RGB").save(os.path.join(os.path.dirname(__file__), "preview_two_dots.png"))

    # 落盘：前景/monochrome 108dp 基准，旧版 48dp 基准
    FG = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
    LEG = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for dpi, s in FG.items():
        fg_master.resize((s, s), Image.LANCZOS).save(
            os.path.join(RES, f"drawable-{dpi}", "ic_launcher_foreground.png"))
        mono_master.resize((s, s), Image.LANCZOS).save(
            os.path.join(RES, f"drawable-{dpi}", "ic_launcher_monochrome.png"))
    for dpi, s in LEG.items():
        composite_flat(s).save(
            os.path.join(RES, f"mipmap-{dpi}", "ic_launcher.png"))

    # 校验：前景真透明（四角）+ 旧版底色正确
    for dpi, s in FG.items():
        im = Image.open(os.path.join(RES, f"drawable-{dpi}", "ic_launcher_foreground.png"))
        assert im.mode == "RGBA" and im.getpixel((0, 0))[3] == 0, f"fg {dpi} not transparent"
        assert im.getpixel((s - 1, 0))[3] == 0 and im.getpixel((0, s - 1))[3] == 0 \
            and im.getpixel((s - 1, s - 1))[3] == 0, f"fg {dpi} corner dirty"
    for dpi, s in LEG.items():
        im = Image.open(os.path.join(RES, f"mipmap-{dpi}", "ic_launcher.png"))
        assert im.getpixel((0, 0)) == GREEN, f"legacy {dpi} wrong bg {im.getpixel((0, 0))}"
    print("APPLIED + VERIFIED")


if __name__ == "__main__":
    main()
