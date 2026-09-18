from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw


FRAME_SIZE = 64
LOGICAL_SIZE = 32
FRAMES_PER_ANIMATION = 4
STAGES = ("kitten", "big_cat", "tiger", "nerd_cat")
ANIMATIONS = ("idle", "happy", "sad", "level_up", "game_over", "evolution_pose")
SPEEDS = {
    "idle": 4.0,
    "happy": 8.0,
    "sad": 5.0,
    "level_up": 10.0,
    "game_over": 3.0,
    "evolution_pose": 8.0,
    "pause": 2.0,
    "high_score": 10.0,
}

PALETTE = {
    "outline": "#2b2033",
    "deep": "#6d351f",
    "orange": "#e97824",
    "light": "#ffad42",
    "cream": "#ffe0a1",
    "white": "#fff8df",
    "eye": "#31534f",
    "pink": "#ef7f8d",
    "gold": "#ffd84a",
    "blue": "#4d8edb",
    "navy": "#25395f",
}

ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "assets" / "characters" / "math_cat"
ATLAS_PATH = OUTPUT_DIR / "math_cat_sprite_sheet.png"
MAP_PATH = OUTPUT_DIR / "math_cat_sprite_sheet.json"


def rect(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], color: str) -> None:
    draw.rectangle(box, fill=color)


def draw_star(draw: ImageDraw.ImageDraw, x: int, y: int, color: str = PALETTE["gold"]) -> None:
    rect(draw, (x, y - 2, x, y + 2), color)
    rect(draw, (x - 2, y, x + 2, y), color)


def pose_values(animation: str, frame: int) -> tuple[int, int, str]:
    if animation == "happy":
        return (0, (0, -2, -4, -2)[frame], "up")
    if animation == "sad":
        return ((0, 0, 1, 1)[frame], (1, 1, 2, 2)[frame], "down")
    if animation == "level_up":
        return (0, (0, -3, -5, -2)[frame], "up")
    if animation == "game_over":
        return (0, (2, 2, 3, 3)[frame], "rest")
    if animation == "evolution_pose":
        return (0, (0, -1, -2, -1)[frame], "hero")
    return (0, (0, 0, 1, 0)[frame], "rest")


