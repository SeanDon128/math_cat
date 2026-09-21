extends Node

const DuelRound = preload("res://scripts/blitz/blitz_duel_round.gd")
const DuelInput = preload("res://scripts/blitz/blitz_duel_input.gd")
const BlitzStore = preload("res://scripts/blitz/blitz_leaderboard_store.gd")
const AdventureCatalog = preload("res://scripts/adventure/adventure_catalog.gd")

signal state_changed(old_state: int, new_state: int)
signal session_started()
signal timer_tick(seconds_left: int)
signal lives_changed(new_lives: int)
signal score_changed(new_score: int)
signal answer_registered(is_correct: bool)
signal answer_evaluated(is_correct: bool, grade: int, uses_pi: bool)
signal time_bonus_awarded(completed_grade: int, bonus_seconds: int)
signal session_ended(final_score: int, final_grade: int, reason: String)
signal new_high_score(score: int)
signal duel_answered(player: int, is_correct: bool, question_closed: bool)
signal adventure_question_resolved(is_correct: bool, timed_out: bool)
signal adventure_timer_changed(seconds_left: float)
signal adventure_finished(success: bool)

enum GameState { TITLE, PLAYING, LEVEL_UP, DEMOTION, PAUSED, GAME_OVER, BLITZ_READY, CAMPAIGN_SELECT, WORLD_MAP, LEVEL_COMPLETE, LEVEL_FAILED, CAMPAIGN_COMPLETE }
enum SessionMode { STANDARD, PRACTICE, BLITZ, ADVENTURE }

const SESSION_TIME_SEC := 120.0
const BLITZ_TIME_MSEC := 120000
const PRACTICE_GRADE_11_12_TIME_SEC := 300.0
const PRACTICE_GRADE_13_TIME_SEC := 1800.0
const START_LIVES := 9
const TIME_BONUS_PER_COMPLETED_GRADE := 10
const VICTORY_REASON := "victory"

var current_state := GameState.TITLE
var session_mode := SessionMode.STANDARD
var practice_grade := ProgressionManager.MIN_GRADE
var practice_lives := ProfileManager.PRACTICE_MIN_LIVES + 2
var time_left := SESSION_TIME_SEC
var lives := START_LIVES
var score := 0
var last_final_score := 0
var last_final_grade := ProgressionManager.MIN_GRADE
var max_grade_achieved := ProgressionManager.MIN_GRADE
var last_end_reason := ""
var best_score := 0
var total_correct_answers := 0
var total_incorrect_answers := 0
var current_correct_streak := 0
var highest_correct_streak := 0
var time_survived_seconds := 0.0
var correct_answers_by_grade: Dictionary = {}
var _last_reported_second := -1
var blitz_grade := ProgressionManager.MIN_GRADE
var session_serial := 0
var _blitz_deadline_msec := -1
var _blitz_result: Dictionary = {}
var _blitz_result_resolved := false
var clock_msec: Callable = Time.get_ticks_msec
var blitz_players := 1
var duel_round: DuelRound
var duel_input := DuelInput.new()
var adventure_campaign := "elementary"
var adventure_config: Dictionary = {}
var adventure_question_id := 0
var adventure_question_open := false
var adventure_reward := 0
var adventure_map_transition: Dictionary = {}
var _adventure_deadline := -1
var _adventure_remaining := 0
var _adventure_started := 0
var _adventure_paused_at := 0

func _ready() -> void:
    Input.joy_connection_changed.connect(func(_device: int, _connected: bool): duel_input.refresh_devices())
    ProgressionManager.promoted.connect(_on_promoted)
    ProgressionManager.demoted.connect(_on_demoted)
    best_score = int(ProfileManager.statistics().records.highest_score)

func _process(delta: float) -> void:
    if is_adventure_mode() and not is_adventure_boss():
        if current_state == GameState.PLAYING:
            time_survived_seconds += delta
            sync_adventure_clock()
        return
    if is_blitz_mode():
        sync_blitz_clock()
        return
    if current_state != GameState.PLAYING:
        return

    time_left = maxf(time_left - delta, 0.0)
    time_survived_seconds += delta
    var seconds_left := ceili(time_left)
    if seconds_left != _last_reported_second:
        _last_reported_second = seconds_left
        timer_tick.emit(seconds_left)

    if is_zero_approx(time_left):
        end_session("time_up")

