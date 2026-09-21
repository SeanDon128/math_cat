class_name MultiDigitMultiplicationGenerator
extends RefCounted

const ChoiceBuilder = preload("res://scripts/generators/question_choice_builder.gd")

func next_question() -> QuestionData:
    var first_factor := randi_range(10, 99)
    var second_factor := randi_range(2, 9)
    var correct_value := first_factor * second_factor
    var question := QuestionData.new()
    question.grade = 4
    question.topic = "multi_digit_multiplication"
    question.question_text = "%d x %d =" % [first_factor, second_factor]
    question.correct_answer = str(correct_value)
    question.choices = ChoiceBuilder.build(correct_value, [
        first_factor * (second_factor - 1),
        first_factor * (second_factor + 1),
        correct_value - 10,
        correct_value + 10
    ])
    return question
