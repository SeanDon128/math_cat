extends RefCounted

signal assignments_changed()

enum Controls { KEYBOARD, CONTROLLERS }

const KEY_CHOICES := [[KEY_S, KEY_D, KEY_A, KEY_W], [KEY_DOWN, KEY_RIGHT, KEY_LEFT, KEY_UP]]
const BUTTON_CHOICES := [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y]
const DPAD_CHOICES := [JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_UP]

var controls := Controls.CONTROLLERS
var devices: Array[int] = [-1, -1]
var connected_devices: Callable = Input.get_connected_joypads
var _held: Dictionary = {}

func reset() -> void:
    controls = Controls.CONTROLLERS
    devices.assign([-1, -1])
    assignments_changed.emit()

func refresh_devices() -> void:
    var connected: Array = connected_devices.call()
    var changed := false
    for player in 2:
        if devices[player] >= 0 and not connected.has(devices[player]):
            devices[player] = -1
            changed = true
    if changed:
        assignments_changed.emit()

func complete() -> bool:
    return controls == Controls.KEYBOARD or (devices[0] >= 0 and devices[1] >= 0)

func join(device: int) -> bool:
    refresh_devices()
    if not (connected_devices.call() as Array).has(device) or devices.has(device):
        return false
    var slot := devices.find(-1)
    if slot < 0:
        return false
    devices[slot] = device
    assignments_changed.emit()
    return true

func status_text() -> String:
    var slots: Array[String] = []
    for player in 2:
        slots.append("P%d: %s" % [player + 1, "Controller %d" % devices[player] if devices[player] >= 0 else "NOT JOINED"])
    return "   |   ".join(slots)

func fresh_press(event: InputEvent) -> bool:
    var identity := ""
    if event is InputEventKey:
        var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
        identity = "key:%d" % code
        if event.echo:
            return false
    elif event is InputEventJoypadButton:
        identity = "pad:%d:%d" % [event.device, event.button_index]
    else:
        return false
    if not event.is_pressed():
        _held.erase(identity)
        return false
    if _held.has(identity):
        return false
    _held[identity] = true
    return true

func answer(event: InputEvent) -> Vector2i:
    if controls == Controls.KEYBOARD and event is InputEventKey:
        var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
        for player in 2:
            var index: int = KEY_CHOICES[player].find(code)
            if index >= 0:
                return Vector2i(player, index)
    elif controls == Controls.CONTROLLERS and event is InputEventJoypadButton:
        var player := devices.find(event.device)
        var index := BUTTON_CHOICES.find(event.button_index)
        if index < 0:
            index = DPAD_CHOICES.find(event.button_index)
        if player >= 0 and index >= 0:
            return Vector2i(player, index)
    return Vector2i(-1, -1)
