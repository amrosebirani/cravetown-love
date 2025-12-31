#!/usr/bin/env python3
"""Generate simple 64x64 top-down sprites for each building type."""
from __future__ import annotations

import json
import math
from pathlib import Path
import struct
import zlib

SIZE = 64
DATA_PATH = Path("data/base/building_types.json")
OUTPUT_DIR = Path("assets/buildings")


def clamp_byte(value: float) -> int:
    return max(0, min(255, int(round(value))))


def with_alpha(rgb, alpha=255):
    r, g, b = rgb
    return clamp_byte(r), clamp_byte(g), clamp_byte(b), clamp_byte(alpha)


def lighten(color, amount):
    r, g, b, a = color
    return (
        clamp_byte(r + (255 - r) * amount),
        clamp_byte(g + (255 - g) * amount),
        clamp_byte(b + (255 - b) * amount),
        a,
    )


def darken(color, amount):
    r, g, b, a = color
    return (
        clamp_byte(r * (1 - amount)),
        clamp_byte(g * (1 - amount)),
        clamp_byte(b * (1 - amount)),
        a,
    )


def mix(color_a, color_b, t):
    r1, g1, b1, a1 = color_a
    r2, g2, b2, a2 = color_b
    return (
        clamp_byte(r1 * (1 - t) + r2 * t),
        clamp_byte(g1 * (1 - t) + g2 * t),
        clamp_byte(b1 * (1 - t) + b2 * t),
        clamp_byte(a1 * (1 - t) + a2 * t),
    )


class Canvas:
    def __init__(self, size=SIZE, background=(0, 0, 0, 0)):
        self.size = size
        self.pixels = [[background for _ in range(size)] for _ in range(size)]

    def fill(self, color):
        if not (isinstance(color, tuple) and len(color) == 4):
            raise TypeError(f"Color must be RGBA tuple, got {color}")
        for y in range(self.size):
            row = self.pixels[y]
            for x in range(self.size):
                row[x] = color

    def set_pixel(self, x, y, color):
        if 0 <= x < self.size and 0 <= y < self.size:
            if not (isinstance(color, tuple) and len(color) == 4):
                raise TypeError(f"Color must be RGBA tuple, got {color}")
            self.pixels[y][x] = color

    def fill_rect(self, x0, y0, x1, y1, color):
        if not (isinstance(color, tuple) and len(color) == 4):
            raise TypeError(f"Color must be RGBA tuple, got {color}")
        for y in range(max(0, y0), min(self.size, y1)):
            row = self.pixels[y]
            for x in range(max(0, x0), min(self.size, x1)):
                row[x] = color

    def stroke_rect(self, x0, y0, x1, y1, color):
        for x in range(x0, x1):
            self.set_pixel(x, y0, color)
            self.set_pixel(x, y1 - 1, color)
        for y in range(y0, y1):
            self.set_pixel(x0, y, color)
            self.set_pixel(x1 - 1, y, color)

    def draw_circle(self, cx, cy, radius, color):
        r2 = radius * radius
        for y in range(int(cy - radius), int(cy + radius) + 1):
            for x in range(int(cx - radius), int(cx + radius) + 1):
                if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r2:
                    self.set_pixel(x, y, color)

    def draw_ring(self, cx, cy, radius, thickness, color):
        r_outer = radius
        r_inner = max(0, radius - thickness)
        outer2 = r_outer * r_outer
        inner2 = r_inner * r_inner
        for y in range(int(cy - r_outer), int(cy + r_outer) + 1):
            for x in range(int(cx - r_outer), int(cx + r_outer) + 1):
                dist2 = (x - cx) * (x - cx) + (y - cy) * (y - cy)
                if inner2 <= dist2 <= outer2:
                    self.set_pixel(x, y, color)

    def draw_line(self, x0, y0, x1, y1, color):
        dx = abs(x1 - x0)
        dy = -abs(y1 - y0)
        sx = 1 if x0 < x1 else -1
        sy = 1 if y0 < y1 else -1
        err = dx + dy
        while True:
            self.set_pixel(x0, y0, color)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy


