"""Regenerates CareBridge app icons and launch images from the repository logo.

Source: docs/images/carebridge0-logo.png (the CareBridge logo on white).
Only the figure mark is used; the wordmark and tagline are not legible at
icon sizes. The mark itself is not redrawn: it is cropped, its white
background is made transparent, and it is scaled onto each platform canvas.

Requires Python 3 and Pillow. Run from the repository root:
    python tool/branding/generate_app_icons.py
"""

import json
from pathlib import Path

from PIL import Image

SOURCE = Path("docs/images/carebridge0-logo.png")
# Bounding box of the figure mark in SOURCE (left, top, right, bottom).
MARK_BOX = (285, 131, 969, 796)
WHITE = (255, 255, 255)
# Matches CareBridgeColors.background in lib/presentation/care_bridge_theme.dart.
LAUNCH_BACKGROUND = (0xF5, 0xF7, 0xF4)

ANDROID_RES = Path("android/app/src/main/res")
ANDROID_DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
IOS_ICONS = Path("ios/Runner/Assets.xcassets/AppIcon.appiconset")
IOS_LAUNCH = Path("ios/Runner/Assets.xcassets/LaunchImage.imageset")


def transparent_mark() -> Image.Image:
    """Crops the mark and converts its white background to transparency."""
    mark = Image.open(SOURCE).convert("RGB").crop(MARK_BOX)
    out = Image.new("RGBA", mark.size)
    source, target = mark.load(), out.load()
    for y in range(mark.height):
        for x in range(mark.width):
            pixel = source[x, y]
            alpha = max(255 - channel for channel in pixel)
            if alpha < 4:
                target[x, y] = (0, 0, 0, 0)
                continue
            # Un-blend from white so anti-aliased edges keep their true color.
            color = tuple(
                round(255 - (255 - channel) * 255 / alpha) for channel in pixel
            )
            target[x, y] = (*color, alpha)
    return out


def place(mark: Image.Image, size: int, fraction: float, background) -> Image.Image:
    """Centers mark, scaled so its larger side is fraction of size."""
    scale = size * fraction / max(mark.size)
    scaled = mark.resize(
        (round(mark.width * scale), round(mark.height * scale)), Image.LANCZOS
    )
    canvas = Image.new("RGBA", (size, size), background)
    canvas.alpha_composite(
        scaled, ((size - scaled.width) // 2, (size - scaled.height) // 2)
    )
    return canvas


def main() -> None:
    mark = transparent_mark()

    for density, factor in ANDROID_DENSITIES.items():
        folder = ANDROID_RES / f"mipmap-{density}"
        # Pre-Android 8 launchers: an opaque white square.
        place(mark, round(48 * factor), 0.76, (*WHITE, 255)).convert("RGB").save(
            folder / "ic_launcher.png", optimize=True
        )
        # Adaptive-icon foreground: 108 dp, mark inside the 66 dp safe zone.
        # Also shown on the pre-Android 12 launch screen.
        place(mark, round(108 * factor), 0.56, (0, 0, 0, 0)).save(
            folder / "ic_launcher_foreground.png", optimize=True
        )

    contents = json.loads((IOS_ICONS / "Contents.json").read_text())
    for image in contents["images"]:
        points = float(image["size"].split("x")[0])
        pixels = round(points * int(image["scale"].rstrip("x")))
        # App Store icons must be opaque.
        place(mark, pixels, 0.8, (*WHITE, 255)).convert("RGB").save(
            IOS_ICONS / image["filename"], optimize=True
        )

    for suffix, factor in (("", 1), ("@2x", 2), ("@3x", 3)):
        place(mark, 120 * factor, 1.0, (0, 0, 0, 0)).save(
            IOS_LAUNCH / f"LaunchImage{suffix}.png", optimize=True
        )


if __name__ == "__main__":
    main()
