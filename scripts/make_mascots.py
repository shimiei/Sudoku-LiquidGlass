"""把生成的角色图裁成圆形贴纸资源（512px，带透明通道）。

统一规则：居中裁成正方形 → 4 倍超采样画圆形蒙版 → 缩回 512。
底色本来就是每只动物的主题色，所以圆内不需要再挖透明。
"""
import os
import sys
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Sudoku", "Resources")
SIZE = 384
SS = 4  # supersample

def circle_crop(path: str, name: str) -> None:
    img = Image.open(path).convert("RGB")
    w, h = img.size
    side = min(w, h)
    img = img.crop(((w - side) // 2, (h - side) // 2, (w - side) // 2 + side, (h - side) // 2 + side))
    img = img.resize((SIZE, SIZE), Image.LANCZOS).convert("RGBA")

    mask = Image.new("L", (SIZE * SS, SIZE * SS), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, SIZE * SS - 1, SIZE * SS - 1), fill=255)
    mask = mask.resize((SIZE, SIZE), Image.LANCZOS)

    img.putalpha(mask)
    # 扁平插画颜色少，收敛成调色板图可以把每张压到 50KB 以内
    img = img.quantize(colors=160, method=Image.Quantize.FASTOCTREE)
    dst = os.path.join(OUT, name)
    img.save(dst, "PNG", optimize=True)
    print("wrote", dst, os.path.getsize(dst), "bytes")

if __name__ == "__main__":
    pairs = [
        (sys.argv[1], "MascotEasy.png"),    # 熊猫 · 简单
        (sys.argv[2], "MascotMedium.png"),  # 狐狸 · 中等
        (sys.argv[3], "MascotHard.png"),    # 老虎 · 困难
        (sys.argv[4], "MascotSleepy.png"),  # 睡觉熊猫 · 空白态
    ]
    for src, name in pairs:
        if not os.path.exists(src):
            print("missing", src)
            continue
        circle_crop(src, name)
