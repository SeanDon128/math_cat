extends Node

const GameScene = preload("res://scenes/game/game.tscn")
const TitleScene = preload("res://scenes/title/title.tscn")
const MainScript = preload("res://scripts/main.gd")

var now_msec := 1000

func _ready() -> void:
    var main := MainScript.new()
    main._configure_input_map()
    main.free()
    GameManager.clock_msec = func(): return now_msec
    BlitzLeaderboard.storage_path = "user://blitz_ui_test.json"
    if FileAccess.file_exists(BlitzLeaderboard.storage_path):
        assert(DirAccess.remove_absolute(BlitzLeaderboard.storage_path) == OK)
    assert(BlitzLeaderboard.reload())
    await _test_title()
    await _test_game_and_initials()
    await _test_feedback_lifecycle()
    await _test_save_failure_and_skip()
    if "--real-time" in OS.get_cmdline_user_args():
        await _test_real_clock()
    GameManager.clock_msec = Time.get_ticks_msec
    if FileAccess.file_exists(BlitzLeaderboard.storage_path):
        assert(DirAccess.remove_absolute(BlitzLeaderboard.storage_path) == OK)
    AudioManager.stop_music()
    for player in AudioManager._players + AudioManager._music_players:
        player.stop()
        player.stream = null
    await get_tree().create_timer(0.25).timeout
    print("Blitz UI smoke tests passed.")
    get_tree().quit()

func _test_title() -> void:
    var title = TitleScene.instantiate()
    add_child(title)
    await get_tree().process_frame
    assert(title.main_buttons[0].text == "RETRO MODE" and title.main_buttons[1].text == "BLITZ")
    _assert_button_palette(title.main_buttons[1], Color("996608"), Color("b77e0c"))
    assert(title.main_buttons[1].get_theme_stylebox("normal").border_color == Color("ffef9a"), "Blitz must match the gameplay Y box border.")
    _assert_button_palette(title.main_buttons[2], Color("c4477f"), Color("d65b94"))
    _assert_button_palette(title.main_buttons[5], Color("b85410"), Color("d36a20"))
    _assert_in_viewport(title.get_node("Panel"), title)
    await _capture("title-menu-colors")
    title._activate_main_option(1)
    assert(title.active_view == "BLITZ MODE")
    assert(title.detail_layout.get_node("DetailSubtitle").text.begins_with("120 seconds."), "Blitz setup must describe the two-minute round.")
    _assert_button_palette(title.detail_buttons[2], Color("1a6b2e"), Color("26873d"))
    title._focus_detail(2)
    await _capture("blitz-setup-colors")
    var slider: HSlider = title.detail_buttons[0]
    assert(slider.min_value == 1 and slider.max_value == 13)
    slider.value = 13
    assert(title.selected_blitz_grade == 13)
    title._open_blitz_scores()
    await get_tree().process_frame
    assert(title.active_view == "BLITZ HIGH SCORES")
    _assert_in_viewport(title.detail_panel, title)
    _key(KEY_ESCAPE)
    assert(title.active_view == "BLITZ MODE" and title.selected_blitz_grade == 13)
    title.selected_blitz_players = 2
    title._open_blitz()
    _assert_button_palette(title.detail_buttons[3], Color("1a6b2e"), Color("26873d"))
    title._open_duel_join()
    _assert_button_palette(title._duel_join_start, Color("1a6b2e"), Color("26873d"))
    title.queue_free()
    await get_tree().process_frame

