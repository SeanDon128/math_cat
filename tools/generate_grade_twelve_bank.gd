extends SceneTree

const OUTPUT_PATH := "res://data/questions/grade_12.json"
const PI_TOPICS := ["Advanced Trigonometry", "Unit Circle", "Trigonometric Identities"]

var records: Array[Dictionary] = []
var question_index := 0

func _init() -> void:
    _add_topic("Advanced Trigonometry", 41, 0)
    _add_topic("Unit Circle", 41, 1)
    _add_topic("Trigonometric Identities", 30, 2)
    _add_topic("Limits", 51, 3)
    _add_topic("Introductory Derivatives", 61, 4)
    _add_topic("Rate of Change", 30, 5)
    _add_topic("Function Analysis", 30, 6)
    _add_topic("Composite Functions", 25, 7)
    _add_topic("Inverse Functions", 25, 8)
    _add_topic("Exponential Functions", 25, 9)
    _add_topic("Logarithmic Functions", 25, 10)
    _add_topic("Sequences and Series", 30, 11)
    _add_topic("Probability", 30, 12)
    _add_topic("Statistical Inference", 30, 13)
    _add_topic("Matrices", 25, 14)
    _add_topic("Vectors", 25, 15)
    _add_topic("Real-World Modeling", 25, 16)
    _add_topic("AP Calculus-Style Problems", 36, 17)
    assert(records.size() == 585, "Grade 12 question bank must contain 585 records.")
    var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
    assert(file != null, "Unable to write Grade 12 question bank.")
    file.store_string(JSON.stringify(records, "  ") + "\n")
    file.close()
    print("Generated %d Grade 12 questions at %s" % [records.size(), OUTPUT_PATH])
    quit()

func _record(topic: String, prompt: String, correct: String, wrong: Array[String]) -> void:
    var choices: Array[String] = []
    for answer in wrong:
        if answer != correct and not choices.has(answer):
            choices.append(answer)
    assert(choices.size() >= 3, "Grade 12 choices must be distinct: %s" % prompt)
    choices.resize(3)
    choices.insert(posmod(question_index, 4), correct)
    records.append({"grade": 12, "topic": topic, "difficulty": "medium" if posmod(question_index, 2) == 0 else "hard", "uses_pi": PI_TOPICS.has(topic), "question": prompt, "choices": choices, "correctAnswer": correct})
    question_index += 1

