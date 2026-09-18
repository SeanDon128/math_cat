extends Control

const Catalog = preload("res://scripts/adventure/adventure_catalog.gd")
const Sun = preload("res://scripts/adventure/adventure_sun.gd")
const INK := Color("100c29")
const WARM := Color("ffbc87")
const ROSE := Color("ff65c5")
const ART_SIZE := Vector2(320, 180)
const HORIZON := 113.0
const RETRO_GRID_SPEED := 0.10
const RETRO_GRID_COLUMNS := 11.0

var level_number: int = 1
var accent: Color = Color("59f7ff")
var background_clock: float = 0.0
var _animated: bool = true

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    clip_contents = true
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    resized.connect(queue_redraw)
    set_process(_animated)
    queue_redraw()

func configure(config: Dictionary) -> void:
    level_number = clampi(int(config.get("number", 1)), 1, 8)
    accent = config.get("highlight_color", Catalog.STAGE_HIGHLIGHT_COLORS[level_number - 1])
    accent.a = 1.0
    queue_redraw()

func set_animated(enabled: bool) -> void:
    _animated = enabled
    set_process(enabled)
    queue_redraw()

func sun_center() -> Vector2:
    var highest_center := Catalog.WORLD_MAP_SUN_CENTER / 4.0
    var progress := float(level_number - 1) / 7.0
    return Vector2(highest_center.x, lerpf(HORIZON - 9.0, highest_center.y, progress))

func _process(delta: float) -> void:
    if not _animated:
        return
    background_clock += delta
    queue_redraw()

func _draw() -> void:
    if size.x <= 0.0 or size.y <= 0.0:
        return
    draw_set_transform(Vector2.ZERO, 0.0, size / ART_SIZE)
    _sky()
    _distant_city()
    _floor()
    match level_number:
        1: _garden_blocks()
        2: _canal_market()
        3: _tram_quarter()
        4: _library_square()
        5: _harbor_lights()
        6: _clockwork_district()
        7: _sky_gardens()
        8: _crystal_avenue()
    draw_set_transform(Vector2.ZERO)

func _sky() -> void:
    var dusk := Color("241631").lerp(accent, 0.025)
    for row in 180:
        var color := Color("0b0d23").lerp(dusk, clampf(float(row) / HORIZON, 0.0, 1.0))
        draw_rect(Rect2(0, row, 320, 1), color)
    for index in 38:
        var x := float(posmod(index * 73 + 19, 312) + 4)
        var y := float(posmod(index * 37 + 11, 88) + 8)
        # The header and question live in open sky, not under a masking panel.
        if y < 34.0 or (x > 48.0 and x < 274.0 and y < 82.0):
            continue
        var star_seed := float(posmod(index * 17, 19)) / 18.0
        var twinkle := 0.5 + 0.5 * sin(background_clock * (1.2 + star_seed * 1.8) + star_seed * 18.0)
        draw_rect(Rect2(x, y, 1, 1), Color("b9b5ee", 0.62 * twinkle))
    draw_set_transform(Vector2.ZERO, 0.0, size / Sun.DESIGN_SIZE)
    Sun.draw_on(self, sun_center() * (Sun.DESIGN_SIZE / ART_SIZE), 0.3)
    draw_set_transform(Vector2.ZERO, 0.0, size / ART_SIZE)

func _distant_city() -> void:
    var fill := Color("19162f").lerp(accent, 0.035)
    var edge := Color("30223f").lerp(accent, 0.055)
    for index in 25:
        var x := float(index * 13)
        var height := float(7 + posmod(index * 7 + level_number * 3, 14))
        if x > 54.0 and x < 264.0:
            height *= 0.65
        var width := minf(10.0, 320.0 - x)
        draw_rect(Rect2(x, HORIZON - height, width, height), fill)
        draw_rect(Rect2(x, HORIZON - height, width, 1), edge)
        if index % 3 == 0:
            draw_rect(Rect2(x + 3, HORIZON - height - 3, 4, 3), fill)
        for window in 2:
            draw_rect(Rect2(x + 2 + window * 4, HORIZON - height + 4, 1, 2), edge)

