extends Control

const QuestionBankScript = preload("res://autoload/question_bank.gd")
const MathCatStagesScript = preload("res://scripts/character/math_cat_stages.gd")
const NumericDisplayFormatterScript = preload("res://scripts/ui/numeric_display_formatter.gd")
const BlitzResults = preload("res://scripts/ui/blitz_results.gd")
const DuelPanel = preload("res://scripts/ui/blitz_duel_panel.gd")
const AdventureGameplay = preload("res://scripts/adventure/adventure_gameplay.gd")
const AdventureStageBackground = preload("res://scripts/adventure/adventure_stage_background.gd")

const CORRECT_PIP_COLOR := Color("79d26a")
const INCORRECT_PIP_COLOR := Color("ed6a5a")
const PIP_FLASH_STEP_DURATION := 0.15
const PAUSE_CONTROLLER_NAV_REPEAT_MS := 100
const ANSWER_CONTROLLER_NAV_REPEAT_MS := 200
const ANSWER_STICK_DEAD_ZONE := 0.65
const RESULT_REVEAL_DELAY_SECONDS := 1.0
const QUESTION_MAX_FONT_SIZE := 64
const QUESTION_MIN_FONT_SIZE := 22
const QUESTION_WORD_PROBLEM_MIN_LENGTH := 40
const GRADE_FIVE_DECIMAL_QUESTION_FONT_SIZE := 42
const GRADE_SIX_EXTENDED_QUESTION_FONT_SIZE := 42
const GRADE_EIGHT_QUADRANT_QUESTION_FONT_SIZE := 42
const GRADE_EIGHT_SCIENTIFIC_NOTATION_QUESTION_FONT_SIZE := 42
const ANSWER_MAX_FONT_SIZE := 42
const ANSWER_MIN_FONT_SIZE := 14
const KITTEN_FRAMES := preload("res://assets/characters/math_cat/math_cat_kitten_frames.tres")
const BIG_CAT_FRAMES := preload("res://assets/characters/math_cat/math_cat_big_cat_frames.tres")
const TIGER_FRAMES := preload("res://assets/characters/math_cat/math_cat_tiger_frames.tres")
const NERD_CAT_FRAMES := preload("res://assets/characters/math_cat/math_cat_nerd_cat_frames.tres")

@onready var grade_label: Label = %GradeLabel
@onready var score_label: Label = %ScoreLabel
@onready var timer_label: Label = %TimerLabel
@onready var heart_icons: Array[Control] = [%HeartContainer.get_node("Heart1"), %HeartContainer.get_node("Heart2"), %HeartContainer.get_node("Heart3"), %HeartContainer.get_node("Heart4"), %HeartContainer.get_node("Heart5"), %HeartContainer.get_node("Heart6"), %HeartContainer.get_node("Heart7"), %HeartContainer.get_node("Heart8"), %HeartContainer.get_node("Heart9")]
@onready var correct_pips: Array[Control] = [%HeaderBar.get_node("Margin/Header/GradeProgressPanel/CorrectProgress/Pip1"), %HeaderBar.get_node("Margin/Header/GradeProgressPanel/CorrectProgress/Pip2"), %HeaderBar.get_node("Margin/Header/GradeProgressPanel/CorrectProgress/Pip3"), %HeaderBar.get_node("Margin/Header/GradeProgressPanel/CorrectProgress/Pip4"), %HeaderBar.get_node("Margin/Header/GradeProgressPanel/CorrectProgress/Pip5")]
@onready var incorrect_pips: Array[Control] = [%HeaderBar.get_node("Margin/Header/GradeProgressPanel/IncorrectProgress/Pip1"), %HeaderBar.get_node("Margin/Header/GradeProgressPanel/IncorrectProgress/Pip2"), %HeaderBar.get_node("Margin/Header/GradeProgressPanel/IncorrectProgress/Pip3")]
@onready var question_label: Label = %QuestionLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var answer_buttons: Array[Button] = [%Answer1, %Answer2, %Answer3, %Answer4]
@onready var face_button_prompts: Array[Control] = [%XboxFaceButtons.get_node("A"), %XboxFaceButtons.get_node("B"), %XboxFaceButtons.get_node("X"), %XboxFaceButtons.get_node("Y")]
@onready var math_cat: MathCat = %MathCat
@onready var time_bonus_label: Label = %TimeBonusLabel
@onready var game_over_overlay: Control = %GameOverOverlay
@onready var game_over_reason_label: Label = %GameOverReasonLabel
@onready var game_over_score_label: Label = %GameOverScoreLabel
@onready var game_over_max_grade_label: Label = %GameOverMaxGradeLabel
@onready var game_over_streak_label: Label = %GameOverStreakLabel
@onready var game_over_answers_label: Label = %GameOverAnswersLabel
@onready var game_over_time_survived_label: Label = %GameOverTimeSurvivedLabel
@onready var game_over_evolution_label: Label = %GameOverEvolutionLabel
@onready var game_over_title_label: Label = %GameOverTitle
@onready var new_high_score_label: Label = %NewHighScoreLabel
@onready var retry_button: Button = %RetryButton
@onready var title_screen_button: Button = %TitleScreenButton
@onready var pause_overlay: Control = %PauseOverlay
@onready var pause_options_button: Button = %OptionsButton
@onready var pause_buttons: Array[Button] = [%ResumeButton, %RestartButton, %OptionsButton, %QuitToTitleButton]

var answer_locked := false
var question_bank := QuestionBankScript.new()
var current_question: QuestionData
var selected_pause_button := 0
var base_answer_normal_styles: Array[StyleBox] = []
var base_answer_hover_styles: Array[StyleBox] = []
var correct_answer_style: StyleBoxFlat
var incorrect_answer_style: StyleBoxFlat
var revealed_answer_style: StyleBoxFlat
var promotion_answer_style: StyleBoxFlat
var answer_focus_style: StyleBoxFlat
var selected_answer_index := 0
var _game_over_is_new_high_score := false
var _progress_reset_pending := false
var _pause_navigation_ready_at := 0
var _pause_options_panel: PanelContainer
var _pause_options_buttons: Array[Button] = []
var _selected_pause_option := 0
var _animated_background_material: ShaderMaterial
var _adventure_stage_background: AdventureStageBackground
var _answer_navigation_ready_at := 0
var _keyboard_answer_navigation_active := false
var _question_visible_at_msec := 0
var _question_paused_at_msec := 0
var _question_paused_duration_msec := 0
var _achievement_toast: PanelContainer
var _achievement_toast_artwork: TextureRect
var _achievement_toast_name: Label
var _achievement_notification_queue: Array[String] = []
var _achievement_notification_showing := false
var blitz_results: BlitzResults
var _blitz_menu_hint: Label
var _blitz_feedback_pending := false
var adventure: AdventureGameplay
var duel_panels: Array[DuelPanel] = []
var _duel_layout: Control
var _duel_connection_hint: Label
var _duel_question_id := -1
var _solo_header_height := 0.0
var _solo_timer_offsets := Vector4.ZERO
var _solo_timer_font_size := 0
var _solo_grade_font_size := 0
var _solo_timer_alignment := HORIZONTAL_ALIGNMENT_LEFT
var _solo_question_minimum_size := Vector2.ZERO
var _solo_answer_centers: Array[Vector2] = []

