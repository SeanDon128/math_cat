extends Node

const DuelInput = preload("res://scripts/blitz/blitz_duel_input.gd")

func _ready() -> void:
    var router := DuelInput.new()
    assert(router.controls == DuelInput.Controls.CONTROLLERS and not router.complete(), "New two-player configurations require two controllers to join.")
    router.controls = DuelInput.Controls.KEYBOARD
    for player in 2:
        for index in 4:
            var key := InputEventKey.new()
            key.physical_keycode = DuelInput.KEY_CHOICES[player][index]
            key.pressed = true
            assert(router.fresh_press(key))
            assert(router.answer(key) == Vector2i(player, index))
            assert(not router.fresh_press(key), "Held keys are not new attempts.")
            key.echo = true
            assert(not router.fresh_press(key))
            key.echo = false
            key.pressed = false
            assert(not router.fresh_press(key))
            key.pressed = true
            assert(router.fresh_press(key))
    var connected: Array[int] = [7, 42, 100]
    router.connected_devices = func(): return connected
    router.controls = DuelInput.Controls.CONTROLLERS
    assert(router.join(42) and not router.join(42))
    assert(router.join(7) and router.complete())
    assert(not router.join(100))
    for player in 2:
        for buttons in [DuelInput.BUTTON_CHOICES, DuelInput.DPAD_CHOICES]:
            for index in 4:
                var event := InputEventJoypadButton.new()
                event.device = router.devices[player]
                event.button_index = buttons[index]
                event.pressed = true
                assert(router.fresh_press(event))
                assert(router.answer(event) == Vector2i(player, index))
                assert(not router.fresh_press(event), "Held D-pad and face buttons must not repeat.")
                event.pressed = false
                assert(not router.fresh_press(event))
    connected.erase(42)
    router.refresh_devices()
    assert(router.devices == [-1, 7] and not router.complete())
    assert(router.join(100) and router.devices == [100, 7])
    connected.clear()
    router.refresh_devices()
    assert(router.devices == [-1, -1])
    connected.assign([3, 19])
    assert(router.join(19) and router.join(3))
    var unassigned := InputEventJoypadButton.new()
    unassigned.device = 55
    unassigned.button_index = JOY_BUTTON_A
    assert(router.answer(unassigned) == Vector2i(-1, -1))
    unassigned.button_index = JOY_BUTTON_DPAD_UP
    assert(router.answer(unassigned) == Vector2i(-1, -1), "Unassigned controllers cannot use the D-pad to answer.")
    var assigned := InputEventJoypadButton.new()
    assigned.device = 19
    assigned.button_index = JOY_BUTTON_DPAD_UP
    assert(router.answer(assigned) == Vector2i(0, 3))
    router.reset()
    assert(router.controls == DuelInput.Controls.CONTROLLERS and router.devices == [-1, -1])
    assert(not router.complete(), "Reset restores controller mode without reusing assignments.")
    router.controls = DuelInput.Controls.KEYBOARD
    assert(router.answer(unassigned) == Vector2i(-1, -1), "Controllers cannot answer in keyboard mode.")
    assert(router.answer(assigned) == Vector2i(-1, -1), "D-pad input cannot bypass keyboard-only match configuration.")
    print("Blitz duel input smoke tests passed.")
    get_tree().quit()
