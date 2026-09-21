extends Node

const GameScene = preload("res://scenes/game/game.tscn")
const TitleScene = preload("res://scenes/title/title.tscn")
const NumericDisplayFormatterScript = preload("res://scripts/ui/numeric_display_formatter.gd")
const TITLE_TAGLINES := [
    "Because worksheets don't have boss battles.",
    "Math is hard. Good thing you have nine lives.",
    "From simple sums to serious cat-culus.",
    "You have nine lives. Math needs one.",
    "Math has never been this catty.",
    "Solve for X. Unlock more cat.",
    "Stay Pawsitive. Solve Everything.",
    "Nine Lives. Zero Excuses. Do the Math.",
    "Think Outside the Litter Box.",
    "From Pawblems to Purrfection.",
]

func _ready() -> void:
    _test_numeric_display_formatting()
    await _test_menu_stick_cooldown()
    if "--menu-cooldown-only" in OS.get_cmdline_user_args():
        print("Menu joystick cooldown tests passed.")
        get_tree().quit()
        return
    await _test_pause_actions()
    _test_title_hub()
    _test_title_start()
    print("Title and pause UI smoke test passed.")
    get_tree().quit()

func _test_numeric_display_formatting() -> void:
    assert(NumericDisplayFormatterScript.format_integer(1000) == "1,000", "Numeric displays must group thousands.")
    assert(NumericDisplayFormatterScript.format_integer(1000000) == "1,000,000", "Numeric displays must group millions.")
    assert(NumericDisplayFormatterScript.format_text("Find 12000 + 0.50 =") == "Find 12,000 + 0.50 =", "Question displays must group whole-number tokens without changing decimals.")
    assert(NumericDisplayFormatterScript.format_text("x1000 = 1000000") == "x1,000 = 1,000,000", "Question displays must group values next to mathematical variables.")
    var question := QuestionData.new()
    question.question_text = "Find 12000 + 0.50 ="
    question.choices = ["12000.50"]
    assert(question.question_text == "Find 12000 + 0.50 =" and question.choices[0] == "12000.50", "Display formatting must not mutate question data used for calculations and answer matching.")

func _test_menu_stick_cooldown() -> void:
    var main := preload("res://scripts/main.gd").new()
    main._configure_input_map()
    main.free()
    var title = TitleScene.instantiate()
    add_child(title)
    await get_tree().process_frame
    assert(title.main_buttons[0].has_focus() and title.selected_main_index == 0, "Title opens with Retro Mode highlighted.")
    _stick(JOY_AXIS_LEFT_Y, 1.0)
    assert(title.selected_main_index == 1)
    var deadline: int = title._controller_navigation_ready_at
    assert(deadline - Time.get_ticks_msec() > 0 and deadline - Time.get_ticks_msec() <= 100)
    for poll in 10:
        _stick(JOY_AXIS_LEFT_Y, -1.0)
        _stick(JOY_AXIS_LEFT_Y, 1.0)
    assert(title.main_buttons[1].has_focus(), "Polled stick events must not bypass the title cooldown through GUI focus navigation.")
    assert(title._controller_navigation_ready_at == deadline, "Rejected polls must not extend the cooldown.")
    while Time.get_ticks_msec() < deadline:
        await get_tree().process_frame
    _stick(JOY_AXIS_LEFT_Y, 1.0)
    assert(title.main_buttons[2].has_focus(), "Title navigation resumes after 0.1 seconds.")
    title._open_options()
    title._focus_detail(0)
    title._controller_navigation_ready_at = 0
    _stick(JOY_AXIS_LEFT_Y, 1.0)
    for poll in 10:
        _stick(JOY_AXIS_LEFT_X, 1.0)
        _stick(JOY_AXIS_LEFT_Y, 1.0)
    assert(title.detail_buttons[1].has_focus(), "Options share the same cooldown across both stick axes.")
    title.queue_free()
    await get_tree().process_frame

    GameManager.start_session()
    var game = GameScene.instantiate()
    add_child(game)
    await get_tree().process_frame
    game._pause_game()
    _stick(JOY_AXIS_LEFT_Y, 1.0)
    assert(game.pause_buttons[1].has_focus())
    deadline = game._pause_navigation_ready_at
    assert(deadline - Time.get_ticks_msec() > 0 and deadline - Time.get_ticks_msec() <= 100)
    for poll in 10:
        _stick(JOY_AXIS_LEFT_Y, -1.0)
        _stick(JOY_AXIS_LEFT_Y, 1.0)
    assert(game.pause_buttons[1].has_focus(), "Polled stick events must not bypass the pause cooldown.")
    while Time.get_ticks_msec() < deadline:
        await get_tree().process_frame
    _stick(JOY_AXIS_LEFT_Y, 1.0)
    assert(game.pause_buttons[2].has_focus(), "Pause navigation resumes after 0.1 seconds.")
    game._open_pause_options()
    game._pause_navigation_ready_at = 0
    _stick(JOY_AXIS_LEFT_Y, 1.0)
    for poll in 10:
        _stick(JOY_AXIS_LEFT_Y, -1.0)
        _stick(JOY_AXIS_LEFT_X, 1.0)
    assert(game._pause_options_buttons[1].has_focus(), "Pause Options must consume rejected joystick polls.")
    game._resume_game()
    game.game_over_overlay.show()
    game.retry_button.grab_focus()
    game._pause_navigation_ready_at = 0
    _stick(JOY_AXIS_LEFT_Y, 1.0)
    assert(game.title_screen_button.has_focus())
    deadline = game._pause_navigation_ready_at
    for poll in 10:
        _stick(JOY_AXIS_LEFT_Y, -1.0)
    assert(game.title_screen_button.has_focus(), "Retro results must throttle joystick focus changes.")
    while Time.get_ticks_msec() < deadline:
        await get_tree().process_frame
    _stick(JOY_AXIS_LEFT_Y, -1.0)
    assert(game.retry_button.has_focus())
    game.queue_free()
    await get_tree().process_frame

