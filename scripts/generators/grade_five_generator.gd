class_name GradeFiveGenerator
extends RefCounted

const QUESTION_BANK_PATH := "res://data/questions/grade_5.json"

var _unused_questions: Array[Dictionary] = []

func next_question() -> QuestionData:
    if _unused_questions.is_empty():
        _refill_question_deck()
    return _to_question_data(_unused_questions.pop_back())

func _refill_question_deck() -> void:
    var file := FileAccess.open(QUESTION_BANK_PATH, FileAccess.READ)
    assert(file != null, "Unable to open Grade 5 question bank.")
    var parsed = JSON.parse_string(file.get_as_text())
    assert(parsed is Array, "Grade 5 question bank must be a JSON array.")
    for record in parsed:
        assert(record is Dictionary, "Each Grade 5 question record must be an object.")
        _unused_questions.append(record)
    assert(_unused_questions.size() == 215, "Grade 5 question bank must contain 215 questions.")
    _unused_questions.shuffle()

func _to_question_data(record: Dictionary) -> QuestionData:
    var question := QuestionData.new()
    question.grade = int(record["grade"])
    question.topic = str(record["topic"])
    question.difficulty = str(record["difficulty"])
    question.uses_pi = bool(record["uses_pi"])
    question.question_text = str(record["question"])
    question.correct_answer = str(record["correctAnswer"])
    for choice in record["choices"]:
        question.choices.append(str(choice))
    return question
