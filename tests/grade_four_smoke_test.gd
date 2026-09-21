extends SceneTree

const QuestionBankScript = preload("res://autoload/question_bank.gd")

func _init() -> void:
    var question_bank = QuestionBankScript.new()
    var seen_prompts: Array[String] = []
    var seen_sets: Array[String] = []

    for question_index in range(200):
        var question = question_bank.get_question(4)
        assert(question.grade == 4, "Grade 4 must receive Grade 4 questions.")
        assert(question.topic == "division_within_10", "Grade 4 must use division prompts.")
        var operands = question.question_text.trim_suffix(" =").split(" ÷ ")
        var dividend := int(operands[0])
        var divisor := int(operands[1])
        var quotient := int(question.correct_answer)
        assert(divisor >= 1 and divisor <= 10, "Division denominators must be between 1 and 10.")
        assert(quotient >= 0 and quotient <= 10, "Division answers must be between 0 and 10.")
        assert(dividend % divisor == 0, "Grade 4 division must have no remainder.")
        assert(dividend / divisor == quotient, "Division answers must be correct.")
        _assert_choices(question, seen_sets)
        if not seen_prompts.has(question.question_text):
            seen_prompts.append(question.question_text)

    assert(seen_prompts.size() == 100, "Grade 4 must use 100 unique division prompts.")
    question_bank.free()
    print("Grade 4 smoke tests passed.")
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

