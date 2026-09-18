extends VBoxContainer

signal submitted(initials: String)
signal skipped()

var letters: Array[String] = ["", "", ""]
var slots: Array[Button] = []
var save_button: Button
var skip_button: Button
var message_label: Label
var selected_index := 0
var _navigation_ready_at := 0

func _ready() -> void:
    add_theme_constant_override("separation", 12)
    var hint := Label.new()
    hint.text = "Enter 3 letters (A-Z)\nController: LEFT/RIGHT selects a slot, UP/DOWN changes a letter."
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_font_size_override("font_size", 20)
    add_child(hint)
    var row := HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_theme_constant_override("separation", 18)
    add_child(row)
    for index in 3:
        var slot := Button.new()
        slot.text = "_"
        slot.custom_minimum_size = Vector2(90, 64)
        slot.add_theme_font_size_override("font_size", 36)
        slot.pressed.connect(_cycle_slot.bind(index))
        slot.focus_entered.connect(_sync_focus.bind(index))
        row.add_child(slot)
        slots.append(slot)
    message_label = Label.new()
    message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message_label.add_theme_color_override("font_color", Color("ffb4b4"))
    message_label.add_theme_font_size_override("font_size", 18)
    add_child(message_label)
    save_button = _button("SAVE SCORE", _submit, 3)
    skip_button = _button("SKIP", func(): skipped.emit(), 4)
    focus_control(0)

func _button(text: String, callback: Callable, index: int) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size.y = 44
    button.add_theme_font_size_override("font_size", 24)
    button.pressed.connect(callback)
    button.focus_entered.connect(_sync_focus.bind(index))
    add_child(button)
    return button

func handle_input(event: InputEvent) -> bool:
    if event is InputEventKey:
        if not event.pressed or event.echo:
            return true
        if event.keycode >= KEY_A and event.keycode <= KEY_Z:
            if selected_index > 2:
                focus_control(0)
            letters[selected_index] = String.chr(event.keycode)
            slots[selected_index].text = letters[selected_index]
            focus_control(mini(selected_index + 1, 3))
            return true
        if event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE:
            var index := mini(selected_index, 2)
            if letters[index].is_empty() and index > 0 and event.keycode == KEY_BACKSPACE:
                index -= 1
            letters[index] = ""
            slots[index].text = "_"
            focus_control(index)
            return true
    elif event is InputEventJoypadMotion:
        if absf(event.axis_value) < 0.65 or (event.axis != JOY_AXIS_LEFT_X and event.axis != JOY_AXIS_LEFT_Y):
            return true
        if not _accept_navigation():
            return true
        var direction := -1 if event.axis_value < 0 else 1
        if event.axis == JOY_AXIS_LEFT_X:
            focus_control(clampi(selected_index + direction, 0, 4))
        else:
            _vertical(direction)
        return true
    elif not event is InputEventJoypadButton:
        return false
    if not event.is_pressed():
        return true
    if event.is_action_pressed("ui_cancel"):
        skipped.emit()
    elif event.is_action_pressed("ui_left"):
        focus_control(maxi(selected_index - 1, 0))
    elif event.is_action_pressed("ui_right"):
        focus_control(mini(selected_index + 1, 4))
    elif event.is_action_pressed("ui_up"):
        _vertical(-1)
    elif event.is_action_pressed("ui_down"):
        _vertical(1)
    elif event.is_action_pressed("ui_accept"):
        if selected_index < 3:
            if letters[selected_index].is_empty():
                _cycle_slot(selected_index)
            focus_control(selected_index + 1)
        elif selected_index == 3:
            _submit()
        else:
            skipped.emit()
    return true

func _accept_navigation() -> bool:
    var now := Time.get_ticks_msec()
    if now < _navigation_ready_at:
        return false
    _navigation_ready_at = now + 100
    return true

func _vertical(direction: int) -> void:
    if selected_index < 3:
        _cycle_slot(selected_index, direction)
    else:
        focus_control(clampi(selected_index + direction, 2, 4))

func _cycle_slot(index: int, direction: int = 1) -> void:
    var current := letters[index].unicode_at(0) - 65 if not letters[index].is_empty() else (-1 if direction > 0 else 0)
    letters[index] = String.chr(65 + posmod(current + direction, 26))
    slots[index].text = letters[index]

func _sync_focus(index: int) -> void:
    selected_index = index

func focus_control(index: int) -> void:
    selected_index = index
    if index < 3:
        slots[index].grab_focus()
    elif index == 3:
        save_button.grab_focus()
    else:
        skip_button.grab_focus()

func _submit() -> void:
    var initials := "".join(letters)
    if not BlitzLeaderboard.valid_initials(initials):
        message_label.text = "Enter exactly three letters, A-Z."
        return
    save_button.disabled = true
    submitted.emit(initials)

func show_save_error(message: String) -> void:
    message_label.text = message
    save_button.text = "RETRY SAVE"
    save_button.disabled = false