func start_session() -> void:
    _start_session(SessionMode.STANDARD, ProgressionManager.MIN_GRADE, START_LIVES)

func start_practice_session(grade: int, starting_lives: int = ProfileManager.PRACTICE_MIN_LIVES + 2) -> void:
    practice_lives = clampi(starting_lives, ProfileManager.PRACTICE_MIN_LIVES, ProfileManager.PRACTICE_MAX_LIVES)
    _start_session(SessionMode.PRACTICE, clampi(grade, ProgressionManager.MIN_GRADE, ProgressionManager.MAX_GRADE), practice_lives)

func start_blitz_session(grade: int, players: int = 1) -> void:
    if grade < ProgressionManager.MIN_GRADE or grade > ProgressionManager.MAX_GRADE:
        push_error("Blitz grade must be between 1 and 13.")
        return
    if players != 1 and players != 2:
        push_error("Blitz requires one or two players.")
        return
    blitz_players = players
    blitz_grade = grade
    _start_session(SessionMode.BLITZ, grade, 0)

func restart_current_session() -> void:
    if is_adventure_mode():
        start_adventure_level(adventure_campaign, int(adventure_config.number))
    elif is_blitz_mode():
        start_blitz_session(blitz_grade, blitz_players)
    elif is_practice_mode():
        _start_session(SessionMode.PRACTICE, practice_grade, practice_lives)
    else:
        start_session()

func is_practice_mode() -> bool:
    return session_mode == SessionMode.PRACTICE

func is_standard_mode() -> bool:
    return session_mode == SessionMode.STANDARD

func is_blitz_mode() -> bool:
    return session_mode == SessionMode.BLITZ

func is_two_player_blitz() -> bool:
    return is_blitz_mode() and blitz_players == 2

func is_adventure_mode() -> bool:
    return session_mode == SessionMode.ADVENTURE

func is_adventure_boss() -> bool:
    return is_adventure_mode() and adventure_config.get("level_type", "") == "boss"

func open_adventure(campaign: String = "") -> void:
    var transition := adventure_map_transition if adventure_map_transition.get("campaign", "") == campaign else {}
    abandon_current_session()
    adventure_map_transition = transition
    session_mode = SessionMode.ADVENTURE
    if AdventureCatalog.CAMPAIGNS.has(campaign):
        adventure_campaign = campaign
        set_state(GameState.WORLD_MAP)
    else:
        lives = START_LIVES
        set_state(GameState.CAMPAIGN_SELECT)

func start_adventure_level(campaign: String, number: int) -> bool:
    if not ProfileManager.adventure_level_unlocked(campaign, number):
        return false
    adventure_campaign = campaign
    adventure_config = AdventureCatalog.level(campaign, number)
    _start_session(SessionMode.ADVENTURE, int(adventure_config.grade), START_LIVES)
    return true

func prepare_adventure_question() -> int:
    adventure_question_id += 1
    adventure_question_open = false
    _adventure_deadline = -1
    _adventure_remaining = roundi(float(adventure_config.timer_seconds) * 1000.0)
    adventure_timer_changed.emit(float(_adventure_remaining) / 1000.0)
    return adventure_question_id

func ready_adventure_question(serial: int, question_id: int) -> void:
    if not is_adventure_mode() or serial != session_serial or question_id != adventure_question_id or adventure_question_open or current_state != GameState.PLAYING:
        return
    adventure_question_open = true
    _adventure_started = int(clock_msec.call())
    _adventure_deadline = _adventure_started + _adventure_remaining if adventure_config.timed else -1

func sync_adventure_clock() -> void:
    if is_adventure_boss():
        if current_state == GameState.PLAYING and time_left <= 0.0:
            end_session("time_up")
        return
    if not is_adventure_mode() or current_state != GameState.PLAYING or not adventure_question_open or _adventure_deadline < 0:
        return
    _adventure_remaining = maxi(_adventure_deadline - int(clock_msec.call()), 0)
    adventure_timer_changed.emit(float(_adventure_remaining) / 1000.0)
    if _adventure_remaining == 0:
        _resolve_adventure_answer(false, false, true)

func submit_adventure_answer(is_correct: bool, uses_pi: bool, serial: int, question_id: int) -> bool:
    if not is_adventure_mode() or serial != session_serial or question_id != adventure_question_id:
        return false
    sync_adventure_clock()
    if serial != session_serial or question_id != adventure_question_id or not adventure_question_open or current_state != GameState.PLAYING:
        return false
    AchievementManager.record_question_response(ProgressionManager.current_grade, is_correct, float(int(clock_msec.call()) - _adventure_started) / 1000.0)
    _resolve_adventure_answer(is_correct, uses_pi, false)
    return true

