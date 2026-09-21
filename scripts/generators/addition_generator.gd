class_name AdditionGenerator
extends RefCounted

const MisconceptionChoiceBuilderScript = preload("res://scripts/generators/misconception_choice_builder.gd")

const MIN_OPERAND := 1
const MAX_OPERAND := 10
const MIN_CHOICE := 0
const MAX_CHOICE := 26

var _unused_problems: Array[Vector3i] = []

func next_question() -> QuestionData:
    if _unused_problems.is_empty():
        _refill_problem_deck()

    var problem: Vector3i = _unused_problems.pop_back()
    var correct_value: int = problem.x + problem.y
    var question := QuestionData.new()
    question.grade = 1
    question.topic = "addition_within_20"
    question.question_text = "%d + %d =" % [problem.x, problem.y]
    question.correct_answer = str(correct_value)
    question.choices = MisconceptionChoiceBuilderScript.build(correct_value, [
        abs(problem.x - problem.y),
        max(problem.x, problem.y),
        correct_value - 1,
        correct_value + 1,
        problem.x * problem.y,
        correct_value + 2
    ], problem.z)
    return question

func _refill_problem_deck() -> void:
    var problem_index := 0
    for first_addend in range(MIN_OPERAND, MAX_OPERAND + 1):
        for second_addend in range(MIN_OPERAND, MAX_OPERAND + 1):
            _unused_problems.append(Vector3i(first_addend, second_addend, problem_index % 4))
            _unused_problems.append(Vector3i(first_addend, second_addend, (problem_index + 2) % 4))
            problem_index += 1

    _unused_problems.shuffle()

