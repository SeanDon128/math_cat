extends SceneTree

const OUTPUT_PATH := "res://data/questions/grade_8.json"

var records: Array[Dictionary] = []
var question_index := 0

func _init() -> void:
    _add_percentages(15)
    _add_rational_numbers(15)
    _add_two_step_equations(15)
    _add_two_step_inequalities(10)
    _add_probability(10)
    _add_area_and_volume(10)
    _add_geometry(10)
    _add_scale_drawings(10)
    _add_linear_equations(50)
    _add_linear_functions(40)
    _add_graphing(40)
    _add_slope(40)
    _add_pythagorean_theorem(40)
    _add_systems(40)
    _add_exponents(40)
    _add_scientific_notation(30)
    _add_transformations(20)
    assert(records.size() == 435, "Grade 8 question bank must contain 435 records.")
    var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
    assert(file != null, "Unable to write Grade 8 question bank.")
    file.store_string(JSON.stringify(records, "  ") + "\n")
    file.close()
    print("Generated %d Grade 8 questions at %s" % [records.size(), OUTPUT_PATH])
    quit()

func _record(topic: String, index: int, count: int, prompt: String, correct: String, wrong: Array[String], uses_pi: bool = false) -> void:
    var choices: Array[String] = []
    for answer in wrong:
        if answer != correct and not choices.has(answer):
            choices.append(answer)
    var fallback := 1
    while choices.size() < 3:
        var answer := str(fallback)
        if answer != correct and not choices.has(answer):
            choices.append(answer)
        fallback += 1
    choices.resize(3)
    choices.insert(posmod(question_index, 4), correct)
    assert(choices.duplicate().size() == 4, "Grade 8 choices must be distinct: %s" % prompt)
    records.append({"grade": 8, "topic": topic, "difficulty": _difficulty(index, count), "uses_pi": uses_pi, "question": prompt, "choices": choices, "correctAnswer": correct})
    question_index += 1

func _difficulty(index: int, count: int) -> String:
    var easy_count := count / 5
    if index < easy_count:
        return "easy"
    if index >= count - easy_count:
        return "hard"
    return "medium"

func _add_percentages(count: int) -> void:
    for index in range(count):
        var percent := 10 + index * 5
        var number := 40 + index * 4
        var value := percent * number / 100.0
        _record("Percentages", index, count, "What is %d%% of %d?" % [percent, number], str(value), [str(percent), str(number / 10), str(number - value)])

func _add_rational_numbers(count: int) -> void:
    for index in range(count):
        var left := index + 3
        var right := index + 2
        if posmod(index, 3) == 0:
            _record("Rational Numbers", index, count, "-%d + %d.5 =" % [left, right], _decimal(right + 0.5 - left), [_decimal(-left - right - 0.5), _decimal(left + right + 0.5), _decimal(left - right - 0.5)])
        elif posmod(index, 3) == 1:
            _record("Rational Numbers", index, count, "(%d/4) + (%d/4) =" % [left, right], _fraction(left + right, 4), [_fraction(left * right, 16), _fraction(left + right, 8), _fraction(left - right, 4)])
        else:
            _record("Rational Numbers", index, count, "-%d - %d =" % [left, right], str(-left - right), [str(-left + right), str(left - right), str(left + right)])

func _add_two_step_equations(count: int) -> void:
    for index in range(count):
        var solution := index + 2
        var multiplier := 2 + posmod(index, 4)
        var addend := index + 3
        _record("Two-Step Equations", index, count, "Solve: %dx + %d = %d" % [multiplier, addend, multiplier * solution + addend], str(solution), [str(multiplier * solution + addend), str(solution + addend), str(multiplier * solution)])

func _add_two_step_inequalities(count: int) -> void:
    for index in range(count):
        var boundary := index + 3
        var multiplier := 2 + posmod(index, 3)
        var addend := index + 2
        _record("Two-Step Inequalities", index, count, "Solve: %dx - %d <= %d" % [multiplier, addend, multiplier * boundary - addend], "x <= %d" % boundary, ["x >= %d" % boundary, "x <= %d" % (multiplier * boundary), "x <= %d" % (boundary - addend)])

