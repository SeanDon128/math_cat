class_name SubtractionGenerator
extends RefCounted

const MisconceptionChoiceBuilderScript = preload("res://scripts/generators/misconception_choice_builder.gd")

var _unused_problems: Array[Vector3i] = []

func next_question() -> QuestionData:
    if _unused_problems.is_empty():
        _refill_problem_deck()

    var problem: Vector3i = _unused_problems.pop_back()
    var correct_value: int = problem.x - problem.y
    var question := QuestionData.new()
    question.grade = 2
    question.topic = "subtraction_within_20"
    question.question_text = "%d - %d =" % [problem.x, problem.y]
    question.correct_answer = str(correct_value)
    question.choices = MisconceptionChoiceBuilderScript.build(correct_value, [
        problem.x + problem.y,
        abs(problem.y - problem.x),
        problem.x,
        problem.y,
        correct_value - 1,
        correct_value + 1
    ], problem.z)
    return question

func _refill_problem_deck() -> void:
    var prompts: Array[Vector2i] = []

    for minuend in range(1, 10):
        for subtrahend in range(minuend + 1):
            prompts.append(Vector2i(minuend, subtrahend))

    for minuend in range(10, 21):
        for subtrahend in range(minuend + 1):
            if prompts.size() == 100:
                break
            prompts.append(Vector2i(minuend, subtrahend))
        if prompts.size() == 100:
            break

    _append_ranked_variants(prompts)
    _unused_problems.shuffle()

func _append_ranked_variants(prompts: Array[Vector2i]) -> void:
    for prompt_index in prompts.size():
        var prompt: Vector2i = prompts[prompt_index]
        _unused_problems.append(Vector3i(prompt.x, prompt.y, prompt_index % 4))
        _unused_problems.append(Vector3i(prompt.x, prompt.y, (prompt_index + 2) % 4))
