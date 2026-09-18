extends Node

const GameScene = preload("res://scenes/game/game.tscn")
const TitleScene = preload("res://scenes/title/title.tscn")
const Main = preload("res://scripts/main.gd")

var now := 1000
var connected: Array[int] = [7, 42]

func _ready() -> void:
    var main := Main.new()
    main._configure_input_map()
    main.free()
    GameManager.clock_msec = func(): return now
    GameManager.duel_input.connected_devices = func(): return connected
    GameManager.answer_registered.disconnect(AudioManager._on_answer_registered)
    GameManager.session_started.disconnect(AudioManager._on_session_started)
    BlitzDuelLeaderboard.storage_path = "user://duel-ui-test.json"
    if FileAccess.file_exists(BlitzDuelLeaderboard.storage_path):
        assert(DirAccess.remove_absolute(BlitzDuelLeaderboard.storage_path) == OK)
    assert(BlitzDuelLeaderboard.reload())
    var solo := BlitzLeaderboard.board(1)
    await _test_empty_results()
    if "--menu-cooldown-only" in OS.get_cmdline_user_args():
        print("Blitz menu joystick cooldown tests passed.")
        get_tree().quit()
        return
    await _test_setup()
    await _test_keyboard()
    await _test_wrong_answers()
    await _test_cat_animation()
    await _test_controllers()
    await _test_long_content()
    if "--real-time" in OS.get_cmdline_user_args():
        await _test_real_clock()
    assert(BlitzLeaderboard.board(1) == solo, "Duel results must not change solo boards.")
    GameManager.clock_msec = Time.get_ticks_msec
    GameManager.duel_input.connected_devices = Input.get_connected_joypads
    if FileAccess.file_exists(BlitzDuelLeaderboard.storage_path):
        assert(DirAccess.remove_absolute(BlitzDuelLeaderboard.storage_path) == OK)
    print("Blitz duel UI smoke tests passed.")
    get_tree().quit()

func _frames() -> void:
    for index in 4:
        await get_tree().process_frame

func _test_empty_results() -> void:
    var results := preload("res://scripts/ui/blitz_results.gd").new()
    add_child(results)
    results.present({
        "two_player": true, "grade": 1, "winner": 1, "score": -21,
        "players": [
            {"score": -27, "correct": 7, "incorrect": 34},
            {"score": -21, "correct": 12, "incorrect": 33},
        ],
    })
    await _frames()
    assert(results.initials_entry == null and results.board_view.get_child_count() == 2)
    _assert_results_spacing(results)
    var event := InputEventKey.new()
    event.pressed = true
    event.keycode = KEY_DOWN
    results.handle_input(event)
    assert(results.title_button.has_focus())
    event.keycode = KEY_UP
    results.handle_input(event)
    assert(results.retry_button.has_focus())
    var joy := InputEventJoypadButton.new()
    joy.pressed = true
    joy.button_index = JOY_BUTTON_DPAD_DOWN
    results.handle_input(joy)
    assert(results.title_button.has_focus())
    joy.button_index = JOY_BUTTON_DPAD_UP
    results.handle_input(joy)
    assert(results.retry_button.has_focus())
    var stick := InputEventJoypadMotion.new()
    stick.axis = JOY_AXIS_LEFT_Y
    stick.axis_value = 1.0
    results.handle_input(stick)
    assert(results.title_button.has_focus())
    var deadline: int = results._navigation_ready_at
    assert(deadline - Time.get_ticks_msec() > 0 and deadline - Time.get_ticks_msec() <= 100)
    for poll in 10:
        assert(results.handle_input(stick))
    assert(results.title_button.has_focus() and results._navigation_ready_at == deadline)
    while Time.get_ticks_msec() < deadline:
        await get_tree().process_frame
    results.handle_input(stick)
    assert(results.retry_button.has_focus(), "Blitz results allow another joystick move after 100ms.")
    if "--capture" in OS.get_cmdline_user_args():
        await RenderingServer.frame_post_draw
        assert(get_viewport().get_texture().get_image().save_png("user://duel-empty-results-spacing.png") == OK)
    results.queue_free()
    await _frames()

    var entry := preload("res://scripts/ui/blitz_initials_entry.gd").new()
    add_child(entry)
    stick.axis = JOY_AXIS_LEFT_X
    entry.handle_input(stick)
    assert(entry.selected_index == 1)
    deadline = entry._navigation_ready_at
    assert(deadline - Time.get_ticks_msec() > 0 and deadline - Time.get_ticks_msec() <= 100)
    for poll in 10:
        assert(entry.handle_input(stick))
    assert(entry.selected_index == 1 and entry._navigation_ready_at == deadline)
    while Time.get_ticks_msec() < deadline:
        await get_tree().process_frame
    entry.handle_input(stick)
    assert(entry.selected_index == 2, "Initials selection allows another joystick move after 100ms.")
    entry.queue_free()
    await _frames()