func _stick(axis: JoyAxis, value: float) -> void:
    var event := InputEventJoypadMotion.new()
    event.axis = axis
    event.axis_value = value
    get_viewport().push_input(event)

func _test_title_start() -> void:
    var title = TitleScene.instantiate()
    add_child(title)
    assert(GameManager.current_state == GameManager.GameState.TITLE, "Title scene must set TITLE state.")
    assert(not AudioManager._music_player.playing, "Title screen must not play music.")
    var main_panel: PanelContainer = title.get_node("Panel")
    assert(main_panel.offset_top == -312.0 and main_panel.offset_bottom == 312.0 and main_panel.size.y == 624.0, "Main menu panel is reduced by 30 pixels at its top and bottom.")
    var first_tagline: String = title.get_node("Panel/Margin/Layout/Subtitle").text
    assert(first_tagline in TITLE_TAGLINES, "Main menu subtitle is one of the authored taglines.")
    var returning_title = TitleScene.instantiate()
    add_child(returning_title)
    assert(returning_title.get_node("Panel/Margin/Layout/Subtitle").text in TITLE_TAGLINES and returning_title.get_node("Panel/Margin/Layout/Subtitle").text != first_tagline, "Returning to the main menu selects a different tagline.")
    returning_title.queue_free()
    var start_button: Button = title.get_node("Panel/Margin/Layout/StartButton")
    assert(start_button.text == "RETRO MODE", "Title Retro Mode must remain the first menu entry.")
    GameManager.start_session()
    assert(GameManager.current_state == GameManager.GameState.PLAYING, "The standard Start Game session must begin playing.")
    assert(AudioManager._music_player.playing, "A standard session must begin gameplay music.")

