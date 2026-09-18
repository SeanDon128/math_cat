extends SceneTree

const OUTPUT_PATH := "res://data/questions/grade_10.json"

var records: Array[Dictionary] = []
var question_index := 0

func _init() -> void:
    _add_linear_equations(40)
    _add_multi_step_equations(40)
    _add_variables_both_sides(30)
    _add_graphing_linear_equations(35)
    _add_slope_intercept_form(30)
    _add_systems(40)
    _add_inequalities(35)
    _add_quadratic_equations(50)
    _add_quadratic_functions(40)
    _add_polynomial_operations(35)
    _add_factoring(50)
    _add_function_notation(25)
    _add_function_evaluation(25)
    _add_function_interpretation(25)
    _add_word_problems(40)
    _add_real_world_modeling(30)
    assert(records.size() == 570, "Grade 10 question bank must contain 570 records.")
    var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
    assert(file != null, "Unable to write Grade 10 question bank.")
    file.store_string(JSON.stringify(records, "  ") + "\n")
    file.close()
    print("Generated %d Grade 10 questions at %s" % [records.size(), OUTPUT_PATH])
    quit()

func _record(topic: String, prompt: String, correct: String, wrong: Array[String]) -> void:
    var choices: Array[String] = []
    for answer in wrong:
        if answer != correct and not choices.has(answer):
            choices.append(answer)
    assert(choices.size() >= 3, "Grade 10 choices must be distinct: %s" % prompt)
    choices.resize(3)
    choices.insert(posmod(question_index, 4), correct)
    records.append({"grade": 10, "topic": topic, "difficulty": "medium" if posmod(question_index, 2) == 0 else "hard", "uses_pi": false, "question": prompt, "choices": choices, "correctAnswer": correct})
    question_index += 1

func _add_linear_equations(count: int) -> void:
    for index in range(count):
        var answer := index + 2
        var coefficient := 2 + posmod(index, 5)
        var constant := index + 3
        _record("Linear Equations", "Solve: %dx + %d = %d" % [coefficient, constant, coefficient * answer + constant], str(answer), [str(answer + constant), str(coefficient * answer), str(coefficient * answer + constant)])

func _add_multi_step_equations(count: int) -> void:
    for index in range(count):
        var answer := index + 2
        var multiplier := 2 + posmod(index, 4)
        var addend := index + 1
        var constant := 3 + posmod(index, 7)
        _record("Multi-Step Equations", "Solve: %d(%dx + %d) - %d = %d" % [multiplier, 2, addend, constant, multiplier * (2 * answer + addend) - constant], str(answer), [str(answer + addend), str(multiplier * answer), str(answer - constant)])

func _add_variables_both_sides(count: int) -> void:
    for index in range(count):
        var answer := index + 3
        var left := 4 + posmod(index, 4)
        var right := 1 + posmod(index, 3)
        var left_constant := index + 5
        _record("Variables on Both Sides", "Solve: %dx + %d = %dx + %d" % [left, left_constant, right, (left - right) * answer + left_constant], str(answer), [str(answer + left_constant), str(answer - left_constant), str(left * answer)])

func _add_graphing_linear_equations(count: int) -> void:
    for index in range(count):
        var slope := 2 + posmod(index, 5)
        var intercept := index - 12
        if posmod(index, 2) == 0:
            _record("Graphing Linear Equations", "For y = %dx + %d, which point is on the line?" % [slope, intercept], "(2, %d)" % (2 * slope + intercept), ["(2, %d)" % (2 * slope + intercept + 1), "(2, %d)" % (2 * slope + intercept - 1), "(1, %d)" % (slope + intercept)])
        else:
            _record("Graphing Linear Equations", "A line has slope %d and y-intercept %d. Which equation represents it?" % [slope, intercept], "y = %dx + %d" % [slope, intercept], ["y = %dx + %d" % [intercept, slope], "y = -%dx + %d" % [slope, intercept], "y = %dx - %d" % [slope, intercept]])

