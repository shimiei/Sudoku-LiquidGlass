"""Draws the app icon with exact geometry, then writes every size iOS needs.

Flat, full-bleed, no transparency, no pre-rounded corners (iOS applies the mask).
iOS 18/26 also tints icons, so the design stays readable as a single glyph.
"""
import os
from PIL import Image, ImageDraw

S = 4096                      # supersampled canvas
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Sudoku", "Resources")

IVORY = (244, 241, 234, 255)
INK = (28, 28, 30, 255)
BLUE = (10, 132, 255, 255)

def draw_icon(size: int) -> Image.Image:
    k = size / 1024.0   # all numbers below are in 1024-space
    img = Image.new("RGBA", (size, size), IVORY)
    d = ImageDraw.Draw(img)

    # 3x3 grid: 600pt square centred in a 1024 canvas, scaled to `size`
    margin = 212 * k
    grid = [margin, margin, size - margin, size - margin]
    cell = (grid[2] - grid[0]) / 3.0
    stroke = 24 * k

    # Filled cell: top-right. The outer corner keeps the icon's large radius so it
    # never leaks past the rounded border; the two inner corners are squared off
    # again because the cell rules cross them.
    r = 34 * k
    d.rounded_rectangle([grid[2] - cell, grid[1], grid[2], grid[1] + cell], radius=int(r), fill=BLUE)
    d.rectangle([grid[2] - cell, grid[1], grid[2] - cell + r, grid[1] + r], fill=BLUE)
    d.rectangle([grid[2] - cell, grid[1] + cell - r, grid[2] - cell + r, grid[1] + cell], fill=BLUE)

    # small dot: bottom-left cell
    cx = grid[0] + cell / 2.0
    cy = grid[3] - cell / 2.0
    r = 26 * k
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=INK)

    # grid lines on top so they stay crisp over the fills
    for i in range(1, 3):
        x = grid[0] + cell * i
        d.line([(x, grid[1]), (x, grid[3])], fill=INK, width=int(stroke))
        y = grid[1] + cell * i
        d.line([(grid[0], y), (grid[2], y)], fill=INK, width=int(stroke))
    d.rounded_rectangle(grid, radius=34 * k, outline=INK, width=int(stroke))
    return img


big = draw_icon(S)
master = big.resize((1024, 1024), Image.LANCZOS)
master.save(os.path.join(OUT, "Icon-1024.png"), "PNG")

targets = {
    "AppIcon60x60@2x.png": 120,
    "AppIcon60x60@3x.png": 180,
    "AppIcon76x76@2x~ipad.png": 152,
    "AppIcon83.5x83.5@2x~ipad.png": 167,
}
for name, px in targets.items():
    master.resize((px, px), Image.LANCZOS).save(os.path.join(OUT, name), "PNG")

print("icon written:", ", ".join(sorted(os.listdir(OUT))))