func _test_setup() -> void:
    var title = TitleScene.instantiate()
    add_child(title)
    _joy(42, JOY_BUTTON_DPAD_DOWN)
    _joy(42, JOY_BUTTON_A)
    assert(title.active_view == "BLITZ MODE")
    assert(title.selected_blitz_players == 1)
    title._controller_navigation_ready_at = 0
    _joy(42, JOY_BUTTON_DPAD_DOWN)
    _joy(42, JOY_BUTTON_A)
    assert(title.selected_blitz_players == 2)
    assert(GameManager.duel_input.controls == GameManager.DuelInput.Controls.CONTROLLERS, "Selecting two players defaults to two controllers.")
    title._controller_navigation_ready_at = 0
    _joy(42, JOY_BUTTON_DPAD_DOWN)
    _joy(42, JOY_BUTTON_A)
    assert(GameManager.duel_input.controls == GameManager.DuelInput.Controls.KEYBOARD, "Shared keyboard remains selectable.")
    _joy(42, JOY_BUTTON_A)
    assert(GameManager.duel_input.controls == GameManager.DuelInput.Controls.CONTROLLERS)
    await _frames()
    _in_view(title.detail_panel)
    if "--capture" in OS.get_cmdline_user_args():
        await RenderingServer.frame_post_draw
        assert(get_viewport().get_texture().get_image().save_png("user://duel-setup.png") == OK)
    title._controller_navigation_ready_at = 0
    _joy(42, JOY_BUTTON_DPAD_DOWN)
    _joy(42, JOY_BUTTON_A)
    assert(title.active_view == "JOIN CONTROLLERS")
    assert(GameManager.duel_input.devices == [-1, -1], "Opening join must not join the initiating A press.")
    _joy(42, JOY_BUTTON_A)
    assert(GameManager.duel_input.devices == [42, -1])
    _joy(42, JOY_BUTTON_A)
    assert(title.active_view == "JOIN CONTROLLERS" and GameManager.duel_input.devices == [42, -1])
    _joy(7, JOY_BUTTON_A)
    assert(GameManager.duel_input.devices == [42, 7])
    assert(not title._duel_join_start.disabled)
    _joy(42, JOY_BUTTON_B)
    assert(title.active_view == "BLITZ MODE")
    title.selected_board_players = 2
    title._open_blitz_scores()
    assert(title._blitz_board.store == BlitzDuelLeaderboard)
    await _frames()
    _in_view(title.detail_panel)
    GameManager.duel_input.controls = GameManager.DuelInput.Controls.KEYBOARD
    title.queue_free()
    await _frames()
    var fresh_title = TitleScene.instantiate()
    add_child(fresh_title)
    assert(fresh_title.selected_blitz_players == 1, "A fresh title screen still defaults to solo.")
    assert(GameManager.duel_input.controls == GameManager.DuelInput.Controls.CONTROLLERS, "A fresh title screen restores the two-controller default.")
    fresh_title.queue_free()
    await _frames()

