extends SceneTree

const ProgressionManagerScript = preload("res://autoload/progression_manager.gd")

func _init() -> void:
    _test_promotion()
    _test_grade_five_promotion()
    _test_max_grade_clamp()
    _test_demotion()
    _test_grade_one_floor()
    _test_independent_counters()
    print("ProgressionManager smoke tests passed.")
    quit()

func _test_promotion() -> void:
    var progression_manager = ProgressionManagerScript.new()
    for answer_index in range(5):
        progression_manager.register_answer(true)

    assert(progression_manager.current_grade == 2, "Five correct answers should promote to Grade 2.")
    assert(progression_manager.correct_count == 0, "Promotion should reset correct answers.")
    assert(progression_manager.incorrect_count == 0, "Promotion should reset incorrect answers.")
    progression_manager.free()

func _test_grade_five_promotion() -> void:
    var progression_manager = ProgressionManagerScript.new()
    progression_manager.current_grade = 4
    for answer_index in range(5):
        progression_manager.register_answer(true)

    assert(progression_manager.current_grade == 5, "Five correct Grade 4 answers should promote to Grade 5.")
    progression_manager.free()

func _test_max_grade_clamp() -> void:
    var progression_manager = ProgressionManagerScript.new()
    progression_manager.current_grade = ProgressionManagerScript.MAX_GRADE
    for answer_index in range(5):
        progression_manager.register_answer(true)

    assert(progression_manager.current_grade == ProgressionManagerScript.MAX_GRADE, "Promotion at MAX_GRADE must clamp instead of exceeding it.")
    progression_manager.free()

func _test_demotion() -> void:
    var progression_manager = ProgressionManagerScript.new()
    progression_manager.current_grade = 2
    for answer_index in range(3):
        progression_manager.register_answer(false)

    assert(progression_manager.current_grade == 1, "Three incorrect answers should demote one grade.")
    assert(progression_manager.correct_count == 0, "Demotion should reset correct answers.")
    assert(progression_manager.incorrect_count == 0, "Demotion should reset incorrect answers.")
    progression_manager.free()

func _test_grade_one_floor() -> void:
    var progression_manager = ProgressionManagerScript.new()
    for answer_index in range(3):
        progression_manager.register_answer(false)

    assert(progression_manager.current_grade == 1, "Grade 1 must remain the lowest grade.")
    progression_manager.free()

func _test_independent_counters() -> void:
    var progression_manager = ProgressionManagerScript.new()
    progression_manager.register_answer(true)
    progression_manager.register_answer(false)

    assert(progression_manager.correct_count == 1, "An incorrect answer must not erase correct answers in the grade.")
    assert(progression_manager.incorrect_count == 1, "A correct answer must not erase incorrect answers in the grade.")
    progression_manager.free()
