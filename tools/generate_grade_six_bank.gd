extends SceneTree

const OUTPUT_PATH := "res://data/questions/grade_6.json"

var records: Array[Dictionary] = []
var question_index := 0

func _init() -> void:
    _add_fraction_multiplication()
    _add_fraction_division()
    _add_decimal_operations()
    _add_prism_volume()
    _add_ratios()
    _add_proportional_relationships()
    _add_negative_numbers()
    _add_algebraic_expressions()
    _add_one_step_equations()
    _add_statistics()
    _add_coordinate_plane_basics()
    _add_geometry_foundations()
    assert(records.size() == 330, "Grade 6 question bank must contain 330 records.")
    var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
    assert(file != null, "Unable to write Grade 6 question bank.")
    file.store_string(JSON.stringify(records, "  ") + "\n")
    file.close()
    print("Generated %d Grade 6 questions at %s" % [records.size(), OUTPUT_PATH])
    quit()

func _record(topic: String, topic_index: int, topic_count: int, question: String, correct_answer: String, incorrect_answers: Array[String]) -> void:
    var choices: Array[String] = []
    for answer in incorrect_answers:
        if answer != correct_answer and not choices.has(answer):
            choices.append(answer)
    for fallback in ["Not enough information", "None of these", "Cannot be determined"]:
        if choices.size() >= 3:
            break
        if fallback != correct_answer and not choices.has(fallback):
            choices.append(fallback)
    assert(choices.size() >= 3, "Grade 6 question needs three distinct incorrect answers: %s" % question)
    choices.resize(3)
    choices.insert(posmod(question_index, 4), correct_answer)
    assert(choices.size() == 4 and choices.duplicate().size() == choices.size(), "Grade 6 choices must be unique.")
    records.append({
        "grade": 6,
        "topic": topic,
        "difficulty": _difficulty(topic_index, topic_count),
        "uses_pi": false,
        "question": question,
        "choices": choices,
        "correctAnswer": correct_answer
    })
    question_index += 1

func _difficulty(topic_index: int, topic_count: int) -> String:
    var easy_count := topic_count / 5
    var hard_start := topic_count - easy_count
    if topic_index < easy_count:
        return "easy"
    if topic_index >= hard_start:
        return "hard"
    return "medium"

func _add_fraction_multiplication() -> void:
    var factors := [[1, 2, 2, 3], [2, 3, 3, 4], [3, 4, 2, 5], [4, 5, 3, 8], [5, 6, 3, 10], [2, 5, 5, 6], [3, 5, 4, 9], [7, 8, 2, 7], [5, 9, 3, 10], [4, 7, 7, 12], [3, 8, 4, 5], [5, 12, 6, 7], [7, 10, 5, 14], [8, 15, 9, 16], [11, 12, 3, 11]]
    for index in range(factors.size()):
        var values: Array = factors[index]
        var numerator_a: int = values[0]
        var denominator_a: int = values[1]
        var numerator_b: int = values[2]
        var denominator_b: int = values[3]
        var correct := _fraction(numerator_a * numerator_b, denominator_a * denominator_b)
        _record("Fraction Multiplication", index, 15, "(%d/%d) x (%d/%d) =" % [numerator_a, denominator_a, numerator_b, denominator_b], correct, [_fraction(numerator_a + numerator_b, denominator_a + denominator_b), _fraction(numerator_a * denominator_b, denominator_a * numerator_b), _fraction(numerator_a * numerator_b, denominator_a + denominator_b), _fraction(numerator_a * numerator_b + 1, denominator_a * denominator_b)])

func _add_fraction_division() -> void:
    var factors := [[1, 2, 1, 4], [2, 3, 1, 2], [3, 4, 2, 5], [4, 5, 2, 3], [5, 6, 1, 3], [2, 5, 1, 10], [3, 5, 2, 7], [7, 8, 1, 2], [5, 9, 5, 6], [4, 7, 2, 3], [3, 8, 3, 10], [5, 12, 1, 4], [7, 10, 2, 5], [8, 15, 4, 9], [11, 12, 11, 18]]
    for index in range(factors.size()):
        var values: Array = factors[index]
        var numerator_a: int = values[0]
        var denominator_a: int = values[1]
        var numerator_b: int = values[2]
        var denominator_b: int = values[3]
        var correct := _fraction(numerator_a * denominator_b, denominator_a * numerator_b)
        _record("Fraction Division", index, 15, "(%d/%d) / (%d/%d) =" % [numerator_a, denominator_a, numerator_b, denominator_b], correct, [_fraction(numerator_a * numerator_b, denominator_a * denominator_b), _fraction(numerator_b * denominator_a, denominator_b * numerator_a), _fraction(numerator_a + numerator_b, denominator_a + denominator_b), _fraction(numerator_a * denominator_b + 1, denominator_a * numerator_b)])

