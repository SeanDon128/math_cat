extends Node

var now := 1000
var question := QuestionData.new()

func _ready() -> void:
    GameManager.answer_registered.disconnect(AudioManager._on_answer_registered)
    GameManager.session_started.disconnect(AudioManager._on_session_started)
    GameManager.clock_msec = func(): return now
    question.choices.assign(["4", "3", "2", "1"])
    question.correct_answer = "4"
    _test_music_recovery()
    var profile := ProfileManager.statistics()
    var best := GameManager.best_score
    for grade in [1, 7, 13]:
        _start(grade)
        var id := GameManager.duel_round.question_id
        _answer(0, 1)
        assert(GameManager.duel_round.scores == [-1, 0])
        _answer(0, 0)
        assert(GameManager.duel_round.scores == [-1, 0], "Wrong locks only the submitting player.")
        _answer(1, 0)
        assert(GameManager.duel_round.scores == [-1, 1])
        assert(GameManager.duel_round.closed)
        _next()
        GameManager.submit_duel_answer(0, 0, GameManager.session_serial, id)
        assert(GameManager.duel_round.scores == [-1, 1], "Stale question input must not score.")
        _answer(1, 1)
        _answer(0, 1)
        assert(GameManager.duel_round.scores == [-2, 0] and GameManager.duel_round.closed)
        _next()
        _answer(1, 0)
        _answer(0, 0)
        assert(GameManager.duel_round.scores == [-2, 1], "Only the first correct event scores.")
        assert(ProgressionManager.current_grade == grade and ProgressionManager.correct_count == 0)
        now += GameManager.BLITZ_TIME_MSEC
        GameManager.sync_blitz_clock()
        var result := GameManager.blitz_result()
        assert(result.winner == 1 and result.score == 1 and result.players[0].incorrect == 2)
        result.players[1].score = 999
        assert(GameManager.blitz_result().players[1].score == 1)
    _test_deadline_restart_and_draw()
    var expected_profile := profile.duplicate(true)
    assert(AchievementManager.is_unlocked(AchievementManager.PRACTICE_MODE))
    if not expected_profile.achievements.unlocked.has(AchievementManager.PRACTICE_MODE):
        expected_profile.achievements.unlocked[AchievementManager.PRACTICE_MODE] = AchievementManager.unlock_timestamp(AchievementManager.PRACTICE_MODE)
    assert(ProfileManager.statistics() == expected_profile and GameManager.best_score == best, "Duel Blitz may only unlock its entry achievement.")
    ProfileManager.data = profile
    ProfileManager.save()
    GameManager.clock_msec = Time.get_ticks_msec
    print("Blitz duel session smoke tests passed.")
    get_tree().quit()

func _test_music_recovery() -> void:
    AudioManager.stop_music()
    GameManager.session_started.connect(AudioManager._on_session_started)
    GameManager.start_blitz_session(5, 2)
    assert(AudioManager._music_player.playing, "Two-player Blitz must start gameplay music.")
    AudioManager._music_player.stop()
    GameManager.restart_current_session()
    assert(AudioManager._music_player.playing, "Restarting Two-player Blitz must recover interrupted gameplay music.")
    GameManager.session_started.disconnect(AudioManager._on_session_started)
    AudioManager.stop_music()

func _start(grade: int = 1) -> void:
    now = 1000
    GameManager.duel_input.reset()
    GameManager.duel_input.controls = GameManager.DuelInput.Controls.KEYBOARD
    GameManager.start_blitz_session(grade, 2)
    assert(GameManager.current_state == GameManager.GameState.BLITZ_READY)
    var id := GameManager.present_duel_question(question, GameManager.session_serial)
    _answer(0, 0)
    assert(GameManager.duel_round.scores == [0, 0])
    now += 9000
    GameManager.sync_blitz_clock()
    assert(GameManager.time_left == 120, "Duel loading preserves the full two-minute round.")
    GameManager.ready_duel_question(GameManager.session_serial, id)

func _next() -> void:
    var id := GameManager.present_duel_question(question, GameManager.session_serial)
    _answer(0, 0)
    assert(not GameManager.duel_round.ready, "A new question is not immediately answerable.")
    GameManager.ready_duel_question(GameManager.session_serial, id)

func _answer(player: int, index: int) -> void:
    GameManager.submit_duel_answer(player, index, GameManager.session_serial, GameManager.duel_round.question_id)

func _test_deadline_restart_and_draw() -> void:
    _start()
    now += 60000
    GameManager.sync_blitz_clock()
    assert(GameManager.current_state == GameManager.GameState.PLAYING and GameManager.time_left == 60.0, "Duel Blitz continues past one minute.")
    now += 59999
    _answer(0, 0)
    _next()
    now += 1
    _answer(1, 0)
    assert(GameManager.blitz_result().winner == 0)
    assert(GameManager.duel_round.scores == [1, 0])
    var old_serial := GameManager.session_serial
    GameManager.restart_current_session()
    assert(GameManager.is_two_player_blitz() and GameManager.duel_round.scores == [0, 0])
    GameManager.ready_duel_question(old_serial, 1)
    assert(GameManager.current_state == GameManager.GameState.BLITZ_READY)
    _next()
    _answer(0, 0)
    _next()
    _answer(1, 0)
    GameManager.set_state(GameManager.GameState.PAUSED)
    now += GameManager.BLITZ_TIME_MSEC
    GameManager.sync_blitz_clock()
    assert(GameManager.blitz_result().winner == -1)
    assert(GameManager.submit_blitz_result("CAT") == -1, "A positive draw cannot be saved.")
    _start()
    _answer(1, 1)
    now += GameManager.BLITZ_TIME_MSEC
    GameManager.sync_blitz_clock()
    assert(GameManager.blitz_result().winner == 0 and GameManager.blitz_result().score == 0)
    assert(GameManager.submit_blitz_result("CAT") == -1, "A zero-scoring winner cannot save.")
    _start()
    _answer(0, 1)
    _answer(1, 1)
    _next()
    _answer(1, 1)
    now += GameManager.BLITZ_TIME_MSEC
    GameManager.sync_blitz_clock()
    assert(GameManager.blitz_result().winner == 0 and GameManager.blitz_result().score == -1)
    assert(GameManager.submit_blitz_result("CAT") == -1, "A negative winner cannot save.")
    GameManager.abandon_current_session()
    assert(GameManager.blitz_result().is_empty() and GameManager.duel_round == null)