func _test_keyboard() -> void:
    GameManager.duel_input.reset()
    GameManager.duel_input.controls = GameManager.DuelInput.Controls.KEYBOARD
    GameManager.start_blitz_session(1, 2)
    var game = GameScene.instantiate()
    add_child(game)
    await _frames()
    assert(not game.answer_locked and GameManager.time_left == 120)
    assert(game.timer_label.text == "TIME 02:00", "Duel Blitz must start at two minutes.")
    _assert_answer_layout(game)
    for panel in game.duel_panels:
        assert(panel.score_label.get_theme_font_size("font_size") == 32, "Duel scores must use the larger 32-point text.")
        for points in [-999, -100, -1, 0, 1, 100, 999]:
            panel.update_score(points)
            assert(panel.score_label.text == "P%d SCORE %d" % [panel.player + 1, points], "Score updates must use P1/P2 and retain signed scores.")
            var score_font: Font = panel.score_label.get_theme_font("font")
            assert(score_font.get_string_size(panel.score_label.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 32).x <= panel.size.x - 4, "Larger signed scores must fit their player panel.")
        panel.update_score(-999 if panel.player == 1 else 999)
    await _frames()
    _assert_answer_layout(game)
    if "--capture" in OS.get_cmdline_user_args():
        await RenderingServer.frame_post_draw
        assert(get_viewport().get_texture().get_image().save_png("user://duel-large-scores.png") == OK)
    for panel in game.duel_panels:
        panel.update_score(0)
    for tile in game.answer_buttons:
        assert(tile.size == Vector2(198, 80), "Shared answers retain the solo tile dimensions.")
    assert(game.grade_label.text == "BLITZ\nGRADE 1")
    assert(absf(game.timer_label.get_global_rect().get_center().x - 640) < 1.0)
    assert(game.timer_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER)
    assert(game.duel_panels.size() == 2 and not game.math_cat.visible)
    assert(not game._animated_background_material.shader.code.contains("split_screen"), "Use one full-width perspective grid.")
    var first_palette := game.duel_panels[0].cat.material as ShaderMaterial
    var second_palette := game.duel_panels[1].cat.material as ShaderMaterial
    assert(first_palette != second_palette and first_palette.get_shader_parameter("fur_color") != second_palette.get_shader_parameter("fur_color"))
    for choice in 4:
        assert(game.answer_buttons[choice].get_theme_stylebox("normal") == game.base_answer_normal_styles[choice])
        assert(game.face_button_prompts[choice].get_node("Label").text == ["A", "B", "X", "Y"][choice], "Keyboard mode also shows only Xbox glyphs.")
    var unassigned_score: Array = GameManager.duel_round.scores.duplicate()
    game.answer_buttons[0].pressed.emit()
    assert(GameManager.duel_round.scores == unassigned_score, "Mouse/GUI activation must not bypass player attribution.")
    var original_cat_color := ProfileManager.cat_color_name()
    ProfileManager.set_cat_color("Green")
    assert(game.duel_panels[0].cat.modulate == Color.WHITE and game.duel_panels[1].cat.modulate == Color.WHITE, "Solo color changes must not override player palettes.")
    ProfileManager.set_cat_color(original_cat_color)
    ProfileManager.set_animated_background(false)
    assert(game.get_node("%Background").material == null)
    ProfileManager.set_animated_background(true)
    assert(game.get_node("%Background").material == game._animated_background_material)
    var index: int = game.current_question.choices.find(game.current_question.correct_answer)
    _key(GameManager.DuelInput.KEY_CHOICES[0][index])
    _key(GameManager.DuelInput.KEY_CHOICES[1][index])
    assert(GameManager.duel_round.scores == [1, 0], "A same-batch opponent event cannot answer a new question.")
    assert(game.answer_buttons[index].get_theme_stylebox("normal") == game.correct_answer_style)
    _assert_resolved_answer_backgrounds(game, index)
    var answered_id: int = game._duel_question_id
    await get_tree().create_timer(0.55).timeout
    assert(game.answer_locked and game._duel_question_id == answered_id, "Hold duel feedback for 0.7 seconds.")
    await get_tree().create_timer(0.25).timeout
    await _frames()
    assert(not game.answer_locked and game._duel_question_id == answered_id + 1)
    for choice in 4:
        assert(game.answer_buttons[choice].get_theme_stylebox("normal") == game.base_answer_normal_styles[choice], "The next question restores every answer background.")
    _assert_answer_layout(game)
    index = game.current_question.choices.find(game.current_question.correct_answer)
    _key(GameManager.DuelInput.KEY_CHOICES[0][(index + 1) % 4])
    _key(GameManager.DuelInput.KEY_CHOICES[0][index])
    assert(GameManager.duel_round.scores == [0, 0] and GameManager.duel_round.attempted[0])
    assert(game.answer_buttons[(index + 1) % 4].get_theme_stylebox("normal") == game.incorrect_answer_style)
    assert(game.answer_buttons[index].get_theme_stylebox("normal") == game.base_answer_normal_styles[index], "One wrong answer must not reveal the correct choice.")
    assert(game.duel_panels[0].lockout_label.visible and not game.duel_panels[1].lockout_label.visible)
    await _frames()
    _assert_answer_layout(game)
    if "--capture" in OS.get_cmdline_user_args():
        await RenderingServer.frame_post_draw
        assert(get_viewport().get_texture().get_image().save_png("user://duel-lockout.png") == OK)
    _key(GameManager.DuelInput.KEY_CHOICES[1][index])
    assert(GameManager.duel_round.scores == [0, 1])
    assert(game.answer_buttons[index].get_theme_stylebox("normal") == game.promotion_answer_style, "Player two's correct answer is blue.")
    _assert_resolved_answer_backgrounds(game, index)
    if "--capture" in OS.get_cmdline_user_args():
        await RenderingServer.frame_post_draw
        assert(get_viewport().get_texture().get_image().save_png("user://duel-correct-transparent.png") == OK)
    await get_tree().create_timer(1.05).timeout
    await _frames()
    assert(not game.duel_panels[0].lockout_label.visible)
    if "--capture" in OS.get_cmdline_user_args():
        await RenderingServer.frame_post_draw
        assert(get_viewport().get_texture().get_image().save_png("user://duel-game.png") == OK)
    for panel in game.duel_panels:
        _in_view(panel)
    _key(KEY_ESCAPE)
    await _frames()
    _assert_pause_hint(game)
    if "--capture" in OS.get_cmdline_user_args():
        await RenderingServer.frame_post_draw
        assert(get_viewport().get_texture().get_image().save_png("user://duel-pause.png") == OK)
    game._open_pause_options()
    await _frames()
    _assert_pause_hint(game)
    if "--capture" in OS.get_cmdline_user_args():
        await RenderingServer.frame_post_draw
        assert(get_viewport().get_texture().get_image().save_png("user://duel-pause-options.png") == OK)
    game._close_pause_options()
    await _frames()
    _assert_pause_hint(game)
    game._open_pause_options()
    now += GameManager.BLITZ_TIME_MSEC
    GameManager.sync_blitz_clock()
    assert(game.blitz_results.visible and not game.pause_overlay.visible)
    assert(game.blitz_results.initials_entry != null and GameManager.blitz_result().winner == 1)
    await _frames()
    _assert_initials_spacing(game.blitz_results)
    if "--capture" in OS.get_cmdline_user_args():
        await RenderingServer.frame_post_draw
        assert(get_viewport().get_texture().get_image().save_png("user://duel-initials-spacing.png") == OK)
    _key(KEY_C)
    _key(KEY_A)
    _key(KEY_T)
    _key(KEY_ENTER)
    assert(BlitzDuelLeaderboard.board(1).size() == 1)
    assert(not GameManager.has_pending_blitz_result())
    game._restart_game()
    await _frames()
    assert(GameManager.is_two_player_blitz() and GameManager.duel_round.scores == [0, 0])
    assert(GameManager.time_left == 120 and game.timer_label.text == "TIME 02:00", "Duel rematches must reset the two-minute clock.")
    now += GameManager.BLITZ_TIME_MSEC
    GameManager.sync_blitz_clock()
    assert(game.blitz_results.initials_entry == null, "Draws do not prompt for initials.")
    await _frames()
    _assert_results_spacing(game.blitz_results)
    for points in range(10, 20):
        assert(BlitzDuelLeaderboard.submit(1, points, "TOP") >= 0)
    game.blitz_results._show_board(0)
    await _frames()
    var columns: Node = game.blitz_results.board_view.get_child(1)
    assert(columns.get_child_count() == 2, "Long result boards use two columns.")
    for column in columns.get_children():
        assert(column.get_child_count() == 5, "Each column must show five scores.")
    for rank_index in 10:
        var row: Label = columns.get_child(0 if rank_index < 5 else 1).get_child(rank_index % 5)
        assert(row.text.ends_with(str(19 - rank_index)), "Read ranks 1-5 down the left and 6-10 down the right.")
        assert(row.get_theme_font_size("font_size") == 18, "Keep leaderboard scores at their original font size.")
        _in_view(row)
    assert(columns.get_child(0).get_child(0).text.begins_with(">"), "Retain the saved-rank highlight.")
    _in_view(game.blitz_results.get_child(1))
    _assert_results_spacing(game.blitz_results)
    if "--capture" in OS.get_cmdline_user_args():
        await RenderingServer.frame_post_draw
        assert(get_viewport().get_texture().get_image().save_png("user://duel-results.png") == OK)
    GameManager.start_blitz_session(1)
    await _frames()
    assert(game.math_cat.visible and game.answer_buttons[0].is_visible_in_tree())
    assert(not game.duel_panels[0].is_visible_in_tree())
    assert(game.question_label.is_visible_in_tree(), "Solo restores its original centered question.")
    assert(game.score_label.visible)
    assert(game.question_label.get_parent().custom_minimum_size == game._solo_question_minimum_size)
    for button in game.answer_buttons:
        assert(button.mouse_filter == Control.MOUSE_FILTER_STOP)
    assert(game.grade_label.text == "BLITZ\nGRADE 1")
    assert(game.get_node("%HeaderBar").custom_minimum_size.y == game._solo_header_height)
    assert(game.timer_label.horizontal_alignment == game._solo_timer_alignment)
    assert(Vector4(game.timer_label.offset_left, game.timer_label.offset_top, game.timer_label.offset_right, game.timer_label.offset_bottom) == game._solo_timer_offsets)
    game.queue_free()
    await _frames()

