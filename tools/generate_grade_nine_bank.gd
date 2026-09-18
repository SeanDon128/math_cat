extends SceneTree

const OUTPUT_PATH := "res://data/questions/grade_9.json"
var records: Array[Dictionary] = []
var question_index := 0

func _init() -> void:
    _add_review("Linear Equations", 15, 0)
    _add_review("Linear Functions", 15, 1)
    _add_review("Graphing and Coordinate Plane", 15, 2)
    _add_review("Slope and Rate of Change", 15, 3)
    _add_review("Pythagorean Theorem", 20, 4)
    _add_review("Systems of Equations", 15, 5)
    _add_review("Exponents", 15, 6)
    _add_review("Scientific Notation", 10, 7)
    _add_review("Geometry Transformations", 10, 8)
    _add_preview("Linear Equations", 35, 0)
    _add_preview("Graphing Linear Equations", 30, 1)
    _add_preview("Systems of Equations", 25, 2)
    _add_preview("Linear Inequalities", 25, 3)
    _add_preview("Quadratic Equations", 35, 4)
    _add_preview("Quadratic Functions", 25, 5)
    _add_preview("Polynomial Operations", 25, 6)
    _add_preview("Factoring Polynomials", 30, 7)
    _add_preview("Function Notation and Evaluation", 25, 8)
    assert(records.size() == 385, "Grade 9 question bank must contain 385 records.")
    var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
    assert(file != null, "Unable to write Grade 9 question bank.")
    file.store_string(JSON.stringify(records, "  ") + "\n")
    file.close()
    print("Generated %d Grade 9 questions at %s" % [records.size(), OUTPUT_PATH])
    quit()

func _record(topic: String, difficulty: String, prompt: String, correct: String, wrong: Array[String]) -> void:
    var choices: Array[String] = []
    for answer in wrong:
        if answer != correct and not choices.has(answer):
            choices.append(answer)
    assert(choices.size() >= 3, "Grade 9 choices must be distinct: %s" % prompt)
    choices.resize(3)
    choices.insert(posmod(question_index, 4), correct)
    records.append({"grade": 9, "topic": topic, "difficulty": difficulty, "uses_pi": false, "question": prompt, "choices": choices, "correctAnswer": correct})
    question_index += 1

func _add_review(name: String, count: int, kind: int) -> void:
    var topic := "Grade 8 Review: " + name
    for index in range(count):
        var value := index + 2
        match kind:
            0:
                _record(topic, "hard", "Solve: %dx + %d = %dx + %d" % [4, index + 3, 2, 2 * value + index + 3], str(value), [str(value + 1), str(value - 1), str(2 * value)])
            1:
                _record(topic, "hard", "For f(x) = %dx - %d, find f(%d)." % [3, index + 1, value], str(3 * value - index - 1), [str(3 * value + index + 1), str(value - index - 1), str(3 * value)])
            2:
                _record(topic, "hard", "What is the midpoint of (%d, %d) and (%d, %d)?" % [value, value + 1, value + 4, value + 7], "(%d, %d)" % [value + 2, value + 4], ["(%d, %d)" % [value + 4, value + 7], "(%d, %d)" % [value + 2, value + 7], "(%d, %d)" % [value + 4, value + 2]])
            3:
                _record(topic, "hard", "Find the slope from (0, 0) to (%d, %d)." % [value + 1, 2 * (value + 1)], "2", ["1/2", str(2 * (value + 1)), "-2"])
            4:
                _record(topic, "hard", "A right triangle has legs %d and %d. Find its hypotenuse." % [3 * value, 4 * value], str(5 * value), [str(7 * value), str(25 * value * value), str(5 * value + 1)])
            5:
                _record(topic, "hard", "Solve x + y = %d and x - y = -%d. Find x." % [2 * value + 3, 3], str(value), [str(value + 3), str(2 * value + 3), str(-value)])
            6:
                _record(topic, "hard", "Simplify: %s / %s" % [_power(index + 2, 4), _power(index + 2, 2)], _power(index + 2, 2), [_power(index + 2, 6), _power(index + 2, 8), _power(2 * (index + 2), 2)])
            7:
                _record(topic, "hard", "What is %d x %s?" % [value, _power(10, 4)], str(value * 10000), [str(value * 1000), str(value * 100000), str(value + 4)])
            _:
                _record(topic, "hard", "Rotate (%d, %d) 90 degrees counterclockwise about the origin." % [value, value + 2], "(-%d, %d)" % [value + 2, value], ["(%d, -%d)" % [value + 2, value], "(-%d, -%d)" % [value, value + 2], "(%d, %d)" % [value + 2, value]])

func _add_preview(name: String, count: int, kind: int) -> void:
    var topic := "Algebra Preview: " + name
    for index in range(count):
        var difficulty := "easy" if posmod(index, 3) == 0 else "medium"
        var value := index + 2
        match kind:
            0:
                _record(topic, difficulty, "Solve: 3(x + %d) = %d" % [index + 1, 3 * (value + index + 1)], str(value), [str(value + index + 1), str(3 * value), str(value - 1)])
            1:
                _record(topic, difficulty, "For y = %dx - %d, what is the slope?" % [2 + posmod(index, 4), index], str(2 + posmod(index, 4)), [str(index), str(-(2 + posmod(index, 4))), "1/2"])
            2:
                _record(topic, difficulty, "Solve x + y = %d and x - y = -2. What is y?" % [2 * value + 2], str(value + 2), [str(value), str(2 * value + 2), str(-value)])
            3:
                _record(topic, difficulty, "Solve: -2x > -%d" % (2 * value), "x < %d" % value, ["x > %d" % value, "x < %d" % (2 * value), "x > -%d" % value])
            4:
                _record(topic, difficulty, "Which value is a root of (x - %d)(x - %d) = 0?" % [value, value + 2], str(value), [str(-value), str(value + 1), str(2 * value + 2)])
            5:
                _record(topic, difficulty, "What is the vertex of y = (x - %d)² + %d?" % [value, index], "(%d, %d)" % [value, index], ["(-%d, %d)" % [value, index], "(%d, -%d)" % [value, index], "(%d, %d)" % [index, value]])
            6:
                _record(topic, difficulty, "Simplify: %dx + %dx" % [value, value + 3], "%dx" % (2 * value + 3), ["%dx" % (value * (value + 3)), "%dx" % 3, "%dx²" % (2 * value + 3)])
            7:
                _record(topic, difficulty, "Factor: x² + %dx + %d" % [2 * value + 1, value * (value + 1)], "(x + %d)(x + %d)" % [value, value + 1], ["(x - %d)(x - %d)" % [value, value + 1], "(x + %d)²" % (2 * value + 1), "(x + %d)(x - %d)" % [value, value + 1]])
            _:
                _record(topic, difficulty, "If f(x) = x² - %d, find f(%d)." % [index, value], str(value * value - index), [str(value - index), str(value * value + 1), str((value - index) * (value - index) + 2)])

func _power(base: int, exponent: int) -> String:
    var superscripts := {"0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹"}
    return "%d%s" % [base, superscripts[str(exponent)]]