func _ready() -> void:
    if OS.is_debug_build():
        add_to_group("debug_gameplay")
    _solo_header_height = %HeaderBar.custom_minimum_size.y
    _solo_timer_offsets = Vector4(timer_label.offset_left, timer_label.offset_top, timer_label.offset_right, timer_label.offset_bottom)
    _solo_timer_font_size = timer_label.get_theme_font_size("font_size")
    _solo_grade_font_size = grade_label.get_theme_font_size("font_size")
    _solo_timer_alignment = timer_label.horizontal_alignment
    _solo_question_minimum_size = question_label.get_parent().custom_minimum_size
    add_child(question_bank)
    correct_answer_style = _create_feedback_style(Color("399653"), Color("c4f3c0"))
    incorrect_answer_style = _create_feedback_style(Color("b94141"), Color("ffc0ba"))
    revealed_answer_style = _create_feedback_style(Color("596273"), Color("aab2c0"))
    promotion_answer_style = _create_feedback_style(Color("326fb8"), Color("aacfff"))
    answer_focus_style = _create_focus_style()
    for answer_index in answer_buttons.size():
        var answer_button := answer_buttons[answer_index]
        _solo_answer_centers.append(Vector2(answer_button.offset_left + answer_button.offset_right, answer_button.offset_top + answer_button.offset_bottom) / 2)
        _set_answer_text_color_overrides(answer_button)
        answer_button.add_theme_stylebox_override("focus", answer_focus_style)
        base_answer_normal_styles.append(answer_button.get_theme_stylebox("normal"))
        base_answer_hover_styles.append(answer_button.get_theme_stylebox("hover"))
        answer_buttons[answer_index].pressed.connect(_select_answer.bind(answer_index))

    GameManager.timer_tick.connect(_update_timer)
    GameManager.lives_changed.connect(_update_lives)
    GameManager.score_changed.connect(_update_score)
    GameManager.time_bonus_awarded.connect(_show_time_bonus)
    GameManager.new_high_score.connect(_on_new_high_score)
    GameManager.session_ended.connect(_show_game_over)
    GameManager.session_started.connect(_reset_after_retry)
    GameManager.duel_answered.connect(_on_duel_answered)
    GameManager.duel_input.assignments_changed.connect(_on_duel_assignments_changed)
    ProgressionManager.answer_registered.connect(_update_progress)
    ProgressionManager.promoted.connect(_show_grade_change.bind(true))
    ProgressionManager.demoted.connect(_show_grade_change.bind(false))
    ProfileManager.setting_changed.connect(_apply_live_setting)
    AchievementManager.achievement_unlocked.connect(_queue_achievement_notification)
    retry_button.pressed.connect(_retry_session)
    title_screen_button.pressed.connect(_quit_to_title)
    pause_buttons[0].pressed.connect(_resume_game)
    pause_buttons[1].pressed.connect(_restart_game)
    pause_options_button.pressed.connect(_open_pause_options)
    pause_buttons[3].pressed.connect(_quit_to_title)

    math_cat.modulate = ProfileManager.cat_modulate()
    _animated_background_material = %Background.material.duplicate() as ShaderMaterial
    _apply_background_setting()
    blitz_results = BlitzResults.new()
    blitz_results.hide()
    add_child(blitz_results)
    blitz_results.retry_requested.connect(_restart_game)
    blitz_results.title_requested.connect(_quit_to_title)
    _blitz_menu_hint = Label.new()
    _blitz_menu_hint.text = "BLITZ: TIME KEEPS RUNNING"
    _blitz_menu_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _blitz_menu_hint.add_theme_color_override("font_color", Color("f0d35e"))
    _blitz_menu_hint.add_theme_font_size_override("font_size", 24)
    var pause_layout := pause_overlay.get_node("Panel/Margin/Layout")
    pause_layout.add_child(_blitz_menu_hint)
    pause_layout.move_child(_blitz_menu_hint, 0)
    _create_duel_ui()
    adventure = AdventureGameplay.new()
    add_child(adventure)
    _configure_answer_input_mode()
    resized.connect(_fit_question_and_answer_text)
    _create_achievement_toast()
    for achievement_id in AchievementManager.consume_pending_notifications():
        _queue_achievement_notification(achievement_id)
    _load_next_question()
    _refresh_hud()
    if GameManager.is_blitz_mode():
        _prepare_blitz_round(GameManager.session_serial)

func _input(event: InputEvent) -> void:
    if DebugMenu.handle_toggle(event):
        return
    if GameManager.is_adventure_mode() and adventure.finished:
        adventure.handle_input(event)
        return
    var fresh := GameManager.duel_input.fresh_press(event)
    if GameManager.is_two_player_blitz():
        if (event is InputEventKey or event is InputEventJoypadButton) and not fresh:
            get_viewport().set_input_as_handled()
            return
        if not blitz_results.visible and _handle_duel_recovery(event):
            get_viewport().set_input_as_handled()
            return
    if blitz_results.visible:
        if blitz_results.handle_input(event):
            get_viewport().set_input_as_handled()
        return
    if GameManager.is_blitz_mode() and event is InputEventKey and event.echo:
        get_viewport().set_input_as_handled()
        return
    if game_over_overlay.visible:
        if event is InputEventJoypadMotion:
            get_viewport().set_input_as_handled()
            if _pause_stick_direction(event) != Vector2i.ZERO:
                if retry_button.has_focus():
                    title_screen_button.grab_focus()
                else:
                    retry_button.grab_focus()
            return
        if event.is_action_pressed("answer_1"):
            _retry_session()
            get_viewport().set_input_as_handled()
        return

    if pause_overlay.visible:
        if event is InputEventJoypadMotion:
            get_viewport().set_input_as_handled()
        if _pause_options_panel != null:
            _handle_pause_options_input(event)
            return
        _handle_pause_input(event)
        return

    if event.is_action_pressed("pause") and GameManager.current_state == GameManager.GameState.PLAYING:
        _pause_game()
        get_viewport().set_input_as_handled()
        return

    if GameManager.is_two_player_blitz():
        var answer := GameManager.duel_input.answer(event)
        if fresh and answer.x >= 0 and not answer_locked:
            GameManager.submit_duel_answer(answer.x, answer.y, GameManager.session_serial, _duel_question_id)
        get_viewport().set_input_as_handled()
        return

    if _handle_gameplay_keyboard_navigation(event):
        get_viewport().set_input_as_handled()
    elif _handle_navigation_mode_controller_input(event):
        get_viewport().set_input_as_handled()
    elif event is InputEventJoypadButton and event.pressed and not ProfileManager.controller_navigation_mode():
        match event.button_index:
            JOY_BUTTON_A:
                _handle_answer_input(0)
            JOY_BUTTON_B:
                _handle_answer_input(1)
            JOY_BUTTON_X:
                _handle_answer_input(2)
            JOY_BUTTON_Y:
                _handle_answer_input(3)

func _handle_answer_input(answer_index: int) -> void:
    _select_answer(answer_index)
    get_viewport().set_input_as_handled()

func _handle_gameplay_keyboard_navigation(event: InputEvent) -> bool:
    if not event is InputEventKey or not event.pressed or event.echo:
        return false

    if event.is_action_pressed("ui_up"):
        _enable_keyboard_answer_navigation()
        _focus_answer(3)
    elif event.is_action_pressed("ui_down"):
        _enable_keyboard_answer_navigation()
        _focus_answer(0)
    elif event.is_action_pressed("ui_left"):
        _enable_keyboard_answer_navigation()
        _focus_answer(2)
    elif event.is_action_pressed("ui_right"):
        _enable_keyboard_answer_navigation()
        _focus_answer(1)
    elif event.is_action_pressed("ui_accept") and (ProfileManager.controller_navigation_mode() or _keyboard_answer_navigation_active):
        _handle_answer_input(selected_answer_index)
    else:
        return false
    return true

func _handle_navigation_mode_controller_input(event: InputEvent) -> bool:
    if not ProfileManager.controller_navigation_mode():
        return false
    var direction := _controller_answer_direction(event)
    if direction != Vector2i.ZERO:
        if direction.y < 0:
            _focus_answer(3)
        elif direction.y > 0:
            _focus_answer(0)
        elif direction.x < 0:
            _focus_answer(2)
        else:
            _focus_answer(1)
        return true
    if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
        _handle_answer_input(selected_answer_index)
        return true
    return false

func _controller_answer_direction(event: InputEvent) -> Vector2i:
    if event is InputEventJoypadMotion:
        if event.axis != JOY_AXIS_LEFT_X and event.axis != JOY_AXIS_LEFT_Y:
            return Vector2i.ZERO
        if absf(event.axis_value) < ANSWER_STICK_DEAD_ZONE or not _accept_answer_navigation():
            return Vector2i.ZERO
        if event.axis == JOY_AXIS_LEFT_Y:
            return Vector2i.UP if event.axis_value < 0.0 else Vector2i.DOWN
        if event.axis == JOY_AXIS_LEFT_X:
            return Vector2i.LEFT if event.axis_value < 0.0 else Vector2i.RIGHT
    elif event is InputEventJoypadButton and event.pressed:
        if event.is_action_pressed("ui_up"):
            return Vector2i.UP if _accept_answer_navigation() else Vector2i.ZERO
        if event.is_action_pressed("ui_down"):
            return Vector2i.DOWN if _accept_answer_navigation() else Vector2i.ZERO
        if event.is_action_pressed("ui_left"):
            return Vector2i.LEFT if _accept_answer_navigation() else Vector2i.ZERO
        if event.is_action_pressed("ui_right"):
            return Vector2i.RIGHT if _accept_answer_navigation() else Vector2i.ZERO
    return Vector2i.ZERO