func _test_game_and_initials() -> void:
    GameManager.start_blitz_session(4)
    var game = GameScene.instantiate()
    add_child(game)
    assert(game.answer_locked, "The first question must be ready before the timer is armed.")
    await get_tree().process_frame
    await get_tree().process_frame
    assert(not game.answer_locked and GameManager.time_left == 120.0)
    assert(game.timer_label.text == "TIME 02:00", "Blitz gameplay must start at two minutes.")
    await _capture("blitz-two-minute-clock")
    assert(game.grade_label.text == "BLITZ\nGRADE 4")
    assert(not game.get_node("%HeartContainer").visible)
    assert(not game.get_node("%HeaderBar").get_node("Margin/Header/LivesLabel").visible)
    assert(not game.correct_pips[0].is_visible_in_tree())
    var answered_question = game.current_question
    var answer_index: int = answered_question.choices.find(answered_question.correct_answer)
    _answer(game, true)
    assert(GameManager.score == 1 and game.answer_locked)
    assert(game.answer_buttons[answer_index].get_theme_stylebox("disabled") == game.correct_answer_style)
    _answer(game, false)
    assert(GameManager.score == 1, "Feedback must block duplicate answers.")
    await get_tree().create_timer(0.55).timeout
    assert(game.answer_locked and game.current_question == answered_question, "Keep the answered question visible for 0.7 seconds.")
    await get_tree().create_timer(0.25).timeout
    assert(not game.answer_locked)
    answer_index = game.current_question.choices.find(game.current_question.correct_answer)
    _answer(game, false)
    assert(GameManager.score == 0 and GameManager.total_incorrect_answers == 1)
    assert(game.answer_buttons[(answer_index + 1) % 4].get_theme_stylebox("disabled") == game.incorrect_answer_style)
    assert(game.answer_buttons[answer_index].get_theme_stylebox("disabled") == game.revealed_answer_style)
    await get_tree().create_timer(1.05).timeout
    _answer(game, false)
    assert(game.score_label.text == "SCORE -1")
    await get_tree().create_timer(1.05).timeout
    _answer(game, true)
    await get_tree().create_timer(1.05).timeout
    _answer(game, true)
    await get_tree().create_timer(1.05).timeout
    var total := GameManager.total_correct_answers + GameManager.total_incorrect_answers
    var repeat := InputEventKey.new()
    repeat.keycode = KEY_ENTER
    repeat.pressed = true
    repeat.echo = true
    Input.parse_input_event(repeat)
    Input.flush_buffered_events()
    assert(GameManager.total_correct_answers + GameManager.total_incorrect_answers == total, "Held keyboard input must not answer again.")

    ProfileManager.set_controller_input_style("direct")
    var correct_index: int = game.current_question.choices.find(game.current_question.correct_answer)
    _joy([JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y][correct_index])
    assert(GameManager.total_correct_answers + GameManager.total_incorrect_answers == total + 1, "One controller event must produce one answer.")
    _key(KEY_ESCAPE)
    assert(game.pause_overlay.visible)
    now_msec += 10000
    GameManager._process(0.0)
    assert(GameManager.time_left == 110.0)
    assert(game._blitz_menu_hint.text.ends_with("01:50"))
    assert(game._blitz_menu_hint.get_parent() == game.pause_overlay.get_node("Panel/Margin/Layout"))
    game._open_pause_options()
    assert(game._pause_options_panel.is_ancestor_of(game._blitz_menu_hint), "Keep the live countdown visible inside Options.")
    now_msec += 110000
    GameManager._process(0.0)
    assert(game.blitz_results.visible and not game.pause_overlay.visible and game._pause_options_panel == null)
    assert(is_instance_valid(game._blitz_menu_hint), "Closing Options on expiry must preserve the countdown for rematches.")
    assert(game.blitz_results.initials_entry != null)
    game._resume_game()
    assert(GameManager.current_state == GameManager.GameState.GAME_OVER)

    var entry = game.blitz_results.initials_entry
    entry._submit()
    assert(entry.message_label.text.contains("three letters"))
    var serial := GameManager.session_serial
    _key(KEY_A)
    _key(KEY_B)
    _key(KEY_X)
    assert("".join(entry.letters) == "ABX")
    assert(GameManager.session_serial == serial, "Initials must not trigger Retry, Back, or answer shortcuts.")
    _key(KEY_BACKSPACE)
    _key(KEY_C)
    assert("".join(entry.letters) == "ABC")
    _key(KEY_ENTER)
    assert(not GameManager.has_pending_blitz_result())
    assert(BlitzLeaderboard.board(4).size() == 1 and BlitzLeaderboard.board(4)[0].initials == "ABC")
    assert(game.blitz_results.initials_entry == null)
    await get_tree().process_frame
    _assert_in_viewport(game.blitz_results.get_child(1), game)
    if "--capture" in OS.get_cmdline_user_args():
        await RenderingServer.frame_post_draw
        assert(get_viewport().get_texture().get_image().save_png("user://blitz-results.png") == OK)

    game.blitz_results.retry_button.emit_signal("pressed")
    await get_tree().process_frame
    await get_tree().process_frame
    assert(GameManager.is_blitz_mode() and GameManager.blitz_grade == 4 and GameManager.score == 0)
    assert(not game.blitz_results.visible and not game.answer_locked and GameManager.time_left == 120.0)
    _answer(game, true)
    now_msec += GameManager.BLITZ_TIME_MSEC
    GameManager.sync_blitz_clock()
    entry = game.blitz_results.initials_entry
    _joy(JOY_BUTTON_DPAD_UP)
    assert(entry.letters[0] == "Z")
    _joy(JOY_BUTTON_A)
    _joy(JOY_BUTTON_DPAD_DOWN)
    _joy(JOY_BUTTON_A)
    _joy(JOY_BUTTON_DPAD_DOWN)
    _joy(JOY_BUTTON_A)
    assert("".join(entry.letters) == "ZAA" and entry.selected_index == 3)
    _joy(JOY_BUTTON_A)
    assert(BlitzLeaderboard.board(4).size() == 2)
    assert(BlitzLeaderboard.reload() and BlitzLeaderboard.board(4).size() == 2)
    for index in 8:
        assert(BlitzLeaderboard.submit(4, 10 + index, "CAT") >= 0)
    game.blitz_results._show_board(0)
    await get_tree().process_frame
    await get_tree().process_frame
    _assert_in_viewport(game.blitz_results.get_child(1), game)
    if "--capture" in OS.get_cmdline_user_args():
        await RenderingServer.frame_post_draw
        assert(get_viewport().get_texture().get_image().save_png("user://blitz-full-board.png") == OK)

    GameManager.start_practice_session(7, 4)
    assert(game.get_node("%HeartContainer").visible and game.grade_label.text == "GRADE 7")
    assert(not game.blitz_results.visible and not game.correct_pips[0].is_visible_in_tree())
    GameManager.start_session()
    assert(game.correct_pips[0].is_visible_in_tree() and GameManager.time_left == 120.0)
    game.queue_free()
    await get_tree().process_frame

