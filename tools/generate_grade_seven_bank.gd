extends SceneTree

const OUTPUT_PATH := "res://data/questions/grade_7.json"

var records: Array[Dictionary] = []
var question_index := 0

func _init() -> void:
    _add_ratios()
    _add_proportional_relationships()
    _add_negative_numbers()
    _add_algebraic_expressions()
    _add_one_step_equations()
    _add_statistics()
    _add_percentages()
    _add_rational_numbers()
    _add_two_step_equations()
    _add_two_step_inequalities()
    _add_probability()
    _add_area_and_volume()
    _add_geometry()
    _add_scale_drawings()
    assert(records.size() == 410, "Grade 7 question bank must contain 410 records.")
    var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
    assert(file != null, "Unable to write Grade 7 question bank.")
    file.store_string(JSON.stringify(records, "  ") + "\n")
    file.close()
    print("Generated %d Grade 7 questions at %s" % [records.size(), OUTPUT_PATH])
    quit()

func _record(topic: String, topic_index: int, topic_count: int, question: String, correct: String, wrong: Array[String], uses_pi: bool = false) -> void:
    var choices: Array[String] = []
    for answer in wrong:
        if answer != correct and not choices.has(answer):
            choices.append(answer)
    var fallback := 1
    while choices.size() < 3:
        var answer := "%d" % fallback
        if answer != correct and not choices.has(answer):
            choices.append(answer)
        fallback += 1
    choices.resize(3)
    choices.insert(posmod(question_index, 4), correct)
    assert(choices.duplicate().size() == choices.size(), "Grade 7 choices must be distinct: %s" % question)
    records.append({"grade": 7, "topic": topic, "difficulty": _difficulty(topic_index, topic_count), "uses_pi": uses_pi, "question": question, "choices": choices, "correctAnswer": correct})
    question_index += 1

func _difficulty(topic_index: int, topic_count: int) -> String:
    var easy_count := topic_count / 5
    if topic_index < easy_count:
        return "easy"
    if topic_index >= topic_count - easy_count:
        return "hard"
    return "medium"

func _add_ratios() -> void:
    for index in range(15):
        var red := index + 2
        var blue := index + 3
        if index < 5:
            _record("Ratios", index, 15, "What is the ratio of %d red tiles to %d blue tiles?" % [red, blue], "%d:%d" % [red, blue], ["%d:%d" % [blue, red], "%d:%d" % [red, red + blue], "%d:%d" % [red + blue, blue]])
        elif index < 10:
            var scale := index - 2
            _record("Ratios", index, 15, "Simplify the ratio %d:%d." % [red * scale, blue * scale], "%d:%d" % [red, blue], ["%d:%d" % [blue, red], "%d:%d" % [red * scale, blue], "%d:%d" % [red + blue, scale]])
        else:
            var groups := index - 7
            _record("Ratios", index, 15, "A mix uses %d cups paint for %d cups water. How much paint for %d cups water?" % [red, blue, blue * groups], "%d cups" % (red * groups), ["%d cups" % (blue * groups), "%d cups" % (red + groups), "%d cups" % (red * groups + blue)])

func _add_proportional_relationships() -> void:
    for index in range(15):
        var rate := index + 2
        var amount := index + 3
        if index < 5:
            _record("Proportional Relationships", index, 15, "%d notebooks cost $%d. What is the unit price?" % [amount, amount * rate], "$%d" % rate, ["$%d" % (amount * rate), "$%d" % amount, "$%d" % (rate + 1)])
        elif index < 10:
            _record("Proportional Relationships", index, 15, "At $%d each, what do %d tickets cost?" % [rate, amount], "$%d" % (rate * amount), ["$%d" % (rate + amount), "$%d" % rate, "$%d" % (rate * amount + rate)])
        else:
            _record("Proportional Relationships", index, 15, "A car travels %d miles per hour. How far in %d hours?" % [rate, amount], "%d miles" % (rate * amount), ["%d miles" % (rate + amount), "%d miles" % amount, "%d miles" % (rate * amount + rate)])

func _add_negative_numbers() -> void:
    for index in range(15):
        var left := index + 3
        var right := index + 2
        if index < 5:
            _record("Negative Numbers", index, 15, "-%d + %d =" % [left, right], str(-left + right), [str(-left - right), str(left + right), str(left - right)])
        elif index < 10:
            _record("Negative Numbers", index, 15, "%d - (%d) =" % [left, -right], str(left + right), [str(left - right), str(-left - right), str(right - left)])
        else:
            _record("Negative Numbers", index, 15, "Which number is greater: -%d or -%d?" % [left, right], "-%d" % right, ["-%d" % left, "They are equal", "%d" % left])