func _floor() -> void:
    draw_rect(Rect2(0, HORIZON, 320, 180 - HORIZON), INK)
    var grid := INK.lerp(accent, 0.13)
    var rim := INK.lerp(accent, 0.28)
    draw_rect(Rect2(0, HORIZON, 320, 1), rim)
    var ground_height := ART_SIZE.y - HORIZON
    for column in range(-7, 8):
        for segment in 32:
            var start_ground := maxf(0.025, float(segment) / 32.0)
            var end_ground := float(segment + 1) / 32.0
            var middle_ground := (start_ground + end_ground) * 0.5
            var start := Vector2(ART_SIZE.x * 0.5 + float(column) * ART_SIZE.x * start_ground / RETRO_GRID_COLUMNS, HORIZON + ground_height * start_ground)
            var end := Vector2(ART_SIZE.x * 0.5 + float(column) * ART_SIZE.x * end_ground / RETRO_GRID_COLUMNS, HORIZON + ground_height * end_ground)
            draw_line(start, end, Color(grid, _grid_opacity(middle_ground)), 0.5)
    var time_phase := fmod(background_clock * RETRO_GRID_SPEED * 1.5, 1.0)
    for line in range(1, 62):
        var ground := 1.5 / (float(line) + 0.5 - time_phase)
        if ground >= 0.025 and ground <= 1.0:
            var y := HORIZON + ground_height * ground
            draw_rect(Rect2(0, y, ART_SIZE.x, 0.5), Color(grid, _grid_opacity(ground)))

func _grid_opacity(ground: float) -> float:
    return smoothstep(0.02, 0.52, ground) * (0.55 + ground * 0.45)

func _building(rect: Rect2, rows: int = 3, warm_windows: bool = false) -> void:
    var fill := Color("211638").lerp(accent, 0.035)
    var edge := INK.lerp(accent, 0.38)
    var glass := INK.lerp(WARM if warm_windows else accent, 0.25)
    draw_rect(rect, fill)
    draw_rect(Rect2(rect.position, Vector2(rect.size.x, 1)), edge)
    draw_rect(Rect2(rect.position + Vector2(rect.size.x - 3, 1), Vector2(3, rect.size.y - 1)), fill.darkened(0.2))
    var columns := maxi(1, int((rect.size.x - 6.0) / 7.0))
    for row in rows:
        for column in columns:
            var at := rect.position + Vector2(4 + column * 7, 5 + row * 8)
            if at.y + 3 < rect.end.y - 2:
                draw_rect(Rect2(at, Vector2(2, 3)), glass)

func _tree(x: float, base_y: float, height: float, blossom: bool = false) -> void:
    var leaf := Color("1d393e").lerp(ROSE if blossom else accent, 0.15)
    var tip := leaf.lerp(WARM if blossom else accent, 0.17)
    draw_rect(Rect2(x - 1, base_y - height + 7, 2, height - 7), Color("58404e"))
    draw_rect(Rect2(x - 6, base_y - height + 3, 12, 8), leaf)
    draw_rect(Rect2(x - 4, base_y - height, 8, 14), leaf)
    draw_rect(Rect2(x - 4, base_y - height, 7, 2), tip)
    draw_rect(Rect2(x - 6, base_y - height + 3, 2, 4), tip)

func _planter(x: float, y: float, width: float) -> void:
    draw_rect(Rect2(x, y, width, 4), Color("33203f"))
    draw_rect(Rect2(x - 1, y, width + 2, 1), INK.lerp(accent, 0.38))
    draw_rect(Rect2(x + 2, y - 3, width - 4, 3), Color("254147"))
    for index in int((width - 4) / 4):
        draw_rect(Rect2(x + 3 + index * 4, y - 4, 1, 1), INK.lerp(WARM, 0.5))

func _garden_blocks() -> void:
    _building(Rect2(3, 79, 25, 34), 3, true)
    _building(Rect2(29, 91, 20, 22), 1)
    var greenhouse := PackedVector2Array([Vector2(3, 79), Vector2(9, 70), Vector2(22, 70), Vector2(28, 79)])
    draw_colored_polygon(greenhouse, Color("20383e"))
    draw_polyline(greenhouse, INK.lerp(accent, 0.43), 1)
    draw_line(Vector2(15, 70), Vector2(15, 79), INK.lerp(accent, 0.27), 1)
    _tree(37, 91, 20)
    _planter(30, 91, 18)
    _building(Rect2(278, 91, 39, 22), 1, true)
    for x in [284.0, 310.0]:
        draw_rect(Rect2(x, 75, 2, 16), Color("3a344a"))
    draw_rect(Rect2(280, 74, 35, 2), INK.lerp(accent, 0.43))
    for x in range(282, 315, 6):
        draw_rect(Rect2(x, 72, 2, 5), Color("344d50"))
    _tree(296, 91, 16, true)
    _planter(279, 109, 37)
    _planter(3, 112, 22)

