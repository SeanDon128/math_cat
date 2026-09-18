extends Node

const GameScene = preload("res://scenes/game/game.tscn")

func _ready() -> void:
    ProfileManager.set_controller_input_style("direct")
    GameManager.start_session()
    GameManager.best_score = 0

    var game = GameScene.instantiate()
    add_child(game)
    await get_tree().process_frame

    _assert_answer_cluster_fits_viewport(game)
    _assert_answer_cluster_is_in_bottom_half(game)
    await _assert_answer_cluster_positions_fixed(game)
    _assert_question_font_resets(game)
    _assert_keyboard_answer_navigation(game)
    _assert_controller_answer_modes(game)
    _assert_answer_feedback_styles(game)
    _assert_evolution_feedback(game)
    _assert_hud_meters(game)
    await _assert_grade_progress_completion_feedback(game)
    await _assert_level_up_time_bonus(game)

    GameManager.register_answer(true)
    GameManager.register_answer(true)
    GameManager.register_answer(false)
    GameManager.add_score(30)
    GameManager.end_session("time_up")
    _assert_game_over_panel(game, "Reason: TIME UP", 50, false, true)

    var retry_button: Button = game.get_node("GameOverOverlay/Panel/Margin/Layout/RetryButton")
    retry_button.emit_signal("pressed")
    _assert_retry_reset(game)

    GameManager.end_session("out_of_lives")
    assert(not game.game_over_overlay.visible, "Out-of-lives results should wait so the final wrong-answer feedback remains visible.")
    await get_tree().create_timer(game.RESULT_REVEAL_DELAY_SECONDS + 0.1).timeout
    _assert_game_over_panel(game, "Reason: OUT OF LIVES", 0, false, false)

    GameManager.start_practice_session(7, 4)
    GameManager.end_session("out_of_lives")
    await get_tree().create_timer(game.RESULT_REVEAL_DELAY_SECONDS + 0.1).timeout
    retry_button.emit_signal("pressed")
    assert(GameManager.is_practice_mode(), "Retry must preserve Practice Mode after a Practice game over.")
    assert(ProgressionManager.current_grade == 7 and GameManager.lives == 4, "Practice retry must preserve the selected grade and lives.")

    GameManager.start_session()
    GameManager.max_grade_achieved = 9
    GameManager.end_session("time_up")
    _assert_game_over_panel(game, "Reason: TIME UP", 0, false, false)

    GameManager.start_session()
    GameManager.best_score = 1000
    GameManager.max_grade_achieved = 12
    ProgressionManager.current_grade = 12
    ProgressionManager.correct_count = ProgressionManager.PROMOTE_THRESHOLD - 1
    game.math_cat.set_stage(MathCatStages.Stage.TIGER)
    game._load_next_question()
    for frame in 5:
        await get_tree().process_frame
    var final_answer: int = game.current_question.choices.find(game.current_question.correct_answer)
    game._select_answer(final_answer)
    assert(not game.game_over_overlay.visible, "Victory results should wait so the Grade 13 promotion remains visible.")
    assert(game.answer_buttons[final_answer].get_theme_stylebox("disabled") == game.correct_answer_style, "Retro final correct answer stays highlighted during the victory delay.")
    assert(game.feedback_label.text == "VICTORY!" and game.feedback_label.modulate == game.CORRECT_PIP_COLOR, "Retro victory feedback is green.")
    assert(game.math_cat.current_stage == MathCatStages.Stage.NERD_CAT and game.math_cat.animation == MathCat.ANIM_EVOLUTION_POSE and game.math_cat.is_playing(), "Retro's final answer displays the moving Nerd Cat evolution before results.")
    await _capture("retro-final-answer")
    await get_tree().create_timer(0.4).timeout
    assert(not game.game_over_overlay.visible and game.answer_locked, "Retro victory preserves the one-second locked final-answer celebration.")
    await get_tree().create_timer(0.7).timeout
    _assert_game_over_panel(game, "Reason: VICTORY", 170, true, false)
    await _capture("retro-victory")
    _assert_title_screen_action(game)

    print("Game Over UI smoke test passed.")
    get_tree().quit()

