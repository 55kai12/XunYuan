# -*- coding: utf-8 -*-
"""应用 A 变体（墨绿底 #2F5D52 + 米白世代相承图形）到 res/
- 前景：真透明 RGBA，按各密度现有尺寸落盘
- monochrome：白色同形（Android 13+ 主题化图标）
- 旧版 mipmap ic_launcher.png：合成整图（预 O 设备）
"""
import os
from PIL import Image

SRC = os.path.dirname(os.path.abspath(__file__))
RES = os.path.join(os.path.dirname(SRC), "android", "app", "src", "main", "res")

fg_master = Image.open(os.path.join(SRC, "fg_green_bg.png")).convert("RGBA")   # 432
mono_master = Image.open(os.path.join(SRC, "mono.png")).convert("RGBA")        # 432
BG = (45, 90, 78, 255)  # #2D5A4E 品牌墨绿（与 colors.xml ink_green 一致）

DENSITIES = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}  # 48dp 基准

def composite_flat(size):
    """真机合成比例（前景占 72/108）铺底色 → 旧版整图"""
    inner = round(size * 72 / 108)
    fg = fg_master.resize((inner, inner), Image.LANCZOS)
    icon = Image.new("RGBA", (size, size), BG)
    icon.alpha_composite(fg, ((size - inner) // 2, (size - inner) // 2))
    return icon.convert("RGB")

for dpi, size in DENSITIES.items():
    # 前景（真透明）
    fg_master.resize((size, size), Image.LANCZOS).save(
        os.path.join(RES, f"drawable-{dpi}", "ic_launcher_foreground.png"))
    # monochrome（系统按 alpha 染色）
    mono_master.resize((size, size), Image.LANCZOS).save(
        os.path.join(RES, f"drawable-{dpi}", "ic_launcher_monochrome.png"))
    # 旧版整图（48dp 基准）
    composite_flat(LEGACY[dpi]).save(os.path.join(RES, f"mipmap-{dpi}", "ic_launcher.png"))

# 校验
for dpi, size in DENSITIES.items():
    fg = Image.open(os.path.join(RES, f"drawable-{dpi}", "ic_launcher_foreground.png"))
    leg = Image.open(os.path.join(RES, f"mipmap-{dpi}", "ic_launcher.png"))
    assert fg.mode == "RGBA" and fg.getpixel((0, 0))[3] == 0, f"fg {dpi} not transparent"
    assert leg.getpixel((0, 0)) == (45, 90, 78), f"legacy {dpi} wrong bg {leg.getpixel((0,0))}"
    assert leg.size == (LEGACY[dpi], LEGACY[dpi]), f"legacy {dpi} wrong size {leg.size}"
print("ALL OK: foreground transparent, legacy composited")