func _test_title_hub() -> void:
    var title = TitleScene.instantiate()
    add_child(title)
    var expected_labels := ["RETRO MODE", "BLITZ", "ADVENTURE", "OPTIONS", "STATS", "ACHIEVEMENTS", "EXIT GAME"]
    for button_index in title.main_buttons.size():
        assert(title.main_buttons[button_index].text == expected_labels[button_index], "Title menu order must match the game hub design.")

    title._focus_main(3)
    assert(title.get_viewport().gui_get_focus_owner() == title.main_buttons[3], "The visible Options highlight must own title-menu focus.")
    title.selected_main_index = 1
    title._activate_focused_main()
    assert(title.active_view == "OPTIONS", "Activating title focus must open Options rather than a stale selected index.")
    var music_slider: HSlider = title.detail_buttons[1] as HSlider
    var master_slider: HSlider = title.detail_buttons[0] as HSlider
    var original_music_volume := ProfileManager.music_volume()
    var original_master_volume := ProfileManager.master_volume()
    title._focus_detail(1)
    assert(title.get_viewport().gui_get_focus_owner() == music_slider, "Music Volume must own focus when visibly highlighted.")
    title.selected_detail_index = 0
    title._adjust_focused_option(-1)
    assert(ProfileManager.music_volume() == posmod(original_music_volume - 1, 11), "Left must adjust the focused Music Volume slider only.")
    assert(ProfileManager.master_volume() == original_master_volume, "A stale detail index must not adjust Master Volume.")
    ProfileManager.set_volume("music_volume", original_music_volume)
    title._focus_detail(5)
    var cat_color_button: Button = title.detail_buttons[5] as Button
    var original_cat_color := ProfileManager.cat_color_name()
    title._adjust_focused_option(1)
    assert(ProfileManager.cat_color_name() != original_cat_color, "Right must adjust the focused Cat Color row only.")
    ProfileManager.set_cat_color(original_cat_color)
    title._close_detail_view()

    title._activate_main_option(1)
    assert(title.active_view == "BLITZ MODE", "Blitz must replace Practice as the second menu entry.")
    var grade_slider := title.detail_buttons[0] as HSlider
    assert(grade_slider.min_value == 1 and grade_slider.max_value == 13 and grade_slider.step == 1, "Blitz Grade must be a whole-step slider from 1 to 13.")
    grade_slider.value = 8
    assert(title.selected_blitz_grade == 8, "The Blitz grade slider must update its selected value.")

    title._close_detail_view()
    title._activate_main_option(3)
    assert(title.active_view == "OPTIONS", "Options must open its settings view.")
    var fullscreen_button: Button = title.detail_buttons[3] as Button
    var original_fullscreen := ProfileManager.fullscreen_enabled()
    assert(fullscreen_button.text == "Fullscreen  <  %s  >" % ("On" if original_fullscreen else "Off"), "Options must show the saved Fullscreen preference.")
    title._focus_detail(3)
    title._adjust_focused_option(1)
    assert(ProfileManager.fullscreen_enabled() != original_fullscreen and fullscreen_button.has_focus() and fullscreen_button.text == "Fullscreen  <  %s  >" % ("On" if ProfileManager.fullscreen_enabled() else "Off"), "Fullscreen changes only the focused option, refreshes its value, and retains focus.")
    ProfileManager.set_fullscreen(original_fullscreen)
    title._refresh_option_button(fullscreen_button, "Fullscreen")
    var original_background_setting := ProfileManager.animated_background_enabled()
    ProfileManager.set_animated_background(not original_background_setting)
    assert(ProfileManager.animated_background_enabled() == not original_background_setting, "Background preference must update.")
    ProfileManager.set_animated_background(original_background_setting)

    title._close_detail_view()
    title._activate_main_option(4)
    assert(title.active_view == "MATH CAT CAREER SUMMARY", "Stats must open the career summary.")
    title._close_detail_view()
    title._activate_main_option(5)
    assert(title.active_view == "ACHIEVEMENTS", "Achievements must open its placeholder view.")
    title._close_detail_view()
    title._activate_main_option(6)
    assert(title.active_view == "EXIT GAME", "Exit must open a confirmation view.")
    title._close_detail_view()