func _accept_answer_navigation() -> bool:
    var now := Time.get_ticks_msec()
    if now < _answer_navigation_ready_at:
        return false
    _answer_navigation_ready_at = now + ANSWER_CONTROLLER_NAV_REPEAT_MS
    return true

func _handle_pause_input(event: InputEvent) -> void:
    var stick_direction := _pause_stick_direction(event)
    if stick_direction != Vector2i.ZERO:
        _focus_pause_button(selected_pause_button + stick_direction.y)
    elif event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
        _resume_game()
    elif event.is_action_pressed("ui_up"):
        if not _accept_pause_navigation(event):
            return
        _focus_pause_button(selected_pause_button - 1)
    elif event.is_action_pressed("ui_down"):
        if not _accept_pause_navigation(event):
            return
        _focus_pause_button(selected_pause_button + 1)
    elif event.is_action_pressed("ui_accept"):
        pause_buttons[selected_pause_button].emit_signal("pressed")
    else:
        return

    get_viewport().set_input_as_handled()

func _accept_pause_navigation(event: InputEvent) -> bool:
    if not (event is InputEventJoypadButton or event is InputEventJoypadMotion):
        return true
    var now := Time.get_ticks_msec()
    if now < _pause_navigation_ready_at:
        return false
    _pause_navigation_ready_at = now + PAUSE_CONTROLLER_NAV_REPEAT_MS
    return true

func _pause_stick_direction(event: InputEvent) -> Vector2i:
    if not event is InputEventJoypadMotion or absf(event.axis_value) < ANSWER_STICK_DEAD_ZONE:
        return Vector2i.ZERO
    if event.axis != JOY_AXIS_LEFT_Y or not _accept_pause_navigation(event):
        return Vector2i.ZERO
    return Vector2i.UP if event.axis_value < 0.0 else Vector2i.DOWN

func _select_answer(answer_index: int) -> void:
    if GameManager.is_adventure_mode():
        adventure.select_answer(answer_index)
        return
    if GameManager.is_two_player_blitz():
        return
    if answer_locked or not GameManager.can_answer_question():
        return

    if GameManager.is_blitz_mode():
        _select_blitz_answer(answer_index)
        return
    var serial := GameManager.session_serial
    answer_locked = true
    _set_buttons_disabled(true)
    _set_face_button_prompt_opacity(answer_index)

    var is_correct := current_question.choices[answer_index] == current_question.correct_answer
    feedback_label.text = "Correct!" if is_correct else "Not quite."
    feedback_label.modulate = Color("79d26a") if is_correct else Color("ed6a5a")
    var response_seconds := float(Time.get_ticks_msec() - _question_visible_at_msec - _question_paused_duration_msec) / 1000.0
    print_debug("Achievement speed check: Grade %d, correct=%s, response=%.3fs" % [current_question.grade, is_correct, response_seconds])
    AchievementManager.record_question_response(current_question.grade, is_correct, response_seconds)
    GameManager.register_answer(is_correct, current_question.uses_pi)
    var is_promotion := is_correct and GameManager.current_state == GameManager.GameState.LEVEL_UP
    _set_selected_answer_feedback(answer_index, is_correct, is_promotion)
    if not is_correct:
        _reveal_correct_answer()

    if GameManager.current_state == GameManager.GameState.GAME_OVER:
        return

    # A promotion or game over drives its own animation; only react here otherwise.
    if not is_promotion:
        if is_correct:
            math_cat.play_happy()
        else:
            math_cat.play_sad()

    await get_tree().create_timer(0.75, false).timeout
    if serial != GameManager.session_serial:
        return
    if GameManager.current_state == GameManager.GameState.LEVEL_UP or GameManager.current_state == GameManager.GameState.DEMOTION:
        await get_tree().create_timer(1.25, false).timeout
        if serial != GameManager.session_serial:
            return
        if GameManager.current_state != GameManager.GameState.GAME_OVER:
            GameManager.set_state(GameManager.GameState.PLAYING)

    if GameManager.current_state == GameManager.GameState.PLAYING:
        _load_next_question()
        feedback_label.text = ""
        _set_buttons_disabled(false)
        answer_locked = false

func _select_blitz_answer(answer_index: int) -> void:
    var serial := GameManager.session_serial
    answer_locked = true
    _set_buttons_disabled(true)
    get_viewport().set_input_as_handled()
    var is_correct := current_question.choices[answer_index] == current_question.correct_answer
    GameManager.register_answer(is_correct, current_question.uses_pi)
    if GameManager.current_state != GameManager.GameState.PLAYING:
        return
    _blitz_feedback_pending = true
    _set_selected_answer_feedback(answer_index, is_correct)
    if not is_correct:
        _reveal_correct_answer()
    feedback_label.text = "+1 Correct!" if is_correct else "-1 Incorrect"
    feedback_label.modulate = CORRECT_PIP_COLOR if is_correct else INCORRECT_PIP_COLOR
    if is_correct:
        math_cat.play_happy()
    else:
        math_cat.play_sad()
    await get_tree().create_timer(0.7, false).timeout
    if not is_inside_tree() or serial != GameManager.session_serial:
        return
    GameManager.sync_blitz_clock()
    if GameManager.current_state not in [GameManager.GameState.PLAYING, GameManager.GameState.PAUSED]:
        return
    _blitz_feedback_pending = false
    _load_next_question()
    feedback_label.text = ""
    answer_locked = GameManager.current_state == GameManager.GameState.PAUSED
    _set_buttons_disabled(answer_locked)

func _prepare_blitz_round(serial: int) -> void:
    answer_locked = true
    _set_buttons_disabled(true)
    await get_tree().process_frame
    if GameManager.is_two_player_blitz():
        await get_tree().process_frame
    if serial != GameManager.session_serial or not is_inside_tree():
        return
    _fit_question_and_answer_text()
    if GameManager.is_two_player_blitz():
        GameManager.ready_duel_question(serial, _duel_question_id)
        answer_locked = not GameManager.duel_round.ready
        _on_duel_assignments_changed()
        return
    GameManager.arm_blitz_round(serial)
    if GameManager.current_state == GameManager.GameState.PLAYING:
        _set_buttons_disabled(false)
        answer_locked = false

func _create_duel_ui() -> void:
    _duel_layout = Control.new()
    _duel_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _duel_layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_duel_layout)
    move_child(_duel_layout, pause_overlay.get_index())
    for player in 2:
        var panel := DuelPanel.new()
        panel.player = player
        _duel_layout.add_child(panel)
        panel.anchor_left = float(player)
        panel.anchor_right = float(player)
        panel.offset_left = 24 if player == 0 else -272
        panel.offset_right = 272 if player == 0 else -24
        panel.offset_top = 132
        panel.offset_bottom = 396
        duel_panels.append(panel)
    _duel_connection_hint = Label.new()
    _duel_connection_hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    _duel_connection_hint.offset_top = 93
    _duel_connection_hint.offset_bottom = 130
    _duel_connection_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _duel_connection_hint.add_theme_font_size_override("font_size", 16)
    _duel_connection_hint.add_theme_color_override("font_color", Color("ffbf85"))
    _duel_connection_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_duel_connection_hint)

func _on_duel_answered(player: int, is_correct: bool, question_closed: bool) -> void:
    duel_panels[player].update_score(GameManager.duel_round.scores[player])
    duel_panels[player].react(is_correct)
    _set_selected_answer_feedback(GameManager.duel_round.selections[player], is_correct, is_correct and player == 1)
    if question_closed:
        if not is_correct:
            _reveal_correct_answer()
        _clear_incorrect_answer_backgrounds(not is_correct)
        answer_locked = true
        _blitz_feedback_pending = true
        _advance_duel_question(GameManager.session_serial, _duel_question_id)

func _advance_duel_question(serial: int, question_id: int) -> void:
    await get_tree().create_timer(0.7, false).timeout
    if not is_inside_tree() or serial != GameManager.session_serial or not GameManager.is_two_player_blitz() or question_id != _duel_question_id:
        return
    GameManager.sync_blitz_clock()
    if GameManager.current_state not in [GameManager.GameState.PLAYING, GameManager.GameState.PAUSED]:
        return
    _blitz_feedback_pending = false
    _load_next_question()
    await _ready_duel_presentation(serial, _duel_question_id)

