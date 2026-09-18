extends RefCounted

const DESIGN_SIZE := Vector2(1280, 720)
const RADIUS := 98.0
const PEACH := Color("ffbc87")
const PINK := Color("ff65c5")

static func draw_on(canvas: CanvasItem, center: Vector2, darkening: float = 0.0) -> void:
    # Draw at map resolution, independently of the scenery's coarser pixel grid.
    for band in range(-49, 49):
        var y := float(band * 2)
        if y > 0 and posmod(int(y), 14) < 5 + int(y / 20):
            continue
        var half_width := floorf(sqrt(RADIUS * RADIUS - y * y))
        var color := PEACH.lerp(PINK, (y + RADIUS) / (RADIUS * 2)).darkened(darkening)
        canvas.draw_rect(Rect2(center + Vector2(-half_width, y), Vector2(half_width * 2, 2)), color)