func _assert_resolved_answer_backgrounds(game: Control, correct_index: int, wrong_choices: Array = []) -> void:
    for choice in 4:
        for state in ["normal", "hover", "pressed", "disabled"]:
            var style := game.answer_buttons[choice].get_theme_stylebox(state) as StyleBoxFlat
            var highlighted := choice == correct_index or choice in wrong_choices
            assert(style.bg_color.a == (1.0 if highlighted else 0.0), "Only revealed feedback keeps a filled background after the duel question closes.")
            assert(style.border_color.a == (1.0 if highlighted else 0.0), "Only revealed feedback keeps a visible outline after the duel question closes.")
            if choice in wrong_choices:
                assert(style == game.incorrect_answer_style, "Both players' wrong guesses must stay red during the reveal.")

func _test_wrong_answers() -> void:
    GameManager.duel_input.reset()
    GameManager.duel_input.controls = GameManager.DuelInput.Controls.KEYBOARD
    GameManager.start_blitz_session(1, 2)
    var game = GameScene.instantiate()
    add_child(game)
    await _frames()
    for scenario in [[0, false], [0, true], [1, false], [1, true]]:
        var first_player: int = scenario[0]
        var same_choice: bool = scenario[1]
        var correct_index: int = game.current_question.choices.find(game.current_question.correct_answer)
        var first_wrong := (correct_index + 1) % 4
        var second_wrong := first_wrong if same_choice else (correct_index + 2) % 4
        var question_id: int = game._duel_question_id
        _key(GameManager.DuelInput.KEY_CHOICES[first_player][first_wrong])
        assert(game.answer_buttons[first_wrong].get_theme_stylebox("normal") == game.incorrect_answer_style)
        await get_tree().create_timer(1.05).timeout
        assert(not game.answer_locked and game._duel_question_id == question_id, "One wrong player waits for the opponent, even past the feedback delay.")
        assert(game.answer_buttons[correct_index].get_theme_stylebox("normal") == game.base_answer_normal_styles[correct_index])
        _key(GameManager.DuelInput.KEY_CHOICES[1 - first_player][second_wrong])
        assert(game.answer_locked)
        assert(game.answer_buttons[correct_index].get_theme_stylebox("normal") == game.revealed_answer_style)
        _assert_resolved_answer_backgrounds(game, correct_index, [first_wrong, second_wrong])
        _assert_answer_layout(game)
        if "--capture" in OS.get_cmdline_user_args():
            await RenderingServer.frame_post_draw
            assert(get_viewport().get_texture().get_image().save_png("user://duel-both-wrong-%s-p%d-first.png" % ["same" if same_choice else "different", first_player + 1]) == OK)
        await get_tree().create_timer(0.55).timeout
        assert(game._duel_question_id == question_id and game.answer_locked)
        _assert_resolved_answer_backgrounds(game, correct_index, [first_wrong, second_wrong])
        await get_tree().create_timer(0.25).timeout
        await _frames()
        assert(game._duel_question_id == question_id + 1 and not game.answer_locked)
        for choice in 4:
            assert(game.answer_buttons[choice].get_theme_stylebox("normal") == game.base_answer_normal_styles[choice])
    for resume_early in [true, false]:
        var question_id: int = game._duel_question_id
        var correct_index: int = game.current_question.choices.find(game.current_question.correct_answer)
        _key(GameManager.DuelInput.KEY_CHOICES[0][correct_index])
        game._pause_game()
        if resume_early:
            game._resume_game()
            await _frames()
            assert(game.answer_locked and game._duel_question_id == question_id)
        await get_tree().create_timer(1.05).timeout
        await _frames()
        if not resume_early:
            assert(game.answer_locked)
            game._resume_game()
            await _frames()
        assert(not game.answer_locked and game._duel_question_id == question_id + 1, "Menus must neither skip feedback nor advance twice.")
    game.queue_free()
    await _frames()