func _add_probability(count: int) -> void:
    var events := [["A fair die is rolled. What is P(an even number)?", "1/2", "1/6", "1/3", "2/3"], ["Two fair coins are flipped. What is P(2 heads)?", "1/4", "1/2", "3/4", "1/3"], ["Two fair coins are flipped. What is P(at least 1 head)?", "3/4", "1/2", "1/4", "1"], ["A bag has 3 red and 5 blue marbles. What is P(red)?", "3/8", "5/8", "3/5", "8/3"], ["A spinner has 8 equal sections; 3 are green. What is P(green)?", "3/8", "5/8", "3/5", "1/8"], ["A fair die is rolled. What is P(a number greater than 4)?", "1/3", "1/2", "1/6", "2/3"], ["Three fair coins are flipped. What is P(3 tails)?", "1/8", "1/2", "1/4", "3/8"], ["A bag has 4 yellow and 6 purple marbles. What is P(purple)?", "3/5", "2/5", "6/4", "1/6"], ["A spinner has 10 equal sections; 4 are stars. What is P(star)?", "2/5", "3/5", "4/5", "1/10"], ["Four fair coins are flipped. What is P(no heads)?", "1/16", "1/4", "1/8", "1/2"]]
    for index in range(count):
        var event: Array = events[index]
        _record("Probability", index, count, event[0], event[1], [event[2], event[3], event[4]])

func _add_area_and_volume(count: int) -> void:
    for index in range(count):
        var length := index + 5
        var width := 3 + posmod(index, 4)
        var height := 2 + posmod(index, 3)
        if index < 5:
            _record("Area and Volume", index, count, "A prism is %d by %d by %d. What is its volume?" % [length, width, height], "%d cubic units" % (length * width * height), ["%d cubic units" % (length + width + height), "%d square units" % (length * width * height), "%d cubic units" % (length * width + height)])
        else:
            _record("Area and Volume", index, count, "A composite shape has rectangles %d by %d and %d by %d. What is its area?" % [length, width, height, width], "%d square units" % ((length + height) * width), ["%d square units" % (length * width), "%d square units" % (length * height), "%d square units" % (length + height + width)])

func _add_geometry(count: int) -> void:
    for index in range(count):
        var radius := index + 2
        if index < 5:
            _record("Geometry", index, count, "Use pi = 3.14. Find the area of a circle with radius %d." % radius, _decimal(3.14 * radius * radius), [_decimal(2.0 * 3.14 * radius), _decimal(3.14 * radius), str(radius * radius)], true)
        else:
            var first_angle := 30 + index * 4
            _record("Geometry", index, count, "A triangle has angles %d and %d degrees. Find the third angle." % [first_angle, 40], "%d degrees" % (140 - first_angle), ["%d degrees" % (first_angle + 40), "%d degrees" % (90 - first_angle), "%d degrees" % (180 + first_angle - 40)])

func _add_scale_drawings(count: int) -> void:
    for index in range(count):
        var scale := 2 + posmod(index, 4)
        var drawing := index + 3
        _record("Scale Drawings", index, count, "A map scale is 1 cm : %d km. What distance is %d cm?" % [scale, drawing], "%d km" % (scale * drawing), ["%d km" % (scale + drawing), "%d km" % scale, "%d km" % (scale * drawing + scale)])

func _add_linear_equations(count: int) -> void:
    for index in range(count):
        var solution := index + 2
        var multiplier := 2 + posmod(index, 5)
        var addend := 3 + posmod(index, 8)
        match posmod(index, 4):
            0: _record("Linear Equations", index, count, "Solve for x: %dx + %d = %d" % [multiplier, addend, multiplier * solution + addend], str(solution), [str(solution + addend), str(multiplier * solution), str(multiplier * solution + addend)])
            1: _record("Linear Equations", index, count, "Solve for x: %dx - %d = %d" % [multiplier, addend, multiplier * solution - addend], str(solution), [str(solution - addend), str(solution + addend), str(multiplier * solution - addend)])
            2: _record("Linear Equations", index, count, "Solve for x: %d(x + %d) = %d" % [multiplier, addend, multiplier * (solution + addend)], str(solution), [str(solution + addend), str(multiplier * solution), str(solution * multiplier + addend)])
            _: _record("Linear Equations", index, count, "Solve for x: %dx + %d = %dx + %d" % [multiplier, addend, multiplier - 1, solution + addend], str(solution), [str(solution + addend), str(multiplier), str(addend)])

