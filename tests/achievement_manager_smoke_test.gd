extends Node

func _ready() -> void:
    var original_profile: Dictionary = ProfileManager.statistics()
    AchievementManager.reset_achievements_for_debugging()

    _test_definitions()
    _test_blitz_mode_eligibility()
    _test_streaks_and_pi_day()
    _test_fast_answer_boundary()
    _test_lifetime_thresholds()

    ProfileManager.data = original_profile
    ProfileManager.save()
    print("AchievementManager smoke tests passed.")
    get_tree().quit()

func _test_definitions() -> void:
    var achievements := AchievementManager.get_all_achievements()
    assert(achievements.size() == 12, "All 12 achievement definitions must be present.")
    for index in achievements.size():
        assert(int(achievements[index].order) == index + 1, "Achievement definitions must retain display order.")

func _test_blitz_mode_eligibility() -> void:
    var achievement := AchievementManager.get_achievement(AchievementManager.PRACTICE_MODE)
    assert(achievement.name == "Practice, we're talking about Practice")
    assert(achievement.description == "Enter Blitz Mode, not a game, not a game.")
    assert(achievement.mode == "blitz")
    GameManager.start_session()
    assert(not AchievementManager.is_unlocked(AchievementManager.PRACTICE_MODE), "Retro must not unlock the Blitz-entry achievement.")
    GameManager.start_practice_session(5, 3)
    assert(not AchievementManager.is_unlocked(AchievementManager.PRACTICE_MODE), "Legacy Practice must not unlock the Blitz-entry achievement.")
    ProgressionManager.promoted.emit(4, 5)
    assert(not AchievementManager.is_unlocked(AchievementManager.MATH_CAT), "Practice must not unlock grade-progression achievements.")
    for players in [1, 2]:
        AchievementManager.reset_achievements_for_debugging()
        GameManager.start_blitz_session(5, players)
        assert(AchievementManager.is_unlocked(AchievementManager.PRACTICE_MODE), "Entering either Blitz variant must unlock the achievement.")
        var unlocked_at := AchievementManager.unlock_timestamp(AchievementManager.PRACTICE_MODE)
        AchievementManager.consume_pending_notifications()
        GameManager.start_blitz_session(5, players)
        assert(AchievementManager.unlock_timestamp(AchievementManager.PRACTICE_MODE) == unlocked_at)
        assert(AchievementManager.consume_pending_notifications().is_empty(), "Existing unlocks must not notify again.")

func _test_streaks_and_pi_day() -> void:
    GameManager.start_practice_session(13, 3)
    for answer_index in 10:
        GameManager.register_answer(true, answer_index == 0)
    assert(AchievementManager.is_unlocked(AchievementManager.HOT_STREAK), "Ten consecutive correct answers must unlock Hot Streak.")
    assert(AchievementManager.is_unlocked(AchievementManager.PI_DAY), "A correct tagged pi answer must unlock Pi Day.")
    assert(AchievementManager.is_unlocked(AchievementManager.MATH_MAJOR), "Seven Grade 13 correct answers must unlock Math Major.")

func _test_fast_answer_boundary() -> void:
    AchievementManager.record_question_response(4, true, 3.0)
    assert(not AchievementManager.is_unlocked(AchievementManager.THAT_WAS_FAST), "A response of exactly three seconds must not unlock That was fast!")
    AchievementManager.record_question_response(4, true, 2.99)
    assert(AchievementManager.is_unlocked(AchievementManager.THAT_WAS_FAST), "A correct Grade 4 answer below three seconds must unlock That was fast!")

func _test_lifetime_thresholds() -> void:
    ProfileManager.data.lifetime.correct_by_grade = [761, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    AchievementManager.evaluate_lifetime_achievements()
    assert(AchievementManager.is_unlocked(AchievementManager.TRUST_THE_PROCESS), "761 lifetime correct answers must unlock Trust the Process.")
    assert(not AchievementManager.is_unlocked(AchievementManager.WILDCAT), "761 lifetime correct answers must not unlock Wildcat.")
    ProfileManager.data.lifetime.correct_by_grade[0] = 2016
    AchievementManager.evaluate_lifetime_achievements()
    assert(AchievementManager.is_unlocked(AchievementManager.WILDCAT), "2,016 lifetime correct answers must unlock Wildcat.")