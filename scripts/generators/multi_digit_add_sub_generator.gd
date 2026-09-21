class_name MultiDigitAddSubGenerator
extends RefCounted

const ChoiceBuilder = preload("res://scripts/generators/question_choice_builder.gd")

func next_question() -> QuestionData:
    var first_number := randi_range(10, 99)
    var second_number := randi_range(10, 99)
    var is_addition := randf() < 0.5
    var correct_value: int
    var operator: String
    var candidates: Array[int]

    if is_addition:
        correct_value = first_number + second_number
        operator = "+"
        candidates = [
            correct_value - 1,
            correct_value + 1,
            correct_value - 10,
            correct_value + 10
        ]
    else:
        var minuend: int = max(first_number, second_number)
        var subtrahend: int = min(first_number, second_number)
        first_number = minuend
        second_number = subtrahend
        correct_value = first_number - second_number
        operator = "-"
        candidates = [
            correct_value - 1,
            correct_value + 1,
            first_number + second_number,
            correct_value + 10
        ]

    var question := QuestionData.new()
    question.grade = 3
    question.topic = "multi_digit_%s" % ("addition" if is_addition else "subtraction")
    question.question_text = "%d %s %d =" % [first_number, operator, second_number]
    question.correct_answer = str(correct_value)
    question.choices = ChoiceBuilder.build(correct_value, candidates)
    return question
