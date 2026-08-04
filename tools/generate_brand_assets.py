"""Generates OffSignal's bundled raster art from the section 8.1 design tokens.

Everything this writes is a real, committed asset - the app never fetches art at
runtime (NFR-4). Re-run after changing a token; replace the outputs wholesale if
a designer supplies hand-drawn artwork.

    python3 tools/generate_brand_assets.py
"""

import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP = os.path.join(ROOT, "packages", "offsignal_app")
IMAGES = os.path.join(APP, "assets", "images")
ICON = os.path.join(APP, "assets", "icon")

BG = (10, 14, 20)
CYAN = (79, 216, 255)
AMBER = (255, 180, 84)
TEXT = (237, 238, 243)
MUTED = (138, 148, 166)
INK = (18, 21, 28)

SS = 4


def canvas(width, height, fill=None):
    return Image.new("RGBA", (width * SS, height * SS), fill or (0, 0, 0, 0))


def finish(image, width, height):
    return image.resize((width, height), Image.LANCZOS)


def rgba(color, alpha):
    return (color[0], color[1], color[2], int(round(alpha * 255)))


def rounded_rect(draw, box, radius, outline=None, width=1, fill=None):
    x0, y0, x1, y1 = (v * SS for v in box)
    draw.rounded_rectangle(
        (x0, y0, x1, y1),
        radius=radius * SS,
        outline=outline,
        width=int(width * SS),
        fill=fill,
    )


def arc(draw, center, radius, start, end, color, width):
    cx, cy = center[0] * SS, center[1] * SS
    r = radius * SS
    draw.arc((cx - r, cy - r, cx + r, cy + r), start, end, fill=color, width=int(width * SS))


def circle(draw, center, radius, fill=None, outline=None, width=1):
    cx, cy = center[0] * SS, center[1] * SS
    r = radius * SS
    draw.ellipse(
        (cx - r, cy - r, cx + r, cy + r),
        fill=fill,
        outline=outline,
        width=int(width * SS),
    )


def line(draw, points, color, width):
    draw.line([(x * SS, y * SS) for x, y in points], fill=color, width=int(width * SS), joint="curve")


def radial_glow(width, height, center, radius, color, peak=0.5):
    glow = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    pixels = glow.load()
    cx, cy = center
    for y in range(height):
        for x in range(width):
            distance = math.hypot(x - cx, y - cy) / radius
            if distance >= 1:
                continue
            falloff = (1 - distance) ** 2.4
            pixels[x, y] = rgba(color, peak * falloff)
    return glow


def signal_mark(draw, center, scale, core_color, wave_color, stroke):
    circle(draw, center, 0.11 * scale, fill=core_color)
    for index, factor in enumerate((0.30, 0.48, 0.66)):
        alpha_color = wave_color if index == 0 else rgba(wave_color, 1 - index * 0.22)
        arc(draw, center, factor * scale, -58, 58, alpha_color, stroke)
        arc(draw, center, factor * scale, 122, 238, alpha_color, stroke)


def phone(draw, box, outline, stroke=3, radius=14, screen_fill=None):
    rounded_rect(draw, box, radius, outline=outline, width=stroke, fill=screen_fill)
    x0, y0, x1, y1 = box
    notch_width = (x1 - x0) * 0.26
    cx = (x0 + x1) / 2
    line(
        draw,
        [(cx - notch_width / 2, y0 + 7), (cx + notch_width / 2, y0 + 7)],
        outline,
        stroke * 0.8,
    )


def write(image, path, width, height):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    out = finish(image, width, height)
    if path.endswith(".webp"):
        out.save(path, "WEBP", lossless=True, quality=100, method=6)
    else:
        out.save(path, "PNG", optimize=True)
    print(f"{os.path.relpath(path, ROOT):58} {out.size[0]}x{out.size[1]}  {os.path.getsize(path):>7} bytes")


def app_icon_master():
    size = 1024
    base = Image.new("RGBA", (size, size), BG + (255,))
    base.alpha_composite(radial_glow(size, size, (size / 2, size * 0.46), size * 0.62, CYAN, 0.30))

    layer = canvas(size, size)
    draw = ImageDraw.Draw(layer)
    signal_mark(draw, (size / 2, size / 2), size * 0.60, CYAN, CYAN, size * 0.030)
    base.alpha_composite(finish(layer, size, size))

    write(base.convert("RGB").convert("RGBA"), os.path.join(ICON, "app_icon_master.png"), size, size)


def adaptive_foreground():
    size = 432
    layer = canvas(size, size)
    draw = ImageDraw.Draw(layer)
    signal_mark(draw, (size / 2, size / 2), size * 0.46, CYAN, CYAN, size * 0.028)
    write(layer, os.path.join(ICON, "app_icon_adaptive_fg.png"), size, size)


def splash_logo(name, ink):
    size = 512
    layer = canvas(size, size)
    draw = ImageDraw.Draw(layer)
    signal_mark(draw, (size / 2, size / 2), size * 0.62, ink, ink, size * 0.028)
    write(layer, os.path.join(ICON, name), size, size)