func _add_decimal_operations() -> void:
    var problems := [["2.4", "+", "1.35", "3.75", "2.99", "3.65", "4.75"], ["5.60", "-", "2.75", "2.85", "3.85", "2.75", "8.35"], ["1.25", "+", "0.80", "2.05", "1.33", "2.30", "0.45"], ["7.2", "-", "3.48", "3.72", "4.72", "3.62", "10.68"], ["0.6", "x", "0.4", "0.24", "2.4", "0.10", "1.0"], ["1.5", "x", "0.8", "1.2", "12", "0.23", "2.3"], ["3.75", "+", "2.06", "5.81", "5.71", "1.69", "6.81"], ["9.00", "-", "4.67", "4.33", "5.33", "4.43", "13.67"], ["2.4", "x", "0.5", "1.2", "12", "0.7", "2.9"], ["6.35", "+", "0.49", "6.84", "6.74", "5.86", "7.84"], ["8.20", "-", "1.95", "6.25", "7.25", "6.15", "10.15"], ["0.75", "x", "0.6", "0.45", "4.5", "0.15", "1.35"], ["4.08", "+", "3.92", "8.00", "7.90", "0.16", "8.90"], ["10.0", "-", "6.47", "3.53", "4.53", "3.43", "16.47"], ["1.25", "x", "0.4", "0.5", "5", "0.09", "1.65"]]
    for index in range(problems.size()):
        var values: Array = problems[index]
        _record("Decimal Operations", index, 15, "%s %s %s =" % [values[0], values[1], values[2]], values[3], [values[4], values[5], values[6]])

func _add_prism_volume() -> void:
    for index in range(15):
        var length := 3 + posmod(index, 5)
        var width := 2 + posmod(index * 2, 4)
        var height := 2 + posmod(index * 3, 5)
        var volume := length * width * height
        if index < 10:
            _record("Volume of Rectangular Prisms", index, 15, "A prism is %d by %d by %d units. What is its volume?" % [length, width, height], "%d cubic units" % volume, ["%d cubic units" % (length + width + height), "%d cubic units" % (length * width + height), "%d square units" % volume, "%d cubic units" % (volume + length)])
        else:
            var missing := volume / length
            _record("Volume of Rectangular Prisms", index, 15, "A prism has volume %d cubic units, length %d, and width %d. What is its height?" % [volume, length, width], "%d units" % height, ["%d units" % missing, "%d units" % (height + 1), "%d units" % (length + width), "%d units" % (volume - length * width)])

func _add_ratios() -> void:
    for index in range(40):
        var first := 2 + index
        var second := 3 + index
        if index < 8:
            _record("Ratios", index, 40, "There are %d red tiles and %d blue tiles. What is the ratio of red to blue?" % [first, second], "%d:%d" % [first, second], ["%d:%d" % [second, first], "%d:%d" % [first, first + second], "%d:%d" % [first + second, second]])
        elif index < 20:
            var scale := 2 + posmod(index, 4)
            _record("Ratios", index, 40, "Simplify the ratio %d:%d." % [first * scale, second * scale], "%d:%d" % [first, second], ["%d:%d" % [second, first], "%d:%d" % [first * scale, second], "%d:%d" % [first + second, scale]])
        elif index < 32:
            var total := first + second
            _record("Ratios", index, 40, "A class has %d students who walk and %d who ride. What is the ratio of walkers to all students?" % [first, second], "%d:%d" % [first, total], ["%d:%d" % [first, second], "%d:%d" % [second, total], "%d:%d" % [total, first]])
        else:
            var groups := 2 + posmod(index, 5)
            _record("Ratios", index, 40, "A paint mix uses %d cups blue for every %d cups white. How many cups of blue are needed for %d cups of white?" % [first, second, second * groups], "%d cups" % (first * groups), ["%d cups" % (second * groups), "%d cups" % (first + groups), "%d cups" % (first * groups + second)])