func _test_feedback_lifecycle() -> void:
    GameManager.start_blitz_session(1)
    var game = GameScene.instantiate()
    add_child(game)
    await get_tree().process_frame
    await get_tree().process_frame
    for resume_early in [true, false]:
        game._select_answer(game.current_question.choices.find(game.current_question.correct_answer))
        game._pause_game()
        if resume_early:
            game._resume_game()
            assert(game.answer_locked, "Resuming must not bypass pending feedback.")
        await get_tree().create_timer(1.05).timeout
        if not resume_early:
            assert(game.answer_locked and not game._blitz_feedback_pending)
            game._resume_game()
        assert(not game.answer_locked and not game._blitz_feedback_pending)
    game._select_answer(game.current_question.choices.find(game.current_question.correct_answer))
    game._restart_game()
    await get_tree().process_frame
    await get_tree().process_frame
    var new_question = game.current_question
    await get_tree().create_timer(1.05).timeout
    assert(game.current_question == new_question and GameManager.score == 0 and not game.answer_locked, "Old feedback must not advance a restarted session.")
    game._select_answer(game.current_question.choices.find(game.current_question.correct_answer))
    now_msec += GameManager.BLITZ_TIME_MSEC
    GameManager.sync_blitz_clock()
    await get_tree().create_timer(1.05).timeout
    assert(game.blitz_results.visible and game.answer_locked and game.current_question == new_question, "Expiry must prevent a delayed question advance.")
    game.queue_free()
    await get_tree().process_frame