func _add_algebraic_expressions() -> void:
    for index in range(15):
        var value := index + 2
        var multiplier := 2 + posmod(index, 4)
        var addend := index + 3
        if index < 5:
            _record("Algebraic Expressions", index, 15, "If x = %d, what is %dx + %d?" % [value, multiplier, addend], str(multiplier * value + addend), [str(value + multiplier + addend), str(multiplier * (value + addend)), str(multiplier * value - addend)])
        elif index < 10:
            _record("Algebraic Expressions", index, 15, "Simplify: %dx + %dx" % [multiplier, addend], "%dx" % (multiplier + addend), ["%dx" % (multiplier * addend), "%dx" % addend, "%dx" % (multiplier + addend + 1)])
        else:
            _record("Algebraic Expressions", index, 15, "If a = %d and b = %d,\nwhat is 3a - b?" % [value, addend], str(3 * value - addend), [str(3 * (value - addend)), str(3 * value + addend), str(value - addend)])

func _add_one_step_equations() -> void:
    for index in range(15):
        var solution := index + 2
        var amount := index + 3
        match posmod(index, 3):
            0:
                _record("One-Step Equations", index, 15, "Solve: x + %d = %d" % [amount, solution + amount], str(solution), [str(solution + amount), str(amount), str(solution - 1)])
            1:
                _record("One-Step Equations", index, 15, "Solve: x - %d = %d" % [amount, solution - amount], str(solution), [str(solution - amount), str(solution + amount), str(amount)])
            _:
                _record("One-Step Equations", index, 15, "Solve: %dx = %d" % [amount, amount * solution], str(solution), [str(amount * solution), str(solution + amount), str(amount)])

func _add_statistics() -> void:
    for index in range(15):
        var first := index + 2
        var second := first + 2
        var third := second + 2
        if index < 5:
            _record("Statistics", index, 15, "Find the mean: %d, %d, %d" % [first, second, third], str(second), [str(first), str(third), str(first + third)])
        elif index < 10:
            _record("Statistics", index, 15, "Find the median: %d, %d, %d, %d, %d" % [third + 4, first, second, third, second], str(second), [str(first), str(third), str(third + 4)])
        else:
            _record("Statistics", index, 15, "Find the range: %d, %d, %d, %d" % [first, second, third, third + 5], "5", [str(third + 5), str(first), str(third - first)])

func _add_percentages() -> void:
    for index in range(50):
        var percent := 10 + posmod(index, 5) * 10
        var number := 40 + index * 4
        var value := percent * number / 100
        if index < 10:
            _record("Percentages", index, 50, "What is %d%% of %d?" % [percent, number], str(value), [str(number / 10), str(percent), str(number - value)])
        elif index < 20:
            var price := 30 + index * 3
            _record("Percentages", index, 50, "A $%d item is %d%% off. What is the discount?" % [price, percent], _money(price * percent / 100.0), [_money(price - price * percent / 100.0), _money(percent), _money(price * percent / 10.0)])
        elif index < 30:
            var cost := 20 + index * 2
            _record("Percentages", index, 50, "What is %d%% tax on $%d?" % [percent, cost], _money(cost * percent / 100.0), [_money(cost + cost * percent / 100.0), _money(percent), _money(cost * percent / 10.0)])
        elif index < 40:
            var bill := 25 + index * 2
            _record("Percentages", index, 50, "What is a %d%% tip on $%d?" % [percent, bill], _money(bill * percent / 100.0), [_money(bill + bill * percent / 100.0), _money(percent), _money(bill * percent / 10.0)])
        else:
            var start := 50 + index * 5
            _record("Percentages", index, 50, "Increase %d by %d%%." % [start, percent], str(start + start * percent / 100), [str(start * percent / 100), str(start - start * percent / 100), str(start + percent)])

