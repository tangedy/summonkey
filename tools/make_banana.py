"""Generates assets/sprites/banana.png, a small pixel-art banana (placeholder art)."""
from PIL import Image, ImageDraw
import math

W = 40
img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
px = img.load()
cx, cy, r_out, r_in = 20, 2, 22, 14
for y in range(W):
    for x in range(W):
        d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
        ang = math.degrees(math.atan2(y + 0.5 - cy, x + 0.5 - cx))
        if 30 < ang < 150 and r_in < d < r_out:
            t = (d - r_in) / (r_out - r_in)
            col = (255, 226, 70, 255) if t < 0.55 else (232, 180, 40, 255)
            if t < 0.18:
                col = (255, 245, 150, 255)
            px[x, y] = col
# outline
out = img.copy()
op = out.load()
for y in range(W):
    for x in range(W):
        if px[x, y][3] == 0 and any(
            0 <= x + dx < W and 0 <= y + dy < W and px[x + dx, y + dy][3] > 0
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
        ):
            op[x, y] = (70, 40, 20, 255)
out.save("assets/sprites/banana.png")
print(out.getbbox())
