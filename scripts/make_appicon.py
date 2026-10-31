"""用角色插画生成 app 图标：薄荷底 + 居中熊猫，满幅、无圆角、无透明。

图标里放角色，和难度行、通关庆祝、空白态是同一套画，才不会显得拼凑。
"""
import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
RES = os.path.join(HERE, "..", "Sudoku", "Resources")
SIZE = 1024
MINT = (230, 243, 234, 255)

def build() -> Image.Image:
    # 直接用未裁圆的原始插画：底色本来就是满幅的，图标才不会出现一圈边
    src = os.path.join(HERE, "..", "dsh-image-gen", "image-7a3ba8df.png")
    art = Image.open(src).convert("RGB")
    w, h = art.size
    side = min(w, h)
    art = art.crop(((w - side) // 2, (h - side) // 2, (w - side) // 2 + side, (h - side) // 2 + side))
    return art.resize((SIZE, SIZE), Image.LANCZOS)

def main() -> None:
    master = build()
    docs = os.path.join(HERE, "..", "docs")
    os.makedirs(docs, exist_ok=True)
    # 仓库里的预览图压一下色，app 包里不需要 1024 原图
    master.quantize(colors=200, method=Image.FASTOCTREE).convert("RGB").save(
        os.path.join(docs, "Icon-1024.png"), "PNG", optimize=True)

    for name, px in {
        "AppIcon60x60@2x.png": 120,
        "AppIcon60x60@3x.png": 180,
        "AppIcon76x76@2x~ipad.png": 152,
        "AppIcon83.5x83.5@2x~ipad.png": 167,
    }.items():
        master.resize((px, px), Image.LANCZOS).save(os.path.join(RES, name), "PNG", optimize=True)
    print("icon done")

if __name__ == "__main__":
    main()