func _assert_answer_cluster_fits_viewport(game: Control) -> void:
    var bottom_safe_edge := game.get_viewport_rect().size.y - 24.0
    for answer_button in game.answer_buttons:
        assert(answer_button.get_global_rect().end.y <= bottom_safe_edge, "Answer buttons must leave room below the gameplay controls.")

func _assert_answer_cluster_is_in_bottom_half(game: Control) -> void:
    var midpoint := game.get_viewport_rect().size.y / 2.0
    for answer_button in game.answer_buttons:
        assert(answer_button.get_global_rect().position.y >= midpoint, "Answer buttons must remain in the lower half of the screen.")
    var face_buttons: Control = game.get_node("Answers/XboxFaceButtons")
    assert(face_buttons.global_position.y >= midpoint, "Controller glyphs must remain in the lower half of the screen.")
    var glyph_y: Control = game.get_node("Answers/XboxFaceButtons/Y")
    var glyph_x: Control = game.get_node("Answers/XboxFaceButtons/X")
    var glyph_b: Control = game.get_node("Answers/XboxFaceButtons/B")
    var glyph_a: Control = game.get_node("Answers/XboxFaceButtons/A")
    var yellow_bottom: float = game.answer_buttons[3].get_global_rect().end.y
    var green_top: float = game.answer_buttons[0].global_position.y
    var center_corridor: float = (yellow_bottom + green_top) / 2.0
    var y_center: float = glyph_y.get_global_rect().get_center().y
    var a_center: float = glyph_a.get_global_rect().get_center().y
    assert(glyph_y.get_global_rect().position.y >= yellow_bottom, "Y glyph must not overlap the yellow answer box.")
    assert(glyph_a.get_global_rect().end.y <= green_top, "A glyph must not overlap the green answer box.")
    assert(is_equal_approx(y_center + a_center, center_corridor * 2.0), "Y and A glyphs must remain evenly paired around the center corridor.")
    assert(is_equal_approx(glyph_x.get_global_rect().get_center().y, game.answer_buttons[2].get_global_rect().get_center().y), "X glyph must align vertically with the left answer box.")
    assert(is_equal_approx(glyph_b.get_global_rect().get_center().y, game.answer_buttons[1].get_global_rect().get_center().y), "B glyph must align vertically with the right answer box.")

func _assert_answer_cluster_positions_fixed(game: Control) -> void:
    var controls: Array[Control] = []
    for answer_button in game.answer_buttons:
        controls.append(answer_button)
    controls.append(game.get_node("Answers/XboxFaceButtons") as Control)
    var original_positions: Array[Vector2] = []
    for control in controls:
        original_positions.append(control.global_position)

    var question_panel: Control = game.get_node("Content/Layout/QuestionPanel")
    var original_minimum_size := question_panel.custom_minimum_size
    question_panel.custom_minimum_size.y += 60.0
    await get_tree().process_frame
    for control_index in controls.size():
        assert(controls[control_index].global_position == original_positions[control_index], "Question layout changes must not move answer controls.")
    question_panel.custom_minimum_size = original_minimum_size
    await get_tree().process_frame