func _canal_market() -> void:
    _building(Rect2(3, 76, 18, 33), 2, true)
    _building(Rect2(23, 83, 22, 26), 1, true)
    for x in [3.0, 23.0]:
        var roof_y := 74.0 if x == 3.0 else 81.0
        draw_colored_polygon(PackedVector2Array([Vector2(x - 1, roof_y), Vector2(x + 9, roof_y - 7), Vector2(x + 19, roof_y)]), Color("473048"))
        draw_rect(Rect2(x, 97, 19, 3), INK.lerp(WARM, 0.38))
        for stripe in 3:
            draw_rect(Rect2(x + 2 + stripe * 6, 97, 3, 4), INK.lerp(accent, 0.38))
        draw_rect(Rect2(x + 1, 100, 1, 9), Color("58404e"))
        draw_rect(Rect2(x + 17, 100, 1, 9), Color("58404e"))
    _water(109, 123)
    draw_rect(Rect2(0, 108, 48, 3), Color("453049"))
    _building(Rect2(292, 83, 25, 25), 2, true)
    # Stepped stone arch; the opening reveals the canal underneath.
    draw_rect(Rect2(267, 104, 50, 4), Color("44304d"))
    draw_rect(Rect2(267, 108, 8, 15), Color("30253f"))
    draw_rect(Rect2(309, 108, 8, 15), Color("30253f"))
    draw_rect(Rect2(275, 108, 5, 7), Color("30253f"))
    draw_rect(Rect2(304, 108, 5, 7), Color("30253f"))
    draw_rect(Rect2(280, 108, 24, 3), Color("30253f"))
    draw_rect(Rect2(267, 99, 50, 1), INK.lerp(accent, 0.4))
    for x in range(268, 318, 8):
        draw_rect(Rect2(x, 100, 1, 4), Color("584563"))
    draw_rect(Rect2(0, 123, 320, 1), INK.lerp(accent, 0.25))

func _water(top: int, bottom: int) -> void:
    draw_rect(Rect2(0, top, 320, bottom - top), Color("122336").lerp(accent, 0.025))
    for index in 25:
        var x := float(posmod(index * 47 + 7, 308))
        var y := float(top + 2 + posmod(index * 5, bottom - top - 3))
        var shimmer := 0.13 + 0.05 * sin(background_clock * 0.9 + float(index))
        draw_rect(Rect2(x, y, 3 + posmod(index, 6), 0.5), INK.lerp(accent, shimmer))
    for index in 4:
        var width := float(12 - index * 2)
        draw_rect(Rect2(291 - width / 2.0, top + 2 + index * 2, width, 0.5), INK.lerp(WARM, 0.21))

func _tram_quarter() -> void:
    _building(Rect2(3, 71, 18, 42), 4, true)
    _building(Rect2(23, 82, 19, 31), 2)
    draw_rect(Rect2(1, 70, 22, 2), INK.lerp(accent, 0.35))
    _building(Rect2(282, 78, 15, 35), 3)
    _building(Rect2(299, 87, 18, 26), 2, true)
    var rail := INK.lerp(accent, 0.36)
    draw_rect(Rect2(0, 103, 54, 2), rail)
    draw_rect(Rect2(0, 107, 54, 2), Color("382d4a"))
    for x in [5.0, 26.0, 47.0]:
        draw_rect(Rect2(x, 109, 3, 4), Color("30253f"))
    draw_rect(Rect2(1, 75, 1, 28), rail)
    draw_rect(Rect2(51, 75, 1, 28), rail)
    draw_rect(Rect2(1, 75, 51, 1), rail)
    draw_polyline(PackedVector2Array([Vector2(22, 86), Vector2(28, 80), Vector2(22, 76), Vector2(34, 76)]), rail, 1)
    draw_rect(Rect2(7, 86, 39, 13), Color("39324f"))
    draw_rect(Rect2(9, 84, 35, 2), INK.lerp(accent, 0.48))
    draw_rect(Rect2(7, 96, 39, 3), INK.lerp(ROSE, 0.32))
    for x in range(11, 40, 7):
        draw_rect(Rect2(x, 88, 5, 5), INK.lerp(WARM, 0.38))
    draw_rect(Rect2(40, 87, 4, 9), Color("192236"))
    for x in [14.0, 36.0]:
        draw_rect(Rect2(x, 99, 5, 4), Color("090d20"))
        draw_rect(Rect2(x + 1, 100, 3, 2), Color("53516a"))
    draw_rect(Rect2(6, 94, 2, 2), INK.lerp(WARM, 0.65))
    draw_rect(Rect2(277, 109, 40, 4), Color("30253f"))
    draw_rect(Rect2(277, 94, 40, 2), rail)
    for x in [279.0, 314.0]:
        draw_rect(Rect2(x, 96, 2, 13), Color("3a344a"))
    draw_rect(Rect2(287, 105, 18, 2), INK.lerp(WARM, 0.24))