func _add_rational_numbers() -> void:
    for index in range(50):
        var left := index + 3
        var right := index + 2
        if index < 10:
            _record("Rational Numbers", index, 50, "-%d + %d.5 =" % [left, right], _decimal(right + 0.5 - left), [_decimal(-left - right - 0.5), _decimal(left + right + 0.5), _decimal(left - right - 0.5)])
        elif index < 20:
            var denominator := 4 + posmod(index, 3) * 2
            _record("Rational Numbers", index, 50, "(%d/%d) + (%d/%d) =" % [left, denominator, right, denominator], _fraction(left + right, denominator), [_fraction(left * right, denominator * denominator), _fraction(left + right, denominator * 2), _fraction(left - right, denominator)])
        elif index < 30:
            _record("Rational Numbers", index, 50, "-%d - %d =" % [left, right], str(-left - right), [str(-left + right), str(left - right), str(left + right)])
        elif index < 40:
            var denominator := 3 + posmod(index, 4)
            _record("Rational Numbers", index, 50, "(%d/%d) x (-%d) =" % [right, denominator, left], _fraction(-right * left, denominator), [_fraction(right * left, denominator), _fraction(right - left, denominator), _fraction(-right, denominator * left)])
        else:
            _record("Rational Numbers", index, 50, "Which is least: -%d.2, -%d.8, %d.1?" % [left, right, left], "-%d.8" % right, ["-%d.2" % left, "%d.1" % left, "They are equal"])

func _add_two_step_equations() -> void:
    for index in range(50):
        var solution := index + 2
        var multiplier := 2 + posmod(index, 5)
        var addend := 3 + posmod(index, 8)
        if posmod(index, 2) == 0:
            _record("Two-Step Equations", index, 50, "Solve: %dx + %d = %d" % [multiplier, addend, multiplier * solution + addend], str(solution), [str(multiplier * solution + addend), str(solution + addend), str(multiplier * solution)])
        else:
            _record("Two-Step Equations", index, 50, "Solve: %dx - %d = %d" % [multiplier, addend, multiplier * solution - addend], str(solution), [str(multiplier * solution - addend), str(solution - addend), str(solution + addend)])

func _add_two_step_inequalities() -> void:
    for index in range(40):
        var boundary := index + 3
        var multiplier := 2 + posmod(index, 4)
        var addend := 2 + posmod(index, 6)
        if posmod(index, 2) == 0:
            _record("Two-Step Inequalities", index, 40, "Solve: %dx + %d > %d" % [multiplier, addend, multiplier * boundary + addend], "x > %d" % boundary, ["x > %d" % (multiplier * boundary), "x < %d" % boundary, "x > %d" % (boundary + addend)])
        else:
            _record("Two-Step Inequalities", index, 40, "Solve: %dx - %d <= %d" % [multiplier, addend, multiplier * boundary - addend], "x <= %d" % boundary, ["x <= %d" % (multiplier * boundary), "x >= %d" % boundary, "x <= %d" % (boundary - addend)])

func _add_probability() -> void:
    for index in range(40):
        if index < 6:
            var face := 1 + index
            _record("Probability", index, 40, "A fair die is rolled. What is P(%d)?" % face, "1/6", ["1/3", "1/2", "%d/6" % face])
        elif index < 10:
            var die_events := [["an even number", "1/2", "1/6", "1/3", "2/3"], ["an odd number", "1/2", "1/6", "1/3", "2/3"], ["a number greater than 4", "1/3", "1/2", "1/6", "2/3"], ["a number less than 3", "1/3", "1/2", "1/6", "2/3"]]
            var event: Array = die_events[index - 6]
            _record("Probability", index, 40, "A fair die is rolled. What is P(%s)?" % event[0], event[1], [event[2], event[3], event[4]])
        elif index < 20:
            var coin_events := [["A fair coin is flipped. What is P(tails)?", "1/2", "1", "1/4", "0"], ["Two fair coins are flipped. What is P(exactly 1 head)?", "1/2", "1/4", "3/4", "1"], ["Two fair coins are flipped. What is P(2 heads)?", "1/4", "1/2", "3/4", "1/3"], ["Two fair coins are flipped. What is P(at least 1 head)?", "3/4", "1/2", "1/4", "1"], ["Three fair coins are flipped. What is P(3 tails)?", "1/8", "1/2", "1/4", "3/8"], ["Three fair coins are flipped. What is P(exactly 2 heads)?", "3/8", "1/2", "1/4", "1/8"], ["Three fair coins are flipped. What is P(at least 2 heads)?", "1/2", "3/8", "1/4", "3/4"], ["Four fair coins are flipped. What is P(no heads)?", "1/16", "1/4", "1/8", "1/2"], ["Four fair coins are flipped. What is P(exactly 2 heads)?", "3/8", "1/2", "1/4", "1/16"], ["Four fair coins are flipped. What is P(at least 1 tail)?", "15/16", "1/16", "3/4", "1/2"]]
            var coin_event: Array = coin_events[index - 10]
            _record("Probability", index, 40, coin_event[0], coin_event[1], [coin_event[2], coin_event[3], coin_event[4]])
        elif index < 30:
            var red := index - 15
            var blue := index - 10
            _record("Probability", index, 40, "A bag has %d red and %d blue marbles. What is P(red)?" % [red, blue], _fraction(red, red + blue), [_fraction(blue, red + blue), _fraction(red, blue), _fraction(red + blue, red)])
        else:
            var favorable := index - 25
            _record("Probability", index, 40, "A spinner has %d equal sections; %d are green. What is P(green)?" % [favorable + 5, favorable], _fraction(favorable, favorable + 5), [_fraction(favorable + 5, favorable), _fraction(favorable, 5), _fraction(5, favorable + 5)])

