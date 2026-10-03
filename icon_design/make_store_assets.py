# -*- coding: utf-8 -*-
"""生成上架 / 开源用素材：
  docs/icon-512.png         商店图标（512×512，Play 与国内商店通用尺寸）
  docs/feature-graphic.png  商店头图（1024×500）
复用 apply_sketch 的涟漪构图，保证与启动图标同源。
"""
import os

from PIL import Image, ImageDraw, ImageFont

import apply_sketch as sk

HERE = os.path.dirname(os.path.abspath(__file__))
DOCS = os.path.join(os.path.dirname(HERE), "docs")

# 文案字体（中文）：等线；找不到则退回项目自带楷体
FONT_CANDIDATES = [
    r"C:\Windows\Fonts\Deng.ttf",
    r"C:\Windows\Fonts\simhei.ttf",
    os.path.join(os.path.dirname(HERE), "assets", "fonts", "LXGWWenKai.ttf"),
]


def pick_font(size):
    for path in FONT_CANDIDATES:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    raise SystemExit("no CJK font found")


def make_icon_512():
    """512 图标：品牌蓝底 + 缩小后的前景（与自适应图标同一安全比例）"""
    fg = sk.shrink_to_canvas(sk.glyph(sk.CREAM))
    out = Image.new("RGBA", (512, 512), sk.GREEN + (255,))
    out.alpha_composite(fg.resize((512, 512), Image.LANCZOS))
    path = os.path.join(DOCS, "icon-512.png")
    out.convert("RGB").save(path)
    print("icon:", path)


def make_feature_graphic():
    """1024×500 头图：蓝底渐变 + 大涟漪 + 白色构图 + 应用名与标语"""
    W, H = 1024, 500
    base = Image.new("RGB", (W, H), sk.GREEN)
    d = ImageDraw.Draw(base)

    # 竖向渐变：上浅下深，营造纵深
    top, bottom = (10, 110, 220), (0, 58, 130)
    for y in range(H):
        t = y / (H - 1)
        d.line([(0, y), (W, y)],
               fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))

    # 背景大涟漪：自左侧图记处向外荡开（呼应图标语义）
    cx, cy = 250, 250
    rings = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    dr = ImageDraw.Draw(rings)
    for r, a in ((130, 40), (200, 30), (280, 22), (370, 14)):
        dr.ellipse([cx - r, cy - r, cx + r, cy + r],
                   outline=(255, 255, 255, a), width=3)
    base = Image.alpha_composite(base.convert("RGBA"), rings)

    # 左侧图记：白色构图（无底色，直接压在渐变上）
    mark = sk.glyph((255, 255, 255), ripple_alphas=(120, 90, 62))
    mark = mark.resize((300, 300), Image.LANCZOS)
    base.alpha_composite(mark, (cx - 150, cy - 150))

    # 右侧文案
    d = ImageDraw.Draw(base)
    name_font = pick_font(104)
    slogan_font = pick_font(38)
    tag_font = pick_font(25)

    x = 470
    d.text((x, 128), "寻渊", font=name_font, fill=(255, 255, 255),
           stroke_width=1, stroke_fill=(255, 255, 255))
    d.text((x + 6, 264), "寻根问祖，渊远流长", font=slogan_font,
           fill=(214, 232, 255))
    d.text((x + 6, 322), "本地优先 · 离线可用 · 开源", font=tag_font,
           fill=(160, 198, 245))

    path = os.path.join(DOCS, "feature-graphic.png")
    base.convert("RGB").save(path)
    print("feature graphic:", path)


if __name__ == "__main__":
    os.makedirs(DOCS, exist_ok=True)
    make_icon_512()
    make_feature_graphic()