func _ready_duel_presentation(serial: int, question_id: int) -> void:
    # Let the replacement question render before accepting the next batch of input.
    await get_tree().process_frame
    await get_tree().process_frame
    if not is_inside_tree() or serial != GameManager.session_serial or question_id != _duel_question_id or not GameManager.is_two_player_blitz():
        return
    GameManager.ready_duel_question(serial, question_id)
    answer_locked = not GameManager.duel_round.ready

func _on_duel_assignments_changed() -> void:
    if _duel_connection_hint == null:
        return
    var missing := GameManager.is_two_player_blitz() and not GameManager.duel_input.complete()
    _duel_connection_hint.visible = missing and not blitz_results.visible
    if missing:
        _duel_connection_hint.offset_left = 0 if pause_overlay.visible else 280
        _duel_connection_hint.offset_right = 0 if pause_overlay.visible else -280
        _duel_connection_hint.offset_top = 672 if pause_overlay.visible else 84
        _duel_connection_hint.offset_bottom = 716 if pause_overlay.visible else 124
        _duel_connection_hint.text = "%s\nNew controller: A to join. %s" % [
            GameManager.duel_input.status_text(),
            "B / Escape: Title" if GameManager.current_state == GameManager.GameState.BLITZ_READY else "Start: Menu. TIME KEEPS RUNNING.",
        ]

func _handle_duel_recovery(event: InputEvent) -> bool:
    if GameManager.duel_input.controls != GameManager.DuelInput.Controls.CONTROLLERS:
        return false
    if GameManager.current_state == GameManager.GameState.BLITZ_READY and event.is_action_pressed("ui_cancel"):
        _quit_to_title()
        return true
    if not GameManager.duel_input.complete() and event is InputEventJoypadButton and event.button_index == JOY_BUTTON_A and not GameManager.duel_input.devices.has(event.device):
        if GameManager.duel_input.join(event.device) and GameManager.duel_input.complete() and GameManager.current_state == GameManager.GameState.BLITZ_READY:
            _prepare_blitz_round(GameManager.session_serial)
        return true
    return false

func _update_timer(seconds_left: int) -> void:
    timer_label.text = "TIME %02d:%02d" % [seconds_left / 60, seconds_left % 60]
    if _blitz_menu_hint != null:
        _blitz_menu_hint.text = "BLITZ: TIME KEEPS RUNNING  %02d:%02d" % [seconds_left / 60, seconds_left % 60]

func _update_lives(new_lives: int) -> void:
    for heart_index in heart_icons.size():
        heart_icons[heart_index].set("filled", heart_index < new_lives)

func _update_score(new_score: int) -> void:
    score_label.text = "SCORE %s" % NumericDisplayFormatterScript.format_integer(new_score)
    if GameManager.is_adventure_mode() and adventure != null:
        adventure.refresh_hud()

func _on_new_high_score(_score: int) -> void:
    # Session ends synchronously right after this fires, so _show_game_over reads the flag.
    _game_over_is_new_high_score = true

func _show_time_bonus(_completed_grade: int, bonus_seconds: int) -> void:
    time_bonus_label.text = "+%d Seconds!" % bonus_seconds
    time_bonus_label.position.y = 284.0
    time_bonus_label.modulate = Color(1, 1, 1, 1)
    time_bonus_label.show()
    var bonus_tween := create_tween()
    bonus_tween.set_parallel(true)
    bonus_tween.tween_property(time_bonus_label, "position:y", 248.0, 0.9)
    bonus_tween.tween_property(time_bonus_label, "modulate:a", 0.0, 0.9)

func _update_progress(_is_correct: bool, correct_count: int, incorrect_count: int) -> void:
    if not GameManager.is_standard_mode():
        return
    grade_label.text = "GRADE %d" % ProgressionManager.current_grade
    _set_meter_fill(correct_pips, correct_count)
    _set_meter_fill(incorrect_pips, incorrect_count)

func _show_grade_change(old_grade: int, new_grade: int, promoted: bool) -> void:
    if GameManager.is_adventure_mode():
        adventure.refresh_hud()
        if GameManager.is_adventure_boss() and not adventure.finished:
            _progress_reset_pending = true
            _flash_progress_meters(correct_pips if promoted else incorrect_pips, CORRECT_PIP_COLOR if promoted else INCORRECT_PIP_COLOR)
            feedback_label.text = "Level Up! Grade %d" % new_grade if promoted else "Demoted to Grade %d" % new_grade
            feedback_label.modulate = CORRECT_PIP_COLOR if promoted else INCORRECT_PIP_COLOR
        return
    grade_label.text = "GRADE %d" % new_grade
    _progress_reset_pending = true
    _flash_progress_meters(correct_pips if promoted else incorrect_pips, CORRECT_PIP_COLOR if promoted else INCORRECT_PIP_COLOR)
    var old_stage := MathCatStagesScript.stage_for_grade(old_grade)
    var new_stage := MathCatStagesScript.stage_for_grade(new_grade)
    var is_evolution := promoted and new_stage != old_stage
    var promotion_feedback := _promotion_feedback_for_grade(new_grade)

    if promoted and not promotion_feedback.is_empty():
        feedback_label.text = promotion_feedback
        feedback_label.modulate = CORRECT_PIP_COLOR
        return

    if is_evolution:
        feedback_label.text = _evolution_feedback_for_stage(new_stage)
        feedback_label.modulate = CORRECT_PIP_COLOR
        return

    feedback_label.text = "Level Up! Grade %d" % new_grade if promoted else "Demoted to Grade %d" % new_grade
    feedback_label.modulate = CORRECT_PIP_COLOR if promoted else Color("f4d35e")

func _promotion_feedback_for_grade(grade: int) -> String:
    match grade:
        6:
            return "A Wild Grade 6 Appears!"
        7:
            return "Grade 7 – Algebra!"
        8:
            return "Grade 8 – More Algebra!"
        9:
            return "Math Cat goes to High School"
        10:
            return "The Pi is a Lie"
        11:
            return "SAT Prep Time"
        12:
            return "Last Level! Let's Go!"
        13:
            return "VICTORY!"
    return ""

func _evolution_feedback_for_stage(stage: MathCatStagesScript.Stage) -> String:
    match stage:
        MathCatStagesScript.Stage.BIG_CAT:
            return "Kitten has evolved to Math Cat!"
        MathCatStagesScript.Stage.TIGER:
            return "Cat has evolved to Math Tiger!"
        MathCatStagesScript.Stage.NERD_CAT:
            return "Professor Wiskers has entered the Game!"
    return ""

func _show_game_over(final_score: int, _final_grade: int, reason: String) -> void:
    answer_locked = true
    _set_buttons_disabled(true)
    if GameManager.is_blitz_mode():
        _close_pause_options()
        pause_overlay.hide()
        game_over_overlay.hide()
        feedback_label.text = ""
        blitz_results.present(GameManager.blitz_result())
        if GameManager.is_two_player_blitz():
            _duel_connection_hint.hide()
            var winner := int(GameManager.blitz_result().winner)
            for player in 2:
                if player == winner:
                    duel_panels[player].cat.play_high_score()
                else:
                    duel_panels[player].cat.play_game_over()
            return
        if BlitzLeaderboard.qualifying_rank(GameManager.blitz_grade, final_score) >= 0:
            math_cat.play_high_score()
        else:
            math_cat.play_game_over()
        return
    var serial := GameManager.session_serial
    if reason == "out_of_lives" or reason == GameManager.VICTORY_REASON:
        await get_tree().create_timer(RESULT_REVEAL_DELAY_SECONDS, false).timeout
        if serial != GameManager.session_serial:
            return
    feedback_label.text = ""
    match reason:
        GameManager.VICTORY_REASON:
            game_over_reason_label.text = "Reason: VICTORY"
        "time_up":
            game_over_reason_label.text = "Reason: TIME UP"
        _:
            game_over_reason_label.text = "Reason: OUT OF LIVES"
    game_over_score_label.text = "Final Score: %s" % NumericDisplayFormatterScript.format_integer(final_score)
    game_over_max_grade_label.text = "Max Grade Level Achieved: %s" % NumericDisplayFormatterScript.format_integer(GameManager.max_grade_achieved)
    game_over_streak_label.text = "Highest Correct Streak: %s" % NumericDisplayFormatterScript.format_integer(GameManager.highest_correct_streak)
    var total_answers := GameManager.total_correct_answers + GameManager.total_incorrect_answers
    var accuracy := 0 if total_answers == 0 else roundi(100.0 * GameManager.total_correct_answers / total_answers)
    game_over_answers_label.text = "Correct Answers: %s / %s (%s%%)" % [NumericDisplayFormatterScript.format_integer(GameManager.total_correct_answers), NumericDisplayFormatterScript.format_integer(total_answers), NumericDisplayFormatterScript.format_integer(accuracy)]
    var time_survived := floori(GameManager.time_survived_seconds)
    game_over_time_survived_label.text = "Time Survived: %02d:%02d" % [time_survived / 60, time_survived % 60]
    var stage := MathCatStagesScript.stage_for_grade(GameManager.max_grade_achieved)
    game_over_evolution_label.text = "Evolution Stage: %s" % MathCatStagesScript.stage_name(stage)
    var won := reason == GameManager.VICTORY_REASON
    game_over_title_label.text = "VICTORY!" if won else "GAME OVER"
    game_over_title_label.add_theme_color_override("font_color", CORRECT_PIP_COLOR if won else Color("f0d35e"))
    new_high_score_label.visible = _game_over_is_new_high_score
    if won:
        math_cat.play_evolution_victory_pose()
    elif _game_over_is_new_high_score:
        math_cat.play_high_score()
    else:
        math_cat.play_game_over()
    _game_over_is_new_high_score = false
    game_over_overlay.show()
    retry_button.grab_focus()

