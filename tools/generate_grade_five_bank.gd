extends SceneTree

const OUTPUT_PATH := "res://data/questions/grade_5.json"

var question_index := 0
var records: Array[Dictionary] = []

func _init() -> void:
    _add_multi_digit_addition()
    _add_multi_digit_subtraction()
    _add_multi_digit_multiplication()
    _add_long_division()
    _add_fraction_addition()
    _add_fraction_subtraction()
    _add_decimal_place_value()
    _add_decimal_comparison()
    _add_decimal_operations()
    assert(records.size() == 215)
    var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
    assert(file != null, "Unable to write Grade 5 question bank.")
    file.store_string(JSON.stringify(records, "  ") + "\n")
    file.close()
    print("Generated %d Grade 5 questions at %s" % [records.size(), OUTPUT_PATH])
    quit()

func _record(topic: String, question: String, correct_answer: String, incorrect_answers: Array) -> void:
    var choices: Array[String] = []
    for incorrect_answer in incorrect_answers:
        choices.append(str(incorrect_answer))
    choices.insert(posmod(question_index, 4), correct_answer)
    records.append({
        "grade": 5,
        "topic": topic,
        "difficulty": _difficulty(),
        "uses_pi": false,
        "question": question,
        "choices": choices,
        "correctAnswer": correct_answer
    })
    question_index += 1

func _difficulty() -> String:
    if question_index < 43:
        return "easy"
    if question_index < 172:
        return "medium"
    return "hard"

func _add_multi_digit_addition() -> void:
    for index in range(35):
        var first := 1234 + index * 137
        var second := 2456 + index * 83
        var answer := first + second
        _record("Multi-Digit Addition", "%s + %s =" % [_number(first), _number(second)], str(answer), [str(answer - 10), str(answer + 10), str(first + second - 100)])

func _add_multi_digit_subtraction() -> void:
    for index in range(35):
        var first := 7000 + index * 191
        var second := 1234 + index * 47
        var answer := first - second
        _record("Multi-Digit Subtraction", "%s - %s =" % [_number(first), _number(second)], str(answer), [str(answer - 10), str(answer + 10), str(first - (second - 100))])

func _add_multi_digit_multiplication() -> void:
    for index in range(35):
        var first := 12 + index * 3
        var second := 14 + index
        var answer := first * second
        _record("Multi-Digit Multiplication", "%d x %d =" % [first, second], str(answer), [str(answer - first), str(answer + first), str(answer + first + second)])

func _add_long_division() -> void:
    for index in range(20):
        var divisor := 3 + posmod(index, 7)
        var quotient := 12 + index * 2
        var dividend := divisor * quotient
        _record("Long Division", "%d / %d =" % [dividend, divisor], str(quotient), [str(quotient - 1), str(quotient + 1), str(dividend - divisor)])

func _add_fraction_addition() -> void:
    for index in range(15):
        var denominator := 4 + index
        var first := 1 + posmod(index, denominator - 2)
        var second := 2 + posmod(index * 2, denominator - 3)
        var numerator := first + second
        var divisor := _gcd(numerator, denominator)
        var simple_numerator := numerator / divisor
        var simple_denominator := denominator / divisor
        var answer := "%d/%d" % [simple_numerator, simple_denominator]
        _record("Fraction Addition (Like Denominators)", "%d/%d + %d/%d =" % [first, denominator, second, denominator], answer, ["%d/%d" % [simple_numerator - 1, simple_denominator], "%d/%d" % [simple_numerator + 1, simple_denominator], "%d/%d" % [simple_numerator, simple_denominator + 1]])

func _add_fraction_subtraction() -> void:
    for index in range(15):
        var denominator := 5 + index
        var first := denominator - 1
        var second := 1 + posmod(index * 2, denominator - 2)
        var numerator := first - second
        var answer := _fraction(numerator, denominator)
        _record("Fraction Subtraction (Like Denominators)", "%d/%d - %d/%d =" % [first, denominator, second, denominator], answer, [_fraction(numerator + 1, denominator), _fraction(abs(numerator - 1), denominator), _fraction(first - second, denominator - 1)])

func _add_decimal_place_value() -> void:
    var values := ["4.582", "7.416", "2.915", "8.273", "5.641", "3.819", "6.154", "9.327", "1.786", "4.239", "7.518", "2.364", "8.915", "5.172", "3.648"]
    for index in range(values.size()):
        var value: String = values[index]
        var digit_position := 2 + posmod(index, 3)
        var digit := value[digit_position]
        var place_values := ["0.1", "0.01", "0.001"]
        var correct := "%s" % [float(digit) * float(place_values[digit_position - 2])]
        var wrong: Array[String] = []
        for place_index in range(3):
            if place_index != digit_position - 2:
                wrong.append("%s" % [float(digit) * float(place_values[place_index])])
        wrong.append(digit)
        _record("Decimal Place Value", "What is the value of the %s in %s?" % [digit, value], correct, wrong)

func _add_decimal_comparison() -> void:
    for index in range(15):
        var left := 1.2 + index * 0.13
        var right := left + (0.01 if index % 2 == 0 else -0.01)
        var left_text := "%.2f" % left
        var right_text := "%.2f" % right
        var correct := "%s is greater" % [left_text if left > right else right_text]
        var other := "%s is greater" % [right_text if correct.begins_with(left_text) else left_text]
        _record("Decimal Comparison", "Which decimal is greater: %s or %s?" % [left_text, right_text], correct, [other, "They are equal", "Not enough information"])

func _add_decimal_operations() -> void:
    for index in range(30):
        var first_cents := 125 + index * 37
        var second_cents := 48 + index * 19
        var adding := index % 2 == 0
        var answer := first_cents + second_cents if adding else first_cents - second_cents
        var symbol := "+" if adding else "-"
        _record("Decimal Operations", "%s %s %s =" % [_decimal(first_cents), symbol, _decimal(second_cents)], _decimal(answer), [_decimal(answer - 10), _decimal(answer + 10), _decimal(first_cents + second_cents if not adding else first_cents - second_cents)])

func _number(value: int) -> String:
    return str(value)

func _decimal(cents: int) -> String:
    return "%d.%02d" % [cents / 100, cents % 100]

func _fraction(numerator: int, denominator: int) -> String:
    var divisor := _gcd(numerator, denominator)
    return "%d/%d" % [numerator / divisor, denominator / divisor]

func _gcd(first: int, second: int) -> int:
    var left: int = abs(first)
    var right: int = abs(second)
    while right != 0:
        var remainder: int = posmod(left, right)
        left = right
        right = remainder
    return max(left, 1)