func _test_cat_animation() -> void:
    GameManager.duel_input.reset()
    GameManager.duel_input.controls = GameManager.DuelInput.Controls.KEYBOARD
    GameManager.start_blitz_session(1, 2)
    var game = GameScene.instantiate()
    add_child(game)
    await _frames()
    for grade in [1, 5, 9, 13]:
        GameManager.start_blitz_session(grade, 2)
        await _frames()
        for panel in game.duel_panels:
            assert(panel.cat.sprite_frames == game.math_cat.sprite_frames, "Every duel form must use Retro's unmodified SpriteFrames.")
            assert(panel.cat.speed_scale == game.math_cat.speed_scale)
        for is_correct in [true, false]:
            if is_correct:
                game.math_cat.play_happy()
            else:
                game.math_cat.play_sad()
            game.math_cat.set_frame_and_progress(0, 0.0)
            for panel in game.duel_panels:
                panel.react(is_correct)
                panel.cat.set_frame_and_progress(0, 0.0)
            var deadline := Time.get_ticks_msec() + 650
            while Time.get_ticks_msec() < deadline:
                await get_tree().process_frame
                for panel in game.duel_panels:
                    assert(panel.cat.animation == game.math_cat.animation and panel.cat.frame == game.math_cat.frame, "Duel reactions must advance through the same frames as Retro.")
                    assert(is_equal_approx(panel.cat.frame_progress, game.math_cat.frame_progress))
                    assert(panel.cat.get_playing_speed() == game.math_cat.get_playing_speed())
                    assert(panel.cat.position == Vector2(panel.size.x * 0.5, 92), "Do not add smooth movement over Retro's sprite animation.")
            _assert_answer_layout(game)

    GameManager.start_blitz_session(1, 2)
    await _frames()
    var correct_index: int = game.current_question.choices.find(game.current_question.correct_answer)
    _key(GameManager.DuelInput.KEY_CHOICES[0][correct_index])
    assert(game.duel_panels[0].cat.animation == "happy")
    assert(game.duel_panels[1].cat.animation == "idle", "Only the answering player's sprite reacts.")
    game._pause_game()
    for panel in game.duel_panels:
        assert(panel.cat.animation == "pause")
    game._resume_game()
    for panel in game.duel_panels:
        assert(panel.cat.animation == "idle")
    await get_tree().create_timer(1.05).timeout
    await _frames()
    correct_index = game.current_question.choices.find(game.current_question.correct_answer)
    _key(GameManager.DuelInput.KEY_CHOICES[1][(correct_index + 1) % 4])
    assert(game.duel_panels[1].cat.animation == "sad")
    _key(GameManager.DuelInput.KEY_CHOICES[0][correct_index])
    now += GameManager.BLITZ_TIME_MSEC
    GameManager.sync_blitz_clock()
    assert(game.duel_panels[0].cat.animation == "high_score" and game.duel_panels[1].cat.animation == "game_over")
    game._restart_game()
    await _frames()
    for panel in game.duel_panels:
        assert(panel.cat.animation == "idle" and panel.cat.position == Vector2(panel.size.x * 0.5, 92))
    game.queue_free()
    await _frames()