func _retry_session() -> void:
    if not game_over_overlay.visible:
        return

    AudioManager.play_sfx(AudioManager.SFX_UI_CONFIRM)
    GameManager.restart_current_session()

func _reset_after_retry() -> void:
    _apply_background_setting()
    if adventure != null:
        adventure.reset()
    if blitz_results != null:
        blitz_results.hide()
    _close_pause_options()
    game_over_overlay.hide()
    pause_overlay.hide()
    time_bonus_label.hide()
    new_high_score_label.hide()
    _game_over_is_new_high_score = false
    feedback_label.text = ""
    _blitz_feedback_pending = false
    answer_locked = false
    _set_buttons_disabled(false)
    math_cat.set_stage(MathCatStagesScript.stage_for_grade(ProgressionManager.current_grade))
    for panel in duel_panels:
        panel.reset_cat(ProgressionManager.current_grade)
        panel.update_score(0)
    _load_next_question()
    _refresh_hud()
    if GameManager.is_blitz_mode():
        _prepare_blitz_round(GameManager.session_serial)

func _pause_game() -> void:
    if GameManager.is_adventure_mode():
        GameManager.sync_adventure_clock()
    GameManager.sync_blitz_clock()
    if GameManager.current_state != GameManager.GameState.PLAYING:
        return
    AudioManager.play_sfx(AudioManager.SFX_PAUSE)
    AudioManager.pause_music()
    answer_locked = true
    _set_buttons_disabled(true)
    _question_paused_at_msec = Time.get_ticks_msec()
    GameManager.set_state(GameManager.GameState.PAUSED)
    math_cat.play_pause()
    if GameManager.is_two_player_blitz():
        for panel in duel_panels:
            panel.cat.play_pause()
    pause_overlay.show()
    _on_duel_assignments_changed()
    _pause_navigation_ready_at = 0
    _focus_pause_button(0)

func _resume_game() -> void:
    GameManager.sync_blitz_clock()
    if not pause_overlay.visible:
        return

    _close_pause_options()
    AudioManager.play_sfx(AudioManager.SFX_UNPAUSE)
    AudioManager.resume_music()
    pause_overlay.hide()
    _on_duel_assignments_changed()
    if _question_paused_at_msec > 0:
        _question_paused_duration_msec += Time.get_ticks_msec() - _question_paused_at_msec
        _question_paused_at_msec = 0
    GameManager.set_state(GameManager.GameState.PLAYING)
    math_cat.play_idle()
    answer_locked = _blitz_feedback_pending or (GameManager.is_adventure_mode() and (adventure.feedback_pending or not GameManager.adventure_question_open))
    _set_buttons_disabled(answer_locked)
    if GameManager.is_two_player_blitz():
        for panel in duel_panels:
            panel.cat.play_idle()
        _set_buttons_disabled(true)
        answer_locked = true
        if not _blitz_feedback_pending:
            _ready_duel_presentation(GameManager.session_serial, _duel_question_id)

func _restart_game() -> void:
    AudioManager.play_sfx(AudioManager.SFX_UI_CONFIRM)
    AudioManager.restart_music()
    GameManager.restart_current_session()

func _open_pause_options() -> void:
    AudioManager.play_sfx(AudioManager.SFX_UI_CONFIRM)
    _pause_options_buttons.clear()
    _pause_options_panel = PanelContainer.new()
    _pause_options_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    _pause_options_panel.size = Vector2(680, 620)
    _pause_options_panel.position = Vector2(-340, -310)
    _pause_options_panel.add_theme_stylebox_override("panel", _create_feedback_style(Color("1a243c"), Color("f0d35e")))
    pause_overlay.add_child(_pause_options_panel)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 32)
    margin.add_theme_constant_override("margin_top", 24)
    margin.add_theme_constant_override("margin_right", 32)
    margin.add_theme_constant_override("margin_bottom", 24)
    _pause_options_panel.add_child(margin)
    var layout := VBoxContainer.new()
    layout.alignment = BoxContainer.ALIGNMENT_CENTER
    layout.add_theme_constant_override("separation", 12)
    margin.add_child(layout)
    _blitz_menu_hint.reparent(layout)
    var title := Label.new()
    title.text = "OPTIONS"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 42)
    title.add_theme_color_override("font_color", Color("f0d35e"))
    layout.add_child(title)
    _add_pause_option(layout, "Master Volume", "master_volume")
    _add_pause_option(layout, "Music Volume", "music_volume")
    _add_pause_option(layout, "Sound Effects Volume", "sfx_volume")
    _add_pause_option(layout, "Controller Input", "controller")
    _add_pause_option(layout, "Cat Color (Solo)" if GameManager.is_two_player_blitz() else "Cat Color", "cat_color")
    _add_pause_option(layout, "Animated Background", "background")
    var back_button := _make_pause_option_button("BACK")
    back_button.pressed.connect(_close_pause_options)
    layout.add_child(back_button)
    _pause_options_buttons.append(back_button)
    _selected_pause_option = 0
    _pause_options_buttons[0].grab_focus()

func _add_pause_option(layout: VBoxContainer, label: String, key: String) -> void:
    var button := _make_pause_option_button("")
    button.set_meta("option_label", label)
    button.set_meta("option_key", key)
    button.pressed.connect(_change_pause_option.bind(button, 1))
    _refresh_pause_option(button)
    layout.add_child(button)
    _pause_options_buttons.append(button)

func _make_pause_option_button(text: String) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(0, 58)
    button.add_theme_font_size_override("font_size", 25)
    button.add_theme_color_override("font_color", Color.WHITE)
    button.add_theme_color_override("font_outline_color", Color.BLACK)
    button.add_theme_constant_override("outline_size", 3)
    button.add_theme_stylebox_override("normal", _create_feedback_style(Color("101f35"), Color("638ab7")))
    button.add_theme_stylebox_override("hover", _create_feedback_style(Color("2b4269"), Color("f0d35e")))
    button.add_theme_stylebox_override("focus", _create_feedback_style(Color("2b4269"), Color("f0d35e")))
    return button

func _change_pause_option(button: Button, direction: int) -> void:
    var key := str(button.get_meta("option_key"))
    match key:
        "master_volume": ProfileManager.set_volume(key, posmod(ProfileManager.master_volume() + direction, 11))
        "music_volume": ProfileManager.set_volume(key, posmod(ProfileManager.music_volume() + direction, 11))
        "sfx_volume": ProfileManager.set_volume(key, posmod(ProfileManager.sfx_volume() + direction, 11))
        "controller": ProfileManager.set_controller_input_style("navigation" if not ProfileManager.controller_navigation_mode() else "direct")
        "cat_color":
            var colors := ProfileManager.CAT_COLORS.keys()
            var current_index := colors.find(ProfileManager.cat_color_name())
            ProfileManager.set_cat_color(colors[posmod(current_index + direction, colors.size())])
            math_cat.modulate = ProfileManager.cat_modulate()
        "background":
            ProfileManager.set_animated_background(not ProfileManager.animated_background_enabled())
            _apply_background_setting()
    _refresh_pause_option(button)
    AudioManager.play_sfx(AudioManager.SFX_UI_CONFIRM)