func _assert_question_font_resets(game: Control) -> void:
    game.current_question = QuestionData.new()
    game.current_question.grade = 5
    game.current_question.topic = "Decimal Place Value"
    game.question_label.text = "What is the value of the 4 in 4.582?"
    game._fit_question_font()
    assert(game.question_label.get_theme_font_size("font_size") == game.GRADE_FIVE_DECIMAL_QUESTION_FONT_SIZE, "Grade 5 decimal place-value prompts must use the stable smaller question font.")

    game.current_question.topic = "Decimal Comparison"
    game.question_label.text = "Which decimal is greater: 1.20 or 1.21?"
    game._fit_question_font()
    assert(game.question_label.get_theme_font_size("font_size") == game.GRADE_FIVE_DECIMAL_QUESTION_FONT_SIZE, "Grade 5 decimal comparison prompts must use the stable smaller question font.")

    game.current_question.grade = 6
    game.current_question.topic = "Geometry Foundations"
    game.question_label.text = "What is the area of a triangle with base 6 and height 4?"
    game._fit_question_font()
    assert(game.question_label.get_theme_font_size("font_size") == game.GRADE_SIX_EXTENDED_QUESTION_FONT_SIZE, "Grade 6 geometry-foundations prompts must use the compact question font.")

    game.current_question.topic = "Statistics"
    game.question_label.text = "Find the median: 12, 4, 6, 8, 6"
    game._fit_question_font()
    assert(game.question_label.get_theme_font_size("font_size") == game.GRADE_SIX_EXTENDED_QUESTION_FONT_SIZE, "Grade 6 mean, median, and mode prompts must use the compact question font.")

    game.current_question.topic = "Algebraic Expressions"
    game.question_label.text = "If a = 6 and b = 5,\nwhat is 2a + b?"
    game._fit_question_font()
    assert(game.question_label.get_theme_font_size("font_size") == game.GRADE_SIX_EXTENDED_QUESTION_FONT_SIZE, "Grade 6 a-and-b algebra prompts must use the compact question font.")

    game.current_question.grade = 8
    game.current_question.topic = "Graphing and Coordinate Plane"
    game.question_label.text = "Which quadrant contains (3, -4)?"
    game._fit_question_font()
    assert(game.question_label.get_theme_font_size("font_size") == game.GRADE_EIGHT_QUADRANT_QUESTION_FONT_SIZE, "Grade 8 quadrant prompts must use the compact question font.")

    game.current_question.topic = "Scientific Notation"
    game.question_label.text = "Write 2000 in scientific notation."
    game._fit_question_font()
    assert(game.question_label.get_theme_font_size("font_size") == game.GRADE_EIGHT_SCIENTIFIC_NOTATION_QUESTION_FONT_SIZE, "Grade 8 scientific-notation prompts must use the compact question font.")

    game.current_question.grade = 5
    game.current_question.topic = "Multi-Digit Addition"
    game.question_label.text = "12 + 8 ="
    game._fit_question_font()
    assert(game.question_label.get_theme_font_size("font_size") == game.QUESTION_MAX_FONT_SIZE, "Non-decimal-place-value prompts must retain the default question font.")

    game.question_label.text = "Maya has 24 stickers. She gives 7 stickers to each of 3 friends and keeps the rest. How many stickers does Maya keep?"
    game._fit_question_font()
    assert(game.question_label.get_theme_font_size("font_size") < game.QUESTION_MAX_FONT_SIZE, "Long word problems should reduce the question font when needed.")
    game.question_label.text = "12 + 8 ="
    game._fit_question_font()
    assert(game.question_label.get_theme_font_size("font_size") == game.QUESTION_MAX_FONT_SIZE, "Short questions must restore the default question font size.")