func _add_slope_intercept_form(count: int) -> void:
    for index in range(count):
        var slope := 2 + posmod(index, 4)
        var intercept := index - 10
        if posmod(index, 2) == 0:
            _record("Slope-Intercept Form", "Write a line with slope %d and y-intercept %d." % [slope, intercept], "y = %dx + %d" % [slope, intercept], ["y = %dx + %d" % [slope + 1, intercept], "y = -%dx + %d" % [slope, intercept], "y = %dx + %d" % [slope, intercept + 1]])
        else:
            _record("Slope-Intercept Form", "What is the y-intercept of %dy - %dx = %d?" % [2, 2 * slope, 2 * intercept], str(intercept), [str(intercept + slope + 1), str(intercept - slope - 1), str(intercept + 1)])

func _add_systems(count: int) -> void:
    for index in range(count):
        var x_value := index + 2
        var y_value := index + 4
        match posmod(index, 3):
            0:
                _record("Systems of Equations", "Solve x + y = %d and x - y = %d. Find x." % [x_value + y_value, x_value - y_value], str(x_value), [str(y_value), str(x_value + y_value), str(x_value - y_value)])
            1:
                _record("Systems of Equations", "Solve 2x + y = %d and x + y = %d. Find y." % [2 * x_value + y_value, x_value + y_value], str(y_value), [str(x_value), str(x_value + y_value), str(y_value - x_value)])
            _:
                _record("Systems of Equations", "Lines y = x + %d and y = -x + %d intersect at what x-value?" % [y_value - x_value, x_value + y_value], str(x_value), [str(y_value), str(y_value - x_value), str(x_value + y_value)])

func _add_inequalities(count: int) -> void:
    for index in range(count):
        var boundary := index + 3
        var multiplier := 2 + posmod(index, 4)
        if posmod(index, 2) == 0:
            _record("Linear Inequalities", "Solve: %dx - %d <= %d" % [multiplier, index + 2, multiplier * boundary - index - 2], "x <= %d" % boundary, ["x >= %d" % boundary, "x <= %d" % (multiplier * boundary), "x <= %d" % (boundary - index - 2)])
        else:
            _record("Linear Inequalities", "Solve: -%dx > -%d" % [multiplier, multiplier * boundary], "x < %d" % boundary, ["x > %d" % boundary, "x < %d" % (multiplier * boundary), "x > -%d" % boundary])

func _add_quadratic_equations(count: int) -> void:
    for index in range(count):
        var root_one := index + 1
        var root_two := index + 3
        if posmod(index, 2) == 0:
            _record("Solving Quadratic Equations", "Solve: (x - %d)(x - %d) = 0. What is the smaller root?" % [root_one, root_two], str(root_one), [str(root_two), str(-root_one), str(root_one + root_two)])
        else:
            _record("Solving Quadratic Equations", "Which value is a root of x² - %dx + %d = 0?" % [root_one + root_two, root_one * root_two], str(root_two), [str(-root_two), str(root_one + root_two), str(root_one * root_two)])

func _add_quadratic_functions(count: int) -> void:
    for index in range(count):
        var h := index - 15
        var k := index + 2
        if posmod(index, 2) == 0:
            _record("Quadratic Functions", "What is the vertex of y = (x - %d)² + %d?" % [h, k], "(%d, %d)" % [h, k], ["(-%d, %d)" % [h, k], "(%d, -%d)" % [h, k], "(%d, %d)" % [k, h]])
        else:
            _record("Quadratic Functions", "What is the axis of symmetry of y = (x - %d)² + %d?" % [h, k], "x = %d" % h, ["y = %d" % k, "x = %d" % k, "x = -%d" % h])