func _refresh_pause_option(button: Button) -> void:
    var label := str(button.get_meta("option_label"))
    var key := str(button.get_meta("option_key"))
    var value := ""
    match key:
        "master_volume": value = str(ProfileManager.master_volume())
        "music_volume": value = str(ProfileManager.music_volume())
        "sfx_volume": value = str(ProfileManager.sfx_volume())
        "controller": value = "Navigation Mode" if ProfileManager.controller_navigation_mode() else "Direct Button Mode"
        "cat_color": value = ProfileManager.cat_color_name()
        "background": value = "On" if ProfileManager.animated_background_enabled() else "Off"
    button.text = "%s  <  %s  >" % [label, value]

func _apply_background_setting() -> void:
    var use_stage_background := GameManager.is_adventure_mode() and not GameManager.is_adventure_boss()
    if use_stage_background:
        question_label.add_theme_color_override("font_outline_color", Color("100c29"))
        question_label.add_theme_constant_override("outline_size", 4)
        if _adventure_stage_background == null:
            _adventure_stage_background = AdventureStageBackground.new()
            _adventure_stage_background.name = "AdventureStageBackground"
            add_child(_adventure_stage_background)
            move_child(_adventure_stage_background, %Background.get_index() + 1)
        _adventure_stage_background.configure(GameManager.adventure_config)
    else:
        question_label.remove_theme_color_override("font_outline_color")
        question_label.remove_theme_constant_override("outline_size")
    if _adventure_stage_background != null:
        _adventure_stage_background.visible = use_stage_background
        _adventure_stage_background.set_animated(use_stage_background and ProfileManager.animated_background_enabled())
    %Background.visible = not use_stage_background
    if ProfileManager.animated_background_enabled():
        %Background.material = _animated_background_material
        %Background.color = Color.WHITE
        $BackgroundEvolutionManager._apply_grade(ProgressionManager.current_grade)
        _apply_adventure_grid_color()
    else:
        %Background.material = null
        %Background.color = Color("0b1225")

func _apply_adventure_grid_color() -> void:
    var use_stage_color := GameManager.is_adventure_mode() and not GameManager.is_adventure_boss()
    _animated_background_material.set_shader_parameter("grid_color_override_enabled", use_stage_color)
    if use_stage_color:
        _animated_background_material.set_shader_parameter("grid_color_override", GameManager.adventure_config.highlight_color)

func _apply_live_setting(setting: String) -> void:
    match setting:
        "controller_input_style":
            _keyboard_answer_navigation_active = false
            _configure_answer_input_mode()
            if ProfileManager.controller_navigation_mode() and not GameManager.is_two_player_blitz():
                _focus_answer(0)
        "cat_color":
            math_cat.modulate = ProfileManager.cat_modulate()
        "animated_background":
            _apply_background_setting()

func _handle_pause_options_input(event: InputEvent) -> void:
    var stick_direction := _pause_options_stick_direction(event)
    if stick_direction != Vector2i.ZERO:
        if stick_direction.y != 0:
            _selected_pause_option = posmod(_selected_pause_option + stick_direction.y, _pause_options_buttons.size())
            _pause_options_buttons[_selected_pause_option].grab_focus()
        else:
            var stick_selected_button := _pause_options_buttons[_selected_pause_option]
            if stick_selected_button.has_meta("option_key"):
                _change_pause_option(stick_selected_button, stick_direction.x)
    elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
        _close_pause_options()
    elif event.is_action_pressed("ui_up"):
        if _accept_pause_navigation(event):
            _selected_pause_option = posmod(_selected_pause_option - 1, _pause_options_buttons.size())
            _pause_options_buttons[_selected_pause_option].grab_focus()
    elif event.is_action_pressed("ui_down"):
        if _accept_pause_navigation(event):
            _selected_pause_option = posmod(_selected_pause_option + 1, _pause_options_buttons.size())
            _pause_options_buttons[_selected_pause_option].grab_focus()
    elif event.is_action_pressed("ui_left"):
        if not _accept_pause_navigation(event):
            return
        var selected_button := _pause_options_buttons[_selected_pause_option]
        if selected_button.has_meta("option_key"):
            _change_pause_option(selected_button, -1)
    elif event.is_action_pressed("ui_right"):
        if not _accept_pause_navigation(event):
            return
        _pause_options_buttons[_selected_pause_option].emit_signal("pressed")
    elif event.is_action_pressed("ui_accept"):
        _pause_options_buttons[_selected_pause_option].emit_signal("pressed")
    else:
        return
    get_viewport().set_input_as_handled()

func _pause_options_stick_direction(event: InputEvent) -> Vector2i:
    if not event is InputEventJoypadMotion or absf(event.axis_value) < ANSWER_STICK_DEAD_ZONE:
        return Vector2i.ZERO
    if event.axis != JOY_AXIS_LEFT_X and event.axis != JOY_AXIS_LEFT_Y:
        return Vector2i.ZERO
    if not _accept_pause_navigation(event):
        return Vector2i.ZERO
    if event.axis == JOY_AXIS_LEFT_X:
        return Vector2i.LEFT if event.axis_value < 0.0 else Vector2i.RIGHT
    return Vector2i.UP if event.axis_value < 0.0 else Vector2i.DOWN

func _close_pause_options() -> void:
    if _pause_options_panel != null:
        var pause_layout := pause_overlay.get_node("Panel/Margin/Layout")
        _blitz_menu_hint.reparent(pause_layout)
        pause_layout.move_child(_blitz_menu_hint, 0)
        _pause_options_panel.queue_free()
    _pause_options_panel = null
    _pause_options_buttons.clear()

func _quit_to_title() -> void:
    if GameManager.is_adventure_mode():
        adventure.return_to_map()
        return
    AudioManager.play_sfx(AudioManager.SFX_UI_CONFIRM)
    AudioManager.stop_music()
    GameManager.abandon_current_session()
    GameManager.goto_scene("res://scenes/title/title.tscn")

func _focus_pause_button(button_index: int) -> void:
    selected_pause_button = posmod(button_index, pause_buttons.size())
    pause_buttons[selected_pause_button].grab_focus()

func _load_next_question() -> void:
    time_bonus_label.hide()
    _set_face_button_prompt_opacity()
    _clear_answer_feedback()
    feedback_label.text = ""
    current_question = question_bank.get_question(ProgressionManager.current_grade)
    question_label.remove_theme_font_size_override("font_size")
    question_label.text = NumericDisplayFormatterScript.format_text(current_question.question_text)
    for answer_index in answer_buttons.size():
        answer_buttons[answer_index].remove_theme_font_size_override("font_size")
        answer_buttons[answer_index].text = NumericDisplayFormatterScript.format_text(current_question.choices[answer_index])

    if GameManager.is_two_player_blitz():
        _duel_question_id = GameManager.present_duel_question(current_question, GameManager.session_serial)
        for panel in duel_panels:
            panel.clear_lockout()
        call_deferred("_fit_question_and_answer_text")
        _configure_answer_input_mode()
        return

    call_deferred("_fit_question_and_answer_text")
    _keyboard_answer_navigation_active = false
    _configure_answer_input_mode()
    if ProfileManager.controller_navigation_mode():
        _focus_answer(0)
    if _progress_reset_pending:
        _reset_progress_indicators()
    _question_visible_at_msec = Time.get_ticks_msec()
    _question_paused_at_msec = 0
    _question_paused_duration_msec = 0
    if GameManager.is_adventure_mode():
        adventure.present_question()

func _fit_question_and_answer_text() -> void:
    _fit_question_font()
    for answer_button in answer_buttons:
        _fit_answer_font(answer_button)

