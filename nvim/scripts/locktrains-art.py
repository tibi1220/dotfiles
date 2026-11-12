#!/usr/bin/env python3
"""Turn a LockTrains art folder into a Lua data file for Neovim's welcome screen.

The art comes from homepi-admin, drawn at terminal size: one art pixel per
half of a character cell, so the width is the number of columns and the
height twice the number of rows. For example:

  cd ~/Documents/Home/homepi-admin
  pnpm lock-trains /tmp/trains-160 --width 160 --height 72 --pixel 1
  python3 ~/dotfiles/nvim/scripts/locktrains-art.py /tmp/trains-160 \
      ~/dotfiles/nvim/lua/locktrains/art/w160.lua

Only what the welcome screen uses is kept: the night sky (gradient, stars,
moon phases), the town and its lit windows, the platform, the four trains
and their doors and lamps. Each sprite is trimmed to its visible pixels and stored as
run-length encoded rows of palette indices, so the files stay small.

With --no-sky, the sky is left out (for :Trains' strip, which shows only the
town and the trains):

  python3 locktrains-art.py --no-sky /tmp/trains-6000 .../art/strip.lua
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import png  # noqa: E402

args = [a for a in sys.argv[1:] if not a.startswith("--")]
no_sky = "--no-sky" in sys.argv[1:]
folder, out = args[0], args[1]
m = json.load(open(os.path.join(folder, "trains.json")))

palette = []  # colors as 0xRRGGBB
index = {}


def color(rgb):
    value = (rgb[0] << 16) | (rgb[1] << 8) | rgb[2]
    if value not in index:
        index[value] = len(palette) + 1  # 0 is transparent
        palette.append(value)
    return index[value]


def hex_color(text):
    return int(text[1:], 16)


sprites = {}


def sprite(name):
    """Load a PNG once; returns its key. Trimmed to opaque pixels, RLE rows."""
    key = name[:-4] if name.endswith(".png") else name
    if key in sprites:
        return key
    w, h, px = png.read(os.path.join(folder, name))
    xs = [x for y in range(h) for x in range(w) if px[y][x][3]]
    ys = [y for y in range(h) for x in range(w) if px[y][x][3]]
    if not xs:
        sprites[key] = {"x": 0, "y": 0, "w": 0, "h": 0, "rows": []}
        return key
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    rows = []
    for y in range(y0, y1 + 1):
        runs, last, count = [], None, 0
        for x in range(x0, x1 + 1):
            r, g, b, a = px[y][x]
            c = color((r, g, b)) if a else 0
            if c == last:
                count += 1
            else:
                if last is not None:
                    runs += [count, last]
                last, count = c, 1
        runs += [count, last]
        rows.append(runs)
    sprites[key] = {"x": x0, "y": y0, "w": x1 - x0 + 1, "h": y1 - y0 + 1, "rows": rows}
    return key


sky = m["sky"]
moon = sky["moon"]
data = {
    "width": m["screen"]["width"],
    "height": m["screen"]["height"],
}
if not no_sky:
    data["gradient"] = {
        "from": m["skyGradient"]["from"],
        "to": m["skyGradient"]["to"],
        "colors": [hex_color(c) for c in m["skyGradient"]["colors"]],
    }
    data["stars"] = {
        "speed": m["stars"]["speed"],
        "groups": [
            {"x": g["x"], "y": g["y"], "phase": g["phase"], "sprite": sprite(g["image"])}
            for g in m["stars"]["groups"]
        ],
    }
    data["moon"] = {
        "x": moon["x"],
        "y": moon["y"],
        "center": moon["center"],
        "phases": [sprite(p) for p in moon["phases"]],
    }
data.update({
    "land": {"x": m["land"]["x"], "y": m["land"]["y"], "sprite": sprite(m["land"]["image"])},
    "windows": [{"x": w["x"], "y": w["y"], "sprite": sprite(w["image"])} for w in m["windows"]],
    "platform": {"x": m["platform"]["x"], "y": m["platform"]["y"], "sprite": sprite(m["platform"]["image"])},
    "train": {"x": m["train"]["x"], "y": m["train"]["y"]},
    "motion": m["motion"],
    "doors": {"x": m["doors"]["x"], "y": m["doors"]["y"], "frames": m["doors"]["frames"]},
    # The lamps: headlights' beam ahead, tail lights behind, shimmering
    "light": {
        "x": m["light"]["x"],
        "y": m["light"]["y"],
        "frames": m["light"]["frames"],
        "perSecond": m["light"]["perSecond"],
    },
    "trains": {},
})
for name, t in m["trains"].items():
    data["trains"][name] = {
        "heading": t["heading"],
        "sprite": sprite(t["image"]),
        "flipped": t["doors"]["flipped"],
        "doors": [sprite(f'{t["doors"]["set"]}-{i}.png') for i in range(1, m["doors"]["frames"] + 1)],
        "lights": [sprite(f'{t["light"]["set"]}-{i}.png') for i in range(1, m["light"]["frames"] + 1)],
    }
data["palette"] = palette
data["sprites"] = sprites


def lua(value, indent=""):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(round(value, 4)) if isinstance(value, float) else str(value)
    if isinstance(value, str):
        return json.dumps(value)
    if isinstance(value, list):
        if all(isinstance(v, (int, float)) for v in value):
            return "{" + ",".join(lua(v) for v in value) + "}"
        inner = indent + "  "
        return "{\n" + "".join(f"{inner}{lua(v, inner)},\n" for v in value) + indent + "}"
    inner = indent + "  "
    items = []
    for k, v in value.items():
        key = k if k.isidentifier() else f"[{json.dumps(k)}]"
        items.append(f"{inner}{key} = {lua(v, inner)},\n")
    return "{\n" + "".join(items) + indent + "}"


with open(out, "w") as f:
    f.write("-- Generated by nvim/scripts/locktrains-art.py from homepi-admin's LockTrains art.\n")
    f.write("-- Do not edit by hand; regenerate instead.\n")
    f.write("return " + lua(data) + "\n")
print(f"{out}: {data['width']}x{data['height']}, {len(sprites)} sprites, {len(palette)} colors, {os.path.getsize(out) // 1024} KB")
