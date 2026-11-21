"""Makes assets/sprites/golem_carry/golem_carry_01.png: the final frame of the
lift animation with the box removed (the game draws carried boxes itself).
No pixels are added or redrawn. Feet at y=143, body centre x=81 (106x147).

    python3 tools/make_carry_pose.py
"""
import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPR = os.path.join(ROOT, "assets", "sprites")

src = Image.open(os.path.join(SPR, "golem_lift_1", "golem_lift_1_09.png")).convert("RGBA")
out = Image.new("RGBA", src.size, (0, 0, 0, 0))
sp, op = src.load(), out.load()
for y in range(src.height):
    for x in range(src.width):
        r, g, b, a = sp[x, y]
        if a > 0 and g > r and g >= b * 0.9:  # golem greens/teals only, not the box
            op[x, y] = sp[x, y]
os.makedirs(os.path.join(SPR, "golem_carry"), exist_ok=True)
out.save(os.path.join(SPR, "golem_carry", "golem_carry_01.png"))
print("bbox", out.getbbox())