func _add_polynomial_operations(count: int) -> void:
    for index in range(count):
        var first := index + 2
        var second := index + 4
        match posmod(index, 3):
            0:
                _record("Polynomial Operations", "Simplify: (%dx² + %dx) + (%dx² - %dx)" % [first, second, second, first], "%dx² + %dx" % [first + second, second - first], ["%dx² + %dx" % [first * second, second - first], "%dx² + %dx" % [first + second, first + second], "%dx²" % (first + second)])
            1:
                _record("Polynomial Operations", "Simplify: (%dx² + %dx) - (%dx² - %dx)" % [first, second, second, first], "%dx² + %dx" % [first - second, first + second], ["%dx² + %dx" % [first + second, second - first], "%dx²" % (first - second), "%dx" % (first + second)])
            _:
                _record("Polynomial Operations", "Expand: (x + %d)(x + %d)" % [first, second], "x² + %dx + %d" % [first + second, first * second], ["x² + %dx + %d" % [first * second, first + second], "x² + %dx + %d" % [second - first, first * second], "x² + %d" % (first * second)])

func _add_factoring(count: int) -> void:
    for index in range(count):
        var first := index + 2
        var second := index + 5
        if posmod(index, 2) == 0:
            _record("Factoring Polynomials", "Factor: x² + %dx + %d" % [first + second, first * second], "(x + %d)(x + %d)" % [first, second], ["(x - %d)(x - %d)" % [first, second], "(x + %d)(x - %d)" % [first, second], "(x + %d)²" % (first + second)])
        else:
            _record("Factoring Polynomials", "Factor: %dx + %d" % [first, first * second], "%d(x + %d)" % [first, second], ["%d(x + %d)" % [second, first], "x(%d + %d)" % [first, second], "%d(x - %d)" % [first, second]])

func _add_function_notation(count: int) -> void:
    for index in range(count):
        var multiplier := 2 + posmod(index, 5)
        var constant := index - 8
        var input := index + 2
        var result := multiplier * input + constant
        _record("Function Notation", "If f(x) = %dx + %d, find f(%d)." % [multiplier, constant, input], str(result), [str(result + 1), str(result - 1), str(result + multiplier)])

func _add_function_evaluation(count: int) -> void:
    for index in range(count):
        var input := index + 2
        var constant := index - 5
        var result := input * input - constant
        _record("Function Evaluation", "If g(x) = x² - %d, find g(%d)." % [constant, input], str(result), [str(result + 1), str(result - 1), str(result + input)])

func _add_function_interpretation(count: int) -> void:
    for index in range(count):
        var start := 10 + index
        var rate := 2 + posmod(index, 5)
        var result := 3 * rate + start
        _record("Function Interpretation", "A table follows y = %dx + %d. What is y when x = 3?" % [rate, start], str(result), [str(result - 1), str(result + 1), str(start + rate)])

func _add_word_problems(count: int) -> void:
    for index in range(count):
        var age := index + 10
        var years := 2 + posmod(index, 5)
        if posmod(index, 2) == 0:
            _record("Algebra Word Problems", "Ava is %d. In %d years, how old will Ava be?" % [age, years], str(age + years), [str(age - years), str(age * years), str(years)])
        else:
            var rate := 3 + posmod(index, 4)
            var time := index + 2
            _record("Algebra Word Problems", "A car travels %d miles per hour for %d hours. How far does it travel?" % [rate, time], "%d miles" % (rate * time), ["%d miles" % (rate + time), "%d miles" % (rate - time), "%d miles" % (rate * time + rate)])

func _add_real_world_modeling(count: int) -> void:
    for index in range(count):
        var start := 100 + index * 10
        var change := 5 + posmod(index, 6)
        var periods := index + 2
        if posmod(index, 2) == 0:
            _record("Real-World Modeling", "A business starts with $%d and earns $%d each day. What is the value after %d days?" % [start, change, periods], "$%d" % (start + change * periods), ["$%d" % (start * change * periods), "$%d" % (start + change + periods), "$%d" % (change * periods)])
        else:
            _record("Real-World Modeling", "A population is %d and grows by %d each year. What is the population after %d years?" % [start, change, periods], str(start + change * periods), [str(start * change * periods), str(start + change + periods), str(change * periods)])