func _add_topic(topic: String, count: int, kind: int) -> void:
    for index in range(count):
        var value := index + 2
        var cycle := index / 3
        match kind:
            0:
                match posmod(index, 3):
                    0: _record(topic, "What is sin(%d degrees)?" % (30 + 360 * cycle), "1/2", ["√3/2", "-1/2", "1" ])
                    1: _record(topic, "Convert %d degrees to radians." % (45 + 180 * cycle), "%dπ/4" % (1 + 4 * cycle), ["%dπ/2" % (1 + 4 * cycle), "%dπ/180" % (45 + 180 * cycle), "%dπ/4" % (2 + 4 * cycle)])
                    _: _record(topic, "A sine graph has amplitude %d. What is its maximum value if its midline is y = %d?" % [value, value + 1], str(2 * value + 1), [str(value + 1), str(value - 1), str(2 * value - 1)])
            1:
                match posmod(index, 3):
                    0: _record(topic, "What is cos(%dπ/3)?" % (1 + 6 * cycle), "1/2", ["√3/2", "-1/2", "0"])
                    1: _record(topic, "Which point is at angle %dπ/2 on the unit circle?" % (1 + 4 * cycle), "(0, 1)", ["(1, 0)", "(0, -1)", "(-1, 0)"])
                    _: _record(topic, "What is tan(%dπ/4)?" % (1 + 4 * cycle), "1", ["0", "-1", "√3"])
            2:
                match posmod(index, 3):
                    0: _record(topic, "Simplify sin²(%dx) + cos²(%dx)." % [value, value], "1", ["0", "sin(%dx)" % value, "cos(%dx)" % value])
                    1: _record(topic, "Which expression is equivalent to 1 - sin²(%dx)?" % value, "cos²(%dx)" % value, ["sin²(%dx)" % value, "tan²(%dx)" % value, "1 + cos²(%dx)" % value])
                    _: _record(topic, "Simplify sin(%dx)/cos(%dx)." % [value, value], "tan(%dx)" % value, ["cot(%dx)" % value, "sec(%dx)" % value, "csc(%dx)" % value])
            3:
                match posmod(index, 3):
                    0: _record(topic, "Evaluate: lim x→%d (x + %d)." % [value, value + 3], str(2 * value + 3), [str(value + 3), str(2 * value), "does not exist"])
                    1: _record(topic, "Evaluate: lim x→%d (x² - %d)." % [value, value], str(value * value - value), [str(value * value), str(2 * value - value), "does not exist"])
                    _: _record(topic, "Evaluate: lim x→%d (x² - %d²)/(x - %d)." % [value, value, value], str(2 * value), [str(value), str(value * value), "0"])
            4:
                var exponent := 2 + posmod(index, 5)
                var coefficient := 2 + cycle
                var derivative_coefficient := coefficient * exponent
                match posmod(index, 3):
                    0: _record(topic, "What is d/dx of %d%s?" % [coefficient, _power_x(exponent)], "%d%s" % [derivative_coefficient, _power_x(exponent - 1)], ["%d%s" % [coefficient, _power_x(exponent - 1)], "%d%s" % [derivative_coefficient, _power_x(exponent)], str(derivative_coefficient)])
                    1: _record(topic, "What is the slope of y = x² + %dx at x = %d?" % [value, value], str(3 * value), [str(2 * value), str(value * value + value), str(value)])
                    _: _record(topic, "What is d/dx of %dx³ - %dx?" % [value, value + 1], "%dx² - %d" % [3 * value, value + 1], ["%dx² - %d" % [value, value + 1], "%dx²" % (3 * value), "%dx³ - %d" % [3 * value, value + 1]])
            5:
                match posmod(index, 3):
                    0: _record(topic, "A position is s(t) = %dt² meters. What is velocity at t = %d?" % [value, value], "%d m/s" % (2 * value * value), ["%d m/s" % (value * value), "%d m/s" % (2 * value + 1), "%d m/s" % (value * value * value + 1)])
                    1: _record(topic, "The average rate of change of f(x) = x² from x = %d to x = %d is:" % [value, value + 2], str(2 * value + 2), [str(value + 2), str(2 * value), str((value + 2) * (value + 2))])
                    _: _record(topic, "If a distance changes from %d km to %d km in 2 hours, what is the average speed?" % [value * 10, value * 10 + 20], "10 km/h", ["20 km/h", "%d km/h" % (value * 10 + 20), "5 km/h"])
            6:
                match posmod(index, 3):
                    0: _record(topic, "What is the domain of f(x) = 1/(x - %d)?" % value, "all real x except %d" % value, ["all real x", "x > %d" % value, "x < %d" % value])
                    1: _record(topic, "What is the y-intercept of f(x) = %dx + %d?" % [value, value + 1], str(value + 1), [str(value), "0", str(2 * value + 1)])
                    _: _record(topic, "For f(x) = (x - %d)², where is the minimum?" % value, "x = %d" % value, ["x = 0", "x = -%d" % value, "x = %d" % (2 * value)])
            7:
                _record(topic, "If f(x) = x + %d and g(x) = %dx, what is f(g(%d))?" % [value, 2 + posmod(index, 3), value + 1], str((2 + posmod(index, 3)) * (value + 1) + value), [str((value + 1) + value), str((2 + posmod(index, 3)) * value), str((2 + posmod(index, 3)) * (value + 1))])
            8:
                _record(topic, "If f(x) = %dx + %d, what is f⁻¹(%d)?" % [2, value, 2 * value + 6], ("%0.1f" % ((value + 6) / 2.0)).trim_suffix(".0"), [str(value + 3), str(value + 6), str(2 * value + 6)])
            9:
                var base := value
                var power := 2 + posmod(index, 3)
                var result := int(pow(base, power))
                _record(topic, "Evaluate: %d%s." % [base, _superscript(power)], str(result), [str(result - 1), str(result + 1), str(result + 2)])
            10:
                var base := value
                var power := 2 + posmod(index, 3)
                var argument := int(pow(base, power))
                _record(topic, "What is log_%d(%d)?" % [base, argument], str(power), [str(power - 1), str(power + 1), str(argument)])
            11:
                match posmod(index, 3):
                    0: _record(topic, "An arithmetic sequence begins %d, %d, %d. What is term 5?" % [value, value + 3, value + 6], str(value + 12), [str(value + 9), str(value + 15), str(5 * value)])
                    1: _record(topic, "A geometric sequence begins %d, %d, %d. What is term 4?" % [value, 2 * value, 4 * value], str(8 * value), [str(6 * value), str(4 * value), str(16 * value)])
                    _: _record(topic, "Find the sum of the first 3 terms: %d + %d + %d." % [value, value + 2, value + 4], str(3 * value + 6), [str(3 * value), str(value + 6), str(3 * value + 12)])
            12:
                match posmod(index, 3):
                    0:
                        var successes := 6 - posmod(value, 5)
                        _record(topic, "On roll %d of a fair-die simulation, what is P(rolling a number greater than %d)?" % [value, posmod(value, 5)], "%d/6" % successes, ["%d/6" % (successes - 1), "%d/6" % (successes + 1), "%d/6" % (successes + 2)])
                    1: _record(topic, "In trial %d, two fair coins are flipped. What is P(exactly one head)?" % value, "1/2", ["1/4", "3/4", "1"])
                    _: _record(topic, "A game pays $%d with probability 1/2 and $0 otherwise. What is its expected value?" % (2 * value), "$%d" % value, ["$%d" % (2 * value), "$0", "$%d" % (value + 1)])
            13:
                match posmod(index, 3):
                    0: _record(topic, "Which sample best supports a claim about every student in a school of %d students?" % (100 + index), "a random sample of students", ["the first 20 students arriving", "only varsity athletes", "students who volunteer"])
                    1: _record(topic, "Two data sets about %d students have the same mean. Which has more variability?" % (100 + value), "the set with the larger standard deviation", ["the set with the smaller mean", "the set with the larger median", "they must have equal variability"])
                    _: _record(topic, "A 95%% confidence interval from sample %d means:" % value, "the method captures the true parameter about 95% of repeated samples", ["95% of data values are in the interval", "there is a 95% chance the parameter changes", "95% of individuals are sampled"])
            14:
                match posmod(index, 2):
                    0: _record(topic, "Add matrices [[%d, 1], [2, 3]] + [[1, 2], [3, 4]]. What is the top-left entry?" % value, str(value + 1), [str(value), "1", str(value + 3)])
                    _: _record(topic, "For A = [[%d, 1], [0, 1]], what is the top-left entry of 2A?" % value, str(2 * value), [str(value), str(value + 2), "2"])
            15:
                match posmod(index, 2):
                    0: _record(topic, "What is the magnitude of vector <%d, 0>?" % value, str(value), [str(value * value), "0", str(value + 1)])
                    _: _record(topic, "What is <%d, %d> + <1, -1>?" % [value, value + 1], "<%d, %d>" % [value + 1, value], ["<%d, %d>" % [value - 1, value + 2], "<%d, %d>" % [value, value], "<%d, %d>" % [value + 1, value + 2]])
            16:
                match posmod(index, 3):
                    0: _record(topic, "An investment of $%d earns 5%% simple interest for 2 years. What is the interest?" % (100 * value), "$%d" % (10 * value), ["$%d" % (5 * value), "$%d" % (100 * value + 10 * value), "$%d" % (50 * value)])
                    1: _record(topic, "A population of %d grows by 10%% once. What is the new population?" % (10 * value), str(11 * value), [str(10 * value + 10), str(value), str(20 * value)])
                    _: _record(topic, "A car travels %d miles at %d mph. How long does the trip take?" % [10 * value, value], "10 hours", ["%d hours" % (value + 1), "%d hours" % (10 * value), "1 hour"])
            _:
                match posmod(index, 3):
                    0: _record(topic, "For f(x) = x² - %dx, where is f'(x) = 0?" % (2 * value), "x = %d" % value, ["x = 0", "x = %d" % (2 * value), "x = -%d" % value])
                    1: _record(topic, "A rectangle has perimeter %d. Which dimensions maximize its area?" % (4 * value), "%d by %d" % [value, value], ["%d by %d" % [value - 1, value + 1], "%d by %d" % [1, 2 * value - 2], "%d by %d" % [value - 2, value + 2]])
                    _: _record(topic, "If f'(x) is positive on (%d, %d), what is f doing there?" % [value, value + 3], "increasing", ["decreasing", "constant", "undefined"])

func _power_x(exponent: int) -> String:
    return "x%s" % _superscript(exponent)

func _superscript(number: int) -> String:
    var superscripts := {"0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹"}
    var rendered := ""
    for character in str(number):
        rendered += superscripts[character]
    return rendered