func _assert_game_over_panel(game: Control, expected_reason: String, expected_score: int, expected_win: bool, expected_is_high_score: bool) -> void:
    var overlay: Control = game.get_node("GameOverOverlay")
    var title_label: Label = game.get_node("GameOverOverlay/Panel/Margin/Layout/GameOverTitle")
    var reason_label: Label = game.get_node("GameOverOverlay/Panel/Margin/Layout/GameOverReasonLabel")
    var score_label: Label = game.get_node("GameOverOverlay/Panel/Margin/Layout/GameOverScoreLabel")
    var max_grade_label: Label = game.get_node("GameOverOverlay/Panel/Margin/Layout/GameOverMaxGradeLabel")
    var streak_label: Label = game.get_node("GameOverOverlay/Panel/Margin/Layout/GameOverStreakLabel")
    var answers_label: Label = game.get_node("GameOverOverlay/Panel/Margin/Layout/GameOverAnswersLabel")
    var time_survived_label: Label = game.get_node("GameOverOverlay/Panel/Margin/Layout/GameOverTimeSurvivedLabel")
    var evolution_label: Label = game.get_node("GameOverOverlay/Panel/Margin/Layout/GameOverEvolutionLabel")
    var high_score_label: Label = game.get_node("GameOverOverlay/Panel/Margin/Layout/NewHighScoreLabel")
    var retry_button: Button = game.get_node("GameOverOverlay/Panel/Margin/Layout/RetryButton")
    var title_screen_button: Button = game.get_node("GameOverOverlay/Panel/Margin/Layout/TitleScreenButton")

    assert(overlay.visible, "Game Over overlay should be visible after a session ends.")
    assert(not game.has_node("EvolutionBanner"), "Evolution transitions should not display a text banner.")
    assert(reason_label.text == expected_reason, "Game Over should show the end reason.")
    assert(score_label.text == "Final Score: %d" % expected_score, "Game Over should show the final score.")
    assert(max_grade_label.text == "Max Grade Level Achieved: %d" % GameManager.max_grade_achieved, "Game Over should show the highest grade reached during the session.")
    assert(streak_label.text == "Highest Correct Streak: %d" % GameManager.highest_correct_streak, "Game Over should show the highest correct streak.")
    assert(score_label.get_theme_font_size("font_size") > streak_label.get_theme_font_size("font_size"), "Final Score should receive more emphasis than Highest Correct Streak.")
    assert(score_label.get_theme_color("font_color") == Color(1, 0.929412, 0.607843, 1), "Final Score should use the highlighted result color.")
    assert(streak_label.get_theme_color("font_color") == Color(0.921569, 0.941176, 0.968627, 1), "Highest Correct Streak should use the supporting-stat color.")
    var total_answers := GameManager.total_correct_answers + GameManager.total_incorrect_answers
    var accuracy := 0 if total_answers == 0 else roundi(100.0 * GameManager.total_correct_answers / total_answers)
    assert(answers_label.text == "Correct Answers: %d / %d (%d%%)" % [GameManager.total_correct_answers, total_answers, accuracy], "Game Over should consolidate answer counts and accuracy.")
    var time_survived := floori(GameManager.time_survived_seconds)
    assert(time_survived_label.text == "Time Survived: %02d:%02d" % [time_survived / 60, time_survived % 60], "Game Over should show active-play time survived.")
    var stage := MathCatStages.stage_for_grade(GameManager.max_grade_achieved)
    assert(evolution_label.text == "Evolution Stage: %s" % MathCatStages.stage_name(stage), "Game Over should show the highest evolution stage reached.")
    assert(title_label.text == ("VICTORY!" if expected_win else "GAME OVER"), "Game Over title should reflect the session end reason.")
    assert(title_label.get_theme_color("font_color") == (Color("79d26a") if expected_win else Color("f0d35e")), "Game Over title color should reflect the session end reason.")
    assert(retry_button.text == "RETRY", "Retry should not display an input hint.")
    assert(title_screen_button.text == "TITLE SCREEN", "Game Over should offer a Title Screen button.")
    assert(high_score_label.visible == expected_is_high_score, "The New High Score banner should only show for a new best score.")
    var expected_animation := "evolution_pose" if expected_win else "high_score" if expected_is_high_score else "game_over"
    assert(String(game.math_cat.animation) == expected_animation, "Math Cat should hold the Nerd Cat evolution pose on victory and celebrate new best scores instead of the normal game-over pose.")
    if expected_win:
        assert(not game.math_cat.is_playing(), "Professor Whiskers should hold a still evolution pose on victory.")

func _assert_retry_reset(game: Control) -> void:
    var overlay: Control = game.get_node("GameOverOverlay")
    var high_score_label: Label = game.get_node("GameOverOverlay/Panel/Margin/Layout/NewHighScoreLabel")

    assert(not overlay.visible, "Retry should hide the Game Over overlay.")
    assert(not high_score_label.visible, "Retry should hide the New High Score banner.")
    assert(GameManager.current_state == GameManager.GameState.PLAYING, "Retry should begin a new playable session.")
    assert(GameManager.lives == GameManager.START_LIVES, "Retry should restore all lives.")
    assert(GameManager.score == 0, "Retry should reset the score.")
    assert(GameManager.highest_correct_streak == 0 and GameManager.total_correct_answers == 0 and GameManager.total_incorrect_answers == 0, "Retry should reset session answer statistics.")
    assert(ceili(GameManager.time_left) == ceili(GameManager.SESSION_TIME_SEC), "Retry should reset the session timer.")

func _assert_title_screen_action(game: Control) -> void:
    var title_screen_button: Button = game.get_node("GameOverOverlay/Panel/Margin/Layout/TitleScreenButton")
    title_screen_button.emit_signal("pressed")
    assert(GameManager.current_state == GameManager.GameState.TITLE, "Title Screen should return to the TITLE state.")

