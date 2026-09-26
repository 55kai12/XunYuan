# -*- coding: utf-8 -*-
"""按用户手绘构图落盘图标前景：左上祖先节点 → 两条线向右下发散至两个后代节点。
前景（真透明）+ monochrome（白色同形）+ 旧版整图（绿底合成）。
"""
import math
import os
from PIL import Image, ImageDraw

SRC = os.path.dirname(os.path.abspath(__file__))
RES = os.path.join(os.path.dirname(SRC), "android", "app", "src", "main", "res")
CREAM = (245, 240, 230)
GREEN = (0, 98, 204)          # 品牌蓝 #0062CC（对齐应用 S1 tint，深色模式渐变深端）
RIPPLE = (255, 255, 255)      # 涟漪提白
CANVAS = 432

# ---- 构图（432 坐标，全部落在安全圆内）----
A = (146, 132)   # 祖先（空心环）
A_R = 38         # 环半径
A_RING = 16      # 环宽
B = (302, 226)   # 后代 1（实心）
C = (256, 318)   # 后代 2（实心）
LEAF_R = 30
STROKE = 16      # 连接线宽


def glyph(color, ripple_alphas=(72, 58, 44)):
    """在 432 透明画布上画手绘构图。color 为 (r,g,b)。
    ripple_alphas：自祖先环荡开的背景涟漪三层透明度（monochrome 传增强值）。
    涟漪固定用白色（RIPPLE），不随主体色。"""
    im = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = color + (255,)

    # 背景涟漪：自祖先环向外荡开三层（石子入水，波纹从此源起）
    for r, a in zip((115, 170, 225), ripple_alphas):
        d.ellipse([A[0] - r, A[1] - r, A[0] + r, A[1] + r],
                  outline=RIPPLE + (a,), width=11)

    # 连接线（圆头端帽，从祖先中心到后代中心，端点被节点盖住）
    d.line([A, B], fill=c, width=STROKE)
    d.line([A, C], fill=c, width=STROKE)
    for p in (A, B, C):
        d.ellipse([p[0] - STROKE // 2, p[1] - STROKE // 2,
                   p[0] + STROKE // 2, p[1] + STROKE // 2], fill=c)

    # 后代：实心圆
    for p in (B, C):
        d.ellipse([p[0] - LEAF_R, p[1] - LEAF_R,
                   p[0] + LEAF_R, p[1] + LEAF_R], fill=c)

    # 祖先：空心环（挖空中心）
    ring = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    dr = ImageDraw.Draw(ring)
    dr.ellipse([A[0] - A_R, A[1] - A_R, A[0] + A_R, A[1] + A_R], fill=c)
    dr.ellipse([A[0] - A_R + A_RING, A[1] - A_R + A_RING,
                A[0] + A_R - A_RING, A[1] + A_R - A_RING], fill=(0, 0, 0, 0))
    # 用环自身 alpha 抠掉连线中心
    im.alpha_composite(ring)
    hole = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    dh = ImageDraw.Draw(hole)
    dh.ellipse([A[0] - A_R + A_RING, A[1] - A_R + A_RING,
                A[0] + A_R - A_RING, A[1] + A_R - A_RING], fill=(0, 0, 0, 255))
    im.putalpha(Image.composite(Image.new("L", (CANVAS, CANVAS), 0),
                                im.getchannel("A"),
                                hole.getchannel("A")))
    return im


def composite_flat(size):
    """旧版整图：绿底 + 前景居中（前景占 78%，符合 48dp 基准的安全比例）。"""
    fg = glyph(CREAM).resize((int(size * 0.78),) * 2, Image.LANCZOS)
    out = Image.new("RGBA", (size, size), GREEN + (255,))
    off = (size - fg.width) // 2
    out.alpha_composite(fg, (off, off))
    return out.convert("RGB")


def shrink_to_canvas(master, scale=0.72):
    """前景整体等比缩小后居中回 432 画布。
    启动器蒙版只显示 108dp 画布中央约 2/3 区域，前景画满会显大
    （2026-09-25 用户真机反馈），缩到 72% 留出呼吸边。"""
    s = int(CANVAS * scale)
    small = master.resize((s, s), Image.LANCZOS)
    out = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    out.alpha_composite(small, ((CANVAS - s) // 2, (CANVAS - s) // 2))
    return out


def main(apply=False):
    fg_master = shrink_to_canvas(glyph(CREAM))                       # 彩色前景（米白 + 低alpha涟漪）
    mono_master = shrink_to_canvas(glyph((255, 255, 255), ripple_alphas=(150, 120, 92)))  # monochrome 涟漪反向增强

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
    sheet.convert("RGB").save(os.path.join(os.path.dirname(__file__), "preview_sketch.png"))

    if not apply:
        print("PREVIEW ONLY (run with --apply to write resources)")
        return

    # 落盘：前景/monochrome 108dp 基准（108/162/216/324/432），旧版 48dp 基准（48/72/96/144/192）
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

    # 校验：前景真透明 + 旧版底色正确
    for dpi, s in FG.items():
        im = Image.open(os.path.join(RES, f"drawable-{dpi}", "ic_launcher_foreground.png"))
        assert im.mode == "RGBA" and im.getpixel((0, 0))[3] == 0, f"fg {dpi} not transparent"
    for dpi, s in LEG.items():
        im = Image.open(os.path.join(RES, f"mipmap-{dpi}", "ic_launcher.png"))
        assert im.getpixel((0, 0)) == GREEN, f"legacy {dpi} wrong bg {im.getpixel((0, 0))}"
    print("APPLIED + VERIFIED")


if __name__ == "__main__":
    import sys
    main(apply="--apply" in sys.argv)
