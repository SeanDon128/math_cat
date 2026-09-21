extends SceneTree

const QuestionBankScript = preload("res://autoload/question_bank.gd")
const EXPECTED_TOPIC_COUNTS := {"Integration": 25, "Integration Techniques": 25, "Applications of Integration": 15, "Sequences and Series": 20, "Convergence and Divergence": 15, "Taylor Series": 15, "Multivariable Functions": 20, "Partial Derivatives": 20, "Multiple Integrals": 15, "Vector Calculus": 20, "First-Order Differential Equations": 25, "Applications of Differential Equations": 15, "Exponential Growth and Decay Models": 15, "Matrices": 20, "Matrix Operations": 20, "Determinants": 15, "Vectors": 20, "Eigenvalues and Eigenvectors": 15, "Groups": 15, "Rings": 10, "Fields": 10, "Modular Arithmetic (Modern Algebra)": 20, "Open Sets": 10, "Closed Sets": 10, "Continuity": 10, "Homeomorphisms": 10, "Modular Arithmetic (Cryptography)": 15, "Prime Numbers": 10, "Public Key Concepts": 10, "RSA Foundations": 10, "Logic": 15, "Mathematical Proofs": 15, "Set Theory": 15}

func _init() -> void:
    var question_bank = QuestionBankScript.new()
    var topic_counts := EXPECTED_TOPIC_COUNTS.duplicate()
    var seen_questions: Array[String] = []
    for question_index in range(520):
        var question: QuestionData = question_bank.get_question(13)
        assert(question.grade == 13, "Grade 13 questions must have Grade 13 metadata.")
        assert(topic_counts.has(question.topic), "Grade 13 question has an unknown topic.")
        topic_counts[question.topic] -= 1
        assert(question.difficulty == "hard", "Every Grade 13 question must be hard.")
        assert(not seen_questions.has(question.question_text), "Grade 13 question text must be unique.")
        seen_questions.append(question.question_text)
        assert(question.choices.size() == 4 and question.choices.has(question.correct_answer), "Grade 13 questions must have four choices including the answer.")
        var unique_choices: Array[String] = []
        for choice in question.choices:
            assert(not unique_choices.has(choice), "Grade 13 choices must be unique.")
            unique_choices.append(choice)
        assert(question.uses_pi == question.question_text.contains("π"), "Grade 13 pi metadata must match pi notation.")
    for topic in topic_counts:
        assert(topic_counts[topic] == 0, "Grade 13 topic count does not match specification.")
    question_bank.free()
    print("Grade 13 smoke tests passed.")
    quit()