extends CanvasLayer

const GameScene = preload("res://scenes/game/game.tscn")
const Main = preload("res://scripts/main.gd")
const PREVIEW_PATH := "user://blitz-results-preview.json"
const SCENARIOS := ["Winner initials", "Draw / empty", "Negative winner", "Full / no entry", "Saved / full", "Save error"]

var _game: Control
var _repair_button: Button
var _busy := false
var _clock_offset := 0
var _scenario_serial := 0

func _ready() -> void:
    # Keep the selector alive when the real Title button changes scenes.
    get_tree().current_scene = null
    layer = 100
    var main := Main.new()
    main._configure_input_map()
    main.free()
    GameManager.clock_msec = func(): return Time.get_ticks_msec() + _clock_offset
    DisplayServer.window_set_title("Math Cat - Interactive Two-Player Results Preview")
    var panel := PanelContainer.new()
    panel.position = Vector2(8, 80)
    panel.custom_minimum_size.x = 200
    add_child(panel)
    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 12)
    panel.add_child(layout)
    var heading := Label.new()
    heading.text = "RESULTS PREVIEW\nClick a screen below.\nTest scores only."
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    heading.add_theme_font_size_override("font_size", 16)
    layout.add_child(heading)
    for scenario in SCENARIOS:
        var button := Button.new()
        button.text = scenario
        button.custom_minimum_size.y = 40
        button.focus_mode = Control.FOCUS_NONE
        button.pressed.connect(_select.bind(scenario))
        layout.add_child(button)
    _repair_button = Button.new()
    _repair_button.text = "Enable saving"
    _repair_button.custom_minimum_size.y = 40
    _repair_button.focus_mode = Control.FOCUS_NONE
    _repair_button.pressed.connect(_repair_save)
    layout.add_child(_repair_button)
    await _select("Draw / empty")
    if "--verify" in OS.get_cmdline_user_args():
        await _verify()
    else:
        print("Interactive results preview ready. Use the left-hand screen selector.")

func _frames() -> void:
    for index in 4:
        await get_tree().process_frame

func _select(scenario: String) -> void:
    if _busy:
        return
    _busy = true
    _scenario_serial += 1
    _repair_button.visible = scenario == "Save error"
    _repair_button.disabled = false
    var previous := get_tree().current_scene
    if previous != null:
        get_tree().root.remove_child(previous)
        previous.queue_free()
    await _frames()
    GameManager.abandon_current_session()
    BlitzDuelLeaderboard.storage_path = PREVIEW_PATH
    if FileAccess.file_exists(PREVIEW_PATH):
        var remove_error := DirAccess.remove_absolute(PREVIEW_PATH)
        if remove_error != OK:
            _fail("Could not reset preview scores: %s" % error_string(remove_error))
            return
    if not BlitzDuelLeaderboard.reload():
        _fail(BlitzDuelLeaderboard.last_error)
        return
    if scenario in ["Full / no entry", "Saved / full"]:
        for points in range(20, 30):
            if BlitzDuelLeaderboard.submit(1, points, "TOP") < 0:
                _fail(BlitzDuelLeaderboard.last_error)
                return
    if scenario == "Save error":
        BlitzDuelLeaderboard.storage_path = "user://preview-missing-%d/scores.json" % _scenario_serial
    GameManager.duel_input.reset()
    GameManager.duel_input.controls = GameManager.DuelInput.Controls.KEYBOARD
    GameManager.start_blitz_session(1, 2)
    _game = GameScene.instantiate()
    get_tree().root.add_child(_game)
    get_tree().current_scene = _game
    await _frames()
    var correct: Array[int] = [11, 14]
    var incorrect: Array[int] = [2, 2]
    if scenario == "Draw / empty":
        correct.assign([0, 0])
        incorrect.assign([0, 0])
    elif scenario == "Negative winner":
        correct.assign([0, 0])
        incorrect.assign([2, 1])
    elif scenario == "Saved / full":
        correct[1] = 34
    GameManager.duel_round.correct.assign(correct)
    GameManager.duel_round.incorrect.assign(incorrect)
    for player in 2:
        GameManager.duel_round.scores[player] = correct[player] - incorrect[player]
        _game.duel_panels[player].update_score(GameManager.duel_round.scores[player])
    _clock_offset += GameManager.BLITZ_TIME_MSEC
    GameManager.sync_blitz_clock()
    if scenario in ["Saved / full", "Save error"]:
        _game.blitz_results._save_score("CAT")
    await _frames()
    _busy = false

func _repair_save() -> void:
    BlitzDuelLeaderboard.storage_path = PREVIEW_PATH
    if not BlitzDuelLeaderboard.reload():
        _fail(BlitzDuelLeaderboard.last_error)
        return
    if is_instance_valid(_game) and _game.blitz_results.initials_entry != null:
        _game.blitz_results.initials_entry.show_save_error("Preview storage restored. Enter initials and choose Retry Save.")
    _repair_button.disabled = true

func _fail(message: String) -> void:
    push_error(message)
    get_tree().quit(1)

func _verify() -> void:
    for scenario in SCENARIOS:
        await _select(scenario)
        assert(GameManager.current_state == GameManager.GameState.GAME_OVER)
        assert(_game.blitz_results.visible)
        var bounds: Rect2 = _game.blitz_results.get_child(1).get_global_rect()
        assert(Rect2(0, 0, 1280, 720).encloses(bounds))
        if scenario in ["Winner initials", "Save error"]:
            assert(_game.blitz_results.initials_entry != null)
        else:
            assert(_game.blitz_results.board_view != null)
        if "--capture" in OS.get_cmdline_user_args():
            hide()
            await RenderingServer.frame_post_draw
            assert(get_viewport().get_texture().get_image().save_png("user://duel-results-%d.png" % SCENARIOS.find(scenario)) == OK)
            show()
        if scenario == "Save error":
            assert(_game.blitz_results.initials_entry.save_button.text == "RETRY SAVE")
            _repair_save()
            _game.blitz_results._save_score("CAT")
            assert(not GameManager.has_pending_blitz_result())
    _game.blitz_results.retry_button.pressed.emit()
    await _frames()
    assert(GameManager.current_state == GameManager.GameState.PLAYING)
    assert(GameManager.is_two_player_blitz())
    await _select("Draw / empty")
    _game.blitz_results.title_button.pressed.emit()
    await _frames()
    assert(GameManager.current_state == GameManager.GameState.TITLE)
    assert(is_inside_tree(), "The preview selector must survive Title navigation.")
    await _select("Winner initials")
    assert(_game.blitz_results.initials_entry != null)
    GameManager.clock_msec = Time.get_ticks_msec
    GameManager.abandon_current_session()
    _game.queue_free()
    _game = null
    await _frames()
    print("Interactive Blitz results preview checks passed.")
    get_tree().quit()