func _test_controllers() -> void:
    GameManager.duel_input.reset()
    GameManager.duel_input.controls = GameManager.DuelInput.Controls.CONTROLLERS
    assert(GameManager.duel_input.join(42) and GameManager.duel_input.join(7))
    ProfileManager.set_controller_input_style("navigation")
    GameManager.start_blitz_session(2, 2)
    var game = GameScene.instantiate()
    add_child(game)
    await _frames()
    for choice in 4:
        assert(game.face_button_prompts[choice].get_node("Label").text == ["A", "B", "X", "Y"][choice], "Duel controller prompts ignore the solo navigation preference.")
    if "--capture" in OS.get_cmdline_user_args():
        await RenderingServer.frame_post_draw
        assert(get_viewport().get_texture().get_image().save_png("user://duel-controller-game.png") == OK)
    var index: int = game.current_question.choices.find(game.current_question.correct_answer)
    _joy(42, GameManager.DuelInput.DPAD_CHOICES[index])
    assert(GameManager.duel_round.scores == [1, 0])
    await get_tree().create_timer(1.05).timeout
    await _frames()
    index = game.current_question.choices.find(game.current_question.correct_answer)
    _joy(42, GameManager.DuelInput.DPAD_CHOICES[(index + 1) % 4])
    assert(GameManager.duel_round.scores == [0, 0] and GameManager.duel_round.attempted[0])
    _joy(42, GameManager.DuelInput.BUTTON_CHOICES[index])
    assert(GameManager.duel_round.scores == [0, 0], "Switching from D-pad to face buttons cannot bypass lockout.")
    _joy(100, GameManager.DuelInput.DPAD_CHOICES[index])
    assert(GameManager.duel_round.scores == [0, 0], "A third controller cannot answer through the D-pad.")
    _joy(7, GameManager.DuelInput.DPAD_CHOICES[index])
    assert(GameManager.duel_round.scores == [0, 1], "The opponent can still answer with their D-pad.")
    await get_tree().create_timer(1.05).timeout
    await _frames()
    connected.erase(42)
    GameManager.duel_input.refresh_devices()
    assert(game._duel_connection_hint.visible)
    await _frames()
    _in_view(game._duel_connection_hint)
    assert(game.duel_panels[0].feedback.visible and game.duel_panels[1].feedback.visible)
    assert(game._duel_connection_hint.get_global_rect().end.y <= game.question_label.get_global_rect().position.y)
    _joy(7, JOY_BUTTON_START)
    assert(game.pause_overlay.visible)
    _joy(7, JOY_BUTTON_DPAD_DOWN)
    game._pause_navigation_ready_at = 0
    _joy(7, JOY_BUTTON_DPAD_DOWN)
    _joy(7, JOY_BUTTON_A)
    assert(game._pause_options_panel != null, "The assigned opponent can open Options without a keyboard.")
    connected.append(100)
    _joy(100, JOY_BUTTON_A)
    assert(GameManager.duel_input.devices == [100, 7] and game.pause_overlay.visible)
    assert(game.duel_panels[0].feedback.visible and game.duel_panels[1].feedback.visible)
    connected.clear()
    GameManager.duel_input.refresh_devices()
    var original_path := BlitzDuelLeaderboard.storage_path
    BlitzDuelLeaderboard.storage_path = "user://duel-ui-missing/scores.json"
    now += GameManager.BLITZ_TIME_MSEC
    GameManager.sync_blitz_clock()
    assert(game.blitz_results.visible and game.blitz_results.initials_entry != null)
    connected.assign([5])
    for slot in 3:
        _joy(5, JOY_BUTTON_DPAD_DOWN)
        _joy(5, JOY_BUTTON_A)
    _joy(5, JOY_BUTTON_A)
    assert(GameManager.has_pending_blitz_result())
    assert(game.blitz_results.initials_entry.save_button.text == "RETRY SAVE")
    await _frames()
    _assert_initials_spacing(game.blitz_results)
    assert(DirAccess.make_dir_recursive_absolute("user://duel-ui-missing") == OK)
    _joy(5, JOY_BUTTON_A)
    assert(not GameManager.has_pending_blitz_result(), "A replacement controller can enter initials and retry saving without a keyboard.")
    assert(BlitzDuelLeaderboard.board(2).size() == 1 and BlitzDuelLeaderboard.board(2)[0].initials == "AAA")
    assert(DirAccess.remove_absolute(BlitzDuelLeaderboard.storage_path) == OK)
    assert(DirAccess.remove_absolute("user://duel-ui-missing") == OK)
    BlitzDuelLeaderboard.storage_path = original_path
    assert(BlitzDuelLeaderboard.reload())
    _joy(5, JOY_BUTTON_A)
    await _frames()
    assert(GameManager.current_state == GameManager.GameState.BLITZ_READY)
    _joy(5, JOY_BUTTON_A)
    connected.append(23)
    _joy(23, JOY_BUTTON_A)
    await _frames()
    assert(GameManager.duel_input.devices == [5, 23])
    assert(GameManager.current_state == GameManager.GameState.PLAYING and GameManager.duel_round.scores == [0, 0])
    index = game.current_question.choices.find(game.current_question.correct_answer)
    _joy(23, GameManager.DuelInput.BUTTON_CHOICES[index])
    now += GameManager.BLITZ_TIME_MSEC
    GameManager.sync_blitz_clock()
    assert(game.blitz_results.initials_entry != null)
    _joy(5, JOY_BUTTON_B)
    assert(game.blitz_results.initials_entry == null, "Either controller can Skip the winner's score.")
    game.queue_free()
    await _frames()

