extends Control

const PALETTES := [
    [Color("355d70"), Color("192e3b"), Color("70b19a"), Color("ffe6a3")],
    [Color("65547b"), Color("282d49"), Color("ca7d91"), Color("a1e8de")],
    [Color("714953"), Color("292d3b"), Color("7c9cbd"), Color("ffca72")],
]

var campaign := "elementary"
var level_number := 1
var background_id := "elementary_1"

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    resized.connect(queue_redraw)

func configure(config: Dictionary) -> void:
    background_id = str(config.background)
    var parts := background_id.rsplit("_", true, 1)
    campaign = parts[0] if parts.size() == 2 else "elementary"
    level_number = clampi(int(parts[1]), 1, 9) if parts.size() == 2 else 1
    queue_redraw()

func _draw() -> void:
    var campaign_index := ["elementary", "middle", "high"].find(campaign)
    var palette: Array = PALETTES[maxi(campaign_index, 0)]
    draw_set_transform(Vector2.ZERO, 0, size / Vector2(320, 180))
    draw_rect(Rect2(0, 0, 320, 180), palette[0].darkened(float(level_number - 1) * 0.035))
    draw_rect(Rect2(236, 24, 18, 18), palette[3])
    for layer in 2:
        for building in 15:
            var width := 14 + (building * 7 + level_number * 3) % 16
            var height := 14 + (building * 13 + level_number * 11) % 35 + level_number * 2
            var position := Vector2(building * 24 - layer * 8, 150 - height + layer * 12)
            draw_rect(Rect2(position, Vector2(width, height)), palette[1] if layer == 1 else palette[2].darkened(0.45))
            for floor_index in int(height / 8):
                for window in 2:
                    if (floor_index + building + window + level_number) % 3 != 0:
                        draw_rect(Rect2(position + Vector2(3 + window * 7, 4 + floor_index * 8), Vector2(3, 3)), palette[3].darkened(0.25))
            if level_number >= 5 and building % 3 == 0:
                draw_rect(Rect2(position + Vector2(width / 2, -level_number * 2), Vector2(2, level_number * 2)), palette[2])
    draw_rect(Rect2(0, 157, 320, 23), palette[1])
    for stripe in 16:
        draw_rect(Rect2(stripe * 22, 169, 12, 2), palette[3].darkened(0.35))
    _draw_landmark(palette)
    draw_rect(Rect2(4, 2, 312, 34), Color(0.025, 0.045, 0.065, 0.88))
    draw_rect(Rect2(14, 36, 292, 112), Color(0.025, 0.045, 0.065, 0.73))
    draw_set_transform(Vector2.ZERO)

func _draw_landmark(palette: Array) -> void:
    match level_number:
        1:
            for tree in 6:
                var position := Vector2(12 + tree * 57, 142)
                draw_rect(Rect2(position, Vector2(3, 17)), palette[3])
                draw_rect(Rect2(position - Vector2(6, 12), Vector2(16, 17)), Color("4f9b72"))
        2:
            draw_rect(Rect2(0, 156, 320, 8), Color("4899ae"))
            for stall in 5:
                var position := Vector2(12 + stall * 65, 145)
                draw_rect(Rect2(position, Vector2(24, 12)), palette[2])
                for stripe in 4:
                    draw_rect(Rect2(position + Vector2(stripe * 6, -4), Vector2(6, 5)), palette[3] if stripe % 2 else Color("c76e64"))
        3:
            draw_rect(Rect2(0, 162, 320, 1), palette[2])
            draw_rect(Rect2(0, 174, 320, 1), palette[2])
            draw_rect(Rect2(211, 147, 60, 18), Color("c76e64"))
            for window in 6:
                draw_rect(Rect2(216 + window * 8, 150, 5, 7), palette[3])
            draw_rect(Rect2(218, 165, 7, 3), Color.BLACK)
            draw_rect(Rect2(259, 165, 7, 3), Color.BLACK)
        4:
            draw_rect(Rect2(252, 117, 56, 42), palette[2])
            draw_colored_polygon(PackedVector2Array([Vector2(248, 117), Vector2(280, 98), Vector2(312, 117)]), palette[3])
            for pillar in 5:
                draw_rect(Rect2(257 + pillar * 10, 121, 4, 32), palette[3])
        5:
            draw_rect(Rect2(0, 156, 320, 12), Color("407e9f"))
            draw_rect(Rect2(34, 77, 5, 83), palette[3])
            draw_rect(Rect2(20, 77, 56, 4), palette[3])
            draw_rect(Rect2(69, 81, 1, 37), palette[3])
            draw_colored_polygon(PackedVector2Array([Vector2(242, 152), Vector2(308, 152), Vector2(298, 164), Vector2(250, 164)]), palette[2])
            draw_rect(Rect2(259, 137, 30, 15), palette[3])
        6:
            draw_rect(Rect2(266, 56, 26, 104), palette[2])
            draw_rect(Rect2(262, 49, 34, 8), palette[3])
            draw_rect(Rect2(270, 62, 18, 18), palette[3])
            draw_line(Vector2(279, 64), Vector2(279, 72), palette[1], 2)
            draw_line(Vector2(279, 72), Vector2(284, 74), palette[1], 2)
        7:
            for terrace in 4:
                var position := Vector2(246 + terrace * 13, 90 + terrace * 19)
                draw_rect(Rect2(position, Vector2(18, 68 - terrace * 18)), palette[2])
                draw_rect(Rect2(position - Vector2(3, 4), Vector2(24, 5)), Color("70b17c"))
                draw_rect(Rect2(position + Vector2(7, -13), Vector2(3, 10)), palette[3])
                draw_rect(Rect2(position + Vector2(3, -19), Vector2(11, 9)), Color("4f9b72"))
        8:
            for tower in 3:
                var position := Vector2(252 + tower * 19, 77 - tower * 14)
                draw_colored_polygon(PackedVector2Array([position, position + Vector2(9, -17), position + Vector2(18, 0), Vector2(position.x + 18, 160), Vector2(position.x, 160)]), palette[2])
                draw_line(position + Vector2(9, -10), Vector2(position.x + 9, 158), palette[3], 2)
        9:
            draw_rect(Rect2(266, 59, 24, 101), palette[2])
            draw_rect(Rect2(257, 52, 42, 10), palette[3])
            draw_rect(Rect2(261, 44, 34, 8), palette[3])
            draw_rect(Rect2(267, 37, 22, 7), palette[3])
            draw_rect(Rect2(277, 20, 3, 20), palette[3])
            for floor_index in 9:
                draw_rect(Rect2(270, 68 + floor_index * 9, 16, 2), palette[3])