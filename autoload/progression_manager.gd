extends Node

signal answer_registered(is_correct: bool, correct_count: int, incorrect_count: int)
signal promoted(old_grade: int, new_grade: int)
signal demoted(old_grade: int, new_grade: int)

const MIN_GRADE := 1
const MAX_GRADE := 13
const PROMOTE_THRESHOLD := 5
const DEMOTE_THRESHOLD := 3

var current_grade := MIN_GRADE
var correct_count := 0
var incorrect_count := 0
var grade_floor := MIN_GRADE

func reset() -> void:
    grade_floor = MIN_GRADE
    current_grade = MIN_GRADE
    correct_count = 0
    incorrect_count = 0

func register_answer(is_correct: bool) -> void:
    if is_correct:
        correct_count += 1
    else:
        incorrect_count += 1

    answer_registered.emit(is_correct, correct_count, incorrect_count)

    if correct_count >= PROMOTE_THRESHOLD:
        _promote()
    elif incorrect_count >= DEMOTE_THRESHOLD:
        _demote()

func _promote() -> void:
    var old_grade := current_grade
    current_grade = min(current_grade + 1, MAX_GRADE)
    _reset_grade_counters()
    promoted.emit(old_grade, current_grade)

func _demote() -> void:
    var old_grade := current_grade
    current_grade = max(current_grade - 1, grade_floor)
    _reset_grade_counters()
    demoted.emit(old_grade, current_grade)

func _reset_grade_counters() -> void:
    correct_count = 0
    incorrect_count = 0
