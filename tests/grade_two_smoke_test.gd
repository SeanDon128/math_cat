extends SceneTree

const QuestionBankScript = preload("res://autoload/question_bank.gd")

func _init() -> void:
    var question_bank = QuestionBankScript.new()
    var seen_prompts: Array[String] = []
    var seen_sets: Array[String] = []
    var single_digit_prompt_count := 0

    for question_index in range(200):
        var question = question_bank.get_question(2)
        var operands = question.question_text.trim_suffix(" =").split(" - ")
        var minuend := int(operands[0])
        var subtrahend := int(operands[1])

        assert(question.grade == 2, "Grade 2 must receive Grade 2 questions.")
        assert(question.topic == "subtraction_within_20", "Grade 2 must use subtraction.")
        assert(minuend >= 1 and minuend <= 20, "The minuend must be between 1 and 20.")
        assert(subtrahend >= 0 and subtrahend <= 20, "The subtrahend must be between 0 and 20.")
        assert(minuend >= subtrahend, "Subtraction must stay non-negative.")
        assert(int(question.correct_answer) == minuend - subtrahend, "The subtraction answer must be correct.")
        _assert_choices(question, seen_sets)
        if not seen_prompts.has(question.question_text):
            seen_prompts.append(question.question_text)
            if minuend <= 9 and subtrahend <= 9:
                single_digit_prompt_count += 1

    assert(seen_prompts.size() == 100, "Grade 2 must use 100 unique subtraction prompts.")
    assert(single_digit_prompt_count == 54, "Grade 2 should emphasize the 54 all-single-digit subtraction prompts with nonzero minuends.")
    question_bank.free()
    print("Grade 2 smoke tests passed.")
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

