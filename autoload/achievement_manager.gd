extends Node

signal achievement_unlocked(achievement_id: String)

const MATH_KITTEN := "math_kitten"
const HOT_STREAK := "hot_streak"
const THAT_WAS_FAST := "that_was_fast"
const MATH_CAT := "math_cat"
const PI_DAY := "pi_day"
const MATH_TIGER := "math_tiger"
const VICTORY := "victory"
const PRACTICE_MODE := "practice_mode"
const TRUST_THE_PROCESS := "trust_the_process"
const WILDCAT := "wildcat"
const PERFECT_GAME := "perfect_game"
const MATH_MAJOR := "math_major"

const ACHIEVEMENTS: Array[Dictionary] = [
    {"id": MATH_KITTEN, "name": "Math Kitten", "description": "Level up for the first time.", "order": 1, "artwork": "kitten_happy", "mode": "standard", "hidden": false},
    {"id": HOT_STREAK, "name": "Hot Streak", "description": "Achieve 10 correct answers in a row.", "order": 2, "artwork": "kitten_celebrate", "mode": "all", "hidden": false},
    {"id": THAT_WAS_FAST, "name": "That was fast!", "description": "Correctly answer a Grade 4 problem in under 3 seconds.", "order": 3, "artwork": "kitten_energetic", "mode": "all", "hidden": false},
    {"id": MATH_CAT, "name": "Math Cat", "description": "Reach Grade 5.", "order": 4, "artwork": "big_cat_happy", "mode": "standard", "hidden": false},
    {"id": PI_DAY, "name": "Pi Day", "description": "Correctly answer a problem that contains pi.", "order": 5, "artwork": "tiger_idle", "mode": "all", "hidden": false},
    {"id": MATH_TIGER, "name": "Math Tiger", "description": "Reach Grade 9.", "order": 6, "artwork": "tiger_happy", "mode": "standard", "hidden": false},
    {"id": VICTORY, "name": "Victory!", "description": "Beat the game.", "order": 7, "artwork": "nerd_cat_victory", "mode": "standard", "hidden": false},
    {"id": PRACTICE_MODE, "name": "Practice, we're talking about Practice", "description": "Enter Blitz Mode, not a game, not a game.", "order": 8, "artwork": "kitten_thinking", "mode": "blitz", "hidden": false},
    {"id": TRUST_THE_PROCESS, "name": "Trust the Process", "description": "Get 761 correct answers.", "order": 9, "artwork": "big_cat_determined", "mode": "all", "hidden": false},
    {"id": WILDCAT, "name": "Once a Wildcat, always a Wildcat", "description": "Get 2,016 correct answers.", "order": 10, "artwork": "tiger_celebrate", "mode": "all", "hidden": false},
    {"id": PERFECT_GAME, "name": "Perfect Game", "description": "Beat the game without getting a single question wrong.", "order": 11, "artwork": "nerd_cat_calculator", "mode": "standard", "hidden": false},
    {"id": MATH_MAJOR, "name": "Math Major", "description": "Achieve a 7 correct-answer streak on Grade 13.", "order": 12, "artwork": "nerd_cat_energetic", "mode": "all", "hidden": false},
]

var _grade_thirteen_streak := 0
var _pending_notifications: Array[String] = []

func _ready() -> void:
    GameManager.session_started.connect(_on_session_started)
    GameManager.answer_evaluated.connect(_on_answer_evaluated)
    ProgressionManager.promoted.connect(_on_promoted)
    GameManager.session_ended.connect(_on_session_ended)
    evaluate_lifetime_achievements()

func get_all_achievements() -> Array[Dictionary]:
    var achievements: Array[Dictionary] = []
    for definition in ACHIEVEMENTS:
        var achievement := definition.duplicate(true)
        achievement.unlocked = is_unlocked(str(definition.id))
        achievement.unlocked_at = unlock_timestamp(str(definition.id))
        achievements.append(achievement)
    return achievements