func _library_square() -> void:
    _building(Rect2(3, 81, 49, 32), 0)
    var edge := INK.lerp(accent, 0.42)
    draw_colored_polygon(PackedVector2Array([Vector2(1, 80), Vector2(27, 66), Vector2(54, 80)]), Color("2b2742"))
    draw_polyline(PackedVector2Array([Vector2(1, 80), Vector2(27, 66), Vector2(54, 80)]), edge, 1)
    draw_rect(Rect2(4, 80, 47, 3), INK.lerp(accent, 0.25))
    for x in [8.0, 19.0, 32.0, 43.0]:
        draw_rect(Rect2(x, 85, 4, 23), Color("3f3a51"))
        draw_rect(Rect2(x - 1, 84, 6, 2), edge)
        draw_rect(Rect2(x - 1, 106, 6, 2), edge.darkened(0.25))
    draw_rect(Rect2(25, 91, 5, 17), Color("101829"))
    draw_rect(Rect2(26, 92, 3, 9), INK.lerp(WARM, 0.32))
    for x in [14.0, 38.0]:
        draw_rect(Rect2(x - 1, 89, 5, 14), Color("11172b"))
        for shelf in 2:
            var shelf_y := 90.0 + shelf * 6.0
            draw_rect(Rect2(x, shelf_y, 1, 4), INK.lerp(WARM, 0.4))
            draw_rect(Rect2(x + 2, shelf_y + 1, 1, 3), INK.lerp(accent, 0.35))
            draw_rect(Rect2(x - 1, shelf_y + 4, 5, 1), Color("534152"))
    for step in 3:
        draw_rect(Rect2(3 - step, 108 + step * 2, 49 + step * 2, 1), Color("4a3f57"))
    draw_colored_polygon(PackedVector2Array([Vector2(22, 72), Vector2(27, 74), Vector2(32, 72), Vector2(32, 76), Vector2(27, 78), Vector2(22, 76)]), INK.lerp(WARM, 0.5))
    draw_rect(Rect2(27, 74, 1, 4), Color("2b2742"))
    _building(Rect2(289, 86, 28, 27), 2, true)
    _tree(282, 111, 24)
    _planter(276, 109, 13)
    # A small tiered fountain sits wholly in the right-hand square.
    draw_rect(Rect2(294, 110, 23, 3), Color("3f3a51"))
    draw_rect(Rect2(297, 108, 17, 2), INK.lerp(accent, 0.38))
    draw_rect(Rect2(304, 98, 3, 10), Color("4a3f57"))
    draw_rect(Rect2(300, 99, 11, 2), INK.lerp(accent, 0.38))
    draw_rect(Rect2(305, 95, 1, 4), INK.lerp(accent, 0.6))
    draw_rect(Rect2(299, 102, 1, 6), INK.lerp(accent, 0.25))
    draw_rect(Rect2(311, 102, 1, 6), INK.lerp(accent, 0.25))

