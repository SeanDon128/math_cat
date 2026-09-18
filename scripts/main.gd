extends Node

func _ready() -> void:
    _configure_input_map()
    GameManager.goto_scene("res://scenes/title/title.tscn")

func _configure_input_map() -> void:
    _add_keys_and_button("answer_1", [KEY_A], JOY_BUTTON_A)
    _add_keys_and_button("answer_2", [KEY_B], JOY_BUTTON_B)
    _add_keys_and_button("answer_3", [KEY_X], JOY_BUTTON_X)
    _add_keys_and_button("answer_4", [KEY_Y], JOY_BUTTON_Y)
    _add_keys_and_button("pause", [KEY_ESCAPE], JOY_BUTTON_START)
    InputMap.action_erase_events("ui_accept")
    _add_keys_and_button("ui_accept", [KEY_ENTER], JOY_BUTTON_A)
    _add_keys_and_button("ui_cancel", [KEY_ESCAPE], JOY_BUTTON_B)
    _add_keys_and_button("ui_up", [KEY_UP, KEY_W], JOY_BUTTON_DPAD_UP)
    _add_keys_and_button("ui_down", [KEY_DOWN, KEY_S], JOY_BUTTON_DPAD_DOWN)
    _add_keys_and_button("ui_left", [KEY_LEFT, KEY_A], JOY_BUTTON_DPAD_LEFT)
    _add_keys_and_button("ui_right", [KEY_RIGHT, KEY_D], JOY_BUTTON_DPAD_RIGHT)

func _add_keys_and_button(action: StringName, keycodes: Array[Key], button: JoyButton) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)

    for keycode in keycodes:
        var key_event := InputEventKey.new()
        key_event.keycode = keycode
        InputMap.action_add_event(action, key_event)

    var button_event := InputEventJoypadButton.new()
    button_event.device = -1
    button_event.button_index = button
    InputMap.action_add_event(action, button_event)
