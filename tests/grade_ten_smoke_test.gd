extends SceneTree

const QuestionBankScript = preload("res://autoload/question_bank.gd")
const EXPECTED_TOPIC_COUNTS := {"Linear Equations": 40, "Multi-Step Equations": 40, "Variables on Both Sides": 30, "Graphing Linear Equations": 35, "Slope-Intercept Form": 30, "Systems of Equations": 40, "Linear Inequalities": 35, "Solving Quadratic Equations": 50, "Quadratic Functions": 40, "Polynomial Operations": 35, "Factoring Polynomials": 50, "Function Notation": 25, "Function Evaluation": 25, "Function Interpretation": 25, "Algebra Word Problems": 40, "Real-World Modeling": 30}

func _init() -> void:
    var question_bank = QuestionBankScript.new()
    var topic_counts := EXPECTED_TOPIC_COUNTS.duplicate()
    var difficulty_counts := {"medium": 0, "hard": 0}
    var seen_questions: Array[String] = []
    for question_index in range(570):
        var question: QuestionData = question_bank.get_question(10)
        assert(question.grade == 10, "Grade 10 questions must have Grade 10 metadata.")
        assert(topic_counts.has(question.topic), "Grade 10 question has an unknown topic.")
        topic_counts[question.topic] -= 1
        assert(difficulty_counts.has(question.difficulty), "Grade 10 questions must be medium or hard.")
        difficulty_counts[question.difficulty] += 1
        assert(not seen_questions.has(question.question_text), "Grade 10 question text must be unique.")
        seen_questions.append(question.question_text)
        assert(question.choices.size() == 4 and question.choices.has(question.correct_answer), "Grade 10 questions must have four choices including the answer.")
        var unique_choices: Array[String] = []
        for choice in question.choices:
            assert(not unique_choices.has(choice), "Grade 10 choices must be unique.")
            unique_choices.append(choice)
        assert(not question.uses_pi, "Grade 10 Algebra I questions must not use pi.")
    for topic in topic_counts:
        assert(topic_counts[topic] == 0, "Grade 10 topic count does not match specification.")
    assert(difficulty_counts == {"medium": 285, "hard": 285}, "Grade 10 difficulty distribution must be 50/50 medium and hard.")
    question_bank.free()
    print("Grade 10 smoke tests passed.")
    quit()