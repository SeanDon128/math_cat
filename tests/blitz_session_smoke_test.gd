extends Node

var now_msec := 1000

func _ready() -> void:
    GameManager.answer_registered.disconnect(AudioManager._on_answer_registered)
    GameManager.session_started.disconnect(AudioManager._on_session_started)
    GameManager.clock_msec = func(): return now_msec
    var original_profile := ProfileManager.statistics()
    var original_best := GameManager.best_score
    _test_rules_and_isolation()
    _test_deadline()
    _test_restart_and_abandon()
    var expected_profile := original_profile.duplicate(true)
    assert(AchievementManager.is_unlocked(AchievementManager.PRACTICE_MODE))
    if not expected_profile.achievements.unlocked.has(AchievementManager.PRACTICE_MODE):
        expected_profile.achievements.unlocked[AchievementManager.PRACTICE_MODE] = AchievementManager.unlock_timestamp(AchievementManager.PRACTICE_MODE)
    assert(ProfileManager.statistics() == expected_profile, "Blitz must only unlock its entry achievement, leaving career records, settings, and other achievements unchanged.")
    assert(GameManager.best_score == original_best, "Blitz must not change the Standard best score.")
    ProfileManager.data = original_profile
    ProfileManager.save()
    GameManager.clock_msec = Time.get_ticks_msec
    AudioManager.stop_music()
    print("Blitz session smoke tests passed.")
    get_tree().quit()

func _start(grade: int) -> void:
    now_msec = 1000
    GameManager.start_blitz_session(grade)
    assert(GameManager.current_state == GameManager.GameState.BLITZ_READY)
    GameManager.register_answer(true)
    assert(GameManager.score == 0, "Preparation must reject answers.")
    now_msec += 9000
    GameManager._process(9.0)
    assert(GameManager.time_left == 120.0, "Loading must preserve the full two-minute Blitz round.")
    GameManager.arm_blitz_round(GameManager.session_serial)
    assert(GameManager.current_state == GameManager.GameState.PLAYING)

func _test_rules_and_isolation() -> void:
    for grade in [1, 4, 7, 13]:
        _start(grade)
        GameManager.register_answer(false)
        assert(GameManager.score == -1, "Blitz scores may go negative.")
        for index in 12:
            GameManager.register_answer(true, true)
            AchievementManager.record_question_response(4, true, 0.1)
        for index in 15:
            GameManager.register_answer(false)
        GameManager.lose_life()
        assert(GameManager.score == -4)
        assert(GameManager.total_correct_answers == 12 and GameManager.total_incorrect_answers == 16)
        assert(ProgressionManager.current_grade == grade)
        assert(ProgressionManager.correct_count == 0 and ProgressionManager.incorrect_count == 0)
        assert(GameManager.current_state == GameManager.GameState.PLAYING, "Blitz has no lives limit or Grade 13 victory.")
        assert(GameManager.time_left == 120.0, "Answers must not award or deduct time.")
        now_msec += GameManager.BLITZ_TIME_MSEC
        GameManager._process(0.0)
        assert(GameManager.last_end_reason == "time_up")
        var result := GameManager.blitz_result()
        assert(result.grade == grade and result.score == -4 and result.correct == 12 and result.incorrect == 16)
        result.score = 500
        assert(GameManager.blitz_result().score == -4, "Result readers must not mutate the recorded result.")

func _test_deadline() -> void:
    _start(6)
    var ended: Array[int] = []
    var callback := func(points: int, _grade: int, _reason: String): ended.append(points)
    GameManager.session_ended.connect(callback)
    now_msec += 60000
    GameManager.sync_blitz_clock()
    assert(GameManager.current_state == GameManager.GameState.PLAYING and GameManager.time_left == 60.0, "Blitz must continue beyond the first minute.")
    now_msec += 59999
    GameManager.register_answer(true)
    assert(GameManager.score == 1, "An answer before the deadline must count.")
    assert(is_equal_approx(GameManager.time_left, 0.001))
    now_msec += 1
    GameManager.register_answer(true)
    assert(GameManager.score == 1, "An answer at the deadline must not count, even before the next process tick.")
    assert(ended == [1])
    now_msec += 10000
    GameManager._process(10.0)
    GameManager.end_session("time_up")
    assert(ended == [1], "Completion must fire once.")
    assert(GameManager.time_left == 0.0 and GameManager.time_survived_seconds == 120.0)
    GameManager.session_ended.disconnect(callback)

    _start(13)
    GameManager.set_state(GameManager.GameState.PAUSED)
    now_msec += 25000
    GameManager._process(0.0)
    assert(GameManager.time_left == 95.0, "Menus must not freeze the Blitz clock.")
    GameManager.register_answer(true)
    assert(GameManager.score == 0, "Menu input must not answer questions.")
    now_msec += 100000
    GameManager._process(0.0)
    assert(GameManager.current_state == GameManager.GameState.GAME_OVER)
    assert(GameManager.time_survived_seconds == 120.0, "A late frame must not lengthen the round.")

func _test_restart_and_abandon() -> void:
    _start(9)
    GameManager.register_answer(true)
    var serial := GameManager.session_serial
    GameManager.restart_current_session()
    assert(GameManager.is_blitz_mode() and GameManager.blitz_grade == 9)
    assert(GameManager.score == 0 and GameManager.time_left == 120.0)
    assert(GameManager.blitz_result().is_empty())
    GameManager.arm_blitz_round(serial)
    assert(GameManager.current_state == GameManager.GameState.BLITZ_READY, "Old readiness callbacks must not arm a restarted round.")
    GameManager.arm_blitz_round(GameManager.session_serial)
    now_msec += GameManager.BLITZ_TIME_MSEC
    GameManager.sync_blitz_clock()
    assert(GameManager.has_pending_blitz_result())
    GameManager.skip_blitz_result()
    assert(not GameManager.has_pending_blitz_result())
    GameManager.restart_current_session()
    GameManager.abandon_current_session()
    GameManager.arm_blitz_round(GameManager.session_serial)
    assert(GameManager.current_state == GameManager.GameState.TITLE)
    assert(GameManager.blitz_result().is_empty())
