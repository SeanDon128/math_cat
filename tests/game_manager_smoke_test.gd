extends Node

func _ready() -> void:
    _test_new_session()
    _test_practice_session()
    _test_practice_session_time_limits()
    _test_level_up_awards_time_bonus()
    _test_reaching_grade_thirteen_wins_standard_mode()
    _test_practice_grade_thirteen_does_not_win()
    _test_answer_registration_signal()
    _test_practice_statistics_scope()
    _test_session_statistics()
    _test_time_survived_tracking()
    _test_new_high_score_signal()
    _test_lives_end_the_session()
    _test_timer_ends_the_session()
    print("GameManager smoke tests passed.")
    get_tree().quit()

func _test_new_session() -> void:
    GameManager.start_session()

    assert(GameManager.current_state == GameManager.GameState.PLAYING, "A new session should begin in PLAYING state.")
    assert(GameManager.lives == GameManager.START_LIVES, "A new session should start with nine lives.")
    assert(ceili(GameManager.time_left) == ceili(GameManager.SESSION_TIME_SEC), "A new session should start with two minutes.")
    assert(GameManager.score == 0, "A new session should start at zero score.")
    assert(GameManager.max_grade_achieved == ProgressionManager.MIN_GRADE, "A new session should reset the maximum grade achieved.")
    assert(GameManager.current_correct_streak == 0 and GameManager.highest_correct_streak == 0, "A new session should reset correct streak statistics.")
    assert(GameManager.total_correct_answers == 0 and GameManager.total_incorrect_answers == 0, "A new session should reset answer totals.")

func _test_practice_session() -> void:
    GameManager.start_practice_session(6, 4)
    for answer_index in range(ProgressionManager.PROMOTE_THRESHOLD):
        GameManager.register_answer(true)

    assert(GameManager.is_practice_mode(), "Practice sessions must report practice mode.")
    assert(ProgressionManager.current_grade == 6, "Practice sessions must keep the selected grade fixed.")
    assert(GameManager.lives == 4 and GameManager.practice_lives == 4, "Practice sessions must use the selected practice lives value.")
    assert(GameManager.current_state == GameManager.GameState.PLAYING, "Practice answers must not trigger a promotion state.")
    assert(GameManager.max_grade_achieved == 6, "Practice sessions must not advance the maximum grade.")
    GameManager.add_score(40)
    GameManager.time_left = 15.0
    GameManager.restart_current_session()
    assert(GameManager.is_practice_mode(), "Restart must preserve Practice Mode.")
    assert(ProgressionManager.current_grade == 6 and GameManager.lives == 4, "Practice restart must preserve selected grade and lives.")
    assert(GameManager.score == 0 and is_equal_approx(GameManager.time_left, GameManager.SESSION_TIME_SEC), "Practice restart must reset score and timer.")

func _test_practice_session_time_limits() -> void:
    GameManager.start_practice_session(10, 4)
    assert(is_equal_approx(GameManager.time_left, GameManager.SESSION_TIME_SEC), "Practice grades other than 11 through 13 should use two minutes.")

    GameManager.start_practice_session(11, 4)
    assert(is_equal_approx(GameManager.time_left, GameManager.PRACTICE_GRADE_11_12_TIME_SEC), "Grade 11 Practice should use five minutes.")

    GameManager.start_practice_session(12, 4)
    assert(is_equal_approx(GameManager.time_left, GameManager.PRACTICE_GRADE_11_12_TIME_SEC), "Grade 12 Practice should use five minutes.")

    GameManager.start_practice_session(13, 4)
    assert(is_equal_approx(GameManager.time_left, GameManager.PRACTICE_GRADE_13_TIME_SEC), "Grade 13 Practice should use thirty minutes.")
    GameManager.time_left = 15.0
    GameManager.restart_current_session()
    assert(is_equal_approx(GameManager.time_left, GameManager.PRACTICE_GRADE_13_TIME_SEC), "Practice restart should preserve the selected grade time limit.")

    GameManager.start_session()
    assert(is_equal_approx(GameManager.time_left, GameManager.SESSION_TIME_SEC), "Standard sessions should keep the two-minute limit.")

func _test_level_up_awards_time_bonus() -> void:
    GameManager.start_session()
    GameManager.time_left = 75.0
    for answer_index in range(ProgressionManager.PROMOTE_THRESHOLD):
        GameManager.register_answer(true)

    assert(ProgressionManager.current_grade == 2, "Five correct Grade 1 answers should promote to Grade 2.")
    assert(is_equal_approx(GameManager.time_left, 85.0), "Completing Grade 1 should immediately award 10 seconds.")
    assert(GameManager.current_state == GameManager.GameState.LEVEL_UP, "A promotion should enter the level-up state.")

func _test_reaching_grade_thirteen_wins_standard_mode() -> void:
    GameManager.start_session()
    ProgressionManager.current_grade = 12
    GameManager.time_left = 10.0
    for answer_index in range(ProgressionManager.PROMOTE_THRESHOLD):
        GameManager.register_answer(true)

    assert(ProgressionManager.current_grade == 13, "Five correct Grade 12 answers should promote to Grade 13.")
    assert(GameManager.max_grade_achieved == 13, "Promotions should update the session's maximum grade achieved.")
    assert(GameManager.current_state == GameManager.GameState.GAME_OVER, "Reaching Grade 13 in Standard Mode should end the session.")
    assert(GameManager.last_end_reason == GameManager.VICTORY_REASON, "Reaching Grade 13 in Standard Mode should record victory.")