func _add_proportional_relationships() -> void:
    for index in range(40):
        var units := 2 + posmod(index, 5)
        var unit_cost := 2 + posmod(index * 3, 7)
        var target := 3 + posmod(index * 2, 6)
        if index < 8:
            _record("Proportional Relationships", index, 40, "%d pencils cost $%d. What is the cost of 1 pencil?" % [units, units * unit_cost], "$%d" % unit_cost, ["$%d" % (units * unit_cost), "$%d" % (unit_cost + 1), "$%d" % (unit_cost - 1)])
        elif index < 20:
            _record("Proportional Relationships", index, 40, "%d notebooks cost $%d. At the same rate, how much do %d notebooks cost?" % [units, units * unit_cost, target], "$%d" % (target * unit_cost), ["$%d" % (units * unit_cost + target), "$%d" % (target + unit_cost), "$%d" % (units * target)])
        elif index < 32:
            var multiplier := 2 + posmod(index, 4)
            _record("Proportional Relationships", index, 40, "A recipe uses %d cups of flour for %d batches. How many cups are needed for %d batches?" % [units, 1, multiplier], "%d cups" % (units * multiplier), ["%d cups" % (units + multiplier), "%d cups" % multiplier, "%d cups" % (units * multiplier + 1)])
        else:
            var rate := 3 + posmod(index, 6)
            var hours := 2 + posmod(index * 2, 5)
            _record("Proportional Relationships", index, 40, "A cyclist rides %d miles each hour. How far in %d hours at the same rate?" % [rate, hours], "%d miles" % (rate * hours), ["%d miles" % (rate + hours), "%d miles" % (rate * hours + rate), "%d miles" % hours])

func _add_negative_numbers() -> void:
    for index in range(40):
        var left := 2 + posmod(index * 3, 8)
        var right := 1 + posmod(index * 5, 7)
        if index < 8:
            var negative := -left
            _record("Negative Numbers", index, 40, "What is the opposite of %d?" % negative, str(left), [str(-left), "0", str(left + 1)])
        elif index < 20:
            var answer := -left + right
            _record("Negative Numbers", index, 40, "%d + %d =" % [-left, right], str(answer), [str(-left - right), str(left + right), str(left - right)])
        elif index < 32:
            var answer := left - (right + 2)
            _record("Negative Numbers", index, 40, "%d - %d =" % [left, right + 2], str(answer), [str(left + right + 2), str(-answer), str(left - right)])
        else:
            var first := -left
            var second := -(right + 2)
            var answer := first - second
            _record("Negative Numbers", index, 40, "%d - (%d) =" % [first, second], str(answer), [str(first + second), str(-left - (right + 2)), str(left + right + 2)])

func _add_algebraic_expressions() -> void:
    for index in range(40):
        var value := 2 + posmod(index, 8)
        var addend := 3 + posmod(index * 2, 9)
        var multiplier := 2 + posmod(index, 5)
        if index < 8:
            _record("Algebraic Expressions", index, 40, "If x = %d, what is x + %d?" % [value, addend], str(value + addend), [str(value * addend), str(addend), str(value)])
        elif index < 20:
            _record("Algebraic Expressions", index, 40, "If n = %d, what is %dn?" % [value, multiplier], str(value * multiplier), [str(value + multiplier), str(value * multiplier + multiplier), str(multiplier)])
        elif index < 32:
            _record("Algebraic Expressions", index, 40, "If y = %d, what is %dy - %d?" % [value, multiplier, addend], str(multiplier * value - addend), [str(multiplier * (value - addend)), str(multiplier * value + addend), str(value - addend)])
        else:
            _record("Algebraic Expressions", index, 40, "If a = %d and b = %d,\nwhat is 2a + b?" % [value, addend], str(2 * value + addend), [str(2 * (value + addend)), str(value + 2 * addend), str(value + addend)])

func _add_one_step_equations() -> void:
    for index in range(40):
        var solution := 2 + index
        var amount := 3 + posmod(index * 2, 8)
        var equation := ""
        var correct := ""
        var wrong: Array[String] = []
        match posmod(index, 4):
            0:
                equation = "x + %d = %d" % [amount, solution + amount]
                correct = str(solution)
                wrong = [str(solution + amount), str(amount), str(solution - 1)]
            1:
                equation = "x - %d = %d" % [amount, solution - amount]
                correct = str(solution)
                wrong = [str(solution - amount), str(solution + amount), str(amount)]
            2:
                equation = "%dx = %d" % [amount, solution * amount]
                correct = str(solution)
                wrong = [str(solution * amount), str(solution + amount), str(amount)]
            _:
                equation = "x / %d = %d" % [amount, solution]
                correct = str(solution * amount)
                wrong = [str(solution), str(solution + amount), str(solution * amount + amount)]
        _record("One-Step Equations", index, 40, "Solve for x: %s" % equation, correct, wrong)