func _add_area_and_volume() -> void:
    for index in range(30):
        var length := index + 4
        var width := 3 + posmod(index, 6)
        var height := 2 + posmod(index, 5)
        if index < 10:
            _record("Area and Volume", index, 30, "A prism is %d by %d by %d. What is its volume?" % [length, width, height], "%d cubic units" % (length * width * height), ["%d cubic units" % (length + width + height), "%d square units" % (length * width * height), "%d cubic units" % (length * width + height)])
        elif index < 20:
            _record("Area and Volume", index, 30, "A rectangle is %d by %d units. What is its area?" % [length, width], "%d square units" % (length * width), ["%d units" % (2 * length + 2 * width), "%d square units" % (length + width), "%d square units" % (length * width + length)])
        else:
            _record("Area and Volume", index, 30, "A composite shape has rectangles %d by %d and %d by %d. What is its area?" % [length, width, height, width], "%d square units" % ((length + height) * width), ["%d square units" % (length * width), "%d square units" % (length + height + width), "%d square units" % (length * height)])

func _add_geometry() -> void:
    for index in range(40):
        if index < 10:
            var radius := 2 + index
            _record("Geometry", index, 40, "Use pi = 3.14. What is the circumference of a circle with radius %d?" % radius, _decimal(2.0 * 3.14 * radius), [_decimal(3.14 * radius), _decimal(3.14 * radius * radius), str(2 * radius)], true)
        elif index < 20:
            var radius := 2 + index - 10
            _record("Geometry", index, 40, "Use pi = 3.14. What is the area of a circle with radius %d?" % radius, _decimal(3.14 * radius * radius), [_decimal(2.0 * 3.14 * radius), _decimal(3.14 * radius), str(radius * radius)], true)
        elif index < 30:
            var first_angle := 30 + index * 2
            var second_angle := 40 + index
            _record("Geometry", index, 40, "A triangle has angles %d and %d degrees. Find the third angle." % [first_angle, second_angle], "%d degrees" % (180 - first_angle - second_angle), ["%d degrees" % (first_angle + second_angle), "%d degrees" % (90 - second_angle), "%d degrees" % (180 + first_angle - second_angle)])
        else:
            var angle := 30 + index * 3
            _record("Geometry", index, 40, "Two supplementary angles include %d degrees. What is the other angle?" % angle, "%d degrees" % (180 - angle), ["%d degrees" % (90 - angle), "%d degrees" % (180 + angle), "%d degrees" % angle])

func _add_scale_drawings() -> void:
    for index in range(20):
        var scale := 2 + posmod(index, 5)
        var drawing := 3 + index
        if index < 10:
            _record("Scale Drawings", index, 20, "A map scale is 1 cm : %d km. What distance is %d cm?" % [scale, drawing], "%d km" % (scale * drawing), ["%d km" % (scale + drawing), "%d km" % scale, "%d km" % (scale * drawing + scale)])
        else:
            _record("Scale Drawings", index, 20, "A model uses scale 1:%d. A real length is %d cm. What is the model length?" % [scale, scale * drawing], "%d cm" % drawing, ["%d cm" % (scale * drawing), "%d cm" % (drawing * scale * scale), "%d cm" % (drawing + scale)])

func _fraction(numerator: int, denominator: int) -> String:
    var divisor := _gcd(numerator, denominator)
    return "%d/%d" % [numerator / divisor, denominator / divisor]

func _decimal(value: float) -> String:
    return "%0.2f" % value

func _money(value: float) -> String:
    return "$%0.2f" % value

func _gcd(first: int, second: int) -> int:
    var left: int = abs(first)
    var right: int = abs(second)
    while right != 0:
        var remainder := posmod(left, right)
        left = right
        right = remainder
    return max(left, 1)