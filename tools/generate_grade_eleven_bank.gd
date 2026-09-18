extends SceneTree

const OUTPUT_PATH := "res://data/questions/grade_11.json"

var records: Array[Dictionary] = []
var question_index := 0

func _init() -> void:
    _add_topic("Complex Numbers", 45, 0)
    _add_topic("Polynomial Functions", 45, 1)
    _add_topic("Polynomial Operations", 30, 2)
    _add_topic("Factoring Higher-Degree Polynomials", 35, 3)
    _add_topic("Exponential Functions", 45, 4)
    _add_topic("Exponential Growth and Decay", 35, 5)
    _add_topic("Logarithmic Functions", 45, 6)
    _add_topic("Logarithm Properties", 30, 7)
    _add_topic("Sequences", 25, 8)
    _add_topic("Series", 25, 9)
    _add_topic("Arithmetic Sequences", 25, 10)
    _add_topic("Geometric Sequences", 25, 11)
    _add_topic("Trigonometric Functions", 45, 12)
    _add_topic("Unit Circle Basics", 30, 13, true)
    _add_topic("Function Transformations", 30, 14)
    _add_topic("Function Composition", 25, 15)
    _add_topic("Inverse Functions", 25, 16)
    _add_topic("Algebra II Word Problems", 40, 17)
    assert(records.size() == 605, "Grade 11 question bank must contain 605 records.")
    var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
    assert(file != null, "Unable to write Grade 11 question bank.")
    file.store_string(JSON.stringify(records, "  ") + "\n")
    file.close()
    print("Generated %d Grade 11 questions at %s" % [records.size(), OUTPUT_PATH])
    quit()

func _record(topic: String, prompt: String, correct: String, wrong: Array[String], uses_pi: bool) -> void:
    var choices: Array[String] = []
    for answer in wrong:
        if answer != correct and not choices.has(answer):
            choices.append(answer)
    assert(choices.size() >= 3, "Grade 11 choices must be distinct: %s" % prompt)
    choices.resize(3)
    choices.insert(posmod(question_index, 4), correct)
    records.append({"grade": 11, "topic": topic, "difficulty": "medium" if posmod(question_index, 2) == 0 else "hard", "uses_pi": uses_pi, "question": prompt, "choices": choices, "correctAnswer": correct})
    question_index += 1

