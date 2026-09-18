extends Node

const CatScene = preload("res://scenes/characters/math_cat.tscn")
var game: Control
var banner: Label
var pause_save_notice: Label
var overlay: Control
var status: Label
var actions: Array[Button] = []
var selected_action := 0
var navigation_ready_at := 0
var selected_answer := -1
var question_id := -1
var feedback_pending := false
var finished := false
var reward_ready := false
var auto_return := true
var reward_tween: Tween

func _ready() -> void:
    game = get_parent()
    banner = _label(game, "SAVE PENDING: CHECK STORAGE", Rect2(330, 110, 620, 35), 20)
    pause_save_notice = _label(game.pause_overlay, "", Rect2(100, 648, 1080, 52), 18)
    GameManager.adventure_timer_changed.connect(_timer)
    GameManager.adventure_question_resolved.connect(_resolved)
    GameManager.adventure_finished.connect(_finished)
    GameManager.state_changed.connect(_state_changed)

func _label(parent: Node, text: String, rect: Rect2, font_size: int) -> Label:
    var label := Label.new()
    label.text = text
    label.position = rect.position
    label.size = rect.size
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color("f4e8bd"))
    label.add_theme_color_override("font_outline_color", Color.BLACK)
    label.add_theme_constant_override("outline_size", 3)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(label)
    return label

func reset() -> void:
    feedback_pending = false
    finished = false
    reward_ready = false
    if reward_tween != null:
        reward_tween.kill()
    if is_instance_valid(overlay):
        overlay.queue_free()
    overlay = null
    actions.clear()
    pause_save_notice.text = ""
    game.get_node("Content").show()
    game.get_node("Answers").show()
    _refresh_hud_visibility()

func _refresh_hud_visibility() -> void:
    var active := GameManager.is_adventure_mode()
    var gameplay_visible := active and not finished and GameManager.current_state != GameManager.GameState.PAUSED
    banner.visible = gameplay_visible and not ProfileManager.last_save_error.is_empty()
    game.timer_label.visible = not active or (gameplay_visible and (GameManager.is_adventure_boss() or bool(GameManager.adventure_config.get("timed", false))))

func refresh_hud() -> void:
    var active := GameManager.is_adventure_mode()
    _refresh_hud_visibility()
    game.pause_buttons[3].text = "WORLD MAP" if active else "QUIT TO TITLE"
    game.math_cat.set_accessories(ProfileManager.adventure_progress(GameManager.adventure_campaign).equipped_accessories if active else {})
    if not active:
        return
    var config := GameManager.adventure_config
    if game.math_cat.current_stage != int(config.character):
        game.math_cat.set_stage(int(config.character))
    game.math_cat.modulate = ProfileManager.cat_modulate()
    game.grade_label.add_theme_font_size_override("font_size", 36 if GameManager.is_adventure_boss() else 24)
    game.grade_label.text = "GRADE %d" % ProgressionManager.current_grade if GameManager.is_adventure_boss() else "%s\nLEVEL %d - GRADE %d" % [str(config.campaign).to_upper(), config.number, ProgressionManager.current_grade]
    game.score_label.add_theme_font_size_override("font_size", game.grade_label.get_theme_font_size("font_size") if GameManager.is_adventure_boss() else 26)
    game.score_label.text = "FINAL BOSS" if GameManager.is_adventure_boss() else "%d / %d CORRECT" % [GameManager.total_correct_answers, config.correct_target]
    for meter in ["CorrectProgress", "IncorrectProgress"]:
        game.get_node("%HeaderBar").get_node("Margin/Header/GradeProgressPanel/" + meter).visible = GameManager.is_adventure_boss()
    game._set_meter_fill(game.correct_pips, ProgressionManager.PROMOTE_THRESHOLD if GameManager.current_state == GameManager.GameState.LEVEL_UP else ProgressionManager.correct_count)
    game._set_meter_fill(game.incorrect_pips, ProgressionManager.DEMOTE_THRESHOLD if GameManager.current_state == GameManager.GameState.DEMOTION else ProgressionManager.incorrect_count)
    if GameManager.is_adventure_boss():
        game._update_timer(ceili(GameManager.time_left))
    else:
        _timer(float(GameManager._adventure_remaining) / 1000.0)

func present_question() -> void:
    if finished:
        return
    feedback_pending = false
    selected_answer = -1
    game.answer_locked = true
    game._set_buttons_disabled(true)
    question_id = GameManager.prepare_adventure_question()
    _ready_question(GameManager.session_serial, question_id)

func _ready_question(serial: int, token: int) -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    if not is_inside_tree() or serial != GameManager.session_serial or token != question_id or not GameManager.is_adventure_mode():
        return
    game._fit_question_and_answer_text()
    GameManager.ready_adventure_question(serial, token)
    game.answer_locked = not GameManager.adventure_question_open or GameManager.current_state != GameManager.GameState.PLAYING
    game._set_buttons_disabled(game.answer_locked)

