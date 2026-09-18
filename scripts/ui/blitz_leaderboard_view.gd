extends VBoxContainer

const Store = preload("res://scripts/blitz/blitz_leaderboard_store.gd")

var store: Store = BlitzLeaderboard
var two_player := false
var two_columns := false

func display(grade: int, highlighted_rank: int = -1) -> void:
    for child in get_children():
        remove_child(child)
        child.queue_free()
    add_theme_constant_override("separation", 1)
    _add_row("%s  -  GRADE %d  -  LOCAL TOP 10" % ["TWO PLAYERS" if two_player else "SOLO", grade], Color("f0d35e"), 22)
    if not store.last_error.is_empty():
        _add_row(store.last_error, Color("ffb4b4"), 18)
        return
    var entries := store.board(grade)
    if entries.is_empty():
        _add_row("No scores yet. Finish a round with a positive score!", Color("ebf0f7"), 20)
        return
    var columns: Array[VBoxContainer] = []
    if two_columns and entries.size() > 5:
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 24)
        add_child(row)
        for index in 2:
            var column := VBoxContainer.new()
            column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            column.add_theme_constant_override("separation", 1)
            row.add_child(column)
            columns.append(column)
    for index in entries.size():
        var entry: Dictionary = entries[index]
        var marker := "> " if index == highlighted_rank else ""
        var label := _add_row("%s%2d.   %s     %d" % [marker, index + 1, entry.initials, int(entry.score)], Color("f0d35e") if index == highlighted_rank else Color("ebf0f7"), 18)
        if not columns.is_empty():
            label.reparent(columns[0 if index < 5 else 1])

func _add_row(text: String, color: Color, font_size: int) -> Label:
    var label := Label.new()
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_color_override("font_color", color)
    label.add_theme_font_size_override("font_size", font_size)
    add_child(label)
    return label