func _add_topic(topic: String, count: int, kind: int, uses_pi: bool = false) -> void:
    for index in range(count):
        var value := index + 2
        match kind:
            0:
                match posmod(index, 3):
                    0: _record(topic, "Simplify: i%s" % _superscript(2 + 4 * (index / 3)), "-1", ["1", "i", "0"], uses_pi)
                    1: _record(topic, "Simplify: (%d + %di) + (%d - %di)" % [value, value + 1, value + 2, value + 3], "%d - 2i" % (2 * value + 2), ["%d + 2i" % (2 * value + 2), "%d - 2i" % (2 * value + 4), "%d + 2i" % (2 * value)], uses_pi)
                    _: _record(topic, "Simplify: (%d + %di)(%d - %di)" % [value, 1, 1, 1], "%d + %di" % [value + 1, 1 - value], ["%d + %di" % [value - 1, value + 1], "%d - %di" % [value + 1, value - 1], "%d" % (value + 1)], uses_pi)
            1:
                match posmod(index, 3):
                    0: _record(topic, "What is the degree of f(x) = %dx⁴ - %dx² + %d?" % [value, value + 1, value + 2], "4", ["2", "3", "6"], uses_pi)
                    1: _record(topic, "Which is a zero of f(x) = (x - %d)(x + %d)?" % [value, value + 1], str(value), [str(-value - 1), str(value + 1), str(value * (value + 1))], uses_pi)
                    _: _record(topic, "What is f(%d) for f(x) = x² - %dx?" % [value, value - 1], str(value), [str(value * value), str(value - 1), str(-value)], uses_pi)
            2:
                match posmod(index, 2):
                    0: _record(topic, "Simplify: (%dx² + %dx + 1) + (%dx² - %dx + 2)" % [value, value + 1, value + 2, value], "%dx² + x + 3" % (2 * value + 2), ["%dx² + x + 3" % (value * (value + 2)), "%dx² + %dx + 3" % [2 * value + 2, 2 * value + 1], "%dx² + 3" % (2 * value + 2)], uses_pi)
                    _: _record(topic, "Expand: (x + %d)(x² + %dx + 1)" % [value, value + 1], "x³ + %dx² + %dx + %d" % [2 * value + 1, value + 2, value], ["x³ + %dx² + %dx + %d" % [value + 1, value + 2, value], "x³ + %dx² + %dx + %d" % [2 * value + 1, value + 1, value], "x³ + %d" % value], uses_pi)
            3:
                _record(topic, "Factor: x³ - %dx²" % value, "x²(x - %d)" % value, ["x(x - %d)" % value, "(x - %d)³" % value, "x²(x + %d)" % value], uses_pi)
            4:
                var result := int(pow(2, value))
                _record(topic, "Evaluate: %s" % _power(2, value), str(result), [str(result - 1), str(result + 1), str(result + 2)], uses_pi)
            5:
                var start := 100 + index * 10
                var rate := 2 + posmod(index, 5)
                _record(topic, "A value of %d grows by %d%% once. What is the new value?" % [start, rate], str(roundi(start * (100 + rate) / 100.0)), [str(start - rate), str(start * rate + 1), str(start * (100 + rate))], uses_pi)
            6:
                var power := 2 + posmod(index, 4)
                var argument := int(pow(value, power))
                _record(topic, "What is log_%d(%d)?" % [value, argument], str(power), [str(power - 1), str(power + 1), str(argument)], uses_pi)
            7:
                _record(topic, "Which expression equals log(%d) + log(%d)?" % [value, value + 1], "log(%d)" % (value * (value + 1)), ["log(%d)" % (value + value + 1), "log(%d/%d)" % [value, value + 1], "%dlog(%d)" % [value + 1, value]], uses_pi)
            8:
                _record(topic, "What is the next term: %d, %d, %d, ...?" % [value, value + 3, value + 6], str(value + 9), [str(value + 8), str(value + 10), str(value + 12)], uses_pi)
            9:
                _record(topic, "Find the sum: %d + %d + %d" % [value, value + 2, value + 4], str(3 * value + 6), [str(3 * value + 3), str(value + 6), str(3 * value + 12)], uses_pi)
            10:
                _record(topic, "An arithmetic sequence starts at %d with difference %d. What is term 4?" % [value, value + 1], str(4 * value + 3), [str(3 * value + 2), str(value + 4), str(4 * value + 4)], uses_pi)
            11:
                _record(topic, "A geometric sequence starts at %d with ratio 2. What is term 4?" % value, str(8 * value), [str(8 * value - 1), str(8 * value + 1), str(4 * value)], uses_pi)
            12:
                match posmod(index, 3):
                    0: _record(topic, "What is sin(%d degrees)?" % (30 + 360 * (index / 3)), "1/2", ["√3/2", "1", "0"], uses_pi)
                    1: _record(topic, "What is cos(%d degrees)?" % (60 + 360 * (index / 3)), "1/2", ["√3/2", "1", "0"], uses_pi)
                    _: _record(topic, "What is tan(%d degrees)?" % (45 + 360 * (index / 3)), "1", ["0", "√3", "1/2"], uses_pi)
            13:
                match posmod(index, 3):
                    0: _record(topic, "What is sin(%dπ/2)?" % (1 + 4 * (index / 3)), "1", ["0", "-1", "√2/2"], uses_pi)
                    1: _record(topic, "Which point is on the unit circle at angle %dπ?" % (1 + 2 * (index / 3)), "(-1, 0)", ["(1, 0)", "(0, 1)", "(0, -1)"], uses_pi)
                    _: _record(topic, "What is cos(%dπ/3)?" % (1 + 6 * (index / 3)), "1/2", ["√3/2", "0", "-1/2"], uses_pi)
            14:
                _record(topic, "How does y = (x - %d)² move y = x²?" % value, "%d units right" % value, ["%d units left" % value, "%d units up" % value, "%d units down" % value], uses_pi)
            15:
                _record(topic, "If f(x) = x + %d and g(x) = 2x, find f(g(%d))." % [value, value + 1], str(3 * value + 2), [str(2 * value + 2), str(3 * value + 1), str(2 * value + 1)], uses_pi)
            16:
                _record(topic, "If f(x) = %dx + %d, what is f⁻¹(%d)?" % [2, value, 2 * value + 4], "2", [str(value + 2), str(value + 4), str(2 * value + 4)], uses_pi)
            _:
                var principal := 500 + index * 20
                var amount := principal + 3 * (index + 2)
                _record(topic, "An account starts with $%d and gains $3 per month. What is the amount after %d months?" % [principal, index + 2], "$%d" % amount, ["$%d" % (principal * 3 * (index + 2)), "$%d" % (principal + 3 + index + 2), "$%d" % (3 * (index + 2))], uses_pi)

func _power(base: int, exponent: int) -> String:
    return "%d%s" % [base, _superscript(exponent)]

func _superscript(number: int) -> String:
    var superscripts := {"0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹"}
    var rendered := ""
    for character in str(number):
        rendered += superscripts[character]
    return rendered