func _test_practice_grade_thirteen_does_not_win() -> void:
    GameManager.start_practice_session(13, 4)

    for answer_index in range(ProgressionManager.PROMOTE_THRESHOLD):
        GameManager.register_answer(true)

    assert(GameManager.current_state == GameManager.GameState.PLAYING, "Practice Mode at Grade 13 must not trigger a victory session end.")

func _test_answer_registration_signal() -> void:
    var answers: Array[bool] = []
    var sfx_names: Array[String] = []
    var callback := func(is_correct: bool): answers.append(is_correct)
    var sfx_callback := func(sfx_name: String): sfx_names.append(sfx_name)
    GameManager.answer_registered.connect(callback)
    AudioManager.sfx_played.connect(sfx_callback)

    GameManager.start_practice_session(6, 4)
    GameManager.register_answer(true)
    GameManager.register_answer(false)

    assert(answers == [true, false], "Practice Mode answers must emit GameManager answer signals for audio feedback.")
    assert(sfx_names == [AudioManager.SFX_CORRECT_ANSWER, AudioManager.SFX_INCORRECT_ANSWER], "Practice Mode answers must trigger the matching sound effects.")
    GameManager.answer_registered.disconnect(callback)
    AudioManager.sfx_played.disconnect(sfx_callback)

func _test_practice_statistics_scope() -> void:
    var original_profile: Dictionary = ProfileManager.statistics()
    ProfileManager.reset_statistics()

    GameManager.start_practice_session(6, 4)
    GameManager.register_answer(true)
    GameManager.time_survived_seconds = 12.5
    GameManager.end_session("time_up")

    var profile := ProfileManager.statistics()
    assert(profile.lifetime.correct_by_grade[5] == 1, "Practice correct answers must contribute to the Grade 6 lifetime total.")
    assert(profile.lifetime.time_played_seconds == 13, "Practice time must contribute to lifetime time played.")
    assert(profile.lifetime.games_played == 0 and profile.lifetime.victories == 0, "Practice sessions must not contribute games played or victories.")
    assert(profile.records.highest_score == 0 and profile.records.highest_grade == 1 and profile.records.most_correct_in_run == 0 and profile.records.best_correct_streak == 0, "Practice sessions must not affect standard-game records.")
    ProfileManager.data = original_profile
    ProfileManager.save()

func _test_session_statistics() -> void:
    GameManager.start_session()
    for answer_index in 3:
        GameManager.register_answer(true)
    GameManager.register_answer(false)
    for answer_index in 2:
        GameManager.register_answer(true)

    assert(GameManager.total_correct_answers == 5, "Every correct answer should increment the session total.")
    assert(GameManager.total_incorrect_answers == 1, "Every incorrect answer should increment the session total.")
    assert(GameManager.current_correct_streak == 2, "An incorrect answer should reset the current correct streak.")
    assert(GameManager.highest_correct_streak == 3, "The highest correct streak should persist after an incorrect answer and promotion.")

func _test_time_survived_tracking() -> void:
    GameManager.start_session()
    GameManager._process(3.5)

    assert(is_equal_approx(GameManager.time_survived_seconds, 3.5), "Time survived should count active gameplay seconds.")
    assert(is_equal_approx(GameManager.time_left, GameManager.SESSION_TIME_SEC - 3.5), "Time survived should advance with the active session timer.")

func _test_new_high_score_signal() -> void:
    GameManager.best_score = 0
    var captured_scores: Array[int] = []
    var callback := func(score: int): captured_scores.append(score)
    GameManager.new_high_score.connect(callback)

    GameManager.start_session()
    GameManager.add_score(50)
    GameManager.end_session("time_up")
    assert(captured_scores == [50], "Beating the best score should emit new_high_score once with the new score.")
    assert(GameManager.best_score == 50, "best_score should update to the new high score.")

    GameManager.start_session()
    GameManager.add_score(20)
    GameManager.end_session("time_up")
    assert(captured_scores == [50], "A lower-scoring session must not emit another new_high_score.")
    assert(GameManager.best_score == 50, "best_score must not regress for a lower-scoring session.")

    GameManager.new_high_score.disconnect(callback)

func _test_lives_end_the_session() -> void:
    GameManager.start_session()

    for answer_index in range(GameManager.START_LIVES):
        GameManager.register_answer(false)
        if GameManager.current_state == GameManager.GameState.DEMOTION:
            GameManager.set_state(GameManager.GameState.PLAYING)

    assert(GameManager.lives == 0, "Nine incorrect answers should remove all lives.")
    assert(GameManager.current_state == GameManager.GameState.GAME_OVER, "Losing all lives should end the session.")
    assert(GameManager.last_end_reason == "out_of_lives", "The session should record the out-of-lives reason.")

func _test_timer_ends_the_session() -> void:
    GameManager.start_session()
    GameManager.time_left = 0.0
    GameManager._process(0.0)

    assert(GameManager.current_state == GameManager.GameState.GAME_OVER, "Time reaching zero should end the session.")
    assert(GameManager.last_end_reason == "time_up", "The session should record the time-up reason.")