func _resolve_adventure_answer(is_correct: bool, uses_pi: bool, timed_out: bool) -> void:
    adventure_question_open = false
    _adventure_deadline = -1
    var grade := ProgressionManager.current_grade
    _apply_answer_totals(is_correct, grade)
    ProfileManager.record_adventure_answer(adventure_campaign, grade, is_correct, highest_correct_streak, float(int(clock_msec.call()) - _adventure_started) / 1000.0)
    answer_evaluated.emit(is_correct, grade, uses_pi)
    if is_adventure_boss():
        ProgressionManager.register_answer(is_correct)
    if not is_correct:
        lose_life()
    elif not is_adventure_boss() and total_correct_answers >= int(adventure_config.correct_target):
        _finish_adventure(true)
    adventure_question_resolved.emit(is_correct, timed_out)

func _finish_adventure(success: bool, failure_reason: String = "out_of_lives") -> void:
    if current_state in [GameState.LEVEL_COMPLETE, GameState.CAMPAIGN_COMPLETE, GameState.LEVEL_FAILED]:
        return
    adventure_question_open = false
    _adventure_deadline = -1
    last_final_score = score
    last_final_grade = ProgressionManager.current_grade
    last_end_reason = "campaign_complete" if success and is_adventure_boss() else "level_complete" if success else failure_reason
    set_state(GameState.CAMPAIGN_COMPLETE if success and is_adventure_boss() else GameState.LEVEL_COMPLETE if success else GameState.LEVEL_FAILED)
    var previous_unlock := int(ProfileManager.adventure_progress(adventure_campaign).highest_unlocked_level)
    adventure_reward = ProfileManager.complete_adventure_level(adventure_config, score, lives) if success else 0
    adventure_map_transition = {}
    if success:
        var next_unlock := int(ProfileManager.adventure_progress(adventure_campaign).highest_unlocked_level)
        if is_adventure_boss() or next_unlock > previous_unlock:
            adventure_map_transition = {
                "campaign": adventure_campaign,
                "from_level": int(adventure_config.number),
                "to_level": next_unlock,
                "boss": is_adventure_boss(),
            }
    if not success:
        ProfileManager.save()
    adventure_finished.emit(success)

func present_duel_question(question: QuestionData, serial: int) -> int:
    if not is_two_player_blitz() or serial != session_serial or duel_round == null:
        return -1
    return duel_round.present(question)

func ready_duel_question(serial: int, question_id: int) -> void:
    if not is_two_player_blitz() or serial != session_serial or duel_round == null or question_id != duel_round.question_id:
        return
    if current_state == GameState.BLITZ_READY:
        duel_input.refresh_devices()
        if not duel_input.complete():
            return
        arm_blitz_round(serial)
    if current_state == GameState.PLAYING and not duel_round.closed:
        duel_round.ready = true

func submit_duel_answer(player: int, index: int, serial: int, question_id: int) -> void:
    if not is_two_player_blitz() or serial != session_serial or duel_round == null or not can_answer_question():
        return
    var outcome := duel_round.submit(player, index, question_id)
    if outcome.is_empty():
        return
    answer_registered.emit(bool(outcome.correct))
    if serial != session_serial or not is_two_player_blitz():
        return
    duel_answered.emit(player, bool(outcome.correct), bool(outcome.closed))

func arm_blitz_round(serial: int) -> void:
    if not is_blitz_mode() or serial != session_serial or current_state != GameState.BLITZ_READY:
        return
    if is_two_player_blitz() and (duel_round == null or duel_round.closed or not duel_input.complete()):
        return
    _blitz_deadline_msec = int(clock_msec.call()) + BLITZ_TIME_MSEC
    set_state(GameState.PLAYING)

func sync_blitz_clock() -> void:
    if not is_blitz_mode() or _blitz_deadline_msec < 0:
        return
    if current_state != GameState.PLAYING and current_state != GameState.PAUSED:
        return
    var remaining_msec := maxi(_blitz_deadline_msec - int(clock_msec.call()), 0)
    time_left = float(remaining_msec) / 1000.0
    time_survived_seconds = float(BLITZ_TIME_MSEC - remaining_msec) / 1000.0
    var seconds_left := ceili(time_left)
    if seconds_left != _last_reported_second:
        _last_reported_second = seconds_left
        timer_tick.emit(seconds_left)
    if remaining_msec == 0:
        end_session("time_up")