func _harbor_lights() -> void:
    _water(102, 122)
    _building(Rect2(3, 90, 34, 17), 1, true)
    draw_colored_polygon(PackedVector2Array([Vector2(2, 90), Vector2(10, 83), Vector2(28, 83), Vector2(38, 90)]), Color("39334c"))
    draw_rect(Rect2(0, 107, 45, 4), Color("382b43"))
    for x in [5.0, 21.0, 37.0]:
        draw_rect(Rect2(x, 111, 2, 8), Color("3b3345"))
    # Keep the lantern below the upper-right gameplay cat, on the same breakwater.
    draw_colored_polygon(PackedVector2Array([Vector2(286, 111), Vector2(290, 85), Vector2(301, 85), Vector2(305, 111)]), Color("434054"))
    draw_colored_polygon(PackedVector2Array([Vector2(289, 93), Vector2(302, 93), Vector2(303, 99), Vector2(288, 99)]), INK.lerp(ROSE, 0.29))
    draw_rect(Rect2(288, 83, 15, 3), INK.lerp(accent, 0.45))
    draw_rect(Rect2(290, 74, 11, 9), Color("39334c"))
    draw_rect(Rect2(292, 76, 7, 5), INK.lerp(accent, 0.65))
    draw_rect(Rect2(295, 76, 1, 5), Color("39334c"))
    draw_colored_polygon(PackedVector2Array([Vector2(287, 74), Vector2(295, 68), Vector2(304, 74)]), Color("45304b"))
    draw_rect(Rect2(294, 103, 3, 8), Color("15182d"))
    draw_colored_polygon(PackedVector2Array([Vector2(276, 113), Vector2(282, 109), Vector2(311, 109), Vector2(319, 115), Vector2(319, 119), Vector2(276, 119)]), Color("29263d"))
    draw_rect(Rect2(0, 122, 320, 1), INK.lerp(accent, 0.24))
    draw_rect(Rect2(49, 99, 1, 11), Color("474054"))
    draw_colored_polygon(PackedVector2Array([Vector2(48, 99), Vector2(48, 107), Vector2(41, 107)]), Color("48405b"))
    draw_colored_polygon(PackedVector2Array([Vector2(40, 111), Vector2(57, 111), Vector2(53, 114), Vector2(43, 114)]), Color("51344b"))

func _clockwork_district() -> void:
    _building(Rect2(4, 89, 16, 24), 2, true)
    _building(Rect2(21, 76, 24, 37), 0, true)
    for tier in 3:
        draw_rect(Rect2(20 + tier * 3, 75 - tier * 4, 26 - tier * 6, 4), Color("37283e"))
        draw_rect(Rect2(20 + tier * 3, 75 - tier * 4, 26 - tier * 6, 1), INK.lerp(accent, 0.4))
    # A recessed brass mechanism makes the workshop distinct from the clocktower.
    draw_rect(Rect2(25, 81, 16, 22), Color("131428"))
    var gear_center := Vector2(33, 91)
    var brass := INK.lerp(accent, 0.39)
    draw_arc(gear_center, 5, 0, TAU, 16, brass, 2)
    for tooth in 8:
        var direction := Vector2.from_angle(float(tooth) * TAU / 8.0)
        var at := (gear_center + direction * 6).floor()
        draw_rect(Rect2(at, Vector2(2, 2)), brass)
    draw_line(gear_center + Vector2(-4, 0), gear_center + Vector2(4, 0), brass, 1)
    draw_line(gear_center + Vector2(0, -4), gear_center + Vector2(0, 4), brass, 1)
    draw_rect(Rect2(32, 97, 2, 4), Color("65505a"))
    draw_rect(Rect2(28, 101, 10, 2), Color("45334a"))
    draw_rect(Rect2(28, 107, 10, 4), INK.lerp(WARM, 0.23))
    _building(Rect2(278, 93, 14, 20), 1)
    _building(Rect2(293, 61, 20, 52), 0)
    draw_rect(Rect2(290, 82, 26, 3), INK.lerp(accent, 0.31))
    draw_rect(Rect2(291, 60, 24, 3), INK.lerp(accent, 0.42))
    draw_colored_polygon(PackedVector2Array([Vector2(291, 60), Vector2(303, 44), Vector2(315, 60)]), Color("45304b"))
    draw_line(Vector2(303, 44), Vector2(303, 40), INK.lerp(accent, 0.5), 1)
    var center := Vector2(303, 72)
    draw_circle(center, 8, Color("101426"))
    draw_arc(center, 8, 0, TAU, 24, INK.lerp(accent, 0.52), 1)
    for index in 4:
        var direction := Vector2.from_angle(float(index) * PI / 2.0)
        draw_line(center + direction * 5, center + direction * 6, INK.lerp(accent, 0.57), 1)
    var hand := Vector2.from_angle(-PI / 2.0 + floorf(background_clock) * TAU / 240.0)
    draw_line(center, center + hand * 5, INK.lerp(accent, 0.72), 1)
    draw_line(center, center + Vector2(3, 2), INK.lerp(WARM, 0.65), 1)
    for x in [297.0, 306.0]:
        draw_rect(Rect2(x, 90, 3, 7), INK.lerp(WARM, 0.3))
        draw_rect(Rect2(x, 103, 3, 6), INK.lerp(accent, 0.22))
    draw_rect(Rect2(276, 111, 41, 2), Color("50404f"))