func _add_linear_functions(count: int) -> void:
    for index in range(count):
        var slope := 2 + posmod(index, 5)
        var intercept := index - 5
        var input := index + 2
        if posmod(index, 2) == 0:
            _record("Linear Functions", index, count, "For y = %dx + %d, find y when x = %d." % [slope, intercept, input], str(slope * input + intercept), [str(slope + input + intercept), str(slope * input), str(input + intercept)])
        else:
            _record("Linear Functions", index, count, "For y = %dx + %d, what is the y-intercept?" % [slope, intercept], str(intercept), [str(slope), str(slope + intercept), "0"])

func _add_graphing(count: int) -> void:
    for index in range(count):
        var x := index + 1
        var y := index + 2
        match posmod(index, 4):
            0: _record("Graphing and Coordinate Plane", index, count, "Which ordered pair is %d right and %d up from the origin?" % [x, y], "(%d, %d)" % [x, y], ["(%d, %d)" % [y, x], "(-%d, %d)" % [x, y], "(%d, -%d)" % [x, y]])
            1: _record("Graphing and Coordinate Plane", index, count, "In (%d, %d), what is the x-coordinate?" % [x, y], str(x), [str(y), str(x + y), "0"])
            2: _record("Graphing and Coordinate Plane", index, count, "Which quadrant contains (%d, -%d)?" % [x, y], "Quadrant IV", ["Quadrant I", "Quadrant II", "Quadrant III"])
            _: _record("Graphing and Coordinate Plane", index, count, "Which point with y-coordinate %d lies on the y-axis?" % y, "(0, %d)" % y, ["(%d, 0)" % x, "(%d, %d)" % [x, y], "(-%d, %d)" % [x, y]])

func _add_slope(count: int) -> void:
    for index in range(count):
        var run := index + 2
        var slope := 1 + index
        var rise := run * slope
        match posmod(index, 4):
            0: _record("Slope and Rate of Change", index, count, "Find the slope from (0, 0) to (%d, %d)." % [run, rise], str(slope), [_fraction(run, rise), str(rise), str(-slope)])
            1: _record("Slope and Rate of Change", index, count, "Find the slope from (0, %d) to (%d, 0)." % [rise, run], "-%s" % _fraction(rise, run), [_fraction(rise, run), "-%s" % _fraction(run, rise), str(rise - run)])
            2: _record("Slope and Rate of Change", index, count, "A line rises %d for every run of %d. What is its slope?" % [rise, run], str(slope), [_fraction(run, rise), str(rise), str(-slope)])
            _: _record("Slope and Rate of Change", index, count, "What is the slope of y = %d?" % rise, "0", ["undefined", str(rise), "1"])

func _add_pythagorean_theorem(count: int) -> void:
    for index in range(count):
        var scale := index + 1
        var a := 3 * scale
        var b := 4 * scale
        var c := 5 * scale
        if posmod(index, 2) == 0:
            _record("Pythagorean Theorem", index, count, "A right triangle has legs %d and %d. Find its hypotenuse." % [a, b], str(c), [str(a + b), str(a * a + b * b), str(c - 1)])
        else:
            _record("Pythagorean Theorem", index, count, "A right triangle has hypotenuse %d and one leg %d. Find the other leg." % [c, a], str(b), [str(c - a), str(c + a), str(c * c - a * a)])

func _add_systems(count: int) -> void:
    for index in range(count):
        var x := index + 2
        var y := index + 3
        if posmod(index, 2) == 0:
            _record("Systems of Equations", index, count, "Solve: x + y = %d and x - y = -1. Find x." % [x + y], str(x), [str(y), str(x + y), str(x - y)])
        else:
            _record("Systems of Equations", index, count, "Solve: x + y = %d and x - y = -1. Find y." % [x + y], str(y), [str(x), str(x + y), str(y - x)])

