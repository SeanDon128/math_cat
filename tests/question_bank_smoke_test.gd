extends SceneTree

const QuestionBankScript = preload("res://autoload/question_bank.gd")

func _init() -> void:
    var question_bank = QuestionBankScript.new()
    var seen_questions: Array[String] = []
    var seen_question_variants: Array[String] = []
    var correct_answer_positions: Array[int] = []
    var correct_lowest_count := 0
    var correct_highest_count := 0
    var correct_middle_count := 0

    for question_index in range(200):
        var question = question_bank.call("get_question", 1)
        assert(question.grade == 1, "Grade 1 should request a Grade 1 question.")
        assert(question.topic == "addition_within_20", "The MVP bank should generate Grade 1 addition.")
        assert(question.choices.size() == 4, "Every question needs four choices.")
        assert(question.choices.has(question.correct_answer), "Choices must include the correct answer.")
        var unique_choices: Array[String] = []
        for choice in question.choices:
            if not unique_choices.has(choice):
                unique_choices.append(choice)
        assert(unique_choices.size() == 4, "Choices must be unique.")
        var question_variant := "%s|%s" % [question.question_text, ",".join(question.choices)]
        assert(not seen_question_variants.has(question_variant), "Question-and-choice sets must not repeat before the deck is exhausted.")
        seen_question_variants.append(question_variant)
        if not seen_questions.has(question.question_text):
            seen_questions.append(question.question_text)

        var correct_position: int = question.choices.find(question.correct_answer)
        if not correct_answer_positions.has(correct_position):
            correct_answer_positions.append(correct_position)

        var addends = question.question_text.trim_suffix(" =").split(" + ")
        var first_addend := int(addends[0])
        var second_addend := int(addends[1])
        var correct_value := int(question.correct_answer)
        assert(first_addend >= 1 and first_addend <= 10, "The first addend must be between 1 and 10.")
        assert(second_addend >= 1 and second_addend <= 10, "The second addend must be between 1 and 10.")
        assert(first_addend + second_addend == correct_value, "The correct answer must equal the sum of both addends.")

        var has_non_adjacent_distractor := false
        var lower_choice_count := 0
        for choice in question.choices:
            var choice_value := int(choice)
            if choice_value != correct_value:
                assert(abs(choice_value - correct_value) <= 3, "Distractors should remain close to the correct answer.")
                if abs(choice_value - correct_value) > 1:
                    has_non_adjacent_distractor = true
                if choice_value < correct_value:
                    lower_choice_count += 1
        assert(has_non_adjacent_distractor, "Each question needs a close but non-adjacent distractor.")
        match lower_choice_count:
            0:
                correct_lowest_count += 1
            3:
                correct_highest_count += 1
            _:
                correct_middle_count += 1

    assert(seen_questions.size() == 100, "The deck should use the 100 ordered operand prompts twice.")
    assert(correct_lowest_count == 50, "The correct answer should be the lowest choice in 25% of the deck.")
    assert(correct_highest_count == 50, "The correct answer should be the highest choice in 25% of the deck.")
    assert(correct_middle_count == 100, "The correct answer should be a middle choice in 50% of the deck.")
    assert(correct_answer_positions.size() == 4, "Correct answers should appear in every choice position across a full deck.")
    question_bank.free()
    print("QuestionBank smoke tests passed.")
    quit()