func _test_save_failure_and_skip() -> void:
    var original_path := BlitzLeaderboard.storage_path
    BlitzLeaderboard.storage_path = "user://blitz-ui-missing/scores.json"
    GameManager.start_blitz_session(2)
    var game = GameScene.instantiate()
    add_child(game)
    await get_tree().process_frame
    await get_tree().process_frame
    _answer(game, true)
    now_msec += GameManager.BLITZ_TIME_MSEC
    GameManager.sync_blitz_clock()
    _key(KEY_C)
    _key(KEY_A)
    _key(KEY_T)
    _key(KEY_ENTER)
    assert(GameManager.has_pending_blitz_result(), "A failed save must keep the completed result.")
    var entry = game.blitz_results.initials_entry
    assert(entry.save_button.text == "RETRY SAVE" and not entry.message_label.text.is_empty())
    assert(DirAccess.make_dir_recursive_absolute("user://blitz-ui-missing") == OK)
    _key(KEY_ENTER)
    assert(not GameManager.has_pending_blitz_result())
    assert(BlitzLeaderboard.board(2).size() == 1, "Retry Save must persist once.")
    assert(DirAccess.remove_absolute(BlitzLeaderboard.storage_path) == OK)
    assert(DirAccess.remove_absolute("user://blitz-ui-missing") == OK)
    BlitzLeaderboard.storage_path = original_path
    assert(BlitzLeaderboard.reload())

    for should_answer in [false, true]:
        game._restart_game()
        await get_tree().process_frame
        await get_tree().process_frame
        if should_answer:
            _answer(game, false)
        now_msec += GameManager.BLITZ_TIME_MSEC
        GameManager.sync_blitz_clock()
        assert(game.blitz_results.initials_entry == null, "Zero and negative scores never prompt for initials.")
        assert(not GameManager.has_pending_blitz_result())
    game._restart_game()
    await get_tree().process_frame
    await get_tree().process_frame
    _answer(game, true)
    now_msec += GameManager.BLITZ_TIME_MSEC
    GameManager.sync_blitz_clock()
    _joy(JOY_BUTTON_B)
    assert(not GameManager.has_pending_blitz_result() and BlitzLeaderboard.board(2).is_empty(), "Skip must not save placeholder initials.")
    game.queue_free()
    await get_tree().process_frame

func _test_real_clock() -> void:
    GameManager.clock_msec = Time.get_ticks_msec
    GameManager.start_blitz_session(1)
    var game = GameScene.instantiate()
    add_child(game)
    await get_tree().process_frame
    await get_tree().process_frame
    var started := Time.get_ticks_msec()
    _answer(game, true)
    game._pause_game()
    game._open_pause_options()
    while GameManager.current_state != GameManager.GameState.GAME_OVER:
        await get_tree().process_frame
    var elapsed := Time.get_ticks_msec() - started
    assert(elapsed >= GameManager.BLITZ_TIME_MSEC - 100 and elapsed < GameManager.BLITZ_TIME_MSEC + 1000, "A real Blitz round must expire at 120 seconds even in Options.")
    assert(game.blitz_results.visible)
    print("Real-time Blitz round completed in %d ms." % elapsed)
    game.queue_free()
    await get_tree().process_frame

func _assert_button_palette(button: Button, normal: Color, highlighted: Color) -> void:
    assert(button.get_theme_stylebox("normal").bg_color == normal, button.text + " should use its requested menu color.")
    for state in ["hover", "focus"]:
        assert(button.get_theme_stylebox(state).bg_color == highlighted, button.text + " should keep its color on hover and keyboard/controller focus.")

func _capture(label: String) -> void:
    if "--capture" not in OS.get_cmdline_user_args():
        return
    for frame in 5:
        await get_tree().process_frame
    await RenderingServer.frame_post_draw
    var path := "user://%s.png" % label
    assert(get_viewport().get_texture().get_image().save_png(path) == OK)
    print("CAPTURE " + ProjectSettings.globalize_path(path))

func _answer(game: Control, correct: bool) -> void:
    var index: int = game.current_question.choices.find(game.current_question.correct_answer)
    if not correct:
        index = (index + 1) % 4
    _key([KEY_DOWN, KEY_RIGHT, KEY_LEFT, KEY_UP][index])
    _key(KEY_ENTER)

func _key(code: Key) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    Input.parse_input_event(event)
    Input.flush_buffered_events()
    var release := InputEventKey.new()
    release.keycode = code
    Input.parse_input_event(release)
    Input.flush_buffered_events()

func _joy(button: JoyButton) -> void:
    var event := InputEventJoypadButton.new()
    event.button_index = button
    event.pressed = true
    Input.parse_input_event(event)
    Input.flush_buffered_events()
    var release := InputEventJoypadButton.new()
    release.button_index = button
    Input.parse_input_event(release)
    Input.flush_buffered_events()

func _assert_in_viewport(control: Control, root: Control) -> void:
    var rectangle := control.get_global_rect()
    assert(rectangle.position.x >= 0 and rectangle.position.y >= 0)
    assert(rectangle.end.x <= root.get_viewport_rect().size.x and rectangle.end.y <= root.get_viewport_rect().size.y)