def write_png(path: Path, pixels):
    height = len(pixels)
    width = len(pixels[0]) if pixels else 0
    raw = bytearray()
    for row in pixels:
        raw.append(0)
        for r, g, b, a in row:
            raw.extend((r, g, b, a))
    compressor = zlib.compress(bytes(raw))

    def chunk(tag, data):
        return (
            struct.pack("!I", len(data))
            + tag
            + data
            + struct.pack("!I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    png = bytearray()
    png.extend(b"\x89PNG\r\n\x1a\n")
    png.extend(
        chunk(
            b"IHDR",
            struct.pack("!2I5B", width, height, 8, 6, 0, 0, 0),
        )
    )
    png.extend(chunk(b"IDAT", compressor))
    png.extend(chunk(b"IEND", b""))

    with open(path, "wb") as fh:
        fh.write(png)


def palette_for(base_color):
    return {
        "base": base_color,
        "light": lighten(base_color, 0.35),
        "lighter": lighten(base_color, 0.6),
        "dark": darken(base_color, 0.25),
        "shadow": darken(base_color, 0.45),
    }


COLORS = {
    "soil": with_alpha((156, 108, 72)),
    "grain": with_alpha((194, 161, 89)),
    "wood_light": with_alpha((190, 140, 90)),
    "wood_dark": with_alpha((110, 78, 50)),
    "stone": with_alpha((120, 128, 140)),
    "ash": with_alpha((70, 70, 80)),
    "metal": with_alpha((180, 188, 196)),
    "gold": with_alpha((222, 182, 60)),
    "emerald": with_alpha((80, 200, 180)),
    "sapphire": with_alpha((70, 130, 200)),
    "ruby": with_alpha((200, 60, 80)),
    "fire": with_alpha((248, 126, 46)),
    "lava": with_alpha((210, 60, 40)),
    "grass": with_alpha((90, 150, 70)),
    "sand": with_alpha((210, 186, 140)),
}


def level_scale(level_info, base=0.75, step=0.08):
    level_value = level_info.get("level", 0)
    return base + step * max(0, min(level_value, 4))


def add_tile_border(canvas, palette, level_info):
    thickness = 1 + level_info.get("level", 0)
    border_outer = palette["shadow"]
    border_inner = palette["dark"]
    for i in range(thickness):
        canvas.stroke_rect(i, i, SIZE - i, SIZE - i, border_outer)
    canvas.stroke_rect(thickness + 1, thickness + 1, SIZE - thickness - 1, SIZE - thickness - 1, border_inner)
    path_color = mix(palette["lighter"], COLORS["sand"], 0.5)
    canvas.fill_rect(0, SIZE - 6, SIZE, SIZE, path_color)


def render_farm(canvas, palette, _entry, level_info):
    rows = 5 + level_info.get("level", 0) * 2
    canvas.fill(palette["light"])
    for i in range(rows):
        color = COLORS["soil"] if i % 2 == 0 else COLORS["grain"]
        start_y = 20
        y = start_y + i * 3
        canvas.fill_rect(6, y, SIZE - 6, y + 3, color)
    path = with_alpha((170, 140, 110))
    canvas.fill_rect(28, 16, 36, SIZE - 8, path)
    barn_body = with_alpha((184, 60, 54))
    canvas.fill_rect(10, 10, 28, 28, barn_body)
    roof = with_alpha((140, 20, 20))
    canvas.fill_rect(8, 6, 30, 12, roof)
    door = with_alpha((80, 40, 30))
    canvas.fill_rect(17, 20, 21, 28, door)


def render_sawmill(canvas, palette, _entry, level_info):
    deck = mix(COLORS["wood_light"], COLORS["wood_dark"], 0.2)
    canvas.fill(deck)
    plank = mix(deck, COLORS["wood_dark"], 0.3)
    for y in range(0, SIZE, 6):
        canvas.fill_rect(0, y, SIZE, y + 1, plank)
    log_core = with_alpha((160, 110, 60))
    scale = level_scale(level_info)
    spacing = int(17 * scale)
    start = 16 - int(3 * scale)
    for idx, cx in enumerate((start, start + spacing, start + spacing * 2)):
        canvas.draw_circle(cx, 42, 9, log_core)
        canvas.draw_circle(cx, 42, 6, lighten(log_core, 0.2))
        canvas.draw_circle(cx, 42, 3, COLORS["grain"])
    saw_body = palette["dark"]
    canvas.fill_rect(8, 8, SIZE - 8, 28, saw_body)
    blade_center = with_alpha((210, 210, 210))
    canvas.draw_circle(32, 18, 10, blade_center)
    teeth_color = COLORS["metal"]
    for angle in range(0, 360, 30):
        rad = math.radians(angle)
        x = int(32 + math.cos(rad) * 13)
        y = int(18 + math.sin(rad) * 13)
        canvas.draw_line(32, 18, x, y, teeth_color)


def render_bakery(canvas, palette, _entry, level_info):
    canvas.fill(with_alpha((235, 208, 184)))
    oven = palette["dark"]
    canvas.fill_rect(6, 6, SIZE - 6, 24, oven)
    opening = COLORS["ash"]
    canvas.fill_rect(20, 10, 44, 22, opening)
    flame = COLORS["fire"]
    canvas.draw_circle(32, 16, 5, flame)
    tray = mix(palette["dark"], COLORS["metal"], 0.5)
    canvas.fill_rect(10, 30, SIZE - 10, 38, tray)
    loaf = COLORS["grain"]
    loaf_count = 3 + level_info.get("level", 0)
    spacing = (SIZE - 20) // max(1, loaf_count - 1)
    for i in range(loaf_count):
        cx = 12 + i * spacing
        canvas.draw_circle(cx, 34, 5, loaf)
        canvas.draw_line(cx - 4, 34, cx + 4, 34, COLORS["wood_dark"])
    counter = mix(COLORS["wood_light"], COLORS["wood_dark"], 0.2)
    canvas.fill_rect(8, 44, SIZE - 8, 56, counter)


def render_restaurant(canvas, palette, _entry, level_info):
    base = with_alpha((220, 220, 220))
    accent = with_alpha((200, 200, 210))
    for y in range(0, SIZE, 8):
        for x in range(0, SIZE, 8):
            color = base if (x + y) // 8 % 2 == 0 else accent
            canvas.fill_rect(x, y, x + 8, y + 8, color)
    table = with_alpha((166, 120, 80))
    chair = with_alpha((80, 120, 180))
    positions = [(20, 20), (44, 20), (20, 44), (44, 44)]
    if level_info.get("level", 0) >= 1:
        positions.extend([(32, 32), (20, 32), (44, 32)])
    for cx, cy in positions:
        canvas.draw_circle(cx, cy, 6, table)
        canvas.fill_rect(cx - 9, cy - 2, cx - 6, cy + 2, chair)
        canvas.fill_rect(cx + 6, cy - 2, cx + 9, cy + 2, chair)
        canvas.fill_rect(cx - 2, cy - 9, cx + 2, cy - 6, chair)
        canvas.fill_rect(cx - 2, cy + 6, cx + 2, cy + 9, chair)
    service = palette["dark"]
    canvas.fill_rect(4, 4, SIZE - 4, 10, service)


def render_bar(canvas, palette, _entry, level_info):
    floor = mix(COLORS["wood_dark"], COLORS["wood_light"], 0.5)
    canvas.fill(floor)
    for x in range(0, SIZE, 4):
        canvas.fill_rect(x, 0, x + 1, SIZE, COLORS["wood_dark"])
    counter = palette["shadow"]
    canvas.fill_rect(4, 14, SIZE - 4, 32, counter)
    top = lighten(counter, 0.3)
    canvas.fill_rect(4, 14, SIZE - 4, 18, top)
    stool_color = with_alpha((100, 50, 40))
    stool_count = 5 + level_info.get("level", 0)
    spacing = max(6, (SIZE - 20) // max(1, stool_count - 1))
    for idx in range(stool_count):
        cx = 10 + idx * spacing
        canvas.draw_circle(cx, 40, 5, stool_color)
        canvas.fill_rect(cx - 1, 45, cx + 1, 52, COLORS["metal"])


def render_shoe_factory(canvas, palette, _entry, level_info):
    floor = with_alpha((170, 176, 180))
    canvas.fill(floor)
    grid = with_alpha((150, 155, 160))
    for y in range(0, SIZE, 8):
        canvas.fill_rect(0, y, SIZE, y + 1, grid)
    for x in range(0, SIZE, 8):
        canvas.fill_rect(x, 0, x + 1, SIZE, grid)
    line_color = palette["dark"]
    canvas.fill_rect(12, 14, SIZE - 12, 28, line_color)
    belt = lighten(line_color, 0.4)
    canvas.fill_rect(12, 18, SIZE - 12, 24, belt)
    shoe = with_alpha((60, 60, 60))
    slots = 4 + level_info.get("level", 0)
    spacing = (SIZE - 24) // max(1, slots - 1)
    for i in range(slots):
        cx = 18 + i * spacing
        canvas.fill_rect(cx - 4, 18, cx + 2, 23, shoe)
        canvas.fill_rect(cx + 2, 20, cx + 4, 22, shoe)
    crates = COLORS["wood_light"]
    canvas.fill_rect(6, 36, 22, 54, crates)
    canvas.fill_rect(SIZE - 22, 36, SIZE - 6, 54, crates)


def render_textile_mill(canvas, palette, _entry, level_info):
    base = mix(palette["light"], with_alpha((240, 240, 240)), 0.5)
    canvas.fill(base)
    loom_frame = COLORS["wood_dark"]
    canvas.fill_rect(8, 10, SIZE - 8, 18, loom_frame)
    canvas.fill_rect(8, 46, SIZE - 8, 54, loom_frame)
    threads = [with_alpha((200, 80, 120)), with_alpha((80, 140, 220)), with_alpha((240, 200, 80))]
    if level_info.get("level", 0) >= 2:
        threads.append(with_alpha((110, 200, 120)))
    for idx, color in enumerate(threads):
        y = 18 + idx * 6
        canvas.fill_rect(12, y, SIZE - 12, y + 4, color)
    spool_core = with_alpha((220, 220, 230))
    canvas.draw_circle(20, 38, 6, spool_core)
    canvas.draw_circle(44, 38, 6, spool_core)
    thread_color = palette["dark"]
    canvas.draw_circle(20, 38, 3, thread_color)
    canvas.draw_circle(44, 38, 3, thread_color)


def render_tailor_shop(canvas, palette, _entry, level_info):
    canvas.fill(with_alpha((236, 228, 220)))
    cutting_table = COLORS["wood_light"]
    canvas.fill_rect(10, 12, SIZE - 10, 30, cutting_table)
    fabric = with_alpha((120, 190, 200))
    canvas.fill_rect(14, 16, SIZE - 14, 26, fabric)
    mannequin = with_alpha((210, 190, 150))
    canvas.draw_circle(18, 44, 6, mannequin)
    canvas.fill_rect(16, 44, 20, 58, mannequin)
    if level_info.get("level", 0) >= 1:
        canvas.draw_circle(46, 44, 6, mannequin)
        canvas.fill_rect(44, 44, 48, 58, mannequin)
    needle = COLORS["metal"]
    canvas.draw_line(40, 38, 54, 24, needle)
    canvas.draw_line(40, 40, 54, 26, needle)
    spool = with_alpha((200, 90, 60))
    canvas.fill_rect(34, 42, 48, 50, spool)
    thread = with_alpha((250, 210, 120))
    canvas.fill_rect(36, 42, 46, 44, thread)


def render_brickyard(canvas, palette, _entry, level_info):
    canvas.fill(COLORS["sand"])
    stack = with_alpha((184, 90, 60))
    mortar = with_alpha((220, 150, 120))
    rows = 6 + level_info.get("level", 0)
    for row in range(rows):
        y = 18 + row * 6
        offset = 0 if row % 2 == 0 else 4
        for col in range(5):
            x = 6 + offset + col * 10
            canvas.fill_rect(x, y, x + 8, y + 4, stack)
            canvas.stroke_rect(x, y, x + 8, y + 4, mortar)
    kiln = palette["dark"]
    canvas.fill_rect(24, 6, 40, 18, kiln)
    fire = COLORS["fire"]
    canvas.draw_circle(32, 12, 4, fire)
    smoke = with_alpha((150, 150, 150))
    canvas.draw_circle(32, 4, 3, smoke)


def render_furniture_shop(canvas, palette, _entry, level_info):
    floor = mix(COLORS["wood_light"], COLORS["wood_dark"], 0.4)
    canvas.fill(floor)
    rug = with_alpha((120, 80, 140))
    margin = int(14 - level_info.get("level", 0) * 2)
    canvas.fill_rect(margin, margin, SIZE - margin, SIZE - margin, rug)
    table = with_alpha((190, 150, 90))
    canvas.fill_rect(22, 22, SIZE - 22, 34, table)
    chair = with_alpha((120, 90, 60))
    canvas.fill_rect(18, 36, 26, 48, chair)
    canvas.fill_rect(SIZE - 26, 36, SIZE - 18, 48, chair)
    shelf = palette["dark"]
    canvas.fill_rect(6, 6, SIZE - 6, 12, shelf)
    canvas.draw_line(10, 9, SIZE - 10, 9, lighten(shelf, 0.4))


def render_jewellery_shop(canvas, palette, _entry, level_info):
    canvas.fill(mix(COLORS["emerald"], with_alpha((255, 255, 255)), 0.4))
    case_color = with_alpha((210, 240, 240))
    canvas.fill_rect(10, 10, SIZE - 10, 18, case_color)
    canvas.fill_rect(10, 28, SIZE - 10, 36, case_color)
    canvas.fill_rect(10, 46, SIZE - 10, 54, case_color)
    gems = [COLORS["ruby"], COLORS["sapphire"], COLORS["gold"]]
    offsets = (14, 32, 50)
    if level_info.get("level", 0) >= 2:
        offsets = (12, 24, 36, 48)
    for row, y in enumerate(offsets):
        for col, x in enumerate((18, 32, 46)):
            color = gems[(row + col) % len(gems)]
            canvas.draw_circle(x, y, 4, color)
    highlight = lighten(case_color, 0.6)
    canvas.stroke_rect(10, 10, SIZE - 10, 18, highlight)
    canvas.stroke_rect(10, 28, SIZE - 10, 36, highlight)
    canvas.stroke_rect(10, 46, SIZE - 10, 54, highlight)


def render_central_bank(canvas, palette, _entry, level_info):
    marble = with_alpha((210, 210, 220))
    canvas.fill(marble)
    column = with_alpha((235, 235, 240))
    columns = (10, 18, 46, 54)
    if level_info.get("level", 0) >= 2:
        columns = (8, 16, 24, 40, 48, 56)
    for x in columns:
        canvas.fill_rect(x, 6, x + 4, 32, column)
        canvas.stroke_rect(x, 6, x + 4, 32, palette["shadow"])
    vault = palette["dark"]
    canvas.draw_circle(32, 40, 14, vault)
    vault_ring = lighten(vault, 0.4)
    canvas.draw_ring(32, 40, 17, 3, vault_ring)
    handle = COLORS["metal"]
    for angle in range(0, 360, 90):
        rad = math.radians(angle)
        x = int(32 + math.cos(rad) * 10)
        y = int(40 + math.sin(rad) * 10)
        canvas.draw_line(32, 40, x, y, handle)
    coin = COLORS["gold"]
    for idx, cx in enumerate((18, 46)):
        canvas.draw_circle(cx, 50, 4, coin)


def render_forge(canvas, palette, _entry, level_info):
    canvas.fill(COLORS["ash"])
    hearth = palette["dark"]
    inset = int(12 - level_info.get("level", 0) * 2)
    canvas.fill_rect(inset, 12, SIZE - inset, 36, hearth)
    molten = COLORS["lava"]
    canvas.fill_rect(20, 18, SIZE - 20, 30, molten)
    glow = COLORS["fire"]
    canvas.draw_circle(32, 24, 8, glow)
    anvil_top = COLORS["metal"]
    canvas.fill_rect(16, 40, SIZE - 16, 48, anvil_top)
    base = palette["shadow"]
    canvas.fill_rect(24, 48, SIZE - 24, 56, base)


def render_blacksmith(canvas, palette, _entry, level_info):
    canvas.fill(mix(COLORS["ash"], palette["light"], 0.5))
    anvil = palette["dark"]
    inset = int(18 - level_info.get("level", 0) * 2)
    canvas.fill_rect(inset, 24, SIZE - inset, 36, anvil)
    canvas.fill_rect(26, 36, SIZE - 26, 46, anvil)
    horn = lighten(anvil, 0.3)
    canvas.fill_rect(SIZE - 22, 26, SIZE - 14, 32, horn)
    hammer_handle = with_alpha((130, 90, 50))
    canvas.fill_rect(8, 14, 12, 40, hammer_handle)
    hammer_head = COLORS["metal"]
    canvas.fill_rect(12, 18, 24, 28, hammer_head)
    sparks = COLORS["fire"]
    for pos in ((30, 18), (36, 16), (40, 20)):
        canvas.draw_circle(pos[0], pos[1], 2, sparks)


def render_mine(canvas, palette, _entry, level_info):
    ground = mix(palette["light"], COLORS["sand"], 0.4)
    canvas.fill(ground)
    crater_edge = palette["shadow"]
    radius = 16 + level_info.get("level", 0) * 2
    canvas.draw_ring(32, 34, radius + 4, 4, crater_edge)
    shaft = with_alpha((30, 30, 40))
    canvas.draw_circle(32, 34, radius, shaft)
    supports = COLORS["wood_dark"]
    canvas.fill_rect(8, 6, 16, 28, supports)
    canvas.fill_rect(SIZE - 16, 6, SIZE - 8, 28, supports)
    cart = COLORS["metal"]
    canvas.fill_rect(22, 44, SIZE - 22, 54, cart)
    ore = with_alpha((120, 160, 200))
    for i in range(5):
        canvas.draw_circle(18 + i * 7, 48, 2, ore)


RENDERERS = {
    "farm": render_farm,
    "sawmill": render_sawmill,
    "bakery": render_bakery,
    "restaurant": render_restaurant,
    "bar": render_bar,
    "shoe_factory": render_shoe_factory,
    "textile_mill": render_textile_mill,
    "tailor_shop": render_tailor_shop,
    "brickyard": render_brickyard,
    "furniture_shop": render_furniture_shop,
    "jewellery_shop": render_jewellery_shop,
    "central_bank": render_central_bank,
    "forge": render_forge,
    "blacksmith": render_blacksmith,
    "mine": render_mine,
}


def render_generic(canvas, palette, data, level_info):
    canvas.fill(palette["light"])
    canvas.fill_rect(10, 10, SIZE - 10, SIZE - 10, palette["base"])
    canvas.stroke_rect(10, 10, SIZE - 10, SIZE - 10, palette["shadow"])
    label = data.get("label", data["id"][:2]).upper()
    label = (label + str(level_info.get("level", 0)))[:3]
    # simple pixel font 3x5
    font = {
        "A": [0b010, 0b101, 0b111, 0b101, 0b101],
        "B": [0b110, 0b101, 0b110, 0b101, 0b110],
        "C": [0b011, 0b100, 0b100, 0b100, 0b011],
        "D": [0b110, 0b101, 0b101, 0b101, 0b110],
        "E": [0b111, 0b100, 0b110, 0b100, 0b111],
        "F": [0b111, 0b100, 0b110, 0b100, 0b100],
        "G": [0b011, 0b100, 0b101, 0b101, 0b011],
        "H": [0b101, 0b101, 0b111, 0b101, 0b101],
        "I": [0b111, 0b010, 0b010, 0b010, 0b111],
        "J": [0b001, 0b001, 0b001, 0b101, 0b010],
        "K": [0b101, 0b101, 0b110, 0b101, 0b101],
        "L": [0b100, 0b100, 0b100, 0b100, 0b111],
        "M": [0b101, 0b111, 0b101, 0b101, 0b101],
        "N": [0b101, 0b111, 0b111, 0b111, 0b101],
        "O": [0b010, 0b101, 0b101, 0b101, 0b010],
        "P": [0b110, 0b101, 0b110, 0b100, 0b100],
        "Q": [0b010, 0b101, 0b101, 0b011, 0b001],
        "R": [0b110, 0b101, 0b110, 0b101, 0b101],
        "S": [0b011, 0b100, 0b010, 0b001, 0b110],
        "T": [0b111, 0b010, 0b010, 0b010, 0b010],
        "U": [0b101, 0b101, 0b101, 0b101, 0b111],
        "V": [0b101, 0b101, 0b101, 0b101, 0b010],
        "W": [0b101, 0b101, 0b101, 0b111, 0b101],
        "X": [0b101, 0b101, 0b010, 0b101, 0b101],
        "Y": [0b101, 0b101, 0b010, 0b010, 0b010],
        "Z": [0b111, 0b001, 0b010, 0b100, 0b111],
    }
    start_x = 20
    for idx, char in enumerate(label[:2]):
        pattern = font.get(char)
        if not pattern:
            continue
        for row, bits in enumerate(pattern):
            for col in range(3):
                if bits & (1 << (2 - col)):
                    canvas.fill_rect(
                        start_x + idx * 8 + col * 2,
                        26 + row * 2,
                        start_x + idx * 8 + col * 2 + 2,
                        28 + row * 2,
                        palette["lighter"],
                    )


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    data = json.loads(DATA_PATH.read_text())
    missing = []
    for entry in data["buildingTypes"]:
        base_rgb = tuple(clamp_byte(c * 255) for c in entry.get("color", [0.5, 0.5, 0.5]))
        base = with_alpha(base_rgb)
        palette = palette_for(base)
        renderer = RENDERERS.get(entry["id"], render_generic)
        levels = entry.get("upgradeLevels") or [{"level": 0}]
        for level_info in levels:
            canvas = Canvas(SIZE, palette["light"])
            renderer(canvas, palette, entry, level_info)
            add_tile_border(canvas, palette, level_info)
            suffix = f"lvl{level_info.get('level', 0)}"
            out_path = OUTPUT_DIR / f"{entry['id']}_{suffix}.png"
            write_png(out_path, canvas.pixels)
            print(f"Generated {out_path} via {renderer.__name__}")
            if renderer is render_generic and entry["id"] not in missing:
                missing.append(entry["id"])
    if missing:
        print("Used fallback art for:", ", ".join(missing))


if __name__ == "__main__":
    main()
