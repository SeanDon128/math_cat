extends Node2D

var items: Dictionary = {}
var icon_mode := false
var icon_item := ""
var icon_box_size := Vector2.ZERO

const ICON_BOUNDS := {
    "bow_tie": Rect2(11, 18, 10, 4),
    "bandana": Rect2(11, 18, 10, 7),
    "crown": Rect2(11, -1, 10, 7),
    "top_hat": Rect2(9, -4, 14, 10),
    "flower": Rect2(16, -1, 9, 8),
    "sunglasses": Rect2(9, 11, 15, 6),
    "bell_collar": Rect2(11, 18, 10, 6),
}

func configure_icon(item: String, box_size: Vector2) -> void:
    icon_mode = true
    icon_item = item
    icon_box_size = box_size
    queue_redraw()

func _draw() -> void:
    if icon_mode:
        if not icon_item.is_empty():
            var bounds: Rect2 = ICON_BOUNDS[icon_item]
            var factor := floorf(minf(icon_box_size.x / bounds.size.x, icon_box_size.y / bounds.size.y))
            draw_rect(Rect2(-icon_box_size / 2, icon_box_size), Color("638ab7"))
            draw_set_transform(-bounds.get_center().floor() * factor, 0, Vector2.ONE * factor)
            _draw_item(icon_item)
        return
    if items.is_empty():
        return
    var cat := get_parent() as AnimatedSprite2D
    var pose := Vector2.ZERO
    var index := cat.frame % 4
    # Match the logical-pixel poses in tools/generate_math_cat_sprites.py,
    # including pause/high_score aliases, so accessories never float during reactions.
    match String(cat.animation):
        "happy": pose.y = [0, -2, -4, -2][index]
        "sad": pose = Vector2([0, 0, 1, 1][index], [1, 1, 2, 2][index])
        "level_up", "high_score": pose.y = [0, -3, -5, -2][index]
        "game_over": pose.y = [2, 2, 3, 3][index]
        "evolution_pose": pose.y = [0, -1, -2, -1][index]
        _: pose.y = [0, 0, 1, 0][index]
    draw_set_transform(Vector2(-32, -32) + pose * 2, 0, Vector2(2, 2))
    for item in items.values():
        _draw_item(str(item))

func _draw_item(item: String) -> void:
    var outline := Color("2b2033")
    match item:
        "bow_tie":
            draw_rect(Rect2(11, 18, 10, 4), outline)
            draw_rect(Rect2(12, 18, 3, 4), Color("ef7f8d"))
            draw_rect(Rect2(17, 18, 3, 4), Color("ef7f8d"))
            draw_rect(Rect2(15, 19, 2, 2), Color("fff8df"))
        "bandana":
            draw_rect(Rect2(11, 18, 10, 3), outline)
            draw_rect(Rect2(13, 21, 6, 2), outline)
            draw_rect(Rect2(15, 23, 2, 2), outline)
            draw_rect(Rect2(12, 18, 8, 2), Color("4d8edb"))
            draw_rect(Rect2(14, 20, 4, 2), Color("4d8edb"))
            draw_rect(Rect2(15, 22, 2, 1), Color("fff8df"))
        "crown":
            draw_rect(Rect2(11, 0, 10, 6), outline)
            draw_rect(Rect2(12, 0, 2, 3), Color("ffd84a"))
            draw_rect(Rect2(15, -1, 2, 4), Color("ffd84a"))
            draw_rect(Rect2(18, 0, 2, 3), Color("ffd84a"))
            draw_rect(Rect2(12, 3, 8, 2), Color("ffd84a"))
            draw_rect(Rect2(15, 3, 2, 1), Color("ef7f8d"))
        "top_hat":
            draw_rect(Rect2(11, -4, 10, 9), outline)
            draw_rect(Rect2(12, -3, 8, 6), Color("25395f"))
            draw_rect(Rect2(12, 2, 8, 2), Color("ef7f8d"))
            draw_rect(Rect2(9, 4, 14, 2), outline)
            draw_rect(Rect2(10, 4, 12, 1), Color("4d8edb"))
        "flower":
            draw_rect(Rect2(19, 3, 2, 4), Color("31534f"))
            draw_rect(Rect2(17, 5, 3, 2), Color("8de58d"))
            draw_rect(Rect2(19, -1, 3, 8), outline)
            draw_rect(Rect2(16, 2, 9, 3), outline)
            draw_rect(Rect2(19, 0, 3, 6), Color("ef7f8d"))
            draw_rect(Rect2(17, 2, 7, 3), Color("ef7f8d"))
            draw_rect(Rect2(19, 2, 3, 3), Color("ffd84a"))
        "sunglasses":
            draw_rect(Rect2(9, 11, 15, 2), outline)
            draw_rect(Rect2(10, 11, 6, 6), outline)
            draw_rect(Rect2(17, 11, 6, 6), outline)
            draw_rect(Rect2(11, 12, 4, 3), Color("25395f"))
            draw_rect(Rect2(18, 12, 4, 3), Color("25395f"))
            draw_rect(Rect2(11, 12, 2, 1), Color("7ab8ff"))
            draw_rect(Rect2(18, 12, 2, 1), Color("7ab8ff"))
        "bell_collar":
            draw_rect(Rect2(11, 18, 10, 3), outline)
            draw_rect(Rect2(12, 18, 8, 2), Color("8de58d"))
            draw_rect(Rect2(14, 20, 5, 4), outline)
            draw_rect(Rect2(15, 20, 3, 3), Color("ffd84a"))
            draw_rect(Rect2(16, 22, 1, 1), Color("6d351f"))