func _test_pause_actions() -> void:
    GameManager.start_session()
    var game = GameScene.instantiate()
    add_child(game)
    await get_tree().process_frame

    var pause_overlay: Control = game.get_node("PauseOverlay")
    var resume_button: Button = game.get_node("PauseOverlay/Panel/Margin/Layout/ResumeButton")
    var restart_button: Button = game.get_node("PauseOverlay/Panel/Margin/Layout/RestartButton")
    var options_button: Button = game.get_node("PauseOverlay/Panel/Margin/Layout/OptionsButton")
    var quit_button: Button = game.get_node("PauseOverlay/Panel/Margin/Layout/QuitToTitleButton")

    game.call("_pause_game")
    assert(pause_overlay.visible, "Pause should show its overlay.")
    assert(GameManager.current_state == GameManager.GameState.PAUSED, "Pause should change the game state.")
    assert(AudioManager._music_player.stream_paused, "Pause should pause the active music stream.")
    assert(String(game.math_cat.animation) == "pause", "Pausing should play the Math Cat pause animation.")
    var paused_time := GameManager.time_left
    GameManager._process(1.0)
    assert(GameManager.time_left == paused_time, "The timer must not advance while paused.")

    assert(options_button.text == "OPTIONS", "Pause menu must offer Options between Restart and Quit.")
    options_button.emit_signal("pressed")
    assert(game._pause_options_panel != null, "Pause Options must open an in-game settings panel.")
    assert(game._pause_options_buttons.size() == 8, "Pause Options must expose seven settings and a Back action.")
    var master_volume_button := _pause_option_button(game, "master_volume")
    assert("/ 10" not in master_volume_button.text, "Pause volume values should not repeat the / 10 suffix.")
    var original_music_volume := ProfileManager.music_volume()
    var original_sfx_volume := ProfileManager.sfx_volume()
    ProfileManager.set_volume("music_volume", 4)
    ProfileManager.set_volume("sfx_volume", 3)
    assert(is_equal_approx(AudioManager._music_volume_db, AudioManager.MUSIC_BASELINE_DB + linear_to_db(0.4)), "Music Volume must change the active music playback gain.")
    assert(is_equal_approx(AudioManager._sfx_volume_db, linear_to_db(0.3)), "Sound Effects Volume must change SFX playback gain.")
    ProfileManager.set_volume("music_volume", original_music_volume)
    ProfileManager.set_volume("sfx_volume", original_sfx_volume)
    var fullscreen_button := _pause_option_button(game, "fullscreen")
    var original_fullscreen := ProfileManager.fullscreen_enabled()
    game._change_pause_option(fullscreen_button, 1)
    assert(ProfileManager.fullscreen_enabled() != original_fullscreen and fullscreen_button.has_focus(), "Pause Fullscreen changes globally and retains focus.")
    ProfileManager.set_fullscreen(original_fullscreen)
    game._refresh_pause_option(fullscreen_button)
    var stick_event := InputEventJoypadMotion.new()
    stick_event.axis = JOY_AXIS_LEFT_Y
    stick_event.axis_value = 1.0
    game._pause_navigation_ready_at = 0
    assert(game._accept_pause_navigation(stick_event), "The first left-stick navigation input should be accepted.")
    assert(not game._accept_pause_navigation(stick_event), "Repeated left-stick navigation must wait for the pause repeat cooldown.")
    var cat_color_button := _pause_option_button(game, "cat_color")
    var original_cat_color := ProfileManager.cat_color_name()
    game._change_pause_option(cat_color_button, 1)
    assert(math_cat_modulate_changed(game, ProfileManager.cat_modulate()), "Changing Cat Color must update the current cat immediately.")
    ProfileManager.set_cat_color(original_cat_color)
    game.math_cat.modulate = ProfileManager.cat_modulate()
    var controller_button := _pause_option_button(game, "controller")
    ProfileManager.set_controller_input_style("direct")
    game._change_pause_option(controller_button, 1)
    assert(ProfileManager.controller_navigation_mode(), "Controller Input must update immediately from Pause Options.")
    assert(game.answer_buttons[0].focus_mode == Control.FOCUS_ALL, "Navigation Mode must immediately enable answer focus without restarting.")
    ProfileManager.set_controller_input_style("direct")
    assert(game.answer_buttons[0].focus_mode == Control.FOCUS_NONE, "Direct Button Mode must immediately clear answer focus without restarting.")
    var background_button := _pause_option_button(game, "background")
    var original_background_enabled := ProfileManager.animated_background_enabled()
    ProfileManager.set_animated_background(false)
    game._apply_background_setting()
    assert(game.get_node("Background").material == null, "Turning Animated Background off must remove the active shader.")
    ProfileManager.set_animated_background(original_background_enabled)
    game._apply_background_setting()
    assert(game.get_node("Background").material != null if original_background_enabled else game.get_node("Background").material == null, "Restoring Animated Background must restore the saved visual state.")
    game._close_pause_options()
    assert(game._pause_options_panel == null, "Closing Pause Options must return to the paused menu.")

    resume_button.emit_signal("pressed")
    assert(not pause_overlay.visible, "Resume should hide the pause overlay.")
    assert(GameManager.current_state == GameManager.GameState.PLAYING, "Resume should return to PLAYING.")
    assert(not AudioManager._music_player.stream_paused, "Resume should continue the active music stream.")
    assert(String(game.math_cat.animation) == "idle", "Resuming should return Math Cat to idle.")

    GameManager.add_score(20)
    game.call("_pause_game")
    restart_button.emit_signal("pressed")
    assert(not pause_overlay.visible, "Restart should hide the pause overlay.")
    assert(GameManager.current_state == GameManager.GameState.PLAYING, "Restart should begin a playable session.")
    assert(AudioManager._music_player.playing and not AudioManager._music_player.stream_paused, "Restart should resume music from its beginning.")
    assert(GameManager.score == 0, "Restart should reset the score.")
    assert(GameManager.lives == GameManager.START_LIVES, "Restart should restore lives.")

    game.call("_pause_game")
    quit_button.emit_signal("pressed")
    assert(GameManager.current_state == GameManager.GameState.TITLE, "Quit to Title should set TITLE state.")
    assert(not AudioManager._music_player.playing, "Quit to Title should stop music.")

func _pause_option_button(game: Control, key: String) -> Button:
    for button in game._pause_options_buttons:
        if button.get_meta("option_key", "") == key:
            return button
    assert(false, "Pause Options must include %s." % key)
    return null

func math_cat_modulate_changed(game: Control, expected_color: Color) -> bool:
    return game.math_cat.modulate == expected_color
