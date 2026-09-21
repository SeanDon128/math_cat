extends SceneTree

const QuestionBankScript = preload("res://autoload/question_bank.gd")

func _init() -> void:
    var question_bank = QuestionBankScript.new()
    var seen_prompts: Array[String] = []
    var seen_sets: Array[String] = []

    for question_index in range(220):
        var question = question_bank.get_question(3)
        assert(question.grade == 3, "Grade 3 must receive Grade 3 questions.")
        assert(question.topic == "multiplication_facts", "Grade 3 must use multiplication prompts.")
        var factors = question.question_text.trim_suffix(" =").split(" × ")
        var first_factor := int(factors[0])
        var second_factor := int(factors[1])
        assert(first_factor >= 0 and first_factor <= 10, "The first factor must be between 0 and 10.")
        assert(second_factor >= 0 and second_factor <= 10, "The second factor must be between 0 and 10.")
        assert(first_factor * second_factor == int(question.correct_answer), "Multiplication answers must be correct.")
        _assert_choices(question, seen_sets)
        if not seen_prompts.has(question.question_text):
            seen_prompts.append(question.question_text)

    assert(seen_prompts.size() == 110, "Grade 3 must use 110 unique multiplication prompts.")
    question_bank.free()
    print("Grade 3 smoke tests passed.")
    quit()

func _assert_choices(question: QuestionData, seen_sets: Array[String]) -> void:
    assert(question.choices.size() == 4, "Each question must have four choices.")
    assert(question.choices.has(question.correct_answer), "Choices must include the correct answer.")

    var unique_choices: Array[String] = []
    for choice in question.choices:
        if not unique_choices.has(choice):
            unique_choices.append(choice)
    assert(unique_choices.size() == 4, "Choices must be unique.")

    var set_key := "%s|%s" % [question.question_text, ",".join(question.choices)]
    assert(not seen_sets.has(set_key), "Question-and-choice sets must not repeat before the deck is exhausted.")
    seen_sets.append(set_key)

    for choice in question.choices:
        var choice_value := int(choice)
        assert(choice_value >= 0, "Grade 3 choices must not be negative.")