func select_answer(index: int) -> void:
    if game.answer_locked or finished:
        return
    selected_answer = index
    GameManager.submit_adventure_answer(game.current_question.choices[index] == game.current_question.correct_answer, game.current_question.uses_pi, GameManager.session_serial, question_id)

func _timer(seconds: float) -> void:
    if GameManager.is_adventure_mode() and not GameManager.is_adventure_boss():
        game.timer_label.text = "TIME %.1f" % (ceilf(maxf(seconds, 0.0) * 10.0) / 10.0)

func _resolved(correct: bool, timed_out: bool) -> void:
    game.answer_locked = true
    game._set_buttons_disabled(true)
    refresh_hud()
    if finished:
        return
    var promotion := GameManager.current_state == GameManager.GameState.LEVEL_UP
    var grade_change := promotion or GameManager.current_state == GameManager.GameState.DEMOTION
    if not grade_change:
        game.feedback_label.modulate = game.CORRECT_PIP_COLOR if correct else game.INCORRECT_PIP_COLOR
    if timed_out:
        game.feedback_label.text = "Time's up! -1 life"
        game.math_cat.play_sad()
        game._load_next_question()
        return
    if selected_answer >= 0:
        game._set_selected_answer_feedback(selected_answer, correct, promotion)
    if not correct:
        game._reveal_correct_answer()
    if not grade_change:
        game.feedback_label.text = "Correct!" if correct else "Not quite."
    if correct and not promotion:
        game.math_cat.play_happy()
    elif not correct:
        game.math_cat.play_sad()
    feedback_pending = true
    var serial := GameManager.session_serial
    var feedback_seconds := 2.0 if grade_change else 0.75 if GameManager.is_adventure_boss() else 0.7
    await get_tree().create_timer(feedback_seconds, false).timeout
    if not is_inside_tree() or serial != GameManager.session_serial or finished or not GameManager.is_adventure_mode():
        return
    if grade_change:
        GameManager.set_state(GameManager.GameState.PLAYING)
    feedback_pending = false
    game.feedback_label.text = ""
    game._load_next_question()

func _state_changed(_old_state: int, new_state: int) -> void:
    if not GameManager.is_adventure_mode() or finished:
        return
    _refresh_hud_visibility()
    if new_state == GameManager.GameState.PLAYING and not feedback_pending:
        _ready_question(GameManager.session_serial, question_id)

func _finished(success: bool) -> void:
    if finished:
        return
    var victory := success and GameManager.is_adventure_boss()
    finished = true
    _refresh_hud_visibility()
    game.answer_locked = true
    game._set_buttons_disabled(true)
    game._close_pause_options()
    game.pause_overlay.hide()
    if victory:
        if selected_answer >= 0:
            game._set_selected_answer_feedback(selected_answer, true)
        game.feedback_label.text = "VICTORY!"
        game.feedback_label.modulate = game.CORRECT_PIP_COLOR
        AudioManager.play_music(AudioManager.MUSIC_VICTORY_THEME)
        var victory_serial := GameManager.session_serial
        await get_tree().create_timer(game.RESULT_REVEAL_DELAY_SECONDS, false).timeout
        if not is_inside_tree() or victory_serial != GameManager.session_serial or not GameManager.is_adventure_boss():
            return
        game.get_node("Content").hide()
        game.get_node("Answers").hide()
        game.math_cat.hide()
        game.time_bonus_label.hide()
    else:
        AudioManager.stop_music()
    overlay = Control.new()
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    game.add_child(overlay)
    var dim := ColorRect.new()
    dim.color = Color(0.02, 0.04, 0.05, 0.90 if victory else 0.96)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.add_child(dim)
    var heading := "VICTORY!" if victory else "LEVEL COMPLETE" if success else "TIME'S UP!" if GameManager.last_end_reason == "time_up" else "OUT OF LIVES"
    var heading_label := _label(overlay, heading, Rect2(140, 64, 1000, 72), 42)
    heading_label.name = "ResultHeading"
    if victory:
        heading_label.add_theme_color_override("font_color", game.CORRECT_PIP_COLOR)
        _label(overlay, "%s CAMPAIGN COMPLETE" % str(GameManager.adventure_campaign).to_upper(), Rect2(100, 142, 1080, 40), 24)
    var cat := CatScene.instantiate()
    cat.name = "ResultCat"
    overlay.add_child(cat)
    cat.position = Vector2(640, 270)
    cat.scale = Vector2(2.5, 2.5)
    cat.set_stage(int(GameManager.adventure_config.character))
    cat.modulate = ProfileManager.cat_modulate()
    cat.set_accessories(ProfileManager.adventure_progress(GameManager.adventure_campaign).equipped_accessories)
    if success:
        if victory:
            cat.play_high_score()
        else:
            cat.play_happy()
            AudioManager.play_sfx(AudioManager.SFX_LEVEL_UP)
        _label(overlay, "+%d COINS" % GameManager.adventure_reward if GameManager.adventure_reward > 0 else "LEVEL REPLAY COMPLETE", Rect2(230, 382, 820, 60), 36)
        if GameManager.adventure_reward > 0:
            _animate_coins()
    else:
        cat.play_game_over()
        _label(overlay, "%d / %d CORRECT" % [GameManager.total_correct_answers, GameManager.adventure_config.correct_target] if not GameManager.is_adventure_boss() else "GRADE %d" % ProgressionManager.current_grade, Rect2(230, 382, 820, 60), 30)
    status = _label(overlay, "", Rect2(120, 450, 1040, 55), 20)
    _action("RETRY SAVE" if success else "RETRY LEVEL", Rect2(350, 534, 580, 55), _primary_action)
    _action("WORLD MAP", Rect2(350, 606, 580, 55), return_to_map)
    actions[0].grab_focus()
    _refresh_save_state(success)
    if success:
        var serial := GameManager.session_serial
        await get_tree().create_timer(1.8, false).timeout
        if not is_inside_tree() or serial != GameManager.session_serial:
            return
        reward_ready = true
        _refresh_save_state(true)
        if auto_return and not victory and ProfileManager.last_save_error.is_empty():
            return_to_map()

