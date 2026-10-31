#!/usr/bin/env python3
"""Renders the Tunely app icon and launch logo (`04` › App icon).

Violet hero gradient (135°, #3F25C9 → #5B3FE6 → #7B4DFF), white Phosphor
`waveform` (bold), no text. Opaque RGB PNGs (App Store Connect rejects alpha).

    python3 tool/make_app_icon.py
"""
import json
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = os.path.join(ROOT, 'packages/phosphor_flutter/lib/fonts/Phosphor-Bold.ttf')
ICONSET = os.path.join(ROOT, 'ios/Runner/Assets.xcassets/AppIcon.appiconset')
LAUNCH = os.path.join(ROOT, 'ios/Runner/Assets.xcassets/LaunchImage.imageset')
WAVEFORM = '\ue802'
STOPS = [(0.0, (0x3F, 0x25, 0xC9)), (0.55, (0x5B, 0x3F, 0xE6)), (1.0, (0x7B, 0x4D, 0xFF))]


def colour_at(t):
    for (t0, c0), (t1, c1) in zip(STOPS, STOPS[1:]):
        if t <= t1:
            f = (t - t0) / (t1 - t0)
            return tuple(round(a + (b - a) * f) for a, b in zip(c0, c1))
    return STOPS[-1][1]


def gradient(size):
    img = Image.new('RGB', (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            px[x, y] = colour_at((x + y) / (2 * (size - 1)))
    return img


def icon(size=1024, mark=0.68):
    img = gradient(size)
    draw = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT, int(size * mark))
    box = draw.textbbox((0, 0), WAVEFORM, font=font)
    w, h = box[2] - box[0], box[3] - box[1]
    draw.text(((size - w) / 2 - box[0], (size - h) / 2 - box[1]), WAVEFORM,
              font=font, fill=(255, 255, 255))
    return img


def main():
    master = icon()
    master.save(os.path.join(ICONSET, 'Icon-App-1024x1024@1x.png'))
    contents = json.load(open(os.path.join(ICONSET, 'Contents.json')))
    for entry in contents['images']:
        name = entry.get('filename')
        if not name or name.startswith('Icon-App-1024'):
            continue
        points = float(entry['size'].split('x')[0])
        scale = int(entry['scale'].rstrip('x'))
        px = round(points * scale)
        master.resize((px, px), Image.LANCZOS).save(os.path.join(ICONSET, name))

    # Launch logo: rounded tile like the Home logo, on a transparent canvas.
    tile = 120 * 3
    logo = icon(tile, mark=0.5).convert('RGBA')
    mask = Image.new('L', (tile, tile), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, tile - 1, tile - 1), radius=int(tile * 0.26), fill=255)
    logo.putalpha(mask)
    for scale, name in [(1, 'LaunchImage.png'), (2, 'LaunchImage@2x.png'), (3, 'LaunchImage@3x.png')]:
        px = 120 * scale
        logo.resize((px, px), Image.LANCZOS).save(os.path.join(LAUNCH, name))
    print('App icon and launch logo written.')


if __name__ == '__main__':
    main()