func get_achievement(achievement_id: String) -> Dictionary:
    for definition in get_all_achievements():
        if definition.id == achievement_id:
            return definition
    return {}

func unlocked_count() -> int:
    return unlocked_ids().size()

func is_unlocked(achievement_id: String) -> bool:
    return achievement_data().unlocked.has(achievement_id)

func unlock_timestamp(achievement_id: String) -> String:
    return str(achievement_data().unlocked.get(achievement_id, ""))

func unlock_achievement(achievement_id: String) -> bool:
    if is_unlocked(achievement_id) or not _has_definition(achievement_id):
        return false
    achievement_data().unlocked[achievement_id] = Time.get_datetime_string_from_system()
    ProfileManager.save()
    _pending_notifications.append(achievement_id)
    achievement_unlocked.emit(achievement_id)
    return true

func consume_pending_notifications() -> Array[String]:
    var pending := _pending_notifications.duplicate()
    _pending_notifications.clear()
    return pending

func acknowledge_notification(achievement_id: String) -> void:
    _pending_notifications.erase(achievement_id)

func evaluate_lifetime_achievements(extra_correct_answers: int = 0) -> void:
    if GameManager.is_blitz_mode():
        return
    var total_correct := _lifetime_correct_answers() + extra_correct_answers
    if total_correct >= 761:
        unlock_achievement(TRUST_THE_PROCESS)
    if total_correct >= 2016:
        unlock_achievement(WILDCAT)

func record_question_response(grade: int, is_correct: bool, response_seconds: float) -> void:
    if GameManager.is_blitz_mode():
        return
    if grade == 4 and is_correct and response_seconds < 3.0:
        unlock_achievement(THAT_WAS_FAST)

func reset_achievements_for_debugging() -> void:
    ProfileManager.data.achievements = ProfileManager._default_data().achievements
    _grade_thirteen_streak = 0
    ProfileManager.save()

func _on_session_started() -> void:
    _grade_thirteen_streak = 0
    if GameManager.is_blitz_mode():
        unlock_achievement(PRACTICE_MODE)

func _on_answer_evaluated(is_correct: bool, grade: int, uses_pi: bool) -> void:
    if GameManager.is_blitz_mode():
        return
    if is_correct:
        if GameManager.current_correct_streak >= 10:
            unlock_achievement(HOT_STREAK)
        if uses_pi:
            unlock_achievement(PI_DAY)
        evaluate_lifetime_achievements(0 if GameManager.is_adventure_mode() else GameManager.total_correct_answers)

    if grade != ProgressionManager.MAX_GRADE:
        return
    if is_correct:
        _grade_thirteen_streak += 1
        if _grade_thirteen_streak >= 7:
            unlock_achievement(MATH_MAJOR)
    else:
        _grade_thirteen_streak = 0

func _on_promoted(old_grade: int, new_grade: int) -> void:
    if not GameManager.is_standard_mode():
        return
    if new_grade > old_grade:
        unlock_achievement(MATH_KITTEN)
    if old_grade == 4 and new_grade == 5:
        unlock_achievement(MATH_CAT)
    if old_grade == 8 and new_grade == 9:
        unlock_achievement(MATH_TIGER)

func _on_session_ended(_score: int, _grade: int, reason: String) -> void:
    if not GameManager.is_standard_mode() or reason != GameManager.VICTORY_REASON:
        return
    unlock_achievement(VICTORY)
    if GameManager.total_incorrect_answers == 0:
        unlock_achievement(PERFECT_GAME)

func _lifetime_correct_answers() -> int:
    var total := 0
    for count in ProfileManager.data.lifetime.correct_by_grade:
        total += int(count)
    return total

func _has_definition(achievement_id: String) -> bool:
    for definition in ACHIEVEMENTS:
        if definition.id == achievement_id:
            return true
    return false

func achievement_data() -> Dictionary:
    return ProfileManager.data.achievements

func unlocked_ids() -> Dictionary:
    return achievement_data().unlocked
