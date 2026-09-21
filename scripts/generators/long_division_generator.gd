class_name LongDivisionGenerator
extends RefCounted

const MisconceptionChoiceBuilderScript = preload("res://scripts/generators/misconception_choice_builder.gd")

var _unused_problems: Array[Vector3i] = []

func next_question() -> QuestionData:
    if _unused_problems.is_empty():
        _refill_problem_deck()

    var problem: Vector3i = _unused_problems.pop_back()
    var dividend: int = problem.x * problem.y
    var question := QuestionData.new()
    question.grade = 4
    question.topic = "division_within_10"
    question.question_text = "%d ÷ %d =" % [dividend, problem.x]
    question.correct_answer = str(problem.y)
    question.choices = MisconceptionChoiceBuilderScript.build(problem.y, [
        dividend,
        problem.x,
        problem.y + problem.x,
        problem.y - 1,
        problem.y + 1,
        dividend - problem.x
    ], problem.z)
    return question

func _refill_problem_deck() -> void:
    var prompt_index := 0
    for divisor in range(1, 11):
        for quotient in range(10):
            _unused_problems.append(Vector3i(divisor, quotient, prompt_index % 4))
            _unused_problems.append(Vector3i(divisor, quotient, (prompt_index + 2) % 4))
            prompt_index += 1

    _unused_problems.shuffle()
