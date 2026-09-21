class_name MultiplicationGenerator
extends RefCounted

const MisconceptionChoiceBuilderScript = preload("res://scripts/generators/misconception_choice_builder.gd")

var _unused_problems: Array[Vector4i] = []

func next_question() -> QuestionData:
    if _unused_problems.is_empty():
        _refill_problem_deck()

    var problem: Vector4i = _unused_problems.pop_back()
    var correct_value: int = problem.x * problem.y
    var question := QuestionData.new()
    question.grade = 3
    question.topic = "multiplication_facts"
    question.question_text = "%d × %d =" % [problem.x, problem.y]
    question.correct_answer = str(correct_value)
    question.choices = MisconceptionChoiceBuilderScript.build(correct_value, [
        problem.x + problem.y,
        problem.x,
        problem.y,
        problem.x * (problem.y + 1),
        problem.x * max(problem.y - 1, 0),
        correct_value + 1
    ], problem.z + problem.w)
    return question

func _refill_problem_deck() -> void:
    var zero_problems: Array[Vector2i] = []
    var low_value_problems: Array[Vector2i] = []
    var remaining_problems: Array[Vector2i] = []

    for first_factor in range(10):
        for second_factor in range(11):
            var correct_value := first_factor * second_factor
            var problem := Vector2i(first_factor, second_factor)
            if correct_value == 0:
                zero_problems.append(problem)
            elif correct_value <= 2:
                low_value_problems.append(problem)
            else:
                remaining_problems.append(problem)

    for problem in zero_problems:
        _append_problem(problem, 0, 0)
        _append_problem(problem, 0, 1)

    _append_problem(low_value_problems[0], 0)
    _append_problem(low_value_problems[0], 1)
    _append_problem(low_value_problems[1], 0)
    _append_problem(low_value_problems[1], 1)
    _append_problem(low_value_problems[2], 1)
    _append_problem(low_value_problems[2], 2)

    for problem_index in range(13):
        _append_problem(remaining_problems[problem_index], 0)
        _append_problem(remaining_problems[problem_index], 1)
    for problem_index in range(13, 68):
        _append_problem(remaining_problems[problem_index], 3)
        _append_problem(remaining_problems[problem_index], 2)
    for problem_index in range(68, remaining_problems.size()):
        _append_problem(remaining_problems[problem_index], 1)
        _append_problem(remaining_problems[problem_index], 2)

    _unused_problems.shuffle()

func _append_problem(problem: Vector2i, answer_rank: int, variant: int = 0) -> void:
    _unused_problems.append(Vector4i(problem.x, problem.y, answer_rank, variant))
