extends SceneTree

const QuestionBankScript = preload("res://autoload/question_bank.gd")
const EXPECTED_TOPIC_COUNTS := {"Percentages": 15, "Rational Numbers": 15, "Two-Step Equations": 15, "Two-Step Inequalities": 10, "Probability": 10, "Area and Volume": 10, "Geometry": 10, "Scale Drawings": 10, "Linear Equations": 50, "Linear Functions": 40, "Graphing and Coordinate Plane": 40, "Slope and Rate of Change": 40, "Pythagorean Theorem": 40, "Systems of Equations": 40, "Exponents": 40, "Scientific Notation": 30, "Geometry Transformations": 20}

func _init() -> void:
    var question_bank = QuestionBankScript.new()
    var topic_counts := EXPECTED_TOPIC_COUNTS.duplicate()
    var difficulty_counts := {"easy": 0, "medium": 0, "hard": 0}
    var seen_questions: Array[String] = []
    for question_index in range(435):
        var question: QuestionData = question_bank.get_question(8)
        assert(question.grade == 8, "Grade 8 questions must have Grade 8 metadata.")
        assert(topic_counts.has(question.topic), "Grade 8 question has an unknown topic.")
        topic_counts[question.topic] -= 1
        difficulty_counts[question.difficulty] += 1
        assert(not seen_questions.has(question.question_text), "Grade 8 question text must be unique.")
        seen_questions.append(question.question_text)
        assert(question.choices.size() == 4 and question.choices.has(question.correct_answer), "Grade 8 questions must have four choices including the answer.")
        var unique_choices: Array[String] = []
        for choice in question.choices:
            assert(not unique_choices.has(choice), "Grade 8 choices must be unique.")
            unique_choices.append(choice)
        assert(question.uses_pi == (question.topic == "Geometry" and question.question_text.contains("pi = 3.14")), "Pi metadata must match circle questions.")
    for topic in topic_counts:
        assert(topic_counts[topic] == 0, "Grade 8 topic count does not match specification.")
    assert(difficulty_counts == {"easy": 87, "medium": 261, "hard": 87}, "Grade 8 difficulty distribution must be 20/60/20.")
    question_bank.free()
    print("Grade 8 smoke tests passed.")
    quit()