func _sky_gardens() -> void:
    _building(Rect2(4, 90, 43, 23), 2)
    _building(Rect2(7, 75, 33, 15), 1, true)
    _building(Rect2(10, 62, 23, 13), 1)
    _planter(5, 88, 40)
    _planter(8, 73, 30)
    _planter(11, 60, 21)
    _tree(19, 60, 17, true)
    _tree(35, 88, 15)
    _building(Rect2(279, 87, 38, 26), 2, true)
    _building(Rect2(293, 72, 24, 15), 1)
    _tree(307, 72, 20, true)
    _tree(284, 87, 16)
    _planter(293, 70, 23)
    _planter(279, 85, 38)
    # Hanging vines belong to the terrace lips, not floating islands.
    for index in 5:
        var x := float(280 + index * 8)
        var length := float(4 + posmod(index * 3, 7))
        draw_rect(Rect2(x, 89, 1, length), Color("345353"))
        draw_rect(Rect2(x + 1, 91, 2, 2), Color("345353"))
    for index in 4:
        var x := float(8 + index * 9)
        draw_rect(Rect2(x, 92, 1, 5 + posmod(index * 3, 5)), Color("345353"))
    draw_rect(Rect2(279, 111, 38, 2), INK.lerp(accent, 0.35))

func _crystal_avenue() -> void:
    _crystal(4, 83, 16, 30)
    _crystal(20, 64, 24, 49)
    _crystal(43, 95, 10, 18)
    _crystal(278, 80, 16, 33)
    _crystal(294, 50, 23, 63)
    draw_rect(Rect2(2, 112, 53, 3), Color("35283f"))
    draw_rect(Rect2(276, 112, 42, 3), Color("35283f"))
    draw_rect(Rect2(2, 112, 53, 1), INK.lerp(accent, 0.42))
    draw_rect(Rect2(276, 112, 42, 1), INK.lerp(accent, 0.42))
    for x in [10.0, 45.0, 281.0, 312.0]:
        draw_rect(Rect2(x, 118, 2, 5), INK.lerp(accent, 0.18))
    # Inlaid avenue edges widen toward the viewer and leave the playfield dark.
    var edge := INK.lerp(accent, 0.19)
    draw_line(Vector2(113, 114), Vector2(32, 180), edge, 1)
    draw_line(Vector2(207, 114), Vector2(288, 180), edge, 1)
    for side in 2:
        for index in 2:
            var x := float(20 + index * 8)
            if side == 1:
                x = 320.0 - x
            var y := float(139 + index * 22)
            var radius := float(3 + index)
            var diamond := PackedVector2Array([Vector2(x, y - 2), Vector2(x + radius, y), Vector2(x, y + 2), Vector2(x - radius, y), Vector2(x, y - 2)])
            draw_colored_polygon(diamond.slice(0, 4), INK.lerp(Color("83bcff"), 0.075))
            draw_polyline(diamond, edge, 0.5)

func _crystal(x: float, top: float, width: float, height: float) -> void:
    var shoulder := floorf(top + width * 0.55)
    var bottom := top + height
    var ridge := x + floorf(width * 0.55)
    var tip := Vector2(ridge, top)
    var left := Vector2(x, shoulder)
    var right := Vector2(x + width, shoulder + 3)
    var foot_left := Vector2(x + 2, bottom)
    var foot_right := Vector2(x + width - 2, bottom)
    var foot_ridge := Vector2(ridge - 2, bottom)
    var junction := Vector2(ridge - 2, floorf(shoulder + (bottom - shoulder) * 0.46))
    draw_colored_polygon(PackedVector2Array([left, tip, right, foot_right, foot_left]), Color("2d2847"))
    draw_colored_polygon(PackedVector2Array([tip, right, junction]), Color("493247"))
    draw_colored_polygon(PackedVector2Array([right, foot_right, foot_ridge, junction]), Color("35233f"))
    draw_colored_polygon(PackedVector2Array([left, junction, foot_left]), Color("31344c"))
    draw_colored_polygon(PackedVector2Array([junction, foot_right, foot_ridge]), Color("443047"))
    var edge := INK.lerp(accent, 0.44)
    draw_polyline(PackedVector2Array([left, tip, right]), edge, 1)
    draw_polyline(PackedVector2Array([tip, junction, foot_ridge]), INK.lerp(accent, 0.27), 1)
    draw_polyline(PackedVector2Array([left, junction, right]), INK.lerp(Color("83bcff"), 0.25), 0.5)
    draw_line(junction, foot_right, INK.lerp(accent, 0.2), 0.5)
