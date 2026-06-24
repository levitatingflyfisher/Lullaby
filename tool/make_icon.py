#!/usr/bin/env python3
"""Generate Lullaby app icon PNGs for flutter_launcher_icons."""

import math
from pathlib import Path
from PIL import Image, ImageDraw

SIZE = 1024
PURPLE = (103, 80, 164, 255)   # #6750A4 — M3 seed color
WHITE = (255, 255, 255, 255)
TRANSPARENT = (0, 0, 0, 0)


def draw_face(draw: ImageDraw.Draw, cx: float, cy: float, r: float) -> None:
    """Draw a simple baby-face silhouette (head circle + eyes + smile)."""
    # Head circle
    draw.ellipse(
        [cx - r, cy - r, cx + r, cy + r],
        fill=WHITE,
    )

    # Eyes — two small filled circles
    eye_r = r * 0.08
    eye_y = cy - r * 0.12
    for dx in (-r * 0.28, r * 0.28):
        ex = cx + dx
        draw.ellipse(
            [ex - eye_r, eye_y - eye_r, ex + eye_r, eye_y + eye_r],
            fill=PURPLE,
        )

    # Smile — arc drawn as a thick chord outline
    smile_r = r * 0.38
    smile_cx = cx
    smile_cy = cy + r * 0.08
    smile_box = [
        smile_cx - smile_r,
        smile_cy - smile_r,
        smile_cx + smile_r,
        smile_cy + smile_r,
    ]
    draw.arc(smile_box, start=20, end=160, fill=PURPLE, width=int(r * 0.10))


def make_icon_png(path: Path) -> None:
    """Full icon: purple rounded-square background + white face."""
    img = Image.new("RGBA", (SIZE, SIZE), TRANSPARENT)
    draw = ImageDraw.Draw(img)

    # Rounded-rect background (corner radius = 22.5% of size — Play Store style)
    r_corner = int(SIZE * 0.225)
    draw.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=r_corner, fill=PURPLE)

    # Face centred with ~20% padding
    face_r = SIZE * 0.32
    draw_face(draw, SIZE / 2, SIZE / 2, face_r)

    img.save(path, "PNG")
    print(f"Wrote {path}")


def make_foreground_png(path: Path) -> None:
    """Adaptive icon foreground: transparent background + white face.

    The Android adaptive icon safe zone is the inner 66% of the canvas.
    We draw the face at ~50% radius so it fits comfortably inside.
    """
    img = Image.new("RGBA", (SIZE, SIZE), TRANSPARENT)
    draw = ImageDraw.Draw(img)

    face_r = SIZE * 0.30
    draw_face(draw, SIZE / 2, SIZE / 2, face_r)

    img.save(path, "PNG")
    print(f"Wrote {path}")


if __name__ == "__main__":
    out_dir = Path(__file__).parent.parent / "assets" / "icon"
    out_dir.mkdir(parents=True, exist_ok=True)

    make_icon_png(out_dir / "icon.png")
    make_foreground_png(out_dir / "icon_foreground.png")
    print("Done.")
