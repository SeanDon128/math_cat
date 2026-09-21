extends Control

signal retry_requested()
signal title_requested()

const BoardView = preload("res://scripts/ui/blitz_leaderboard_view.gd")
const InitialsEntry = preload("res://scripts/ui/blitz_initials_entry.gd")
const Store = preload("res://scripts/blitz/blitz_leaderboard_store.gd")

var initials_entry: InitialsEntry
var board_view: BoardView
var retry_button: Button
var title_button: Button
var _layout: VBoxContainer
var _result: Dictionary = {}
var _selected_action := 0
var _navigation_ready_at := 0
var _store: Store = BlitzLeaderboard
var _two_player := false

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var dimmer := ColorRect.new()
    dimmer.color = Color(0.02, 0.03, 0.06, 0.92)
    dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(dimmer)
    var panel := PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    panel.offset_left = -420
    panel.offset_right = 420
    panel.offset_top = -330
    panel.offset_bottom = 330
    var style := StyleBoxFlat.new()
    style.bg_color = Color("1a243c")
    style.border_color = Color("f0d35e")
    style.set_border_width_all(3)
    panel.add_theme_stylebox_override("panel", style)
    add_child(panel)
    var margin := MarginContainer.new()
    for edge in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + edge, 20)
    panel.add_child(margin)
    _layout = VBoxContainer.new()
    _layout.alignment = BoxContainer.ALIGNMENT_CENTER
    _layout.add_theme_constant_override("separation", 8)
    margin.add_child(_layout)

func present(result: Dictionary) -> void:
    _result = result.duplicate(true)
    _two_player = bool(_result.get("two_player", false))
    _layout.add_theme_constant_override("separation", 6 if _two_player else 8)
    _store = BlitzDuelLeaderboard if _two_player else BlitzLeaderboard
    show()
    _store.reload()
    var has_winner := not _two_player or int(_result.winner) >= 0
    var entering_initials := has_winner and int(_result.score) > 0 and (not _store.last_error.is_empty() or _store.qualifying_rank(int(_result.grade), int(_result.score)) >= 0)
    _build_header()
    if entering_initials:
        _label("PLAYER %d - WINNER'S INITIALS" % (int(_result.winner) + 1) if _two_player else "LOCAL HIGH SCORE ENTRY", 24, Color("f0d35e"))
        initials_entry = InitialsEntry.new()
        _layout.add_child(initials_entry)
        initials_entry.submitted.connect(_save_score)
        initials_entry.skipped.connect(_skip_score)
        if not _store.last_error.is_empty():
            initials_entry.show_save_error(_store.last_error)
    else:
        GameManager.skip_blitz_result()
        _show_board()

func _build_header() -> void:
    for child in _layout.get_children():
        _layout.remove_child(child)
        child.queue_free()
    initials_entry = null
    board_view = null
    retry_button = null
    title_button = null
    _label("BLITZ COMPLETE", 32 if _two_player else 36, Color("f0d35e"))
    if _two_player:
        _label("DRAW" if int(_result.winner) < 0 else "PLAYER %d WINS!" % (int(_result.winner) + 1), 28, Color("f0d35e"))
        _section_gap()
        _label("Grade %d   |   Two Players   |   %d seconds" % [int(_result.grade), GameManager.BLITZ_TIME_MSEC / 1000], 22)
        for player in 2:
            var stats: Dictionary = _result.players[player]
            var attempts := int(stats.correct) + int(stats.incorrect)
            var accuracy := roundi(100.0 * int(stats.correct) / attempts) if attempts > 0 else 0
            _label("P%d  Score: %d   Correct: %d   Wrong: %d   Accuracy: %d%%" % [player + 1, int(stats.score), int(stats.correct), int(stats.incorrect), accuracy], 18)
        _section_gap()
        return
    _label("Grade %d   |   Score: %d   |   %d seconds" % [int(_result.grade), int(_result.score), GameManager.BLITZ_TIME_MSEC / 1000], 26)
    var correct := int(_result.correct)
    var incorrect := int(_result.incorrect)
    var accuracy := roundi(100.0 * correct / (correct + incorrect)) if correct + incorrect > 0 else 0
    _label("Correct: %d   Incorrect: %d   Accuracy: %d%%" % [correct, incorrect, accuracy], 22)

func _save_score(initials: String) -> void:
    var rank := GameManager.submit_blitz_result(initials)
    if rank < 0:
        initials_entry.show_save_error(_store.last_error)
        return
    _show_board(rank)

func _skip_score() -> void:
    GameManager.skip_blitz_result()
    _show_board()

func _show_board(highlighted_rank: int = -1) -> void:
    _build_header()
    board_view = BoardView.new()
    board_view.store = _store
    board_view.two_player = _two_player
    board_view.two_columns = _two_player
    _layout.add_child(board_view)
    board_view.display(int(_result.grade), highlighted_rank)
    if highlighted_rank >= 0:
        _label("SCORE SAVED", 20, Color("79d26a"))
    if _two_player:
        _section_gap()
    retry_button = _button("RETRY BLITZ", func(): retry_requested.emit())
    title_button = _button("TITLE SCREEN", func(): title_requested.emit())
    retry_button.focus_entered.connect(func(): _selected_action = 0)
    title_button.focus_entered.connect(func(): _selected_action = 1)
    retry_button.grab_focus()

func handle_input(event: InputEvent) -> bool:
    if initials_entry != null:
        return initials_entry.handle_input(event)
    if event is InputEventJoypadMotion:
        if event.axis == JOY_AXIS_LEFT_Y and absf(event.axis_value) >= 0.65 and Time.get_ticks_msec() >= _navigation_ready_at:
            _navigation_ready_at = Time.get_ticks_msec() + 100
            _focus_action(1 - _selected_action)
        return true
    if not (event is InputEventKey or event is InputEventJoypadButton):
        return false
    if not event.is_pressed() or (event is InputEventKey and event.echo):
        return true
    if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
        _focus_action(1 - _selected_action)
    elif event.is_action_pressed("ui_accept"):
        if _selected_action == 0:
            retry_requested.emit()
        else:
            title_requested.emit()
    elif event.is_action_pressed("ui_cancel"):
        title_requested.emit()
    return true

func _focus_action(index: int) -> void:
    _selected_action = index
    if index == 0:
        retry_button.grab_focus()
    else:
        title_button.grab_focus()

func _label(text: String, font_size: int, color: Color = Color("ebf0f7")) -> void:
    var label := Label.new()
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    _layout.add_child(label)

func _section_gap() -> void:
    var spacer := Control.new()
    spacer.custom_minimum_size.y = 20
    spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _layout.add_child(spacer)

func _button(text: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size.y = 44
    button.add_theme_font_size_override("font_size", 24)
    button.pressed.connect(callback)
    _layout.add_child(button)
    return button