func _assert_keyboard_answer_navigation(game: Control) -> void:
    var expected_indices := {KEY_UP: 3, KEY_DOWN: 0, KEY_LEFT: 2, KEY_RIGHT: 1}
    for keycode in expected_indices:
        var event := InputEventKey.new()
        event.keycode = keycode
        event.pressed = true
        game._handle_gameplay_keyboard_navigation(event)
        assert(game.selected_answer_index == expected_indices[keycode], "Arrow keys should highlight their spatial answer button.")

func _assert_controller_answer_modes(game: Control) -> void:
    var prompts := [
        game.get_node("Answers/XboxFaceButtons/A/Label") as Label,
        game.get_node("Answers/XboxFaceButtons/B/Label") as Label,
        game.get_node("Answers/XboxFaceButtons/X/Label") as Label,
        game.get_node("Answers/XboxFaceButtons/Y/Label") as Label,
    ]

    ProfileManager.set_controller_input_style("direct")
    game._keyboard_answer_navigation_active = false
    game._configure_answer_input_mode()
    for answer_button in game.answer_buttons:
        assert(answer_button.focus_mode == Control.FOCUS_NONE, "Direct Button Mode must begin without an answer highlight focus.")
    assert([prompts[0].text, prompts[1].text, prompts[2].text, prompts[3].text] == ["A", "B", "X", "Y"], "Direct Button Mode must retain face-button labels.")

    ProfileManager.set_controller_input_style("navigation")
    game._configure_answer_input_mode()
    game._focus_answer(2)
    assert(game.answer_buttons[2].has_focus(), "Navigation Mode must keep the highlighted answer focused.")
    assert([prompts[0].text, prompts[1].text, prompts[2].text, prompts[3].text] == ["", "", "A", ""], "Navigation Mode must show A only on the highlighted answer prompt.")
    var stick_event := InputEventJoypadMotion.new()
    stick_event.axis = JOY_AXIS_LEFT_Y
    stick_event.axis_value = 1.0
    game._answer_navigation_ready_at = 0
    assert(game._handle_navigation_mode_controller_input(stick_event), "Navigation Mode must accept left-stick movement.")
    assert(game.selected_answer_index == 0, "Downward left-stick input must select the lower green answer.")
    assert(not game._handle_navigation_mode_controller_input(stick_event), "Repeated left-stick movement must respect the answer navigation debounce.")
    ProfileManager.set_controller_input_style("direct")
    game._load_next_question()
    for answer_button in game.answer_buttons:
        assert(answer_button.focus_mode == Control.FOCUS_NONE, "A new Direct Button Mode question must clear answer focus.")

func _assert_answer_feedback_styles(game: Control) -> void:
    var answer_button: Button = game.get_node("Answers/Answer1")
    var correct_answer_button: Button = game.get_node("Answers/Answer2")
    var feedback_label: Label = game.get_node("Content/Layout/FeedbackLabel")

    game._set_selected_answer_feedback(0, true)
    assert(answer_button.get_theme_stylebox("disabled") == game.correct_answer_style, "Correct selections should use the green answer style.")
    game._set_selected_answer_feedback(0, false)
    assert(answer_button.get_theme_stylebox("disabled") == game.incorrect_answer_style, "Incorrect selections should use the red answer style.")
    var answer_choices: Array[String] = ["1", "2", "3", "4"]
    game.current_question.choices = answer_choices
    game.current_question.correct_answer = "2"
    game._reveal_correct_answer()
    assert(correct_answer_button.get_theme_stylebox("disabled") == game.revealed_answer_style, "An incorrect selection should reveal the correct answer with the gray style.")
    game._set_selected_answer_feedback(0, true, true)
    assert(answer_button.get_theme_stylebox("disabled") == game.promotion_answer_style, "Promotion-triggering correct selections should use the blue answer style.")
    assert(answer_button.get_theme_color("font_color") == Color.WHITE, "Answer button text should be white.")
    assert(answer_button.get_theme_color("font_disabled_color") == Color.WHITE, "Disabled answer button text should remain white.")

    game._clear_answer_feedback()
    game._show_grade_change(1, 2, true)
    assert(feedback_label.text == "Level Up! Grade 2", "Retro Level Up text should capitalize Up.")
    assert(feedback_label.modulate == game.CORRECT_PIP_COLOR, "Promotions should use green feedback text.")