func _add_statistics() -> void:
    for index in range(30):
        var first := 2 + index
        var second := first + 2
        var third := second + 2
        if index < 6:
            _record("Statistics", index, 30, "Find the mean: %d, %d, %d" % [first, second, third], str(second), [str(first), str(third), str(first + third)])
        elif index < 16:
            var fourth := third + 4
            _record("Statistics", index, 30, "Find the median: %d, %d, %d, %d, %d" % [fourth, first, second, third, second], str(second), [str(first), str(third), str(fourth)])
        elif index < 24:
            _record("Statistics", index, 30, "Find the mode: %d, %d, %d, %d, %d" % [first, second, second, third, third + 3], str(second), [str(first), str(third), "No mode"])
        else:
            var largest := third + 3
            _record("Statistics", index, 30, "Find the range: %d, %d, %d, %d" % [first, second, third, largest], str(largest - first), [str(largest), str(first), str(third - first)])

func _add_coordinate_plane_basics() -> void:
    for index in range(20):
        var x := 1 + index
        var y := 2 + index
        if index < 8:
            _record("Coordinate Plane Basics", index, 20, "A point is %d right and %d up from the origin. What is its ordered pair?" % [x, y], "(%d, %d)" % [x, y], ["(%d, %d)" % [y, x], "(-%d, %d)" % [x, y], "(%d, -%d)" % [x, y]])
        elif index < 16:
            _record("Coordinate Plane Basics", index, 20, "In the ordered pair (%d, %d), what is the y-coordinate?" % [x, y], str(y), [str(x), str(x + y), "0"])
        else:
            _record("Coordinate Plane Basics", index, 20, "Which point with x-coordinate %d is on the x-axis?" % x, "(%d, 0)" % x, ["(0, %d)" % y, "(%d, %d)" % [x, y], "(-%d, %d)" % [x, y]])

func _add_geometry_foundations() -> void:
    for index in range(20):
        var base := 4 + posmod(index, 6)
        var height := 3 + posmod(index * 2, 5)
        if index < 4:
            _record("Geometry Foundations", index, 20, "What is the area of a triangle with base %d and height %d?" % [base, height], "%d square units" % (base * height / 2), ["%d square units" % (base * height), "%d square units" % (base + height), "%d square units" % (base * height / 2 + base)])
        elif index < 12:
            var length := base + 2
            _record("Geometry Foundations", index, 20, "What is the perimeter of a rectangle with length %d and width %d?" % [length, height], "%d units" % (2 * length + 2 * height), ["%d units" % (length * height), "%d units" % (length + height), "%d units" % (2 * length + height)])
        elif index < 16:
            var perpendicular_contexts := ["A vertical line and a horizontal line meet. They are", "The sides that meet at a square's corner are", "Two streets cross to make four 90-degree angles. The streets are", "A line through (0, 0) to (0, 4) meets a line through (0, 0) to (4, 0). They are"]
            _record("Geometry Foundations", index, 20, "%s" % perpendicular_contexts[index - 12], "perpendicular", ["parallel", "congruent", "intersecting at 45 degrees"])
        else:
            _record("Geometry Foundations", index, 20, "A triangle has angles of %d degrees and %d degrees. What is the third angle?" % [base * 10, height * 10], "%d degrees" % (180 - base * 10 - height * 10), ["%d degrees" % (base * 10 + height * 10), "%d degrees" % (180 + base * 10 - height * 10), "%d degrees" % (90 - height * 10)])

func _fraction(numerator: int, denominator: int) -> String:
    var divisor := _gcd(numerator, denominator)
    return "%d/%d" % [numerator / divisor, denominator / divisor]

func _gcd(first: int, second: int) -> int:
    var left: int = abs(first)
    var right: int = abs(second)
    while right != 0:
        var remainder := posmod(left, right)
        left = right
        right = remainder
    return max(left, 1)