func _fit_question_font() -> void:
    if GameManager.is_two_player_blitz():
        _fit_duel_text(question_label, question_label.text, Vector2(question_label.size.x - 16, 144), QUESTION_MAX_FONT_SIZE, QUESTION_MIN_FONT_SIZE)
        return
    question_label.add_theme_font_size_override("font_size", QUESTION_MAX_FONT_SIZE)
    if current_question != null and current_question.grade == 5 and current_question.topic in ["Decimal Place Value", "Decimal Comparison"]:
        question_label.add_theme_font_size_override("font_size", GRADE_FIVE_DECIMAL_QUESTION_FONT_SIZE)
        return
    if _uses_grade_six_extended_question_font():
        question_label.add_theme_font_size_override("font_size", GRADE_SIX_EXTENDED_QUESTION_FONT_SIZE)
        return
    if _uses_grade_eight_quadrant_question_font():
        question_label.add_theme_font_size_override("font_size", GRADE_EIGHT_QUADRANT_QUESTION_FONT_SIZE)
        return
    if _uses_grade_eight_scientific_notation_question_font():
        question_label.add_theme_font_size_override("font_size", GRADE_EIGHT_SCIENTIFIC_NOTATION_QUESTION_FONT_SIZE)
        return
    if question_label.text.length() < QUESTION_WORD_PROBLEM_MIN_LENGTH:
        return

    var available_width := maxf(question_label.size.x - 48.0, 1.0)
    var available_height := maxf(question_label.size.y - 32.0, 1.0)
    var font: Font = question_label.get_theme_font("font")
    var selected_font_size := QUESTION_MIN_FONT_SIZE
    for font_size in range(QUESTION_MAX_FONT_SIZE, QUESTION_MIN_FONT_SIZE - 1, -1):
        var full_text_width := font.get_string_size(question_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
        var longest_word_width := _longest_word_width(font, question_label.text, font_size)
        var line_count := ceili(full_text_width / available_width)
        var text_height := font.get_height(font_size) * line_count
        if text_height <= available_height and longest_word_width <= available_width:
            selected_font_size = font_size
            break
    question_label.add_theme_font_size_override("font_size", selected_font_size)

func _uses_grade_six_extended_question_font() -> bool:
    if current_question == null or current_question.grade != 6:
        return false
    if current_question.topic in ["Geometry Foundations", "Coordinate Plane Basics"]:
        return true
    if current_question.topic == "Algebraic Expressions" and question_label.text.begins_with("If a ="):
        return true
    return current_question.topic == "Statistics" and (question_label.text.begins_with("Find the mean:") or question_label.text.begins_with("Find the median:") or question_label.text.begins_with("Find the mode:"))

func _uses_grade_eight_quadrant_question_font() -> bool:
    return current_question != null and current_question.grade == 8 and current_question.topic == "Graphing and Coordinate Plane" and question_label.text.begins_with("Which quadrant contains")

func _uses_grade_eight_scientific_notation_question_font() -> bool:
    return current_question != null and current_question.grade == 8 and current_question.topic == "Scientific Notation"

func _fit_answer_font(answer_button: Button) -> void:
    if GameManager.is_two_player_blitz():
        var tile_size := answer_button.custom_minimum_size
        _fit_duel_text(answer_button, answer_button.text, tile_size - Vector2(8, 8), ANSWER_MAX_FONT_SIZE, ANSWER_MIN_FONT_SIZE)
        answer_button.size = tile_size
        var anchor := Vector2(answer_button.anchor_left, answer_button.anchor_top)
        answer_button.position = answer_button.get_parent().size * anchor + _solo_answer_centers[answer_buttons.find(answer_button)] - tile_size / 2
        return
    var available_width := maxf(answer_button.size.x - 32.0, 1.0)
    var available_height := maxf(answer_button.size.y - 20.0, 1.0)
    var font: Font = answer_button.get_theme_font("font")
    var selected_font_size := ANSWER_MIN_FONT_SIZE
    for font_size in range(ANSWER_MAX_FONT_SIZE, ANSWER_MIN_FONT_SIZE - 1, -1):
        var full_text_width := font.get_string_size(answer_button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
        var line_count := ceili(full_text_width / available_width)
        var text_height := font.get_height(font_size) * line_count
        if text_height <= available_height and _longest_word_width(font, answer_button.text, font_size) <= available_width:
            selected_font_size = font_size
            break
    answer_button.add_theme_font_size_override("font_size", selected_font_size)

func _fit_duel_text(control: Control, text: String, available: Vector2, max_size: int, min_size: int) -> void:
    var font := control.get_theme_font("font")
    for font_size in range(max_size, min_size - 1, -1):
        control.add_theme_font_size_override("font_size", font_size)
        var measured := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, maxf(available.x, 1), font_size)
        var line_spacing := control.get_theme_constant("line_spacing") if control is Label else 0
        var lines := maxi(ceili(measured.y / font.get_height(font_size)), 1)
        if measured.y + (lines - 1) * line_spacing <= available.y and _longest_word_width(font, text, font_size) <= available.x:
            break

func _longest_word_width(font: Font, text: String, font_size: int) -> float:
    var widest_word := 0.0
    for word in text.split(" ", false):
        widest_word = maxf(widest_word, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
    return widest_word

func _refresh_hud() -> void:
    var duel := GameManager.is_two_player_blitz()
    %HeaderBar.custom_minimum_size.y = _solo_header_height
    var timer_offsets := Vector4(-140, -54, 140, -9) if duel else _solo_timer_offsets
    timer_label.offset_left = timer_offsets.x
    timer_label.offset_top = timer_offsets.y
    timer_label.offset_right = timer_offsets.z
    timer_label.offset_bottom = timer_offsets.w
    timer_label.add_theme_font_size_override("font_size", _solo_timer_font_size)
    timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if duel else _solo_timer_alignment
    grade_label.add_theme_font_size_override("font_size", _solo_grade_font_size)
    question_label.get_parent().custom_minimum_size = Vector2(680, 160) if duel else _solo_question_minimum_size
    _duel_layout.visible = duel
    math_cat.visible = not duel
    score_label.visible = not duel
    feedback_label.visible = not duel
    for panel in duel_panels:
        panel.reset_cat(ProgressionManager.current_grade)
    _on_duel_assignments_changed()
    grade_label.text = ("BLITZ\nGRADE %d" if GameManager.is_blitz_mode() else "GRADE %d") % ProgressionManager.current_grade
    %HeaderBar.get_node("Margin/Header/GradeProgressPanel/CorrectProgress").visible = GameManager.is_standard_mode()
    %HeaderBar.get_node("Margin/Header/GradeProgressPanel/IncorrectProgress").visible = GameManager.is_standard_mode()
    %HeartContainer.visible = not GameManager.is_blitz_mode()
    %HeaderBar.get_node("Margin/Header/LivesLabel").visible = not GameManager.is_blitz_mode()
    if _blitz_menu_hint != null:
        _blitz_menu_hint.visible = GameManager.is_blitz_mode()
    _update_score(GameManager.score)
    _update_timer(ceili(GameManager.time_left))
    _update_lives(GameManager.lives)
    _update_progress(true, ProgressionManager.correct_count, ProgressionManager.incorrect_count)
    score_label.add_theme_font_size_override("font_size", 36)
    if adventure != null:
        adventure.refresh_hud()

func debug_shift_clock(elapsed_msec: int) -> void:
    if OS.is_debug_build() and _question_paused_at_msec == 0:
        _question_visible_at_msec += elapsed_msec

func debug_clear_achievement_notifications() -> void:
    if OS.is_debug_build():
        _achievement_notification_queue.clear()
        if _achievement_toast != null:
            _achievement_toast.hide()

func debug_refresh_hud() -> void:
    if not OS.is_debug_build():
        return
    _update_score(GameManager.score)
    _update_lives(GameManager.lives)
    _update_timer(ceili(GameManager.time_left))
    _update_progress(true, ProgressionManager.correct_count, ProgressionManager.incorrect_count)
    if GameManager.is_two_player_blitz():
        for player in 2:
            duel_panels[player].update_score(GameManager.duel_round.scores[player])
    if adventure != null:
        adventure.refresh_hud()

func _set_meter_fill(meters: Array[Control], filled_count: int) -> void:
    for meter_index in meters.size():
        meters[meter_index].set("filled", meter_index < filled_count)

func _flash_progress_meters(meters: Array[Control], original_color: Color) -> void:
    for meter in meters:
        var flash_tween := create_tween()
        flash_tween.tween_property(meter, "active_color", Color.WHITE, PIP_FLASH_STEP_DURATION)
        flash_tween.tween_property(meter, "active_color", original_color, PIP_FLASH_STEP_DURATION)
        flash_tween.tween_property(meter, "active_color", Color.WHITE, PIP_FLASH_STEP_DURATION)
        flash_tween.tween_property(meter, "active_color", original_color, PIP_FLASH_STEP_DURATION)

func _reset_progress_indicators() -> void:
    _set_meter_fill(correct_pips, 0)
    _set_meter_fill(incorrect_pips, 0)
    for meter in correct_pips:
        meter.set("active_color", CORRECT_PIP_COLOR)
    for meter in incorrect_pips:
        meter.set("active_color", INCORRECT_PIP_COLOR)
    _progress_reset_pending = false

func _set_buttons_disabled(disabled: bool) -> void:
    for answer_button in answer_buttons:
        answer_button.disabled = disabled and not GameManager.is_two_player_blitz()

func _set_face_button_prompt_opacity(selected_index: int = -1) -> void:
    for prompt in face_button_prompts:
        prompt.modulate = Color.WHITE
    _update_face_button_prompt_labels()

func _focus_answer(answer_index: int) -> void:
    selected_answer_index = answer_index
    answer_buttons[selected_answer_index].grab_focus()
    _update_face_button_prompt_labels()

func _enable_keyboard_answer_navigation() -> void:
    _keyboard_answer_navigation_active = true
    for answer_button in answer_buttons:
        answer_button.focus_mode = Control.FOCUS_ALL

func _configure_answer_input_mode() -> void:
    if GameManager.is_two_player_blitz():
        for button in answer_buttons:
            button.focus_mode = Control.FOCUS_NONE
            button.mouse_filter = Control.MOUSE_FILTER_IGNORE
            button.release_focus()
        _update_face_button_prompt_labels()
        return
    for answer_button in answer_buttons:
        answer_button.mouse_filter = Control.MOUSE_FILTER_STOP
        answer_button.focus_mode = Control.FOCUS_ALL if ProfileManager.controller_navigation_mode() else Control.FOCUS_NONE
        if not ProfileManager.controller_navigation_mode() and answer_button.has_focus():
            answer_button.release_focus()
    _update_face_button_prompt_labels()

func _update_face_button_prompt_labels() -> void:
    var direct_labels := ["A", "B", "X", "Y"]
    for prompt_index in face_button_prompts.size():
        var label := face_button_prompts[prompt_index].get_node("Label") as Label
        if label != null:
            if GameManager.is_two_player_blitz():
                label.text = direct_labels[prompt_index]
                label.add_theme_font_size_override("font_size", 36)
                continue
            label.add_theme_font_size_override("font_size", 36)
            label.text = "A" if ProfileManager.controller_navigation_mode() and prompt_index == selected_answer_index else "" if ProfileManager.controller_navigation_mode() else direct_labels[prompt_index]

func _set_selected_answer_feedback(answer_index: int, is_correct: bool, is_promotion: bool = false) -> void:
    var feedback_style: StyleBoxFlat = promotion_answer_style if is_promotion else correct_answer_style if is_correct else incorrect_answer_style
    _set_answer_feedback_style(answer_index, feedback_style)

func _set_answer_feedback_style(answer_index: int, feedback_style: StyleBoxFlat) -> void:
    var answer_button := answer_buttons[answer_index]
    answer_button.add_theme_stylebox_override("normal", feedback_style)
    answer_button.add_theme_stylebox_override("hover", feedback_style)
    answer_button.add_theme_stylebox_override("pressed", feedback_style)
    answer_button.add_theme_stylebox_override("disabled", feedback_style)

func _reveal_correct_answer() -> void:
    var correct_answer_index := current_question.choices.find(current_question.correct_answer)
    if correct_answer_index >= 0:
        _set_answer_feedback_style(correct_answer_index, revealed_answer_style)

func _clear_incorrect_answer_backgrounds(preserve_wrong_selections: bool = false) -> void:
    var correct_answer_index := current_question.choices.find(current_question.correct_answer)
    for answer_index in answer_buttons.size():
        if answer_index == correct_answer_index:
            continue
        if preserve_wrong_selections and answer_index in GameManager.duel_round.selections:
            continue
        var style := answer_buttons[answer_index].get_theme_stylebox("normal").duplicate() as StyleBoxFlat
        style.bg_color.a = 0.0
        style.border_color.a = 0.0
        _set_answer_feedback_style(answer_index, style)

func _clear_answer_feedback() -> void:
    for answer_index in answer_buttons.size():
        var answer_button := answer_buttons[answer_index]
        answer_button.add_theme_stylebox_override("normal", base_answer_normal_styles[answer_index])
        answer_button.add_theme_stylebox_override("hover", base_answer_hover_styles[answer_index])
        answer_button.remove_theme_stylebox_override("pressed")
        answer_button.remove_theme_stylebox_override("disabled")

func _create_feedback_style(background_color: Color, border_color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = background_color
    style.border_width_left = 2
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    style.border_color = border_color
    style.corner_radius_top_left = 4
    style.corner_radius_top_right = 4
    style.corner_radius_bottom_right = 4
    style.corner_radius_bottom_left = 4
    return style

func _create_focus_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0, 0, 0, 0)
    style.border_width_left = 4
    style.border_width_top = 4
    style.border_width_right = 4
    style.border_width_bottom = 4
    style.border_color = Color("d9f3ff")
    style.expand_margin_left = 3
    style.expand_margin_top = 3
    style.expand_margin_right = 3
    style.expand_margin_bottom = 3
    style.corner_radius_top_left = 6
    style.corner_radius_top_right = 6
    style.corner_radius_bottom_right = 6
    style.corner_radius_bottom_left = 6
    return style

func _set_answer_text_color_overrides(answer_button: Button) -> void:
    answer_button.add_theme_color_override("font_color", Color.WHITE)
    answer_button.add_theme_color_override("font_hover_color", Color.WHITE)
    answer_button.add_theme_color_override("font_pressed_color", Color.WHITE)
    answer_button.add_theme_color_override("font_disabled_color", Color.WHITE)

func _create_achievement_toast() -> void:
    _achievement_toast = PanelContainer.new()
    _achievement_toast.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    _achievement_toast.position = Vector2(-346, 20)
    _achievement_toast.size = Vector2(326, 92)
    _achievement_toast.add_theme_stylebox_override("panel", _create_feedback_style(Color("1a243c"), Color("f0d35e")))
    _achievement_toast.hide()
    add_child(_achievement_toast)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)
    _achievement_toast.add_child(row)
    _achievement_toast_artwork = TextureRect.new()
    _achievement_toast_artwork.custom_minimum_size = Vector2(82, 82)
    _achievement_toast_artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _achievement_toast_artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    row.add_child(_achievement_toast_artwork)
    var copy := VBoxContainer.new()
    copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    copy.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_child(copy)
    var heading := Label.new()
    heading.text = "Achievement Unlocked!"
    heading.add_theme_font_size_override("font_size", 17)
    heading.add_theme_color_override("font_color", Color("f0d35e"))
    copy.add_child(heading)
    _achievement_toast_name = Label.new()
    _achievement_toast_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _achievement_toast_name.add_theme_font_size_override("font_size", 20)
    _achievement_toast_name.add_theme_color_override("font_color", Color.WHITE)
    copy.add_child(_achievement_toast_name)

func _queue_achievement_notification(achievement_id: String) -> void:
    AchievementManager.acknowledge_notification(achievement_id)
    _achievement_notification_queue.append(achievement_id)
    _show_next_achievement_notification()

func _show_next_achievement_notification() -> void:
    if _achievement_notification_showing or _achievement_notification_queue.is_empty() or _achievement_toast == null:
        return
    _achievement_notification_showing = true
    var achievement := AchievementManager.get_achievement(_achievement_notification_queue.pop_front())
    _achievement_toast_name.text = str(achievement.name)
    _achievement_toast_artwork.texture = _achievement_texture(str(achievement.artwork))
    _achievement_toast.modulate.a = 0.0
    _achievement_toast.show()
    AudioManager.play_sfx(AudioManager.SFX_UI_CONFIRM)
    var fade_in := create_tween()
    fade_in.tween_property(_achievement_toast, "modulate:a", 1.0, 0.16)
    await get_tree().create_timer(3.0, false).timeout
    var fade_out := create_tween()
    fade_out.tween_property(_achievement_toast, "modulate:a", 0.0, 0.3)
    await fade_out.finished
    _achievement_toast.hide()
    _achievement_notification_showing = false
    _show_next_achievement_notification()

func _achievement_texture(artwork: String) -> Texture2D:
    var frames: SpriteFrames = KITTEN_FRAMES
    if artwork.begins_with("big_cat"):
        frames = BIG_CAT_FRAMES
    elif artwork.begins_with("tiger"):
        frames = TIGER_FRAMES
    elif artwork.begins_with("nerd_cat"):
        frames = NERD_CAT_FRAMES
    var animation := &"happy"
    if artwork.contains("thinking") or artwork.contains("determined") or artwork.contains("calculator") or artwork.ends_with("_idle"):
        animation = &"idle"
    elif artwork.contains("celebrate") or artwork.contains("victory") or artwork.contains("graduate"):
        animation = &"level_up"
    elif artwork.contains("energetic"):
        animation = &"evolution_pose"
    return frames.get_frame_texture(animation, 0)