func _assert_evolution_feedback(game: Control) -> void:
    var feedback_label: Label = game.get_node("Content/Layout/FeedbackLabel")

    game._show_grade_change(4, 5, true)
    assert(feedback_label.text == "Kitten has evolved to Math Cat!", "Grade 5 should announce the Math Cat evolution.")
    game._show_grade_change(5, 6, true)
    assert(feedback_label.text == "A Wild Grade 6 Appears!", "Grade 6 should use its custom promotion message.")
    game._show_grade_change(6, 7, true)
    assert(feedback_label.text == "Grade 7 – Algebra!", "Grade 7 should use its custom promotion message.")
    game._show_grade_change(7, 8, true)
    assert(feedback_label.text == "Grade 8 – More Algebra!", "Grade 8 should use its custom promotion message.")
    game._show_grade_change(8, 9, true)
    assert(feedback_label.text == "Math Cat goes to High School", "Grade 9 should use its custom promotion message.")
    game._show_grade_change(9, 10, true)
    assert(feedback_label.text == "The Pi is a Lie", "Grade 10 should use its custom promotion message.")
    game._show_grade_change(10, 11, true)
    assert(feedback_label.text == "SAT Prep Time", "Grade 11 should use its custom promotion message.")
    game._show_grade_change(11, 12, true)
    assert(feedback_label.text == "Last Level! Let's Go!", "Grade 12 should use its custom promotion message.")
    assert(feedback_label.modulate == Color("79d26a"), "Grade 12 promotion feedback should be green.")
    game._show_grade_change(12, 13, true)
    assert(feedback_label.text == "VICTORY!", "Grade 13 should use its custom victory message.")
    assert(feedback_label.modulate == Color("79d26a"), "Grade 13 victory feedback should be green.")
    for grade in range(2, 14):
        game._show_grade_change(grade - 1, grade, true)
        assert(feedback_label.modulate == game.CORRECT_PIP_COLOR, "All Retro promotion and evolution text should use green.")

func _capture(label: String) -> void:
    if "--capture" not in OS.get_cmdline_user_args():
        return
    await get_tree().process_frame
    await RenderingServer.frame_post_draw
    var path := "user://%s.png" % label
    assert(get_viewport().get_texture().get_image().save_png(path) == OK, "Capture " + label)
    print("CAPTURE " + ProjectSettings.globalize_path(path))

func _assert_hud_meters(game: Control) -> void:
    var heart_container: HBoxContainer = game.get_node("Content/Layout/HeaderBar/Margin/Header/HeartContainer") as HBoxContainer
    var lives_label: Label = game.get_node("Content/Layout/HeaderBar/Margin/Header/LivesLabel") as Label
    var grade_label: Label = game.get_node("Content/Layout/HeaderBar/Margin/Header/GradeProgressPanel/GradeLabel") as Label
    var score_label: Label = game.get_node("Content/Layout/HeaderBar/Margin/Header/ScoreTimePanel/ScoreLabel") as Label
    var timer_label: Label = game.get_node("Content/Layout/HeaderBar/Margin/Header/ScoreTimePanel/TimerLabel") as Label
    assert(heart_container.get_child_count() == GameManager.START_LIVES, "The header must show one heart container for each starting life.")
    assert(lives_label.text == "LIVES", "The heart containers must have a Lives label.")
    assert(score_label.get_theme_font_size("font_size") == grade_label.get_theme_font_size("font_size"), "Score font size must match Grade.")
    assert(timer_label.get_theme_font_size("font_size") == grade_label.get_theme_font_size("font_size"), "Time font size must match Grade.")
    assert(lives_label.get_theme_font_size("font_size") == grade_label.get_theme_font_size("font_size"), "Lives font size must match Grade.")
    assert(score_label.position.y == grade_label.position.y - 54.0 and timer_label.position.y == grade_label.position.y - 54.0, "Score and Time must retain their scaled header alignment above Grade.")
    assert(lives_label.position.y == grade_label.position.y - 8.0, "Lives text must sit above the heart containers.")
    assert(heart_container.position.y == grade_label.position.y + 46.0, "Heart containers must sit beneath the Lives label with clear spacing.")
    _assert_filled_meter_count(heart_container, GameManager.START_LIVES, "A new session must show every heart filled.")

    game._update_lives(6)
    _assert_filled_meter_count(heart_container, 6, "Lost lives must display as empty heart containers.")

    var correct_pips: HBoxContainer = game.get_node("Content/Layout/HeaderBar/Margin/Header/GradeProgressPanel/CorrectProgress") as HBoxContainer
    var incorrect_pips: HBoxContainer = game.get_node("Content/Layout/HeaderBar/Margin/Header/GradeProgressPanel/IncorrectProgress") as HBoxContainer
    game._update_progress(true, 3, 1)
    _assert_filled_meter_count(correct_pips, 3, "Correct progress must fill one of five pips per correct answer.", 1)
    _assert_filled_meter_count(incorrect_pips, 1, "Incorrect progress must fill one of three pips per incorrect answer.", 1)

    var timer_position := timer_label.position
    game._update_score(100000)
    assert(timer_label.position == timer_position, "Time KPI position must remain fixed when the score changes.")

