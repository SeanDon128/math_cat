extends SceneTree

const QuestionBankScript = preload("res://autoload/question_bank.gd")
const EXPECTED_TOPIC_COUNTS := {"Complex Numbers": 45, "Polynomial Functions": 45, "Polynomial Operations": 30, "Factoring Higher-Degree Polynomials": 35, "Exponential Functions": 45, "Exponential Growth and Decay": 35, "Logarithmic Functions": 45, "Logarithm Properties": 30, "Sequences": 25, "Series": 25, "Arithmetic Sequences": 25, "Geometric Sequences": 25, "Trigonometric Functions": 45, "Unit Circle Basics": 30, "Function Transformations": 30, "Function Composition": 25, "Inverse Functions": 25, "Algebra II Word Problems": 40}

func _init() -> void:
    var question_bank = QuestionBankScript.new()
    var topic_counts := EXPECTED_TOPIC_COUNTS.duplicate()
    var difficulty_counts := {"medium": 0, "hard": 0}
    var seen_questions: Array[String] = []
    for question_index in range(605):
        var question: QuestionData = question_bank.get_question(11)
        assert(question.grade == 11, "Grade 11 questions must have Grade 11 metadata.")
        assert(topic_counts.has(question.topic), "Grade 11 question has an unknown topic.")
        topic_counts[question.topic] -= 1
        assert(difficulty_counts.has(question.difficulty), "Grade 11 questions must be medium or hard.")
        difficulty_counts[question.difficulty] += 1
        assert(not seen_questions.has(question.question_text), "Grade 11 question text must be unique.")
        seen_questions.append(question.question_text)
        assert(question.choices.size() == 4 and question.choices.has(question.correct_answer), "Grade 11 questions must have four choices including the answer.")
        var unique_choices: Array[String] = []
        for choice in question.choices:
            assert(not unique_choices.has(choice), "Grade 11 choices must be unique.")
            unique_choices.append(choice)
        assert(question.uses_pi == (question.topic == "Unit Circle Basics"), "Only Grade 11 Unit Circle Basics questions must use pi.")
    for topic in topic_counts:
        assert(topic_counts[topic] == 0, "Grade 11 topic count does not match specification.")
    assert(difficulty_counts == {"medium": 303, "hard": 302}, "Grade 11 difficulty distribution must be approximately 50/50.")
    question_bank.free()
    print("Grade 11 smoke tests passed.")
    quit()