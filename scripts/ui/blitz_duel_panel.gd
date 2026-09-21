extends Control

const CatScene = preload("res://scenes/characters/math_cat.tscn")
const CatPalette = preload("res://shaders/blitz_cat_palette.gdshader")
const Stages = preload("res://scripts/character/math_cat_stages.gd")
const ACCENTS := [Color("d5adff"), Color("87dfff")]
const CAT_PALETTES := [
    [Color("e97824"), Color("ffad42"), Color("6d351f")],
    [Color("49b8ee"), Color("95e1ff"), Color("235778")],
]
var player := 0
var score_label: Label
var feedback: Label
var lockout_label: Label
var cat: MathCat

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    score_label = _label(self, 32, ACCENTS[player])
    score_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    score_label.offset_top = -104
    score_label.offset_bottom = -58
    lockout_label = _label(self, 16, Color("ffb4b4"))
    lockout_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    lockout_label.offset_top = -24
    lockout_label.hide()
    feedback = _label(self, 18, Color.WHITE)
    feedback.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    feedback.offset_top = -54
    feedback.offset_bottom = -28
    cat = CatScene.instantiate()
    var palette := ShaderMaterial.new()
    palette.shader = CatPalette
    palette.set_shader_parameter("fur_color", CAT_PALETTES[player][0])
    palette.set_shader_parameter("highlight_color", CAT_PALETTES[player][1])
    palette.set_shader_parameter("shadow_color", CAT_PALETTES[player][2])
    cat.material = palette
    cat.scale = Vector2(2, 2)
    add_child(cat)
    resized.connect(_update_cat_position)
    _update_cat_position()
    update_score(0)

func _label(parent: Node, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.add_theme_color_override("font_outline_color", Color.BLACK)
    label.add_theme_constant_override("outline_size", 2)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(label)
    return label

func _update_cat_position() -> void:
    if is_instance_valid(cat):
        cat.position = Vector2(size.x * 0.5, 92)

func clear_lockout() -> void:
    lockout_label.hide()
    if not feedback.text.is_empty():
        feedback.text = "LAST: +1 CORRECT" if feedback.text.contains("CORRECT") else "LAST: -1 WRONG"

func reset_cat(grade: int) -> void:
    cat.set_stage(Stages.stage_for_grade(grade))
    feedback.text = ""
    lockout_label.hide()

func update_score(points: int) -> void:
    score_label.text = "P%d SCORE %d" % [player + 1, points]

func react(is_correct: bool) -> void:
    feedback.text = "+1 CORRECT!" if is_correct else "-1 WRONG"
    feedback.modulate = (Color("79d26a") if player == 0 else Color("68b7ff")) if is_correct else Color("ffb4b4")
    if is_correct:
        cat.play_happy()
    else:
        lockout_label.text = "LOCKED OUT - NEXT QUESTION"
        lockout_label.show()
        cat.play_sad()