func can_answer_question() -> bool:
    sync_blitz_clock()
    return current_state == GameState.PLAYING

func blitz_result() -> Dictionary:
    return _blitz_result.duplicate(true)

func has_pending_blitz_result() -> bool:
    return not _blitz_result.is_empty() and not _blitz_result_resolved

func submit_blitz_result(initials: String) -> int:
    if not has_pending_blitz_result() or current_state != GameState.GAME_OVER:
        push_warning("There is no pending Blitz result to save.")
        return -1
    if _blitz_result.get("two_player", false) and (int(_blitz_result.winner) < 0 or int(_blitz_result.score) <= 0):
        push_warning("Only a positive-scoring two-player winner can submit a score.")
        return -1
    var store: BlitzStore = BlitzDuelLeaderboard if _blitz_result.get("two_player", false) else BlitzLeaderboard
    var rank := store.submit(int(_blitz_result.grade), int(_blitz_result.score), initials)
    if rank >= 0:
        _blitz_result_resolved = true
    return rank

func skip_blitz_result() -> void:
    _blitz_result_resolved = true

func abandon_current_session() -> void:
    adventure_map_transition = {}
    session_serial += 1
    _blitz_deadline_msec = -1
    _blitz_result.clear()
    _blitz_result_resolved = true
    duel_round = null
    adventure_question_open = false
    _adventure_deadline = -1
    set_state(GameState.TITLE)

func _start_session(mode: SessionMode, starting_grade: int, starting_lives: int) -> void:
    adventure_map_transition = {}
    session_serial += 1
    _blitz_deadline_msec = -1
    _blitz_result.clear()
    _blitz_result_resolved = false
    session_mode = mode
    adventure_question_open = false
    _adventure_deadline = -1
    adventure_reward = 0
    duel_round = DuelRound.new() if is_two_player_blitz() else null
    practice_grade = starting_grade
    score = 0
    time_left = _time_limit_for_session(mode, starting_grade)
    lives = starting_lives
    max_grade_achieved = starting_grade
    total_correct_answers = 0
    total_incorrect_answers = 0
    current_correct_streak = 0
    highest_correct_streak = 0
    time_survived_seconds = 0.0
    correct_answers_by_grade.clear()
    _last_reported_second = -1
    last_end_reason = ""
    ProgressionManager.reset()
    if is_adventure_boss():
        ProgressionManager.grade_floor = int(adventure_config.boss_start_grade)
    if not is_standard_mode():
        ProgressionManager.current_grade = starting_grade
    score_changed.emit(score)
    timer_tick.emit(ceili(time_left))
    lives_changed.emit(lives)
    set_state(GameState.BLITZ_READY if is_blitz_mode() else GameState.PLAYING)
    session_started.emit()

func _time_limit_for_session(mode: SessionMode, grade: int) -> float:
    if mode == SessionMode.BLITZ:
        return float(BLITZ_TIME_MSEC) / 1000.0
    if mode != SessionMode.PRACTICE:
        return SESSION_TIME_SEC
    if grade == 13:
        return PRACTICE_GRADE_13_TIME_SEC
    if grade == 11 or grade == 12:
        return PRACTICE_GRADE_11_12_TIME_SEC
    return SESSION_TIME_SEC

func register_answer(is_correct: bool, uses_pi: bool = false) -> void:
    if is_adventure_mode():
        submit_adventure_answer(is_correct, uses_pi, session_serial, adventure_question_id)
        return
    if is_two_player_blitz():
        push_warning("Two-player Blitz requires a player-aware answer.")
        return
    if not can_answer_question():
        return

    var answer_grade := ProgressionManager.current_grade
    _apply_answer_totals(is_correct, answer_grade)
    if is_standard_mode():
        ProgressionManager.register_answer(is_correct)

    answer_evaluated.emit(is_correct, answer_grade, uses_pi)

    if not is_correct and not is_blitz_mode():
        lose_life()