func _test_long_content() -> void:
    GameManager.duel_input.reset()
    GameManager.duel_input.controls = GameManager.DuelInput.Controls.KEYBOARD
    GameManager.start_blitz_session(12, 2)
    var game = GameScene.instantiate()
    add_child(game)
    await _frames()
    for grade in range(5, 14):
        var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/questions/grade_%d.json" % grade))
        var longest_question: Dictionary = rows[0]
        var longest_choice: Dictionary = rows[0]
        var max_choice := 0
        for row: Dictionary in rows:
            if str(row.question).length() > str(longest_question.question).length():
                longest_question = row
            for choice: String in row.choices:
                if choice.length() > max_choice:
                    max_choice = choice.length()
                    longest_choice = row
        for row in [longest_question, longest_choice]:
            var question := QuestionData.new()
            question.grade = grade
            question.topic = row.topic
            question.question_text = row.question
            question.correct_answer = row.correctAnswer
            question.choices.assign(row.choices)
            game.current_question = question
            game.question_label.text = game.NumericDisplayFormatterScript.format_text(question.question_text)
            for choice in 4:
                game.answer_buttons[choice].text = game.NumericDisplayFormatterScript.format_text(question.choices[choice])
            game._fit_question_and_answer_text()
            await _frames()
            _assert_answer_layout(game)
            if grade == 12 and row == longest_choice and "--capture" in OS.get_cmdline_user_args():
                await RenderingServer.frame_post_draw
                assert(get_viewport().get_texture().get_image().save_png("user://duel-long-content.png") == OK)
    var numeric_question := QuestionData.new()
    numeric_question.question_text = "5 + 5 ="
    numeric_question.choices.assign(["10", "11", "12", "13"])
    game.current_question = numeric_question
    game.question_label.text = numeric_question.question_text
    for choice in 4:
        game.answer_buttons[choice].text = numeric_question.choices[choice]
    game._fit_question_and_answer_text()
    await _frames()
    _assert_answer_layout(game)
    assert(game.question_label.get_theme_font_size("font_size") == 64, "Short equations restore the full-size question font.")
    for tile in game.answer_buttons:
        assert(tile.size == Vector2(198, 80), "Retain solo tile dimensions for '%s': %s" % [tile.text, tile.size])
    game.queue_free()
    await _frames()

func _test_real_clock() -> void:
    GameManager.clock_msec = Time.get_ticks_msec
    GameManager.duel_input.reset()
    GameManager.duel_input.controls = GameManager.DuelInput.Controls.KEYBOARD
    GameManager.start_blitz_session(1, 2)
    var game = GameScene.instantiate()
    add_child(game)
    await _frames()
    var started := Time.get_ticks_msec()
    game._pause_game()
    game._open_pause_options()
    while GameManager.current_state != GameManager.GameState.GAME_OVER:
        await get_tree().process_frame
    var elapsed := Time.get_ticks_msec() - started
    assert(elapsed >= GameManager.BLITZ_TIME_MSEC - 100 and elapsed < GameManager.BLITZ_TIME_MSEC + 1000, "A real duel round must last 120 seconds even in Options.")
    assert(game.blitz_results.visible)
    game.queue_free()
    await _frames()

func _key(code: Key) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    Input.parse_input_event(event)
    Input.flush_buffered_events()
    event = event.duplicate()
    event.pressed = false
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func _joy(device: int, button: JoyButton) -> void:
    var event := InputEventJoypadButton.new()
    event.device = device
    event.button_index = button
    event.pressed = true
    Input.parse_input_event(event)
    Input.flush_buffered_events()
    event = event.duplicate()
    event.pressed = false
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func _in_view(control: Control) -> void:
    var rect := control.get_global_rect()
    assert(rect.position.x >= 0 and rect.position.y >= 0)
    assert(rect.end.x <= 1280 and rect.end.y <= 720, "Control must fit in viewport: %s" % rect)

func _assert_initials_spacing(results: Control) -> void:
    _assert_results_spacing(results)
    _in_view(results.initials_entry.skip_button)

func _assert_pause_hint(game: Control) -> void:
    var panel: Control = game._pause_options_panel if game._pause_options_panel != null else game.pause_overlay.get_node("Panel")
    var hint: Label = game._blitz_menu_hint
    var panel_rect := panel.get_global_rect()
    var hint_rect := hint.get_global_rect()
    assert(hint.is_visible_in_tree())
    assert(panel_rect.encloses(hint_rect), "Keep the countdown inside the active menu, not across its border.")
    assert(hint_rect.position.y >= panel_rect.position.y + 24, "Pad the countdown below the top border.")
    assert(hint.get_index() == 0)
    var heading: Control = hint.get_parent().get_child(1)
    assert(hint_rect.end.y + 12 <= heading.get_global_rect().position.y, "Separate the countdown from the menu heading.")
    _in_view(panel)

func _assert_results_spacing(results: Control) -> void:
    var labels: Array[Label] = []
    for child in results._layout.get_children():
        if child is Label:
            labels.append(child)
    assert(labels.size() >= 5)
    assert(labels[2].get_global_rect().position.y - labels[1].get_global_rect().end.y >= 32, "Leave a section gap after the winner announcement.")
    var next_section: Control = labels[5] if results.initials_entry != null else results.board_view
    assert(next_section.get_global_rect().position.y - labels[4].get_global_rect().end.y >= 32, "Leave a section gap between statistics and initials or leaderboard.")
    _in_view(results.get_child(1))
    if results.board_view != null:
        _in_view(results.board_view)
        _in_view(results.title_button)
        var retry_rect: Rect2 = results.retry_button.get_global_rect()
        var title_rect: Rect2 = results.title_button.get_global_rect()
        var preceding_section: Control = labels[5] if labels.size() > 5 else results.board_view
        assert(retry_rect.position.y - preceding_section.get_global_rect().end.y >= 32, "Leave breathing room between the board/saved status and actions.")
        assert(title_rect.position.y >= retry_rect.end.y + 6, "Stack Retry above Title.")
        assert(retry_rect.position.x == title_rect.position.x and retry_rect.size.x == title_rect.size.x)

