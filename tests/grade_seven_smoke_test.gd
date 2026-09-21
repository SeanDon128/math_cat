extends SceneTree

const QuestionBankScript = preload("res://autoload/question_bank.gd")

const EXPECTED_TOPIC_COUNTS := {
    "Ratios": 15,
    "Proportional Relationships": 15,
    "Negative Numbers": 15,
    "Algebraic Expressions": 15,
    "One-Step Equations": 15,
    "Statistics": 15,
    "Percentages": 50,
    "Rational Numbers": 50,
    "Two-Step Equations": 50,
    "Two-Step Inequalities": 40,
    "Probability": 40,
    "Area and Volume": 30,
    "Geometry": 40,
    "Scale Drawings": 20
}

func _init() -> void:
    var question_bank = QuestionBankScript.new()
    var topic_counts := EXPECTED_TOPIC_COUNTS.duplicate()
    var difficulty_counts := {"easy": 0, "medium": 0, "hard": 0}
    var seen_questions: Array[String] = []
    for question_index in range(410):
        var question: QuestionData = question_bank.get_question(7)
        assert(question.grade == 7, "Grade 7 questions must have Grade 7 metadata.")
        assert(topic_counts.has(question.topic), "Grade 7 question has an unknown topic.")
        topic_counts[question.topic] -= 1
        assert(difficulty_counts.has(question.difficulty), "Grade 7 question has an unknown difficulty.")
        difficulty_counts[question.difficulty] += 1
        assert(not question.question_text.is_empty(), "Grade 7 questions need text.")
        assert(not seen_questions.has(question.question_text), "Grade 7 question text must be unique.")
        seen_questions.append(question.question_text)
        assert(question.choices.size() == 4, "Each Grade 7 question must have four choices.")
        assert(question.choices.has(question.correct_answer), "Choices must include the correct answer.")
        var unique_choices: Array[String] = []
        for choice in question.choices:
            assert(not unique_choices.has(choice), "Question choices must be unique.")
            unique_choices.append(choice)
        assert(question.uses_pi == (question.topic == "Geometry" and (question.question_text.contains("pi = 3.14"))), "Pi metadata must match Grade 7 circle questions.")
    for topic in topic_counts:
        assert(topic_counts[topic] == 0, "Grade 7 topic count does not match the bank specification.")
    assert(difficulty_counts == {"easy": 82, "medium": 246, "hard": 82}, "Grade 7 difficulty distribution must be 20/60/20.")
    question_bank.free()
    print("Grade 7 smoke tests passed.")
    quit()