func _action(text: String, rect: Rect2, callback: Callable) -> void:
    var button: Button = game._make_pause_option_button(text)
    button.position = rect.position
    button.size = rect.size
    button.pressed.connect(callback)
    overlay.add_child(button)
    actions.append(button)
    button.focus_entered.connect(func(): selected_action = actions.find(button))

func _primary_action() -> void:
    AudioManager.play_sfx(AudioManager.SFX_UI_CONFIRM)
    if not ProfileManager.last_save_error.is_empty():
        ProfileManager.save()
        _refresh_save_state(GameManager.current_state != GameManager.GameState.LEVEL_FAILED)
        return
    if GameManager.current_state == GameManager.GameState.LEVEL_FAILED:
        game._restart_game()
        return
    if ProfileManager.save():
        _refresh_save_state(true)
        if reward_ready:
            return_to_map()
    else:
        _refresh_save_state(true)

func _refresh_save_state(success: bool) -> void:
    var saved := ProfileManager.last_save_error.is_empty()
    status.text = ("PAID AND SAVED" if GameManager.adventure_reward > 0 else "PROGRESS SAVED") if success and saved else "" if saved else ProfileManager.last_save_error
    actions[0].text = "RETRY LEVEL" if saved else "RETRY SAVE"
    actions[0].visible = not success or not saved
    actions[1].disabled = not saved or (success and not reward_ready)
    if actions[1].disabled:
        if actions[0].visible:
            actions[0].grab_focus()
    else:
        actions[1].grab_focus()

func return_to_map() -> void:
    if not ProfileManager.save():
        if is_instance_valid(status):
            status.text = ProfileManager.last_save_error
        else:
            pause_save_notice.text = ProfileManager.last_save_error
        return
    AudioManager.stop_music()
    GameManager.open_adventure(GameManager.adventure_campaign)
    GameManager.goto_scene("res://scenes/adventure/adventure_hub.tscn")

func handle_input(event: InputEvent) -> void:
    if not (event is InputEventJoypadMotion or event is InputEventJoypadButton or event is InputEventKey):
        return
    game.get_viewport().set_input_as_handled()
    if actions.is_empty():
        return
    if event is InputEventJoypadMotion:
        if event.axis != JOY_AXIS_LEFT_Y or absf(event.axis_value) < 0.65 or Time.get_ticks_msec() < navigation_ready_at:
            return
        navigation_ready_at = Time.get_ticks_msec() + 100
    else:
        if not event.is_pressed() or (event is InputEventKey and event.echo):
            return
        if event.is_action_pressed("ui_accept"):
            if not actions[selected_action].disabled and actions[selected_action].visible:
                actions[selected_action].pressed.emit()
            return
        if event.is_action_pressed("ui_cancel"):
            if not actions[1].disabled:
                return_to_map()
            return
        if not (event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down")):
            return
    for offset in range(1, actions.size() + 1):
        var candidate := (selected_action + offset) % actions.size()
        if actions[candidate].visible and not actions[candidate].disabled:
            actions[candidate].grab_focus()
            break

func _animate_coins() -> void:
    var texture := PixelMeterIcon.coin_texture()
    reward_tween = create_tween().set_parallel(true)
    for index in 7:
        var coin := TextureRect.new()
        coin.texture = texture
        coin.position = Vector2(500 + index * 42, 180)
        coin.scale = Vector2(3, 3)
        overlay.add_child(coin)
        reward_tween.tween_property(coin, "position", Vector2(624, 350), 0.7).set_delay(index * 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
        reward_tween.tween_property(coin, "modulate:a", 0.0, 0.2).set_delay(0.7 + index * 0.08)