def draw_tail(draw: ImageDraw.ImageDraw, stage: int, frame: int, animation: str, ox: int, oy: int) -> None:
    if animation == "game_over":
        points = [(20 + ox, 23 + oy), (25, 25 + oy), (27, 27 + oy)]
    else:
        tail_tip = (7, 4, 5, 8)[frame]
        length = 2 if stage == 0 else 4
        points = [(21 + ox, 22 + oy), (26 + length // 2, 19 + oy), (27, 13 + tail_tip // 2)]
    draw.line(points, fill=PALETTE["outline"], width=4, joint="curve")
    draw.line(points, fill=PALETTE["orange"], width=2, joint="curve")


def draw_body(draw: ImageDraw.ImageDraw, stage: int, animation: str, frame: int, ox: int, oy: int, arm_pose: str) -> None:
    grown = stage > 0
    wide = stage >= 2
    left = 10 - int(wide) + ox
    right = 22 + int(wide) + ox
    top = (15 if grown else 16) + oy
    bottom = 27 + oy

    if animation == "game_over":
        top += 2
        left -= 1
        right += 1

    rect(draw, (left - 1, top, right + 1, bottom), PALETTE["outline"])
    rect(draw, (left, top, right, bottom - 1), PALETTE["orange"])
    rect(draw, (14 + ox, top + 2, 18 + ox, bottom - 2), PALETTE["cream"])

    if arm_pose == "up":
        rect(draw, (left - 3, top - 3, left, top + 5), PALETTE["outline"])
        rect(draw, (right, top - 3, right + 3, top + 5), PALETTE["outline"])
        rect(draw, (left - 2, top - 2, left, top + 4), PALETTE["orange"])
        rect(draw, (right, top - 2, right + 2, top + 4), PALETTE["orange"])
    elif arm_pose == "down":
        rect(draw, (left - 2, top + 5, left, top + 11), PALETTE["outline"])
        rect(draw, (right, top + 6, right + 2, top + 12), PALETTE["outline"])
        rect(draw, (left - 1, top + 5, left, top + 10), PALETTE["orange"])
        rect(draw, (right, top + 6, right + 1, top + 11), PALETTE["orange"])
    elif arm_pose == "hero":
        rect(draw, (right, top - 5, right + 3, top + 6), PALETTE["outline"])
        rect(draw, (right, top - 4, right + 2, top + 5), PALETTE["orange"])
        rect(draw, (left - 2, top + 3, left, top + 9), PALETTE["outline"])
        rect(draw, (left - 1, top + 3, left, top + 8), PALETTE["orange"])

    foot_y = bottom - 1
    if animation == "game_over":
        rect(draw, (left - 2, foot_y - 2, left + 4, foot_y + 1), PALETTE["outline"])
        rect(draw, (right - 4, foot_y - 2, right + 2, foot_y + 1), PALETTE["outline"])
        rect(draw, (left - 1, foot_y - 2, left + 4, foot_y), PALETTE["light"])
        rect(draw, (right - 4, foot_y - 2, right + 1, foot_y), PALETTE["light"])
    else:
        rect(draw, (left, foot_y, left + 4, foot_y + 2), PALETTE["outline"])
        rect(draw, (right - 4, foot_y, right, foot_y + 2), PALETTE["outline"])
        rect(draw, (left + 1, foot_y, left + 4, foot_y + 1), PALETTE["light"])
        rect(draw, (right - 4, foot_y, right - 1, foot_y + 1), PALETTE["light"])


def draw_head(draw: ImageDraw.ImageDraw, stage: int, animation: str, frame: int, ox: int, oy: int) -> None:
    grown = stage > 0
    wide = stage >= 2
    left = 8 - int(wide) + ox
    right = 23 + int(wide) + ox
    top = (5 if grown else 6) + oy
    bottom = 17 + oy
    droop = animation == "sad"

    ear_top = top + 3 if droop else top - 4
    draw.polygon([(left, top + 4), (left + 1, ear_top), (left + 6, top + 2)], fill=PALETTE["outline"])
    draw.polygon([(right, top + 4), (right - 1, ear_top), (right - 6, top + 2)], fill=PALETTE["outline"])
    draw.polygon([(left + 1, top + 3), (left + 2, ear_top + 2), (left + 5, top + 3)], fill=PALETTE["pink"])
    draw.polygon([(right - 1, top + 3), (right - 2, ear_top + 2), (right - 5, top + 3)], fill=PALETTE["pink"])

    draw.polygon(
        [(left + 2, top), (right - 2, top), (right, top + 3), (right, bottom - 3),
         (right - 3, bottom), (left + 3, bottom), (left, bottom - 3), (left, top + 3)],
        fill=PALETTE["outline"],
    )
    rect(draw, (left + 1, top + 2, right - 1, bottom - 3), PALETTE["orange"])
    rect(draw, (left + 3, bottom - 4, right - 3, bottom - 1), PALETTE["cream"])

    if stage >= 2:
        for stripe_x in (left + 4, left + 7, right - 7, right - 4):
            rect(draw, (stripe_x, top + 1, stripe_x + 1, top + 4), PALETTE["deep"])
        rect(draw, (left + 1, top + 7, left + 3, top + 8), PALETTE["deep"])
        rect(draw, (right - 3, top + 7, right - 1, top + 8), PALETTE["deep"])
    elif stage == 1:
        rect(draw, (left + 5, top + 1, left + 6, top + 3), PALETTE["deep"])
        rect(draw, (right - 6, top + 1, right - 5, top + 3), PALETTE["deep"])

    eye_y = top + 7
    blink = animation == "idle" and frame == 3
    closed = animation == "game_over" or blink
    happy = animation in ("happy", "level_up")
    if closed or happy:
        rect(draw, (left + 4, eye_y + 1, left + 7, eye_y + 1), PALETTE["outline"])
        rect(draw, (right - 7, eye_y + 1, right - 4, eye_y + 1), PALETTE["outline"])
    else:
        eye_height = 3 if stage == 0 else 2
        rect(draw, (left + 4, eye_y, left + 6, eye_y + eye_height), PALETTE["white"])
        rect(draw, (right - 6, eye_y, right - 4, eye_y + eye_height), PALETTE["white"])
        rect(draw, (left + 5, eye_y + 1, left + 6, eye_y + eye_height), PALETTE["eye"])
        rect(draw, (right - 6, eye_y + 1, right - 5, eye_y + eye_height), PALETTE["eye"])

    nose_x = 15 + ox
    rect(draw, (nose_x, top + 11, nose_x + 1, top + 11), PALETTE["pink"])
    if animation == "sad":
        rect(draw, (nose_x - 1, top + 13, nose_x + 2, top + 13), PALETTE["outline"])
        rect(draw, (nose_x, top + 12, nose_x + 1, top + 12), PALETTE["outline"])
    elif animation in ("happy", "level_up", "evolution_pose"):
        rect(draw, (nose_x - 2, top + 12, nose_x + 3, top + 12), PALETTE["outline"])
        rect(draw, (nose_x - 1, top + 13, nose_x + 2, top + 13), PALETTE["pink"])


def draw_nerd_accessories(draw: ImageDraw.ImageDraw, animation: str, frame: int, ox: int, oy: int) -> None:
    cap_toss = animation == "level_up" and frame >= 2
    cap_y = (0 if not cap_toss else -4 - frame) + oy
    cap_x = (0 if not cap_toss else frame * 2) + ox
    draw.polygon([(8 + cap_x, 4 + cap_y), (16 + cap_x, 1 + cap_y), (24 + cap_x, 4 + cap_y), (16 + cap_x, 7 + cap_y)], fill=PALETTE["navy"])
    rect(draw, (12 + cap_x, 5 + cap_y, 20 + cap_x, 7 + cap_y), PALETTE["navy"])
    rect(draw, (23 + cap_x, 4 + cap_y, 24 + cap_x, 9 + cap_y), PALETTE["gold"])

    glasses_y = 12 + oy
    rect(draw, (10 + ox, glasses_y, 15 + ox, glasses_y + 3), PALETTE["navy"])
    rect(draw, (17 + ox, glasses_y, 22 + ox, glasses_y + 3), PALETTE["navy"])
    rect(draw, (15 + ox, glasses_y + 1, 17 + ox, glasses_y + 1), PALETTE["navy"])
    rect(draw, (11 + ox, glasses_y + 1, 14 + ox, glasses_y + 2), PALETTE["white"])
    rect(draw, (18 + ox, glasses_y + 1, 21 + ox, glasses_y + 2), PALETTE["white"])

    if animation == "evolution_pose":
        rect(draw, (4, 19 + oy, 10, 26 + oy), PALETTE["outline"])
        rect(draw, (5, 20 + oy, 9, 25 + oy), PALETTE["blue"])
        rect(draw, (7, 20 + oy, 7, 25 + oy), PALETTE["gold"])


def draw_effects(draw: ImageDraw.ImageDraw, animation: str, frame: int, stage: int) -> None:
    if animation == "level_up":
        draw_star(draw, 5 + frame, 8 + (frame % 2))
        draw_star(draw, 27 - frame, 13 - (frame % 2))
    elif animation == "evolution_pose":
        draw_star(draw, 4 + frame, 5 + frame, PALETTE["white"])
        draw_star(draw, 27 - frame, 8 + (frame % 2), PALETTE["gold"])
        if stage >= 2:
            draw_star(draw, 5, 24 - frame, PALETTE["blue"])
    elif animation == "happy" and frame in (1, 2):
        draw_star(draw, 27, 8 + frame, PALETTE["gold"])


def make_frame(stage: int, animation: str, frame: int) -> Image.Image:
    image = Image.new("RGBA", (LOGICAL_SIZE, LOGICAL_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    ox, oy, arm_pose = pose_values(animation, frame)
    draw_tail(draw, stage, frame, animation, ox, oy)
    draw_body(draw, stage, animation, frame, ox, oy, arm_pose)
    draw_head(draw, stage, animation, frame, ox, oy)
    if stage == 3:
        draw_nerd_accessories(draw, animation, frame, ox, oy)
    draw_effects(draw, animation, frame, stage)
    return image.resize((FRAME_SIZE, FRAME_SIZE), Image.Resampling.NEAREST)


def atlas_region(stage_index: int, animation_index: int, frame: int) -> tuple[int, int, int, int]:
    return ((stage_index * FRAMES_PER_ANIMATION + frame) * FRAME_SIZE, animation_index * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)


def write_sprite_frames(stage_index: int, stage_name: str) -> None:
    path = OUTPUT_DIR / f"math_cat_{stage_name}_frames.tres"
    regions: dict[tuple[str, int], str] = {}
    subresources: list[str] = []
    subresource_index = 1
    for animation_index, animation in enumerate(ANIMATIONS):
        for frame in range(FRAMES_PER_ANIMATION):
            resource_id = f"Atlas_{subresource_index:02d}"
            regions[(animation, frame)] = resource_id
            x, y, width, height = atlas_region(stage_index, animation_index, frame)
            subresources.append(
                f'[sub_resource type="AtlasTexture" id="{resource_id}"]\n'
                'atlas = ExtResource("1_atlas")\n'
                f"region = Rect2({x}, {y}, {width}, {height})\n"
            )
            subresource_index += 1

    resource_animations = list(ANIMATIONS) + ["pause", "high_score"]
    source_animation = {"pause": "idle", "high_score": "level_up"}
    animation_entries: list[str] = []
    for animation in resource_animations:
        source = source_animation.get(animation, animation)
        frames = ", ".join(
            f'{{"duration": 1.0, "texture": SubResource("{regions[(source, frame)]}")}}'
            for frame in range(FRAMES_PER_ANIMATION)
        )
        loop = "true" if animation in ("idle", "pause", "high_score") else "false"
        animation_entries.append(
            "{\n"
            f'"frames": [{frames}],\n'
            f'"loop": {loop},\n'
            f'"name": &"{animation}",\n'
            f'"speed": {SPEEDS[animation]}\n'
            "}"
        )

    contents = (
        f"[gd_resource type=\"SpriteFrames\" load_steps={subresource_index + 1} format=3]\n\n"
        '[ext_resource type="Texture2D" path="res://assets/characters/math_cat/math_cat_sprite_sheet.png" id="1_atlas"]\n\n'
        + "\n".join(subresources)
        + "\n[resource]\nanimations = ["
        + ",\n".join(animation_entries)
        + "]\n"
    )
    path.write_text(contents, encoding="utf-8", newline="\n")


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    atlas_width = len(STAGES) * FRAMES_PER_ANIMATION * FRAME_SIZE
    atlas_height = len(ANIMATIONS) * FRAME_SIZE
    atlas = Image.new("RGBA", (atlas_width, atlas_height), (0, 0, 0, 0))
    frame_map: dict[str, object] = {
        "image": ATLAS_PATH.name,
        "frame_size": [FRAME_SIZE, FRAME_SIZE],
        "layout": "rows=animations, columns=stage groups of four frames",
        "animations": list(ANIMATIONS),
        "stages": {},
    }

    for stage_index, stage_name in enumerate(STAGES):
        stage_data: dict[str, list[dict[str, int]]] = {}
        for animation_index, animation in enumerate(ANIMATIONS):
            stage_data[animation] = []
            for frame in range(FRAMES_PER_ANIMATION):
                sprite = make_frame(stage_index, animation, frame)
                x, y, width, height = atlas_region(stage_index, animation_index, frame)
                atlas.alpha_composite(sprite, (x, y))
                stage_data[animation].append({"x": x, "y": y, "w": width, "h": height})
        frame_map["stages"][stage_name] = stage_data
        write_sprite_frames(stage_index, stage_name)

    atlas.save(ATLAS_PATH, optimize=True)
    MAP_PATH.write_text(json.dumps(frame_map, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(f"Wrote {ATLAS_PATH} ({atlas.width}x{atlas.height}, RGBA)")
    print(f"Wrote {len(STAGES)} SpriteFrames resources and {MAP_PATH.name}")


if __name__ == "__main__":
    main()