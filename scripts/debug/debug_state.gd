extends RefCounted

const LIMIT := 1000000000
const SESSION_FIELDS := ["score", "lives", "time_left", "max_grade_achieved", "total_correct_answers", "total_incorrect_answers", "current_correct_streak", "highest_correct_streak", "time_survived_seconds"]

static func fail(message: String) -> String:
    push_warning(message)
    return message

static func integer(value: Variant, minimum: int = 0, maximum: int = LIMIT) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and value >= minimum and value <= maximum

static func save_profile(draft: Dictionary) -> String:
    if not OS.is_debug_build():
        return fail("Debug editing is unavailable in release builds.")
    var error := validate_profile(draft)
    if not error.is_empty():
        return fail(error)
    var previous := ProfileManager.data
    ProfileManager.data = draft.duplicate(true)
    if not ProfileManager.save():
        ProfileManager.data = previous
        return fail(ProfileManager.last_save_error)
    GameManager.best_score = int(draft.records.highest_score)
    if previous.achievements != draft.achievements:
        AchievementManager.consume_pending_notifications()
        AchievementManager._grade_thirteen_streak = 0
        var game := GameManager.get_tree().get_first_node_in_group("debug_gameplay")
        if game != null:
            game.debug_clear_achievement_notifications()
    ProfileManager.apply_audio_settings()
    AudioManager.set_music_volume(ProfileManager.music_volume())
    AudioManager.set_sfx_volume(ProfileManager.sfx_volume())
    for key in draft.settings:
        ProfileManager.setting_changed.emit(str(key))
    return ""

static func validate_profile(draft: Dictionary) -> String:
    var defaults := ProfileManager._default_data()
    for section in defaults:
        if not draft.get(section) is Dictionary:
            return "Missing profile section: " + section
        for key in defaults[section]:
            if not draft[section].has(key):
                return "Missing profile field: %s.%s" % [section, key]
    for key in ["master_volume", "music_volume", "sfx_volume"]:
        if not integer(draft.settings[key], 0, 10):
            return "Volumes must be integers from 0 to 10."
    if not integer(draft.settings.practice_lives, 1, 9):
        return "Practice lives must be between 1 and 9."
    if draft.settings.controller_input_style not in ["direct", "navigation"] or not ProfileManager.CAT_COLORS.has(draft.settings.cat_color) or not draft.settings.animated_background is bool:
        return "Invalid controller style, cat color, or background setting."
    for section in ["records", "lifetime"]:
        for key in defaults[section]:
            if key == "correct_by_grade":
                var counts: Variant = draft[section][key]
                if not counts is Array or counts.size() != 13:
                    return "Lifetime answers require all 13 grade totals."
                for count in counts:
                    if not integer(count):
                        return "Grade totals must be nonnegative integers."
            elif not integer(draft[section][key], 1 if key == "highest_grade" else 0, 13 if key == "highest_grade" else LIMIT):
                return "Invalid record or lifetime value: " + key
    if not draft.achievements.unlocked is Dictionary:
        return "Achievement unlocks must be a dictionary."
    for id in draft.achievements.unlocked:
        if AchievementManager.get_achievement(str(id)).is_empty() or not draft.achievements.unlocked[id] is String or str(draft.achievements.unlocked[id]).is_empty():
            return "Invalid achievement ID or timestamp: " + str(id)
    var normalized := ProfileManager.AdventureCatalog.normalize(draft.adventure)
    if normalized != draft.adventure:
        return "Adventure progress must be sequential, with valid results, coins, and unlocks."
    return ""

static func session_snapshot() -> Dictionary:
    var result := {}
    for key in SESSION_FIELDS:
        result[key] = GameManager.get(key)
    result.correct_count = ProgressionManager.correct_count
    result.incorrect_count = ProgressionManager.incorrect_count
    result.correct_by_grade = []
    for grade in range(1, 14):
        result.correct_by_grade.append(int(GameManager.correct_answers_by_grade.get(grade, 0)))
    result.question_seconds = float(GameManager._adventure_remaining) / 1000.0
    if GameManager.is_two_player_blitz() and GameManager.duel_round != null:
        result.players = []
        for player in 2:
            result.players.append({"score": GameManager.duel_round.scores[player], "correct": GameManager.duel_round.correct[player], "incorrect": GameManager.duel_round.incorrect[player]})
    return result

