extends SceneTree

const QuestionBankScript = preload("res://autoload/question_bank.gd")
const EXPECTED_TOPIC_COUNTS := {"Grade 8 Review: Linear Equations": 15, "Grade 8 Review: Linear Functions": 15, "Grade 8 Review: Graphing and Coordinate Plane": 15, "Grade 8 Review: Slope and Rate of Change": 15, "Grade 8 Review: Pythagorean Theorem": 20, "Grade 8 Review: Systems of Equations": 15, "Grade 8 Review: Exponents": 15, "Grade 8 Review: Scientific Notation": 10, "Grade 8 Review: Geometry Transformations": 10, "Algebra Preview: Linear Equations": 35, "Algebra Preview: Graphing Linear Equations": 30, "Algebra Preview: Systems of Equations": 25, "Algebra Preview: Linear Inequalities": 25, "Algebra Preview: Quadratic Equations": 35, "Algebra Preview: Quadratic Functions": 25, "Algebra Preview: Polynomial Operations": 25, "Algebra Preview: Factoring Polynomials": 30, "Algebra Preview: Function Notation and Evaluation": 25}

func _init() -> void:
    var question_bank = QuestionBankScript.new()
    var topic_counts := EXPECTED_TOPIC_COUNTS.duplicate()
    var difficulty_counts := {"easy": 0, "medium": 0, "hard": 0}
    var seen_questions: Array[String] = []
    for question_index in range(385):
        var question: QuestionData = question_bank.get_question(9)
        assert(question.grade == 9, "Grade 9 questions must have Grade 9 metadata.")
        assert(topic_counts.has(question.topic), "Grade 9 question has an unknown topic.")
        topic_counts[question.topic] -= 1
        difficulty_counts[question.difficulty] += 1
        assert(not seen_questions.has(question.question_text), "Grade 9 question text must be unique.")
        seen_questions.append(question.question_text)
        assert(question.choices.size() == 4 and question.choices.has(question.correct_answer), "Grade 9 questions must have four choices including the answer.")
        var unique_choices: Array[String] = []
        for choice in question.choices:
            assert(not unique_choices.has(choice), "Grade 9 choices must be unique.")
            unique_choices.append(choice)
        assert(not question.uses_pi, "The Grade 9 Algebra-readiness deck has no pi questions.")
        if question.topic.begins_with("Grade 8 Review:"):
            assert(question.difficulty == "hard", "Grade 8 review questions must be hard.")
        else:
            assert(question.difficulty in ["easy", "medium"], "Algebra preview questions must be easy or medium.")
    for topic in topic_counts:
        assert(topic_counts[topic] == 0, "Grade 9 topic count does not match specification.")
    assert(difficulty_counts == {"easy": 89, "medium": 166, "hard": 130}, "Grade 9 difficulty distribution must match the transition design.")
    question_bank.free()
    print("Grade 9 smoke tests passed.")
    quit()