func _apply_answer_totals(is_correct: bool, answer_grade: int) -> void:
    answer_registered.emit(is_correct)
    if is_correct:
        total_correct_answers += 1
        current_correct_streak += 1
        highest_correct_streak = max(highest_correct_streak, current_correct_streak)
        add_score(1 if is_blitz_mode() else 10 * answer_grade)
        correct_answers_by_grade[answer_grade] = int(correct_answers_by_grade.get(answer_grade, 0)) + 1
    else:
        total_incorrect_answers += 1
        current_correct_streak = 0
        if is_blitz_mode():
            add_score(-1)

func lose_life() -> void:
    if is_blitz_mode():
        return
    lives = max(lives - 1, 0)
    lives_changed.emit(lives)
    if lives == 0:
        if is_adventure_mode():
            _finish_adventure(false)
        else:
            end_session("out_of_lives")

func add_score(points: int) -> void:
    score += points
    score_changed.emit(score)

func set_state(new_state: GameState) -> void:
    if current_state == new_state:
        return

    if is_adventure_mode() and adventure_question_open:
        var now := int(clock_msec.call())
        if new_state == GameState.PAUSED:
            sync_adventure_clock()
            if current_state != GameState.PLAYING:
                return
            _adventure_paused_at = now
            _adventure_deadline = -1
        elif current_state == GameState.PAUSED and new_state == GameState.PLAYING:
            _adventure_started += now - _adventure_paused_at
            _adventure_deadline = now + _adventure_remaining if adventure_config.timed else -1

    var old_state := current_state
    current_state = new_state
    state_changed.emit(old_state, current_state)

func end_session(reason: String) -> void:
    if is_adventure_mode():
        _finish_adventure(false, reason)
        return
    if current_state == GameState.GAME_OVER:
        return
    if is_blitz_mode():
        if reason != "time_up" or _blitz_deadline_msec < 0 or int(clock_msec.call()) < _blitz_deadline_msec:
            push_warning("Blitz results require a completed %d-second round." % (BLITZ_TIME_MSEC / 1000))
            return
        _blitz_result = {
            "grade": blitz_grade, "score": score,
            "correct": total_correct_answers, "incorrect": total_incorrect_answers,
        }
        if is_two_player_blitz():
            duel_round.ready = false
            _blitz_result = duel_round.snapshot(blitz_grade)
            score = int(_blitz_result.score)
        time_left = 0.0
        time_survived_seconds = float(BLITZ_TIME_MSEC) / 1000.0

    last_final_score = score
    last_final_grade = ProgressionManager.current_grade
    last_end_reason = reason
    if is_standard_mode() and score > best_score:
        best_score = score
        new_high_score.emit(score)
    if not is_blitz_mode():
        ProfileManager.record_session(score, max_grade_achieved, total_correct_answers, highest_correct_streak, time_survived_seconds, correct_answers_by_grade, is_practice_mode(), reason)
    set_state(GameState.GAME_OVER)
    session_ended.emit(last_final_score, last_final_grade, last_end_reason)

func goto_scene(scene_path: String) -> void:
    get_tree().change_scene_to_file.bind(scene_path).call_deferred()

func _on_promoted(old_grade: int, new_grade: int) -> void:
    if is_adventure_boss():
        max_grade_achieved = maxi(max_grade_achieved, new_grade)
        add_score(50)
        if new_grade >= int(adventure_config.boss_victory_grade):
            _finish_adventure(true)
            return
        if new_grade > old_grade:
            _award_time_bonus(old_grade)
        set_state(GameState.LEVEL_UP)
        return
    if not is_standard_mode():
        return
    max_grade_achieved = max(max_grade_achieved, new_grade)
    add_score(50)
    if old_grade < ProgressionManager.MAX_GRADE and new_grade == ProgressionManager.MAX_GRADE:
        end_session(VICTORY_REASON)
        return
    if new_grade > old_grade:
        _award_time_bonus(old_grade)
    set_state(GameState.LEVEL_UP)

func _on_demoted(_old_grade: int, _new_grade: int) -> void:
    if is_adventure_boss():
        set_state(GameState.DEMOTION)
        return
    if not is_standard_mode():
        return
    set_state(GameState.DEMOTION)

func _award_time_bonus(completed_grade: int) -> void:
    var bonus_seconds := TIME_BONUS_PER_COMPLETED_GRADE * completed_grade
    time_left += bonus_seconds
    _last_reported_second = ceili(time_left)
    timer_tick.emit(_last_reported_second)
    time_bonus_awarded.emit(completed_grade, bonus_seconds)