func _add_exponents(count: int) -> void:
    for index in range(count):
        var base := 2 + posmod(index, 5)
        var exponent := 2 + posmod(index, 3)
        match posmod(index, 4):
            0: _record("Exponents", index, count, "What is %s?" % _power(base, exponent), str(pow(base, exponent)), [str(base * exponent), str(base + exponent), str(pow(base, exponent - 1))])
            1: _record("Exponents", index, count, "Simplify: %s x %s" % [_power(base, exponent), _power(base, 2)], _power(base, exponent + 2), [_power(base, exponent * 2), _power(base * base, exponent + 2), _power(base, exponent)])
            2: _record("Exponents", index, count, "Simplify: %s / %s" % [_power(base, exponent + 2), _power(base, 2)], _power(base, exponent), [_power(base, exponent + 4), _power(base, 2), _power(base, exponent * 2)])
            _: _record("Exponents", index, count, "What is (%s)²?" % _power(base, exponent), _power(base, exponent * 2), [_power(base, exponent + 2), _power(base * base, exponent), _power(base, 2)])

func _add_scientific_notation(count: int) -> void:
    for index in range(count):
        var coefficient := 2 + index / 4
        var exponent := 3 + posmod(index, 4)
        var whole: int = coefficient * int(pow(10, exponent))
        if posmod(index, 2) == 0:
              _record("Scientific Notation", index, count, "Write %d in scientific notation." % whole, "%d x %s" % [coefficient, _power(10, exponent)], ["%d x %s" % [coefficient, _power(10, exponent - 1)], "%d x %s" % [coefficient * 10, _power(10, exponent)], "%d x %s" % [coefficient, _power(10, exponent + 1)]])
        else:
              _record("Scientific Notation", index, count, "What is %d x %s?" % [coefficient, _power(10, exponent)], str(whole), [str(coefficient * pow(10, exponent - 1)), str(coefficient * 10 * pow(10, exponent)), str(coefficient + exponent)])

func _add_transformations(count: int) -> void:
    for index in range(count):
        var x := index + 1
        var y := index + 2
        match posmod(index, 4):
            0: _record("Geometry Transformations", index, count, "Translate (%d, %d) right 3 and up 2." % [x, y], "(%d, %d)" % [x + 3, y + 2], ["(%d, %d)" % [x - 3, y + 2], "(%d, %d)" % [x + 3, y - 2], "(%d, %d)" % [y + 2, x + 3]])
            1: _record("Geometry Transformations", index, count, "Reflect (%d, %d) across the y-axis." % [x, y], "(-%d, %d)" % [x, y], ["(%d, -%d)" % [x, y], "(-%d, -%d)" % [x, y], "(%d, %d)" % [y, x]])
            2: _record("Geometry Transformations", index, count, "Reflect (%d, %d) across the x-axis." % [x, y], "(%d, -%d)" % [x, y], ["(-%d, %d)" % [x, y], "(-%d, -%d)" % [x, y], "(%d, %d)" % [y, x]])
            _: _record("Geometry Transformations", index, count, "Rotate (%d, %d) 90 degrees counterclockwise about the origin." % [x, y], "(-%d, %d)" % [y, x], ["(%d, -%d)" % [y, x], "(%d, %d)" % [y, x], "(-%d, -%d)" % [x, y]])

func _fraction(numerator: int, denominator: int) -> String:
    var divisor := _gcd(numerator, denominator)
    return "%d/%d" % [numerator / divisor, denominator / divisor]

func _decimal(value: float) -> String:
    return "%0.2f" % value

func _power(base: int, exponent: int) -> String:
    var superscripts := {"0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹", "-": "⁻"}
    var rendered_exponent := ""
    for character in str(exponent):
        rendered_exponent += superscripts[character]
    return "%d%s" % [base, rendered_exponent]

func _gcd(first: int, second: int) -> int:
    var left: int = abs(first)
    var right: int = abs(second)
    while right != 0:
        var remainder := posmod(left, right)
        left = right
        right = remainder
    return max(left, 1)