func _assert_filled_meter_count(container: HBoxContainer, expected_filled: int, message: String, first_meter_index: int = 0) -> void:
    var filled_count := 0
    for child_index in range(first_meter_index, container.get_child_count()):
        var meter: Control = container.get_child(child_index) as Control
        if meter.get("filled"):
            filled_count += 1
    assert(filled_count == expected_filled, message)

func _assert_grade_progress_completion_feedback(game: Control) -> void:
    var correct_pips: HBoxContainer = game.get_node("Content/Layout/HeaderBar/Margin/Header/GradeProgressPanel/CorrectProgress") as HBoxContainer
    var incorrect_pips: HBoxContainer = game.get_node("Content/Layout/HeaderBar/Margin/Header/GradeProgressPanel/IncorrectProgress") as HBoxContainer

    for answer_index in ProgressionManager.PROMOTE_THRESHOLD:
        GameManager.register_answer(true)
    assert(GameManager.current_state == GameManager.GameState.LEVEL_UP, "Promotion must enter the level-up state.")
    _assert_filled_meter_count(correct_pips, ProgressionManager.PROMOTE_THRESHOLD, "Promotion pips must remain filled during grade feedback.", 1)
    await get_tree().create_timer(0.7).timeout
    _assert_filled_meter_count(correct_pips, ProgressionManager.PROMOTE_THRESHOLD, "Promotion pips must remain filled after flashing.", 1)
    game._load_next_question()
    _assert_filled_meter_count(correct_pips, 0, "Promotion pips must clear when the next question appears.", 1)

    GameManager.start_session()
    for answer_index in ProgressionManager.DEMOTE_THRESHOLD:
        GameManager.register_answer(false)
    assert(GameManager.current_state == GameManager.GameState.DEMOTION, "Demotion must enter the demotion state.")
    _assert_filled_meter_count(incorrect_pips, ProgressionManager.DEMOTE_THRESHOLD, "Demotion pips must remain filled during grade feedback.", 1)
    await get_tree().create_timer(0.7).timeout
    _assert_filled_meter_count(incorrect_pips, ProgressionManager.DEMOTE_THRESHOLD, "Demotion pips must remain filled after flashing.", 1)
    game._load_next_question()
    _assert_filled_meter_count(incorrect_pips, 0, "Demotion pips must clear when the next question appears.", 1)
    GameManager.start_session()

func _assert_level_up_time_bonus(game: Control) -> void:
    var timer_label: Label = game.get_node("Content/Layout/HeaderBar/Margin/Header/ScoreTimePanel/TimerLabel")
    var time_bonus_label: Label = game.get_node("TimeBonusLabel")
    GameManager.time_left = 60.0
    for answer_index in range(ProgressionManager.PROMOTE_THRESHOLD):
        GameManager.register_answer(true)
    await get_tree().process_frame

    assert(time_bonus_label.visible, "A level-up should show the time-bonus notification.")
    assert(time_bonus_label.text == "+10 Seconds!", "Completing Grade 1 should display a 10-second bonus.")
    assert(timer_label.text == "TIME 01:10", "The timer display should update immediately after the bonus.")
    GameManager.start_session()