func _assert_answer_layout(game: Control) -> void:
    var question: Label = game.question_label
    assert(question.is_visible_in_tree(), "Both players share the original equation label.")
    assert(question.text == game.NumericDisplayFormatterScript.format_text(game.current_question.question_text))
    var question_rect := question.get_global_rect()
    assert(absf(question_rect.get_center().x - 640) < 1)
    assert(question_rect.position.x >= game.duel_panels[0].get_global_rect().end.x + 16)
    assert(question_rect.end.x + 16 <= game.duel_panels[1].get_global_rect().position.x)
    assert(question_rect.end.y + 16 <= game.answer_buttons[3].get_global_rect().position.y)
    var question_font := question.get_theme_font("font")
    var question_size := question.get_theme_font_size("font_size")
    assert(question_size >= 22)
    assert(question.get_line_count() * question_font.get_height(question_size) + maxi(question.get_line_count() - 1, 0) * question.get_theme_constant("line_spacing") <= question.size.y)
    for index in 4:
        var tile: Button = game.answer_buttons[index]
        assert(tile.is_visible_in_tree() and not tile.disabled)
        var expected_centers := [Vector2(640, 640), Vector2(915, 520), Vector2(365, 520), Vector2(640, 400)]
        assert(tile.get_global_rect().get_center().is_equal_approx(expected_centers[index]), "Long text must not move the solo answer diamond.")
        assert(tile.size == Vector2(198, 80))
        assert(tile.text == game.NumericDisplayFormatterScript.format_text(game.current_question.choices[index]))
        assert(tile.focus_mode == Control.FOCUS_NONE and tile.mouse_filter == Control.MOUSE_FILTER_IGNORE)
        assert(tile.modulate == Color.WHITE and tile.self_modulate == Color.WHITE, "One player's lockout must not dim shared answers.")
        var expected_style: StyleBox = game.base_answer_normal_styles[index]
        var correct_index: int = game.current_question.choices.find(game.current_question.correct_answer)
        for player in 2:
            if GameManager.duel_round.selections[player] == index:
                expected_style = (game.correct_answer_style if player == 0 else game.promotion_answer_style) if index == correct_index else game.incorrect_answer_style
        if index == correct_index and GameManager.duel_round.closed and not correct_index in GameManager.duel_round.selections:
            expected_style = game.revealed_answer_style
        var preserved_wrong: bool = not correct_index in GameManager.duel_round.selections and index in GameManager.duel_round.selections
        if GameManager.duel_round.closed and index != correct_index and not preserved_wrong:
            var transparent_style := tile.get_theme_stylebox("normal") as StyleBoxFlat
            var filled_style := expected_style as StyleBoxFlat
            assert(transparent_style.bg_color.a == 0.0 and transparent_style.border_color.a == 0.0)
            assert(filled_style.bg_color.a == 1.0 and filled_style.border_color.a == 1.0, "Transparency must not mutate shared answer styles.")
        else:
            assert(tile.get_theme_stylebox("normal") == expected_style)
        var font := tile.get_theme_font("font")
        var font_size := tile.get_theme_font_size("font_size")
        assert(font_size >= 14)
        assert(font.get_multiline_string_size(tile.text, HORIZONTAL_ALIGNMENT_CENTER, tile.size.x - 8, font_size).y <= tile.size.y - 8, "All answer text must fit.")
        for prompt in game.face_button_prompts:
            assert(not tile.get_global_rect().intersects(prompt.get_global_rect()))
        _in_view(tile)
    for prompt in game.face_button_prompts:
        var glyph: Label = prompt.get_node("Label")
        var glyph_font := glyph.get_theme_font("font")
        assert(glyph.text in ["A", "B", "X", "Y"], "Only Xbox face-button glyphs appear during two-player gameplay.")
        assert(glyph.get_theme_font_size("font_size") == 36)
        assert(glyph_font.get_string_size(glyph.text, HORIZONTAL_ALIGNMENT_CENTER, -1, glyph.get_theme_font_size("font_size")).x <= glyph.size.x - 4, "Xbox glyphs must fit their shared controls.")
    for panel in game.duel_panels:
        assert(panel.cat.is_visible_in_tree())
        assert(absf(panel.cat.global_position.x - panel.get_global_rect().get_center().x) <= 8)
        var cat_size: Vector2 = panel.cat.sprite_frames.get_frame_texture(panel.cat.animation, panel.cat.frame).get_size() * panel.cat.scale
        var cat_rect := Rect2(panel.cat.global_position - cat_size / 2, cat_size)
        assert(not cat_rect.intersects(question_rect))
        assert(not cat_rect.intersects(game.grade_label.get_global_rect()), "Cat jumps must clear the grade heading.")
        assert(cat_rect.end.y + 4 <= panel.score_label.get_global_rect().position.y)
        assert(panel.score_label.get_global_rect().end.y + 4 <= panel.feedback.get_global_rect().position.y)
        assert(panel.feedback.get_global_rect().end.y + 4 <= panel.lockout_label.get_global_rect().position.y)
        for label in [panel.score_label, panel.feedback, panel.lockout_label]:
            assert(panel.get_global_rect().encloses(label.get_global_rect()))
        var score_font: Font = panel.score_label.get_theme_font("font")
        var score_font_size: int = panel.score_label.get_theme_font_size("font_size")
        assert(score_font.get_height(score_font_size) <= panel.score_label.size.y, "The enlarged score text must fit vertically.")
        _in_view(panel)
