"""Writes SpriteFrames .tres resources from the frame folders in assets/sprites.

Re-run after adding/replacing frames:  python3 tools/gen_spriteframes.py
"""
import glob
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# resource file -> list of (anim name, frame folder, fps, loop)
SETS = {
    "monkey_frames.tres": [
        ("idle", "monkey_idle", 7.0, True),
        ("walk", "monkey_walk", 12.0, True),
        ("jump", "monkey_jump", 10.0, False),
        ("summon", "monkey_summon", 9.0, False),
    ],
    "golem_frames.tres": [
        ("idle", "golem_idle", 4.0, True),
        ("walk", "golem_walk", 8.0, True),
        ("summon", "golem_summon", 8.0, False),
        ("lift_1", "golem_lift_1", 10.0, False),
        ("lift_2", "golem_lift_2", 10.0, False),
        ("lift_3", "golem_lift_3", 10.0, False),
        ("carry_idle", "golem_carry", 1.0, True),
        ("carry_walk", "golem_carry", 1.0, True),
    ],
    "particle_frames.tres": [
        ("burst", "summon_particles", 9.0, False),
    ],
}

for out_name, anims in SETS.items():
    ext = []
    anim_txt = []
    for name, folder, fps, loop in anims:
        frames = sorted(glob.glob(os.path.join(ROOT, "assets/sprites", folder, "*.png")))
        assert frames, folder
        entries = []
        for f in frames:
            ext.append("res://" + os.path.relpath(f, ROOT))
            entries.append('{\n"duration": 1.0,\n"texture": ExtResource("%d")\n}' % len(ext))
        anim_txt.append(
            '{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %s\n}'
            % (", ".join(entries), "true" if loop else "false", name, fps)
        )
    lines = ['[gd_resource type="SpriteFrames" load_steps=%d format=3]\n' % (len(ext) + 1)]
    for i, path in enumerate(ext, 1):
        lines.append('[ext_resource type="Texture2D" path="%s" id="%d"]' % (path, i))
    lines.append("\n[resource]")
    lines.append("animations = [%s]" % ", ".join(anim_txt))
    with open(os.path.join(ROOT, "resources", out_name), "w") as fh:
        fh.write("\n".join(lines) + "\n")
    print("wrote", out_name, len(ext), "frames")
