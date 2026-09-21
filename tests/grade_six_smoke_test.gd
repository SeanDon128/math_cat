extends SceneTree

const QuestionBankScript = preload("res://autoload/question_bank.gd")

const EXPECTED_TOPIC_COUNTS := {
    "Fraction Multiplication": 15,
    "Fraction Division": 15,
    "Decimal Operations": 15,
    "Volume of Rectangular Prisms": 15,
    "Ratios": 40,
    "Proportional Relationships": 40,
    "Negative Numbers": 40,
    "Algebraic Expressions": 40,
    "One-Step Equations": 40,
    "Statistics": 30,
    "Coordinate Plane Basics": 20,
    "Geometry Foundations": 20
}

func _init() -> void:
    var question_bank = QuestionBankScript.new()
    var topic_counts := EXPECTED_TOPIC_COUNTS.duplicate()
    var difficulty_counts := {"easy": 0, "medium": 0, "hard": 0}
    var seen_questions: Array[String] = []
    for question_index in range(330):
        var question: QuestionData = question_bank.get_question(6)
        assert(question.grade == 6, "Grade 6 questions must have Grade 6 metadata.")
        assert(topic_counts.has(question.topic), "Grade 6 question has an unknown topic.")
        topic_counts[question.topic] -= 1
        assert(difficulty_counts.has(question.difficulty), "Grade 6 question has an unknown difficulty.")
        difficulty_counts[question.difficulty] += 1
        assert(not question.uses_pi, "The Grade 6 bank contains no circle questions, so pi must be false.")
        assert(not question.question_text.is_empty(), "Grade 6 questions need text.")
        assert(not seen_questions.has(question.question_text), "Grade 6 question text must be unique.")
        seen_questions.append(question.question_text)
        assert(question.choices.size() == 4, "Each Grade 6 question must have four choices.")
        assert(question.choices.has(question.correct_answer), "Choices must include the correct answer.")
        var unique_choices: Array[String] = []
        for choice in question.choices:
            assert(not unique_choices.has(choice), "Question choices must be unique.")
            unique_choices.append(choice)
    for topic in topic_counts:
        assert(topic_counts[topic] == 0, "Grade 6 topic count does not match the bank specification.")
    assert(difficulty_counts == {"easy": 66, "medium": 198, "hard": 66}, "Grade 6 difficulty distribution must be 20/60/20.")
    question_bank.free()
    print("Grade 6 smoke tests passed.")
    quit()