static func apply_session(draft: Dictionary) -> String:
    if not OS.is_debug_build():
        return fail("Debug editing is unavailable in release builds.")
    if GameManager.current_state not in [GameManager.GameState.PLAYING, GameManager.GameState.PAUSED]:
        return fail("Live values can only be applied during a running or paused session.")
    for key in SESSION_FIELDS:
        if key in ["time_left", "time_survived_seconds"]:
            var value: Variant = draft.get(key)
            if not (value is int or value is float) or not is_finite(float(value)) or value < (0.1 if key == "time_left" else 0.0) or value > LIMIT:
                return fail("Invalid session time: " + key)
        else:
            var minimum := -LIMIT if key == "score" and GameManager.is_blitz_mode() else 1 if key == "max_grade_achieved" or (key == "lives" and not GameManager.is_blitz_mode()) else 0
            var maximum := 9 if key == "lives" else 13 if key == "max_grade_achieved" else LIMIT
            if not integer(draft.get(key), minimum, maximum):
                return fail("Invalid session value: " + key)
    if not integer(draft.get("correct_count"), 0, 4) or not integer(draft.get("incorrect_count"), 0, 2):
        return fail("Grade progress must stay below the promotion/demotion thresholds.")
    if not draft.get("correct_by_grade") is Array or draft.correct_by_grade.size() != 13:
        return fail("Session answers require all 13 grade totals.")
    for count in draft.correct_by_grade:
        if not integer(count):
            return fail("Session grade totals must be nonnegative integers.")
    if GameManager.is_adventure_mode():
        var seconds: Variant = draft.get("question_seconds")
        if not (seconds is int or seconds is float) or not is_finite(float(seconds)) or seconds < 0.1 or seconds > LIMIT:
            if not GameManager.is_adventure_boss() and GameManager.adventure_config.timed:
                return fail("Question time must be positive.")
    if GameManager.is_two_player_blitz():
        if GameManager.duel_round == null or not draft.get("players") is Array or draft.players.size() != 2:
            return fail("Two-player session data is missing.")
        for player in draft.players:
            if not player is Dictionary or not integer(player.get("score"), -LIMIT) or not integer(player.get("correct")) or not integer(player.get("incorrect")):
                return fail("Invalid two-player score or answer totals.")
    for key in SESSION_FIELDS:
        GameManager.set(key, draft[key])
    ProgressionManager.correct_count = int(draft.correct_count)
    ProgressionManager.incorrect_count = int(draft.incorrect_count)
    GameManager.correct_answers_by_grade.clear()
    for index in 13:
        GameManager.correct_answers_by_grade[index + 1] = int(draft.correct_by_grade[index])
    if GameManager.is_blitz_mode() and GameManager._blitz_deadline_msec >= 0:
        GameManager._blitz_deadline_msec = int(GameManager.clock_msec.call()) + roundi(GameManager.time_left * 1000.0)
    if GameManager.is_adventure_mode() and not GameManager.is_adventure_boss() and GameManager.adventure_config.timed:
        GameManager._adventure_remaining = roundi(float(draft.question_seconds) * 1000.0)
        if GameManager._adventure_deadline >= 0:
            GameManager._adventure_deadline = int(GameManager.clock_msec.call()) + GameManager._adventure_remaining
        GameManager.adventure_timer_changed.emit(float(draft.question_seconds))
    if GameManager.is_two_player_blitz():
        for player in 2:
            GameManager.duel_round.scores[player] = int(draft.players[player].score)
            GameManager.duel_round.correct[player] = int(draft.players[player].correct)
            GameManager.duel_round.incorrect[player] = int(draft.players[player].incorrect)
    GameManager.score_changed.emit(GameManager.score)
    GameManager.lives_changed.emit(GameManager.lives)
    GameManager.timer_tick.emit(ceili(GameManager.time_left))
    var game := GameManager.get_tree().get_first_node_in_group("debug_gameplay")
    if game != null:
        game.debug_refresh_hud()
    return ""