def onboarding_light_concept():
    width, height = 320, 240
    layer = canvas(width, height)
    draw = ImageDraw.Draw(layer)

    phone(draw, (24, 52, 108, 196), CYAN, stroke=3)
    phone(draw, (212, 52, 296, 196), AMBER, stroke=3)

    inner = canvas(width, height)
    inner_draw = ImageDraw.Draw(inner)
    rounded_rect(inner_draw, (38, 78, 94, 170), 6, fill=rgba(CYAN, 0.16))
    for row in range(4):
        for column in range(4):
            rounded_rect(
                inner_draw,
                (44 + column * 12, 86 + row * 20, 52 + column * 12, 98 + row * 20),
                2,
                fill=rgba(CYAN, 0.85 if (row + column) % 2 == 0 else 0.35),
            )
    layer.alpha_composite(inner)

    for index, radius in enumerate((16, 30, 44)):
        alpha = 0.9 - index * 0.2
        arc(draw, (110, 124), radius, -48, 48, rgba(CYAN, alpha), 3)
    for index, radius in enumerate((16, 30, 44)):
        alpha = 0.5 + index * 0.2
        arc(draw, (210, 124), radius, 132, 228, rgba(AMBER, alpha), 3)
    write(layer, os.path.join(IMAGES, "onboarding_light_concept.webp"), width * 3, height * 3)


def onboarding_permissions():
    width, height = 320, 240
    layer = canvas(width, height)
    draw = ImageDraw.Draw(layer)

    phone(draw, (108, 34, 212, 206), CYAN, stroke=3, radius=18)

    rounded_rect(draw, (124, 60, 196, 132), 10, outline=rgba(CYAN, 0.5), width=2)
    circle(draw, (160, 96), 22, outline=CYAN, width=3)
    circle(draw, (160, 96), 9, fill=rgba(CYAN, 0.9))

    for index, radius in enumerate((32, 42)):
        arc(draw, (160, 96), radius, -40, 40, rgba(CYAN, 0.45 - index * 0.18), 2)
        arc(draw, (160, 96), radius, 140, 220, rgba(CYAN, 0.45 - index * 0.18), 2)

    line(draw, [(126, 154), (194, 154)], rgba(MUTED, 0.65), 3)
    line(draw, [(126, 168), (170, 168)], rgba(MUTED, 0.4), 3)

    circle(draw, (206, 178), 20, fill=rgba(BG, 0.0), outline=AMBER, width=3)
    line(draw, [(197, 178), (203, 185), (215, 171)], AMBER, 4)

    write(layer, os.path.join(IMAGES, "onboarding_permissions.webp"), width * 3, height * 3)


def home_screen_grid(draw, origin, accent):
    x, y = origin
    for row in range(3):
        for column in range(3):
            filled = row == 0 and column == 0
            rounded_rect(
                draw,
                (x + column * 22, y + row * 22, x + 16 + column * 22, y + 16 + row * 22),
                4,
                fill=rgba(accent, 0.9) if filled else rgba(MUTED, 0.28),
            )


def onboarding_add_to_home_ios():
    width, height = 320, 240
    layer = canvas(width, height)
    draw = ImageDraw.Draw(layer)

    phone(draw, (28, 40, 140, 200), CYAN, stroke=3, radius=16)
    rounded_rect(draw, (44, 148, 124, 184), 8, outline=rgba(CYAN, 0.55), width=2)
    rounded_rect(draw, (58, 158, 78, 174), 4, outline=CYAN, width=3)
    line(draw, [(68, 172), (68, 152)], CYAN, 3)
    line(draw, [(62, 158), (68, 152), (74, 158)], CYAN, 3)
    line(draw, [(90, 166), (114, 166)], rgba(TEXT, 0.75), 3)

    line(draw, [(152, 120), (188, 120)], rgba(AMBER, 0.9), 3)
    line(draw, [(180, 112), (188, 120), (180, 128)], rgba(AMBER, 0.9), 3)

    phone(draw, (200, 40, 296, 200), rgba(MUTED, 0.55), stroke=2, radius=14)
    home_screen_grid(draw, (216, 78), CYAN)

    write(layer, os.path.join(IMAGES, "onboarding_add_to_home_ios.webp"), width * 3, height * 3)


def onboarding_add_to_home_android():
    width, height = 320, 240
    layer = canvas(width, height)
    draw = ImageDraw.Draw(layer)

    phone(draw, (28, 40, 140, 200), CYAN, stroke=3, radius=16)
    for index in range(3):
        circle(draw, (122, 62 + index * 9), 2.4, fill=CYAN)

    rounded_rect(draw, (44, 150, 124, 182), 8, fill=rgba(CYAN, 0.16), outline=rgba(CYAN, 0.6), width=2)
    circle(draw, (60, 166), 8, outline=CYAN, width=2.5)
    line(draw, [(60, 161), (60, 171)], CYAN, 2.5)
    line(draw, [(56, 167), (60, 171), (64, 167)], CYAN, 2.5)
    line(draw, [(78, 166), (112, 166)], rgba(TEXT, 0.8), 3)

    line(draw, [(152, 120), (188, 120)], rgba(AMBER, 0.9), 3)
    line(draw, [(180, 112), (188, 120), (180, 128)], rgba(AMBER, 0.9), 3)

    phone(draw, (200, 40, 296, 200), rgba(MUTED, 0.55), stroke=2, radius=14)
    home_screen_grid(draw, (216, 78), CYAN)

    write(layer, os.path.join(IMAGES, "onboarding_add_to_home_android.webp"), width * 3, height * 3)


def main():
    app_icon_master()
    adaptive_foreground()
    splash_logo("splash_logo_dark.png", CYAN)
    splash_logo("splash_logo_light.png", INK)
    onboarding_light_concept()
    onboarding_permissions()
    onboarding_add_to_home_ios()
    onboarding_add_to_home_android()


if __name__ == "__main__":
    main()
