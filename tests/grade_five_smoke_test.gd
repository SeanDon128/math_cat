extends SceneTree

const QuestionBankScript = preload("res://autoload/question_bank.gd")

const EXPECTED_TOPIC_COUNTS := {
    "Multi-Digit Addition": 35,
    "Multi-Digit Subtraction": 35,
    "Multi-Digit Multiplication": 35,
    "Long Division": 20,
    "Fraction Addition (Like Denominators)": 15,
    "Fraction Subtraction (Like Denominators)": 15,
    "Decimal Place Value": 15,
    "Decimal Comparison": 15,
    "Decimal Operations": 30
}

func _init() -> void:
    var question_bank = QuestionBankScript.new()
    var topic_counts := EXPECTED_TOPIC_COUNTS.duplicate()
    var difficulty_counts := {"easy": 0, "medium": 0, "hard": 0}
    var seen_questions: Array[String] = []

    for question_index in range(215):
        var question: QuestionData = question_bank.get_question(5)
        assert(question.grade == 5, "Grade 5 questions must have Grade 5 metadata.")
        assert(topic_counts.has(question.topic), "Grade 5 question has an unknown topic.")
        topic_counts[question.topic] -= 1
        assert(difficulty_counts.has(question.difficulty), "Grade 5 question has an unknown difficulty.")
        difficulty_counts[question.difficulty] += 1
        assert(not question.uses_pi, "Grade 5 questions must not use pi.")
        assert(not question.question_text.is_empty(), "Grade 5 questions need text.")
        assert(not question.question_text.ends_with("= ?"), "Grade 5 arithmetic prompts must not end with a question mark.")
        assert(not seen_questions.has(question.question_text), "Grade 5 question text must be unique.")
        seen_questions.append(question.question_text)
        assert(question.choices.size() == 4, "Each Grade 5 question must have four choices.")
        assert(question.choices.has(question.correct_answer), "Choices must include the correct answer.")
        var unique_choices: Array[String] = []
        for choice in question.choices:
            assert(not unique_choices.has(choice), "Question choices must be unique.")
            unique_choices.append(choice)

    for topic in topic_counts:
        assert(topic_counts[topic] == 0, "Grade 5 topic count does not match the bank specification.")
    assert(difficulty_counts == {"easy": 43, "medium": 129, "hard": 43}, "Grade 5 difficulty distribution must be 20/60/20.")
    question_bank.free()
    print("Grade 5 smoke tests passed.")
    quit()
