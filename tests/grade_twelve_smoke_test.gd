extends SceneTree

const QuestionBankScript = preload("res://autoload/question_bank.gd")
const PI_TOPICS := ["Advanced Trigonometry", "Unit Circle", "Trigonometric Identities"]
const EXPECTED_TOPIC_COUNTS := {"Advanced Trigonometry": 41, "Unit Circle": 41, "Trigonometric Identities": 30, "Limits": 51, "Introductory Derivatives": 61, "Rate of Change": 30, "Function Analysis": 30, "Composite Functions": 25, "Inverse Functions": 25, "Exponential Functions": 25, "Logarithmic Functions": 25, "Sequences and Series": 30, "Probability": 30, "Statistical Inference": 30, "Matrices": 25, "Vectors": 25, "Real-World Modeling": 25, "AP Calculus-Style Problems": 36}

func _init() -> void:
    var question_bank = QuestionBankScript.new()
    var topic_counts := EXPECTED_TOPIC_COUNTS.duplicate()
    var difficulty_counts := {"medium": 0, "hard": 0}
    var seen_questions: Array[String] = []
    for question_index in range(585):
        var question: QuestionData = question_bank.get_question(12)
        assert(question.grade == 12, "Grade 12 questions must have Grade 12 metadata.")
        assert(topic_counts.has(question.topic), "Grade 12 question has an unknown topic.")
        topic_counts[question.topic] -= 1
        assert(difficulty_counts.has(question.difficulty), "Grade 12 questions must be medium or hard.")
        difficulty_counts[question.difficulty] += 1
        assert(not seen_questions.has(question.question_text), "Grade 12 question text must be unique.")
        seen_questions.append(question.question_text)
        assert(question.choices.size() == 4 and question.choices.has(question.correct_answer), "Grade 12 questions must have four choices including the answer.")
        var unique_choices: Array[String] = []
        for choice in question.choices:
            assert(not unique_choices.has(choice), "Grade 12 choices must be unique.")
            unique_choices.append(choice)
        assert(question.uses_pi == PI_TOPICS.has(question.topic), "Grade 12 pi metadata must match the trigonometry topics.")
    for topic in topic_counts:
        assert(topic_counts[topic] == 0, "Grade 12 topic count does not match specification.")
    assert(difficulty_counts == {"medium": 293, "hard": 292}, "Grade 12 difficulty distribution must be approximately 50/50.")
    question_bank.free()
    print("Grade 12 smoke tests passed.")
    quit()